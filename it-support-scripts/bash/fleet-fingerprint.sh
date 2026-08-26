#!/usr/bin/env bash
# fleet-fingerprint — one-line correlation ID for "is this a fleet incident?"
# First principle: one broken laptop is noise; 40 identical fingerprints is a change failure.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
fleet-fingerprint — emit a compact, comparable machine signal.

Usage:
  ./fleet-fingerprint.sh          # human + hash
  ./fleet-fingerprint.sh --json   # machine-readable
EOF
  exit 0
fi

JSON=0
[[ "${1:-}" == "--json" ]] && JSON=1

os="unknown"; ver="unknown"; kern="$(uname -r 2>/dev/null || echo unknown)"
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  os="${ID:-linux}"; ver="${VERSION_ID:-}"
elif [[ "$(uname -s)" == "Darwin" ]]; then
  os="macos"; ver="$(sw_vers -productVersion 2>/dev/null || true)"
fi

dns="$(awk '/^nameserver/{print $2; exit}' /etc/resolv.conf 2>/dev/null || echo none)"
gw="$(ip route show default 2>/dev/null | awk '/default/{print $3; exit}' || route -n 2>/dev/null | awk '$1=="0.0.0.0"{print $2; exit}' || echo none)"
wifi="none"
if it_need iwgetid; then wifi="$(iwgetid -r 2>/dev/null || echo none)"; fi
if [[ "$(uname -s)" == "Darwin" ]]; then
  wifi="$(networksetup -getairportnetwork en0 2>/dev/null | sed 's/Current Wi-Fi Network: //' || echo none)"
fi
vpn="no"
if ip link 2>/dev/null | grep -qiE 'tun|utun|wg|ppp|tailscale'; then vpn="yes"; fi
if ifconfig 2>/dev/null | grep -qiE 'utun|tun|wg'; then vpn="yes"; fi

# package/client hints (best-effort)
clients=""
for c in zoom slack teams code docker; do
  it_need "$c" && clients+="${c},"
done
clients="${clients%,}"

payload="os=${os}|ver=${ver}|kern=${kern}|dns=${dns}|gw_octet=${gw##*.}|wifi=${wifi}|vpn=${vpn}|clients=${clients}"
hash="$(printf '%s' "$payload" | sha256sum 2>/dev/null | awk '{print $1}' | cut -c1-16)"
[[ -z "$hash" ]] && hash="$(printf '%s' "$payload" | shasum -a 256 2>/dev/null | awk '{print $1}' | cut -c1-16)"

if [[ "$JSON" -eq 1 ]]; then
  cat <<EOF
{"host":"$(it_host)","utc":"$(it_utc)","fingerprint":"$hash","signal":"$payload"}
EOF
else
  echo "# fleet-fingerprint — $(it_host) @ $(it_utc)"
  echo "fingerprint: $hash"
  echo "signal:      $payload"
  echo
  echo "Paste fingerprint into the ticket. Matching hashes across users ⇒ fleet change, not one-off."
fi
