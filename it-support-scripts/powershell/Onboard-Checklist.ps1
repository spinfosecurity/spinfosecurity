<#
.SYNOPSIS
  Guided new-hire IT checklist with a ticket-ready log.

.PARAMETER UserName
  Display name of the new hire.

.EXAMPLE
  .\Onboard-Checklist.ps1 -UserName 'Ada Lovelace'
#>
[CmdletBinding()]
param(
    [string]$UserName
)

if (-not $UserName) {
    $UserName = Read-Host 'New hire display name'
}

$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
$safe = ($UserName -replace '[^A-Za-z0-9._-]', '_')
$log = Join-Path (Get-Location) "onboard-$safe-$stamp.log"

function Ask([string]$Prompt) {
    while ($true) {
        $ans = Read-Host "$Prompt [y/n/s=skip]"
        switch -Regex ($ans) {
            '^[Yy]$' { Add-Content $log "DONE  | $Prompt"; return }
            '^[Nn]$' { Add-Content $log "OPEN  | $Prompt"; return }
            '^[Ss]$' { Add-Content $log "SKIP  | $Prompt"; return }
            default  { Write-Host 'Enter y, n, or s.' }
        }
    }
}

@"
Onboarding checklist
user=$UserName
started_utc=$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
technician=$env:USERNAME
----
"@ | Set-Content -Path $log

Write-Host ""
Write-Host "Onboarding: $UserName"
Write-Host "Log file:   $log"
Write-Host 'Answer y (done), n (still open), or s (skip/N/A).'
Write-Host ""

Ask 'Identity created (AD / IdP account)'
Ask 'MFA enrolled / verified'
Ask 'Email / Google Workspace or M365 mailbox ready'
Ask 'Groups / distribution lists assigned per role'
Ask 'Laptop imaged and enrolled in MDM'
Ask 'Disk encryption confirmed (FileVault / BitLocker)'
Ask 'VPN profile installed and tested'
Ask 'Core apps installed (browser, Office/Workspace, chat)'
Ask 'Printers / shared drives access verified'
Ask 'Security awareness / acceptable use acknowledged'
Ask 'Welcome ticket updated with asset tag + username'
Ask 'Manager notified that day-1 access is ready'

Add-Content $log '----'
Add-Content $log "finished_utc=$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))"

Write-Host ""
Write-Host "Checklist saved: $log"
Write-Host 'Attach this log to the onboarding ticket / knowledge base note.'
