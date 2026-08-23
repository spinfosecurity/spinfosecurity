#!/usr/bin/env python3
"""Aggregate CISA ICS/OT advisories from the official CSAF feed.

CISA's public RSS endpoints often return HTTP 403 to automated clients.
The authoritative machine-readable source is the CISA CSAF OT feed on GitHub:

  https://github.com/cisagov/CSAF

This script:
  1. Reads the ROLIE feed index
  2. Fetches recent CSAF JSON documents
  3. Writes advisories.json, feed.xml, and index.html for GitHub Pages
"""

from __future__ import annotations

import argparse
import concurrent.futures
import html
import json
import re
import sys
import threading
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from xml.sax.saxutils import escape as xml_escape

_FETCH_LOCK = threading.Lock()
_LAST_FETCH_AT = 0.0

FEED_URL = (
    "https://raw.githubusercontent.com/cisagov/CSAF/develop/"
    "csaf_files/OT/white/cisa-csaf-ot-feed-tlp-white.json"
)
USER_AGENT = "SpinfoSecurity-Advisories/1.0 (+https://spinfosecurity.github.io/advisories/)"
SITE_ORIGIN = "https://spinfosecurity.github.io"
PAGE_PATH = "/advisories/"
DEFAULT_LIMIT = 120
MAX_WORKERS = 2
REQUEST_TIMEOUT = 45
REQUEST_GAP_SECONDS = 0.35

SEVERITY_RANK = {
    "CRITICAL": 4,
    "HIGH": 3,
    "MEDIUM": 2,
    "LOW": 1,
    "NONE": 0,
    "UNKNOWN": 0,
}


def fetch_json(url: str) -> Any:
    """Fetch JSON with a small global gap between requests (be polite to GitHub)."""
    global _LAST_FETCH_AT
    with _FETCH_LOCK:
        now = time.monotonic()
        wait = REQUEST_GAP_SECONDS - (now - _LAST_FETCH_AT)
        if wait > 0:
            time.sleep(wait)
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": USER_AGENT,
                "Accept": "application/json",
            },
        )
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
            payload = json.load(resp)
        _LAST_FETCH_AT = time.monotonic()
        return payload


def walk_products(branches: list[dict[str, Any]] | None) -> tuple[list[str], list[str]]:
    vendors: list[str] = []
    products: list[str] = []

    def walk(nodes: list[dict[str, Any]] | None) -> None:
        if not nodes:
            return
        for node in nodes:
            category = node.get("category")
            name = (node.get("name") or "").strip()
            if category == "vendor" and name:
                vendors.append(name)
            elif category == "product_name" and name:
                products.append(name)
            walk(node.get("branches"))

    walk(branches)
    # Preserve order, drop duplicates
    def uniq(items: list[str]) -> list[str]:
        seen: set[str] = set()
        out: list[str] = []
        for item in items:
            key = item.casefold()
            if key not in seen:
                seen.add(key)
                out.append(item)
        return out

    return uniq(vendors), uniq(products)


def max_severity(vulnerabilities: list[dict[str, Any]] | None) -> tuple[str, float | None]:
    best_sev = "UNKNOWN"
    best_score: float | None = None
    best_rank = -1
    for vuln in vulnerabilities or []:
        for score in vuln.get("scores") or []:
            cvss = score.get("cvss_v3") or score.get("cvss_v2") or {}
            sev = (cvss.get("baseSeverity") or "").upper() or "UNKNOWN"
            raw = cvss.get("baseScore")
            try:
                numeric = float(raw) if raw is not None else None
            except (TypeError, ValueError):
                numeric = None
            rank = SEVERITY_RANK.get(sev, 0)
            if numeric is not None and (best_score is None or numeric > best_score):
                best_score = numeric
            if rank > best_rank or (rank == best_rank and numeric is not None and (best_score is None or numeric >= best_score)):
                best_rank = rank
                best_sev = sev if sev in SEVERITY_RANK else "UNKNOWN"
                if numeric is not None:
                    best_score = numeric if best_score is None else max(best_score, numeric)
    if best_rank < 0:
        return "UNKNOWN", best_score
    return best_sev, best_score


def collect_cves(vulnerabilities: list[dict[str, Any]] | None) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for vuln in vulnerabilities or []:
        cve = (vuln.get("cve") or "").strip()
        if cve and cve not in seen:
            seen.add(cve)
            out.append(cve)
    return out


def web_url_from_doc(doc: dict[str, Any], advisory_id: str) -> str:
    for ref in doc.get("references") or []:
        url = (ref.get("url") or "").strip()
        summary = (ref.get("summary") or "").lower()
        if "web version" in summary and "cisa.gov" in url:
            return url
        if re.search(r"cisa\.gov/news-events/ics(?:-medical)?-advisories/", url):
            return url
    slug = advisory_id.lower()
    if slug.startswith("icsma-"):
        return f"https://www.cisa.gov/news-events/ics-medical-advisories/{slug}"
    return f"https://www.cisa.gov/news-events/ics-advisories/{slug}"


def advisory_kind(advisory_id: str) -> str:
    if advisory_id.upper().startswith("ICSMA-"):
        return "medical"
    return "advisory"


