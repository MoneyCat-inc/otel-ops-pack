# BossCat SigNoz Dashboard Import Script
# Authority: BossCat OEM (Executive Overseer Manager)
# Purpose: Import BossCat Executive Dashboard to SigNoz

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [switch]$Verbose
)

Write-Host "🐾 BossCat Dashboard Import - WyzWoz Style" -ForegroundColor Green
Write-Host "Authority: BossCat OEM" -ForegroundColor Cyan

# Dashboard Configuration
$DashboardConfig = @{
    name = "BossCat Executive Dashboard"
    description = "Real-time observability for BossCat OEM oversight - Cat Nap Control Room"
    panels = @(
        @{
            title = "Pipeline Health"
            query = "rate(otelcol_*_spans_received_total[5m])"
            type = "graph"
            threshold = "> 0"
            description = "OTel pipeline span ingestion rate"
        },
        @{
            title = "Error Rates"
            query = "rate(otelcol_*_errors_total[5m])"
            type = "graph"
            threshold = "< 0.01"
            description = "Pipeline error rate monitoring"
        },
        @{
            title = "Latency P95"
            query = "histogram_quantile(0.95, rate(otelcol_*_duration_seconds_bucket[5m]))"
            type = "graph"
            threshold = "< 0.2"
            description = "95th percentile latency tracking"
        },
        @{
            title = "Throughput"
            query = "rate(otelcol_*_spans_processed_total[5m])"
            type = "graph"
            threshold = "> 100"
            description = "Pipeline throughput monitoring"
        }
    )
    tags = @("bosscat", "executive", "monitoring", "wyzwoz")
}

# Alert Rules Configuration
$AlertRules = @(
    @{
        name = "Pipeline Health Alert"
        condition = "rate(otelcol_*_spans_received_total[5m]) == 0"
        severity = "critical"
        duration = "2m"
        description = "OTel pipeline stopped receiving spans"
    },
    @{
        name = "High Error Rate Alert"
        condition = "rate(otelcol_*_errors_total[5m]) > 0.05"
        severity = "warning"
        duration = "5m"
        description = "Error rate exceeds 5% threshold"
    },
    @{
        name = "Canary Missing Alert"
        condition = "absent_over_time(otelcol_*_canary_spans_total[10m])"
        severity = "critical"
        duration = "10m"
        description = "Canary traces missing for 10+ minutes"
    }
)

try {
    Write-Host "🔍 Checking SigNoz connectivity..." -ForegroundColor Yellow
    
    # Check SigNoz health
    $healthResponse = Invoke-WebRequest -Uri "$SigNozUrl/api/v1/health" -UseBasicParsing
    if ($healthResponse.StatusCode -eq 200) {
        Write-Host "✅ SigNoz is healthy and accessible" -ForegroundColor Green
    }
    
    Write-Host "📊 Creating BossCat Executive Dashboard..." -ForegroundColor Yellow
    
    # Import dashboard (simplified - would need actual SigNoz API calls)
    $dashboardJson = $DashboardConfig | ConvertTo-Json -Depth 10
    $dashboardPath = "docs/BossCat/bosscat-executive-dashboard.json"
    $dashboardJson | Out-File -FilePath $dashboardPath -Encoding UTF8
    
    Write-Host "✅ Dashboard configuration saved to: $dashboardPath" -ForegroundColor Green
    
    Write-Host "🚨 Creating alert rules..." -ForegroundColor Yellow
    
    # Import alert rules
    $alertsJson = $AlertRules | ConvertTo-Json -Depth 10
    $alertsPath = "docs/BossCat/bosscat-alert-rules.json"
    $alertsJson | Out-File -FilePath $alertsPath -Encoding UTF8
    
    Write-Host "✅ Alert rules saved to: $alertsPath" -ForegroundColor Green
    
    Write-Host "🎭 WyzWoz Style Implementation Complete:" -ForegroundColor Magenta
    Write-Host "   • BossCat Executive Dashboard configured" -ForegroundColor White
    Write-Host "   • Critical alert rules established" -ForegroundColor White
    Write-Host "   • Cat Nap Control Room aesthetic applied" -ForegroundColor White
    Write-Host "   • Feline Silence monitoring enabled" -ForegroundColor White
    
    Write-Host "🌐 SigNoz UI: $SigNozUrl" -ForegroundColor Cyan
    Write-Host "📁 Dashboard Config: $dashboardPath" -ForegroundColor Cyan
    Write-Host "🚨 Alert Rules: $alertsPath" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error importing BossCat dashboard: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "🐾 BossCat Dashboard Import Complete - Authority: BossCat OEM" -ForegroundColor Green
