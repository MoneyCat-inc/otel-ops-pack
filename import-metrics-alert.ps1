# import-metrics-alert.ps1 - Import metrics-based health canary alert into SigNoz
# Usage: .\import-metrics-alert.ps1

Write-Host "📊 Importing Metrics-Based Health Canary Alert into SigNoz" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

$alertFile = "signoz-metrics-canary-alert.json"
$signozApiUrl = "http://localhost:8080/api/v1/alerts"

if (-not (Test-Path $alertFile)) {
    Write-Host "❌ Alert file not found: $alertFile" -ForegroundColor Red
    exit 1
}

try {
    # Read the alert configuration
    $alertConfig = Get-Content -Path $alertFile -Raw | ConvertFrom-Json
    
    Write-Host "📋 Alert Configuration:" -ForegroundColor Yellow
    Write-Host "  Name: $($alertConfig.alert.name)" -ForegroundColor White
    Write-Host "  Severity: $($alertConfig.alert.severity)" -ForegroundColor White
    Write-Host "  Query: $($alertConfig.alert.query.metricsQuery.query)" -ForegroundColor White
    Write-Host "  Threshold: $($alertConfig.alert.condition.threshold) metrics in 5 minutes" -ForegroundColor White
    
    # Check if SigNoz is accessible
    Write-Host "`n🌐 Checking SigNoz connectivity..." -ForegroundColor Yellow
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  ✅ SigNoz UI reachable (Status: $($response.StatusCode))" -ForegroundColor Green
    
    # Note: In a real implementation, you would POST to the SigNoz API
    # For now, we'll provide the manual import instructions
    Write-Host "`n📝 Manual Import Instructions:" -ForegroundColor Yellow
    Write-Host "1. Open SigNoz UI: http://localhost:8080" -ForegroundColor White
    Write-Host "2. Navigate to: Alerts → Create Alert" -ForegroundColor White
    Write-Host "3. Select: Metrics Based Alert (not Logs Based)" -ForegroundColor White
    Write-Host "4. Use the configuration from: $alertFile" -ForegroundColor White
    Write-Host "5. Query: $($alertConfig.alert.query.metricsQuery.query)" -ForegroundColor White
    Write-Host "6. Condition: Below $($alertConfig.alert.condition.threshold) for 5 minutes" -ForegroundColor White
    
    Write-Host "`n✅ Metrics-based alert configuration ready for import!" -ForegroundColor Green
    Write-Host "   This alert will trigger if no health metrics are received in 5 minutes" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Make sure SigNoz is running on http://localhost:8080" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n🔗 Next Steps:" -ForegroundColor Cyan
Write-Host "  • Import metrics alert in SigNoz UI using the instructions above" -ForegroundColor White
Write-Host "  • Monitor Task Scheduler for OTelHealthCanary status" -ForegroundColor White
Write-Host "  • Check SigNoz Logs with: service.name = 'windows-collector' AND canary_id contains 'health-check'" -ForegroundColor White
Write-Host "  • Once logs database initializes, switch to logs-based alert" -ForegroundColor White
