#!/usr/bin/env bash
# dns-truth — OS resolver vs independent DoH. Detect hijack, captive, NXDOMAIN forgery.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

NAME="${1:-example.com}"
if [[ "$NAME" == "-h" || "$NAME" == "--help" ]]; then
  cat <<'EOF'
dns-truth — compare system DNS to DoH ground truth.

Usage: ./dns-truth.sh [name]

Flags private/CGNAT answers, empty answers, and NXDOMAIN forgery
(random name that should not resolve).
EOF
  exit 0
fi

echo "# dns-truth — $NAME — $(it_host) @ $(it_utc)"
IT_HYPS=()

it_section "System resolver"
mapfile -t SYS < <(it_resolve_system "$NAME")
if [[ ${#SYS[@]} -eq 0 ]]; then
  it_fail "no answer"
  it_hyp_add 1 "System DNS dead" "no A for $NAME" "check /etc/resolv.conf, VPN DNS, nic"
else
  printf '  %s\n' "${SYS[@]}"
fi

it_section "DoH ground truth"
mapfile -t DOH < <(it_resolve_doh "$NAME")
if [[ ${#DOH[@]} -eq 0 ]]; then
  it_warn "DoH unreachable — cannot establish ground truth"
  it_hyp_add 2 "DoH path blocked" "cloudflare-dns.com query failed" \
    "if system DNS also empty → network; else continue with private-IP checks"
else
  printf '  %s\n' "${DOH[@]}"
fi

it_section "Honesty checks"
for ip in "${SYS[@]:-}"; do
  if it_is_private_ip "$ip"; then
    it_fail "non-public answer $ip for public name"
    it_hyp_add 1 "DNS hijack or captive portal" "$NAME → $ip" \
      "portal login or fix DNS; do not trust browser redirects alone"
  fi
done

RAND="nx-$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n').invalid"
nx="$(it_resolve_system "$RAND" | head -n1 || true)"
if [[ -n "$nx" ]]; then
  it_fail "random name resolved to $nx — NXDOMAIN forgery / sinkhole"
  it_hyp_add 1 "NXDOMAIN forgery" "$RAND → $nx" \
    "capture resolver IP; escalate — this is policy/malware/middlebox territory"
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
    it_warn "no overlap with DoH (multi-CDN possible) — trust private-IP + NXDOMAIN checks"
  fi
fi

it_hyp_print
[[ ${#IT_HYPS[@]} -gt 0 ]] && exit 1 || exit 0