def enrich_entry(entry: dict[str, Any]) -> dict[str, Any] | None:
    advisory_id = (entry.get("id") or "").strip()
    title = (entry.get("title") or "").strip()
    published = entry.get("published") or entry.get("updated") or ""
    updated = entry.get("updated") or published
    csaf_url = ""
    for link in entry.get("link") or []:
        if link.get("rel") == "self" and str(link.get("href", "")).endswith(".json"):
            csaf_url = link["href"]
            break
    if not csaf_url:
        content = entry.get("content") or {}
        csaf_url = content.get("src") or ""
    if not advisory_id or not csaf_url:
        return None

    try:
        payload = fetch_json(csaf_url)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError) as exc:
        print(f"warn: skip {advisory_id}: {exc}", file=sys.stderr)
        return {
            "id": advisory_id,
            "title": title or advisory_id,
            "published": published,
            "updated": updated,
            "kind": advisory_kind(advisory_id),
            "severity": "UNKNOWN",
            "cvss": None,
            "vendors": [],
            "products": [],
            "cves": [],
            "url": web_url_from_doc({}, advisory_id),
            "csaf_url": csaf_url,
            "summary": "",
        }

    doc = payload.get("document") or {}
    vendors, products = walk_products((payload.get("product_tree") or {}).get("branches"))
    severity, cvss = max_severity(payload.get("vulnerabilities"))
    cves = collect_cves(payload.get("vulnerabilities"))
    summary = ""
    for note in doc.get("notes") or []:
        if note.get("category") in {"summary", "description", "general"} and note.get("text"):
            summary = re.sub(r"\s+", " ", note["text"]).strip()
            if len(summary) > 280:
                summary = summary[:277].rstrip() + "…"
            break

    return {
        "id": (doc.get("tracking") or {}).get("id") or advisory_id,
        "title": doc.get("title") or title or advisory_id,
        "published": (doc.get("tracking") or {}).get("initial_release_date") or published,
        "updated": (doc.get("tracking") or {}).get("current_release_date") or updated,
        "kind": advisory_kind(advisory_id),
        "severity": severity,
        "cvss": cvss,
        "vendors": vendors,
        "products": products[:8],
        "cves": cves[:12],
        "url": web_url_from_doc(doc, advisory_id),
        "csaf_url": csaf_url,
        "summary": summary,
    }


def parse_dt(value: str) -> datetime:
    if not value:
        return datetime.min.replace(tzinfo=timezone.utc)
    text = value.replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(text)
    except ValueError:
        return datetime.min.replace(tzinfo=timezone.utc)


def build_rss(advisories: list[dict[str, Any]], generated_at: str) -> str:
    items: list[str] = []
    for adv in advisories:
        pub = parse_dt(adv["published"] or adv["updated"])
        pub_rss = pub.strftime("%a, %d %b %Y %H:%M:%S +0000") if pub.year > 1 else generated_at
        vendors = ", ".join(adv.get("vendors") or []) or "Vendor not listed"
        desc_parts = [
            f"CISA {adv['id']}",
            f"Severity: {adv.get('severity') or 'UNKNOWN'}",
            f"Vendor: {vendors}",
        ]
        if adv.get("cvss") is not None:
            desc_parts.append(f"CVSS: {adv['cvss']}")
        if adv.get("summary"):
            desc_parts.append(adv["summary"])
        description = " · ".join(desc_parts)
        items.append(
            "\n".join(
                [
                    "    <item>",
                    f"      <title>{xml_escape(adv['title'])}</title>",
                    f"      <link>{xml_escape(adv['url'])}</link>",
                    f"      <guid isPermaLink=\"false\">{xml_escape(adv['id'])}</guid>",
                    f"      <pubDate>{xml_escape(pub_rss)}</pubDate>",
                    f"      <category>{xml_escape(adv.get('kind') or 'advisory')}</category>",
                    f"      <description>{xml_escape(description)}</description>",
                    "    </item>",
                ]
            )
        )

    return "\n".join(
        [
            '<?xml version="1.0" encoding="UTF-8"?>',
            '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">',
            "  <channel>",
            "    <title>SpinfoSecurity ICS/OT Advisories</title>",
            f"    <link>{SITE_ORIGIN}{PAGE_PATH}</link>",
            "    <description>Aggregated CISA ICS/OT security advisories for industrial control equipment maintainers.</description>",
            "    <language>en-us</language>",
            f"    <lastBuildDate>{xml_escape(datetime.fromisoformat(generated_at.replace('Z', '+00:00')).strftime('%a, %d %b %Y %H:%M:%S +0000'))}</lastBuildDate>",
            f'    <atom:link href="{SITE_ORIGIN}{PAGE_PATH}feed.xml" rel="self" type="application/rss+xml"/>',
            *items,
            "  </channel>",
            "</rss>",
            "",
        ]
    )


def fmt_date(value: str) -> str:
    dt = parse_dt(value)
    if dt.year <= 1:
        return "—"
    return dt.strftime("%Y-%m-%d")


