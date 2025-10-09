# Queue Configuration Optimization Script
# ECRR Framework: Examine → Clean → Report → Role
# Actor: Cursor Agent - Observability Copilot

param(
    [int]$TestDurationSeconds = 60,
    [switch]$DryRun
)

Write-Host "🔍 Queue Configuration Optimization Analysis" -ForegroundColor Cyan
Write-Host "Actor: Cursor Agent - Observability Copilot" -ForegroundColor Gray
Write-Host ""

# Examine: Current Configuration Analysis
Write-Host "📊 Examine: Current Configuration Analysis..." -ForegroundColor Yellow
$ConfigPath = "config.yaml"
$ConfigContent = Get-Content $ConfigPath -Raw

# Extract current batch configuration
$TimeoutMatch = [regex]::Match($ConfigContent, 'timeout:\s*(\d+)ms')
$BatchSizeMatch = [regex]::Match($ConfigContent, 'send_batch_size:\s*(\d+)')

if ($TimeoutMatch.Success -and $BatchSizeMatch.Success) {
    $CurrentTimeout = [int]$TimeoutMatch.Groups[1].Value
    $CurrentBatchSize = [int]$BatchSizeMatch.Groups[1].Value
    Write-Host "  Current timeout: $($CurrentTimeout)ms" -ForegroundColor Green
    Write-Host "  Current batch size: $($CurrentBatchSize)" -ForegroundColor Green
} else {
    Write-Host "  ❌ Could not parse current configuration" -ForegroundColor Red
    exit 1
}

# Clean: Performance Analysis
Write-Host ""
Write-Host "🧹 Clean: Analyzing Current Performance..." -ForegroundColor Yellow

