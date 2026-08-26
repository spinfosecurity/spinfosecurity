#!/usr/bin/env bash
# why-broken — ranked root-cause self-triage. Open a ticket only if #1 needs a human.
# First principle: most "IT is broken" tickets are clock, DNS lies, disk, or captive portal.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
why-broken — decide what is actually broken before anyone opens a ticket.

Checks (ranked): clock skew, captive portal / DNS lies, disk pressure,
default route, resolver health, outbound HTTPS.

Usage: ./why-broken.sh
Exit: 0 = workable, 1 = likely user-blocking fault found
EOF
  exit 0
fi

IT_HYPS=()
echo "# why-broken — $(it_host) @ $(it_utc)"

# --- Clock skew (SSO/Kerberos killer) ---
it_section "Clock"
skew_s=""
if it_need timedatectl; then
  timedatectl show -p NTPSynchronized -p TimeUSec 2>/dev/null | sed 's/^/  /' || true
fi
# Compare local UTC epoch to Cloudflare/Google date header (no privileged NTP needed)
remote_date="$(curl -sI --max-time 3 https://1.1.1.1 2>/dev/null | awk -F': ' 'tolower($1)=="date"{print $2; exit}' | tr -d '\r')"
if [[ -n "$remote_date" ]]; then
  remote_epoch="$(date -u -d "$remote_date" +%s 2>/dev/null || date -u -j -f '%a, %d %b %Y %H:%M:%S %Z' "$remote_date" +%s 2>/dev/null || echo "")"
  local_epoch="$(date -u +%s)"
  if [[ -n "$remote_epoch" ]]; then
    skew_s=$(( local_epoch - remote_epoch ))
    abs=${skew_s#-}
    it_info "skew vs edge clock: ${skew_s}s"
    if [[ "$abs" -gt 120 ]]; then
      it_fail "clock skew ${skew_s}s — auth will flake"
      it_hyp_add 1 "Clock skew" "local differs from edge by ${skew_s}s (>120s breaks Kerberos/SSO)"
    else
      it_ok "clock within ${abs}s"
    fi
  fi
else
  it_warn "could not sample remote clock (offline or blocked)"
fi

# --- Captive portal / DNS lie ---
it_section "DNS truth"
sys_ip="$(getent ahostsv4 example.com 2>/dev/null | awk '{print $1; exit}' || true)"
doh_ip=""
if it_need curl; then
  doh_json="$(curl -s --max-time 4 'https://cloudflare-dns.com/dns-query?name=example.com&type=A' -H 'accept: application/dns-json' 2>/dev/null || true)"
  doh_ip="$(printf '%s' "$doh_json" | sed -n 's/.*"data":"\([0-9.]*\)".*/\1/p' | head -n1)"
fi
it_info "system resolver → ${sys_ip:-none}"
it_info "DoH ground truth → ${doh_ip:-none}"
if [[ -n "$sys_ip" && -n "$doh_ip" && "$sys_ip" != "$doh_ip" ]]; then
  # example.com has multiple A records — only flag if system returns RFC1918/CGNAT/captive-ish
  case "$sys_ip" in
    10.*|192.168.*|172.1[6-9].*|172.2[0-9].*|172.3[0-1].*|100.64.*|127.*|0.0.0.0)
      it_fail "resolver returned private/captive address for public name"
      it_hyp_add 1 "Captive portal or DNS hijack" "system=$sys_ip doh=$doh_ip"
      ;;
    *)
      it_warn "A-record mismatch (may be multi-CDN); not conclusive"
      ;;
  esac
elif [[ -z "$sys_ip" ]]; then
  it_fail "system DNS returned nothing for example.com"
  it_hyp_add 1 "DNS failure" "getent/example.com empty"
else
  it_ok "resolver answers for example.com"
fi

# --- Captive portal probe ---
portal="$(curl -s --max-time 4 -o /dev/null -w '%{http_code}' http://connectivitycheck.gstatic.com/generate_204 2>/dev/null || echo 000)"
if [[ "$portal" != "204" && "$portal" != "000" ]]; then
  it_fail "captive portal signal (HTTP $portal on generate_204)"
  it_hyp_add 1 "Captive portal" "generate_204 returned HTTP $portal (want 204)"
elif [[ "$portal" == "204" ]]; then
  it_ok "no captive portal"
fi

# --- Disk ---
it_section "Disk pressure"
root_use="$(df -P / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}')"
if [[ -n "$root_use" ]]; then
  it_info "/ at ${root_use}%"
  if [[ "$root_use" -ge 95 ]]; then
    it_fail "root filesystem critically full"
    it_hyp_add 1 "Disk full" "/ at ${root_use}%"
  elif [[ "$root_use" -ge 85 ]]; then
    it_warn "root filesystem high"
    it_hyp_add 2 "Disk pressure" "/ at ${root_use}%"
  else
    it_ok "disk headroom OK"
  fi
fi

# --- Default route ---
it_section "Path"
gw=""
if it_need ip; then
  gw="$(ip route show default 2>/dev/null | awk '/default/{print $3; exit}' || true)"
else
  gw="$(route -n 2>/dev/null | awk '$1=="0.0.0.0"{print $2; exit}' || true)"
fi
if [[ -z "$gw" ]]; then
  it_fail "no default route"
  it_hyp_add 1 "No default route" "machine is islanded"
else
  it_ok "default gateway $gw"
fi

# --- Outbound HTTPS ---
code="$(curl -s --max-time 5 -o /dev/null -w '%{http_code}' https://example.com 2>/dev/null || echo 000)"
if [[ "$code" =~ ^[23] ]]; then
  it_ok "outbound HTTPS works ($code)"
else
  it_fail "outbound HTTPS broken ($code)"
  it_hyp_add 1 "Outbound HTTPS blocked/broken" "example.com → HTTP $code"
fi

it_hyp_print
if [[ ${#IT_HYPS[@]} -gt 0 ]]; then
  echo
  echo "Next: fix #1, re-run. If still red → ./escalate-smart.sh"
  exit 1
fi
echo
echo "Verdict: workable. If an app still fails, it is probably the app — not the OS path."
exit 0
