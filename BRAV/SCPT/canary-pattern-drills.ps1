# Canary Log Pattern Drills
# T-2025-01-27-004: Expand windows-canary emitter with steady/Poisson/Pareto patterns
# Cursor-Local: Observability Copilot

param(
    [ValidateSet("Steady", "Poisson", "Pareto", "All")]
    [string]$Pattern = "All",
    [int]$Duration = 300,  # 5 minutes default
    [switch]$Analyze = $false
)

# ECRR: Examine → Clean → Report → Role
Write-Host "🎯 Canary Pattern Drills - ECRR Framework" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$ArtifactsDir = "artifacts"
if (-not (Test-Path $ArtifactsDir)) {
    New-Item -ItemType Directory -Path $ArtifactsDir | Out-Null
}

$LogsDir = "C:\logs"
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir | Out-Null
}

# Pattern definitions and implementations
function Invoke-SteadyPattern {
    param([int]$Duration)
    
    Write-Host "⏱️ Running Steady Pattern: 1 event every 10 seconds for $Duration seconds" -ForegroundColor Green
    $Events = @()
    $Interval = 10  # 10 seconds
    $TotalEvents = [math]::Floor($Duration / $Interval)
    
    for ($i = 0; $i -lt $TotalEvents; $i++) {
        $Timestamp = Get-Date
        $LogEntry = @{
            timestamp = $Timestamp.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            level = "INFO"
            message = "windows-canary-steady-$i"
            pattern = "steady"
            event_id = $i
            inter_arrival = $Interval
            lambda = 0.1  # 1/10 seconds
        } | ConvertTo-Json -Compress
        
        Add-Content -Path "$LogsDir\canary-steady.log" -Value $LogEntry
        $Events += @{
            timestamp = $Timestamp
            pattern = "steady"
            event_id = $i
            inter_arrival = $Interval
        }
        
        Write-Host "  📝 Steady event $i at $($Timestamp.ToString("HH:mm:ss"))" -ForegroundColor Gray
        if ($i -lt ($TotalEvents - 1)) { Start-Sleep -Seconds $Interval }
    }
    
    return $Events
}

function Invoke-PoissonPattern {
    param([int]$Duration)
    
    Write-Host "⚡ Running Poisson Pattern: λ=0.1 events/second for $Duration seconds" -ForegroundColor Green
    $Events = @()
    $Lambda = 0.1  # 0.1 events per second
    $Random = New-Object System.Random
    $CurrentTime = 0
    $EventId = 0
    
    while ($CurrentTime -lt $Duration) {
        # Generate exponential inter-arrival time
        $U = $Random.NextDouble()
        $InterArrival = -[math]::Log(1 - $U) / $Lambda
        $CurrentTime += $InterArrival
        
        if ($CurrentTime -lt $Duration) {
            $Timestamp = (Get-Date).AddSeconds($CurrentTime - $Duration)
            $LogEntry = @{
                timestamp = $Timestamp.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                level = "INFO"
                message = "windows-canary-poisson-$EventId"
                pattern = "poisson"
                event_id = $EventId
                inter_arrival = $InterArrival
                lambda = $Lambda
            } | ConvertTo-Json -Compress
            
            Add-Content -Path "$LogsDir\canary-poisson.log" -Value $LogEntry
            $Events += @{
                timestamp = Get-Date
                pattern = "poisson"
                event_id = $EventId
                inter_arrival = $InterArrival
            }
            
            Write-Host "  🎲 Poisson event $EventId, inter-arrival: $([math]::Round($InterArrival, 2))s" -ForegroundColor Gray
            $EventId++
            
            # Sleep for the inter-arrival time
            Start-Sleep -Milliseconds ([math]::Max(100, $InterArrival * 1000))
        }
    }
    
    return $Events
}

