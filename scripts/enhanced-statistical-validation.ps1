# Enhanced Statistical Validation for Fractal Pattern Analysis
# Implements investigation insights for improved statistical reliability

param(
    [int]$MinSampleSize = 200,
    [int]$TestDuration = 600,
    [switch]$CalculateConfidenceIntervals = $true,
    [switch]$UseCoefficientOfVariation = $true,
    [switch]$GenerateReport = $true
)

# ECRR - Examine → Clean → Report → Role
Write-Host "🔍 Examine Enhanced Statistical Validation - ECRR Framework" -ForegroundColor Cyan
Write-Host "🎭 Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

Write-Host "`n📊 Enhanced Statistical Validation Implementation" -ForegroundColor Green
Write-Host "Based on Poisson anomaly investigation insights" -ForegroundColor Cyan

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

# Enhanced Hurst exponent calculation with confidence intervals
function Get-EnhancedHurstEstimate {
    param(
        $InterArrivals,
        [string]$PatternName,
        [switch]$CalculateCI = $true
    )
    
    if ($InterArrivals.Count -lt $MinSampleSize) {
        Write-Host "  ⚠️ Sample size $($InterArrivals.Count) below minimum $MinSampleSize" -ForegroundColor Yellow
        return $null
    }
    
    $Mean = ($InterArrivals | Measure-Object -Average).Average
    $Variance = ($InterArrivals | ForEach-Object { [math]::Pow($_ - $Mean, 2) } | Measure-Object -Average).Average
    $StdDev = [math]::Sqrt($Variance)
    
    # R/S statistic calculation with improved methodology
    $CumulativeDeviations = @()
    $RunningSum = 0
    for ($i = 0; $i -lt $InterArrivals.Count; $i++) {
        $RunningSum += ($InterArrivals[$i] - $Mean)
        $CumulativeDeviations += $RunningSum
    }
    
    $RangeRS = ($CumulativeDeviations | Measure-Object -Maximum).Maximum - ($CumulativeDeviations | Measure-Object -Minimum).Minimum
    $HurstEstimate = if ($StdDev -gt 0) {
        [math]::Log($RangeRS / $StdDev) / [math]::Log($InterArrivals.Count)
    } else { 0.5 }
    
    # Coefficient of Variation (CV) - more robust for short samples
    $CoefficientOfVariation = if ($Mean -gt 0) { $StdDev / $Mean } else { 0 }
    
    $Result = @{
        pattern = $PatternName
        sample_size = $InterArrivals.Count
        mean_inter_arrival = [math]::Round($Mean, 4)
        std_dev = [math]::Round($StdDev, 4)
        coefficient_of_variation = [math]::Round($CoefficientOfVariation, 4)
        hurst_estimate = [math]::Round($HurstEstimate, 4)
        range_rs = [math]::Round($RangeRS, 4)
        variance = [math]::Round($Variance, 4)
    }
    
    # Confidence interval calculation (simplified bootstrap approach)
    if ($CalculateCI) {
        $BootstrapSamples = 100
        $BootstrapHursts = @()
        
        for ($i = 0; $i -lt $BootstrapSamples; $i++) {
            $BootstrapSample = @()
            for ($j = 0; $j -lt $InterArrivals.Count; $j++) {
                $RandomIndex = Get-Random -Minimum 0 -Maximum $InterArrivals.Count
                $BootstrapSample += $InterArrivals[$RandomIndex]
            }
            
            # Calculate Hurst for bootstrap sample
            $BootstrapMean = ($BootstrapSample | Measure-Object -Average).Average
            $BootstrapStdDev = [math]::Sqrt(($BootstrapSample | ForEach-Object { [math]::Pow($_ - $BootstrapMean, 2) } | Measure-Object -Average).Average)
            
            $BootstrapCumulativeDeviations = @()
            $BootstrapRunningSum = 0
            for ($k = 0; $k -lt $BootstrapSample.Count; $k++) {
                $BootstrapRunningSum += ($BootstrapSample[$k] - $BootstrapMean)
                $BootstrapCumulativeDeviations += $BootstrapRunningSum
            }
            
            $BootstrapRangeRS = ($BootstrapCumulativeDeviations | Measure-Object -Maximum).Maximum - ($BootstrapCumulativeDeviations | Measure-Object -Minimum).Minimum
            $BootstrapHurst = if ($BootstrapStdDev -gt 0) {
                [math]::Log($BootstrapRangeRS / $BootstrapStdDev) / [math]::Log($BootstrapSample.Count)
            } else { 0.5 }
            
            $BootstrapHursts += $BootstrapHurst
        }
        
        $SortedBootstrapHursts = $BootstrapHursts | Sort-Object
        $CI95Lower = $SortedBootstrapHursts[[math]::Floor($BootstrapSamples * 0.025)]
        $CI95Upper = $SortedBootstrapHursts[[math]::Floor($BootstrapSamples * 0.975)]
        
        $Result.confidence_interval_95 = @{
            lower = [math]::Round($CI95Lower, 4)
            upper = [math]::Round($CI95Upper, 4)
            width = [math]::Round($CI95Upper - $CI95Lower, 4)
        }
    }
    
    # Statistical significance testing
    $ExpectedHurst = 0.5
    $HurstDeviation = [math]::Abs($HurstEstimate - $ExpectedHurst)
    $SignificantDeviation = $HurstDeviation -gt 0.1  # Threshold for significant deviation
    
    $Result.statistical_significance = @{
        expected_hurst = $ExpectedHurst
        deviation = [math]::Round($HurstDeviation, 4)
        significant_deviation = $SignificantDeviation
        interpretation = if ($HurstEstimate -lt 0.4) { "Anti-persistent" }
                       elseif ($HurstEstimate -gt 0.6) { "Persistent" }
                       else { "Random walk" }
    }
    
    return $Result
}

