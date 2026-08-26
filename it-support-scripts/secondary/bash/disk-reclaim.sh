#!/usr/bin/env bash
# disk-reclaim — ranked safe reclaim under disk pressure. No blind rm -rf.
# First principle: full disks cause mysterious build/docker/IDE failures — fix cause, keep user data.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

APPLY=0
for a in "$@"; do
  case "$a" in
    -h|--help)
      cat <<'EOF'
disk-reclaim — find reclaimable caches with safety rank; optional purge of SAFE tier.

Usage:
  ./disk-reclaim.sh           # report only
  ./disk-reclaim.sh --apply   # delete SAFE-tier caches only
EOF
      exit 0
      ;;
    --apply) APPLY=1 ;;
  esac
done

echo "# disk-reclaim — $(it_host) @ $(it_utc)"
it_section "Pressure"
df -h / 2>/dev/null | sed 's/^/  /'
root_use="$(df -P / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}')"

human_du() {
  local p="$1"
  [[ -e "$p" ]] || return 0
  du -sh "$p" 2>/dev/null | awk '{print $1"\t"$2}'
}

it_section "Ranked candidates"
printf '  %-6s %-8s %s\n' "TIER" "SIZE" "PATH"
printf '  %-6s %-8s %s\n' "----" "----" "----"

# SAFE: regenerable package/build caches
SAFE_PATHS=(
  "$HOME/.cache/pip"
  "$HOME/.cache/thumbnails"
  "$HOME/.npm/_cacache"
  "$HOME/.cargo/registry/cache"
  "$HOME/Library/Caches/com.apple.Safari"          # macOS
  "$HOME/Library/Caches/Google/Chrome/Default/Cache"
  "/tmp"
)
# CAUTION: large but may annoy (user re-download)
CAUTION_PATHS=(
  "$HOME/.cache"
  "$HOME/Downloads"
  "$HOME/.local/share/Trash"
  "$HOME/.Trash"
)
# DANGER: never auto-delete — report only
DANGER_HINTS=(
  "docker system df   # images/containers may be huge"
  "journalctl --disk-usage"
)

declare -a SAFE_FOUND=()
for p in "${SAFE_PATHS[@]}"; do
  [[ -e "$p" ]] || continue
  sz="$(du -sm "$p" 2>/dev/null | awk '{print $1}')"
  [[ -n "$sz" && "$sz" -ge 1 ]] || continue
  hs="$(du -sh "$p" 2>/dev/null | awk '{print $1}')"
  printf '  %-6s %-8s %s\n' "SAFE" "$hs" "$p"
  SAFE_FOUND+=("$p")
done
for p in "${CAUTION_PATHS[@]}"; do
  [[ -e "$p" ]] || continue
  hs="$(du -sh "$p" 2>/dev/null | awk '{print $1}')"
  printf '  %-6s %-8s %s\n' "CAUTION" "$hs" "$p"
done
for h in "${DANGER_HINTS[@]}"; do
  printf '  %-6s %-8s %s\n' "MANUAL" "-" "$h"
done

# Top space hogs in home (depth 2) — report only
it_section "Largest dirs in \$HOME (depth≤2, report only)"
du -h -d 2 "$HOME" 2>/dev/null | sort -hr | head -n 15 | sed 's/^/  /' || true

if [[ "$APPLY" -eq 1 ]]; then
  it_section "Apply SAFE purge"
  for p in "${SAFE_FOUND[@]:-}"; do
    # never wipe /tmp entirely on multiuser — clear only user-owned old files if /tmp
    if [[ "$p" == "/tmp" ]]; then
      find /tmp -user "$(id -u)" -type f -atime +3 -delete 2>/dev/null || true
      it_ok "cleared your old files in /tmp"
    else
      rm -rf "${p:?}/"* 2>/dev/null || true
      it_ok "cleared $p"
    fi
  done
  df -h / | sed 's/^/  /'
else
  echo
  it_info "Dry-run. Pass --apply to purge SAFE tier only."
fi

if [[ -n "$root_use" && "$root_use" -ge 90 ]]; then
  echo
  it_fail "still critical after review? escalate with disk-reclaim output attached"
  exit 1
fi
exit 0
