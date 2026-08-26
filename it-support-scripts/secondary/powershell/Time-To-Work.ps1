<#
.SYNOPSIS
  Timed onboarding — measure minutes-to-productive, not checkbox theater.
#>
[CmdletBinding()]
param([string]$UserName)
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
if (-not $UserName) { $UserName = Read-Host 'New hire display name' }

$start = Get-Date
$safe = ($UserName -replace '[^A-Za-z0-9._-]','_')
$log = Join-Path (Get-Location) ("ttw-$safe-{0:yyyyMMdd-HHmmss}.log" -f [DateTime]::UtcNow)

@"
time-to-work
user=$UserName
start_utc=$(Get-ItUtc)
technician=$env:USERNAME
----
"@ | Set-Content $log

function Ask([string]$Prompt, [int]$Critical = 0) {
    $t = [int]((Get-Date) - $start).TotalSeconds
    while ($true) {
        $ans = Read-Host "[+${t}s] $Prompt  (y=done / n=blocked / s=skip)"
        $t = [int]((Get-Date) - $start).TotalSeconds
        switch -Regex ($ans) {
            '^[Yy]$' { Add-Content $log "DONE  t=+${t}s  critical=$Critical  | $Prompt"; return }
            '^[Nn]$' {
                Add-Content $log "BLOCK t=+${t}s  critical=$Critical  | $Prompt"
                if ($Critical -eq 1) { Write-ItFail "critical path blocked at +${t}s" }
                return
            }
            '^[Ss]$' { Add-Content $log "SKIP  t=+${t}s  critical=$Critical  | $Prompt"; return }
            default { Write-Host 'y / n / s' }
        }
    }
}

Write-Host "# time-to-work — $UserName"
Write-Host "Log: $log"
Ask 'IdP/AD account live + MFA' 1
Ask 'Laptop enrolled + BitLocker verified' 1
Ask 'VPN connects (or not required on corp LAN)' 1
Ask 'Can reach IdP + email + chat' 1
Ask 'Git/code forge auth works' 1
Ask 'Clone + build assigned repo succeeds' 1
Ask 'Printers / shared drives' 0
Ask 'Meeting AV preflight cleared' 0
Ask 'Manager notified + asset tag in ticket' 0

$total = [int]((Get-Date) - $start).TotalSeconds
Add-Content $log '----'
Add-Content $log "end_utc=$(Get-ItUtc)"
Add-Content $log "total_seconds=$total"
Write-ItSection 'Score'
Write-Host ("  wall_clock: {0:N1} minutes" -f ($total/60.0))
Write-Host "  log:        $log"
Write-Host 'Elite bar: critical path < 60 minutes. If higher, the process is the bug.'
