#!/usr/bin/env bash
# Lab-only example: slow Modbus discovery.
# Do NOT point at production OT without authorization, a change window, and OT owner approval.
set -euo pipefail

TARGET="${1:-}"
if [[ -z "${TARGET}" ]]; then
  echo "Usage: $0 <lab-host-or-cidr>" >&2
  exit 1
fi

echo "Authorized lab target only: ${TARGET}"
nmap -sT -Pn -T1 --scan-delay 200ms --max-rate 20 \
  -p 502 \
  --script modbus-discover \
  -oA "lab-modbus-$(date +%Y%m%d-%H%M%S)" \
  "${TARGET}"
