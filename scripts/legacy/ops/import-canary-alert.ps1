# import-canary-alert.ps1 - Import health canary alert into SigNoz
# Usage: .\import-canary-alert.ps1

Write-Host "🚨 Importing Health Canary Alert into SigNoz" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

$alertFile = "signoz-health-canary-alert.json"
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
    Write-Host "  Query: $($alertConfig.alert.query.logsQuery.query)" -ForegroundColor White
    Write-Host "  Threshold: $($alertConfig.alert.condition.threshold) canaries in 5 minutes" -ForegroundColor White
    
    # Check if SigNoz is accessible
    Write-Host "`n🌐 Checking SigNoz connectivity..." -ForegroundColor Yellow
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  ✅ SigNoz UI reachable (Status: $($response.StatusCode))" -ForegroundColor Green
    
    # Note: In a real implementation, you would POST to the SigNoz API
    # For now, we'll provide the manual import instructions
    Write-Host "`n📝 Manual Import Instructions:" -ForegroundColor Yellow
    Write-Host "1. Open SigNoz UI: http://localhost:8080" -ForegroundColor White
    Write-Host "2. Navigate to: Alerts → Create Alert" -ForegroundColor White
    Write-Host "3. Use the configuration from: $alertFile" -ForegroundColor White
    Write-Host "4. Query: $($alertConfig.alert.query.logsQuery.query)" -ForegroundColor White
    Write-Host "5. Condition: Below $($alertConfig.alert.condition.threshold) for 5 minutes" -ForegroundColor White
    
    Write-Host "`n✅ Alert configuration ready for import!" -ForegroundColor Green
    Write-Host "   The alert will trigger if no health canaries are received in 5 minutes" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Make sure SigNoz is running on http://localhost:8080" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n🔗 Next Steps:" -ForegroundColor Cyan
Write-Host "  • Import alert in SigNoz UI using the instructions above" -ForegroundColor White
Write-Host "  • Monitor Task Scheduler for OTelHealthCanary status" -ForegroundColor White
Write-Host "  • Check SigNoz Logs with: service.name = 'windows-collector' AND canary_id contains 'health-check'" -ForegroundColor White
