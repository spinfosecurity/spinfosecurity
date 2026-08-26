<#
.SYNOPSIS
  Measure clock skew vs edge clocks; optionally sync (SSO/Kerberos killer).
#>
[CmdletBinding()]
param([switch]$Fix)
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
Reset-ItHyps

Write-Host "# auth-clock — $env:COMPUTERNAME @ $(Get-ItUtc)"
Write-ItSection 'Local'
Write-ItInfo "utc $(Get-ItUtc)"

Write-ItSection 'Edge samples'
$skews = @()
foreach ($url in @('https://1.1.1.1','https://www.google.com','https://www.cloudflare.com')) {
    $s = Get-ItEdgeSkewSeconds $url
    if ($null -ne $s) {
        $skews += $s
        Write-ItInfo ("{0,-32} skew={1}s" -f $url, $s)
    } else { Write-ItWarn "$url unreachable" }
}
if (-not $skews) { Write-ItFail 'no edge samples'; exit 1 }

$mid = ($skews | Sort-Object)[[int]($skews.Count / 2)]
$abs = [math]::Abs($mid)
Write-ItSection 'Verdict'
Write-ItInfo "representative skew ${mid}s (median of $($skews.Count) samples)"
if ($abs -gt 120) {
    Write-ItFail "skew ${mid}s — auth intermittent"
    Add-ItHyp 1 'Clock skew' "${mid}s vs edge" '.\Auth-Clock.ps1 -Fix'
} elseif ($abs -gt 30) {
    Write-ItWarn "skew ${mid}s"
    Add-ItHyp 3 'Mild clock skew' "${mid}s" 'ensure Windows Time service healthy'
} else { Write-ItOk 'clock healthy (≤30s)' }

if ($Fix -and $abs -gt 30) {
    Write-ItSection 'Fix'
    Start-Service W32Time -EA SilentlyContinue
    w32tm /resync /force 2>$null
    Write-ItOk 'requested w32tm resync — re-run without -Fix'
}
Write-ItHyps
if ($abs -gt 120) { exit 1 }
