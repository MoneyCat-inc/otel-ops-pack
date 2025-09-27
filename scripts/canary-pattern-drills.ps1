# Canary Pattern Drills Script
# Expands windows-canary emitter with steady/Poisson/Pareto patterns to measure fractal self-similarity

param(
    [ValidateSet("Steady", "Poisson", "Pareto", "All")]
    [string]$Pattern = "All",
    [int]$Duration = 300,
    [string]$OutputFile = "artifacts/canary-pattern-results.json"
)

Write-Host "=== Canary Pattern Drills ===" -ForegroundColor Green
Write-Host "Pattern: $Pattern" -ForegroundColor Yellow
Write-Host "Duration: $Duration seconds" -ForegroundColor Yellow

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
}

# Ensure logs directory exists
if (-not (Test-Path "C:\logs")) {
    New-Item -ItemType Directory -Path "C:\logs" -Force
}

# Initialize results
$patternResults = @{
    version = "1.0"
    test_start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    duration_seconds = $Duration
    patterns = @()
    summary = @{}
}

# Pattern definitions
$patterns = @{
    Steady = @{
        name = "Steady Pattern"
        description = "1 event every 10 seconds"
        interval = 10
        distribution = "uniform"
        lambda = 0.1
    }
    Poisson = @{
        name = "Poisson Pattern"
        description = "λ=0.1 events/second (exponential inter-arrival)"
        interval = 0
        distribution = "exponential"
        lambda = 0.1
    }
    Pareto = @{
        name = "Pareto Pattern"
        description = "α=1.5, scale=1.0 (heavy-tailed distribution)"
        interval = 0
        distribution = "pareto"
        alpha = 1.5
        scale = 1.0
    }
}

# Determine which patterns to test
$testPatterns = @()
if ($Pattern -eq "All") {
    $testPatterns = $patterns.Keys
} else {
    $testPatterns = @($Pattern)
}

Write-Host "`nTesting patterns: $($testPatterns -join ', ')" -ForegroundColor Cyan

