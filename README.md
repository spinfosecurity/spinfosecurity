# SpinfoSecurity

Defensive **OT/ICS** cybersecurity automation in **PowerShell** and **Bash**.

Portfolio site: **[spinfosecurity.github.io](https://spinfosecurity.github.io/)**

I build practical tools for authorized security assessment, exposure discovery, and analyst-ready reporting.

## Featured project

| Project | Use case |
|---|---|
| [ICS OT Protector](https://github.com/spinfosecurity/water-utility-protector) | Unified critical-infrastructure OT/SCADA scanners for water, energy, building automation (BAS), and rail — PowerShell + Bash, shared config/CI, JSON reports |

Sector entry points inside that monorepo:

| Sector | Path |
|---|---|
| Water & wastewater | [`scanners/water/`](https://github.com/spinfosecurity/water-utility-protector/tree/main/scanners/water) |
| Power grid & substation | [`scanners/energy-grid/`](https://github.com/spinfosecurity/water-utility-protector/tree/main/scanners/energy-grid) |
| Building automation / BACnet | [`scanners/bas/`](https://github.com/spinfosecurity/water-utility-protector/tree/main/scanners/bas) |
| Rail & transit | [`scanners/rail/`](https://github.com/spinfosecurity/water-utility-protector/tree/main/scanners/rail) |

> **Repo rename in progress:** the monorepo will become `spinfosecurity/ics-ot-protector`. GitHub will redirect the current `water-utility-protector` URL after rename. Standalone `BAS-Guardian`, `Energy-Grid-Protector`, and `Rail-OT-Protector` repos are being archived with pointers to the monorepo.

## Core capabilities

- PowerShell automation for Windows diagnostics and security operations
- OT/ICS exposure discovery and critical-infrastructure security workflows
- Network service and protocol visibility for authorized assessments
- JSON reporting for incident triage and ticketing
- GitHub Actions linting, syntax validation, and non-networked tests

## How I build

- **Defensive by design:** explicit authorization-only scope
- **Operationally aware:** safety guidance and documented limitations
- **Evidence-focused:** findings built for engineering and security triage

**Authorized defensive use only.** These projects are not exploit frameworks and must never be used without explicit asset-owner permission.