def render_rows(advisories: list[dict[str, Any]]) -> str:
    rows: list[str] = []
    for adv in advisories:
        sev = (adv.get("severity") or "UNKNOWN").upper()
        kind = adv.get("kind") or "advisory"
        kind_label = "Medical" if kind == "medical" else "Advisory"
        vendors = ", ".join(adv.get("vendors") or []) or "Vendor not listed"
        products = ", ".join(adv.get("products") or [])
        meta_bits = [html.escape(vendors)]
        if products:
            meta_bits.append(html.escape(products))
        cvss = adv.get("cvss")
        cvss_html = f'<span class="cvss">{html.escape(f"{cvss:.1f}")}</span>' if isinstance(cvss, (int, float)) else ""
        search = " ".join(
            [
                adv.get("id") or "",
                adv.get("title") or "",
                vendors,
                products,
                " ".join(adv.get("cves") or []),
                kind_label,
                sev,
            ]
        ).casefold()
        rows.append(
            f"""
        <article class="adv-row" data-severity="{html.escape(sev)}" data-kind="{html.escape(kind)}" data-search="{html.escape(search)}" id="{html.escape(adv['id'])}">
          <div class="adv-rail">
            <span class="sev sev-{html.escape(sev.lower())}">{html.escape(sev.title() if sev != 'UNKNOWN' else 'Unrated')}</span>
            {cvss_html}
          </div>
          <div class="adv-body">
            <div class="adv-topline">
              <time datetime="{html.escape(adv.get('published') or '')}">{html.escape(fmt_date(adv.get('published') or ''))}</time>
              <span class="adv-id">{html.escape(adv['id'])}</span>
              <span class="adv-kind">{html.escape(kind_label)}</span>
            </div>
            <h3 class="adv-title"><a href="{html.escape(adv['url'])}" rel="noopener noreferrer">{html.escape(adv['title'])}</a></h3>
            <p class="adv-meta">{' · '.join(meta_bits)}</p>
          </div>
          <a class="adv-open" href="{html.escape(adv['url'])}" rel="noopener noreferrer" aria-label="Open {html.escape(adv['id'])} on CISA">Open</a>
        </article>"""
        )
    return "\n".join(rows)


def render_html(advisories: list[dict[str, Any]], generated_at: str, template: str) -> str:
    display = datetime.fromisoformat(generated_at.replace("Z", "+00:00")).strftime("%Y-%m-%d %H:%M UTC")
    critical = sum(1 for a in advisories if a.get("severity") == "CRITICAL")
    high = sum(1 for a in advisories if a.get("severity") == "HIGH")
    return (
        template.replace("{{GENERATED_AT_ISO}}", html.escape(generated_at))
        .replace("{{GENERATED_AT_DISPLAY}}", html.escape(display))
        .replace("{{COUNT}}", str(len(advisories)))
        .replace("{{CRITICAL_COUNT}}", str(critical))
        .replace("{{HIGH_COUNT}}", str(high))
        .replace("{{ADVISORY_ROWS}}", render_rows(advisories))
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path(__file__).resolve().parents[2] / "docs" / "job-hunting-site" / "advisories",
    )
    parser.add_argument("--template", type=Path, default=Path(__file__).resolve().parent / "index.template.html")
    parser.add_argument("--limit", type=int, default=DEFAULT_LIMIT)
    args = parser.parse_args()

    print(f"Fetching feed index: {FEED_URL}")
    feed_doc = fetch_json(FEED_URL)
    entries = (feed_doc.get("feed") or {}).get("entry") or []
    if not entries:
        print("error: feed contained no entries", file=sys.stderr)
        return 1

    entries = sorted(entries, key=lambda e: parse_dt(e.get("published") or e.get("updated") or ""), reverse=True)
    selected = entries[: max(1, args.limit)]
    print(f"Enriching {len(selected)} advisories…")

    advisories: list[dict[str, Any]] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
        futures = [pool.submit(enrich_entry, entry) for entry in selected]
        for fut in concurrent.futures.as_completed(futures):
            item = fut.result()
            if item:
                advisories.append(item)

    advisories.sort(key=lambda a: parse_dt(a.get("published") or a.get("updated") or ""), reverse=True)
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    args.out_dir.mkdir(parents=True, exist_ok=True)
    json_path = args.out_dir / "advisories.json"
    rss_path = args.out_dir / "feed.xml"
    html_path = args.out_dir / "index.html"

    payload = {
        "generated_at": generated_at,
        "source": {
            "name": "CISA CSAF OT feed (TLP:WHITE)",
            "url": FEED_URL,
            "publisher": "Cybersecurity and Infrastructure Security Agency",
        },
        "count": len(advisories),
        "advisories": advisories,
    }
    json_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    rss_path.write_text(build_rss(advisories, generated_at), encoding="utf-8")

    template = args.template.read_text(encoding="utf-8")
    html_path.write_text(render_html(advisories, generated_at, template), encoding="utf-8")

    print(f"Wrote {json_path}")
    print(f"Wrote {rss_path}")
    print(f"Wrote {html_path}")
    print(f"Advisories: {len(advisories)} (critical={sum(1 for a in advisories if a.get('severity')=='CRITICAL')})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
