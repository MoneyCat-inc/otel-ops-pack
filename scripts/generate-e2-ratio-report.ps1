# Generate E2 Ratio Analysis Report - Cat Nap Control Room
# Produces a markdown report from the sweep results JSON

param(
    [string]$ResultsFile = "artifacts/e2-ratio-sweep-results.json",
    [string]$OutputFile = "artifacts/e2-ratio-analysis-report.md",
    [string]$DashboardFile = "artifacts/e2-ratio-dashboard.json",
    [string]$AlertsFile = "artifacts/e2-ratio-alerts.json",
    [switch]$IncludeVisualizations,
    [switch]$GeneratePDF
)

Write-Host "== Cat Nap Control Room - E2 Ratio Analysis Report Generator ==" -ForegroundColor Green
Write-Host "Preparing a calm, detailed report..." -ForegroundColor Cyan

if (-not (Test-Path 'artifacts')) {
    New-Item -ItemType Directory -Path 'artifacts' -Force | Out-Null
}

if (-not (Test-Path $ResultsFile)) {
    Write-Error "Results file not found: $ResultsFile"
    Write-Host "Run the sweep first with: pwsh -File scripts/e2-ratio-sweep-enhanced.ps1" -ForegroundColor Yellow
    exit 1
}

try {
    $json = Get-Content -Path $ResultsFile -Raw
    if (-not $json) {
        throw "Results file is empty"
    }
    $results = $json | ConvertFrom-Json
} catch {
    Write-Error "Failed to load results: $($_.Exception.Message)"
    exit 1
}

$combos = @($results.combinations)
if ($combos.Count -eq 0) {
    Write-Error "No combinations found in results file."
    exit 1
}

function Get-NumericValues {
    param(
        [object[]]$Items,
        [string[]]$Path
    )

    $values = @()
    foreach ($item in $Items) {
        $value = $item
        foreach ($segment in $Path) {
            if ($null -eq $value) { break }
            $value = $value.$segment
        }
        if ($null -eq $value) { continue }
        try {
            $values += [double]$value
        } catch {
        }
    }
    return $values
}

function Get-Stats {
    param([double[]]$Values)

    if (-not $Values -or $Values.Count -eq 0) {
        return @{ Min = $null; Max = $null; Average = $null }
    }

    $measure = $Values | Measure-Object -Minimum -Maximum -Average
    return @{
        Min = [double]$measure.Minimum
        Max = [double]$measure.Maximum
        Average = [double]$measure.Average
    }
}

function Format-Number {
    param(
        [Nullable[Double]]$Value,
        [string]$Format = 'F2'
    )

    if ($null -eq $Value) { return 'n/a' }
    return ("{0:$Format}" -f $Value)
}

$p50Values = Get-NumericValues -Items $combos -Path @('metrics','p50_latency_ms')
$p95Values = Get-NumericValues -Items $combos -Path @('metrics','p95_latency_ms')
$p99Values = Get-NumericValues -Items $combos -Path @('metrics','p99_latency_ms')
$queueValues = Get-NumericValues -Items $combos -Path @('metrics','queue_utilization_percent')
$batchValues = Get-NumericValues -Items $combos -Path @('metrics','batch_efficiency_percent')
$throughputValues = Get-NumericValues -Items $combos -Path @('metrics','throughput_events_per_second')
$serenityValues = Get-NumericValues -Items $combos -Path @('cat_nap_metrics','serenity_score')
$purrValues = Get-NumericValues -Items $combos -Path @('cat_nap_metrics','purr_factor')

$p50Stats = Get-Stats $p50Values
$p95Stats = Get-Stats $p95Values
$p99Stats = Get-Stats $p99Values
$queueStats = Get-Stats $queueValues
$batchStats = Get-Stats $batchValues
$throughputStats = Get-Stats $throughputValues
$serenityStats = Get-Stats $serenityValues
$purrStats = Get-Stats $purrValues

$rangeP50 = if ($p50Stats.Min -ne $null -and $p50Stats.Max -ne $null) { $p50Stats.Max - $p50Stats.Min } else { $null }
$rangeP95 = if ($p95Stats.Min -ne $null -and $p95Stats.Max -ne $null) { $p95Stats.Max - $p95Stats.Min } else { $null }
$rangeP99 = if ($p99Stats.Min -ne $null -and $p99Stats.Max -ne $null) { $p99Stats.Max - $p99Stats.Min } else { $null }

