# IT Support Scripts — first principles

**Mission:** minimize minutes until a builder is unblocked. Everything else is vanity.

These are not helpdesk wallpaper scripts (`ipconfig /all`, reboot theater, checkbox onboarding). Each tool encodes a decision rule used by strong IT people — then makes that rule runnable, ranked, and pasteable.

## The dozen

| # | Tool | Bash | PowerShell | Why it exists |
|---|------|------|------------|---------------|
| 1 | **why-broken** | `why-broken.sh` | `Why-Broken.ps1` | Ranked root cause before a ticket exists |
| 2 | **dns-truth** | `dns-truth.sh` | `Dns-Truth.ps1` | OS resolver is not ground truth — compare to DoH |
| 3 | **path-quality** | `path-quality.sh` | `Path-Quality.ps1` | Measure paths people work on, not 8.8.8.8 theater |
| 4 | **auth-clock** | `auth-clock.sh` | `Auth-Clock.ps1` | Clock skew is the silent SSO/Kerberos killer |
| 5 | **stack-reset** | `stack-reset.sh` | `Stack-Reset.ps1` | Idempotent heal with before/after proof — not reboot |
| 6 | **disk-reclaim** | `disk-reclaim.sh` | `Disk-Reclaim.ps1` | Ranked SAFE reclaim; never blind `rm -rf` |
| 7 | **meeting-preflight** | `meeting-preflight.sh` | `Meeting-Preflight.ps1` | Fail the all-hands in private, not live |
| 8 | **reach-matrix** | `reach-matrix.sh` | `Reach-Matrix.ps1` | IT path vs app failure in one glance |
| 9 | **fleet-fingerprint** | `fleet-fingerprint.sh` | `Fleet-Fingerprint.ps1` | Correlate one-off vs fleet change failure |
| 10 | **time-to-work** | `time-to-work.sh` | `Time-To-Work.ps1` | Onboarding metric = minutes to ship |
| 11 | **secret-hygiene** | `secret-hygiene.sh` | `Secret-Hygiene.ps1` | Catch token spills on the laptop before incident |
| 12 | **escalate-smart** | `escalate-smart.sh` | `Escalate-Smart.ps1` | One-page ranked brief — L3 time is scarce |

## Operating loop

```
why-broken ──► fix #1 ──► re-run
     │
     └─ still red ──► stack-reset --apply ──► escalate-smart ──► L3
```

For meetings: `meeting-preflight`  
For “is it just me?”: `fleet-fingerprint`  
For onboarding: `time-to-work` (critical path &lt; 60 min bar)

## Quick start

```bash
chmod +x bash/*.sh
cp targets.example.conf targets.conf   # edit to your real services
./bash/why-broken.sh
./bash/escalate-smart.sh
```

```powershell
Set-ExecutionPolicy -Scope Process Bypass
Copy-Item targets.example.conf targets.conf
.\powershell\Why-Broken.ps1
.\powershell\Escalate-Smart.ps1
```

## Docs

- [PRINCIPLES.md](PRINCIPLES.md) — design rules
- [FOR-EMPLOYERS.md](FOR-EMPLOYERS.md) — interview / reviewer map

## Safety

Authorized systems only. Diagnostics are read-only. `--apply` / `-Apply` mutations are explicit, bounded, and proven with before/after checks. `secret-hygiene` never exfiltrates — redacted local hits only.

## License

MIT
