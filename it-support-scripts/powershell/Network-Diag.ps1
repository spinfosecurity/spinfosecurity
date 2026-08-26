<#
.SYNOPSIS
  Quick network triage for IT tickets (read-only).

.DESCRIPTION
  Prints addressing, gateway, DNS, and reachability in a ticket-friendly format.

.PARAMETER Target
  Host or IP to probe. Default: 1.1.1.1

.EXAMPLE
  .\Network-Diag.ps1
  .\Network-Diag.ps1 -Target 8.8.8.8
#>
[CmdletBinding()]
param(
    [string]$Target = '1.1.1.1'
)

function Write-Section([string]$Name) {
    Write-Host ""
    Write-Host "== $Name =="
}

Write-Section 'Timestamp'
[DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
$env:COMPUTERNAME

Write-Section 'Interfaces / addressing'
Get-NetIPConfiguration | ForEach-Object {
    [pscustomobject]@{
        Interface = $_.InterfaceAlias
        IPv4      = ($_.IPv4Address.IPAddress -join ', ')
        Gateway   = ($_.IPv4DefaultGateway.NextHop -join ', ')
        DNS       = ($_.DNSServer.ServerAddresses -join ', ')
    }
} | Format-Table -AutoSize | Out-String | Write-Host

Write-Section 'DNS resolvers'
Get-DnsClientServerAddress -AddressFamily IPv4 |
    Where-Object { $_.ServerAddresses } |
    Select-Object InterfaceAlias, ServerAddresses |
    Format-Table -AutoSize | Out-String | Write-Host

Write-Section 'Gateway reachability'
$gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Sort-Object RouteMetric |
    Select-Object -First 1 -ExpandProperty NextHop)
if ($gw) {
    Write-Host "Default gateway: $gw"
    Test-Connection -ComputerName $gw -Count 2 -ErrorAction SilentlyContinue |
        Format-Table -AutoSize | Out-String | Write-Host
} else {
    Write-Host 'Could not determine default gateway.'
}

Write-Section "External probe: $Target"
Test-Connection -ComputerName $Target -Count 3 -ErrorAction SilentlyContinue |
    Format-Table -AutoSize | Out-String | Write-Host

Write-Section 'DNS resolution sample'
try {
    Resolve-DnsName example.com -Type A -ErrorAction Stop |
        Select-Object Name, Type, IPAddress |
        Format-Table -AutoSize | Out-String | Write-Host
} catch {
    Write-Host "DNS lookup failed: $($_.Exception.Message)"
}

Write-Section 'Listening ports (sample)'
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Select-Object -First 20 LocalAddress, LocalPort, OwningProcess |
    Format-Table -AutoSize | Out-String | Write-Host

Write-Host ''
Write-Host 'Done. Paste this output into the ticket (redact hostnames if required).'
