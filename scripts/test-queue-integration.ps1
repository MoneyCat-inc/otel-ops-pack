param(
    [string]$SigNozUrl = "http://localhost:8080"
)

function Test-QueueIntegration {
    param([string]$Url)
    
    Write-Host "=== Queue Telemetry Integration Test ==="
    Write-Host "SigNoz URL: $Url"
    Write-Host ""
    
    # Test 1: Check if SigNoz is accessible
    Write-Host "1. Testing SigNoz connectivity..."
    try {
        $healthResponse = Invoke-WebRequest -Uri "$Url/api/v1/health" -UseBasicParsing -TimeoutSec 10
        if ($healthResponse.StatusCode -eq 200) {
            Write-Host "   ✅ SigNoz is accessible"
        } else {
            Write-Host "   ⚠️ SigNoz returned status: $($healthResponse.StatusCode)"
        }
    } catch {
        Write-Host "   ❌ SigNoz not accessible: $($_.Exception.Message)"
        return $false
    }
    
    # Test 2: Generate fresh telemetry
    Write-Host ""
    Write-Host "2. Generating fresh queue telemetry..."
    try {
        & pwsh -File "scripts\observability\emit-queue-telemetry.ps1" -RepoRoot . -OutputPath "C:\logs\queue\health.log"
        Write-Host "   ✅ Telemetry generated successfully"
    } catch {
        Write-Host "   ❌ Failed to generate telemetry: $($_.Exception.Message)"
        return $false
    }
    
    # Test 3: Verify log file exists and has recent data
    Write-Host ""
    Write-Host "3. Verifying log file..."
    $logFile = "C:\logs\queue\health.log"
    if (Test-Path $logFile) {
        $lastEntry = Get-Content $logFile | Select-Object -Last 1
        if ($lastEntry -match '"dataset":"agent_queue"') {
            Write-Host "   ✅ Log file contains queue telemetry"
            Write-Host "   📊 Latest entry: queueLength=$(($lastEntry | ConvertFrom-Json).queueLength)"
        } else {
            Write-Host "   ❌ Log file missing queue telemetry"
            return $false
        }
    } else {
        Write-Host "   ❌ Log file not found: $logFile"
        return $false
    }
    
    # Test 4: Check if collector is running (if possible)
    Write-Host ""
    Write-Host "4. Checking collector status..."
    try {
        $service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
        if ($service) {
            Write-Host "   📋 Collector service status: $($service.Status)"
            if ($service.Status -eq "Running") {
                Write-Host "   ✅ Collector is running"
            } else {
                Write-Host "   ⚠️ Collector is not running - logs may not be forwarded to SigNoz"
            }
        } else {
            Write-Host "   ⚠️ Collector service not found"
        }
    } catch {
        Write-Host "   ⚠️ Could not check collector status"
    }
    
    # Test 5: Provide verification instructions
    Write-Host ""
    Write-Host "5. SigNoz Verification Instructions:"
    Write-Host "   📋 Manual verification steps:"
    Write-Host "   a) Open SigNoz UI: $Url"
    Write-Host "   b) Go to Logs → Explorer"
    Write-Host "   c) Add filter: log.file.path contains 'C:/logs/queue/health.log'"
    Write-Host "   d) Add filter: message contains '\"dataset\":\"agent_queue\"'"
    Write-Host "   e) Look for recent entries with queueLength=14"
    Write-Host ""
    Write-Host "   📊 Test queries to run in SigNoz:"
    Write-Host "   - Count queue telemetry entries:"
    Write-Host "     SELECT count(*) FROM signoz_logs.logs_v2 WHERE JSONExtractString(body, 'dataset') = 'agent_queue' AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 1 HOUR;"
    Write-Host ""
    Write-Host "   - Current queue depth:"
    Write-Host "     SELECT avg(JSONExtractInt(body, 'queueLength')) AS queue_depth FROM signoz_logs.logs_v2 WHERE JSONExtractString(body, 'dataset') = 'agent_queue' AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 5 MINUTE;"
    Write-Host ""
    
    return $true
}

# Main execution
$success = Test-QueueIntegration -Url $SigNozUrl

Write-Host "=== Integration Test Summary ==="
if ($success) {
    Write-Host "✅ Queue telemetry integration setup complete"
    Write-Host "📋 Next steps:"
    Write-Host "   1. Verify data appears in SigNoz UI (see instructions above)"
    Write-Host "   2. Import the Queue Steward dashboard"
    Write-Host "   3. Set up alerts for queue health monitoring"
} else {
    Write-Host "❌ Integration test failed - check errors above"
}
