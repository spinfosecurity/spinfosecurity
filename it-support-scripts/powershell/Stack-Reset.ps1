<#
.SYNOPSIS
  Idempotent network heal with before/after proof. Not a reboot.
#>
[CmdletBinding()]
param([switch]$Apply)
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')

function Get-Snap {
    $gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -EA SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1).NextHop
    $ping = Test-Connection 1.1.1.1 -Count 3 -EA SilentlyContinue
    $ms = if ($ping) { [math]::Round(($ping | Measure-Object Latency -Average).Average, 1) } else { 'FAIL' }
    try { $https = (Invoke-WebRequest https://example.com -UseBasicParsing -TimeoutSec 5).StatusCode }
    catch { $https = 0 }
    Write-ItInfo "gw=$gw  icmp=${ms}ms  https=$https"
    [pscustomobject]@{ Ping = $ms; Https = $https; Gw = $gw }
}

Write-Host "# stack-reset — $env:COMPUTERNAME @ $(Get-ItUtc)"
Write-ItSection 'BEFORE'
$before = Get-Snap
if (-not $Apply) {
    Write-ItSection 'Plan (dry-run)'
    Write-Host '  1. Clear-DnsClientCache'
    Write-Host '  2. ipconfig /renew on Up adapters'
    Write-Host '  3. re-probe'
    Write-Host ''
    Write-Host 'Re-run with -Apply to execute.'
    return
}

Write-ItSection 'Apply'
Clear-DnsClientCache
Write-ItOk 'DNS cache cleared'
Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {
    Write-ItInfo "renew $($_.Name)"
    ipconfig /release $_.Name | Out-Null
    ipconfig /renew $_.Name | Out-Null
}

Write-ItSection 'AFTER'
$after = Get-Snap
Write-ItSection 'Delta'
Write-ItInfo "ICMP  $($before.Ping) → $($after.Ping)"
Write-ItInfo "HTTPS $($before.Https) → $($after.Https)"
Write-ItInfo "GW    $($before.Gw) → $($after.Gw)"
if ($after.Https -match '^(2|3)') {
    Write-ItOk 'path healthy after reset — no reboot required'
} else {
    Write-ItFail 'still broken after stack reset'
    Write-Host '  Next: .\Why-Broken.ps1 ; .\Escalate-Smart.ps1'
    exit 1
}
