#!/usr/bin/env bash
# onboard-checklist.sh — guided new-hire IT checklist with a ticket-ready log
# Usage: ./onboard-checklist.sh ["Display Name"]

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
onboard-checklist.sh — interactive onboarding checklist; writes a completion log.

Usage:
  ./onboard-checklist.sh ["Display Name"]

Does not create AD/M365 accounts — it documents the human steps around them.
EOF
  exit 0
fi

NAME="${1:-}"
if [[ -z "$NAME" ]]; then
  read -r -p "New hire display name: " NAME
fi

STAMP="$(date -u '+%Y%m%d-%H%M%S')"
SAFE_NAME="$(printf '%s' "$NAME" | tr -cs 'A-Za-z0-9._-' '_')"
LOG="./onboard-${SAFE_NAME}-${STAMP}.log"

ask() {
  local prompt="$1"
  local ans
  while true; do
    read -r -p "${prompt} [y/n/s=skip]: " ans
    case "${ans}" in
      y|Y) echo "DONE  | ${prompt}" >> "$LOG"; return 0 ;;
      n|N) echo "OPEN  | ${prompt}" >> "$LOG"; return 0 ;;
      s|S) echo "SKIP  | ${prompt}" >> "$LOG"; return 0 ;;
      *) echo "Enter y, n, or s." ;;
    esac
  done
}

{
  echo "Onboarding checklist"
  echo "user=${NAME}"
  echo "started_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "technician=${USER:-unknown}"
  echo "----"
} > "$LOG"

echo
echo "Onboarding: ${NAME}"
echo "Log file:   ${LOG}"
echo "Answer y (done), n (still open), or s (skip/N/A)."
echo

ask "Identity created (AD / IdP account)"
ask "MFA enrolled / verified"
ask "Email / Google Workspace or M365 mailbox ready"
ask "Groups / distribution lists assigned per role"
ask "Laptop imaged and enrolled in MDM"
ask "Disk encryption confirmed (FileVault / BitLocker)"
ask "VPN profile installed and tested"
ask "Core apps installed (browser, Office/Workspace, chat)"
ask "Printers / shared drives access verified"
ask "Security awareness / acceptable use acknowledged"
ask "Welcome ticket updated with asset tag + username"
ask "Manager notified that day-1 access is ready"

{
  echo "----"
  echo "finished_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
} >> "$LOG"

echo
echo "Checklist saved: ${LOG}"
echo "Attach this log to the onboarding ticket / knowledge base note."
