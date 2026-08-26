#!/usr/bin/env bash
# Shared helpers — ticket-grade output, ranked hypotheses, portable probes.
# shellcheck shell=bash

it_utc()  { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
it_host() { hostname 2>/dev/null || scutil --get LocalHostName 2>/dev/null || echo unknown; }

it_section() { printf '\n## %s\n' "$1"; }
it_ok()      { printf '  [OK]   %s\n' "$*"; }
it_warn()    { printf '  [WARN] %s\n' "$*"; }
it_fail()    { printf '  [FAIL] %s\n' "$*"; }
it_info()    { printf '  [--]   %s\n' "$*"; }
it_fix()     { printf '  [FIX]  %s\n' "$*"; }

it_need() { command -v "$1" >/dev/null 2>&1; }

# severity|title|evidence|fix
# severity: 1=critical 2=high 3=medium 4=low
IT_HYPS=()
it_hyp_add() {
  IT_HYPS+=("${1}|${2}|${3}|${4:-}")
}

it_hyp_print() {
  if [[ ${#IT_HYPS[@]} -eq 0 ]]; then
    it_ok "No strong failure signal."
    return 0
  fi
  local sorted i=1 line sev title evidence fix
  mapfile -t sorted < <(printf '%s\n' "${IT_HYPS[@]}" | sort -t'|' -k1,1n)
  echo
  echo "### Ranked hypotheses — act on #1 first"
  for line in "${sorted[@]}"; do
    IFS='|' read -r sev title evidence fix <<<"$line"
    printf '  #%d  %s\n' "$i" "$title"
    printf '       evidence: %s\n' "$evidence"
    [[ -n "$fix" ]] && printf '       fix:      %s\n' "$fix"
    i=$((i + 1))
  done
}

it_is_private_ip() {
  case "$1" in
    10.*|192.168.*|172.1[6-9].*|172.2[0-9].*|172.3[0-1].*|100.64.*|127.*|0.0.0.0|169.254.*) return 0 ;;
    *) return 1 ;;
  esac
}

it_default_gw() {
  if it_need ip; then
    ip route show default 2>/dev/null | awk '/default/{print $3; exit}'
  elif it_need route; then
    route -n get default 2>/dev/null | awk '/gateway:/{print $2; exit}' \
      || route -n 2>/dev/null | awk '$1=="0.0.0.0"{print $2; exit}'
  fi
}

# Parse HTTP Date header → epoch seconds (GNU date + BSD date)
it_http_date_epoch() {
  local hdr="$1" epoch=""
  [[ -z "$hdr" ]] && return 1
  epoch="$(date -u -d "$hdr" +%s 2>/dev/null || true)"
  if [[ -z "$epoch" ]]; then
    epoch="$(date -u -j -f '%a, %d %b %Y %H:%M:%S %Z' "$hdr" +%s 2>/dev/null || true)"
  fi
  [[ -n "$epoch" ]] && printf '%s\n' "$epoch"
}

# Sample skew (local - remote) in seconds vs URL Date header. Empty on failure.
it_edge_skew_s() {
  local url="${1:-https://1.1.1.1}"
  local hdr remote local_e
  hdr="$(curl -sI --max-time 4 "$url" 2>/dev/null | awk -F': ' 'tolower($1)=="date"{print $2; exit}' | tr -d '\r')"
  remote="$(it_http_date_epoch "$hdr" || true)"
  [[ -z "$remote" ]] && return 1
  local_e="$(date -u +%s)"
  echo $(( local_e - remote ))
}

it_resolve_system() {
  local name="$1"
  if it_need dig; then
    dig +short +time=2 +tries=1 "$name" A 2>/dev/null | grep -E '^[0-9.]+$' | head -n 5
  elif it_need getent; then
    getent ahostsv4 "$name" 2>/dev/null | awk '{print $1}' | awk '!seen[$0]++' | head -n 5
  else
    python3 -c "import socket; print(socket.gethostbyname('$name'))" 2>/dev/null || true
  fi
}

it_resolve_doh() {
  local name="$1" url json
  url="https://cloudflare-dns.com/dns-query?name=${name}&type=A"
  json="$(curl -s --max-time 5 "$url" -H 'accept: application/dns-json' 2>/dev/null || true)"
  printf '%s' "$json" | sed -n 's/.*"data":"\([0-9.]*\)".*/\1/p' | head -n 5
}

it_ms_ping() {
  local host="$1" count="${2:-3}" out avg
  out="$(ping -c "$count" -W 2 "$host" 2>/dev/null || ping -c "$count" -w 2 "$host" 2>/dev/null || true)"
  if ! grep -q 'bytes from' <<<"$out"; then
    echo "FAIL"; return 1
  fi
  avg="$(awk -F'/' '/rtt|round-trip/ {print $5; exit}' <<<"$out")"
  if [[ -z "$avg" ]]; then
    avg="$(echo "$out" | awk -F'=' '/time=/{gsub(/ ms/,"",$NF); s+=$NF; n++} END{if(n) printf "%.2f", s/n; else print "FAIL"}')"
  fi
  echo "${avg:-FAIL}"
}

it_tcp_check() {
  local host="$1" port="$2"
  if it_need nc; then
    nc -z -w 3 "$host" "$port" 2>/dev/null
  else
    timeout 3 bash -c "echo >/dev/tcp/${host}/${port}" 2>/dev/null
  fi
}

it_targets_file() {
  local root="$1"
  if [[ -f "${root}/targets.conf" ]]; then
    echo "${root}/targets.conf"
  else
    echo "${root}/targets.example.conf"
  fi
}
