<#
.SYNOPSIS
  Measure clock skew vs edge clocks; optionally sync (SSO/Kerberos killer).
#>
[CmdletBinding()]
param([switch]$Fix)
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
$script:ItHyps = New-Object System.Collections.Generic.List[string]

Write-Host "# auth-clock — $env:COMPUTERNAME @ $(Get-ItUtc)"
$skews = @()
foreach ($url in @('https://1.1.1.1','https://www.google.com','https://www.cloudflare.com')) {
    try {
        $hdr = (Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 4 -UseBasicParsing).Headers.Date
        $remote = [DateTime]::Parse($hdr).ToUniversalTime()
        $skew = [int]([DateTime]::UtcNow - $remote).TotalSeconds
        $skews += $skew
        Write-ItInfo "$url skew=${skew}s"
    } catch { Write-ItWarn "$url unreachable" }
}
if (-not $skews) { Write-ItFail 'no edge samples'; exit 1 }
$mid = ($skews | Sort-Object)[[int]($skews.Count / 2)]
$abs = [math]::Abs($mid)
Write-ItSection 'Verdict'
Write-ItInfo "representative skew ${mid}s"
if ($abs -gt 120) { Write-ItFail "skew ${mid}s — auth intermittent"; Add-ItHyp 1 'Clock skew' "${mid}s vs edge" }
elseif ($abs -gt 30) { Write-ItWarn "skew ${mid}s"; Add-ItHyp 3 'Mild clock skew' "${mid}s" }
else { Write-ItOk 'clock healthy (≤30s)' }

if ($Fix -and $abs -gt 30) {
    Write-ItSection 'Fix attempt'
    Start-Service W32Time -ErrorAction SilentlyContinue
    w32tm /resync /force 2>$null
    Write-ItInfo 'requested w32tm resync; re-run to verify'
}
Write-ItHyps
if ($abs -gt 120) { exit 1 }