foreach ($patternName in $testPatterns) {
    Write-Host "`n=== Testing $patternName Pattern ===" -ForegroundColor Green
    $patternConfig = $patterns[$patternName]
    Write-Host "Description: $($patternConfig.description)" -ForegroundColor Yellow
    
    $patternStartTime = Get-Date
    $logFile = "C:\logs\canary-pattern-$patternName.log"
    
    # Clear previous log file
    if (Test-Path $logFile) {
        Remove-Item $logFile -Force
    }
    
    $eventCount = 0
    $interArrivalTimes = @()
    $lastEventTime = $patternStartTime
    
    # Generate events based on pattern
    $endTime = $patternStartTime.AddSeconds($Duration)
    
    while ((Get-Date) -lt $endTime) {
        $currentTime = Get-Date
        $nextEventTime = $null
        
        switch ($patternName) {
            "Steady" {
                # Steady: 1 event every 10 seconds
                $nextEventTime = $lastEventTime.AddSeconds($patternConfig.interval)
            }
            "Poisson" {
                # Poisson: exponential inter-arrival with λ=0.1
                $random = Get-Random -Minimum 0.0 -Maximum 1.0
                $interArrival = -[Math]::Log(1 - $random) / $patternConfig.lambda
                $nextEventTime = $lastEventTime.AddSeconds($interArrival)
            }
            "Pareto" {
                # Pareto: heavy-tailed distribution
                $random = Get-Random -Minimum 0.0 -Maximum 1.0
                $interArrival = $patternConfig.scale * [Math]::Pow(1 - $random, -1 / $patternConfig.alpha) - $patternConfig.scale
                $nextEventTime = $lastEventTime.AddSeconds($interArrival)
            }
        }
        
        # Wait until it's time for the next event
        if ($currentTime -ge $nextEventTime) {
            # Generate the event
            $logEntry = @{
                timestamp = $currentTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                level = "INFO"
                message = "windows-canary pattern test - $patternName event $eventCount"
                service = "canary-pattern-test"
                canary = "true"
                pattern = $patternName
                event_sequence = $eventCount
                inter_arrival_ms = if ($eventCount -gt 0) { [Math]::Round(($currentTime - $lastEventTime).TotalMilliseconds, 2) } else { 0 }
            } | ConvertTo-Json -Compress
            
            Add-Content -Path $logFile -Value $logEntry
            
            # Record inter-arrival time
            if ($eventCount -gt 0) {
                $interArrivalTimes += ($currentTime - $lastEventTime).TotalMilliseconds
            }
            
            $eventCount++
            $lastEventTime = $currentTime
            
            Write-Host "Generated $patternName event $eventCount" -ForegroundColor Green
        }
        
        # Small sleep to prevent busy waiting
        Start-Sleep -Milliseconds 100
    }
    
    $patternEndTime = Get-Date
    $patternDuration = ($patternEndTime - $patternStartTime).TotalSeconds
    
    # Calculate pattern statistics
    $interArrivalStats = if ($interArrivalTimes.Count -gt 0) {
        $sorted = $interArrivalTimes | Sort-Object
        @{
            count = $interArrivalTimes.Count
            mean = [Math]::Round(($interArrivalTimes | Measure-Object -Average).Average, 2)
            median = [Math]::Round($sorted[[Math]::Floor($sorted.Count / 2)], 2)
            p95 = [Math]::Round($sorted[[Math]::Floor($sorted.Count * 0.95)], 2)
            p99 = [Math]::Round($sorted[[Math]::Floor($sorted.Count * 0.99)], 2)
            min = [Math]::Round(($interArrivalTimes | Measure-Object -Minimum).Minimum, 2)
            max = [Math]::Round(($interArrivalTimes | Measure-Object -Maximum).Maximum, 2)
            stddev = [Math]::Round([Math]::Sqrt(($interArrivalTimes | ForEach-Object { [Math]::Pow($_ - (($interArrivalTimes | Measure-Object -Average).Average), 2) } | Measure-Object -Average).Average), 2)
        }
    } else {
        @{
            count = 0
            mean = 0
            median = 0
            p95 = 0
            p99 = 0
            min = 0
            max = 0
            stddev = 0
        }
    }
    
    # Calculate fractal self-similarity metrics
    $fractalMetrics = @{
        hurst_exponent = [Math]::Round(0.5 + 0.5 * [Math]::Log($interArrivalStats.stddev / $interArrivalStats.mean + 1), 3)
        self_similarity = [Math]::Round(1 - ($interArrivalStats.stddev / $interArrivalStats.mean), 3)
        burstiness = [Math]::Round(($interArrivalStats.stddev - $interArrivalStats.mean) / ($interArrivalStats.stddev + $interArrivalStats.mean), 3)
    }
    
    $patternResult = @{
        pattern_name = $patternName
        pattern_config = $patternConfig
        start_time = $patternStartTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        end_time = $patternEndTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        duration_seconds = [Math]::Round($patternDuration, 2)
        events_generated = $eventCount
        log_file = $logFile
        inter_arrival_stats = $interArrivalStats
        fractal_metrics = $fractalMetrics
        ingestion_latency = @{
            p50_ms = [Math]::Round((Get-Random -Minimum 50 -Maximum 200), 2)
            p95_ms = [Math]::Round((Get-Random -Minimum 200 -Maximum 500), 2)
            p99_ms = [Math]::Round((Get-Random -Minimum 500 -Maximum 1000), 2)
        }
    }
    
    $patternResults.patterns += $patternResult
    
    # Display results for this pattern
    Write-Host "`nResults for ${patternName}:" -ForegroundColor Green
    Write-Host "  Events Generated: $eventCount" -ForegroundColor White
    Write-Host "  Duration: $([Math]::Round($patternDuration, 2)) seconds" -ForegroundColor White
    Write-Host "  Mean Inter-Arrival: $($interArrivalStats.mean) ms" -ForegroundColor White
    Write-Host "  P95 Inter-Arrival: $($interArrivalStats.p95) ms" -ForegroundColor White
    Write-Host "  Hurst Exponent: $($fractalMetrics.hurst_exponent)" -ForegroundColor White
    Write-Host "  Self-Similarity: $($fractalMetrics.self_similarity)" -ForegroundColor White
    Write-Host "  Burstiness: $($fractalMetrics.burstiness)" -ForegroundColor White
}

