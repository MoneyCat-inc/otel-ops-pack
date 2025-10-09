# Validation Script: Tail Sampling Configuration
# Recipe: Add/adjust tail_sampling policies for errors/slow/canary traces

param(
    [string]$ConfigPath = "config.yaml",
    [string]$TestTraceId = "validation-test-$(Get-Date -Format 'HHmmss')"
)

Write-Host "🔍 Validating Tail Sampling Configuration..." -ForegroundColor Green

$issues = @()
$warnings = @()

# 1. Check collector dry-run
Write-Host "1. Testing collector configuration..." -ForegroundColor Cyan
try {
    $dryRunOutput = & otelcol-contrib --config=$ConfigPath --dry-run 2>&1
    if ($LASTEXITCODE -ne 0) {
        $issues += "Collector dry-run failed: $dryRunOutput"
    } else {
        Write-Host "✅ Collector dry-run passed" -ForegroundColor Green
    }
} catch {
    $issues += "Collector dry-run error: $($_.Exception.Message)"
}

# 2. Check tail_sampling configuration
Write-Host "2. Validating tail_sampling configuration..." -ForegroundColor Cyan
$config = Get-Content $ConfigPath -Raw

if ($config -notmatch "tail_sampling:") {
    $issues += "Tail sampling processor not configured"
} else {
    # Check for required policies
    $requiredPolicies = @("error-rate", "latency", "canary", "always_sample")
    foreach ($policy in $requiredPolicies) {
        if ($config -notmatch $policy) {
            $warnings += "Policy '$policy' not found in tail sampling configuration"
        }
    }
    
    # Check policy types
    if ($config -notmatch "type: error_rate") {
        $warnings += "Error rate policy not configured"
    }
    if ($config -notmatch "type: latency") {
        $warnings += "Latency policy not configured"
    }
    if ($config -notmatch "type: string_attribute") {
        $warnings += "String attribute policy not configured (needed for canary)"
    }
    if ($config -notmatch "type: always_sample") {
        $warnings += "Always sample policy not configured"
    }
    
    Write-Host "✅ Tail sampling processor configured" -ForegroundColor Green
}

# 3. Test error trace sampling
Write-Host "3. Testing error trace sampling..." -ForegroundColor Cyan
try {
    $errorTracePayload = @{
        resourceSpans = @(
            @{
                resource = @{
                    attributes = @(
                        @{ key = "service.name"; value = @{ stringValue = "validation-test" } }
                    )
                }
                scopeSpans = @(
                    @{
                        spans = @(
                            @{
                                traceId = $TestTraceId
                                spanId = "1234567890123456"
                                name = "error-test-span"
                                kind = 1
                                startTimeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                                endTimeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + 100) * 1000000
                                status = @{
                                    code = 2  # ERROR
                                    message = "Test error for sampling validation"
                                }
                                attributes = @(
                                    @{ key = "error"; value = @{ boolValue = $true } }
                                    @{ key = "validation"; value = @{ stringValue = "error-sampling" } }
                                )
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "http://localhost:14318/v1/traces" -Method Post -Body $errorTracePayload -ContentType "application/json" -TimeoutSec 10
    Write-Host "✅ Error trace sent successfully" -ForegroundColor Green
} catch {
    $issues += "Error trace test failed: $($_.Exception.Message)"
}

# 4. Test canary trace sampling
Write-Host "4. Testing canary trace sampling..." -ForegroundColor Cyan
try {
    $canaryTracePayload = @{
        resourceSpans = @(
            @{
                resource = @{
                    attributes = @(
                        @{ key = "service.name"; value = @{ stringValue = "validation-test" } }
                    )
                }
                scopeSpans = @(
                    @{
                        spans = @(
                            @{
                                traceId = "$TestTraceId-canary"
                                spanId = "1234567890123457"
                                name = "canary-test-span"
                                kind = 1
                                startTimeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                                endTimeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + 50) * 1000000
                                attributes = @(
                                    @{ key = "canary"; value = @{ stringValue = "true" } }
                                    @{ key = "validation"; value = @{ stringValue = "canary-sampling" } }
                                )
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "http://localhost:14318/v1/traces" -Method Post -Body $canaryTracePayload -ContentType "application/json" -TimeoutSec 10
    Write-Host "✅ Canary trace sent successfully" -ForegroundColor Green
} catch {
    $issues += "Canary trace test failed: $($_.Exception.Message)"
}

# 5. Test high latency trace sampling
Write-Host "5. Testing high latency trace sampling..." -ForegroundColor Cyan
try {
    $latencyTracePayload = @{
        resourceSpans = @(
            @{
                resource = @{
                    attributes = @(
                        @{ key = "service.name"; value = @{ stringValue = "validation-test" } }
                    )
                }
                scopeSpans = @(
                    @{
                        spans = @(
                            @{
                                traceId = "$TestTraceId-latency"
                                spanId = "1234567890123458"
                                name = "latency-test-span"
                                kind = 1
                                startTimeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                                endTimeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + 500) * 1000000  # 500ms
                                attributes = @(
                                    @{ key = "validation"; value = @{ stringValue = "latency-sampling" } }
                                )
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "http://localhost:14318/v1/traces" -Method Post -Body $latencyTracePayload -ContentType "application/json" -TimeoutSec 10
    Write-Host "✅ High latency trace sent successfully" -ForegroundColor Green
} catch {
    $issues += "High latency trace test failed: $($_.Exception.Message)"
}

# 6. Check SigNoz connectivity
Write-Host "6. Checking SigNoz connectivity..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 10
    if ($response.status -ne "ok") {
        $warnings += "SigNoz UI unhealthy: $($response.status)"
    } else {
        Write-Host "✅ SigNoz UI healthy" -ForegroundColor Green
    }
} catch {
    $warnings += "SigNoz UI unreachable: $($_.Exception.Message)"
}

# Summary
Write-Host "`n📊 Validation Summary:" -ForegroundColor Cyan
if ($issues.Count -gt 0) {
    Write-Host "❌ Issues found:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "✅ All critical checks passed" -ForegroundColor Green
}

if ($warnings.Count -gt 0) {
    Write-Host "⚠️  Warnings:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

Write-Host "`n🎯 Expected Output: Traces sampled correctly, SigNoz reachable" -ForegroundColor Green
Write-Host "🔗 Check SigNoz UI: http://localhost:8080/traces (filter by traceId: $TestTraceId)" -ForegroundColor Cyan


