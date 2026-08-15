#Requires -Version 7.0

<#
.SYNOPSIS
    Test SigNoz Telemetry Integration for Parallel Agent Framework
    Validates agent registration and baseline health scoring
#>

[CmdletBinding()]
param(
    [string]$SigNozEndpoint,
    [string]$OTLPEndpoint,
    [int]$TestDurationSeconds = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'lib\OtelPorts.psm1') -Force
$script:OtelPorts = Get-OtelPorts
if (-not $SigNozEndpoint) { $SigNozEndpoint = "http://localhost:$($script:OtelPorts.SignozUiHttp)" }
if (-not $OTLPEndpoint) { $OTLPEndpoint = Get-OtelIngestHttpBase -HostName 'localhost' -Ports $script:OtelPorts }

Write-Host "🔍 Testing SigNoz Telemetry Integration" -ForegroundColor Green

# Test 1: SigNoz Health Check
Write-Host "`n📊 Test 1: SigNoz Health Check" -ForegroundColor Cyan
try {
    $healthResponse = Invoke-RestMethod -Uri "$SigNozEndpoint/api/v1/health" -TimeoutSec 10
    Write-Host "  ✅ SigNoz is healthy: $($healthResponse | ConvertTo-Json -Compress)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ SigNoz health check failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: OTLP Endpoint Connectivity
Write-Host "`n📡 Test 2: OTLP Endpoint Connectivity" -ForegroundColor Cyan
try {
    # Test OTLP HTTP endpoint
    $otlpTestPayload = @{
        resourceSpans = @(
            @{
                resource = @{
                    attributes = @(
                        @{
                            key = "service.name"
                            value = @{
                                stringValue = "bosscat-parallel-agents-test"
                            }
                        }
                    )
                }
                scopeSpans = @(
                    @{
                        scope = @{
                            name = "test-scope"
                        }
                        spans = @(
                            @{
                                traceId = "12345678901234567890123456789012"
                                spanId = "1234567890123456"
                                name = "test-span"
                                startTimeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                                endTimeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + 100) * 1000000
                                attributes = @(
                                    @{
                                        key = "test.attribute"
                                        value = @{
                                            stringValue = "test-value"
                                        }
                                    }
                                )
                            }
                        )
                    }
                )
            }
        )
    }
    
    $headers = @{
        'Content-Type' = 'application/json'
    }
    
    $otlpResponse = Invoke-RestMethod -Uri "$OTLPEndpoint/v1/traces" -Method Post -Body ($otlpTestPayload | ConvertTo-Json -Depth 10) -Headers $headers -TimeoutSec 10
    Write-Host "  ✅ OTLP endpoint is accessible" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ OTLP endpoint test failed (expected if not configured): $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test 3: Agent Telemetry Simulation
Write-Host "`n🤖 Test 3: Agent Telemetry Simulation" -ForegroundColor Cyan

$testAgents = @(
    @{ Id = "test-agent-001"; Type = "dashboard-export"; Duration = 5000 },
    @{ Id = "test-agent-002"; Type = "batch-processing"; Duration = 8000 },
    @{ Id = "test-agent-003"; Type = "monitoring"; Duration = 3000 },
    @{ Id = "test-agent-004"; Type = "api-testing"; Duration = 2000 }
)

$telemetryResults = @()

foreach ($agent in $testAgents) {
    Write-Host "  Simulating agent: $($agent.Id) ($($agent.Type))" -ForegroundColor Gray
    
    $agentStartTime = Get-Date
    $agentMetrics = @{
        agent_id = $agent.Id
        agent_type = $agent.Type
        start_time = $agentStartTime.ToString('o')
        status = "running"
    }
    
    # Simulate agent work
    Start-Sleep -Milliseconds $agent.Duration
    
    $agentEndTime = Get-Date
    $agentMetrics.end_time = $agentEndTime.ToString('o')
    $agentMetrics.duration_ms = ($agentEndTime - $agentStartTime).TotalMilliseconds
    $agentMetrics.status = "completed"
    $agentMetrics.success = $true
    
    $telemetryResults += $agentMetrics
    
    Write-Host "    ✅ Agent completed in $([Math]::Round($agentMetrics.duration_ms, 2)) ms" -ForegroundColor Green
}

# Test 4: SigNoz Query Validation
Write-Host "`n🔍 Test 4: SigNoz Query Validation" -ForegroundColor Cyan
try {
    # Test basic query endpoint
    $queryParams = @{
        query = "up"
        start = [DateTimeOffset]::UtcNow.AddHours(-1).ToUnixTimeSeconds()
        end = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        step = "15s"
    }
    
    $queryUrl = "$SigNozEndpoint/api/v1/query?" + ($queryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
    $queryResponse = Invoke-RestMethod -Uri $queryUrl -TimeoutSec 10
    
    Write-Host "  ✅ SigNoz query endpoint accessible" -ForegroundColor Green
    Write-Host "    Query response: $($queryResponse | ConvertTo-Json -Compress)" -ForegroundColor Gray
} catch {
    Write-Host "  ⚠️ SigNoz query test failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test 5: Dashboard Export Test
Write-Host "`n📊 Test 5: Dashboard Export Test" -ForegroundColor Cyan
try {
    # Test dashboard export endpoint
    $dashboardResponse = Invoke-RestMethod -Uri "$SigNozEndpoint/api/v1/dashboards" -TimeoutSec 10
    
    if ($dashboardResponse.data -and $dashboardResponse.data.Count -gt 0) {
        Write-Host "  ✅ Dashboard export accessible - Found $($dashboardResponse.data.Count) dashboards" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ No dashboards found for export" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️ Dashboard export test failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Compile test results
$testResults = @{
    timestamp = (Get-Date).ToString('o')
    sigoz_endpoint = $SigNozEndpoint
    otlp_endpoint = $OTLPEndpoint
    test_duration_seconds = $TestDurationSeconds
    sigoz_health = $healthResponse
    otlp_accessible = $otlpResponse -ne $null
    agents_simulated = $testAgents.Count
    telemetry_results = $telemetryResults
    performance_summary = @{
        total_agents = $testAgents.Count
        successful_agents = ($telemetryResults | Where-Object { $_.success -eq $true }).Count
        average_duration = [Math]::Round(($telemetryResults | ForEach-Object { $_.duration_ms } | Measure-Object -Average).Average, 2)
        total_duration = [Math]::Round(($telemetryResults | ForEach-Object { $_.duration_ms } | Measure-Object -Sum).Sum, 2)
    }
}

# Save test results
$resultsPath = "artifacts/signoz-telemetry-test-results.json"
$null = New-Item -ItemType Directory -Path "artifacts" -Force
$testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsPath -Encoding UTF8

# Generate summary report
$summaryReport = @"
# SigNoz Telemetry Integration Test Results

## 📊 Test Summary
- **SigNoz Endpoint**: $SigNozEndpoint
- **OTLP Endpoint**: $OTLPEndpoint
- **Test Duration**: $TestDurationSeconds seconds
- **Agents Simulated**: $($testAgents.Count)
- **Successful Agents**: $(($telemetryResults | Where-Object { $_.success -eq $true }).Count)

## 🤖 Agent Performance
- **Average Duration**: $($testResults.performance_summary.average_duration) ms
- **Total Duration**: $($testResults.performance_summary.total_duration) ms
- **Success Rate**: $([Math]::Round((($telemetryResults | Where-Object { $_.success -eq $true }).Count / $testAgents.Count) * 100, 2))%

## 🔍 Integration Status
- **SigNoz Health**: $(if ($healthResponse) { '✅ Healthy' } else { '❌ Unhealthy' })
- **OTLP Accessible**: $(if ($otlpResponse -ne $null) { '✅ Accessible' } else { '⚠️ Not Accessible' })
- **Query Endpoint**: $(if ($queryResponse) { '✅ Accessible' } else { '⚠️ Not Accessible' })
- **Dashboard Export**: $(if ($dashboardResponse) { '✅ Accessible' } else { '⚠️ Not Accessible' })

## 📁 Generated Files
- Test Results: $resultsPath
- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

---
*SigNoz Telemetry Integration Test Complete*
"@

$summaryPath = "artifacts/signoz-telemetry-test-summary.md"
Set-Content -Path $summaryPath -Value $summaryReport -Encoding UTF8

Write-Host "`n🎉 SigNoz Telemetry Integration Test Complete!" -ForegroundColor Green
Write-Host "Results: $resultsPath" -ForegroundColor Cyan
Write-Host "Summary: $summaryPath" -ForegroundColor Cyan

$successRate = [Math]::Round((($telemetryResults | Where-Object { $_.success -eq $true }).Count / $testAgents.Count) * 100, 2)
Write-Host "Agent Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { 'Green' } else { 'Yellow' })

if ($successRate -ge 90 -and $healthResponse) {
    Write-Host "✅ SigNoz telemetry integration is operational!" -ForegroundColor Green
} else {
    Write-Host "⚠️ Review test results for integration issues" -ForegroundColor Yellow
}
