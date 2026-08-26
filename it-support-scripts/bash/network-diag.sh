#!/usr/bin/env bash
# network-diag.sh — quick network triage for IT tickets (read-only)
# Usage: ./network-diag.sh [host]
# Example: ./network-diag.sh 1.1.1.1

set -euo pipefail

TARGET="${1:-1.1.1.1}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
network-diag.sh — IP, gateway, DNS, and reachability summary for tickets.

Usage:
  ./network-diag.sh [host]

Default probe host: 1.1.1.1
EOF
  exit 0
fi

section() { printf '\n== %s ==\n' "$1"; }

section "Timestamp"
date -u '+%Y-%m-%dT%H:%M:%SZ'
hostname

section "Interfaces / addressing"
if command -v ip >/dev/null 2>&1; then
  ip -br addr
  echo
  ip route | head -n 20
elif command -v ifconfig >/dev/null 2>&1; then
  ifconfig
  echo
  netstat -rn 2>/dev/null | head -n 30 || route -n get default 2>/dev/null || true
else
  echo "No ip/ifconfig available."
fi

section "DNS resolvers"
if [[ -f /etc/resolv.conf ]]; then
  grep -E '^(nameserver|search|domain)' /etc/resolv.conf || true
fi
if command -v scutil >/dev/null 2>&1; then
  scutil --dns 2>/dev/null | awk '/nameserver|domain/ {print}' | head -n 20 || true
fi

section "Gateway reachability"
GW=""
if command -v ip >/dev/null 2>&1; then
  GW="$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}' || true)"
fi
if [[ -z "${GW}" ]] && command -v route >/dev/null 2>&1; then
  # macOS BSD route
  GW="$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2; exit}' || true)"
fi
if [[ -z "${GW}" ]] && command -v route >/dev/null 2>&1; then
  # Linux net-tools
  GW="$(route -n 2>/dev/null | awk '$1=="0.0.0.0" {print $2; exit}' || true)"
fi
if [[ -z "${GW}" ]] && command -v netstat >/dev/null 2>&1; then
  GW="$(netstat -rn 2>/dev/null | awk '$1=="0.0.0.0" || $1=="default" {print $2; exit}' || true)"
fi
if [[ -n "${GW}" ]]; then
  echo "Default gateway: ${GW}"
  ping -c 2 -W 2 "${GW}" 2>/dev/null || ping -c 2 -w 2 "${GW}" 2>/dev/null || echo "Gateway ping failed or blocked."
else
  echo "Could not determine default gateway."
fi

section "External probe: ${TARGET}"
ping -c 3 -W 2 "${TARGET}" 2>/dev/null || ping -c 3 -w 2 "${TARGET}" 2>/dev/null || echo "Ping to ${TARGET} failed or blocked."

section "DNS resolution sample"
if command -v dig >/dev/null 2>&1; then
  dig +short +time=2 +tries=1 example.com A || true
  dig +short +time=2 +tries=1 example.com NS | head -n 3 || true
elif command -v nslookup >/dev/null 2>&1; then
  nslookup example.com 2>/dev/null | head -n 12 || true
elif command -v host >/dev/null 2>&1; then
  host example.com || true
else
  echo "No dig/nslookup/host available."
fi

section "Listening summary (top)"
if command -v ss >/dev/null 2>&1; then
  ss -tuln 2>/dev/null | head -n 25 || true
elif command -v netstat >/dev/null 2>&1; then
  netstat -tuln 2>/dev/null | head -n 25 || true
fi

echo
echo "Done. Paste this output into the ticket (redact hostnames if required)."
