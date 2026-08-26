<#
.SYNOPSIS
  Compact correlation ID for fleet incidents.
#>
[CmdletBinding()]
param([switch]$Json)
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')

$os = Get-CimInstance Win32_OperatingSystem
$dns = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object ServerAddresses | Select-Object -First 1).ServerAddresses[0]
$gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -EA SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1).NextHop
$vpn = if (Get-NetAdapter -EA SilentlyContinue | Where-Object { $_.InterfaceDescription -match 'VPN|WireGuard|Tailscale|Cisco|GlobalProtect' }) { 'yes' } else { 'no' }
$clients = (@('zoom','slack','Teams','Code','docker') | Where-Object { Get-Command $_ -EA SilentlyContinue }) -join ','
$payload = "os=windows|ver=$($os.BuildNumber)|dns=$dns|gw_octet=$($gw.Split('.')[-1])|vpn=$vpn|clients=$clients"
$sha = [System.BitConverter]::ToString(
    [System.Security.Cryptography.SHA256]::Create().ComputeHash(
        [Text.Encoding]::UTF8.GetBytes($payload)
    )
).Replace('-','').Substring(0,16).ToLower()

if ($Json) {
    @{ host=$env:COMPUTERNAME; utc=(Get-ItUtc); fingerprint=$sha; signal=$payload } | ConvertTo-Json -Compress
} else {
    Write-Host "# fleet-fingerprint — $env:COMPUTERNAME @ $(Get-ItUtc)"
    Write-Host "fingerprint: $sha"
    Write-Host "signal:      $payload"
    Write-Host ''
    Write-Host 'Matching hashes across users ⇒ fleet change, not one-off.'
}
