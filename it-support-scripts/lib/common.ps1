# Shared helpers for IT support PowerShell scripts
function Get-ItUtc { [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ') }
function Write-ItSection([string]$Name) { Write-Host ""; Write-Host "## $Name" }
function Write-ItOk([string]$m)   { Write-Host "  [OK]   $m" }
function Write-ItWarn([string]$m) { Write-Host "  [WARN] $m" }
function Write-ItFail([string]$m) { Write-Host "  [FAIL] $m" }
function Write-ItInfo([string]$m) { Write-Host "  [--]   $m" }

$script:ItHyps = New-Object System.Collections.Generic.List[string]
function Add-ItHyp([int]$Sev, [string]$Title, [string]$Evidence) {
    $script:ItHyps.Add("$Sev|$Title|$Evidence") | Out-Null
}
function Write-ItHyps {
    if ($script:ItHyps.Count -eq 0) {
        Write-ItOk 'No strong failure signal — environment looks workable.'
        return
    }
    Write-Host ''
    Write-Host '### Ranked hypotheses (act on #1 first)'
    $i = 1
    $script:ItHyps | Sort-Object { [int]($_ -split '\|')[0] } | ForEach-Object {
        $p = $_ -split '\|', 3
        Write-Host ("  #{0}  [sev={1}] {2}" -f $i, $p[0], $p[1])
        Write-Host ("       evidence: {0}" -f $p[2])
        $i++
    }
}
