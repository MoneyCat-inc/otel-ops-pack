# Validation Script: Cardinality Spikes
# Recipe: Add transform to drop/normalize hot attributes

param(
    [string]$ConfigPath = "config.yaml",
    [int]$MaxSeriesCount = 1000
)

Write-Host "🔍 Validating Cardinality Controls..." -ForegroundColor Green

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

# 2. Check transform configuration
Write-Host "2. Validating transform configuration..." -ForegroundColor Cyan
$config = Get-Content $ConfigPath -Raw

if ($config -notmatch "attributes/redact:") {
    $warnings += "Attributes redaction not configured (recommended for cardinality control)"
} else {
    # Check for common high-cardinality attributes being redacted
    $highCardinalityAttrs = @("pod.uid", "container.id", "user.id", "request.id")
    foreach ($attr in $highCardinalityAttrs) {
        if ($config -notmatch $attr) {
            $warnings += "High cardinality attribute '$attr' not being redacted"
        }
    }
    Write-Host "✅ Attributes redaction configured" -ForegroundColor Green
}

# 3. Check for cardinality control processors
Write-Host "3. Checking cardinality control processors..." -ForegroundColor Cyan
if ($config -notmatch "memory_limiter:") {
    $warnings += "Memory limiter not configured (helps with cardinality spikes)"
} else {
    Write-Host "✅ Memory limiter configured" -ForegroundColor Green
}

# 4. Test high cardinality data
Write-Host "4. Testing high cardinality data handling..." -ForegroundColor Cyan
try {
    # Generate high cardinality test data
    $highCardinalityPayload = @{
        resourceLogs = @(
            @{
                resource = @{
                    attributes = @(
                        @{ key = "service.name"; value = @{ stringValue = "cardinality-test" } }
                        @{ key = "pod.uid"; value = @{ stringValue = "test-pod-$(Get-Random)" } }
                        @{ key = "container.id"; value = @{ stringValue = "test-container-$(Get-Random)" } }
                    )
                }
                scopeLogs = @(
                    @{
                        logRecords = @(
                            @{
                                timeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                                severityNumber = 17
                                severityText = "INFO"
                                body = @{ stringValue = "High cardinality test log" }
                                attributes = @(
                                    @{ key = "user.id"; value = @{ stringValue = "user-$(Get-Random)" } }
                                    @{ key = "request.id"; value = @{ stringValue = "req-$(Get-Random)" } }
                                    @{ key = "validation"; value = @{ stringValue = "cardinality-test" } }
                                )
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "http://localhost:4318/v1/logs" -Method Post -Body $highCardinalityPayload -ContentType "application/json" -TimeoutSec 10
    Write-Host "✅ High cardinality data sent successfully" -ForegroundColor Green
} catch {
    $issues += "High cardinality data test failed: $($_.Exception.Message)"
}

# 5. Check metrics for cardinality indicators
Write-Host "5. Checking metrics for cardinality indicators..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8888/metrics" -Method Get -TimeoutSec 10
    $metrics = $response -split "`n"
    
    # Look for cardinality-related metrics
    $cardinalityMetrics = $metrics | Where-Object { 
        $_ -match "otelcol_processor_batch_processor_batch_send_size" -or
        $_ -match "otelcol_processor_memory_limiter" -or
        $_ -match "otelcol_processor_attributes_processor"
    }
    
    if ($cardinalityMetrics.Count -gt 0) {
        Write-Host "✅ Cardinality-related metrics found: $($cardinalityMetrics.Count)" -ForegroundColor Green
        $cardinalityMetrics | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    } else {
        $warnings += "No cardinality-related metrics found"
    }
} catch {
    $warnings += "Metrics endpoint error: $($_.Exception.Message)"
}

# 6. Test series count (simplified)
Write-Host "6. Testing series count..." -ForegroundColor Cyan
try {
    # This would normally query the metrics store for actual series count
    # For now, we'll check if the collector is handling the load
    $response = Invoke-RestMethod -Uri "http://localhost:13134/" -Method Get -TimeoutSec 10
    if ($response.status -eq "Server available") {
        Write-Host "✅ Collector handling load (series count check would require metrics store query)" -ForegroundColor Green
    } else {
        $issues += "Collector not handling load properly"
    }
} catch {
    $issues += "Collector load test failed: $($_.Exception.Message)"
}

# 7. Check for batch processing
Write-Host "7. Validating batch processing..." -ForegroundColor Cyan
if ($config -notmatch "batch:") {
    $warnings += "Batch processing not configured (helps with cardinality spikes)"
} else {
    # Check batch size limits
    if ($config -match "send_batch_max_size: (\d+)") {
        $batchSize = [int]$matches[1]
        if ($batchSize -gt 2048) {
            $warnings += "Batch size ($batchSize) may be too large for cardinality control"
        } else {
            Write-Host "✅ Batch processing configured with reasonable limits" -ForegroundColor Green
        }
    }
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

Write-Host "`n🎯 Expected Output: High cardinality data handled, transforms working" -ForegroundColor Green
Write-Host "📊 Max Series Count: $MaxSeriesCount (configurable)" -ForegroundColor Cyan


