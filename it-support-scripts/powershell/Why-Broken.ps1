<#
.SYNOPSIS
  Ranked root-cause check. Open a ticket only if #1 still needs a human.

.DESCRIPTION
  Checks clock skew, DNS honesty, disk space, default gateway, and outbound HTTPS.
  Prints ranked failures with a suggested next fix.
#>
[CmdletBinding()]
param()
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
Reset-ItHyps

Write-Host "# why-broken — $env:COMPUTERNAME @ $(Get-ItUtc)"

Write-ItSection '1. Clock'
$skew = Get-ItEdgeSkewSeconds
if ($null -ne $skew) {
    Write-ItInfo "skew vs edge: ${skew}s"
    if ([math]::Abs($skew) -gt 120) {
        Write-ItFail "clock skew ${skew}s — auth will flake"
        Add-ItHyp 1 'Clock skew' "local−edge = ${skew}s" '.\Auth-Clock.ps1 -Fix'
    } else { Write-ItOk "clock within $([math]::Abs($skew))s" }
} else { Write-ItWarn 'could not sample edge clock' }

Write-ItSection '2. DNS honesty'
try {
    $sys = @([System.Net.Dns]::GetHostAddresses('example.com') |
        Where-Object AddressFamily -eq 'InterNetwork' |
        ForEach-Object IPAddressToString)
} catch { $sys = @() }
$doh = @()
try {
    $j = Invoke-RestMethod -Uri 'https://cloudflare-dns.com/dns-query?name=example.com&type=A' -Headers @{accept='application/dns-json'} -TimeoutSec 4
    $doh = @($j.Answer | Where-Object type -eq 1 | ForEach-Object data)
} catch {}
Write-ItInfo "system → $($sys -join ', ')"
Write-ItInfo "DoH    → $($doh -join ', ')"
if (-not $sys) {
    Write-ItFail 'system DNS returned nothing'
    Add-ItHyp 1 'DNS failure' 'no A from OS resolver' '.\Dns-Truth.ps1'
} else {
    $priv = $sys | Where-Object { Test-ItPrivateIp $_ } | Select-Object -First 1
    if ($priv) {
        Write-ItFail "resolver returned private/captive address $priv"
        Add-ItHyp 1 'Captive portal or DNS hijack' "system=$priv" 'complete portal login; .\Dns-Truth.ps1'
    } else { Write-ItOk 'resolver returns public addresses' }
}

Write-ItSection '3. Disk'
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$pct = [int](100 - ($disk.FreeSpace / $disk.Size * 100))
Write-ItInfo "C: at ${pct}% used"
if ($pct -ge 95) { Write-ItFail 'C: critically full'; Add-ItHyp 1 'Disk full' "C: ${pct}%" 'free space, then re-run' }
elseif ($pct -ge 90) { Write-ItWarn 'C: high'; Add-ItHyp 2 'Disk pressure' "C: ${pct}%" 'free ≥10%' }
else { Write-ItOk 'disk headroom OK' }

Write-ItSection '4. Path'
$gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -EA SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1).NextHop
if (-not $gw) { Write-ItFail 'no default route'; Add-ItHyp 1 'No default route' 'islanded' '.\Stack-Reset.ps1 -Apply' }
else { Write-ItOk "default gateway $gw" }

try {
    $code = (Invoke-WebRequest https://example.com -UseBasicParsing -TimeoutSec 5).StatusCode
    Write-ItOk "outbound HTTPS works ($code)"
} catch {
    Write-ItFail 'outbound HTTPS broken'
    Add-ItHyp 1 'Outbound HTTPS blocked/broken' $_.Exception.Message '.\Reach-Matrix.ps1 ; .\Stack-Reset.ps1 -Apply'
}

Write-ItHyps
if ($script:ItHyps.Count -gt 0) {
    Write-Host ''
    Write-Host 'Next: apply fix for #1 → re-run .\Why-Broken.ps1'
    Write-Host 'Still red → .\Escalate-Smart.ps1'
    exit 1
}
Write-Host ''
Write-Host 'Verdict: OS path looks workable.'
Write-Host 'If an app still fails → .\Reach-Matrix.ps1 (path vs app).'
