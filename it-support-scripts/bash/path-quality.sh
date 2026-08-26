#!/usr/bin/env bash
# path-quality — measure the paths people actually work on (latency / loss / TLS).
# First principle: pinging 8.8.8.8 proves almost nothing about git push or SSO.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

TARGETS_FILE="${1:-}"
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
path-quality — parallel quality probes to real endpoints.

Usage:
  ./path-quality.sh [targets.conf]

Default targets: ../targets.example.conf (copy → targets.conf for your fleet).
EOF
  exit 0
fi

CONF="${TARGETS_FILE:-}"
if [[ -z "$CONF" ]]; then
  if [[ -f "${ROOT}/targets.conf" ]]; then
    CONF="${ROOT}/targets.conf"
  else
    CONF="${ROOT}/targets.example.conf"
  fi
fi

echo "# path-quality — $(it_host) @ $(it_utc)"
echo "# targets: $CONF"
printf '%-18s %-10s %-8s %-8s %s\n' "NAME" "HOST" "ICMP_ms" "LOSS%" "TLS/TCP"
printf '%-18s %-10s %-8s %-8s %s\n' "----" "----" "-------" "-----" "------"

probe_one() {
  local name="$1" host="$2" port="$3" proto="$4"
  local icmp="n/a" loss="n/a" tcp="n/a"
  if [[ "$proto" == "icmp" || "$proto" == "tcp" ]]; then
    local pout tx rx
    pout="$(ping -c 5 -W 2 "$host" 2>/dev/null || ping -c 5 -w 2 "$host" 2>/dev/null || true)"
    if grep -q 'bytes from' <<<"$pout"; then
      icmp="$(awk -F'/' '/rtt|round-trip/{print $5; exit}' <<<"$pout")"
      tx="$(echo "$pout" | awk -F',' '/packets transmitted/{print $1}' | tr -dc '0-9')"
      rx="$(echo "$pout" | awk -F',' '/packets transmitted/{print $2}' | tr -dc '0-9')"
      if [[ -n "$tx" && -n "$rx" && "$tx" -gt 0 ]]; then
        loss="$(awk -v t="$tx" -v r="$rx" 'BEGIN{printf "%d", (t-r)*100/t}')"
      else
        loss="0"
      fi
    else
      icmp="FAIL"; loss="100"
    fi
  fi
  if [[ "$proto" == "tcp" ]]; then
    if it_need nc; then
      if nc -z -w 3 "$host" "$port" 2>/dev/null; then tcp="open/$port"; else tcp="CLOSED/$port"; fi
    elif it_need curl && [[ "$port" == "443" ]]; then
      local t code
      t="$(curl -s --max-time 5 -o /dev/null -w '%{time_connect}' "https://${host}/" 2>/dev/null || echo FAIL)"
      code="$(curl -sk --max-time 5 -o /dev/null -w '%{http_code}' "https://${host}/" 2>/dev/null || echo 000)"
      if [[ "$code" != "000" ]]; then tcp="tls:${code}/${t}s"; else tcp="FAIL"; fi
    else
      tcp="skip"
    fi
  fi
  printf '%-18s %-24s %-8s %-8s %s\n' "$name" "$host" "${icmp}" "${loss}" "${tcp}"
}

declare -a PIDS=()
TMPDIR_PQ="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_PQ"' EXIT

idx=0
while IFS='|' read -r name host port proto; do
  [[ -z "${name:-}" || "$name" =~ ^# ]] && continue
  idx=$((idx + 1))
  out="${TMPDIR_PQ}/${idx}.txt"
  ( probe_one "$name" "$host" "$port" "$proto" >"$out" ) &
  PIDS+=("$!")
done < "$CONF"

for pid in "${PIDS[@]:-}"; do
  wait "$pid" || true
done

# stable order
for f in $(ls "${TMPDIR_PQ}"/*.txt 2>/dev/null | sort -V); do
  cat "$f"
done

echo
it_section "Read"
echo "  ICMP_ms >50 on LAN or >150 remote → investigate Wi-Fi/VPN first"
echo "  LOSS% >2 on wired → bad path (not 'reboot the laptop')"
echo "  TLS/TCP FAIL with good ICMP → middlebox / SNI / firewall, not 'DNS'"
