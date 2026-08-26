#!/usr/bin/env bash
# escalate-smart — one-page ranked brief for L3. Evidence, not a log landfill.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
escalate-smart — paste-ready escalation brief from live probes.

Usage: ./escalate-smart.sh [outfile.md]

Runs: why-broken → auth-clock → dns-truth → reach-matrix
Writes a one-page markdown brief with ranked hypothesis + evidence.
EOF
  exit 0
fi

STAMP="$(date -u +%Y%m%d-%H%M%S)"
OUT="${1:-./escalate-${STAMP}.md}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

echo "# escalate-smart — collecting probes…"
bash "${ROOT}/bash/why-broken.sh"  >"$TMP/why.txt"   2>&1 || true
bash "${ROOT}/bash/auth-clock.sh"  >"$TMP/clock.txt" 2>&1 || true
bash "${ROOT}/bash/dns-truth.sh"   >"$TMP/dns.txt"   2>&1 || true
bash "${ROOT}/bash/reach-matrix.sh">"$TMP/reach.txt" 2>&1 || true

# Pull hypothesis block (#1 title + evidence + fix lines)
HYP="$(awk '
  /^### Ranked hypotheses/{grab=1; next}
  grab && /^  #[0-9]/{print; getline; print; getline; if ($0 ~ /fix:/) print; exit}
' "$TMP/why.txt" || true)"

VERDICT="unknown"
if grep -q 'Verdict: OS path looks workable' "$TMP/why.txt"; then
  VERDICT="OS path workable — suspect app/IdP/service"
elif grep -q 'Ranked hypotheses' "$TMP/why.txt"; then
  VERDICT="OS-path fault likely — see hypothesis #1"
fi

REACH_SUM="$(awk '/^  \[/{print}' "$TMP/reach.txt" | tail -n 3 | tr '\n' ' ')"

{
  echo "# Escalation brief"
  echo
  echo "| Field | Value |"
  echo "|-------|-------|"
  echo "| Host | $(it_host) |"
  echo "| When (UTC) | $(it_utc) |"
  echo "| Operator | ${USER:-unknown} |"
  echo "| Auto-verdict | ${VERDICT} |"
  echo
  echo "## User impact"
  echo "_Who is blocked · since when · blast radius (1 user / team / site)._"
  echo
  echo "## Ranked hypothesis"
  if [[ -n "$HYP" ]]; then
    echo '```'
    echo "$HYP"
    echo '```'
  else
    echo "_No strong OS-path signal from why-broken — suspect app/IdP/service._"
  fi
  echo
  echo "## Already tried"
  echo "- [ ] Reproduced on phone hotspot (isolates corp network)"
  echo "- [ ] \`./stack-reset.sh --apply\`"
  echo "- [ ] \`./dns-truth.sh\` reviewed"
  echo "- [ ] \`./auth-clock.sh\` skew checked"
  echo
  echo "## Reach snapshot"
  echo "${REACH_SUM:-_(see evidence)_}"
  echo
  echo "## Evidence"
  echo
  echo "<details><summary>why-broken</summary>"
  echo
  echo '```'
  cat "$TMP/why.txt"
  echo '```'
  echo
  echo "</details>"
  echo
  echo "<details><summary>auth-clock</summary>"
  echo
  echo '```'
  cat "$TMP/clock.txt"
  echo '```'
  echo
  echo "</details>"
  echo
  echo "<details><summary>dns-truth</summary>"
  echo
  echo '```'
  cat "$TMP/dns.txt"
  echo '```'
  echo
  echo "</details>"
  echo
  echo "<details><summary>reach-matrix</summary>"
  echo
  echo '```'
  cat "$TMP/reach.txt"
  echo '```'
  echo
  echo "</details>"
  echo
  echo "## Ask of L3"
  echo "_One concrete ask — e.g. check VPN ACL for user X / reset IdP session / inspect DHCP on VLAN Y._"
} >"$OUT"

echo
echo "Brief written: $OUT"
echo "Paste into the ticket. Do not attach multi-MB log zips unless L3 asks."
