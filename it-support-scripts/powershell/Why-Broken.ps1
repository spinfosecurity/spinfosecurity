<#
.SYNOPSIS
  Ranked root-cause self-triage. Open a ticket only if #1 needs a human.
#>
[CmdletBinding()]
param()
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
$script:ItHyps = New-Object System.Collections.Generic.List[string]

Write-Host "# why-broken — $env:COMPUTERNAME @ $(Get-ItUtc)"

Write-ItSection 'Clock'
try {
    $hdr = (Invoke-WebRequest -Uri 'https://1.1.1.1' -Method Head -TimeoutSec 4 -UseBasicParsing).Headers.Date
    $remote = [DateTime]::Parse($hdr).ToUniversalTime()
    $skew = [int]([DateTime]::UtcNow - $remote).TotalSeconds
    Write-ItInfo "skew vs edge clock: ${skew}s"
    if ([math]::Abs($skew) -gt 120) {
        Write-ItFail "clock skew ${skew}s — auth will flake"
        Add-ItHyp 1 'Clock skew' "local differs from edge by ${skew}s"
    } else { Write-ItOk "clock within $([math]::Abs($skew))s" }
} catch { Write-ItWarn 'could not sample remote clock' }

Write-ItSection 'DNS truth'
try {
    $sys = [System.Net.Dns]::GetHostAddresses('example.com') | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1 -ExpandProperty IPAddressToString
} catch { $sys = $null }
$doh = $null
try {
    $j = Invoke-RestMethod -Uri 'https://cloudflare-dns.com/dns-query?name=example.com&type=A' -Headers @{accept='application/dns-json'} -TimeoutSec 4
    $doh = ($j.Answer | Where-Object { $_.type -eq 1 } | Select-Object -First 1).data
} catch {}
Write-ItInfo "system resolver → $sys"
Write-ItInfo "DoH ground truth → $doh"
if ($sys -match '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|100\.64\.|127\.)') {
    Write-ItFail "resolver returned private/captive address $sys"
    Add-ItHyp 1 'Captive portal or DNS hijack' "system=$sys doh=$doh"
} elseif ($sys) { Write-ItOk 'resolver answers for example.com' }
else {
    Write-ItFail 'system DNS returned nothing'
    Add-ItHyp 1 'DNS failure' 'example.com empty'
}

Write-ItSection 'Disk pressure'
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$pct = [int](100 - ($disk.FreeSpace / $disk.Size * 100))
Write-ItInfo "C: at ${pct}% used"
if ($pct -ge 95) { Write-ItFail 'C: critically full'; Add-ItHyp 1 'Disk full' "C: ${pct}%" }
elseif ($pct -ge 85) { Write-ItWarn 'C: high'; Add-ItHyp 2 'Disk pressure' "C: ${pct}%" }
else { Write-ItOk 'disk headroom OK' }

Write-ItSection 'Path'
$gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1).NextHop
if (-not $gw) { Write-ItFail 'no default route'; Add-ItHyp 1 'No default route' 'islanded' }
else { Write-ItOk "default gateway $gw" }

try {
    $code = (Invoke-WebRequest -Uri 'https://example.com' -UseBasicParsing -TimeoutSec 5).StatusCode
    Write-ItOk "outbound HTTPS works ($code)"
} catch {
    Write-ItFail 'outbound HTTPS broken'
    Add-ItHyp 1 'Outbound HTTPS blocked/broken' $_.Exception.Message
}

Write-ItHyps
if ($script:ItHyps.Count -gt 0) {
    Write-Host ''
    Write-Host 'Next: fix #1, re-run. If still red → .\Escalate-Smart.ps1'
    exit 1
}
Write-Host ''
Write-Host 'Verdict: workable. If an app still fails, it is probably the app — not the OS path.'