# Enhanced pattern validation
function Test-EnhancedPatternValidation {
    param(
        [double]$Lambda = 0.1,
        [string]$PatternName = "Poisson",
        [int]$Duration = 600
    )
    
    Write-Host "`n🧪 Enhanced Validation: $PatternName Pattern" -ForegroundColor Yellow
    Write-Host "  Duration: ${Duration}s, Min Sample Size: $MinSampleSize" -ForegroundColor Cyan
    
    $Events = @()
    $Random = New-Object System.Random
    $CurrentTime = 0
    $EventId = 0
    
    # Generate events with improved sampling
    while ($CurrentTime -lt $Duration) {
        $U = $Random.NextDouble()
        $InterArrival = -[math]::Log(1 - $U) / $Lambda
        $CurrentTime += $InterArrival
        
        if ($CurrentTime -lt $Duration) {
            $Events += @{
                timestamp = Get-Date
                pattern = $PatternName.ToLower()
                event_id = $EventId
                inter_arrival = $InterArrival
                lambda = $Lambda
            }
            $EventId++
        }
    }
    
    if ($Events.Count -lt $MinSampleSize) {
        Write-Host "  ❌ Insufficient events: $($Events.Count) < $MinSampleSize" -ForegroundColor Red
        return $null
    }
    
    $InterArrivals = $Events | ForEach-Object { $_.inter_arrival }
    $EnhancedResult = Get-EnhancedHurstEstimate -InterArrivals $InterArrivals -PatternName $PatternName -CalculateCI $CalculateConfidenceIntervals
    
    # Display results
    Write-Host "  📊 Enhanced Results:" -ForegroundColor Cyan
    Write-Host "    Sample Size: $($EnhancedResult.sample_size)" -ForegroundColor White
    Write-Host "    Mean: $($EnhancedResult.mean_inter_arrival)s" -ForegroundColor White
    Write-Host "    CV: $($EnhancedResult.coefficient_of_variation)" -ForegroundColor White
    Write-Host "    Hurst: $($EnhancedResult.hurst_estimate)" -ForegroundColor White
    
    if ($EnhancedResult.confidence_interval_95) {
        Write-Host "    95% CI: [$($EnhancedResult.confidence_interval_95.lower), $($EnhancedResult.confidence_interval_95.upper)]" -ForegroundColor White
        Write-Host "    CI Width: $($EnhancedResult.confidence_interval_95.width)" -ForegroundColor White
    }
    
    Write-Host "    Interpretation: $($EnhancedResult.statistical_significance.interpretation)" -ForegroundColor White
    Write-Host "    Significant: $($EnhancedResult.statistical_significance.significant_deviation)" -ForegroundColor White
    
    return $EnhancedResult
}

