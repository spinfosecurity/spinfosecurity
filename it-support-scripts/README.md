# IT Support Scripts

Small, readable **Bash** and **PowerShell** helpers for day-to-day IT Services work: network triage, health checks, ticket-ready diagnostics, DNS/DHCP refresh, and new-hire onboarding checklists.

Aimed at second-line troubleshooting — clear ticket notes, safe defaults, and docs a teammate can reuse.

| Script | Bash | PowerShell | Purpose |
|--------|------|------------|---------|
| Network diagnostics | `bash/network-diag.sh` | `powershell/Network-Diag.ps1` | IP, gateway, DNS, reachability — paste into a ticket |
| System health | `bash/system-health.sh` | `powershell/System-Health.ps1` | OS, uptime, CPU/RAM/disk snapshot |
| Support bundle | `bash/collect-support-bundle.sh` | `powershell/Collect-SupportBundle.ps1` | One folder of diagnostics for escalation |
| DNS / DHCP renew | `bash/dns-renew.sh` | `powershell/Dns-Renew.ps1` | Flush DNS cache; optional DHCP renew |
| Onboard checklist | `bash/onboard-checklist.sh` | `powershell/Onboard-Checklist.ps1` | Guided new-hire setup checklist (log for KB/tickets) |

## Design

- **Simple** — one job per script; easy to read in an interview
- **Functional** — real commands techs use daily (no toy placeholders)
- **Safe by default** — diagnostics are read-only; renew scripts warn before changing network state
- **Ticket-friendly** — timestamps and labeled sections for ServiceNow / Jira paste

## Quick start

```bash
# Linux / macOS
chmod +x bash/*.sh
./bash/network-diag.sh
./bash/system-health.sh
./bash/collect-support-bundle.sh
./bash/dns-renew.sh          # flush only
./bash/dns-renew.sh --renew  # flush + DHCP renew
./bash/onboard-checklist.sh "Ada Lovelace"
```

```powershell
# Windows (PowerShell 5.1+ or 7+)
Set-ExecutionPolicy -Scope Process Bypass
.\powershell\Network-Diag.ps1
.\powershell\System-Health.ps1
.\powershell\Collect-SupportBundle.ps1
.\powershell\Dns-Renew.ps1
.\powershell\Dns-Renew.ps1 -Renew
.\powershell\Onboard-Checklist.ps1 -UserName "Ada Lovelace"
```

## Docs

- [FOR-EMPLOYERS.md](FOR-EMPLOYERS.md) — why these scripts, mapped to IT Services responsibilities
- Inline usage: `./script.sh --help` or `Get-Help .\Script.ps1`

## Safety

These scripts are for **authorized systems you support**. They do not require domain admin rights. DHCP renew and DNS flush may briefly interrupt connectivity — use during a maintenance window or with the user present.

## License

MIT — use, fork, and adapt for your helpdesk.
