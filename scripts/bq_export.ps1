Param(
    [string]$GcpProject = "demo-project",
    [string]$RepoCohort = "otel,resonai,comfort-cat",
    [string]$StartDate = "2024-01-01",
    [string]$EndDate = "2024-01-31"
)

$ErrorActionPreference = 'Stop'

function New-DirIfMissing([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path "$Root\.." | Select-Object -ExpandProperty Path
$OutDir = Join-Path $RepoRoot "artifacts\bq_exports"
$SqlDir = Join-Path $RepoRoot "sql"

New-DirIfMissing $OutDir

$openedCsv = Join-Path $OutDir "pr_opened_baseline.csv"
$closedCsv = Join-Path $OutDir "pr_closed_merge_join.csv"
$summaryFile = Join-Path $OutDir "export_summary.txt"

$bq = Get-Command bq -ErrorAction SilentlyContinue
$hasBq = $null -ne $bq

Write-Host "[bq_export] Start $(Get-Date -Format o) | Project=$GcpProject | Range=$StartDate..$EndDate" -ForegroundColor Cyan

if ($hasBq -and (Test-Path "$SqlDir\pr_opened_baseline.sql") -and (Test-Path "$SqlDir\pr_closed_merge_join.sql")) {
    Write-Host "[bq_export] BigQuery CLI detected. Running real queries..." -ForegroundColor Green
    $repos = ($RepoCohort -split ',') | ForEach-Object { "'$_'" }
    $repos = $repos -join ','
    $sqlOpened = Get-Content -Raw -Path "$SqlDir\pr_opened_baseline.sql"
    $sqlOpened = $sqlOpened -replace "\$\{REPOS\}", $repos -replace "\$\{START\}", $StartDate -replace "\$\{END\}", $EndDate
    $sqlClosed = Get-Content -Raw -Path "$SqlDir\pr_closed_merge_join.sql"
    $sqlClosed = $sqlClosed -replace "\$\{REPOS\}", $repos -replace "\$\{START\}", $StartDate -replace "\$\{END\}", $EndDate

    & bq query --project_id $GcpProject --use_legacy_sql=false --format=csv "$sqlOpened" | Set-Content -Path $openedCsv -Encoding utf8
    & bq query --project_id $GcpProject --use_legacy_sql=false --format=csv "$sqlClosed" | Set-Content -Path $closedCsv -Encoding utf8
}
else {
    Write-Host "[bq_export] BigQuery CLI not available or SQL missing. Writing mock data..." -ForegroundColor Yellow
    @(
        'repo_name,created_at,pr_number,author,ai_signal',
        'otel,2024-01-03,101,alice,agentic',
        'resonai,2024-01-08,55,bob,automation',
        'comfort-cat,2024-01-12,12,carol,none'
    ) | Set-Content -Path $openedCsv -Encoding utf8

    @(
        'repo_name,closed_at,pr_number,merged,merge_duration_hours,ai_signal',
        'otel,2024-01-06,101,true,72,agentic',
        'resonai,2024-01-10,55,false,48,automation',
        'comfort-cat,2024-01-15,12,true,24,none'
    ) | Set-Content -Path $closedCsv -Encoding utf8
}

function Get-CsvRowCount([string]$Path) {
    if (-not (Test-Path $Path)) { return 0 }
    $lines = Get-Content -Path $Path
    if ($lines.Count -le 1) { return 0 }
    return ($lines.Count - 1)
}

$openedCount = Get-CsvRowCount $openedCsv
$closedCount = Get-CsvRowCount $closedCsv

$summary = @()
$summary += "Phase A Export Summary"
$summary += "Timestamp: $(Get-Date -Format o)"
$summary += "Project: $GcpProject"
$summary += "Repos: $RepoCohort"
$summary += "Range: $StartDate .. $EndDate"
$summary += "Opened rows: $openedCount"
$summary += "Closed rows: $closedCount"

$summary | Set-Content -Path $summaryFile -Encoding utf8

Write-Host "[bq_export] Wrote:" -ForegroundColor Cyan
Write-Host " - $openedCsv ($openedCount rows)"
Write-Host " - $closedCsv ($closedCount rows)"
Write-Host " - $summaryFile"

exit 0
