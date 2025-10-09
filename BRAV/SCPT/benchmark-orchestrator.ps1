<#
.SYNOPSIS
    Self-optimizing orchestrator for ECRR processing benchmarks.
.DESCRIPTION
    Repeatedly invokes scripts/benchmark-process-all-ecrr-reports.ps1, parses results,
    computes a weighted score emphasizing errors detected (highest weight) and performance,
    and stops when improvement stalls or max rounds reached. Writes a simple CSV trend.
#>

[CmdletBinding()]
param(
    [ValidateRange(1, 100)]
    [int]$MaxRounds = 3,

    [ValidateRange(0, 100)]
    [double]$MinImprovementPct = 2.0,

    [ValidateRange(1, 5000)]
    [int]$ReportCount = 200,

    [ValidateRange(1, 10)]
    [int]$Iterations = 1,

    [int[]]$MaxParallelSettings = @(1,4,8),

    [switch]$IncludeAutoParallel,

    [ValidateRange(0.0, 1.0)]
    [double]$FaultyPercentage = 0.08,

    [string]$BenchmarkRoot = 'artifacts/benchmarks/process-all-ecrr-reports',

    [string]$TrendCsv = 'artifacts/benchmarks/process-all-ecrr-reports/orchestrator-trend.csv'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Get-Location
$benchRootPath = Join-Path $repoRoot $BenchmarkRoot
if (-not (Test-Path $benchRootPath)) { $null = New-Item -ItemType Directory -Path $benchRootPath -Force }

function Get-LatestBenchmarkFolder {
    param([string]$Root)
    Get-ChildItem -LiteralPath $Root -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

function Get-ScenarioErrorCount {
    param([string]$ScenarioDir)
    $errorTotal = 0
    $metrics = Get-ChildItem -LiteralPath $ScenarioDir -Recurse -File -Filter 'ecrr-compliance-metrics.json' -ErrorAction SilentlyContinue
    foreach ($m in $metrics) {
        try {
            $obj = Get-Content -Raw -Path $m.FullName | ConvertFrom-Json
            if ($null -ne $obj) {
                $candidates = @('ErrorsDetected','IssuesFound','Violations','violations','errors','errorCount')
                foreach ($key in $candidates) {
                    if ($obj.PSObject.Properties.Name -contains $key) {
                        $val = [int]($obj.$key)
                        if ($val -gt 0) { $errorTotal += $val }
                        break
                    }
                }
            }
        } catch {
            Write-Verbose "Failed to parse metrics at $($m.FullName): $($_.Exception.Message)"
        }
    }
    return $errorTotal
}

function Get-OrchestratorScore {
    param(
        [object[]]$SummaryRows,
        [hashtable]$ScenarioErrorMap
    )
    # Weights
    $errorWeight = 1000.0  # highest weight as requested
    $perfWeight = 1.0

    # Choose best scenario by Avg ms (lower is better)
    $best = $SummaryRows | Sort-Object -Property AverageMs | Select-Object -First 1
    if ($null -eq $best) { return @{ Score = 0; ChosenScenario = $null; Details = $null } }

    $scenarioName = [string]$best.Scenario
    $avgMs = [double]$best.AverageMs
    $minMs = [double]$best.MinMs
    $errors = 0
    if ($ScenarioErrorMap.ContainsKey($scenarioName)) { $errors = [int]$ScenarioErrorMap[$scenarioName] }

    # Performance contribution: inverse of avg latency, scaled
    $perfScore = if ($avgMs -gt 0) { (100000.0 / $avgMs) } else { 0 }
    $score = ($errorWeight * $errors) + ($perfWeight * $perfScore)
    return @{ Score = [math]::Round($score,2); ChosenScenario = $scenarioName; Details = @{ AvgMs=$avgMs; MinMs=$minMs; Errors=$errors } }
}

function Add-OrchestratorTrend {
    param(
        [string]$CsvFullPath,
        [string]$Scenario,
        [double]$Score,
        [double]$AvgMs,
        [double]$MinMs,
        [int]$Errors,
        [int]$ReportCount,
        [int]$Iterations,
        [string]$RunDir
    )
    $csvDir = Split-Path -Parent $CsvFullPath
    if (-not (Test-Path $csvDir)) { $null = New-Item -ItemType Directory -Path $csvDir -Force }
    if (-not (Test-Path $CsvFullPath)) {
        'timestamp,scenario,score,avgMs,minMs,errors,reportCount,iterations,runDir' | Set-Content -Path $CsvFullPath -Encoding UTF8
    }
    $ts = (Get-Date).ToString('o')
    $line = '"{0}","{1}",{2},{3},{4},{5},{6},{7},"{8}"' -f $ts,$Scenario,$Score,$AvgMs,$MinMs,$Errors,$ReportCount,$Iterations,$RunDir
    Add-Content -Path $CsvFullPath -Value $line -Encoding UTF8
}

$bestScore = 0.0
$bestRound = 0
$lastScore = 0.0

for ($round = 1; $round -le $MaxRounds; $round++) {
    Write-Host "[Orchestrator] Round $round/$MaxRounds" -ForegroundColor Cyan

    $invokeArgs = @(
        '-ReportCount', $ReportCount,
        '-Iterations', $Iterations,
        '-FaultyPercentage', $FaultyPercentage,
        '-BenchmarkRoot', $BenchmarkRoot
    )
    # Pass each MaxParallelSettings value by repeating the switch to avoid positional binding issues
    foreach ($mp in $MaxParallelSettings) { $invokeArgs += @('-MaxParallelSettings', [string]$mp) }
    if ($IncludeAutoParallel) { $invokeArgs += '-IncludeAutoParallel' }

    & pwsh -NoLogo -NoProfile -File 'scripts/benchmark-process-all-ecrr-reports.ps1' @invokeArgs

    $latest = Get-LatestBenchmarkFolder -Root $benchRootPath
    if ($null -eq $latest) { Write-Warning '[Orchestrator] No benchmark outputs found'; break }
    $runDir = $latest.FullName

    $summaryPath = Join-Path $runDir 'benchmark-summary.json'
    if (-not (Test-Path $summaryPath)) { Write-Warning "[Orchestrator] Missing $summaryPath"; break }
    $summary = Get-Content -Raw -Path $summaryPath | ConvertFrom-Json

    # Build error map per scenario by scanning scenario subfolders
    $scenarioErrors = @{}
    $subdirs = Get-ChildItem -LiteralPath $runDir -Directory
    foreach ($sd in $subdirs) {
        $name = $sd.Name -replace '-run\d+$',''
        $count = Get-ScenarioErrorCount -ScenarioDir $sd.FullName
        if ($scenarioErrors.ContainsKey($name)) { $scenarioErrors[$name] += $count } else { $scenarioErrors[$name] = $count }
    }

    $scoreObj = Get-OrchestratorScore -SummaryRows $summary -ScenarioErrorMap $scenarioErrors
    $score = [double]$scoreObj.Score
    $chosen = [string]$scoreObj.ChosenScenario
    $avgMs = [double]$scoreObj.Details.AvgMs
    $minMs = [double]$scoreObj.Details.MinMs
    $errors = [int]$scoreObj.Details.Errors

    $relRunDir = [IO.Path]::GetRelativePath($repoRoot.ProviderPath, $runDir)
    Add-OrchestratorTrend -CsvFullPath (Join-Path $repoRoot $TrendCsv) -Scenario $chosen -Score $score -AvgMs $avgMs -MinMs $minMs -Errors $errors -ReportCount $ReportCount -Iterations $Iterations -RunDir $relRunDir

    Write-Host "[Orchestrator] Score=$score Scenario=$chosen AvgMs=$avgMs Errors=$errors Run=$relRunDir" -ForegroundColor Green

    if ($score -gt $bestScore) { $bestScore = $score; $bestRound = $round }

    if ($lastScore -gt 0) {
        $improvePct = (($score - $lastScore) / [math]::Max($lastScore,1e-9)) * 100.0
        if ($improvePct -lt $MinImprovementPct) {
            Write-Host "[Orchestrator] Improvement $([math]::Round($improvePct,2))% < threshold $MinImprovementPct%. Stopping." -ForegroundColor Yellow
            break
        }
    }
    $lastScore = $score
}

Write-Host "[Orchestrator] BestScore=$bestScore at round $bestRound" -ForegroundColor Magenta

