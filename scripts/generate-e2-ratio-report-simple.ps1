# Generate E2 Ratio Analysis Report - Simplified Version
# Cat Nap Control Room - Basic report generation

param(
    [string]$ResultsFile = "artifacts/e2-ratio-sweep-results.json",
    [string]$OutputFile = "artifacts/e2-ratio-analysis-report.md"
)

Write-Host "🐱 === Cat Nap Control Room - E2 Ratio Analysis Report Generator (Simple) ===" -ForegroundColor Green
Write-Host "Creating comprehensive E2 ratio analysis report..." -ForegroundColor Cyan

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
}

# Check if results file exists
if (-not (Test-Path $ResultsFile)) {
    Write-Error "Results file not found: $ResultsFile"
    Write-Host "Please run the E2 ratio sweep first: pwsh -File scripts/e2-ratio-sweep-simple.ps1" -ForegroundColor Yellow
    exit 1
}

# Load results
try {
    $results = Get-Content $ResultsFile | ConvertFrom-Json
    Write-Host "✅ Loaded results for $($results.combinations.Count) combinations" -ForegroundColor Green
} catch {
    Write-Error "Failed to load results file: $($_.Exception.Message)"
    exit 1
}

# Calculate summary statistics
$allP50s = $results.combinations | ForEach-Object { $_.metrics.p50_latency_ms }
$allP95s = $results.combinations | ForEach-Object { $_.metrics.p95_latency_ms }
$allP99s = $results.combinations | ForEach-Object { $_.metrics.p99_latency_ms }
$allQueueUtils = $results.combinations | ForEach-Object { $_.metrics.queue_utilization_percent }
$allSerenityScores = $results.combinations | ForEach-Object { $_.cat_nap_metrics.serenity_score }
$allPurrFactors = $results.combinations | ForEach-Object { $_.cat_nap_metrics.purr_factor }

$bestP50 = ($allP50s | Measure-Object -Minimum).Minimum
$worstP50 = ($allP50s | Measure-Object -Maximum).Maximum
$avgP50 = [math]::Round(($allP50s | Measure-Object -Average).Average, 2)

$bestP95 = ($allP95s | Measure-Object -Minimum).Minimum
$worstP95 = ($allP95s | Measure-Object -Maximum).Maximum
$avgP95 = [math]::Round(($allP95s | Measure-Object -Average).Average, 2)

$bestP99 = ($allP99s | Measure-Object -Minimum).Minimum
$worstP99 = ($allP99s | Measure-Object -Maximum).Maximum
$avgP99 = [math]::Round(($allP99s | Measure-Object -Average).Average, 2)

$bestQueue = ($allQueueUtils | Measure-Object -Minimum).Minimum
$worstQueue = ($allQueueUtils | Measure-Object -Maximum).Maximum
$avgQueue = [math]::Round(($allQueueUtils | Measure-Object -Average).Average, 2)

$bestSerenity = ($allSerenityScores | Measure-Object -Maximum).Maximum
$worstSerenity = ($allSerenityScores | Measure-Object -Minimum).Minimum
$avgSerenity = [math]::Round(($allSerenityScores | Measure-Object -Average).Average, 1)

$bestPurr = ($allPurrFactors | Measure-Object -Maximum).Maximum
$worstPurr = ($allPurrFactors | Measure-Object -Minimum).Minimum
$avgPurr = [math]::Round(($allPurrFactors | Measure-Object -Average).Average, 1)

# Find optimal configuration
$optimalConfig = $results.combinations | Where-Object { 
    $_.metrics.p95_latency_ms -lt 2000 -and 
    $_.metrics.queue_utilization_percent -lt 70 -and
    $_.cat_nap_metrics.serenity_score -gt 80
} | Sort-Object { $_.cat_nap_metrics.purr_factor } -Descending | Select-Object -First 1

# Generate report
$report = @"
# Cat Nap Control Room - E2 Ratio Analysis Report

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
**Analysis Period:** $($results.test_start_time) - $($results.test_end_time)
**Total Combinations Tested:** $($results.combinations.Count)
**Test Duration per Combination:** $($results.test_duration_per_combination_minutes) minutes

---

## 🐱 Executive Summary

The E2 Ratio Sweep Analysis has been completed with **$($results.combinations.Count)** different configuration combinations tested across agent timeout and gateway timeout parameters. This analysis provides insights into the optimal configuration for the Cat Nap Control Room observability pipeline, ensuring sub-second harmony in log processing.

### Key Findings

- **Best P95 Latency:** $($results.summary.best_p95_latency_ms) ms
- **Worst P95 Latency:** $($results.summary.worst_p95_latency_ms) ms
- **Average Queue Utilization:** $($results.summary.average_queue_utilization_percent)%
- **Average Serenity Score:** $($results.summary.average_serenity_score)
- **Max Purr Factor:** $($results.summary.max_purr_factor)

---

## 📊 Performance Analysis

### Latency Metrics

| Metric | Best | Worst | Average | Range |
|--------|------|-------|---------|-------|
| P50 Latency (ms) | $bestP50 | $worstP50 | $avgP50 | $($worstP50 - $bestP50) |
| P95 Latency (ms) | $bestP95 | $worstP95 | $avgP95 | $($worstP95 - $bestP95) |
| P99 Latency (ms) | $bestP99 | $worstP99 | $avgP99 | $($worstP99 - $bestP99) |

### System Performance

| Metric | Best | Worst | Average |
|--------|------|-------|---------|
| Queue Utilization (%) | $bestQueue | $worstQueue | $avgQueue |
| Serenity Score | $bestSerenity | $worstSerenity | $avgSerenity |
| Purr Factor | $bestPurr | $worstPurr | $avgPurr |

---

## 🎯 Configuration Analysis

