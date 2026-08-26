# SpinfoSecurity

**PowerShell IT triage for Windows endpoints — plus defensive network tooling you can review in public code.**

[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e?style=flat-square)](it-support-scripts/LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207+-5391FE?style=flat-square&logo=powershell&logoColor=white)](it-support-scripts/)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078D4?style=flat-square&logo=windows&logoColor=white)](it-support-scripts/)
[![Focus](https://img.shields.io/badge/Focus-IT%20Services%20%2F%20Triage-0c6f74?style=flat-square)](it-support-scripts/)
[![Portfolio](https://img.shields.io/badge/Portfolio-spinfosecurity.github.io-111827?style=flat-square)](https://spinfosecurity.github.io)
[![Last commit](https://img.shields.io/github/last-commit/spinfosecurity/spinfosecurity?style=flat-square)](https://github.com/spinfosecurity/spinfosecurity/commits/main)

## IT Triage Toolkit

**[it-support-scripts](it-support-scripts/)** — second-line style PowerShell helpers:

| Script | Purpose |
|--------|---------|
| Why-Broken | Ranked endpoint triage (clock, DNS, disk, path) |
| Dns-Truth | DNS honesty vs public resolver |
| Auth-Clock | Clock skew checks (SSO / “wrong password”) |
| Reach-Matrix | Critical-service reachability (path vs app) |
| Stack-Reset | DNS/DHCP reset with before/after proof |
| Escalate-Smart | One-page escalation brief |

```powershell
cd it-support-scripts
Set-ExecutionPolicy -Scope Process Bypass
.\powershell\Why-Broken.ps1
```

## Also: ICS/OT defensive scanners

**[ICS OT Protector](https://github.com/spinfosecurity/ics-ot-protector)** — authorized TCP reachability scanners for industrial networks (water, energy, building automation, rail). Same craft: scripting, networking, structured findings, operator docs. MIT · no exploit payloads.

| Sector | Scanner |
|--------|---------|
| Water & wastewater | WUP |
| Power grid & substation | Energy Grid Protector |
| Building automation | BAS Guardian |
| Rail & transit | Rail-OT-Protector |

## Guides

- **[Nmap for ICS/OT Security](https://github.com/spinfosecurity/nmap-ot-howto)** — authorized exposure discovery with Nmap ([mirror](docs/nmap-ot-howto/README.md))

## About

Public PowerShell tools for endpoint triage, network checks, and clean escalations—plus defensive ICS/OT reachability scanners with clear authorized-use limits.

## Links

- Portfolio: https://spinfosecurity.github.io
- IT Triage Toolkit: https://github.com/spinfosecurity/spinfosecurity/tree/main/it-support-scripts
- ICS OT Protector: https://github.com/spinfosecurity/ics-ot-protector
- Advisories: https://spinfosecurity.github.io/ics-ot-advisories/
