<#
.SYNOPSIS
  Local scan for high-signal secret spills (redacted). No exfiltration.
#>
[CmdletBinding()]
param()
$Root = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
. (Join-Path $Root 'lib\common.ps1')
$script:ItHyps = New-Object System.Collections.Generic.List[string]

Write-Host "# secret-hygiene — $env:COMPUTERNAME @ $(Get-ItUtc)"
$patterns = @(
    'AKIA[0-9A-Z]{16}',
    'ghp_[A-Za-z0-9]{20,}',
    'github_pat_[A-Za-z0-9_]{20,}',
    'xox[baprs]-[A-Za-z0-9-]{10,}',
    '-----BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY-----',
    'sk-live-[A-Za-z0-9]{20,}',
    'sk-proj-[A-Za-z0-9]{20,}'
)
$rx = ($patterns -join '|')
$targets = @(
    "$env:USERPROFILE\.aws\credentials",
    "$env:USERPROFILE\.npmrc",
    "$env:USERPROFILE\.netrc",
    "$env:USERPROFILE\.docker\config.json"
) | Where-Object { Test-Path $_ }

$hits = 0
Write-ItSection "Scan targets ($($targets.Count) files)"
foreach ($f in $targets) {
    $len = (Get-Item $f).Length
    if ($len -gt 2MB) { continue }
    Select-String -Path $f -Pattern $rx -AllMatches -EA SilentlyContinue | ForEach-Object {
        $line = $_.Line -replace '(AKIA[0-9A-Z]{4})[0-9A-Z]+','$1********' `
                        -replace '(ghp_[A-Za-z0-9]{4})[A-Za-z0-9]+','$1********' `
                        -replace '(sk-[A-Za-z0-9_-]{4})[A-Za-z0-9_-]+','$1********'
        Write-ItFail "$f:$($_.LineNumber)  $line"
        $hits++
    }
}
Write-ItSection 'Verdict'
if ($hits -gt 0) {
    Write-ItFail "$hits potential secret spill(s)"
    Add-ItHyp 1 'Credential spill on endpoint' "$hits hit(s) — rotate now"
    Write-ItHyps
    Write-Host 'Playbook: rotate → revoke → purge → document. Do not paste secrets into chat.'
    exit 1
}
Write-ItOk 'no high-signal spills in scanned locations'
