<#
.SYNOPSIS
  One-page ranked escalation brief for L3 — evidence, not a log landfill.
#>
[CmdletBinding()]
param([string]$OutFile)
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
if (-not $OutFile) { $OutFile = ".\escalate-{0:yyyyMMdd-HHmmss}.md" -f [DateTime]::UtcNow }

Write-Host '# escalate-smart — collecting probes…'
$why   = & (Join-Path $Root 'powershell\Why-Broken.ps1')   *>&1 | Out-String
$clock = & (Join-Path $Root 'powershell\Auth-Clock.ps1')   *>&1 | Out-String
$dns   = & (Join-Path $Root 'powershell\Dns-Truth.ps1')    *>&1 | Out-String
$reach = & (Join-Path $Root 'powershell\Reach-Matrix.ps1') *>&1 | Out-String

$verdict = if ($why -match 'OS path looks workable') {
    'OS path workable — suspect app/IdP/service'
} elseif ($why -match 'Ranked hypotheses') {
    'OS-path fault likely — see hypothesis #1'
} else { 'unknown' }

@"
# Escalation brief

| Field | Value |
|-------|-------|
| Host | $env:COMPUTERNAME |
| When (UTC) | $(Get-ItUtc) |
| Operator | $env:USERNAME |
| Auto-verdict | $verdict |

## User impact
_Who is blocked · since when · blast radius (1 user / team / site)._

## Already tried
- [ ] Reproduced on phone hotspot
- [ ] ``.\Stack-Reset.ps1 -Apply``
- [ ] ``.\Dns-Truth.ps1`` reviewed
- [ ] ``.\Auth-Clock.ps1`` skew checked

## Evidence

<details><summary>why-broken</summary>

``````
$why
``````

</details>

<details><summary>auth-clock</summary>

``````
$clock
``````

</details>

<details><summary>dns-truth</summary>

``````
$dns
``````

</details>

<details><summary>reach-matrix</summary>

``````
$reach
``````

</details>

## Ask of L3
_One concrete ask._
"@ | Set-Content -Path $OutFile -Encoding utf8

Write-Host ""
Write-Host "Brief written: $OutFile"
Write-Host 'Paste into the ticket. Do not attach multi-MB log zips unless L3 asks.'
