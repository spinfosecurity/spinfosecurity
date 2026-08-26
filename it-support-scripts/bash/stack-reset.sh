#!/usr/bin/env bash
# stack-reset — idempotent network heal with before/after proof. Not a reboot.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

APPLY=0
for a in "$@"; do
  case "$a" in
    -h|--help)
      cat <<'EOF'
stack-reset — flush DNS + renew DHCP + prove the delta.

Usage:
  ./stack-reset.sh          # dry-run: before metrics + plan
  ./stack-reset.sh --apply  # heal + after metrics

Prefer this over reboot. Reboot hides root cause.
EOF
      exit 0
      ;;
    --apply) APPLY=1 ;;
  esac
done

measure() {
  M_GW="$(it_default_gw || true)"
  M_PING="$(it_ms_ping 1.1.1.1 3 2>/dev/null || echo FAIL)"
  M_HTTP="$(curl -s --max-time 5 -o /dev/null -w '%{http_code}' https://example.com 2>/dev/null || echo 000)"
  it_info "gw=${M_GW:-none}  icmp=${M_PING}ms  https=${M_HTTP}"
}

echo "# stack-reset — $(it_host) @ $(it_utc)"
it_section "BEFORE"
measure
B_PING="$M_PING" B_HTTP="$M_HTTP" B_GW="${M_GW:-none}"

if [[ "$APPLY" -eq 0 ]]; then
  it_section "Plan (dry-run)"
  echo "  1. flush local DNS caches"
  echo "  2. renew DHCP on active interface"
  echo "  3. re-probe ICMP + HTTPS"
  echo
  echo "Re-run with --apply to execute."
  exit 0
fi

it_section "Apply"
flushed=0
if it_need resolvectl; then
  sudo resolvectl flush-caches && { it_ok "resolvectl flush-caches"; flushed=1; }
elif [[ "$(uname -s)" == "Darwin" ]]; then
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder
  it_ok "macOS DNS flush"; flushed=1
fi
[[ "$flushed" -eq 0 ]] && it_warn "no known DNS flush tool on this host"

if it_need nmcli; then
  DEV="$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$3=="connected"&&($2=="ethernet"||$2=="wifi"){print $1; exit}')"
  if [[ -n "${DEV:-}" ]]; then
    sudo nmcli device reapply "$DEV" && it_ok "nmcli reapply $DEV"
  else
    it_warn "no connected ethernet/wifi via nmcli"
  fi
elif it_need dhclient; then
  sudo dhclient -r && sudo dhclient && it_ok "dhclient renew"
elif [[ "$(uname -s)" == "Darwin" ]]; then
  SVC="$(networksetup -listallnetworkservices 2>/dev/null | awk 'NR>1 && !/^\*/{print; exit}')"
  if [[ -n "${SVC:-}" ]]; then
    networksetup -setdhcp "$SVC" && it_ok "DHCP renew ($SVC)"
  fi
else
  it_warn "no DHCP renew tool found"
fi

it_section "AFTER"
measure
A_PING="$M_PING" A_HTTP="$M_HTTP" A_GW="${M_GW:-none}"

it_section "Delta"
it_info "ICMP  ${B_PING} → ${A_PING}"
it_info "HTTPS ${B_HTTP} → ${A_HTTP}"
it_info "GW    ${B_GW} → ${A_GW}"

if [[ "$A_HTTP" =~ ^[23] ]]; then
  it_ok "path healthy after reset — no reboot required"
  exit 0
fi
it_fail "still broken after stack reset"
echo "  Next: ./why-broken.sh && ./escalate-smart.sh"
exit 1
