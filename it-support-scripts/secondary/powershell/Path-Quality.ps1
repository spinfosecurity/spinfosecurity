<#
.SYNOPSIS
  Parallel quality probes to real work endpoints (not ping-theater).
#>
[CmdletBinding()]
param([string]$TargetsFile)
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
if (-not $TargetsFile) {
    $TargetsFile = if (Test-Path (Join-Path $Root 'targets.conf')) { Join-Path $Root 'targets.conf' } else { Join-Path $Root 'targets.example.conf' }
}

Write-Host "# path-quality — $env:COMPUTERNAME @ $(Get-ItUtc)"
Write-Host "# targets: $TargetsFile"
'{0,-18} {1,-24} {2,-8} {3,-8} {4}' -f 'NAME','HOST','ICMP_ms','LOSS%','TCP' | Write-Host

Get-Content $TargetsFile | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object {
    $name,$targetHost,$port,$proto = $_ -split '\|'
    $icmp = 'n/a'; $loss = 'n/a'; $tcp = 'n/a'
    if ($proto -in 'icmp','tcp') {
        $p = Test-Connection -ComputerName $targetHost -Count 5 -ErrorAction SilentlyContinue
        if ($p) {
            $icmp = [math]::Round(($p | Measure-Object Latency -Average).Average, 1)
            $loss = [math]::Round((1 - ($p.Count / 5)) * 100, 0)
        } else { $icmp = 'FAIL'; $loss = 100 }
    }
    if ($proto -eq 'tcp') {
        try {
            $c = New-Object System.Net.Sockets.TcpClient
            $iar = $c.BeginConnect($targetHost, [int]$port, $null, $null)
            $ok = $iar.AsyncWaitHandle.WaitOne(3000, $false)
            if ($ok -and $c.Connected) { $tcp = "open/$port" } else { $tcp = "CLOSED/$port" }
            $c.Close()
        } catch { $tcp = "FAIL/$port" }
    }
    '{0,-18} {1,-24} {2,-8} {3,-8} {4}' -f $name,$targetHost,$icmp,$loss,$tcp | Write-Host
}

Write-ItSection 'Read'
Write-Host '  LOSS% >2 on wired → bad path (not reboot the laptop)'
Write-Host '  TCP FAIL with good ICMP → middlebox/firewall, not DNS'