$topByP95 = $combos | Where-Object { $_.metrics.p95_latency_ms -ne $null } | Sort-Object { [double]$_.metrics.p95_latency_ms } | Select-Object -First 5
$topBySerenity = $combos | Where-Object { $_.cat_nap_metrics.serenity_score -ne $null } | Sort-Object { [double]$_.cat_nap_metrics.serenity_score } -Descending | Select-Object -First 5
$topByPurr = $combos | Where-Object { $_.cat_nap_metrics.purr_factor -ne $null } | Sort-Object { [double]$_.cat_nap_metrics.purr_factor } -Descending | Select-Object -First 5

$optimalConfig = $combos |
    Where-Object {
        $_.metrics.p95_latency_ms -ne $null -and
        $_.metrics.queue_utilization_percent -ne $null -and
        [double]$_.metrics.p95_latency_ms -lt 2000 -and
        [double]$_.metrics.queue_utilization_percent -lt 70
    } |
    Sort-Object { if ($_.cat_nap_metrics.purr_factor -ne $null) { [double]$_.cat_nap_metrics.purr_factor } else { [double]::MinValue } } -Descending |
    Select-Object -First 1

$recommendations = @()
if ($p95Stats.Min -ne $null) {
    $recommendations += "Low latency anchor: {0}" -f (($topByP95 | Select-Object -First 1).test_id)
}
if ($queueStats.Min -ne $null) {
    $lowestQueue = $combos | Where-Object { $_.metrics.queue_utilization_percent -ne $null } | Sort-Object { [double]$_.metrics.queue_utilization_percent } | Select-Object -First 1
    if ($lowestQueue) {
        $recommendations += "Lightest queue: {0}" -f $lowestQueue.test_id
    }
}
if ($serenityStats.Max -ne $null) {
    $highSerenity = $combos | Where-Object { $_.cat_nap_metrics.serenity_score -ne $null } | Sort-Object { [double]$_.cat_nap_metrics.serenity_score } -Descending | Select-Object -First 1
    if ($highSerenity) {
        $recommendations += "Most serene: {0}" -f $highSerenity.test_id
    }
}
if ($purrStats.Max -ne $null) {
    $highPurr = $combos | Where-Object { $_.cat_nap_metrics.purr_factor -ne $null } | Sort-Object { [double]$_.cat_nap_metrics.purr_factor } -Descending | Select-Object -First 1
    if ($highPurr) {
        $recommendations += "Top purr factor: {0}" -f $highPurr.test_id
    }
}

$highLatencyConfigs = $combos | Where-Object { $_.metrics.p95_latency_ms -gt 2000 }
$highQueueConfigs = $combos | Where-Object { $_.metrics.queue_utilization_percent -gt 80 }
$lowSerenityConfigs = $combos | Where-Object { $_.cat_nap_metrics.serenity_score -lt 70 }
$dataLossConfigs = $combos | Where-Object { $_.metrics.data_loss_count -gt 0 }

$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine('# Cat Nap Control Room - E2 Ratio Analysis Report')
$null = $sb.AppendLine('')
$null = $sb.AppendLine("**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')")
$null = $sb.AppendLine("**Analysis Period:** $($results.test_start_time) - $($results.test_end_time)")
$null = $sb.AppendLine("**Total Combinations Tested:** $($combos.Count)")
$null = $sb.AppendLine("**Test Duration per Combination:** $($results.test_duration_per_combination_minutes) minutes")
$null = $sb.AppendLine('')
$null = $sb.AppendLine('---')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('## Executive Summary =^.^=')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('The E2 ratio sweep evaluated agent and gateway timeout pairs for the Cat Nap Control Room. The figures below highlight the best candidates to keep observability calm and responsive.')
$null = $sb.AppendLine('')

$summary = $results.summary
$bestP95 = if ($summary) { $summary.best_p95_latency_ms } else { $p95Stats.Min }
$worstP95 = if ($summary) { $summary.worst_p95_latency_ms } else { $p95Stats.Max }
$avgQueue = if ($summary) { $summary.average_queue_utilization_percent } else { $queueStats.Average }
$avgSerenity = if ($summary) { $summary.average_serenity_score } else { $serenityStats.Average }
$maxPurr = if ($summary) { $summary.max_purr_factor } else { $purrStats.Max }