function Invoke-ParetoPattern {
    param([int]$Duration)
    
    Write-Host "📊 Running Pareto Pattern: α=1.5, scale=1.0 for $Duration seconds" -ForegroundColor Green
    $Events = @()
    $Alpha = 1.5
    $Scale = 1.0
    $Random = New-Object System.Random
    $CurrentTime = 0
    $EventId = 0
    
    while ($CurrentTime -lt $Duration) {
        # Generate Pareto-distributed inter-arrival time
        $U = $Random.NextDouble()
        $InterArrival = $Scale * [math]::Pow((1 - $U), (-1.0 / $Alpha)) - $Scale
        $InterArrival = [math]::Max(0.1, $InterArrival)  # Minimum 0.1 seconds
        $CurrentTime += $InterArrival
        
        if ($CurrentTime -lt $Duration) {
            $Timestamp = (Get-Date).AddSeconds($CurrentTime - $Duration)
            $LogEntry = @{
                timestamp = $Timestamp.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                level = "INFO"
                message = "windows-canary-pareto-$EventId"
                pattern = "pareto"
                event_id = $EventId
                inter_arrival = $InterArrival
                alpha = $Alpha
                scale = $Scale
            } | ConvertTo-Json -Compress
            
            Add-Content -Path "$LogsDir\canary-pareto.log" -Value $LogEntry
            $Events += @{
                timestamp = Get-Date
                pattern = "pareto"
                event_id = $EventId
                inter_arrival = $InterArrival
            }
            
            Write-Host "  📈 Pareto event $EventId, inter-arrival: $([math]::Round($InterArrival, 2))s" -ForegroundColor Gray
            $EventId++
            
            # Sleep for the inter-arrival time
            Start-Sleep -Milliseconds ([math]::Max(100, $InterArrival * 1000))
        }
    }
    
    return $Events
}

function Measure-FractalMetrics {
    param($Events, $PatternName)
    
    Write-Host "📐 Calculating fractal self-similarity metrics for $PatternName..." -ForegroundColor Yellow
    
    $InterArrivals = $Events | ForEach-Object { $_.inter_arrival }
    
    if ($InterArrivals.Count -lt 2) {
        return @{
            pattern = $PatternName
            count = $InterArrivals.Count
            mean = 0
            variance = 0
            hurst_estimate = "N/A"
        }
    }
    
    $Mean = ($InterArrivals | Measure-Object -Average).Average
    $Variance = ($InterArrivals | ForEach-Object { [math]::Pow($_ - $Mean, 2) } | Measure-Object -Average).Average
    $StdDev = [math]::Sqrt($Variance)
    
    # Simple Hurst exponent estimation using R/S statistic
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
    
    return @{
        pattern = $PatternName
        count = $InterArrivals.Count
        mean = [math]::Round($Mean, 4)
        variance = [math]::Round($Variance, 4)
        std_dev = [math]::Round($StdDev, 4)
        hurst_estimate = [math]::Round($HurstEstimate, 4)
        range_rs = [math]::Round($RangeRS, 4)
    }
}

# Main execution
$Results = @()
$TestStart = Get-Date

Write-Host "🚀 Starting Canary Pattern Drills - Duration: ${Duration}s" -ForegroundColor Green

if ($Pattern -eq "All" -or $Pattern -eq "Steady") {
    $SteadyEvents = Invoke-SteadyPattern -Duration $Duration
    $SteadyMetrics = Measure-FractalMetrics -Events $SteadyEvents -PatternName "Steady"
    $Results += $SteadyMetrics
}

if ($Pattern -eq "All" -or $Pattern -eq "Poisson") {
    $PoissonEvents = Invoke-PoissonPattern -Duration $Duration
    $PoissonMetrics = Measure-FractalMetrics -Events $PoissonEvents -PatternName "Poisson"
    $Results += $PoissonMetrics
}

if ($Pattern -eq "All" -or $Pattern -eq "Pareto") {
    $ParetoEvents = Invoke-ParetoPattern -Duration $Duration
    $ParetoMetrics = Measure-FractalMetrics -Events $ParetoEvents -PatternName "Pareto"
    $Results += $ParetoMetrics
}

$TestEnd = Get-Date
$TotalDuration = ($TestEnd - $TestStart).TotalSeconds

