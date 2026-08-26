#!/usr/bin/env bash
# Shared helpers for IT support scripts — keep output ticket-grade and ranked.
# shellcheck shell=bash

it_utc() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
it_host() { hostname 2>/dev/null || echo unknown; }

it_section() { printf '\n## %s\n' "$1"; }

it_ok()   { printf '  [OK]   %s\n' "$*"; }
it_warn() { printf '  [WARN] %s\n' "$*"; }
it_fail() { printf '  [FAIL] %s\n' "$*"; }
it_info() { printf '  [--]   %s\n' "$*"; }

# Append a hypothesis: severity|title|evidence
# severity: 1=critical 2=high 3=medium 4=low
it_hyp_add() {
  local sev="$1" title="$2" evidence="$3"
  IT_HYPS+=("${sev}|${title}|${evidence}")
}

it_hyp_print() {
  if [[ ${#IT_HYPS[@]} -eq 0 ]]; then
    it_ok "No strong failure signal — environment looks workable."
    return 0
  fi
  local sorted
  mapfile -t sorted < <(printf '%s\n' "${IT_HYPS[@]}" | sort -t'|' -k1,1n)
  local i=1 line sev title evidence
  echo
  echo "### Ranked hypotheses (act on #1 first)"
  for line in "${sorted[@]}"; do
    IFS='|' read -r sev title evidence <<<"$line"
    printf '  #%d  [sev=%s] %s\n       evidence: %s\n' "$i" "$sev" "$title" "$evidence"
    i=$((i + 1))
  done
}

it_need() {
  command -v "$1" >/dev/null 2>&1
}

it_ms_ping() {
  # print average rtt ms or FAIL
  local host="$1" count="${2:-3}"
  local out avg
  out="$(ping -c "$count" -W 2 "$host" 2>/dev/null || ping -c "$count" -w 2 "$host" 2>/dev/null || true)"
  if ! grep -q 'bytes from' <<<"$out"; then
    echo "FAIL"
    return 1
  fi
  avg="$(awk -F'/' '/rtt|round-trip/ {print $5; exit}' <<<"$out")"
  if [[ -z "$avg" ]]; then
    avg="$(echo "$out" | awk -F'=' '/time=/{gsub(/ ms/,"",$NF); s+=$NF; n++} END{if(n) printf "%.2f", s/n; else print "FAIL"}')"
  fi
  echo "${avg:-FAIL}"
}

IT_HYPS=()
