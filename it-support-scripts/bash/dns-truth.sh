#!/usr/bin/env bash
# dns-truth — detect lies: hijack, captive portal, split-brain, NXDOMAIN forgery.
# First principle: the OS resolver is not ground truth. Compare it to an independent path.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

NAME="${1:-example.com}"
if [[ "$NAME" == "-h" || "$NAME" == "--help" ]]; then
  cat <<'EOF'
dns-truth — compare system DNS to DoH ground truth.

Usage: ./dns-truth.sh [name]
EOF
  exit 0
fi

echo "# dns-truth — $NAME — $(it_host) @ $(it_utc)"
IT_HYPS=()

resolve_system() {
  if it_need dig; then
    dig +short +time=2 +tries=1 "$1" A 2>/dev/null | head -n 5
  elif it_need getent; then
    getent ahostsv4 "$1" 2>/dev/null | awk '{print $1}' | uniq | head -n 5
  else
    python3 - <<PY 2>/dev/null || true
import socket
print(socket.gethostbyname("$1"))
PY
  fi
}

resolve_doh() {
  curl -s --max-time 5 "https://cloudflare-dns.com/dns-query?name=$1&type=A" \
    -H 'accept: application/dns-json' 2>/dev/null |
    sed -n 's/.*"data":"\([0-9.]*\)".*/\1/p'
}

it_section "System resolver"
mapfile -t SYS < <(resolve_system "$NAME" | sed '/^$/d')
if [[ ${#SYS[@]} -eq 0 ]]; then
  it_fail "no answer"
  it_hyp_add 1 "System DNS dead" "no A for $NAME"
else
  printf '  %s\n' "${SYS[@]}"
fi

it_section "DoH ground truth (cloudflare-dns.com)"
mapfile -t DOH < <(resolve_doh "$NAME" | sed '/^$/d')
if [[ ${#DOH[@]} -eq 0 ]]; then
  it_warn "DoH unreachable — cannot establish ground truth (proxy/firewall?)"
  it_hyp_add 2 "DoH path blocked" "cannot validate resolver honesty"
else
  printf '  %s\n' "${DOH[@]}"
fi

it_section "Verdict"
is_private() {
  case "$1" in
    10.*|192.168.*|172.1[6-9].*|172.2[0-9].*|172.3[0-1].*|100.64.*|127.*|0.0.0.0|169.254.*) return 0 ;;
    *) return 1 ;;
  esac
}

for ip in "${SYS[@]:-}"; do
  if is_private "$ip"; then
    it_fail "system returned non-routable/public-lie address $ip"
    it_hyp_add 1 "DNS hijack or captive portal" "$NAME → $ip (private/CGNAT)"
  fi
done

# NXDOMAIN forgery probe: random label should not resolve
RAND="nx-$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n').invalid"
nx="$(resolve_system "$RAND" | head -n1 || true)"
if [[ -n "$nx" ]]; then
  it_fail "random name resolved to $nx — NXDOMAIN forgery / sinkhole"
  it_hyp_add 1 "NXDOMAIN forgery" "$RAND → $nx"
else
  it_ok "random name correctly empty"
fi

if [[ ${#SYS[@]} -gt 0 && ${#DOH[@]} -gt 0 ]]; then
  overlap=0
  for s in "${SYS[@]}"; do
    for d in "${DOH[@]}"; do
      [[ "$s" == "$d" ]] && overlap=1
    done
  done
  if [[ "$overlap" -eq 1 ]]; then
    it_ok "system answer intersects DoH set"
  else
    it_warn "no overlap with DoH (CDN multi-A possible) — check private/captive flags above"
  fi
fi

it_hyp_print