# Get current metrics
try {
    $MetricsResponse = Invoke-RestMethod -Uri "http://localhost:8888/metrics" -Method Get
    $Metrics = $MetricsResponse -split "`n"
    
    # Extract key metrics
    $QueueSize = ($Metrics | Where-Object { $_ -match 'otelcol_exporter_queue_size.*(\d+)' } | ForEach-Object { [int]($_ -split '\s+')[-1] })[0]
    $QueueCapacity = ($Metrics | Where-Object { $_ -match 'otelcol_exporter_queue_capacity.*(\d+)' } | ForEach-Object { [int]($_ -split '\s+')[-1] })[0]
    $TimeoutTriggers = ($Metrics | Where-Object { $_ -match 'otelcol_processor_batch_timeout_trigger_send.*(\d+)' } | ForEach-Object { [int]($_ -split '\s+')[-1] })[0]
    $BatchCount = ($Metrics | Where-Object { $_ -match 'otelcol_processor_batch_batch_send_size_count.*(\d+)' } | ForEach-Object { [int]($_ -split '\s+')[-1] })[0]
    $BatchSum = ($Metrics | Where-Object { $_ -match 'otelcol_processor_batch_batch_send_size_sum.*(\d+)' } | ForEach-Object { [int]($_ -split '\s+')[-1] })[0]
    
    $QueueUtilization = if ($QueueCapacity -gt 0) { [math]::Round(($QueueSize / $QueueCapacity) * 100, 2) } else { 0 }
    $AvgBatchSize = if ($BatchCount -gt 0) { [math]::Round($BatchSum / $BatchCount, 2) } else { 0 }
    
    Write-Host "  Queue utilization: $QueueUtilization% ($QueueSize/$QueueCapacity)" -ForegroundColor Green
    Write-Host "  Average batch size: $AvgBatchSize" -ForegroundColor Green
    Write-Host "  Timeout triggers: $TimeoutTriggers" -ForegroundColor Green
    Write-Host "  Total batches: $BatchCount" -ForegroundColor Green
    
} catch {
    Write-Host "  ❌ Could not retrieve metrics: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Report: Optimization Recommendations
Write-Host ""
Write-Host "📝 Report: Optimization Analysis..." -ForegroundColor Yellow

$Recommendations = @()

# Analyze queue utilization
if ($QueueUtilization -lt 10) {
    $Recommendations += "Queue severely underutilized ($QueueUtilization%) - consider increasing timeout to allow larger batches"
} elseif ($QueueUtilization -gt 80) {
    $Recommendations += "Queue highly utilized ($QueueUtilization%) - consider reducing timeout or increasing batch size"
} else {
    $Recommendations += "Queue utilization healthy ($QueueUtilization%)"
}

# Analyze batch efficiency
$BatchEfficiency = [math]::Round(($AvgBatchSize / $CurrentBatchSize) * 100, 2)
if ($BatchEfficiency -lt 50) {
    $Recommendations += "Batch efficiency low ($BatchEfficiency%) - batches not filling up before timeout"
} elseif ($BatchEfficiency -gt 90) {
    $Recommendations += "Batch efficiency excellent ($BatchEfficiency%) - batches filling up well"
} else {
    $Recommendations += "Batch efficiency acceptable ($BatchEfficiency%)"
}

# Analyze timeout vs size triggers
$TimeoutRatio = if ($BatchCount -gt 0) { [math]::Round(($TimeoutTriggers / $BatchCount) * 100, 2) } else { 0 }
if ($TimeoutRatio -gt 80) {
    $Recommendations += "Mostly timeout-triggered batches ($TimeoutRatio%) - consider longer timeout for better efficiency"
} else {
    $Recommendations += "Good mix of timeout and size triggers ($TimeoutRatio% timeout-triggered)"
}

Write-Host "  Analysis Results:" -ForegroundColor Cyan
foreach ($rec in $Recommendations) {
    Write-Host "    • $rec" -ForegroundColor White
}

# Calculate optimized configuration
Write-Host ""
Write-Host "🎯 Optimization Recommendations:" -ForegroundColor Cyan

$NewTimeout = $CurrentTimeout
$NewBatchSize = $CurrentBatchSize

# Optimization logic based on analysis
if ($QueueUtilization -lt 10 -and $BatchEfficiency -lt 50) {
    # Severely underutilized - increase timeout significantly
    $NewTimeout = [math]::Min($CurrentTimeout * 4, 5000)
    $Recommendation = "Increase timeout from ${CurrentTimeout}ms to ${NewTimeout}ms for better batch efficiency"
} elseif ($QueueUtilization -gt 80) {
    # High utilization - reduce timeout or increase batch size
    $NewTimeout = [math]::Max($CurrentTimeout * 0.5, 100)
    $Recommendation = "Reduce timeout from ${CurrentTimeout}ms to ${NewTimeout}ms to reduce queue pressure"
} else {
    # Balanced - minor optimization
    $NewTimeout = [math]::Min($CurrentTimeout * 1.5, 2000)
    $Recommendation = "Moderate timeout increase from ${CurrentTimeout}ms to ${NewTimeout}ms for better efficiency"
}

if ($AvgBatchSize -gt $CurrentBatchSize * 0.8) {
    $NewBatchSize = [math]::Min($CurrentBatchSize * 2, 1024)
    $Recommendation += " and increase batch size from $CurrentBatchSize to $NewBatchSize"
}

Write-Host "  $Recommendation" -ForegroundColor Yellow

# Role: Apply Optimizations
if (-not $DryRun) {
    Write-Host ""
    Write-Host "🎭 Role: Applying Optimizations..." -ForegroundColor Yellow
    
    # Backup current config
    $BackupPath = "config.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').yaml"
    Copy-Item $ConfigPath $BackupPath
    Write-Host "  ✅ Backed up config to: $BackupPath" -ForegroundColor Green
    
    # Apply new configuration
    $NewConfig = $ConfigContent -replace "timeout:\s*${CurrentTimeout}ms", "timeout: ${NewTimeout}ms"
    $NewConfig = $NewConfig -replace "send_batch_size:\s*${CurrentBatchSize}", "send_batch_size: ${NewBatchSize}"
    
    Set-Content -Path $ConfigPath -Value $NewConfig
    Write-Host "  ✅ Updated configuration: ${NewTimeout}ms timeout, ${NewBatchSize} batch size" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "⚠️  Configuration updated. Restart collector service to apply changes:" -ForegroundColor Yellow
    Write-Host "  net stop otelcol-contrib && net start otelcol-contrib" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "🔍 Dry run complete - no changes applied" -ForegroundColor Gray
}

# Generate optimization report
$ReportPath = "artifacts/queue-optimization-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$ReportContent = @"
# Queue Configuration Optimization Report

**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Actor**: Cursor Agent - Observability Copilot  
**Analysis Duration**: $TestDurationSeconds seconds

## Current Configuration
- **Timeout**: ${CurrentTimeout}ms
- **Batch Size**: ${CurrentBatchSize}

## Performance Metrics
- **Queue Utilization**: $QueueUtilization% ($QueueSize/$QueueCapacity)
- **Average Batch Size**: $AvgBatchSize
- **Batch Efficiency**: $BatchEfficiency%
- **Timeout Triggers**: $TimeoutTriggers ($TimeoutRatio% of batches)
- **Total Batches**: $BatchCount

## Analysis
$($Recommendations -join "`n")

## Optimization Applied
- **New Timeout**: ${NewTimeout}ms (from ${CurrentTimeout}ms)
- **New Batch Size**: ${NewBatchSize} (from ${CurrentBatchSize})
- **Rationale**: $Recommendation

## Next Steps
1. Restart collector service to apply new configuration
2. Monitor queue utilization and batch efficiency
3. Adjust configuration based on new performance patterns
4. Set up automated monitoring for queue pressure

---
**Generated by**: Queue Configuration Optimization Script  
**ECRR Framework**: Examine → Clean → Report → Role
"@

New-Item -Path (Split-Path $ReportPath -Parent) -ItemType Directory -Force | Out-Null
Set-Content -Path $ReportPath -Value $ReportContent
Write-Host "  📊 Report saved to: $ReportPath" -ForegroundColor Green

Write-Host ""
Write-Host "✅ Queue Configuration Optimization Complete!" -ForegroundColor Green
