# Validation Script: OTLP Exporter Failures
# Recipe: Increase batch size, enable queued_retry, add self-metrics

param(
    [string]$ConfigPath = "config.yaml",
    [string]$BackupPath = "config.backup.yaml"
)

Write-Host "🔍 Validating OTLP Exporter Configuration..." -ForegroundColor Green

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

# 2. Check collector health
Write-Host "2. Checking collector health..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:13134/" -Method Get -TimeoutSec 10
    if ($response.status -ne "Server available") {
        $issues += "Collector health check failed: $($response.status)"
    } else {
        Write-Host "✅ Collector health check passed" -ForegroundColor Green
    }
} catch {
    $issues += "Collector health check error: $($_.Exception.Message)"
}

# 3. Check batch configuration
Write-Host "3. Validating batch configuration..." -ForegroundColor Cyan
$config = Get-Content $ConfigPath -Raw
if ($config -notmatch "batch:") {
    $issues += "Batch processor not configured"
} else {
    if ($config -notmatch "send_batch_size:") {
        $warnings += "Batch size not explicitly set"
    }
    if ($config -notmatch "timeout:") {
        $warnings += "Batch timeout not explicitly set"
    }
    Write-Host "✅ Batch processor configured" -ForegroundColor Green
}

# 4. Check queued_retry configuration
Write-Host "4. Validating queued_retry configuration..." -ForegroundColor Cyan
if ($config -notmatch "queued_retry:") {
    $warnings += "Queued retry not configured (recommended for reliability)"
} else {
    Write-Host "✅ Queued retry configured" -ForegroundColor Green
}

# 5. Check memory limiter
Write-Host "5. Validating memory limiter..." -ForegroundColor Cyan
if ($config -notmatch "memory_limiter:") {
    $warnings += "Memory limiter not configured"
} else {
    Write-Host "✅ Memory limiter configured" -ForegroundColor Green
}

# 6. Test OTLP endpoint
Write-Host "6. Testing OTLP endpoint..." -ForegroundColor Cyan
try {
    $testPayload = @{
        resourceLogs = @(
            @{
                resource = @{ attributes = @() }
                scopeLogs = @(
                    @{
                        logRecords = @(
                            @{
                                timeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                                severityNumber = 17
                                severityText = "INFO"
                                body = @{ stringValue = "Validation test log" }
                                attributes = @()
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "http://localhost:4318/v1/logs" -Method Post -Body $testPayload -ContentType "application/json" -TimeoutSec 10
    Write-Host "✅ OTLP endpoint test passed" -ForegroundColor Green
} catch {
    $issues += "OTLP endpoint test failed: $($_.Exception.Message)"
}

# 7. Check metrics endpoint
Write-Host "7. Checking metrics endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8888/metrics" -Method Get -TimeoutSec 10
    $otelLines = $response -split "`n" | Where-Object { $_ -match "otelcol_" }
    if ($otelLines.Count -lt 5) {
        $warnings += "Limited collector metrics available: $($otelLines.Count)"
    } else {
        Write-Host "✅ Metrics endpoint healthy ($($otelLines.Count) metrics)" -ForegroundColor Green
    }
} catch {
    $issues += "Metrics endpoint error: $($_.Exception.Message)"
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

Write-Host "`n🎯 Expected Output: Collector healthy, OTLP working, batch configured" -ForegroundColor Green


