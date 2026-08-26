<#
.SYNOPSIS
  Flush DNS cache; optionally renew DHCP lease (common L1/L2 fix).

.PARAMETER Renew
  Also release/renew DHCP on active adapters (may briefly drop connectivity).

.EXAMPLE
  .\Dns-Renew.ps1
  .\Dns-Renew.ps1 -Renew
#>
[CmdletBinding()]
param(
    [switch]$Renew
)

function Write-Section([string]$Name) {
    Write-Host ""
    Write-Host "== $Name =="
}

Write-Section 'Before'
[DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
Get-DnsClientServerAddress -AddressFamily IPv4 |
    Where-Object { $_.ServerAddresses } |
    Select-Object InterfaceAlias, ServerAddresses |
    Format-Table -AutoSize | Out-String | Write-Host

Write-Section 'Flush DNS cache'
Clear-DnsClientCache
Write-Host 'DNS client cache cleared.'

if ($Renew) {
    Write-Section 'DHCP renew'
    Write-Host 'Renewing DHCP on connected adapters (connectivity may flicker)...'
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
        $alias = $_.Name
        Write-Host " -> $alias"
        try {
            ipconfig /release $alias | Out-Null
            ipconfig /renew $alias | Out-Null
            Write-Host "    renewed"
        } catch {
            Write-Host "    failed: $($_.Exception.Message)"
        }
    }
} else {
    Write-Host ''
    Write-Host 'DNS flush only. Pass -Renew to also renew DHCP.'
}

Write-Section 'After — quick check'
Test-Connection -ComputerName 1.1.1.1 -Count 2 -ErrorAction SilentlyContinue |
    Format-Table -AutoSize | Out-String | Write-Host
Write-Host 'Done.'
