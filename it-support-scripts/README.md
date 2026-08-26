# IT Support Scripts (PowerShell)

**Mission:** get people unblocked fast.

Six PowerShell tools you can explain in plain English on a video call. Each one encodes a decision a strong helpdesk tech makes — then makes it repeatable.

| Script | One-liner you’d say to an interviewer |
|--------|--------------------------------------|
| [`Why-Broken.ps1`](powershell/Why-Broken.ps1) | “Checks the usual culprits — clock, DNS lies, disk, gateway, HTTPS — and tells you what to fix first.” |
| [`Dns-Truth.ps1`](powershell/Dns-Truth.ps1) | “Compares what Windows DNS says to Cloudflare’s public DNS so we catch captive portals and hijacks.” |
| [`Auth-Clock.ps1`](powershell/Auth-Clock.ps1) | “A lot of ‘wrong password’ tickets are just a wrong PC clock — this measures skew and can sync it.” |
| [`Reach-Matrix.ps1`](powershell/Reach-Matrix.ps1) | “Can this laptop reach the services that matter? If yes, it’s the app — not the network.” |
| [`Stack-Reset.ps1`](powershell/Stack-Reset.ps1) | “Flush DNS, renew DHCP, prove it worked — instead of the reboot ritual.” |
| [`Escalate-Smart.ps1`](powershell/Escalate-Smart.ps1) | “Builds a one-page brief for senior IT: what failed, what I tried, one clear ask.” |

## How you’d use them on a call

```
Why-Broken  →  fix #1  →  re-run
    │
    ├─ DNS looks weird  →  Dns-Truth
    ├─ login flaky      →  Auth-Clock -Fix
    ├─ “is it IT?”      →  Reach-Matrix
    └─ still broken     →  Stack-Reset -Apply  →  Escalate-Smart
```

## Run

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd it-support-scripts
Copy-Item targets.example.conf targets.conf   # edit to your real services
.\powershell\Why-Broken.ps1
.\powershell\Escalate-Smart.ps1
```

## Docs

- [PRINCIPLES.md](PRINCIPLES.md) — why these six

## Safety

Authorized machines only. Checks are read-only until you pass `-Apply` / `-Fix`. No Active Directory changes from these scripts.

## License

MIT
