# IT Support Scripts — for employers / interviewers

This folder shows practical scripting for **IT Services / helpdesk L2** work: diagnose, document, escalate, and onboard — without over-engineering.

## Mapped to typical L2 responsibilities

| Responsibility | Script evidence |
|----------------|-----------------|
| Network triage (TCP/IP, DNS, DHCP) | `network-diag`, `dns-renew` |
| System crashes / performance context | `system-health` |
| Ticket detail + escalation package | `collect-support-bundle` |
| New-hire onboarding consistency | `onboard-checklist` |
| Knowledge base / self-service | README + `--help` on every script |
| Cross-platform (Windows + macOS/Linux) | Matching Bash and PowerShell pairs |

## What to look at first (≈5 minutes)

1. `bash/network-diag.sh` and `powershell/Network-Diag.ps1` — same workflow, two shells
2. `collect-support-bundle` — how diagnostics are packaged for Level 3
3. `onboard-checklist` — process discipline, not just tech commands

## Principles

- Prefer **readable** scripts over clever one-liners
- Prefer **safe defaults** (read-only unless the operator opts in)
- Prefer **output a tech can paste into a ticket** over flashy UI

No Active Directory write operations are included here (those belong behind change control and role-based access). The checklist documents the human steps that usually wrap AD/M365 provisioning.