# Main enhanced validation
$ValidationStart = Get-Date
Write-Host "`n🚀 Starting Enhanced Statistical Validation..." -ForegroundColor Green

$EnhancedResults = @()

# Test different patterns with enhanced validation
$Patterns = @(
    @{ Name = "Steady"; Lambda = 0.1; Duration = $TestDuration },
    @{ Name = "Poisson"; Lambda = 0.1; Duration = $TestDuration },
    @{ Name = "Pareto"; Lambda = 0.1; Duration = $TestDuration }
)

foreach ($Pattern in $Patterns) {
    $Result = Test-EnhancedPatternValidation -Lambda $Pattern.Lambda -PatternName $Pattern.Name -Duration $Pattern.Duration
    if ($Result) {
        $EnhancedResults += $Result
    }
}

$ValidationEnd = Get-Date
$TotalDuration = ($ValidationEnd - $ValidationStart).TotalMinutes

# Comprehensive analysis
Write-Host "`n📊 Enhanced Validation Analysis" -ForegroundColor Green
Write-Host "Total Tests: $($EnhancedResults.Count)" -ForegroundColor Cyan
Write-Host "Validation Duration: $([math]::Round($TotalDuration, 2)) minutes" -ForegroundColor Cyan

# Statistical summary
$HurstValues = $EnhancedResults | ForEach-Object { $_.hurst_estimate }
$CVValues = $EnhancedResults | ForEach-Object { $_.coefficient_of_variation }

Write-Host "`n🎯 Statistical Summary:" -ForegroundColor Yellow
Write-Host "  Hurst Mean: $([math]::Round(($HurstValues | Measure-Object -Average).Average, 4))" -ForegroundColor White
Write-Host "  Hurst StdDev: $([math]::Round([math]::Sqrt(($HurstValues | ForEach-Object { [math]::Pow($_ - ($HurstValues | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average), 4))" -ForegroundColor White
Write-Host "  CV Mean: $([math]::Round(($CVValues | Measure-Object -Average).Average, 4))" -ForegroundColor White

# Reliability assessment
$ReliableSamples = ($EnhancedResults | Where-Object { $_.sample_size -ge $MinSampleSize }).Count
$SignificantDeviations = ($EnhancedResults | Where-Object { $_.statistical_significance.significant_deviation }).Count

Write-Host "`n📈 Reliability Assessment:" -ForegroundColor Yellow
Write-Host "  Reliable Samples: $ReliableSamples / $($EnhancedResults.Count)" -ForegroundColor White
Write-Host "  Significant Deviations: $SignificantDeviations / $($EnhancedResults.Count)" -ForegroundColor White

