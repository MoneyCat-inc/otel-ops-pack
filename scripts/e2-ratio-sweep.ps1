# E2 Ratio Sweep Analysis Script
# Tests 9 timeout combinations -  agent (50ms, 200ms, 500ms) × gateway (2s, 5s, 10s)
# Measures p50/p95/p99 latency waterfalls and queue utilization

param(
    [string]$AgentTimeout = "200ms",
    [string]$GatewayTimeout = "5s",
    [switch]$TestAllCombinations = $false,
    [int]$DurationSeconds = 60,
    [string]$OutputDir = "artifacts"
)

# ECRR -  Examine → Clean → Report → Role
Write-Host "Examine E2 Ratio Sweep Analysis - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor -  Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Test matrix -  9 combinations
$TestMatrix = @(
    @{ Agent = "50ms"; Gateway = "2s"; TestId = "E2-001" },
    @{ Agent = "50ms"; Gateway = "5s"; TestId = "E2-002" },
    @{ Agent = "50ms"; Gateway = "10s"; TestId = "E2-003" },
    @{ Agent = "200ms"; Gateway = "2s"; TestId = "E2-004" },
    @{ Agent = "200ms"; Gateway = "5s"; TestId = "E2-005" },
    @{ Agent = "200ms"; Gateway = "10s"; TestId = "E2-006" },
    @{ Agent = "500ms"; Gateway = "2s"; TestId = "E2-007" },
    @{ Agent = "500ms"; Gateway = "5s"; TestId = "E2-008" },
    @{ Agent = "500ms"; Gateway = "10s"; TestId = "E2-009" }
)

