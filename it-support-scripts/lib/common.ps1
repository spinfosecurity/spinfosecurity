# Shared helpers for IT support PowerShell scripts
function Get-ItUtc { [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ') }
function Write-ItSection([string]$Name) { Write-Host ""; Write-Host "## $Name" }
function Write-ItOk([string]$m)   { Write-Host "  [OK]   $m" }
function Write-ItWarn([string]$m) { Write-Host "  [WARN] $m" }
function Write-ItFail([string]$m) { Write-Host "  [FAIL] $m" }
function Write-ItInfo([string]$m) { Write-Host "  [--]   $m" }
function Write-ItFix([string]$m)  { Write-Host "  [FIX]  $m" }

$script:ItHyps = New-Object System.Collections.Generic.List[string]
function Reset-ItHyps { $script:ItHyps = New-Object System.Collections.Generic.List[string] }
function Add-ItHyp([int]$Sev, [string]$Title, [string]$Evidence, [string]$Fix = '') {
    $script:ItHyps.Add("$Sev|$Title|$Evidence|$Fix") | Out-Null
}
function Write-ItHyps {
    if ($script:ItHyps.Count -eq 0) {
        Write-ItOk 'No strong failure signal.'
        return
    }
    Write-Host ''
    Write-Host '### Ranked hypotheses — act on #1 first'
    $i = 1
    $script:ItHyps | Sort-Object { [int]($_ -split '\|')[0] } | ForEach-Object {
        $p = $_ -split '\|', 4
        Write-Host ("  #{0}  {1}" -f $i, $p[1])
        Write-Host ("       evidence: {0}" -f $p[2])
        if ($p[3]) { Write-Host ("       fix:      {0}" -f $p[3]) }
        $i++
    }
}

function Test-ItPrivateIp([string]$Ip) {
    return [bool]($Ip -match '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|100\.64\.|127\.|0\.0\.0\.0|169\.254\.)')
}

function Get-ItEdgeSkewSeconds([string]$Url = 'https://1.1.1.1') {
    try {
        $hdr = (Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 4 -UseBasicParsing).Headers.Date
        $remote = [DateTime]::Parse($hdr).ToUniversalTime()
        return [int]([DateTime]::UtcNow - $remote).TotalSeconds
    } catch { return $null }
}

function Get-ItTargetsFile([string]$Root) {
    $custom = Join-Path $Root 'targets.conf'
    if (Test-Path $custom) { return $custom }
    return Join-Path $Root 'targets.example.conf'
}

function Test-ItTcp([string]$TargetHost, [int]$Port, [int]$TimeoutMs = 3000) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $iar = $c.BeginConnect($TargetHost, $Port, $null, $null)
        $ok = $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false) -and $c.Connected
        $c.Close()
        return $ok
    } catch { return $false }
}
