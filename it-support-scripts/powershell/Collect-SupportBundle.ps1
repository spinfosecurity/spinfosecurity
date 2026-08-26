<#
.SYNOPSIS
  Gather ticket-ready diagnostics into one folder.

.PARAMETER OutputDir
  Destination folder. Default: .\support-bundle-YYYYMMDD-HHMMSS

.EXAMPLE
  .\Collect-SupportBundle.ps1
#>
[CmdletBinding()]
param(
    [string]$OutputDir
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
if (-not $OutputDir) {
    $OutputDir = Join-Path (Get-Location) "support-bundle-$stamp"
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

@"
host=$env:COMPUTERNAME
collected_utc=$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
user=$env:USERNAME
"@ | Set-Content -Path (Join-Path $OutputDir 'meta.txt')

Write-Host 'Collecting network diagnostics...'
& (Join-Path $here 'Network-Diag.ps1') *>&1 |
    Out-File -FilePath (Join-Path $OutputDir 'network-diag.txt') -Encoding utf8

Write-Host 'Collecting system health...'
& (Join-Path $here 'System-Health.ps1') *>&1 |
    Out-File -FilePath (Join-Path $OutputDir 'system-health.txt') -Encoding utf8

Get-WinEvent -LogName System -MaxEvents 50 -ErrorAction SilentlyContinue |
    Format-List TimeCreated, Id, LevelDisplayName, ProviderName, Message |
    Out-String |
    Set-Content -Path (Join-Path $OutputDir 'system-events-recent.txt')

@"
Support bundle created $stamp UTC
Attach this folder (or zip it) to the IT ticket before escalating to L3.

Contents:
  meta.txt
  network-diag.txt
  system-health.txt
  system-events-recent.txt
"@ | Set-Content -Path (Join-Path $OutputDir 'README.txt')

Write-Host ""
Write-Host "Bundle ready: $OutputDir"
Write-Host "Zip tip: Compress-Archive -Path '$OutputDir' -DestinationPath '$OutputDir.zip'"