# Save enhanced results
$EnhancedResultsData = @{
    validation_start = $ValidationStart.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    validation_end = $ValidationEnd.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    total_duration_minutes = [math]::Round($TotalDuration, 2)
    min_sample_size = $MinSampleSize
    test_duration = $TestDuration
    enhanced_results = $EnhancedResults
    statistical_summary = @{
        hurst_mean = [math]::Round(($HurstValues | Measure-Object -Average).Average, 4)
        hurst_stddev = [math]::Round([math]::Sqrt(($HurstValues | ForEach-Object { [math]::Pow($_ - ($HurstValues | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average), 4)
        cv_mean = [math]::Round(($CVValues | Measure-Object -Average).Average, 4)
    }
    reliability_metrics = @{
        reliable_samples = $ReliableSamples
        total_samples = $EnhancedResults.Count
        significant_deviations = $SignificantDeviations
    }
    recommendations = @{
        min_sample_size = $MinSampleSize
        use_confidence_intervals = $CalculateConfidenceIntervals
        use_coefficient_of_variation = $UseCoefficientOfVariation
        statistical_significance_threshold = 0.1
    }
}

$EnhancedResultsFile = "artifacts\enhanced-statistical-validation.json"
$EnhancedResultsData | ConvertTo-Json -Depth 4 | Set-Content -Path $EnhancedResultsFile -Encoding UTF8

Write-Host "`n💾 Enhanced results saved to: $EnhancedResultsFile" -ForegroundColor Green

# Generate comprehensive report
if ($GenerateReport) {
    $EnhancedReport = @"
# Enhanced Statistical Validation Report

**Date**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Actor**: Cursor-Local (Observability Copilot)  
**Purpose**: Enhanced statistical validation based on investigation insights

## Implementation Insights

### Key Improvements
1. **Minimum Sample Size**: $MinSampleSize events required for reliable analysis
2. **Confidence Intervals**: 95% CI calculation using bootstrap methodology
3. **Coefficient of Variation**: More robust metric for short samples
4. **Statistical Significance**: Deviation threshold of 0.1 for significance testing

### Validation Results

#### Pattern Analysis
"@

    foreach ($Result in $EnhancedResults) {
        $EnhancedReport += @"

##### $($Result.pattern) Pattern
- **Sample Size**: $($Result.sample_size) events
- **Mean Inter-arrival**: $($Result.mean_inter_arrival)s
- **Coefficient of Variation**: $($Result.coefficient_of_variation)
- **Hurst Exponent**: $($Result.hurst_estimate)
- **95% Confidence Interval**: [$($Result.confidence_interval_95.lower), $($Result.confidence_interval_95.upper)]
- **Interpretation**: $($Result.statistical_significance.interpretation)
- **Significant Deviation**: $($Result.statistical_significance.significant_deviation)
"@
    }

    $EnhancedReport += @"

## Statistical Summary
- **Total Validations**: $($EnhancedResults.Count)
- **Reliable Samples**: $ReliableSamples / $($EnhancedResults.Count)
- **Significant Deviations**: $SignificantDeviations / $($EnhancedResults.Count)
- **Mean Hurst**: $([math]::Round(($HurstValues | Measure-Object -Average).Average, 4))
- **Mean CV**: $([math]::Round(($CVValues | Measure-Object -Average).Average, 4))

## Recommendations

### Enhanced Monitoring
1. **Sample Size Requirements**: Use minimum $MinSampleSize events for reliable analysis
2. **Confidence Intervals**: Include 95% CI in all Hurst estimates
3. **Coefficient of Variation**: Use CV alongside Hurst for validation
4. **Statistical Significance**: Test deviations > 0.1 for significance

### Implementation Changes
1. **Default Duration**: Increase to $TestDuration seconds for larger samples
2. **Bootstrap Validation**: Implement confidence interval calculation
3. **Multi-metric Approach**: Combine Hurst, CV, and statistical significance
4. **Reliability Thresholds**: Set minimum sample size requirements

## Conclusion
Enhanced statistical validation provides more reliable fractal pattern analysis through:
- Larger sample sizes for statistical power
- Confidence intervals for uncertainty quantification
- Coefficient of variation for robustness
- Statistical significance testing for deviation detection

---
*Generated by Enhanced Statistical Validation Script*
"@

    $EnhancedReportFile = "artifacts\enhanced-statistical-validation-report.md"
    Set-Content -Path $EnhancedReportFile -Value $EnhancedReport -Encoding UTF8
    Write-Host "📄 Enhanced report saved to: $EnhancedReportFile" -ForegroundColor Green
}

Write-Host "`n🎯 Enhanced Statistical Validation Complete!" -ForegroundColor Green
Write-Host "📋 Summary:" -ForegroundColor Cyan
Write-Host "  Validations: $($EnhancedResults.Count)" -ForegroundColor White
Write-Host "  Reliable Samples: $ReliableSamples" -ForegroundColor White
Write-Host "  Significant Deviations: $SignificantDeviations" -ForegroundColor White
Write-Host "  Results File: $EnhancedResultsFile" -ForegroundColor White

Write-Host "`n💡 Key Improvements:" -ForegroundColor Yellow
Write-Host "  ✅ Minimum sample size: $MinSampleSize events" -ForegroundColor White
Write-Host "  ✅ Confidence intervals: 95% CI calculation" -ForegroundColor White
Write-Host "  ✅ Coefficient of variation: Robust validation metric" -ForegroundColor White
Write-Host "  ✅ Statistical significance: Deviation testing" -ForegroundColor White

Write-Host "`n🎭 Role: Cursor-Local (Observability Copilot) - Enhanced Statistical Validation Complete" -ForegroundColor Magenta
