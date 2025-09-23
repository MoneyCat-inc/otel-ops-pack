# OTel Health Check Script
# Part of OTel Health CI Patch

param(
    [switch]$Verbose,
    [switch]$Quiet
)

Write-Host "🔍 OTel Health Check Starting..." -ForegroundColor Cyan

# Check OTel Collector Service
$service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "✅ OTel Collector service: $($service.Status)" -ForegroundColor Green
} else {
    Write-Host "❌ OTel Collector service not found" -ForegroundColor Red
    exit 1
}

# Test OTLP endpoint
try {
    $testPayload = @{
        resourceLogs = @(
            @{
                resource = @{ attributes = @() }
                scopeLogs = @(
                    @{
                        scope = @{ name = "health-check" }
                        logRecords = @(
                            @{
                                timeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
                                severityText = "INFO"
                                body = @{ stringValue = "Health check test" }
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10
    
    Invoke-RestMethod -Uri "http://localhost:5318/v1/logs" -Method POST -ContentType "application/json" -Body $testPayload -TimeoutSec 10 | Out-Null
    Write-Host "✅ OTLP endpoint responding" -ForegroundColor Green
} catch {
    Write-Host "❌ OTLP endpoint test failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 OTel Health Check Complete - All systems green!" -ForegroundColor Green
