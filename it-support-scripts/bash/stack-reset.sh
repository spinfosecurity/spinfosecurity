#!/usr/bin/env bash
# stack-reset — idempotent network heal with before/after proof. Not a reboot.
# First principle: cargo-cult reboot hides root cause; measure → fix → prove.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

APPLY=0
for a in "$@"; do
  case "$a" in
    -h|--help)
      cat <<'EOF'
stack-reset — flush DNS + renew DHCP + re-check path. Proves delta.

Usage:
  ./stack-reset.sh          # dry-run: show plan + before metrics
  ./stack-reset.sh --apply  # perform heal + after metrics
EOF
      exit 0
      ;;
    --apply) APPLY=1 ;;
  esac
done

# Sets globals: M_GW M_PING M_HTTP
measure() {
  M_GW="$(ip route show default 2>/dev/null | awk '/default/{print $3; exit}' || route -n 2>/dev/null | awk '$1=="0.0.0.0"{print $2; exit}' || true)"
  M_PING="$(it_ms_ping 1.1.1.1 3 2>/dev/null || echo FAIL)"
  M_HTTP="$(curl -s --max-time 5 -o /dev/null -w '%{http_code}' https://example.com 2>/dev/null || echo 000)"
  it_info "gateway=${M_GW:-none}  icmp_1.1.1.1=${M_PING}ms  https_example=${M_HTTP}"
}

echo "# stack-reset — $(it_host) @ $(it_utc)"
it_section "BEFORE"
measure
BEFORE_PING="$M_PING" BEFORE_HTTP="$M_HTTP" BEFORE_GW="${M_GW:-none}"

if [[ "$APPLY" -eq 0 ]]; then
  it_section "Plan (dry-run)"
  echo "  1. flush local DNS caches"
  echo "  2. renew DHCP on active interface"
  echo "  3. re-probe ICMP + HTTPS"
  echo
  echo "Re-run with --apply to execute. Prefer this over reboot."
  exit 0
fi

it_section "Apply"
if it_need resolvectl; then
  sudo resolvectl flush-caches && it_ok "resolvectl flush-caches"
elif [[ "$(uname -s)" == "Darwin" ]]; then
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder
  it_ok "macOS DNS flush"
else
  it_warn "no known DNS flush tool"
fi

if it_need nmcli; then
  DEV="$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$3=="connected"&&($2=="ethernet"||$2=="wifi"){print $1; exit}')"
  if [[ -n "$DEV" ]]; then
    sudo nmcli device reapply "$DEV" && it_ok "nmcli reapply $DEV"
  fi
elif it_need dhclient; then
  sudo dhclient -r && sudo dhclient && it_ok "dhclient renew"
elif [[ "$(uname -s)" == "Darwin" ]]; then
  SVC="$(networksetup -listallnetworkservices 2>/dev/null | awk 'NR>1 && !/^\*/{print; exit}')"
  [[ -n "$SVC" ]] && networksetup -setdhcp "$SVC" && it_ok "DHCP renew $SVC"
fi

it_section "AFTER"
measure
AFTER_PING="$M_PING" AFTER_HTTP="$M_HTTP" AFTER_GW="${M_GW:-none}"

it_section "Delta"
it_info "ICMP ${BEFORE_PING} → ${AFTER_PING}"
it_info "HTTPS ${BEFORE_HTTP} → ${AFTER_HTTP}"
it_info "GW ${BEFORE_GW} → ${AFTER_GW}"
if [[ "$AFTER_HTTP" =~ ^[23] ]]; then
  it_ok "path restored or still healthy — no reboot required"
else
  it_fail "still broken after stack reset → escalate-smart / L3"
  exit 1
fi
