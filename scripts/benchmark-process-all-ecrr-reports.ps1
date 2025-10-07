<#
.SYNOPSIS
    Benchmark harness for scripts/process-all-ecrr-reports.ps1.
.DESCRIPTION
    Seeds synthetic ECRR reports (including controlled faults), runs the processing script with various
    parallel settings, and captures timing metrics plus summary artifacts under artifacts/benchmarks.
#>

[CmdletBinding()]
param(
    [ValidateRange(1, 5000)]
    [int]$ReportCount = 1200,

    [int[]]$MaxParallelSettings = @(1, 2, 4, 6, 8, 12, 16),

    # Convenience CLI input: comma-separated values for MaxParallel (e.g. "1,2,4,6,8,12,16")
    [string]$MaxParallelCsv,

    [switch]$IncludeAutoParallel,

    [ValidateRange(1, 10)]
    [int]$Iterations = 2,

    [string]$BenchmarkRoot = 'artifacts/benchmarks/process-all-ecrr-reports',

    [switch]$KeepSyntheticReports,

    [string]$TrendCsvPath = 'artifacts/benchmarks/process-all-ecrr-reports/processing-trend.csv',

    [ValidateRange(0,1)]
    [double]$FaultyPercentage = 0.15,

    [int]$RandomSeed
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Get-Location
$ecrrDir = Join-Path $repoRoot 'docs/ECRR_REPORTS'
if (-not (Test-Path $ecrrDir)) {
    throw "ECRR reports directory not found at $ecrrDir"
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runRoot = Join-Path $repoRoot $BenchmarkRoot
$runDir = Join-Path $runRoot $timestamp
$null = New-Item -ItemType Directory -Path $runDir -Force

$syntheticTag = "benchmark-load-$timestamp"
$createdFiles = New-Object System.Collections.Generic.List[string]
$random = if ($PSBoundParameters.ContainsKey('RandomSeed')) {
    [System.Random]::new($RandomSeed)
} else {
    [System.Random]::new()
}
$parsedCsvValues = @()
if ($PSBoundParameters.ContainsKey('MaxParallelCsv') -and [string]::IsNullOrWhiteSpace($MaxParallelCsv) -eq $false) {
    try {
        $parsedCsvValues = @($MaxParallelCsv.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ } | Where-Object { $_ -ge 1 })
        if ($parsedCsvValues.Count -gt 0) {
            $MaxParallelSettings = @($parsedCsvValues | Sort-Object -Unique)
            Write-Host ("[Benchmark] Using MaxParallel settings from -MaxParallelCsv: {0}" -f ($MaxParallelSettings -join ',')) -ForegroundColor Cyan
        } else {
            Write-Warning "[Benchmark] -MaxParallelCsv provided but no valid integers were parsed. Falling back to MaxParallelSettings."
        }
    } catch {
        Write-Warning "[Benchmark] Failed to parse -MaxParallelCsv: $($_.Exception.Message). Falling back to MaxParallelSettings."
    }
}

$faultModeCounts = @{}
$faultyReports = 0

function New-BenchmarkReportContent {
    param(
        [int]$Index,
        [string]$Timestamp,
        [System.Random]$Random,
        [bool]$IsFaulty
    )

    $base = @"
# Benchmark ECRR Report $Index

## ?? 1. Examine
- Finding: Synthetic issue trace $Index
- Evidence: Benchmark log sample $Index

## ?? 2. Clean
- Action: Applied synthetic remediation
- Logs: images/benchmark/$Index.png (placeholder)

## ?? 3. Report
- Status: COMPLETE
- Metrics: Throughput baseline established

## ?? 4. Role
- Agent: Benchmark Harness
- Actor Declaration: Automated synthetic run $Timestamp

### ECRR Gate
- ProductionReady: true
- EvidenceReference: benchmark-artifacts/$Timestamp

"@

    if (-not $IsFaulty) {
        return [pscustomobject]@{
            Content = $base
            FaultMode = 'None'
        }
    }

    $faultModes = [string[]]@('MissingStatus', 'MissingSection', 'MissingEvidence', 'MissingGate')
    $mode = $faultModes[$Random.Next($faultModes.Count)]

    switch ($mode) {
        'MissingStatus' {
            $content = @"
# Benchmark ECRR Report $Index

## ?? 1. Examine
- Finding: Synthetic issue trace $Index
- Evidence: Benchmark log sample $Index

## ?? 2. Clean
- Action: Applied synthetic remediation
- Logs: images/benchmark/$Index.png (placeholder)

## ?? 3. Report
- Metrics: Throughput baseline established

## ?? 4. Role
- Agent: Benchmark Harness
- Actor Declaration: Automated synthetic run $Timestamp

### ECRR Gate
- ProductionReady: true
- EvidenceReference: benchmark-artifacts/$Timestamp

"@
        }
        'MissingSection' {
            $content = @"
# Benchmark ECRR Report $Index

## ?? 1. Examine
- Finding: Synthetic issue trace $Index
- Evidence: Benchmark log sample $Index

## ?? 2. Clean
- Action: Applied synthetic remediation
- Logs: images/benchmark/$Index.png (placeholder)

## 4 Role Alignment
- Agent: Benchmark Harness
- Actor Declaration: Automated synthetic run $Timestamp

### ECRR Gate
- ProductionReady: true
- EvidenceReference: benchmark-artifacts/$Timestamp

"@
        }
        'MissingEvidence' {
            $content = @"
# Benchmark ECRR Report $Index

## ?? 1. Examine
- Finding: Synthetic issue trace $Index
- Notes: Benchmark observation without explicit evidence tag

## ?? 2. Clean
- Action: Applied synthetic remediation
- Logs: images/benchmark/$Index.png (placeholder)

## ?? 3. Report
- Status: COMPLETE
- Metrics: Throughput baseline established

## ?? 4. Role
- Agent: Benchmark Harness
- Actor Declaration: Automated synthetic run $Timestamp

### ECRR Gate
- ProductionReady: true
- TracePointer: benchmark-artifacts/$Timestamp

"@
        }
        'MissingGate' {
            $content = @"
# Benchmark ECRR Report $Index

## ?? 1. Examine
- Finding: Synthetic issue trace $Index
- Evidence: Benchmark log sample $Index

## ?? 2. Clean
- Action: Applied synthetic remediation
- Logs: images/benchmark/$Index.png (placeholder)

## ?? 3. Report
- Status: COMPLETE
- Metrics: Throughput baseline established

## ?? 4. Role
- Agent: Benchmark Harness
- Actor Declaration: Automated synthetic run $Timestamp

### Observability Gate
- ProductionReady: true
- EvidenceReference: benchmark-artifacts/$Timestamp

"@
        }
        Default {
            $content = $base
        }
    }

    return [pscustomobject]@{
        Content = $content
        FaultMode = $mode
    }
}

Write-Host "[Benchmark] Seeding $ReportCount synthetic ECRR reports (tag=$syntheticTag)" -ForegroundColor Cyan
for ($i = 1; $i -le $ReportCount; $i++) {
    $fileName = "${syntheticTag}-${i:D4}.md"
    $filePath = Join-Path $ecrrDir $fileName
    $isFaulty = $false
    if ($FaultyPercentage -gt 0) {
        $isFaulty = $random.NextDouble() -lt $FaultyPercentage
    }
    $reportInfo = New-BenchmarkReportContent -Index $i -Timestamp $timestamp -Random $random -IsFaulty:$isFaulty
    Set-Content -Path $filePath -Value $reportInfo.Content -Encoding UTF8
    $createdFiles.Add($filePath)
    if ($isFaulty -and $reportInfo.FaultMode -ne 'None') {
        $faultyReports++
        if (-not $faultModeCounts.ContainsKey($reportInfo.FaultMode)) {
            $faultModeCounts[$reportInfo.FaultMode] = 0
        }
        $faultModeCounts[$reportInfo.FaultMode]++
    }
}

Write-Host "[Benchmark] Synthetic reports created: $($createdFiles.Count)" -ForegroundColor Green
if ($faultyReports -gt 0) {
    $faultPercent = [math]::Round(($faultyReports / $ReportCount) * 100, 2)
    Write-Host "[Benchmark] Fault injection applied to $faultyReports reports (${faultPercent}%)" -ForegroundColor Yellow
    foreach ($entry in $faultModeCounts.GetEnumerator() | Sort-Object Name) {
        Write-Host "  - $($entry.Name): $($entry.Value)" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "[Benchmark] Fault injection disabled for this run" -ForegroundColor Cyan
}

$scenarios = New-Object System.Collections.Generic.List[object]
foreach ($max in $MaxParallelSettings) {
    if ($max -lt 1) { continue }
    $scenarios.Add([pscustomobject]@{
        Name = "max-$max"
        Arguments = @('-MaxParallel', $max)
    })
}
if ($IncludeAutoParallel) {
    $scenarios.Add([pscustomobject]@{
        Name = 'auto-parallel'
        Arguments = @('-AutoParallel')
    })
}
if ($scenarios.Count -eq 0) {
    throw 'No scenarios to execute. Provide MaxParallelSettings or IncludeAutoParallel.'
}

$results = New-Object System.Collections.Generic.List[object]
$summary = New-Object System.Collections.Generic.List[object]

foreach ($scenario in $scenarios) {
    for ($iteration = 1; $iteration -le $Iterations; $iteration++) {
        $scenarioOutputDir = Join-Path $runDir "$($scenario.Name)-run$iteration"
        $null = New-Item -ItemType Directory -Path $scenarioOutputDir -Force

        $arguments = @('-NoLogo', '-NoProfile', '-File', 'scripts/process-all-ecrr-reports.ps1', '-OutputDir', $scenarioOutputDir)
        $arguments += $scenario.Arguments

        Write-Host "[Benchmark] Running scenario '$($scenario.Name)' iteration $iteration" -ForegroundColor Yellow
        $measurement = Measure-Command {
            & pwsh.exe @arguments
        }

        $metricsPath = Join-Path $scenarioOutputDir 'ecrr-compliance-metrics.json'
        $missingFourCount = 0
        $missingStatusCount = 0
        $qualityIssueCount = 0
        if (Test-Path $metricsPath) {
            try {
                $metrics = Get-Content -Path $metricsPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $missingFourCount = @($metrics.MissingFourSection).Count
                $missingStatusCount = @($metrics.MissingStatus).Count
                $qualityIssueCount = @($metrics.QualityIssues).Count
            } catch {
                Write-Warning ("[Benchmark] Failed to parse compliance metrics for {0} run {1}: {2}" -f $scenario.Name, $iteration, $_.Exception.Message)
            }
        } else {
            Write-Warning "[Benchmark] Compliance metrics not found for $($scenario.Name) run $iteration"
        }
        $issuesFound = $missingFourCount + $missingStatusCount + $qualityIssueCount

        $result = [pscustomobject]@{
            Scenario = $scenario.Name
            Iteration = $iteration
            MaxParallel = if ($scenario.Name -like 'max-*') { [int]($scenario.Name.Split('-')[1]) } else { $null }
            UsedAutoParallel = ($scenario.Name -eq 'auto-parallel')
            TotalMilliseconds = [math]::Round($measurement.TotalMilliseconds, 2)
            TotalSeconds = [math]::Round($measurement.TotalSeconds, 3)
            Timestamp = (Get-Date).ToString('o')
            OutputDir = [IO.Path]::GetRelativePath($repoRoot.ProviderPath, $scenarioOutputDir)
            IssuesFound = $issuesFound
            MissingFourSection = $missingFourCount
            MissingStatus = $missingStatusCount
            QualityIssueCount = $qualityIssueCount
        }
        $results.Add($result)
    }
}

$grouped = $results | Group-Object -Property Scenario
foreach ($group in $grouped) {
    $durations = $group.Group.TotalMilliseconds
    $issues = $group.Group.IssuesFound
    $summary.Add([pscustomobject]@{
        Scenario = $group.Name
        Runs = $group.Count
        AverageMs = [math]::Round(($durations | Measure-Object -Average).Average, 2)
        MinMs = [math]::Round(($durations | Measure-Object -Minimum).Minimum, 2)
        MaxMs = [math]::Round(($durations | Measure-Object -Maximum).Maximum, 2)
        AverageIssues = [math]::Round((($issues | Measure-Object -Average).Average), 2)
    })
}

$resultsPath = Join-Path $runDir 'benchmark-results.json'
$summaryPath = Join-Path $runDir 'benchmark-summary.json'
$markdownPath = Join-Path $runDir 'benchmark-summary.md'

$results | ConvertTo-Json -Depth 6 | Out-File -FilePath $resultsPath -Encoding UTF8
$summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $summaryPath -Encoding UTF8

$markdown = @()
$markdown += "# ECRR Processing Benchmark ($timestamp)"
$markdown += ""
$markdown += "- Synthetic reports: $ReportCount"
$markdown += "- Iterations per scenario: $Iterations"
$markdown += "- Synthetic tag: $syntheticTag"
$markdown += "- Faulty percentage target: $FaultyPercentage"
$markdown += "- Source script: scripts/process-all-ecrr-reports.ps1"
$markdown += ""
$markdown += "| Scenario | Runs | Avg (ms) | Min (ms) | Max (ms) | Avg Issues |"
$markdown += "| --- | ---: | ---: | ---: | ---: | ---: |"
foreach ($row in $summary) {
    $markdown += "| $($row.Scenario) | $($row.Runs) | $($row.AverageMs) | $($row.MinMs) | $($row.MaxMs) | $($row.AverageIssues) |"
}
$markdown += ""
$markdown += "Results JSON: $([IO.Path]::GetRelativePath($repoRoot.ProviderPath, $resultsPath))"
$markdown += ""
$markdown += "Summary JSON: $([IO.Path]::GetRelativePath($repoRoot.ProviderPath, $summaryPath))"

$markdown | Set-Content -Path $markdownPath -Encoding UTF8

Write-Host "[Benchmark] Results written to $([IO.Path]::GetRelativePath($repoRoot.ProviderPath, $runDir))" -ForegroundColor Green

# Append trend CSV line for quick historical tracking
try {
    $bestRow = $summary | Sort-Object -Property AverageMs | Select-Object -First 1
    if ($null -ne $bestRow) {
        $chosenScenario = [string]$bestRow.Scenario
        $parallelism = if ($chosenScenario -like 'max-*') { $chosenScenario.Split('-')[1] } else { 'auto' }
        $bestMs = [double]$bestRow.MinMs
        $averageMs = [double]$bestRow.AverageMs
        $issuesForScenario = 0
        $scenarioSample = $results | Where-Object { $_.Scenario -eq $chosenScenario } | Select-Object -First 1
        if ($scenarioSample) {
            $issuesForScenario = [int]$scenarioSample.IssuesFound
        }
        $baseScore = if ($averageMs -gt 0) { [math]::Round(($ReportCount / $averageMs) * 1000, 2) } else { 0 }

        $csvDir = Split-Path -Parent (Join-Path $repoRoot $TrendCsvPath)
        if (-not (Test-Path $csvDir)) { $null = New-Item -ItemType Directory -Path $csvDir -Force }
        $csvFullPath = Join-Path $repoRoot $TrendCsvPath
        $existingRows = @()
        $headerLine = 'timestamp,reportCount,iterations,scenario,parallelism,issuesFound,faultyReports,faultyPercentage,bestMs,averageMs,score,bonus,scoreWithBonus,runDir'
        if (Test-Path $csvFullPath) {
            try { $existingRows = Import-Csv -Path $csvFullPath } catch { $existingRows = @() }
            if ($existingRows.Count -gt 0 -and ($existingRows[0].PSObject.Properties.Name -notcontains 'issuesFound')) {
                $convertedLines = @($headerLine)
                foreach ($row in $existingRows) {
                    $reportCountLegacy = [int]$row.reportCount
                    $iterationsLegacy = [int]$row.iterations
                    $bestLegacy = [double]$row.bestMs
                    $avgLegacy = [double]$row.averageMs
                    $baseScoreLegacy = 0
                    if ($avgLegacy -gt 0) {
                        $baseScoreLegacy = [math]::Round(($reportCountLegacy / $avgLegacy) * 1000, 2)
                    }
                    $convertedLines += ('"{0}",{1},{2},"{3}","{4}",{5},{6},{7},{8},{9},{10},{11},{12},"{13}"' -f $row.timestamp, $reportCountLegacy, $iterationsLegacy, $row.scenario, $row.parallelism, 0, 0, 0, [math]::Round($bestLegacy, 2), [math]::Round($avgLegacy, 2), $baseScoreLegacy, 0, $baseScoreLegacy, $row.runDir)
                }
                Set-Content -Path $csvFullPath -Value $convertedLines -Encoding UTF8
                $existingRows = Import-Csv -Path $csvFullPath
            }
        } else {
            $headerLine | Set-Content -Path $csvFullPath -Encoding UTF8
        }
        $previousEntry = $null
        if ($existingRows.Count -gt 0) {
            $previousEntry = $existingRows[-1]
        }
        $previousIssuesCount = $null
        if (($null -ne $previousEntry) -and ($null -ne $previousEntry.issuesFound)) {
            $previousIssuesCount = [int]$previousEntry.issuesFound
        }
        $bonus = 0
        if ($null -ne $previousIssuesCount) {
            $bonus = ($previousIssuesCount - $issuesForScenario) * 1000
        }
        $bonus = [math]::Round($bonus, 2)
        $scoreWithBonus = [math]::Round($baseScore + $bonus, 2)

        $relRunDir = [IO.Path]::GetRelativePath($repoRoot.ProviderPath, $runDir)
        $faultPercentActual = if ($ReportCount -gt 0) { [math]::Round(($faultyReports / $ReportCount) * 100, 2) } else { 0 }
        $line = ('"{0}",{1},{2},"{3}","{4}",{5},{6},{7},{8},{9},{10},{11},{12},"{13}"' -f (Get-Date).ToString('o'), $ReportCount, $Iterations, $chosenScenario, $parallelism, $issuesForScenario, $faultyReports, $faultPercentActual, [math]::Round($bestMs, 2), [math]::Round($averageMs, 2), $baseScore, $bonus, $scoreWithBonus, $relRunDir)
        Add-Content -Path $csvFullPath -Value $line -Encoding UTF8

        Write-Host "[Benchmark] Score base=$baseScore bonus=$bonus total=$scoreWithBonus issues=$issuesForScenario (prev=$previousIssuesCount)" -ForegroundColor Magenta
        Write-Host "[Benchmark] Trend appended: $line" -ForegroundColor DarkCyan

        # Archive best run if this score beats all previous entries
        try {
            $previousMax = $null
            if ($existingRows.Count -gt 0 -and ($existingRows[0].PSObject.Properties.Name -contains 'scoreWithBonus')) {
                $previousMax = ($existingRows | ForEach-Object { [double]::Parse("" + $_.scoreWithBonus) } | Measure-Object -Maximum).Maximum
            }

            $isNewBest = $false
            if ($null -eq $previousMax) {
                $isNewBest = $true
            } elseif ([double]$scoreWithBonus -gt [double]$previousMax) {
                $isNewBest = $true
            }

            if ($isNewBest) {
                $bestRoot = Join-Path $runRoot 'best-runs'
                if (-not (Test-Path $bestRoot)) { $null = New-Item -ItemType Directory -Path $bestRoot -Force }
                $safeScenario = ($chosenScenario -replace '[^a-zA-Z0-9_-]', '_')
                $archiveName = ("best-{0}-{1}-{2}" -f $timestamp, $safeScenario, ($scoreWithBonus.ToString().Replace('.', '_')))
                $archiveDir = Join-Path $bestRoot $archiveName
                if (-not (Test-Path $archiveDir)) { $null = New-Item -ItemType Directory -Path $archiveDir -Force }

                # Copy the full run directory for complete context
                Copy-Item -Path $runDir -Destination (Join-Path $archiveDir (Split-Path $runDir -Leaf)) -Recurse -Force -ErrorAction SilentlyContinue

                # Save the winning CSV row for quick reference
                $bestRowFile = Join-Path $archiveDir 'best-trend-row.csv'
                Set-Content -Path $bestRowFile -Value $headerLine -Encoding UTF8
                Add-Content -Path $bestRowFile -Value $line -Encoding UTF8

                # Also record a small JSON metadata file
                $meta = [pscustomobject]@{
                    timestamp = (Get-Date).ToString('o')
                    scenario = $chosenScenario
                    parallelism = $parallelism
                    reportCount = $ReportCount
                    iterations = $Iterations
                    faultyReports = $faultyReports
                    faultyPercentage = $faultPercentActual
                    bestMs = [math]::Round($bestMs, 2)
                    averageMs = [math]::Round($averageMs, 2)
                    score = $baseScore
                    bonus = $bonus
                    scoreWithBonus = $scoreWithBonus
                    sourceRunDir = $relRunDir
                }
                $meta | ConvertTo-Json -Depth 5 | Out-File -FilePath (Join-Path $archiveDir 'best-metadata.json') -Encoding UTF8

                Write-Host ("[Benchmark] 🏆 New best score detected ({0}). Archived to {1}" -f $scoreWithBonus, $archiveDir) -ForegroundColor Green
            }
        } catch {
            Write-Warning ("[Benchmark] Failed to archive best run: {0}" -f $_.Exception.Message)
        }
    }
} catch {
    Write-Warning "[Benchmark] Failed to append trend CSV: $($_.Exception.Message)"
}

if (-not $KeepSyntheticReports) {
    Write-Host "[Benchmark] Cleaning up synthetic reports" -ForegroundColor Cyan
    foreach ($file in $createdFiles) {
        if (Test-Path $file) {
            Remove-Item -Path $file -Force
        }
    }
} else {
    Write-Host "[Benchmark] Synthetic reports retained (KeepSyntheticReports flag set)" -ForegroundColor Yellow
}

Write-Host "[Benchmark] Complete" -ForegroundColor Green


