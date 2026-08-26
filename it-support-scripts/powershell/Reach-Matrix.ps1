<#
.SYNOPSIS
  TCP reachability matrix — is IT blocking me, or is the app broken?
#>
[CmdletBinding()]
param([string]$TargetsFile)
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
if (-not $TargetsFile) { $TargetsFile = Get-ItTargetsFile $Root }

Write-Host "# reach-matrix — $env:COMPUTERNAME @ $(Get-ItUtc)"
Write-Host "# targets: $TargetsFile"
Write-Host ''
'{0,-18} {1,-28} {2,-6} {3}' -f 'SERVICE','ENDPOINT','PORT','RESULT' | Write-Host
'{0,-18} {1,-28} {2,-6} {3}' -f '-------','--------','----','------' | Write-Host

$open = 0; $blocked = 0; $total = 0
Get-Content $TargetsFile | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object {
    $name, $targetHost, $port, $proto = $_ -split '\|'
    if ($proto -ne 'tcp') { return }
    $total++
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $ok = Test-ItTcp $targetHost ([int]$port)
    $sw.Stop()
    if ($ok) {
        $open++
        $res = "OPEN $($sw.ElapsedMilliseconds)ms"
    } else {
        $blocked++
        $res = 'BLOCKED'
    }
    '{0,-18} {1,-28} {2,-6} {3}' -f $name, $targetHost, $port, $res | Write-Host
}

Write-ItSection 'Summary'
Write-ItInfo "open=$open  blocked=$blocked"
if ($total -eq 0) { Write-ItWarn "no tcp targets in $TargetsFile"; return }
if ($blocked -eq 0) {
    Write-ItOk 'all TCP targets reachable — not an OS path issue; debug app/credentials/IdP'
    exit 0
}
if ($open -eq 0) {
    Write-ItFail 'nothing reachable — run .\Why-Broken.ps1 and .\Stack-Reset.ps1 -Apply'
    exit 1
}
Write-ItFail 'partial path failure — service ACL/outage or selective filter'
exit 1
