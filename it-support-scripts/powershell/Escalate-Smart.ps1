<#
.SYNOPSIS
  One-page escalation brief with ranked hypotheses — not a log landfill.
#>
[CmdletBinding()]
param([string]$OutFile)
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
if (-not $OutFile) { $OutFile = ".\escalate-{0:yyyyMMdd-HHmmss}.md" -f [DateTime]::UtcNow }

Write-Host '# escalate-smart — collecting…'
$why = & (Join-Path $Root 'powershell\Why-Broken.ps1') *>&1 | Out-String
$fp  = & (Join-Path $Root 'powershell\Fleet-Fingerprint.ps1') *>&1 | Out-String
$reach = & (Join-Path $Root 'powershell\Reach-Matrix.ps1') *>&1 | Out-String
$clock = & (Join-Path $Root 'powershell\Auth-Clock.ps1') *>&1 | Out-String
$fpHash = ([regex]::Match($fp, 'fingerprint:\s*(\w+)')).Groups[1].Value

@"
# Escalation brief

| Field | Value |
|-------|-------|
| Host | $env:COMPUTERNAME |
| When (UTC) | $(Get-ItUtc) |
| Operator | $env:USERNAME |
| Fleet fingerprint | ``$fpHash`` |

## User impact
_Replace: who is blocked, since when, blast radius._

## Already tried
- [ ] Reproduced on hotspot
- [ ] Stack-Reset -Apply
- [ ] Dns-Truth
- [ ] Auth-Clock

## Evidence

### why-broken
``````
$why
``````

### auth-clock
``````
$clock
``````

### reach-matrix
``````
$reach
``````

### fleet-fingerprint
``````
$fp
``````

## Ask of L3
_One concrete ask._
"@ | Set-Content -Path $OutFile -Encoding utf8

Write-Host ""
Write-Host "Brief written: $OutFile"
Write-Host 'Paste into the ticket. Do not attach multi-MB log zips unless L3 asks.'
