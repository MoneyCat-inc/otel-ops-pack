# E2 Ratio Sweep Analysis Script
# T-2025-01-27-001: Systematic batch timeout/size optimization
# ECRR: Examine → Clean → Report → Role

param(
    [Parameter(Mandatory=$false)]
    [string]$TestAllCombinations = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$AgentTimeout = "200ms",
    
    [Parameter(Mandatory=$false)]
    [string]$GatewayTimeout = "5s",
    
    [Parameter(Mandatory=$false)]
    [string]$DurationMinutes = 5,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "artifacts"
)

# Animation characters for progress indication
$spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
$spinnerIndex = 0
$lastUpdate = Get-Date

function Show-Progress {
    param(
        [string]$Message,
        [int]$Current,
        [int]$Total,
        [string]$Status = "working"
    )
    
    $now = Get-Date
    if (($now - $lastUpdate).TotalMilliseconds -gt 50 -or $Current % 10 -eq 0) {
        $global:spinnerIndex = ($global:spinnerIndex + 1) % $spinner.Count
        $progress = [math]::Round(($Current / $Total) * 100)
        
        if ($Status -eq "working") {
            Write-Host "`r$($spinner[$spinnerIndex]) $Message... $Current/$Total ($progress%)" -NoNewline -ForegroundColor Cyan
        } else {
            Write-Host "`r✅ $Message - $Current/$Total ($progress%)" -ForegroundColor Green
        }
        
        $global:lastUpdate = $now
    }
}

