#!/usr/bin/env bash
# secret-hygiene — stop credential spills before they become incidents.
# First principle: the cheapest breach prevention is catching tokens on the laptop.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
secret-hygiene — scan common local spill locations for high-signal secret patterns.

Usage: ./secret-hygiene.sh
Does NOT exfiltrate. Prints redacted file:line hits for the operator to remediate.
EOF
  exit 0
fi

echo "# secret-hygiene — $(it_host) @ $(it_utc)"
echo "# local scan only — results stay on this machine"
IT_HYPS=()
hits=0

PATTERNS=(
  'AKIA[0-9A-Z]{16}'
  'ghp_[A-Za-z0-9]{20,}'
  'github_pat_[A-Za-z0-9_]{20,}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  '-----BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY-----'
  'sk-live-[A-Za-z0-9]{20,}'
  'sk-proj-[A-Za-z0-9]{20,}'
  'AIza[0-9A-Za-z_-]{35}'
)

TARGETS=()
for f in \
  "$HOME/.bash_history" "$HOME/.zsh_history" "$HOME/.python_history" \
  "$HOME/.npmrc" "$HOME/.netrc" "$HOME/.aws/credentials" \
  "$HOME/.config/gh/hosts.yml" \
  "$HOME/.docker/config.json"
 do
  [[ -f "$f" ]] && TARGETS+=("$f")
done
while IFS= read -r f; do TARGETS+=("$f"); done < <(find "$HOME/Downloads" "$HOME/Desktop" -maxdepth 1 -type f \( -name '*.env' -o -name '*.pem' -o -name '*.key' -o -name '*credential*' -o -name '*secret*' \) 2>/dev/null | head -n 50)

it_section "Scan targets (${#TARGETS[@]} files)"
PAT_JOINED="$(IFS='|'; echo "${PATTERNS[*]}")"
HITFILE="$(mktemp)"; trap 'rm -f "$HITFILE"' EXIT

for f in "${TARGETS[@]:-}"; do
  sz="$(wc -c <"$f" 2>/dev/null | tr -d ' ' || echo 0)"
  [[ "${sz:-0}" -gt 2000000 ]] && continue
  if grep -nE "$PAT_JOINED" "$f" >"$HITFILE" 2>/dev/null; then
    while IFS= read -r line; do
      ln="${line%%:*}"
      rest="${line#*:}"
      redacted="$(printf '%s' "$rest" | sed -E \
        -e 's/(AKIA[0-9A-Z]{4})[0-9A-Z]+/\1********/g' \
        -e 's/(ghp_[A-Za-z0-9]{4})[A-Za-z0-9]+/\1********/g' \
        -e 's/(xox[baprs]-[A-Za-z0-9-]{4})[A-Za-z0-9-]+/\1********/g' \
        -e 's/(sk-[A-Za-z0-9_-]{4})[A-Za-z0-9_-]+/\1********/g')"
      it_fail "$f:$ln  $redacted"
      hits=$((hits + 1))
    done < "$HITFILE"
  fi
done

it_section "Verdict"
if [[ "$hits" -gt 0 ]]; then
  it_fail "$hits potential secret spill(s)"
  it_hyp_add 1 "Credential spill on endpoint" "$hits hit(s) — rotate now, then delete local copy"
  it_hyp_print
  echo
  echo "Playbook: rotate → revoke → purge file/history → document in ticket. Do not paste raw secrets into chat."
  exit 1
fi
it_ok "no high-signal spills in scanned locations"
exit 0