$null = $sb.AppendLine("- **Best P95 Latency:** $(Format-Number $bestP95 'F1') ms")
$null = $sb.AppendLine("- **Worst P95 Latency:** $(Format-Number $worstP95 'F1') ms")
$null = $sb.AppendLine("- **Average Queue Utilization:** $(Format-Number $avgQueue 'F1')%");
$null = $sb.AppendLine("- **Average Serenity Score:** $(Format-Number $avgSerenity 'F1')")
$null = $sb.AppendLine("- **Max Purr Factor:** $(Format-Number $maxPurr 'F1')")
$null = $sb.AppendLine('')
$null = $sb.AppendLine('---')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('## Performance Analysis')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('| Metric | Best | Worst | Average | Range |')
$null = $sb.AppendLine('|--------|------|-------|---------|-------|')
$null = $sb.AppendLine("| P50 Latency (ms) | $(Format-Number $p50Stats.Min 'F1') | $(Format-Number $p50Stats.Max 'F1') | $(Format-Number $p50Stats.Average 'F1') | $(Format-Number $rangeP50 'F1') |")
$null = $sb.AppendLine("| P95 Latency (ms) | $(Format-Number $p95Stats.Min 'F1') | $(Format-Number $p95Stats.Max 'F1') | $(Format-Number $p95Stats.Average 'F1') | $(Format-Number $rangeP95 'F1') |")
$null = $sb.AppendLine("| P99 Latency (ms) | $(Format-Number $p99Stats.Min 'F1') | $(Format-Number $p99Stats.Max 'F1') | $(Format-Number $p99Stats.Average 'F1') | $(Format-Number $rangeP99 'F1') |")
$null = $sb.AppendLine('')
$null = $sb.AppendLine('| Metric | Best | Worst | Average |')
$null = $sb.AppendLine('|--------|------|-------|---------|')
$null = $sb.AppendLine("| Queue Utilization (%) | $(Format-Number $queueStats.Min 'F1') | $(Format-Number $queueStats.Max 'F1') | $(Format-Number $queueStats.Average 'F1') |")
$null = $sb.AppendLine("| Batch Efficiency (%) | $(Format-Number $batchStats.Min 'F1') | $(Format-Number $batchStats.Max 'F1') | $(Format-Number $batchStats.Average 'F1') |")
$null = $sb.AppendLine("| Throughput (events/sec) | $(Format-Number $throughputStats.Min 'F1') | $(Format-Number $throughputStats.Max 'F1') | $(Format-Number $throughputStats.Average 'F1') |")
$null = $sb.AppendLine('')

function Append-TopTable {
    param(
        [System.Text.StringBuilder]$Builder,
        [string]$Title,
        [object[]]$Rows,
        [string[]]$Columns
    )

    if (-not $Rows -or $Rows.Count -eq 0) { return }
    $null = $Builder.AppendLine("### $Title")
    $null = $Builder.AppendLine('')
    $header = '| # | Test ID | Agent Timeout | Gateway Timeout | P95 (ms) | Serenity | Purr |'
    $separator = '|---|---------|---------------|-----------------|---------|---------|------|'
    if ($Columns) {
        $header = $Columns[0]
        $separator = $Columns[1]
    }
    $null = $Builder.AppendLine($header)
    $null = $Builder.AppendLine($separator)
    $rank = 1
    foreach ($row in $Rows) {
        $p95 = if ($row.metrics.p95_latency_ms -ne $null) { Format-Number ([double]$row.metrics.p95_latency_ms) 'F1' } else { 'n/a' }
        $serenity = if ($row.cat_nap_metrics.serenity_score -ne $null) { Format-Number ([double]$row.cat_nap_metrics.serenity_score) 'F1' } else { 'n/a' }
        $purr = if ($row.cat_nap_metrics.purr_factor -ne $null) { Format-Number ([double]$row.cat_nap_metrics.purr_factor) 'F1' } else { 'n/a' }
        $null = $Builder.AppendLine("| $rank | $($row.test_id) | $($row.agent_timeout) | $($row.gateway_timeout) | $p95 | $serenity | $purr |")
        $rank++
    }
    $null = $Builder.AppendLine('')
}

Append-TopTable -Builder $sb -Title 'Top Low-Latency Configurations' -Rows $topByP95 -Columns @('| # | Test ID | Agent Timeout | Gateway Timeout | P95 (ms) | Serenity | Purr |','|---|---------|---------------|-----------------|---------|---------|------|')
Append-TopTable -Builder $sb -Title 'Top Serenity Scores' -Rows $topBySerenity -Columns @('| # | Test ID | Agent Timeout | Gateway Timeout | Serenity | P95 (ms) | Purr |','|---|---------|---------------|-----------------|---------|---------|------|')
Append-TopTable -Builder $sb -Title 'Top Purr Factors' -Rows $topByPurr -Columns @('| # | Test ID | Agent Timeout | Gateway Timeout | Purr | Serenity | P95 (ms) |','|---|---------|---------------|-----------------|------|---------|---------|')

