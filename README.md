# SpinfoSecurity

Defensive **OT/ICS** cybersecurity automation in **PowerShell** and **Bash**.

Portfolio: **[spinfosecurity.github.io](https://spinfosecurity.github.io/)** · Open to **OT/ICS cybersecurity** and **security automation** roles.

I build practical tools for authorized exposure discovery and analyst-ready reporting—TCP reachability checks only, not exploit frameworks.

## Featured project

| Project | What it is |
|---|---|
| [ICS OT Protector](https://github.com/spinfosecurity/ics-ot-protector) | Unified critical-infrastructure OT/SCADA scanners for water, energy, building automation (BAS), and rail — PowerShell + Bash, shared config/CI, severity-ranked JSON reports |

| Sector | Path |
|---|---|
| Water & wastewater | [`scanners/water/`](https://github.com/spinfosecurity/ics-ot-protector/tree/main/scanners/water) |
| Power grid & substation | [`scanners/energy-grid/`](https://github.com/spinfosecurity/ics-ot-protector/tree/main/scanners/energy-grid) |
| Building automation / BACnet | [`scanners/bas/`](https://github.com/spinfosecurity/ics-ot-protector/tree/main/scanners/bas) |
| Rail & transit | [`scanners/rail/`](https://github.com/spinfosecurity/ics-ot-protector/tree/main/scanners/rail) |

## What this demonstrates

- PowerShell and Bash automation for security operations workflows
- OT/ICS exposure discovery concepts (remote access + sector protocol ports)
- Structured JSON reporting for triage with IT/OT stakeholders
- Documentation, safe-operation guidance, and GitHub Actions checks

## Accurate scope

**Does:** authorized subnet TCP reachability checks, severity labels, CISA-oriented remediation pointers.  
**Does not:** credential testing, exploit payloads, config changes, or replace a penetration test.

**Authorized defensive use only.** Never run these tools without explicit asset-owner permission.
