#!/usr/bin/env bash
# escalate-smart — one-page escalation brief with ranked hypotheses (not a log landfill).
# First principle: L3 time is scarce — send evidence + ranked cause, not a zip of noise.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

OUT="${1:-}"
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
escalate-smart — build a ranked escalation brief from live probes.

Usage:
  ./escalate-smart.sh [outfile]

Runs why-broken + fingerprints + reach sample, writes a paste-ready brief.
EOF
  exit 0
fi

STAMP="$(date -u +%Y%m%d-%H%M%S)"
OUT="${OUT:-./escalate-${STAMP}.md}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

echo "# escalate-smart — collecting…"
bash "${ROOT}/bash/why-broken.sh" >"$TMP/why.txt" 2>&1 || true
bash "${ROOT}/bash/fleet-fingerprint.sh" >"$TMP/fp.txt" 2>&1 || true
bash "${ROOT}/bash/reach-matrix.sh" >"$TMP/reach.txt" 2>&1 || true
bash "${ROOT}/bash/auth-clock.sh" >"$TMP/clock.txt" 2>&1 || true

# Extract first hypothesis line if present
HYP="$(awk '/^  #1/{print; getline; print; exit}' "$TMP/why.txt" || true)"
FP="$(awk '/^fingerprint:/{print $2; exit}' "$TMP/fp.txt" || true)"

{
  echo "# Escalation brief"
  echo
  echo "| Field | Value |"
  echo "|-------|-------|"
  echo "| Host | $(it_host) |"
  echo "| When (UTC) | $(it_utc) |"
  echo "| Operator | ${USER:-unknown} |"
  echo "| Fleet fingerprint | \`${FP:-n/a}\` |"
  echo
  echo "## User impact"
  echo "_Replace this line with: who is blocked, since when, blast radius (1 user / team / site)._"
  echo
  echo "## Ranked hypothesis"
  if [[ -n "$HYP" ]]; then
    echo '```'
    echo "$HYP"
    echo '```'
  else
    echo "_why-broken found no strong OS-path signal — suspect app/IdP/service._"
  fi
  echo
  echo "## Already tried"
  echo "- [ ] Reproduced on another network (phone hotspot)"
  echo "- [ ] stack-reset --apply"
  echo "- [ ] Confirmed not captive portal (dns-truth)"
  echo "- [ ] auth-clock skew checked"
  echo
  echo "## Evidence"
  echo
  echo "### why-broken"
  echo '```'
  cat "$TMP/why.txt"
  echo '```'
  echo
  echo "### auth-clock"
  echo '```'
  cat "$TMP/clock.txt"
  echo '```'
  echo
  echo "### reach-matrix"
  echo '```'
  cat "$TMP/reach.txt"
  echo '```'
  echo
  echo "### fleet-fingerprint"
  echo '```'
  cat "$TMP/fp.txt"
  echo '```'
  echo
  echo "## Ask of L3"
  echo "_One concrete ask — e.g. check VPN ACL for user X / reset IdP session / inspect DHCP helper on VLAN Y._"
} >"$OUT"

echo
echo "Brief written: $OUT"
echo "Paste into the ticket. Do not attach raw multi-MB log zips unless L3 asks."
