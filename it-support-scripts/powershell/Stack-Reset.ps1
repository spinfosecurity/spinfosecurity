<#
.SYNOPSIS
  Idempotent network heal with before/after proof. Not a reboot.
#>
[CmdletBinding()]
param([switch]$Apply)
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')

function Get-Snap([string]$Label) {
    Write-ItSection $Label
    $gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -EA SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1).NextHop
    $ping = Test-Connection 1.1.1.1 -Count 3 -EA SilentlyContinue
    $ms = if ($ping) { [math]::Round(($ping | Measure-Object Latency -Average).Average,1) } else { 'FAIL' }
    try { $https = (Invoke-WebRequest https://example.com -UseBasicParsing -TimeoutSec 5).StatusCode } catch { $https = 0 }
    Write-ItInfo "gateway=$gw  icmp=$ms  https=$https"
    [pscustomobject]@{ Ping=$ms; Https=$https; Gw=$gw }
}

Write-Host "# stack-reset — $env:COMPUTERNAME @ $(Get-ItUtc)"
$before = Get-Snap BEFORE
if (-not $Apply) {
    Write-ItSection 'Plan (dry-run)'
    Write-Host '  1. Clear-DnsClientCache'
    Write-Host '  2. ipconfig /renew on Up adapters'
    Write-Host '  3. re-probe'
    Write-Host ''
    Write-Host 'Re-run with -Apply. Prefer this over reboot.'
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
$after = Get-Snap AFTER
Write-ItSection 'Delta'
Write-ItInfo "ICMP $($before.Ping) → $($after.Ping)"
Write-ItInfo "HTTPS $($before.Https) → $($after.Https)"
if ($after.Https -match '^(2|3)') { Write-ItOk 'path restored or healthy — no reboot required' }
else { Write-ItFail 'still broken → Escalate-Smart'; exit 1 }