### All Test Combinations

| Test ID | Agent | Gateway | P50 (ms) | P95 (ms) | P99 (ms) | Queue (%) | Serenity | Purr |
|---------|-------|---------|----------|----------|----------|-----------|----------|------|
"@

foreach ($combo in $results.combinations) {
    $report += @"
| $($combo.test_id) | $($combo.agent_timeout) | $($combo.gateway_timeout) | $($combo.metrics.p50_latency_ms) | $($combo.metrics.p95_latency_ms) | $($combo.metrics.p99_latency_ms) | $($combo.metrics.queue_utilization_percent) | $($combo.cat_nap_metrics.serenity_score) | $($combo.cat_nap_metrics.purr_factor) |
"@
}

if ($optimalConfig) {
    $report += @"

---

## 🌟 Optimal Configuration Recommendation

Based on the comprehensive analysis, the optimal configuration for the Cat Nap Control Room observability pipeline is:

### **$($optimalConfig.test_id)**

- **Agent Timeout:** $($optimalConfig.agent_timeout)
- **Gateway Timeout:** $($optimalConfig.gateway_timeout)
- **P95 Latency:** $($optimalConfig.metrics.p95_latency_ms) ms
- **P99 Latency:** $($optimalConfig.metrics.p99_latency_ms) ms
- **Queue Utilization:** $($optimalConfig.metrics.queue_utilization_percent)%
- **Batch Efficiency:** $($optimalConfig.metrics.batch_efficiency_percent)%
- **Serenity Score:** $($optimalConfig.cat_nap_metrics.serenity_score)
- **Purr Factor:** $($optimalConfig.cat_nap_metrics.purr_factor)

This configuration provides the best balance of performance, stability, and serenity for the observability pipeline.

"@
} else {
    $report += @"

---

## ⚠️ Optimal Configuration Analysis

No single configuration meets all optimal criteria (P95 < 2000ms, Queue < 70%, Serenity > 80). 

**Best Available Configuration:**
"@

    $bestAvailable = $results.combinations | Sort-Object { $_.cat_nap_metrics.purr_factor } -Descending | Select-Object -First 1
    $report += @"

- **Test ID:** $($bestAvailable.test_id)
- **Agent Timeout:** $($bestAvailable.agent_timeout)
- **Gateway Timeout:** $($bestAvailable.gateway_timeout)
- **P95 Latency:** $($bestAvailable.metrics.p95_latency_ms) ms
- **Purr Factor:** $($bestAvailable.cat_nap_metrics.purr_factor)

"@
}

$report += @"

---

## 🎯 Recommendations

### Configuration Guidelines

1. **For Low Latency Requirements:** Use configurations with shorter agent timeouts (50ms-200ms)
2. **For High Serenity Requirements:** Use configurations with moderate queue utilization (< 60%)
3. **For Balanced Performance:** Choose configurations with high purr factor (> 85)
4. **Avoid High Queue Utilization:** Monitor queue utilization and avoid configurations exceeding 80%
5. **Maintain Serenity:** Keep serenity scores above 70 for optimal system health

### Monitoring Setup

1. **Regular Analysis:** Run E2 ratio sweeps weekly to ensure optimal configuration
2. **Performance Tracking:** Monitor key metrics (P95 latency, queue utilization, serenity score)
3. **Configuration Tuning:** Adjust timeouts based on performance analysis results

---

## 📚 Additional Resources

- **Raw Results:** `$ResultsFile`
- **Monitoring Script:** `scripts/e2-ratio-sweep-simple.ps1`
- **Report Generator:** `scripts/generate-e2-ratio-report-simple.ps1`

---

## 🐱 Cat Nap Control Room Philosophy

*"While the cat naps, we measure the rhythm of observability. Every configuration tells a story, every metric whispers about the system's health. In the serene glow of the control room, we find the perfect balance between performance and tranquility."*

**Sleep easy. We've got the signal.** 🐱✨

---

*Report generated by Cat Nap Control Room E2 Ratio Analysis System*
*For questions or support, refer to the observability pipeline documentation*

"@

# Save report
$report | Set-Content $OutputFile -Encoding UTF8
Write-Host "✅ E2 ratio analysis report saved to: $OutputFile" -ForegroundColor Green

# Generate summary
Write-Host "`n📊 === E2 Ratio Analysis Report Summary ===" -ForegroundColor Green
Write-Host "Total combinations analyzed: $($results.combinations.Count)" -ForegroundColor White
Write-Host "Best P95 latency: $bestP95 ms" -ForegroundColor White
Write-Host "Average serenity score: $avgSerenity" -ForegroundColor White
Write-Host "Max purr factor: $bestPurr" -ForegroundColor White

if ($optimalConfig) {
    Write-Host "`n🌟 Optimal configuration: $($optimalConfig.test_id)" -ForegroundColor Green
    Write-Host "  Agent Timeout: $($optimalConfig.agent_timeout)" -ForegroundColor White
    Write-Host "  Gateway Timeout: $($optimalConfig.gateway_timeout)" -ForegroundColor White
    Write-Host "  P95 Latency: $($optimalConfig.metrics.p95_latency_ms) ms" -ForegroundColor White
    Write-Host "  Purr Factor: $($optimalConfig.cat_nap_metrics.purr_factor)" -ForegroundColor White
} else {
    Write-Host "`n⚠️ No configuration meets all optimal criteria" -ForegroundColor Yellow
}

Write-Host "`n📄 Report saved to: $OutputFile" -ForegroundColor Green
Write-Host "🐱 Cat Nap Control Room E2 Ratio Analysis Report completed!" -ForegroundColor Green
Write-Host "Sleep easy. We've got the signal. 🐱✨" -ForegroundColor Cyan
