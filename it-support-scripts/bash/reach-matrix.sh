#!/usr/bin/env bash
# reach-matrix — is IT blocking the path, or is the app broken?
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
reach-matrix — parallel TCP reachability for critical services.

Usage: ./reach-matrix.sh [targets.conf]

Exit: 0 = all TCP targets open · 1 = one or more blocked
Configure real services in targets.conf (see targets.example.conf).
EOF
  exit 0
fi

CONF="${1:-$(it_targets_file "$ROOT")}"
echo "# reach-matrix — $(it_host) @ $(it_utc)"
echo "# targets: $CONF"
printf '\n%-18s %-28s %-6s %s\n' "SERVICE" "ENDPOINT" "PORT" "RESULT"
printf '%-18s %-28s %-6s %s\n' "-------" "--------" "----" "------"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
idx=0
while IFS='|' read -r name host port proto; do
  [[ -z "${name:-}" || "$name" =~ ^[[:space:]]*# ]] && continue
  [[ "$proto" != "tcp" ]] && continue
  idx=$((idx + 1))
  (
    start_ms="$(date +%s%3N 2>/dev/null || python3 -c 'import time;print(int(time.time()*1000))')"
    if it_tcp_check "$host" "$port"; then
      end_ms="$(date +%s%3N 2>/dev/null || python3 -c 'import time;print(int(time.time()*1000))')"
      printf '%-18s %-28s %-6s OPEN %sms\n' "$name" "$host" "$port" "$((end_ms - start_ms))" >"$TMP/$idx"
    else
      printf '%-18s %-28s %-6s BLOCKED\n' "$name" "$host" "$port" >"$TMP/$idx"
    fi
  ) &
done < "$CONF"
wait || true

open_n=0; block_n=0
for f in $(ls "$TMP"/* 2>/dev/null | sort -V); do
  line="$(cat "$f")"
  echo "$line"
  if [[ "$line" == *OPEN* ]]; then open_n=$((open_n + 1)); else block_n=$((block_n + 1)); fi
done

echo
it_section "Summary"
it_info "open=${open_n}  blocked=${block_n}"
if [[ "$idx" -eq 0 ]]; then
  it_warn "no tcp targets in $CONF"
  exit 0
fi
if [[ "$block_n" -eq 0 ]]; then
  it_ok "all TCP targets reachable — not an OS path issue; debug app/credentials/IdP"
  exit 0
fi
if [[ "$open_n" -eq 0 ]]; then
  it_fail "nothing reachable — run ./why-broken.sh and ./stack-reset.sh --apply"
  exit 1
fi
it_fail "partial path failure — single-service ACL/outage or selective proxy filter"
it_info "escalate that service's owners with this matrix attached"
exit 1
