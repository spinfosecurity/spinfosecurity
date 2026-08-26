#!/usr/bin/env bash
# dns-renew.sh — flush DNS cache; optional DHCP renew (common L1/L2 fix)
# Usage: ./dns-renew.sh [--renew]

set -euo pipefail

RENEW=0
for arg in "$@"; do
  case "$arg" in
    -h|--help)
      cat <<'EOF'
dns-renew.sh — flush local DNS cache; optionally renew DHCP lease.

Usage:
  ./dns-renew.sh           # flush DNS only
  ./dns-renew.sh --renew   # flush DNS + renew DHCP (may briefly drop connectivity)

Requires appropriate privileges for some platforms (sudo).
EOF
      exit 0
      ;;
    --renew) RENEW=1 ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

section() { printf '\n== %s ==\n' "$1"; }

section "Before"
date -u '+%Y-%m-%dT%H:%M:%SZ'
if [[ -f /etc/resolv.conf ]]; then
  grep '^nameserver' /etc/resolv.conf || true
fi

section "Flush DNS cache"
flushed=0
if command -v resolvectl >/dev/null 2>&1; then
  sudo resolvectl flush-caches && flushed=1
elif command -v systemd-resolve >/dev/null 2>&1; then
  sudo systemd-resolve --flush-caches && flushed=1
elif [[ "$(uname -s)" == "Darwin" ]]; then
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder
  flushed=1
elif command -v nscd >/dev/null 2>&1; then
  sudo service nscd reload 2>/dev/null || sudo systemctl reload nscd 2>/dev/null || true
  flushed=1
fi

if [[ "$flushed" -eq 1 ]]; then
  echo "DNS cache flush attempted."
else
  echo "No known DNS flush method on this host; resolv.conf still applies."
fi

if [[ "$RENEW" -eq 1 ]]; then
  section "DHCP renew"
  echo "Renewing DHCP lease (connectivity may flicker)..."
  if command -v nmcli >/dev/null 2>&1; then
    # Renew on the first connected ethernet/wifi device
    DEV="$(nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: '$3=="connected" && ($2=="ethernet"||$2=="wifi"){print $1; exit}')"
    if [[ -n "${DEV}" ]]; then
      sudo nmcli device reapply "${DEV}" || sudo nmcli connection up "$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v d="$DEV" '$2==d{print $1; exit}')"
    else
      echo "No active ethernet/wifi device found via nmcli."
    fi
  elif command -v dhclient >/dev/null 2>&1; then
    sudo dhclient -r && sudo dhclient
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    SERVICE="$(networksetup -listallnetworkservices | awk 'NR>1 && !/^\*/{print; exit}')"
    if [[ -n "${SERVICE}" ]]; then
      sudo ipconfig set "${SERVICE}" DHCP 2>/dev/null || networksetup -setdhcp "${SERVICE}"
    fi
  else
    echo "No nmcli/dhclient/networksetup renew path found."
  fi
else
  echo
  echo "DNS flush only. Pass --renew to also renew DHCP."
fi

section "After — quick check"
ping -c 2 -W 2 1.1.1.1 2>/dev/null || ping -c 2 1.1.1.1 2>/dev/null || echo "Probe failed; verify cable/Wi-Fi/VPN."
echo "Done."
