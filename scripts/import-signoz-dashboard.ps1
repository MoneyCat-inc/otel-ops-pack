# SigNoz Dashboard Import Helper
# This script helps import the ECRR dashboard into SigNoz

param(
    [string]$SignozUrl = "http://localhost:8080",
    [string]$DashboardFile = "artifacts/signoz-ecrr-dashboard.json",
    [string]$ApiKey = "",
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

Write-Host "SigNoz ECRR Dashboard Import" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Check if dashboard file exists
if (-not (Test-Path $DashboardFile)) {
    Write-Host "❌ Dashboard file not found: $DashboardFile" -ForegroundColor Red
    Write-Host "Run: pwsh -File scripts/visualize-ecrr-trends.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Check SigNoz connectivity
Write-Host "`n🔍 Checking SigNoz connectivity..." -ForegroundColor Yellow
try {
    $HealthResponse = Invoke-RestMethod -Uri "$SignozUrl/api/v1/health" -Method Get -TimeoutSec 10
    Write-Host "✅ SigNoz is accessible at: $SignozUrl" -ForegroundColor Green
} catch {
    Write-Host "❌ Cannot connect to SigNoz at: $SignozUrl" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPlease ensure SigNoz is running:" -ForegroundColor Yellow
    Write-Host "1. Check Docker: docker ps | findstr signoz" -ForegroundColor White
    Write-Host "2. Check logs: docker logs signoz-otel-collector" -ForegroundColor White
    Write-Host "3. Verify URL: http://localhost:8080" -ForegroundColor White
    exit 1
}

# Load dashboard configuration
Write-Host "`n📊 Loading dashboard configuration..." -ForegroundColor Yellow
$DashboardConfig = Get-Content $DashboardFile | ConvertFrom-Json
Write-Host "✅ Dashboard loaded: $($DashboardConfig.name)" -ForegroundColor Green
Write-Host "   Panels: $($DashboardConfig.panels.Count)" -ForegroundColor White
Write-Host "   Description: $($DashboardConfig.description)" -ForegroundColor White

if ($DryRun) {
    Write-Host "`n🔍 Dry Run - Dashboard Preview:" -ForegroundColor Cyan
    Write-Host "Name: $($DashboardConfig.name)" -ForegroundColor White
    Write-Host "Description: $($DashboardConfig.description)" -ForegroundColor White
    Write-Host "Panels:" -ForegroundColor White
    foreach ($Panel in $DashboardConfig.panels) {
        Write-Host "  - $($Panel.title): $($Panel.type)" -ForegroundColor Gray
    }
    Write-Host "`nTo import, run without -DryRun flag" -ForegroundColor Yellow
    exit 0
}

# Prepare API headers
$Headers = @{
    "Content-Type" = "application/json"
}
if ($ApiKey) {
    $Headers["Authorization"] = "Bearer $ApiKey"
}

# Import dashboard
Write-Host "`n📤 Importing dashboard to SigNoz..." -ForegroundColor Yellow
try {
    $ImportResponse = Invoke-RestMethod -Uri "$SignozUrl/api/v1/dashboards/import" -Method Post -Headers $Headers -Body ($DashboardConfig | ConvertTo-Json -Depth 10) -TimeoutSec 30
    Write-Host "✅ Dashboard imported successfully!" -ForegroundColor Green
    Write-Host "   Dashboard ID: $($ImportResponse.id)" -ForegroundColor White
    Write-Host "   Dashboard URL: $SignozUrl/dashboards/$($ImportResponse.id)" -ForegroundColor White
} catch {
    Write-Host "❌ Dashboard import failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $ErrorResponse = $_.Exception.Response.GetResponseStream()
        $Reader = New-Object System.IO.StreamReader($ErrorResponse)
        $ErrorBody = $Reader.ReadToEnd()
        Write-Host "Error details: $ErrorBody" -ForegroundColor Red
    }
    Write-Host "`nManual import steps:" -ForegroundColor Yellow
    Write-Host "1. Open SigNoz: $SignozUrl" -ForegroundColor White
    Write-Host "2. Go to Dashboards → + New Dashboard" -ForegroundColor White
    Write-Host "3. Click Import JSON" -ForegroundColor White
    Write-Host "4. Upload: $DashboardFile" -ForegroundColor White
    exit 1
}

# Verify dashboard
Write-Host "`n🔍 Verifying dashboard..." -ForegroundColor Yellow
try {
    $VerifyResponse = Invoke-RestMethod -Uri "$SignozUrl/api/v1/dashboards/$($ImportResponse.id)" -Method Get -Headers $Headers -TimeoutSec 10
    Write-Host "✅ Dashboard verification successful!" -ForegroundColor Green
    Write-Host "   Name: $($VerifyResponse.name)" -ForegroundColor White
    Write-Host "   Panels: $($VerifyResponse.panels.Count)" -ForegroundColor White
} catch {
    Write-Host "⚠️ Dashboard verification failed, but import may have succeeded" -ForegroundColor Yellow
}

Write-Host "`n🎉 SigNoz Dashboard Import Complete!" -ForegroundColor Cyan
Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Open dashboard: $SignozUrl/dashboards/$($ImportResponse.id)" -ForegroundColor White
Write-Host "2. Set up alert rules for compliance drops" -ForegroundColor White
Write-Host "3. Configure notification channels (email/Slack)" -ForegroundColor White
Write-Host "4. Test metrics: $SignozUrl/metrics" -ForegroundColor White
Write-Host "5. Monitor compliance trends daily" -ForegroundColor White

Write-Host "`n📊 Dashboard Features:" -ForegroundColor Cyan
Write-Host "- ECRR Compliance Trend (Four-section structure)" -ForegroundColor White
Write-Host "- ECRR Gates Compliance" -ForegroundColor White
Write-Host "- Total Reports Counter" -ForegroundColor White
Write-Host "- Real-time metrics from OTLP export" -ForegroundColor White