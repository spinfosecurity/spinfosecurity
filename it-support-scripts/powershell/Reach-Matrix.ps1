<#
.SYNOPSIS
  TCP reachability matrix — is IT blocking me, or is the app broken?
#>
[CmdletBinding()]
param([string]$TargetsFile)
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
if (-not $TargetsFile) {
    $TargetsFile = if (Test-Path (Join-Path $Root 'targets.conf')) { Join-Path $Root 'targets.conf' } else { Join-Path $Root 'targets.example.conf' }
}

Write-Host "# reach-matrix — $env:COMPUTERNAME @ $(Get-ItUtc)"
'{0,-18} {1,-28} {2,-6} {3}' -f 'SERVICE','ENDPOINT','PORT','RESULT' | Write-Host

Get-Content $TargetsFile | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object {
    $name,$targetHost,$port,$proto = $_ -split '\|'
    if ($proto -eq 'icmp') { return }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $ok = $false
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $iar = $c.BeginConnect($targetHost, [int]$port, $null, $null)
        $ok = $iar.AsyncWaitHandle.WaitOne(3000, $false) -and $c.Connected
        $c.Close()
    } catch { $ok = $false }
    $sw.Stop()
    $res = if ($ok) { "OPEN $($sw.ElapsedMilliseconds)ms" } else { 'BLOCKED/FAIL' }
    '{0,-18} {1,-28} {2,-6} {3}' -f $name,$targetHost,$port,$res | Write-Host
}

Write-ItSection 'How to read'
Write-Host '  All OPEN → not a path issue; debug the app/credentials.'
Write-Host '  Cluster of FAILs on 443 → proxy/VPN/firewall.'
