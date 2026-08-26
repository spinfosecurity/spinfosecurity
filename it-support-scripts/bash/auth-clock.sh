#!/usr/bin/env bash
# auth-clock — measure (and optionally fix) the silent SSO killer: clock skew.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

FIX=0
for a in "$@"; do
  case "$a" in
    -h|--help)
      cat <<'EOF'
auth-clock — skew vs multiple edge clocks; optional NTP sync.

Usage:
  ./auth-clock.sh         # measure
  ./auth-clock.sh --fix   # enable/sync NTP (may need sudo)

Thresholds: ≤30s OK · 31–120s watch · >120s auth will flake
EOF
      exit 0
      ;;
    --fix) FIX=1 ;;
  esac
done

echo "# auth-clock — $(it_host) @ $(it_utc)"
IT_HYPS=()

it_section "Local"
it_info "utc $(date -u '+%Y-%m-%dT%H:%M:%SZ')  epoch $(date -u +%s)"
if it_need timedatectl; then
  timedatectl status 2>/dev/null | sed -n '1,8p' | sed 's/^/  /' || true
fi

it_section "Edge samples"
declare -a SKEWS=()
for url in "https://1.1.1.1" "https://www.google.com" "https://www.cloudflare.com"; do
  s="$(it_edge_skew_s "$url" || true)"
  if [[ -n "$s" ]]; then
    SKEWS+=("$s")
    it_info "$(printf '%-32s skew=%ss' "$url" "$s")"
  else
    it_warn "$url unreachable for Date header"
  fi
done

if [[ ${#SKEWS[@]} -eq 0 ]]; then
  it_fail "no edge samples — offline or TLS intercepted without Date?"
  exit 1
fi

mapfile -t SORTED < <(printf '%s\n' "${SKEWS[@]}" | sort -n)
mid="${SORTED[$(( ${#SORTED[@]} / 2 ))]}"
abs=${mid#-}

it_section "Verdict"
it_info "representative skew ${mid}s (median of ${#SKEWS[@]} samples)"
if [[ "$abs" -gt 300 ]]; then
  it_fail "skew ${mid}s — Kerberos/SSO will fail hard"
  it_hyp_add 1 "Severe clock skew" "${mid}s vs edge" "./auth-clock.sh --fix"
elif [[ "$abs" -gt 120 ]]; then
  it_fail "skew ${mid}s — auth intermittent"
  it_hyp_add 1 "Clock skew" "${mid}s vs edge" "./auth-clock.sh --fix"
elif [[ "$abs" -gt 30 ]]; then
  it_warn "skew ${mid}s — watch for flaky MFA/SSO"
  it_hyp_add 3 "Mild clock skew" "${mid}s vs edge" "enable NTP if not managed by MDM"
else
  it_ok "clock healthy (≤30s)"
fi

if [[ "$FIX" -eq 1 && "$abs" -gt 30 ]]; then
  it_section "Fix"
  if it_need timedatectl; then
    sudo timedatectl set-ntp true
    sudo systemctl restart systemd-timesyncd 2>/dev/null || sudo systemctl restart chronyd 2>/dev/null || true
    it_ok "NTP enabled — wait 5s and re-run without --fix"
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    sudo sntp -sS time.apple.com 2>/dev/null || sudo ntpdate -u time.apple.com 2>/dev/null \
      || it_warn "turn off manual Date & Time in System Settings, then retry"
  else
    it_warn "no timedatectl — install chrony or sync via MDM"
  fi
fi

it_hyp_print
[[ "$abs" -gt 120 ]] && exit 1 || exit 0
