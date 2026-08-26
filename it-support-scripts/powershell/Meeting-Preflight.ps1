<#
.SYNOPSIS
  Mic/cam presence + uplink quality before joining a meeting.
#>
[CmdletBinding()]
param()
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
$script:ItHyps = New-Object System.Collections.Generic.List[string]
$fail = $false

Write-Host "# meeting-preflight — $env:COMPUTERNAME @ $(Get-ItUtc)"
Write-ItSection 'Devices'
try {
    $cams = Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'Camera' -or $_.Name -match 'Camera|Webcam' }
    if ($cams) { Write-ItOk "camera: $(($cams | Select-Object -First 1).Name)" }
    else { Write-ItWarn 'no camera device'; Add-ItHyp 2 'Camera missing' 'no PnP camera'; $fail = $true }
} catch { Write-ItWarn 'camera probe failed' }

$mics = Get-CimInstance Win32_SoundDevice -EA SilentlyContinue
if ($mics) { Write-ItOk "audio devices: $($mics.Count)" } else { Write-ItFail 'no audio devices'; Add-ItHyp 1 'No audio' 'Win32_SoundDevice empty'; $fail = $true }

Write-ItSection 'Uplink'
$p = Test-Connection 1.1.1.1 -Count 10 -EA SilentlyContinue
if ($p) {
    $avg = [math]::Round(($p | Measure-Object Latency -Average).Average,1)
    $loss = [math]::Round((1 - $p.Count/10)*100,0)
    Write-ItInfo "rtt_avg=${avg}ms loss=${loss}%"
    if ($avg -gt 150 -or $loss -gt 2) {
        Write-ItFail 'uplink not meeting-grade'
        Add-ItHyp 1 'Poor uplink for A/V' "rtt=$avg loss=$loss"
        $fail = $true
    } else { Write-ItOk 'uplink acceptable for A/V' }
} else {
    Write-ItFail 'no ICMP to edge'; Add-ItHyp 1 'Network down' 'ping failed'; $fail = $true
}

Write-ItHyps
if ($fail) { Write-Host ''; Write-Host 'Do not join yet.'; exit 1 }
Write-Host ''; Write-Host 'Verdict: clear to join.'
