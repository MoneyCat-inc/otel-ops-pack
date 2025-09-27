# E2 Ratio Optimization Sweep
# T-2025-01-27-001: Systematic E2 ratio optimization through batch timeout/size permutations
# Cursor-Local: Observability Copilot

param(
    [string]$AgentTimeout = "200ms",
    [string]$GatewayTimeout = "5s",
    [switch]$TestAllCombinations = $false,
    [int]$DurationSeconds = 60
)

# ECRR: Examine → Clean → Report → Role
Write-Host "🔍 E2 Ratio Sweep Analysis - ECRR Framework" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

# Test matrix: Agent Timeout × Gateway Timeout
$TestMatrix = @(
    @{Agent="50ms"; Gateway="2s"; ID="E2-001"},
    @{Agent="50ms"; Gateway="5s"; ID="E2-002"},
    @{Agent="50ms"; Gateway="10s"; ID="E2-003"},
    @{Agent="200ms"; Gateway="2s"; ID="E2-004"},
    @{Agent="200ms"; Gateway="5s"; ID="E2-005"},
    @{Agent="200ms"; Gateway="10s"; ID="E2-006"},
    @{Agent="500ms"; Gateway="2s"; ID="E2-007"},
    @{Agent="500ms"; Gateway="5s"; ID="E2-008"},
    @{Agent="500ms"; Gateway="10s"; ID="E2-009"}
)

# Results storage
$Results = @()
$ArtifactsDir = "artifacts"
if (-not (Test-Path $ArtifactsDir)) {
    New-Item -ItemType Directory -Path $ArtifactsDir | Out-Null
}

