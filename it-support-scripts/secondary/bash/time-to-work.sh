#!/usr/bin/env bash
# time-to-work — onboarding that measures minutes-to-productive, not checkbox theater.
# First principle: the metric is time until the hire can ship — everything else is vanity.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
time-to-work — timed onboarding with wall-clock burn-down.

Usage: ./time-to-work.sh ["Display Name"]
EOF
  exit 0
fi

NAME="${1:-}"
[[ -z "$NAME" ]] && read -r -p "New hire display name: " NAME
SAFE="$(printf '%s' "$NAME" | tr -cs 'A-Za-z0-9._-' '_')"
START_EPOCH="$(date +%s)"
START_UTC="$(it_utc)"
LOG="./ttw-${SAFE}-$(date -u +%Y%m%d-%H%M%S).log"

{
  echo "time-to-work"
  echo "user=$NAME"
  echo "start_utc=$START_UTC"
  echo "technician=${USER:-unknown}"
  echo "----"
} >"$LOG"

elapsed() { echo $(( $(date +%s) - START_EPOCH )); }

ask() {
  local prompt="$1" critical="${2:-0}"
  local ans t
  while true; do
    t="$(elapsed)"
    read -r -p "[+${t}s] ${prompt}  (y=done / n=blocked / s=skip): " ans
    case "$ans" in
      y|Y)
        echo "DONE  t=+${t}s  critical=${critical}  | ${prompt}" >>"$LOG"
        return 0
        ;;
      n|N)
        echo "BLOCK t=+${t}s  critical=${critical}  | ${prompt}" >>"$LOG"
        if [[ "$critical" -eq 1 ]]; then
          it_fail "critical path blocked at +${t}s — swarm this, do not proceed ceremonially"
        fi
        return 0
        ;;
      s|S)
        echo "SKIP  t=+${t}s  critical=${critical}  | ${prompt}" >>"$LOG"
        return 0
        ;;
      *) echo "y / n / s" ;;
    esac
  done
}

echo "# time-to-work — $NAME"
echo "Log: $LOG"
echo "Goal: minimize wall clock to first productive action."
echo

# Critical path first — identity → device → code path
ask "IdP/AD account live + MFA" 1
ask "Laptop enrolled + disk encryption verified" 1
ask "VPN connects (or not required on corp LAN)" 1
ask "Can reach IdP + email + chat" 1
ask "Git/code forge auth works (SSH or SSO)" 1
ask "Clone + build hello-world / assigned repo succeeds" 1
# Secondary — do not block day-1 on these
ask "Printers / shared drives" 0
ask "Meeting AV preflight cleared (./meeting-preflight.sh)" 0
ask "Manager notified + asset tag in ticket" 0

TOTAL="$(elapsed)"
{
  echo "----"
  echo "end_utc=$(it_utc)"
  echo "total_seconds=$TOTAL"
  echo "total_minutes=$(awk -v t="$TOTAL" 'BEGIN{printf "%.1f", t/60}')"
} >>"$LOG"

it_section "Score"
mins="$(awk -v t="$TOTAL" 'BEGIN{printf "%.1f", t/60}')"
blocked="$(grep -c '^BLOCK' "$LOG" || true)"
echo "  wall_clock: ${mins} minutes"
echo "  blockers:   ${blocked}"
echo "  log:        $LOG"
echo
echo "Elite bar: critical path < 60 minutes. If higher, the process is the bug — fix the process."