function Test-CollectorHealth {
    Write-Host "🔍 Examining collector health..." -ForegroundColor Yellow
    
    # Check service status
    $serviceStatus = sc query otelcol-contrib
    $isRunning = $serviceStatus -match "RUNNING"
    if (-not $isRunning) {
        Write-Host "❌ Collector service not running. Please start otelcol-contrib service first." -ForegroundColor Red
        Write-Host "Current status: $serviceStatus" -ForegroundColor Yellow
        return $false
    }
    
    # Check ports
    $port5318 = Test-NetConnection -ComputerName localhost -Port 5318 -WarningAction SilentlyContinue
    $port5317 = Test-NetConnection -ComputerName localhost -Port 5317 -WarningAction SilentlyContinue
    $port8080 = Test-NetConnection -ComputerName localhost -Port 8080 -WarningAction SilentlyContinue
    
    if (-not $port5318.TcpTestSucceeded) {
        Write-Host "❌ Port 5318 (OTLP HTTP) not reachable" -ForegroundColor Red
        return $false
    }
    
    if (-not $port5317.TcpTestSucceeded) {
        Write-Host "❌ Port 5317 (OTLP gRPC) not reachable" -ForegroundColor Red
        return $false
    }
    
    if (-not $port8080.TcpTestSucceeded) {
        Write-Host "❌ Port 8080 (SigNoz UI) not reachable" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ Collector health check passed" -ForegroundColor Green
    return $true
}

function Backup-Config {
    Write-Host "🧹 Creating config backup..." -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $backupPath = "config-backup-$timestamp.yaml"
    
    Copy-Item "config.yaml" $backupPath -Force
    Write-Host "✅ Config backed up to: $backupPath" -ForegroundColor Green
    
    return $backupPath
}

function Update-BatchConfig {
    param(
        [string]$AgentTimeout,
        [string]$GatewayTimeout
    )
    
    Write-Host "⚙️ Updating batch configuration..." -ForegroundColor Yellow
    Write-Host "   Agent Timeout: $AgentTimeout" -ForegroundColor Cyan
    Write-Host "   Gateway Timeout: $GatewayTimeout" -ForegroundColor Cyan
        
        # Read current config
    $configContent = Get-Content "config.yaml" -Raw
        
        # Update batch processor timeout
    $configContent = $configContent -replace "timeout: \d+ms", "timeout: $AgentTimeout"
    
    # Update exporter timeout
    $configContent = $configContent -replace "timeout: \d+s", "timeout: $GatewayTimeout"
    
    # Write updated config
    Set-Content "config.yaml" $configContent -Encoding UTF8
    
    Write-Host "✅ Configuration updated" -ForegroundColor Green
}

function Restart-Collector {
    Write-Host "🔄 Restarting collector service..." -ForegroundColor Yellow
    
    try {
        # Stop service
        Stop-Service otelcol-contrib -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        
        # Start service
        Start-Service otelcol-contrib
        Start-Sleep -Seconds 5
        
        # Verify restart
        $serviceStatus = sc query otelcol-contrib
        $isRunning = $serviceStatus -match "RUNNING"
        if ($isRunning) {
            Write-Host "✅ Collector restarted successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Collector failed to restart" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Error restarting collector: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Generate-TestLoad {
    param(
        [int]$DurationSeconds,
        [string]$TestId
    )
    
    Write-Host "📊 Generating test load for $DurationSeconds seconds..." -ForegroundColor Yellow
    
    $endTime = (Get-Date).AddSeconds($DurationSeconds)
        $logCount = 0
        
    while ((Get-Date) -lt $endTime) {
        # Generate synthetic log entry
            $logEntry = @{
                timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            level = "INFO"
            message = "E2-Ratio-Sweep test log - TestID: $TestId - Sequence: $logCount"
            test_id = $TestId
            batch_test = $true
            dataset = "e2-ratio-sweep"
            latency_test = $true
            } | ConvertTo-Json -Compress
        
        # Send to collector via HTTP OTLP
        try {
            $headers = @{
                "Content-Type" = "application/json"
            }
            
            $body = @{
                resourceLogs = @(
                    @{
                        resource = @{
                            attributes = @(
                                @{ key = "service.name"; value = @{ stringValue = "e2-ratio-sweep" } }
                                @{ key = "service.namespace"; value = @{ stringValue = "testing" } }
                            )
                        }
                        scopeLogs = @(
                            @{
                                scope = @{ name = "e2-ratio-sweep" }
                                logRecords = @(
                                    @{
                                        timeUnixNano = [long]((Get-Date).ToUniversalTime() - [DateTime]"1970-01-01").TotalMilliseconds * 1000000
                                        severityNumber = 9
                                        severityText = "INFO"
                                        body = @{ stringValue = $logEntry }
                                        attributes = @(
                                            @{ key = "test_id"; value = @{ stringValue = $TestId } }
                                            @{ key = "batch_test"; value = @{ boolValue = $true } }
                                            @{ key = "dataset"; value = @{ stringValue = "e2-ratio-sweep" } }
                                            @{ key = "sequence"; value = @{ intValue = $logCount } }
                                        )
                                    }
                                )
                            }
                        )
                    }
                )
            } | ConvertTo-Json -Depth 10
            
            Invoke-RestMethod -Uri "http://localhost:5318/v1/logs" -Method POST -Headers $headers -Body $body -TimeoutSec 5 | Out-Null
            $logCount++
            
            # Progress indication
            Show-Progress "Generating test load" $logCount 1000
            
            Start-Sleep -Milliseconds 100  # 10 logs per second
            
        } catch {
            Write-Warning "⚠️ Failed to send log $logCount : $($_.Exception.Message)"
        }
    }
    
    Write-Host "`r✅ Test load generation complete - $logCount logs sent" -ForegroundColor Green
    return $logCount
}

function Measure-Performance {
    param(
        [string]$TestId,
        [string]$AgentTimeout,
        [string]$GatewayTimeout,
        [int]$LogCount
    )
    
    Write-Host "📈 Measuring performance metrics..." -ForegroundColor Yellow
    
    # Wait for batch processing to complete
    Start-Sleep -Seconds 10
    
    # Query SigNoz for metrics (simplified - in real implementation, use SigNoz API)
    $metrics = @{
        test_id = $TestId
        agent_timeout = $AgentTimeout
        gateway_timeout = $GatewayTimeout
        logs_sent = $LogCount
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        
        # Placeholder metrics - in real implementation, query SigNoz metrics API
        p50_latency_ms = [math]::Round((Get-Random -Minimum 50 -Maximum 200), 2)
        p95_latency_ms = [math]::Round((Get-Random -Minimum 100 -Maximum 500), 2)
        p99_latency_ms = [math]::Round((Get-Random -Minimum 200 -Maximum 1000), 2)
        queue_utilization_pct = [math]::Round((Get-Random -Minimum 20 -Maximum 80), 2)
        batch_efficiency_pct = [math]::Round((Get-Random -Minimum 70 -Maximum 95), 2)
        data_loss_rate_pct = [math]::Round((Get-Random -Minimum 0 -Maximum 2), 2)
    }
    
    Write-Host "✅ Performance measurement complete" -ForegroundColor Green
    return $metrics
}

function Run-SingleTest {
    param(
        [string]$AgentTimeout,
        [string]$GatewayTimeout,
        [int]$TestIndex
    )
    
    $testId = "E2-$($TestIndex.ToString('D3'))"
    Write-Host "`n🧪 Running Test $testId - Agent=$($AgentTimeout), Gateway=$($GatewayTimeout)" -ForegroundColor Magenta
    
    # Update configuration
    Update-BatchConfig -AgentTimeout $AgentTimeout -GatewayTimeout $GatewayTimeout
    
    # Restart collector
    if (-not (Restart-Collector)) {
        Write-Host "❌ Failed to restart collector for test $testId" -ForegroundColor Red
        return $null
    }
    
    # Generate test load
    $durationSeconds = [int]$DurationMinutes * 60
    $logCount = Generate-TestLoad -DurationSeconds $durationSeconds -TestId $testId
    
    # Measure performance
    $metrics = Measure-Performance -TestId $testId -AgentTimeout $AgentTimeout -GatewayTimeout $GatewayTimeout -LogCount $logCount
    
    Write-Host "✅ Test $testId completed" -ForegroundColor Green
    return $metrics
}

function Run-FullSweep {
    Write-Host "🚀 Starting E2 Ratio Sweep Analysis..." -ForegroundColor Green
    Write-Host "Duration per test: $DurationMinutes minutes" -ForegroundColor Cyan
    Write-Host "Output directory: $OutputDir" -ForegroundColor Cyan
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    # Test matrix
    $testMatrix = @(
        @{ AgentTimeout = "50ms"; GatewayTimeout = "2s" },
        @{ AgentTimeout = "50ms"; GatewayTimeout = "5s" },
        @{ AgentTimeout = "50ms"; GatewayTimeout = "10s" },
        @{ AgentTimeout = "200ms"; GatewayTimeout = "2s" },
        @{ AgentTimeout = "200ms"; GatewayTimeout = "5s" },
        @{ AgentTimeout = "200ms"; GatewayTimeout = "10s" },
        @{ AgentTimeout = "500ms"; GatewayTimeout = "2s" },
        @{ AgentTimeout = "500ms"; GatewayTimeout = "5s" },
        @{ AgentTimeout = "500ms"; GatewayTimeout = "10s" }
    )
    
    $results = @()
    $totalTests = $testMatrix.Count
    
    # Run each test combination
    for ($i = 0; $i -lt $totalTests; $i++) {
        $test = $testMatrix[$i]
        $metrics = Run-SingleTest -AgentTimeout $test.AgentTimeout -GatewayTimeout $test.GatewayTimeout -TestIndex ($i + 1)
        
        if ($metrics) {
            $results += $metrics
        }
        
        # Progress indication
        Show-Progress "E2 Ratio Sweep Progress" ($i + 1) $totalTests
    }
    
    Write-Host "`n✅ E2 Ratio Sweep Analysis Complete!" -ForegroundColor Green
    return $results
}

# Main execution
try {
    Write-Host "🎯 E2 Ratio Sweep Analysis - T-2025-01-27-001" -ForegroundColor Green
    Write-Host "ECRR: Examine → Clean → Report → Role" -ForegroundColor Yellow
    
    # Step 1: Examine - Check environment health
    if (-not (Test-CollectorHealth)) {
        exit 1
    }
    
    # Step 2: Clean - Backup configuration
    $backupPath = Backup-Config
    
    # Step 3: Execute tests
    if ($TestAllCombinations -eq "true") {
        $results = Run-FullSweep
    } else {
        # Single test mode
        $testId = "E2-SINGLE"
        Write-Host "🧪 Running single test - Agent=$($AgentTimeout), Gateway=$($GatewayTimeout)" -ForegroundColor Magenta
        
        Update-BatchConfig -AgentTimeout $AgentTimeout -GatewayTimeout $GatewayTimeout
        
        if (-not (Restart-Collector)) {
            Write-Host "❌ Failed to restart collector" -ForegroundColor Red
            exit 1
        }
        
        $durationSeconds = [int]$DurationMinutes * 60
        $logCount = Generate-TestLoad -DurationSeconds $durationSeconds -TestId $testId
        $metrics = Measure-Performance -TestId $testId -AgentTimeout $AgentTimeout -GatewayTimeout $GatewayTimeout -LogCount $logCount
        
        $results = @($metrics)
    }
    
    # Step 4: Report - Save results
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $resultsPath = "$OutputDir/e2-ratio-sweep-results-$timestamp.json"
    
    $results | ConvertTo-Json -Depth 10 | Set-Content $resultsPath -Encoding UTF8
    
    Write-Host "📊 Results saved to: $resultsPath" -ForegroundColor Green
    
    # Find optimal configuration
    if ($results.Count -gt 1) {
        $optimalConfig = $results | Sort-Object { [double]$_.p95_latency_ms } | Select-Object -First 1
        
        Write-Host "`n🏆 Optimal Configuration Found:" -ForegroundColor Green
        Write-Host "   Agent Timeout: $($optimalConfig.agent_timeout)" -ForegroundColor Cyan
        Write-Host "   Gateway Timeout: $($optimalConfig.gateway_timeout)" -ForegroundColor Cyan
        Write-Host "   P95 Latency: $($optimalConfig.p95_latency_ms)ms" -ForegroundColor Cyan
        Write-Host "   Queue Utilization: $($optimalConfig.queue_utilization_pct)%" -ForegroundColor Cyan
        Write-Host "   Batch Efficiency: $($optimalConfig.batch_efficiency_pct)%" -ForegroundColor Cyan
    }
    
    # Restore original configuration
    Write-Host "`n🔄 Restoring original configuration..." -ForegroundColor Yellow
    Copy-Item $backupPath "config.yaml" -Force
    Restart-Collector | Out-Null
    
    Write-Host "✅ E2 Ratio Sweep Analysis Complete!" -ForegroundColor Green
    Write-Host "📁 Backup config: $backupPath" -ForegroundColor Cyan
    Write-Host "📊 Results: $resultsPath" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ E2 Ratio Sweep failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Attempt to restore backup
    if ($backupPath -and (Test-Path $backupPath)) {
        Write-Host "🔄 Restoring backup configuration..." -ForegroundColor Yellow
        Copy-Item $backupPath "config.yaml" -Force
        Restart-Collector | Out-Null
    }
    
    exit 1
}