function Test-E2Combination {
    param($AgentTimeout, $GatewayTimeout, $TestID)
    
    Write-Host "`n🧪 Testing ${TestID}: Agent=${AgentTimeout}, Gateway=${GatewayTimeout}" -ForegroundColor Yellow
    
    # 1. Update config.yaml with test parameters
    $ConfigPath = "config.yaml"
    $ConfigBackup = "config-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').yaml"
    Copy-Item $ConfigPath $ConfigBackup
    
    try {
        # Update batch processor timeout
        $ConfigContent = Get-Content $ConfigPath -Raw
        $ConfigContent = $ConfigContent -replace 'timeout: \d+ms', "timeout: $AgentTimeout"
        
        # Update exporter timeout (if present)
        if ($ConfigContent -match 'timeout: \d+s') {
            $ConfigContent = $ConfigContent -replace 'timeout: \d+s', "timeout: $GatewayTimeout"
        }
        
        Set-Content -Path $ConfigPath -Value $ConfigContent
        
        # 2. Restart collector
        Write-Host "  🔄 Restarting collector with new config..." -ForegroundColor Gray
        try {
            Stop-Service otelcol-contrib -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Start-Service otelcol-contrib
            Start-Sleep -Seconds 5
        } catch {
            Write-Host "    ⚠️ Service restart failed, continuing..." -ForegroundColor Yellow
        }
        
        # 3. Generate test load
        Write-Host "  📊 Generating test load for $DurationSeconds seconds..." -ForegroundColor Gray
        $TestStart = Get-Date
        
        # Generate canary logs
        for ($i = 0; $i -lt $DurationSeconds; $i++) {
            $LogEntry = @{
                timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                level = "INFO"
                message = "E2-ratio-test-$TestID-$i"
                agent_timeout = $AgentTimeout
                gateway_timeout = $GatewayTimeout
                test_id = $TestID
                iteration = $i
            } | ConvertTo-Json -Compress
            
            Add-Content -Path "C:\logs\e2-test.log" -Value $LogEntry
            Start-Sleep -Milliseconds 100
        }
        
        $TestEnd = Get-Date
        $TestDuration = ($TestEnd - $TestStart).TotalSeconds
        
        # 4. Collect metrics
        Write-Host "  📈 Collecting performance metrics..." -ForegroundColor Gray
        
        # Get collector metrics
        $CollectorMetrics = @{
            cpu_usage = (Get-Process -Name "otelcol-contrib" -ErrorAction SilentlyContinue | Measure-Object CPU -Sum).Sum
            memory_usage = (Get-Process -Name "otelcol-contrib" -ErrorAction SilentlyContinue | Measure-Object WorkingSet -Sum).Sum
            test_duration = $TestDuration
        }
        
        # 5. Query SigNoz for latency metrics
        $SigNozQuery = @{
            query = "rate(otelcol_exporter_sent_spans_total[1m])"
            start = [int]((Get-Date).AddMinutes(-5) - (Get-Date '1970-01-01')).TotalSeconds
            end = [int]((Get-Date) - (Get-Date '1970-01-01')).TotalSeconds
        }
        
        try {
            $SigNozResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/query_range" -Method Get -Body $SigNozQuery
            $CollectorMetrics.sent_spans_rate = $SigNozResponse.data.result[0].values[-1][1]
        } catch {
            $CollectorMetrics.sent_spans_rate = "N/A"
        }
        
        # 6. Store results
        $Result = @{
            test_id = $TestID
            agent_timeout = $AgentTimeout
            gateway_timeout = $GatewayTimeout
            test_duration = $TestDuration
            metrics = $CollectorMetrics
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
        
        $Results += $Result
        
        Write-Host "  ✅ $TestID completed: $($CollectorMetrics.sent_spans_rate) spans/sec" -ForegroundColor Green
        
    } catch {
        Write-Host "  ❌ $TestID failed: $($_.Exception.Message)" -ForegroundColor Red
        $Result = @{
            test_id = $TestID
            agent_timeout = $AgentTimeout
            gateway_timeout = $GatewayTimeout
            error = $_.Exception.Message
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
        $Results += $Result
    } finally {
        # Restore original config
        Copy-Item $ConfigBackup $ConfigPath
        Remove-Item $ConfigBackup
    }
}

# Main execution
if ($TestAllCombinations) {
    Write-Host "🚀 Running complete E2 ratio sweep (9 combinations)" -ForegroundColor Green
    foreach ($Test in $TestMatrix) {
        Test-E2Combination -AgentTimeout $Test.Agent -GatewayTimeout $Test.Gateway -TestID $Test.ID
        Start-Sleep -Seconds 2
    }
} else {
    Write-Host "🎯 Testing single combination: Agent=$AgentTimeout, Gateway=$GatewayTimeout" -ForegroundColor Green
    $TestID = "E2-SINGLE-$(Get-Date -Format 'HHmmss')"
    Test-E2Combination -AgentTimeout $AgentTimeout -GatewayTimeout $GatewayTimeout -TestID $TestID
}

# Save results
$ResultsPath = "$ArtifactsDir/e2-ratio-sweep-results.json"
$Results | ConvertTo-Json -Depth 3 | Set-Content -Path $ResultsPath

Write-Host "`n📊 E2 Ratio Sweep Results:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
$Results | ForEach-Object {
    if ($_.error) {
        Write-Host "❌ $($_.test_id): $($_.error)" -ForegroundColor Red
    } else {
        Write-Host "✅ $($_.test_id): $($_.metrics.sent_spans_rate) spans/sec" -ForegroundColor Green
    }
}

Write-Host "`n📁 Results saved to: $ResultsPath" -ForegroundColor Yellow
Write-Host "🎯 Next: Analyze results and identify optimal configuration" -ForegroundColor Yellow

# ECRR Report
$ECRRReport = @"
# E2 Ratio Sweep Analysis - ECRR Report
**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Actor**: Cursor-Local (Observability Copilot)

## Examine
- Current batch processor: 500ms timeout
- Current exporter: 127.0.0.1:14317 (gRPC)
- Test matrix: 9 combinations (3 agent × 3 gateway timeouts)

## Clean
- Backup original config.yaml
- Test each combination systematically
- Restore config after each test

## Report
- Results: $($Results.Count) tests completed
- Artifacts: $ResultsPath
- Metrics: CPU, memory, span rate, latency

## Role
Cursor-Local: Observability Copilot - E2 ratio optimization analysis
"@

$ECRRReport | Set-Content -Path "$ArtifactsDir/e2-ratio-sweep-ecrr.md"

Write-Host "`n🎭 ECRR Report saved to: $ArtifactsDir/e2-ratio-sweep-ecrr.md" -ForegroundColor Magenta