# Save results
$FinalResults = @{
    test_start = $TestStart.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    test_end = $TestEnd.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    total_duration = [math]::Round($TotalDuration, 2)
    pattern_results = $Results
    fractal_analysis = @{
        steady = @{
            expected_hurst = 0.5
            description = "Regular intervals should show H≈0.5 (random walk)"
        }
        poisson = @{
            expected_hurst = 0.5
            description = "Exponential inter-arrivals should show H≈0.5 (memoryless)"
        }
        pareto = @{
            expected_hurst = "> 0.5"
            description = "Heavy-tailed distribution should show H>0.5 (long-range dependence)"
        }
    }
}

$ResultsPath = "$ArtifactsDir/canary-pattern-results.json"
$FinalResults | ConvertTo-Json -Depth 4 | Set-Content -Path $ResultsPath

# Display results
Write-Host "`n📊 Canary Pattern Analysis Results:" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

foreach ($Result in $Results) {
    Write-Host "`n🎯 Pattern: $($Result.pattern)" -ForegroundColor Yellow
    Write-Host "   Events: $($Result.count)"
    Write-Host "   Mean inter-arrival: $($Result.mean)s"
    Write-Host "   Std deviation: $($Result.std_dev)s"
    Write-Host "   Hurst estimate: $($Result.hurst_estimate)"
    
    # Interpretation
    if ($Result.hurst_estimate -is [double]) {
        if ($Result.hurst_estimate -lt 0.4) {
            Write-Host "   📉 Anti-persistent (H < 0.5)" -ForegroundColor Red
        } elseif ($Result.hurst_estimate -gt 0.6) {
            Write-Host "   📈 Persistent/Long-range dependent (H > 0.5)" -ForegroundColor Green
        } else {
            Write-Host "   🎲 Random walk behavior (H ≈ 0.5)" -ForegroundColor Blue
        }
    }
}

Write-Host "`n📁 Results saved to: $ResultsPath" -ForegroundColor Yellow

# ECRR Report
$ECRRReport = @"
# Canary Pattern Drills - ECRR Report
**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Actor**: Cursor-Local (Observability Copilot)

## Examine
- Pattern types: Steady (10s intervals), Poisson (λ=0.1), Pareto (α=1.5, scale=1.0)
- Duration: ${Duration} seconds
- Log destinations: C:\logs\canary-*.log
- Fractal self-similarity analysis via Hurst exponent estimation

## Clean
- Generated structured canary logs with pattern metadata
- Calculated inter-arrival time distributions
- Measured fractal characteristics for each pattern

## Report
- Results: $($Results.Count) patterns analyzed
- Total events: $($Results | ForEach-Object { $_.count } | Measure-Object -Sum).Sum
- Artifacts: $ResultsPath
- Duration: $([math]::Round($TotalDuration, 2)) seconds

## Role
Cursor-Local: Observability Copilot - Canary pattern analysis and fractal drift detection
"@

$ECRRReport | Set-Content -Path "$ArtifactsDir/canary-pattern-ecrr.md"

Write-Host "`n🎭 ECRR Report saved to: $ArtifactsDir/canary-pattern-ecrr.md" -ForegroundColor Magenta

if ($Analyze) {
    Write-Host "`n🔍 Querying SigNoz for pattern ingestion verification..." -ForegroundColor Cyan
    
    # Check SigNoz for canary logs
    try {
        $SigNozQuery = @{
            start = [int]($TestStart - (Get-Date '1970-01-01')).TotalSeconds
            end = [int]($TestEnd - (Get-Date '1970-01-01')).TotalSeconds
            query = 'message contains "windows-canary"'
        }
        
        $SigNozResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs" -Method Get -Body $SigNozQuery -ErrorAction Stop
        Write-Host "✅ SigNoz ingestion verified: $($SigNozResponse.data.result.length) logs found" -ForegroundColor Green
        
    } catch {
        Write-Host "⚠️ SigNoz verification failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 Canary Pattern Drills Complete!" -ForegroundColor Green
Write-Host "Next: Deploy fractal drift monitors dashboard" -ForegroundColor Yellow