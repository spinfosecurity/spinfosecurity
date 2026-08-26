#!/usr/bin/env bash
# reach-matrix — "is IT blocking me, or is the app broken?"
# First principle: parallel yes/no to critical services beats serial guessing.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
reach-matrix — TCP reachability matrix for critical services.

Usage: ./reach-matrix.sh [targets.conf]
EOF
  exit 0
fi

CONF="${1:-}"
if [[ -z "$CONF" ]]; then
  [[ -f "${ROOT}/targets.conf" ]] && CONF="${ROOT}/targets.conf" || CONF="${ROOT}/targets.example.conf"
fi

echo "# reach-matrix — $(it_host) @ $(it_utc)"
echo "# $CONF"
printf '%-18s %-28s %-6s %s\n' "SERVICE" "ENDPOINT" "PORT" "RESULT"
printf '%-18s %-28s %-6s %s\n' "-------" "--------" "----" "------"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
idx=0
while IFS='|' read -r name host port proto; do
  [[ -z "${name:-}" || "$name" =~ ^# ]] && continue
  [[ "$proto" == "icmp" ]] && continue
  idx=$((idx+1))
  (
    start=$(date +%s%3N 2>/dev/null || python3 -c 'import time;print(int(time.time()*1000))')
    ok=0
    if it_need nc; then
      nc -z -w 3 "$host" "$port" 2>/dev/null && ok=1
    else
      # bash /dev/tcp
      timeout 3 bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null && ok=1 || true
    fi
    end=$(date +%s%3N 2>/dev/null || python3 -c 'import time;print(int(time.time()*1000))')
    ms=$(( end - start ))
    if [[ "$ok" -eq 1 ]]; then
      printf '%-18s %-28s %-6s %s\n' "$name" "$host" "$port" "OPEN ${ms}ms" >"$TMP/$idx"
    else
      printf '%-18s %-28s %-6s %s\n' "$name" "$host" "$port" "BLOCKED/FAIL" >"$TMP/$idx"
    fi
  ) &
done < "$CONF"
wait || true
for f in $(ls "$TMP"/* 2>/dev/null | sort -V); do cat "$f"; done

echo
it_section "How to read"
echo "  All OPEN → not a path issue; debug the app/credentials."
echo "  Cluster of FAILs on 443 → proxy/VPN/firewall; run why-broken + dns-truth."
echo "  Single FAIL → that service or its ACL — escalate to owners with this matrix."
