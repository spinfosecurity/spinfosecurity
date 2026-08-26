#!/usr/bin/env bash
# why-broken — ranked root-cause self-triage. Ticket only if #1 needs a human.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
why-broken — decide what is actually broken before anyone opens a ticket.

Probes (in order): clock skew → DNS honesty → captive portal → disk →
default route → outbound HTTPS.

Usage:  ./why-broken.sh
Exit:   0 = workable OS path
        1 = user-blocking fault found (see hypothesis #1)
EOF
  exit 0
fi

IT_HYPS=()
echo "# why-broken — $(it_host) @ $(it_utc)"

# --- 1. Clock (SSO/Kerberos killer) ---
it_section "1. Clock"
skew="$(it_edge_skew_s https://1.1.1.1 || true)"
if [[ -z "$skew" ]]; then
  skew="$(it_edge_skew_s https://www.cloudflare.com || true)"
fi
if [[ -n "$skew" ]]; then
  abs=${skew#-}
  it_info "skew vs edge: ${skew}s"
  if [[ "$abs" -gt 120 ]]; then
    it_fail "clock skew ${skew}s — auth will flake"
    it_hyp_add 1 "Clock skew" "local−edge = ${skew}s (>120s breaks Kerberos/SSO)" \
      "./auth-clock.sh --fix   # then re-run why-broken"
  else
    it_ok "clock within ${abs}s"
  fi
else
  it_warn "could not sample edge clock (offline or Date header blocked)"
fi

# --- 2. DNS honesty ---
it_section "2. DNS honesty"
mapfile -t SYS_IPS < <(it_resolve_system example.com)
mapfile -t DOH_IPS < <(it_resolve_doh example.com)
it_info "system → ${SYS_IPS[*]:-none}"
it_info "DoH    → ${DOH_IPS[*]:-none}"

dns_bad=0
if [[ ${#SYS_IPS[@]} -eq 0 ]]; then
  it_fail "system DNS returned nothing for example.com"
  it_hyp_add 1 "DNS failure" "no A record from OS resolver" \
    "./dns-truth.sh ; check VPN/DNS settings"
  dns_bad=1
else
  for ip in "${SYS_IPS[@]}"; do
    if it_is_private_ip "$ip"; then
      it_fail "resolver returned private/captive address $ip"
      it_hyp_add 1 "Captive portal or DNS hijack" "system=$ip doh=${DOH_IPS[*]:-n/a}" \
        "complete portal login, or ./dns-truth.sh for proof"
      dns_bad=1
      break
    fi
  done
  if [[ "$dns_bad" -eq 0 ]]; then
    it_ok "resolver returns public addresses"
  fi
fi

# --- 3. Captive portal ---
it_section "3. Captive portal"
portal="$(curl -s --max-time 4 -o /dev/null -w '%{http_code}' http://connectivitycheck.gstatic.com/generate_204 2>/dev/null || echo 000)"
case "$portal" in
  204) it_ok "no captive portal" ;;
  000) it_warn "portal probe unreachable (may be firewall; not conclusive)" ;;
  *)
    it_fail "captive portal signal (HTTP $portal, want 204)"
    it_hyp_add 1 "Captive portal" "generate_204 → HTTP $portal" \
      "open browser, complete portal, re-run"
    ;;
esac

# --- 4. Disk ---
it_section "4. Disk"
root_use="$(df -P / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}')"
if [[ -n "${root_use:-}" ]]; then
  it_info "/ at ${root_use}% used"
  if [[ "$root_use" -ge 95 ]]; then
    it_fail "root filesystem critically full"
    it_hyp_add 1 "Disk full" "/ at ${root_use}%" \
      "free space (caches/logs), then re-run"
  elif [[ "$root_use" -ge 90 ]]; then
    it_warn "root filesystem high"
    it_hyp_add 2 "Disk pressure" "/ at ${root_use}%" \
      "free ≥10% before builds/updates"
  else
    it_ok "disk headroom OK"
  fi
fi

# --- 5. Default route + HTTPS ---
it_section "5. Path"
gw="$(it_default_gw || true)"
if [[ -z "${gw:-}" ]]; then
  it_fail "no default route"
  it_hyp_add 1 "No default route" "machine is islanded" \
    "check link/Wi-Fi/VPN; ./stack-reset.sh --apply"
else
  it_ok "default gateway $gw"
fi

code="$(curl -s --max-time 5 -o /dev/null -w '%{http_code}' https://example.com 2>/dev/null || echo 000)"
if [[ "$code" =~ ^[23] ]]; then
  it_ok "outbound HTTPS works ($code)"
else
  it_fail "outbound HTTPS broken ($code)"
  it_hyp_add 1 "Outbound HTTPS blocked/broken" "example.com → HTTP $code" \
    "./reach-matrix.sh ; ./stack-reset.sh --apply"
fi

# --- Verdict ---
it_hyp_print
if [[ ${#IT_HYPS[@]} -gt 0 ]]; then
  echo
  echo "Next: apply fix for #1 → re-run ./why-broken.sh"
  echo "Still red after two cycles → ./escalate-smart.sh"
  exit 1
fi
echo
echo "Verdict: OS path looks workable."
echo "If an app still fails → ./reach-matrix.sh (path vs app), then app/IdP owners."
exit 0
