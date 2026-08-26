<#
.SYNOPSIS
  OS / resource snapshot for IT tickets (read-only).

.EXAMPLE
  .\System-Health.ps1
#>
[CmdletBinding()]
param()

function Write-Section([string]$Name) {
    Write-Host ""
    Write-Host "== $Name =="
}

Write-Section 'Timestamp'
[DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
$env:COMPUTERNAME

Write-Section 'Operating system'
$os = Get-CimInstance Win32_OperatingSystem
[pscustomobject]@{
    Caption      = $os.Caption
    Version      = $os.Version
    Build        = $os.BuildNumber
    Architecture = $os.OSArchitecture
    LastBoot     = $os.LastBootUpTime
} | Format-List | Out-String | Write-Host

Write-Section 'Uptime'
$boot = $os.LastBootUpTime
$uptime = (Get-Date) - $boot
Write-Host ("{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)

Write-Section 'Memory'
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
Write-Host ("Total: {0} GiB  Free: {1} GiB  Used: {2}%" -f $totalGB, $freeGB, [math]::Round((1 - $freeGB / $totalGB) * 100, 1))

Write-Section 'Disk'
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    [pscustomobject]@{
        Drive   = $_.DeviceID
        SizeGiB = [math]::Round($_.Size / 1GB, 1)
        FreeGiB = [math]::Round($_.FreeSpace / 1GB, 1)
        FreePct = [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
    }
} | Format-Table -AutoSize | Out-String | Write-Host

Write-Section 'Top CPU processes'
Get-Process | Sort-Object CPU -Descending | Select-Object -First 8 Name, Id, CPU, @{n='WS_MB';e={[math]::Round($_.WorkingSet64/1MB,1)}} |
    Format-Table -AutoSize | Out-String | Write-Host

Write-Host ''
Write-Host 'Done. Attach or paste into the incident ticket.'
