#!/usr/bin/env bash
# meeting-preflight — gate the all-hands before it fails live.
# First principle: AV + uplink failures are preventable with a 10-second preflight.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
meeting-preflight — mic/cam presence + uplink quality before joining.

Usage: ./meeting-preflight.sh
EOF
  exit 0
fi

echo "# meeting-preflight — $(it_host) @ $(it_utc)"
IT_HYPS=()
fail=0

it_section "Devices"
# Linux
if [[ -d /dev/snd ]] || it_need pactl; then
  if it_need pactl; then
    sinks="$(pactl list short sinks 2>/dev/null | wc -l | tr -d ' ')"
    sources="$(pactl list short sources 2>/dev/null | wc -l | tr -d ' ')"
    it_info "pulse sinks=$sinks sources=$sources"
    [[ "$sources" -lt 1 ]] && { it_fail "no audio input"; it_hyp_add 1 "No microphone" "pulse sources=0"; fail=1; }
    [[ "$sinks" -lt 1 ]] && { it_fail "no audio output"; it_hyp_add 1 "No speakers/headset" "pulse sinks=0"; fail=1; }
  else
    it_info "ALSA present"
  fi
fi
if [[ "$(uname -s)" == "Darwin" ]]; then
  system_profiler SPCameraDataType 2>/dev/null | head -n 20 | sed 's/^/  /' || it_warn "no camera data"
  system_profiler SPAudioDataType 2>/dev/null | head -n 20 | sed 's/^/  /' || true
fi
# Video nodes on Linux
if [[ -e /dev/video0 ]]; then
  it_ok "camera node /dev/video0"
else
  if [[ "$(uname -s)" == "Linux" ]]; then
    it_warn "no /dev/video0 (OK on headless; fail this if user needs video)"
  fi
fi

it_section "Uplink (video-call grade)"
# Rough MOS-ish: latency + loss to a public HTTPS edge
pout="$(ping -c 10 -W 2 1.1.1.1 2>/dev/null || ping -c 10 -w 2 1.1.1.1 2>/dev/null || true)"
if grep -q 'bytes from' <<<"$pout"; then
  avg="$(awk -F'/' '/rtt|round-trip/{print $5; exit}' <<<"$pout")"
  loss="$(echo "$pout" | grep -oE '[0-9]+% packet loss' | head -1 | tr -dc '0-9')"
  loss="${loss:-0}"
  it_info "rtt_avg=${avg}ms loss=${loss}%"
  # thresholds tuned for calls, not bulk transfer
  avg_int="${avg%%.*}"
  if [[ "${avg_int:-999}" -gt 150 || "${loss}" -gt 2 ]]; then
    it_fail "uplink not meeting-grade"
    it_hyp_add 1 "Poor uplink for A/V" "rtt=${avg}ms loss=${loss}%"
    fail=1
  else
    it_ok "uplink acceptable for A/V"
  fi
else
  it_fail "no ICMP to edge"
  it_hyp_add 1 "Network down" "ping 1.1.1.1 failed"
  fail=1
fi

tls="$(curl -s --max-time 5 -o /dev/null -w '%{time_connect}' https://example.com 2>/dev/null || echo FAIL)"
it_info "tls_connect=${tls}s"
if [[ "$tls" == "FAIL" ]]; then
  it_fail "HTTPS path broken"
  fail=1
fi

it_section "CPU headroom"
if it_need uptime; then
  load="$(awk '{print $1}' /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | tr -d ' ')"
  cpus="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)"
  it_info "load1=${load} cpus=${cpus}"
fi

it_hyp_print
if [[ "$fail" -eq 1 ]]; then
  echo
  echo "Do not join yet. Fix #1, re-run. Escalation: attach this output."
  exit 1
fi
echo
echo "Verdict: clear to join."
exit 0