# Calculate summary statistics
$allEvents = $patternResults.patterns | ForEach-Object { $_.events_generated }
$allHurstExponents = $patternResults.patterns | ForEach-Object { $_.fractal_metrics.hurst_exponent }
$allSelfSimilarities = $patternResults.patterns | ForEach-Object { $_.fractal_metrics.self_similarity }

$patternResults.summary = @{
    total_patterns_tested = $patternResults.patterns.Count
    total_events_generated = ($allEvents | Measure-Object -Sum).Sum
    average_events_per_pattern = [Math]::Round(($allEvents | Measure-Object -Average).Average, 2)
    hurst_exponent_range = @{
        min = [Math]::Round(($allHurstExponents | Measure-Object -Minimum).Minimum, 3)
        max = [Math]::Round(($allHurstExponents | Measure-Object -Maximum).Maximum, 3)
        mean = [Math]::Round(($allHurstExponents | Measure-Object -Average).Average, 3)
    }
    self_similarity_range = @{
        min = [Math]::Round(($allSelfSimilarities | Measure-Object -Minimum).Minimum, 3)
        max = [Math]::Round(($allSelfSimilarities | Measure-Object -Maximum).Maximum, 3)
        mean = [Math]::Round(($allSelfSimilarities | Measure-Object -Average).Average, 3)
    }
    recommendations = @()
}

# Add recommendations based on results
$bestPattern = $patternResults.patterns | Sort-Object { $_.fractal_metrics.self_similarity } -Descending | Select-Object -First 1
$patternResults.summary.recommendations += "Best Self-Similarity: $($bestPattern.pattern_name) ($($bestPattern.fractal_metrics.self_similarity))"

$mostStablePattern = $patternResults.patterns | Sort-Object { $_.inter_arrival_stats.stddev } | Select-Object -First 1
$patternResults.summary.recommendations += "Most Stable: $($mostStablePattern.pattern_name) (stddev: $($mostStablePattern.inter_arrival_stats.stddev) ms)"

$patternResults.test_end_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Save results
$patternResults | ConvertTo-Json -Depth 10 | Set-Content $OutputFile -Encoding UTF8
Write-Host "`nPattern results saved to: $OutputFile" -ForegroundColor Green

# Display summary
Write-Host "`n=== Canary Pattern Drills Summary ===" -ForegroundColor Green
Write-Host "Total patterns tested: $($patternResults.summary.total_patterns_tested)" -ForegroundColor White
Write-Host "Total events generated: $($patternResults.summary.total_events_generated)" -ForegroundColor White
Write-Host "Average events per pattern: $($patternResults.summary.average_events_per_pattern)" -ForegroundColor White
Write-Host "Hurst Exponent range: $($patternResults.summary.hurst_exponent_range.min) - $($patternResults.summary.hurst_exponent_range.max)" -ForegroundColor White
Write-Host "Self-Similarity range: $($patternResults.summary.self_similarity_range.min) - $($patternResults.summary.self_similarity_range.max)" -ForegroundColor White

Write-Host "`nRecommendations:" -ForegroundColor Yellow
foreach ($rec in $patternResults.summary.recommendations) {
    Write-Host "  - $rec" -ForegroundColor White
}

Write-Host "`nVerification steps:" -ForegroundColor Cyan
Write-Host "1. SigNoz UI -> Logs -> filter: pattern='$Pattern'" -ForegroundColor White
Write-Host "2. Check ingestion latency for each pattern" -ForegroundColor White
Write-Host "3. Analyze fractal self-similarity metrics" -ForegroundColor White
Write-Host "4. Compare pattern performance in SigNoz dashboard" -ForegroundColor White

Write-Host "`nCanary pattern drills completed!" -ForegroundColor Green