if ($optimalConfig) {
    $null = $sb.AppendLine('### Recommended Configuration')
    $null = $sb.AppendLine('')
    $null = $sb.AppendLine("**$($optimalConfig.test_id)** keeps latency low while holding queue utilisation under 70%. Key readings:")
    $null = $sb.AppendLine("- Agent Timeout: $($optimalConfig.agent_timeout)")
    $null = $sb.AppendLine("- Gateway Timeout: $($optimalConfig.gateway_timeout)")
    $null = $sb.AppendLine("- P95 Latency: $(Format-Number ([double]$optimalConfig.metrics.p95_latency_ms) 'F1') ms")
    $null = $sb.AppendLine("- Queue Utilisation: $(Format-Number ([double]$optimalConfig.metrics.queue_utilization_percent) 'F1')%")
    $null = $sb.AppendLine("- Serenity Score: $(Format-Number ([double]$optimalConfig.cat_nap_metrics.serenity_score) 'F1')")
    $null = $sb.AppendLine("- Purr Factor: $(Format-Number ([double]$optimalConfig.cat_nap_metrics.purr_factor) 'F1')")
    $null = $sb.AppendLine('')
}

if ($recommendations.Count -gt 0) {
    $null = $sb.AppendLine('### Highlights')
    $null = $sb.AppendLine('')
    foreach ($rec in $recommendations) {
        $null = $sb.AppendLine("- $rec")
    }
    $null = $sb.AppendLine('')
}

if ($highLatencyConfigs.Count -gt 0 -or $highQueueConfigs.Count -gt 0 -or $lowSerenityConfigs.Count -gt 0 -or $dataLossConfigs.Count -gt 0) {
    $null = $sb.AppendLine('### Warnings')
    $null = $sb.AppendLine('')
    if ($highLatencyConfigs.Count -gt 0) {
        $null = $sb.AppendLine("- $($highLatencyConfigs.Count) combinations exceed 2000 ms P95 latency.")
    }
    if ($highQueueConfigs.Count -gt 0) {
        $null = $sb.AppendLine("- $($highQueueConfigs.Count) combinations push queue utilisation above 80%.")
    }
    if ($lowSerenityConfigs.Count -gt 0) {
        $null = $sb.AppendLine("- $($lowSerenityConfigs.Count) combinations drop serenity below 70.")
    }
    if ($dataLossConfigs.Count -gt 0) {
        $null = $sb.AppendLine("- $($dataLossConfigs.Count) combinations reported data loss events.")
    }
    $null = $sb.AppendLine('')
}

$null = $sb.AppendLine('### Monitoring Checklist')
$null = $sb.AppendLine('')
$null = $sb.AppendLine("- Dashboard JSON: $DashboardFile")
$null = $sb.AppendLine("- Alert rules: $AlertsFile")
$null = $sb.AppendLine('- Filter logs in SigNoz Logs view: dataset = "e2_ratio_sweep"')
$null = $sb.AppendLine('- Schedule regular sweeps to confirm the configuration holds steady')
$null = $sb.AppendLine('')

$null = $sb.AppendLine('## Cat Nap Control Room Mantra')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('Steady rhythms, quiet queues, predictable latency. Keep the dashboards gentle so the team can rest easy.')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('---')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('*Report generated by the Cat Nap Control Room E2 toolkit.*')

$reportText = $sb.ToString()
$reportText | Set-Content -Path $OutputFile -Encoding UTF8

Write-Host "Report saved to: $OutputFile" -ForegroundColor Green
Write-Host "Combinations analysed: $($combos.Count)" -ForegroundColor White
Write-Host "Best observed P95 latency: $(Format-Number $bestP95 'F1') ms" -ForegroundColor White
if ($optimalConfig) {
    Write-Host "Recommended configuration: $($optimalConfig.test_id)" -ForegroundColor Green
} else {
    Write-Host "No configuration met the balanced criteria." -ForegroundColor Yellow
}

if ($IncludeVisualizations) {
    Write-Host 'Visualization exports are not automated yet. Use the dashboard script to refresh panels.' -ForegroundColor Yellow
}

if ($GeneratePDF) {
    Write-Host 'PDF export is not implemented. Convert the markdown with your preferred renderer.' -ForegroundColor Yellow
}

Write-Host "Report generation complete. =^.^=" -ForegroundColor Cyan
