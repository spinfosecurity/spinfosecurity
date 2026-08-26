#!/usr/bin/env bash
# collect-support-bundle.sh — gather ticket-ready diagnostics into one folder
# Usage: ./collect-support-bundle.sh [output-dir]

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
collect-support-bundle.sh — write network + health diagnostics to a folder.

Usage:
  ./collect-support-bundle.sh [output-dir]

Default output: ./support-bundle-YYYYMMDD-HHMMSS
EOF
  exit 0
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date -u '+%Y%m%d-%H%M%S')"
OUT="${1:-./support-bundle-${STAMP}}"

mkdir -p "${OUT}"

{
  echo "host=$(hostname)"
  echo "collected_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "user=${USER:-unknown}"
} > "${OUT}/meta.txt"

echo "Collecting network diagnostics..."
bash "${ROOT}/network-diag.sh" > "${OUT}/network-diag.txt" 2>&1 || true

echo "Collecting system health..."
bash "${ROOT}/system-health.sh" > "${OUT}/system-health.txt" 2>&1 || true

if command -v dmesg >/dev/null 2>&1; then
  dmesg 2>/dev/null | tail -n 200 > "${OUT}/dmesg-tail.txt" || true
fi

if [[ -d /var/log ]]; then
  # Best-effort recent syslog snippets (no secrets scraping)
  for f in /var/log/system.log /var/log/syslog /var/log/messages; do
    if [[ -r "$f" ]]; then
      tail -n 200 "$f" > "${OUT}/$(basename "$f")-tail.txt" || true
    fi
  done
fi

cat > "${OUT}/README.txt" <<EOF
Support bundle created ${STAMP} UTC
Attach this folder (or zip it) to the IT ticket before escalating to L3.

Contents:
  meta.txt           - host / time / user
  network-diag.txt   - addressing, DNS, reachability
  system-health.txt  - OS, memory, disk, top processes
  *-tail.txt         - recent log snippets when available
EOF

echo
echo "Bundle ready: ${OUT}"
echo "Zip tip:  zip -r ${OUT}.zip ${OUT}"
