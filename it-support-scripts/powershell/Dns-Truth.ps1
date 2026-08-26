<#
.SYNOPSIS
  Compare system DNS to DoH ground truth — hijack / captive / NXDOMAIN forgery.
#>
[CmdletBinding()]
param([string]$Name = 'example.com')
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
Reset-ItHyps

Write-Host "# dns-truth — $Name — $env:COMPUTERNAME @ $(Get-ItUtc)"

Write-ItSection 'System resolver'
try {
    $sys = @([System.Net.Dns]::GetHostAddresses($Name) |
        Where-Object AddressFamily -eq 'InterNetwork' |
        ForEach-Object IPAddressToString)
} catch { $sys = @() }
if (-not $sys) {
    Write-ItFail 'no answer'
    Add-ItHyp 1 'System DNS dead' "no A for $Name" 'check NIC DNS / VPN'
} else { $sys | ForEach-Object { Write-Host "  $_" } }

Write-ItSection 'DoH ground truth'
$doh = @()
try {
    $j = Invoke-RestMethod -Uri "https://cloudflare-dns.com/dns-query?name=$Name&type=A" -Headers @{accept='application/dns-json'} -TimeoutSec 5
    $doh = @($j.Answer | Where-Object type -eq 1 | ForEach-Object data)
    $doh | ForEach-Object { Write-Host "  $_" }
} catch {
    Write-ItWarn 'DoH unreachable'
    Add-ItHyp 2 'DoH path blocked' 'cannot validate resolver honesty'
}

Write-ItSection 'Honesty checks'
foreach ($ip in $sys) {
    if (Test-ItPrivateIp $ip) {
        Write-ItFail "non-public answer $ip"
        Add-ItHyp 1 'DNS hijack or captive portal' "$Name → $ip" 'portal login or fix DNS'
    }
}
$rand = "nx-$([guid]::NewGuid().ToString('N').Substring(0,16)).invalid"
try {
    $null = [System.Net.Dns]::GetHostAddresses($rand)
    Write-ItFail 'random name resolved — NXDOMAIN forgery'
    Add-ItHyp 1 'NXDOMAIN forgery' "$rand resolved" 'capture resolver IP; escalate'
} catch { Write-ItOk 'random name correctly empty' }

if ($sys -and $doh) {
    $overlap = $sys | Where-Object { $doh -contains $_ }
    if ($overlap) { Write-ItOk 'system answer intersects DoH set' }
    else { Write-ItWarn 'no overlap with DoH (multi-CDN possible)' }
}

Write-ItHyps
if ($script:ItHyps.Count -gt 0) { exit 1 }
