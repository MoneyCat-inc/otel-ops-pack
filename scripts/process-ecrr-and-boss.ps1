# Orchestrate processing of ECRR and BossCat reports with timestamp correlation
param(
    [string]$EcrrOutputDir = "artifacts",
    [string]$BossOutputDir = "artifacts",
    [string]$BossReportsDir = "docs/BossCat/reports",
    [int]$CorrelationWindowMinutes = 180
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $EcrrOutputDir)) { New-Item -ItemType Directory -Path $EcrrOutputDir -Force | Out-Null }
if (-not (Test-Path $BossOutputDir)) { New-Item -ItemType Directory -Path $BossOutputDir -Force | Out-Null }

Write-Host "🚀 Processing ECRR and BossCat reports" -ForegroundColor Cyan

# 1) Run ECRR processing
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/process-all-ecrr-reports.ps1 -OutputDir $EcrrOutputDir | Write-Host

# 2) Run Boss processing
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/process-all-boss-reports.ps1 -ReportsDir $BossReportsDir -OutputDir $BossOutputDir | Write-Host

# 3) Load summaries and correlate by timestamp proximity
$ecrrMetricsPath = Join-Path $EcrrOutputDir 'ecrr-compliance-metrics.json'
$bossSummaryPath = Join-Path $BossOutputDir 'boss-processing-summary.json'

if (-not (Test-Path $ecrrMetricsPath) -or -not (Test-Path $bossSummaryPath)) {
    Write-Host "Correlation skipped: missing input summaries." -ForegroundColor Yellow
    exit 0
}

$ecrrMetrics = Get-Content $ecrrMetricsPath -Raw | ConvertFrom-Json
$bossSummary = Get-Content $bossSummaryPath -Raw | ConvertFrom-Json

# Build naive ECRR timestamp index from report names if present
$ecrrReportsDir = 'docs/ECRR_REPORTS'
$ecrrFiles = Get-ChildItem -Path $ecrrReportsDir -Filter '*.md' -File
$ecrrIndex = @()
foreach ($f in $ecrrFiles) {
    $dateMatch = [regex]::Match($f.Name, '(20\d{2}-\d{2}-\d{2})')
    if ($dateMatch.Success) {
        $ts = Get-Date ($dateMatch.Groups[1].Value + ' 00:00:00')
        $ecrrIndex += [pscustomobject]@{ Name = $f.Name; Path = $f.FullName.Replace('\\','/'); Timestamp = $ts }
    }
}

$window = [TimeSpan]::FromMinutes($CorrelationWindowMinutes)
$pairs = New-Object System.Collections.Generic.List[object]

# Helper to parse a timestamp string into [datetime]
function Convert-ToDate {
    param([string]$text)
    if (-not $text) { return $null }
    $t = $text.Trim().TrimEnd(':',';','.',',')
    $m = [regex]::Match($t, '(20\d{2}-\d{2}-\d{2})[T\s](\d{2}:\d{2}(?::\d{2})?)')
    $norm = if ($m.Success) { "$($m.Groups[1].Value) $($m.Groups[2].Value)" } else { $t }
    $formats = @('yyyy-MM-dd HH:mm:ss','yyyy-MM-dd HH:mm','yyyy-MM-ddTHH:mm:ss','yyyy-MM-ddTHH:mm')
    foreach ($fmt in $formats) {
        try { return [datetime]::ParseExact($norm, $fmt, [System.Globalization.CultureInfo]::InvariantCulture) } catch { }
    }
    try { return [datetime]::Parse($norm, [System.Globalization.CultureInfo]::InvariantCulture) } catch { return $null }
}

foreach ($boss in $bossSummary.Reports) {
    if (-not $boss.Timestamp) { continue }
    $bossTs = Convert-ToDate -text ([string]$boss.Timestamp)
    if (-not $bossTs) { continue }

    $near = $ecrrIndex | Where-Object { $_.Timestamp -and ([timespan]::FromTicks([math]::Abs(($_.Timestamp - $bossTs).Ticks))) -le $window }
    foreach ($n in $near) {
        $pairs.Add([pscustomobject]@{
            bossName = $boss.Name
            bossPath = $boss.Path
            bossTimestamp = $bossTs.ToString('yyyy-MM-dd HH:mm:ss')
            ecrrName = $n.Name
            ecrrPath = $n.Path
            ecrrTimestamp = $n.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')
            deltaMinutes = [math]::Round((New-TimeSpan -Start $n.Timestamp -End $bossTs).TotalMinutes, 1)
        }) | Out-Null
    }
}

$correlation = @{
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    windowMinutes = $CorrelationWindowMinutes
    bossTotals = $bossSummary.Totals
    ecrrSummary = $ecrrMetrics
    pairs = $pairs
}

$outCorr = Join-Path $EcrrOutputDir 'ecrr-boss-correlation.json'
($correlation | ConvertTo-Json -Depth 8) | Out-File -Encoding UTF8 $outCorr
Write-Host "✅ Correlation generated: $outCorr (pairs: $($pairs.Count))" -ForegroundColor Green
exit 0


