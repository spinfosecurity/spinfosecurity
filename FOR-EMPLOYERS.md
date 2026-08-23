# Reviewing this repo for a role

If you are hiring for **OT/ICS security**, **security automation**, or defensive analyst work with an industrial bent, this page is a five-minute map.

**Live site:** [spinfosecurity.github.io/ics-ot-advisories](https://spinfosecurity.github.io/ics-ot-advisories/)  
**Repo:** [github.com/spinfosecurity/ics-ot-advisories](https://github.com/spinfosecurity/ics-ot-advisories)  
**Portfolio:** [spinfosecurity.github.io](https://spinfosecurity.github.io)  
**Companion scanners:** [ICS OT Protector](https://github.com/spinfosecurity/ics-ot-protector)

---

## What this repository demonstrates

A small, reviewable **security-automation** pipeline that keeps public ICS/OT advisories usable for people who maintain equipment:

| Signal | Where to look |
|--------|----------------|
| Reliable official source (CISA CSAF, not fragile RSS scrapes) | [ATTRIBUTION.md](ATTRIBUTION.md) · `tools/aggregate.py` |
| Maintainer-first UX (vendor/product search, severity triage) | [Live site](https://spinfosecurity.github.io/ics-ot-advisories/) |
| Machine consumers (RSS + JSON) | `site/feed.xml` · `site/advisories.json` |
| Polite automation (weekly schedule, rate-limited fetches) | `.github/workflows/update-advisories.yml` |
| SEO / public credibility (canonical URLs, structured data, sitemap) | `site/index.html` · `site/sitemap.xml` · `site/robots.txt` |
| Honest limits and attribution | [ATTRIBUTION.md](ATTRIBUTION.md) |

Posture is explicit: **aggregate public advisories → help maintainers triage → link to CISA**. No exploit development.

---

## Suggested resume / portfolio bullets

Edit to match the conversation — these describe what the public repo shows:

- Built an open-source **CISA ICS/OT advisory aggregator** with a maintainer-focused triage UI, RSS feed, and JSON snapshot.
- Used the official **CISA CSAF OT** machine feed (avoiding brittle RSS endpoints that return HTTP 403 to automation).
- Shipped **weekly, rate-limited** GitHub Actions refresh so the public site stays current without aggressive scraping.
- Documented attribution, limits, and hiring-manager review paths for a credible defensive portfolio artifact.

---

## Roles this maps to

OT/ICS security · critical infrastructure defense · security automation · vulnerability / advisory management · roles that need CISA/ICS awareness and clean public tooling judgment.

---

## Read next

1. [README.md](README.md) — purpose, live URLs, how to run locally  
2. [Live advisories page](https://spinfosecurity.github.io/ics-ot-advisories/) — the operator-facing product  
3. [ICS OT Protector](https://github.com/spinfosecurity/ics-ot-protector) — sector exposure scanners + employer guide  
