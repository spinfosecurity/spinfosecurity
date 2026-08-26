# Principles

Written so a sharp engineer (or Elon) can reject bad IT tooling in seconds.

## 1. Optimize the real objective

The product of IT Services is **unblocked builders**.  
Not tickets closed, not KB article count, not “rebooted successfully.”

If a script does not reduce time-to-unblocked or prevent a class of outage, delete it.

## 2. Rank causes — don’t dump state

`ipconfig /all` is not diagnosis. Diagnosis is:

1. gather the minimum evidence  
2. rank hypotheses by severity × likelihood  
3. act on #1  
4. re-measure

Every triage script here ends in **ranked hypotheses**.

## 3. Prefer proof over ritual

Reboot is a ritual.  
`stack-reset` measures → changes one layer → measures again. If still broken, escalate with evidence — don’t hide the bug under a reboot.

## 4. Ground truth beats the OS story

DNS managers lie (captive portals, sinkholes, split-horizon mistakes).  
`dns-truth` compares the system resolver to an independent path (DoH).  
`auth-clock` compares local time to edge `Date` headers — because “password incorrect” is often skew.

## 5. Measure the path that matters

Pinging a public DNS IP proves almost nothing about git, SSO, or model APIs.  
`path-quality` and `reach-matrix` use a configurable target list (`targets.conf`) — your real critical path.

## 6. One-off vs fleet

If 40 laptops share a `fleet-fingerprint`, you have a change failure — not 40 tickets.  
Correlate before you heroically reimage one machine.

## 7. Onboarding is a stopwatch

Vanity: 40-item checklist.  
Signal: **minutes until clone+build works**.  
`time-to-work` timestamps every step and treats critical-path blocks as fires.

## 8. Security is local and early

The cheapest breach is the one that never leaves the laptop.  
`secret-hygiene` hunts high-signal tokens in history and config — redacted, no exfil.

## 9. Escalations must be scarce and sharp

L3 attention is expensive.  
`escalate-smart` emits a one-page brief: impact, ranked hypothesis, already-tried, evidence, **one concrete ask**. No multi-megabyte zip of noise.

## 10. Safe by construction

- Read-only by default  
- Mutations behind `--apply` / `-Apply`  
- SAFE-tier deletes only in `disk-reclaim`  
- Never write AD/IdP from a laptop script (that belongs behind IAM + change control)
