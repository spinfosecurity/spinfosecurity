# IT Support Scripts

**Mission:** minimize minutes until a builder is unblocked.

Six high-ROI tools — Bash + PowerShell — that encode how strong IT people actually think: measure → rank → fix → prove → escalate only when needed.

| # | Tool | Bash | PowerShell | Job |
|---|------|------|------------|-----|
| 1 | **why-broken** | `why-broken.sh` | `Why-Broken.ps1` | Ranked root cause before a ticket |
| 2 | **dns-truth** | `dns-truth.sh` | `Dns-Truth.ps1` | OS DNS vs DoH ground truth |
| 3 | **auth-clock** | `auth-clock.sh` | `Auth-Clock.ps1` | Catch the silent SSO killer (skew) |
| 4 | **reach-matrix** | `reach-matrix.sh` | `Reach-Matrix.ps1` | Path vs app — in one glance |
| 5 | **stack-reset** | `stack-reset.sh` | `Stack-Reset.ps1` | Heal with before/after proof |
| 6 | **escalate-smart** | `escalate-smart.sh` | `Escalate-Smart.ps1` | One-page ranked L3 brief |

## Operating loop

```
why-broken ──► fix #1 ──► re-run
     │
     ├─ DNS doubt ──► dns-truth
     ├─ auth flakes ──► auth-clock [--fix]
     ├─ path vs app ──► reach-matrix
     └─ still red ──► stack-reset --apply ──► escalate-smart ──► L3
```

## Quick start

```bash
chmod +x bash/*.sh
cp targets.example.conf targets.conf   # point at your real services
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

- [PRINCIPLES.md](PRINCIPLES.md) — why these six, not twelve mediocre ones
- [FOR-EMPLOYERS.md](FOR-EMPLOYERS.md) — 5-minute review path
- [secondary/](secondary/) — lower-ROI experiments (not the interview set)

## Safety

Authorized systems only. Diagnostics are read-only. Mutations (`--apply` / `-Fix`) are explicit and proven with before/after checks. No AD/IdP writes from a laptop script.

## License

MIT
