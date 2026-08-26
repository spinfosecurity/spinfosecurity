#!/usr/bin/env bash
# auth-clock — find and optionally fix the silent SSO killer: clock skew.
# First principle: if time is wrong, every 'password incorrect' ticket is a lie.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

FIX=0
for a in "$@"; do
  case "$a" in
    -h|--help)
      cat <<'EOF'
auth-clock — measure skew vs edge clocks; optionally sync.

Usage:
  ./auth-clock.sh           # measure only
  ./auth-clock.sh --fix     # attempt NTP sync (may need sudo)
EOF
      exit 0
      ;;
    --fix) FIX=1 ;;
  esac
done

echo "# auth-clock — $(it_host) @ $(it_utc)"
IT_HYPS=()

sample_edge() {
  local url="$1"
  local hdr epoch
  hdr="$(curl -sI --max-time 4 "$url" 2>/dev/null | awk -F': ' 'tolower($1)=="date"{print $2; exit}' | tr -d '\r')"
  [[ -z "$hdr" ]] && return 1
  epoch="$(date -u -d "$hdr" +%s 2>/dev/null || date -u -j -f '%a, %d %b %Y %H:%M:%S %Z' "$hdr" +%s 2>/dev/null || true)"
  [[ -n "$epoch" ]] && echo "$epoch"
}

it_section "Local"
local_epoch="$(date -u +%s)"
it_info "local epoch $local_epoch ($(date -u))"
if it_need timedatectl; then
  timedatectl status 2>/dev/null | sed -n '1,12p' | sed 's/^/  /' || true
fi

it_section "Edge samples"
declare -a SKEWS=()
for url in "https://1.1.1.1" "https://www.google.com" "https://www.cloudflare.com"; do
  re="$(sample_edge "$url" || true)"
  if [[ -n "$re" ]]; then
    skew=$(( local_epoch - re ))
    SKEWS+=("$skew")
    it_info "$url skew=${skew}s"
  else
    it_warn "$url unreachable for Date header"
  fi
done

if [[ ${#SKEWS[@]} -eq 0 ]]; then
  it_fail "no edge samples — offline?"
  exit 1
fi

# median-ish: sort and pick middle
mapfile -t SORTED < <(printf '%s\n' "${SKEWS[@]}" | sort -n)
mid="${SORTED[$(( ${#SORTED[@]} / 2 ))]}"
abs=${mid#-}
it_section "Verdict"
it_info "representative skew ${mid}s"

if [[ "$abs" -gt 300 ]]; then
  it_fail "skew ${mid}s — Kerberos/SSO will fail hard"
  it_hyp_add 1 "Severe clock skew" "${mid}s vs edge"
elif [[ "$abs" -gt 120 ]]; then
  it_fail "skew ${mid}s — auth intermittent"
  it_hyp_add 1 "Clock skew" "${mid}s vs edge"
elif [[ "$abs" -gt 30 ]]; then
  it_warn "skew ${mid}s — watch for flaky MFA/SSO"
  it_hyp_add 3 "Mild clock skew" "${mid}s vs edge"
else
  it_ok "clock healthy (≤30s)"
fi

if [[ "$FIX" -eq 1 && "$abs" -gt 30 ]]; then
  it_section "Fix attempt"
  if it_need timedatectl; then
    sudo timedatectl set-ntp true
    sudo systemctl restart systemd-timesyncd 2>/dev/null || sudo systemctl restart chronyd 2>/dev/null || true
    it_info "enabled NTP; re-run to verify"
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    sudo sntp -sS time.apple.com 2>/dev/null || sudo ntpdate -u time.apple.com 2>/dev/null || it_warn "macOS sync needs Manual Date & Time off in Settings"
  else
    it_warn "no timedatectl — install chrony/ntp or sync via MDM"
  fi
fi

it_hyp_print
[[ "$abs" -gt 120 ]] && exit 1 || exit 0
