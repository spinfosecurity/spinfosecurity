#!/usr/bin/env bash
# system-health.sh — OS / resource snapshot for IT tickets (read-only)
# Usage: ./system-health.sh

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
system-health.sh — uptime, OS, CPU, memory, and disk snapshot.

Usage:
  ./system-health.sh
EOF
  exit 0
fi

section() { printf '\n== %s ==\n' "$1"; }

section "Timestamp"
date -u '+%Y-%m-%dT%H:%M:%SZ'
hostname

section "Operating system"
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "${PRETTY_NAME:-unknown}"
elif command -v sw_vers >/dev/null 2>&1; then
  sw_vers
else
  uname -a
fi
uname -m
uname -r

section "Uptime / load"
uptime

section "Memory"
if command -v free >/dev/null 2>&1; then
  free -h
elif command -v vm_stat >/dev/null 2>&1; then
  # macOS-friendly summary
  vm_stat | head -n 16
  pagesize="$(pagesize 2>/dev/null || echo 4096)"
  free_pages="$(vm_stat | awk '/Pages free/ {gsub(/\./,"",$3); print $3}')"
  if [[ -n "${free_pages}" ]]; then
    awk -v p="${free_pages}" -v s="${pagesize}" 'BEGIN {printf "Approx free: %.1f GiB\n", (p*s)/1024/1024/1024}'
  fi
fi

section "Disk"
df -h -x tmpfs -x devtmpfs -x squashfs 2>/dev/null | head -n 20 || df -h 2>/dev/null | head -n 20

section "Top CPU processes"
if command -v ps >/dev/null 2>&1; then
  if ps aux --sort=-%cpu >/dev/null 2>&1; then
    ps aux --sort=-%cpu | head -n 9
  else
    ps -Ao pid,pcpu,pmem,comm -r 2>/dev/null | head -n 9 || ps aux | head -n 9
  fi
fi

echo
echo "Done. Attach or paste into the incident ticket."
