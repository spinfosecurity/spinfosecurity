<#
.SYNOPSIS
  Ranked safe disk reclaim under pressure. No blind deletes.
#>
[CmdletBinding()]
param([switch]$Apply)
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')

Write-Host "# disk-reclaim — $env:COMPUTERNAME @ $(Get-ItUtc)"
Write-ItSection 'Pressure'
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $u = [math]::Round((1 - $_.FreeSpace/$_.Size)*100,1)
    Write-ItInfo "$($_.DeviceID) used=${u}% free=$([math]::Round($_.FreeSpace/1GB,1))GiB"
}

$safe = @(
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp",
    "$env:LOCALAPPDATA\NuGet\v3-cache",
    "$env:LOCALAPPDATA\pip\Cache",
    "$env:USERPROFILE\.npm\_cacache",
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
)
Write-ItSection 'Ranked candidates'
'{0,-8} {1,-8} {2}' -f 'TIER','SIZE','PATH' | Write-Host
$found = @()
foreach ($p in $safe) {
    if (-not (Test-Path $p)) { continue }
    $bytes = (Get-ChildItem $p -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
    if (-not $bytes -or $bytes -lt 1MB) { continue }
    $gb = '{0:N1}G' -f ($bytes/1GB)
    '{0,-8} {1,-8} {2}' -f 'SAFE',$gb,$p | Write-Host
    $found += $p
}
'{0,-8} {1,-8} {2}' -f 'MANUAL','-','docker system df' | Write-Host
'{0,-8} {1,-8} {2}' -f 'MANUAL','-','cleanmgr /sageset:1 then /sagerun:1' | Write-Host

if ($Apply) {
    Write-ItSection 'Apply SAFE purge'
    foreach ($p in $found) {
        Get-ChildItem $p -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
        Write-ItOk "cleared $p"
    }
} else {
    Write-ItInfo 'Dry-run. Pass -Apply to purge SAFE tier only.'
}
