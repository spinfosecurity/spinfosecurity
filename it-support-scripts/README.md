# IT Triage Toolkit (PowerShell)

Second-line style helpers for Windows endpoints: diagnose, fix safely, prove it, escalate cleanly.

| Script | What it does |
|--------|----------------|
| [`Why-Broken.ps1`](powershell/Why-Broken.ps1) | Checks clock, DNS honesty, disk, gateway, and HTTPS — ranks what to fix first |
| [`Dns-Truth.ps1`](powershell/Dns-Truth.ps1) | Compares Windows DNS to Cloudflare public DNS (captive portal / hijack signals) |
| [`Auth-Clock.ps1`](powershell/Auth-Clock.ps1) | Measures clock skew (common “wrong password” / SSO cause); optional resync |
| [`Reach-Matrix.ps1`](powershell/Reach-Matrix.ps1) | Tests TCP reachability to critical services — path problem vs app problem |
| [`Stack-Reset.ps1`](powershell/Stack-Reset.ps1) | Flushes DNS and renews DHCP with before/after proof (prefer over reboot) |
| [`Escalate-Smart.ps1`](powershell/Escalate-Smart.ps1) | Builds a one-page escalation brief: impact, hypothesis, tried steps, one ask |

## Workflow

```
Why-Broken  →  fix #1  →  re-run
    │
    ├─ DNS looks wrong   →  Dns-Truth
    ├─ Login / SSO flaky →  Auth-Clock -Fix
    ├─ “Is it the network?” →  Reach-Matrix
    └─ Still broken      →  Stack-Reset -Apply  →  Escalate-Smart
```

## Run

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd it-support-scripts
Copy-Item targets.example.conf targets.conf   # point at your real services
.\powershell\Why-Broken.ps1
.\powershell\Escalate-Smart.ps1
```

Edit `targets.conf` for Reach-Matrix (GitHub, IdP, chat, internal apps — whatever your environment needs).

## Design notes

See [PRINCIPLES.md](PRINCIPLES.md).

## Safety

Use on systems you are authorized to support. Diagnostics are read-only until you pass `-Apply` or `-Fix`. These scripts do not change Active Directory or IdP accounts.

## License

MIT
