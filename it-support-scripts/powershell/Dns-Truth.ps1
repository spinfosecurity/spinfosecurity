<#
.SYNOPSIS
  Compare system DNS to DoH ground truth — detect hijack / captive / NXDOMAIN forgery.
#>
[CmdletBinding()]
param([string]$Name = 'example.com')
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
$script:ItHyps = New-Object System.Collections.Generic.List[string]

Write-Host "# dns-truth — $Name — $env:COMPUTERNAME @ $(Get-ItUtc)"

Write-ItSection 'System resolver'
try {
    $sys = @([System.Net.Dns]::GetHostAddresses($Name) | Where-Object AddressFamily -eq 'InterNetwork' | ForEach-Object IPAddressToString)
} catch { $sys = @() }
$sys | ForEach-Object { Write-Host "  $_" }
if (-not $sys) { Write-ItFail 'no answer'; Add-ItHyp 1 'System DNS dead' "no A for $Name" }

Write-ItSection 'DoH ground truth'
$doh = @()
try {
    $j = Invoke-RestMethod -Uri "https://cloudflare-dns.com/dns-query?name=$Name&type=A" -Headers @{accept='application/dns-json'} -TimeoutSec 5
    $doh = @($j.Answer | Where-Object type -eq 1 | ForEach-Object data)
    $doh | ForEach-Object { Write-Host "  $_" }
} catch { Write-ItWarn 'DoH unreachable'; Add-ItHyp 2 'DoH path blocked' 'cannot validate' }

Write-ItSection 'Verdict'
foreach ($ip in $sys) {
    if ($ip -match '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|100\.64\.|127\.|169\.254\.)') {
        Write-ItFail "system returned non-routable $ip"
        Add-ItHyp 1 'DNS hijack or captive portal' "$Name → $ip"
    }
}
$rand = "nx-$([guid]::NewGuid().ToString('N')).invalid"
try {
    $nx = [System.Net.Dns]::GetHostAddresses($rand)
    if ($nx) { Write-ItFail "random name resolved — NXDOMAIN forgery"; Add-ItHyp 1 'NXDOMAIN forgery' "$rand resolved" }
} catch { Write-ItOk 'random name correctly empty' }

Write-ItHyps