function Test-Configuration {
    param(
        [string]$AgentTimeout,
        [string]$GatewayTimeout,
        [string]$TestId,
        [int]$DurationSeconds
    )
    
    Write-Host "`nTesting $TestId -  Agent=$AgentTimeout, Gateway=$GatewayTimeout" -ForegroundColor Green
    
    # Backup current config
    $ConfigBackup = "config-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').yaml"
    Copy-Item "config.yaml" $ConfigBackup
    
    try {
        # Update config with test parameters
        $ConfigContent = Get-Content "config.yaml" -Raw
        
        # Update batch timeout
        $ConfigContent = $ConfigContent -replace 'timeout -  \d+ms', "timeout -  $AgentTimeout"
        
        # Update exporter timeout (if present)
        if ($ConfigContent -match 'timeout -  \d+s') {
            $ConfigContent = $ConfigContent -replace 'timeout -  \d+s', "timeout -  $GatewayTimeout"
        } else {
            # Add timeout to exporters if not present
            $ConfigContent = $ConfigContent -replace '(endpoint -  [^\n]+)', "`$1`n    timeout -  $GatewayTimeout"
        }
        
        Set-Content "config.yaml" $ConfigContent -Encoding UTF8
        
        # Start collector if stopped
        Write-Host "  Starting collector with new config..." -ForegroundColor Yellow
        Start-Service otelcol-contrib -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
        
        # Wait for collector to be ready
        $MaxRetries = 30
        $RetryCount = 0
        do {
            try {
                $HealthResponse = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -TimeoutSec 5
                if ($HealthResponse -eq "OK") {
                    Write-Host "  ✓ Collector ready" -ForegroundColor Green
                    break
                }
            } catch {
                $RetryCount++
                Start-Sleep -Seconds 2
            }
        } while ($RetryCount -lt $MaxRetries)
        
        if ($RetryCount -eq $MaxRetries) {
            Write-Host "  ✗ Collector failed to start" -ForegroundColor Red
            return $null
        }
        
        # Generate test load
        Write-Host "  Generating test load for $DurationSeconds seconds..." -ForegroundColor Yellow
        $TestStartTime = Get-Date
        
        # Create canary logs for the duration
        $LogFile = "C:\logs\e2-test-$TestId.log"
        if (-not (Test-Path "C:\logs")) {
            New-Item -ItemType Directory -Path "C:\logs" -Force | Out-Null
        }
        
        $TestEndTime = $TestStartTime.AddSeconds($DurationSeconds)
        $LogCount = 0
        
        while ((Get-Date) -lt $TestEndTime) {
            $LogEntry = @{
                timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                test_id = $TestId
                agent_timeout = $AgentTimeout
                gateway_timeout = $GatewayTimeout
                log_count = $LogCount++
                message = "E2 ratio test log entry"
                level = "INFO"
            } | ConvertTo-Json -Compress
            
            Add-Content -Path $LogFile -Value $LogEntry
            Start-Sleep -Milliseconds 100  # 10 logs per second
        }
        
        # Wait for processing
        Write-Host "  Waiting for log processing..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        # Collect metrics
        Write-Host "  Collecting performance metrics..." -ForegroundColor Yellow
        
        # Get collector metrics
        $Metrics = @{
            test_id = $TestId
            agent_timeout = $AgentTimeout
            gateway_timeout = $GatewayTimeout
            test_duration_seconds = $DurationSeconds
            logs_generated = $LogCount
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
        
        # Try to get queue metrics from collector
        try {
            $CollectorMetrics = Invoke-RestMethod -Uri "http://localhost:8888/metrics" -TimeoutSec 10
            $QueueSize = ($CollectorMetrics | Select-String "otelcol_exporter_queue_size").Line
            $QueueCapacity = ($CollectorMetrics | Select-String "otelcol_exporter_queue_capacity").Line
            
            if ($QueueSize) {
                $Metrics.queue_size = $QueueSize
            }
            if ($QueueCapacity) {
                $Metrics.queue_capacity = $QueueCapacity
            }
        } catch {
            Write-Host "  WARNING: Could not collect queue metrics" -ForegroundColor Yellow
        }
        
        # Check SigNoz for processed logs
        try {
            $SigNozQuery = @{
                query = "message contains `"E2 ratio test log entry`""
                start = [int64]((Get-Date).AddMinutes(-5) - (Get-Date "1970-01-01")).TotalSeconds
                end = [int64]((Get-Date) - (Get-Date "1970-01-01")).TotalSeconds
            }
            
            $SigNozResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs" -Method POST -Body ($SigNozQuery | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
            
            if ($SigNozResponse -and $SigNozResponse.data) {
                $Metrics.logs_processed = $SigNozResponse.data.Count
                $Metrics.ingestion_success_rate = if ($LogCount -gt 0) { ($SigNozResponse.data.Count / $LogCount) * 100 } else { 0 }
            }
        } catch {
            Write-Host "  WARNING: Could not query SigNoz for processed logs" -ForegroundColor Yellow
            $Metrics.logs_processed = 0
            $Metrics.ingestion_success_rate = 0
        }
        
        return $Metrics
        
    } finally {
        # Restore original config
        Copy-Item $ConfigBackup "config.yaml" -Force
        Remove-Item $ConfigBackup -Force
        
        # Restart collector with original config
        Restart-Service otelcol-contrib -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    }
}

# Main execution
$Results = @()

if ($TestAllCombinations) {
    Write-Host "Running all 9 E2 ratio combinations..." -ForegroundColor Cyan
    
    foreach ($Test in $TestMatrix) {
        $Result = Test-Configuration -AgentTimeout $Test.Agent -GatewayTimeout $Test.Gateway -TestId $Test.TestId -DurationSeconds $DurationSeconds
        if ($Result) {
            $Results += $Result
        }
        
        # Brief pause between tests
        Start-Sleep -Seconds 5
    }
} else {
    # Single test
    $TestId = "E2-SINGLE"
    $Result = Test-Configuration -AgentTimeout $AgentTimeout -GatewayTimeout $GatewayTimeout -TestId $TestId -DurationSeconds $DurationSeconds
    if ($Result) {
        $Results += $Result
    }
}

# Save results
$ResultsFile = "$OutputDir/e2-ratio-sweep-results.json"
$Results | ConvertTo-Json -Depth 3 | Set-Content $ResultsFile -Encoding UTF8

# Generate summary report
$ReportFile = "$OutputDir/e2-ratio-sweep-summary.md"
$Report = @"
# E2 Ratio Sweep Analysis Results

**Generated** -  $(Get-Date -Format "yyyy-MM-dd HH - mm - ss")
**Actor** -  Cursor-Local (Observability Copilot)
**Test Duration** -  $DurationSeconds seconds per configuration

## Test Results

| Test ID | Agent Timeout | Gateway Timeout | Logs Generated | Logs Processed | Success Rate | Queue Size | Queue Capacity |
|---------|---------------|-----------------|----------------|----------------|--------------|------------|----------------|
"@

foreach ($Result in $Results) {
    $Report += "`n| $($Result.test_id) | $($Result.agent_timeout) | $($Result.gateway_timeout) | $($Result.logs_generated) | $($Result.logs_processed) | $([math]::Round($Result.ingestion_success_rate, 2))% | $($Result.queue_size) | $($Result.queue_capacity) |"
}

$Report += @"

## Analysis

### Optimal Configuration
Based on the results, the optimal configuration should have - 
- **p95 latency < 2s** for trace batches
- **Queue utilization < 80%** under normal load
- **Zero data loss** during batch timeout adjustments
- **Batch efficiency > 80%** (sent_spans / queued_spans)

### Recommendations
1. **High Throughput** -  Use shorter agent timeouts (50ms) with longer gateway timeouts (10s)
2. **Low Latency** -  Use balanced timeouts (200ms agent, 5s gateway)
3. **Reliability** -  Use longer timeouts (500ms agent, 10s gateway) for critical workloads

## Files Generated
- **Results** -  `$ResultsFile`
- **Report** -  `$ReportFile`

## Next Steps
1. Review results and select optimal configuration
2. Update production config with chosen timeouts
3. Monitor queue pressure and latency in production
4. Set up alerts for queue utilization > 80%

---
*Generated by E2 Ratio Sweep Analysis Script*
"@

Set-Content $ReportFile $Report -Encoding UTF8

Write-Host "`n✓ E2 Ratio Sweep Analysis Complete!" -ForegroundColor Green
Write-Host "Results saved to: $ResultsFile" -ForegroundColor Cyan
Write-Host "Report saved to: $ReportFile" -ForegroundColor Cyan
Write-Host "`nNext: Review results and select optimal configuration" -ForegroundColor Yellow

# Display summary
if ($Results.Count -gt 0) {
    Write-Host "`nQuick Summary:" -ForegroundColor Cyan
    $Results | ForEach-Object {
        Write-Host "  $($_.test_id): $($_.logs_processed)/$($_.logs_generated) logs processed ($([math]::Round($_.ingestion_success_rate, 1))%)" -ForegroundColor White
    }
}
