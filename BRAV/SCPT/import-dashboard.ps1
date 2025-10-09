# SigNoz Dashboard Import Script
# Imports the OTel Queue Pressure Dashboard to SigNoz

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$DashboardFile = "artifacts/signoz-queue-pressure-dashboard.json",
    [string]$ApiToken = $env:SIGNOZ_API_TOKEN,
    [switch]$SkipBrowser = $false
)

# ECRR: Examine → Clean → Report → Role
Write-Host "SigNoz Dashboard Import - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check prerequisites
Write-Host "`nExamine: Checking dashboard import prerequisites..." -ForegroundColor Green

$ImportStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    signoz_url = $SigNozUrl
    dashboard_file = $DashboardFile
    api_token_set = $false
    dashboard_file_exists = $false
    signoz_accessible = $false
    import_successful = $false
    recommendations = @()
}

# Check if API token is set
Write-Host "Checking API token..." -ForegroundColor Yellow
if ($ApiToken) {
    Write-Host "  ✅ API token is set" -ForegroundColor Green
    $ImportStatus.api_token_set = $true
} else {
    Write-Host "  ❌ API token not set" -ForegroundColor Red
    $ImportStatus.recommendations += "Set SIGNOZ_API_TOKEN environment variable"
}

# Check if dashboard file exists
Write-Host "Checking dashboard file..." -ForegroundColor Yellow
if (Test-Path $DashboardFile) {
    Write-Host "  ✅ Dashboard file exists: $DashboardFile" -ForegroundColor Green
    $ImportStatus.dashboard_file_exists = $true
} else {
    Write-Host "  ❌ Dashboard file not found: $DashboardFile" -ForegroundColor Red
    $ImportStatus.recommendations += "Create dashboard configuration file"
}

# Check if SigNoz is accessible
Write-Host "Checking SigNoz accessibility..." -ForegroundColor Yellow
try {
    $SigNozResponse = Invoke-WebRequest -Uri $SigNozUrl -TimeoutSec 5
    if ($SigNozResponse.StatusCode -eq 200) {
        Write-Host "  ✅ SigNoz UI accessible at $SigNozUrl" -ForegroundColor Green
        $ImportStatus.signoz_accessible = $true
    }
} catch {
    Write-Host "  ❌ SigNoz UI not accessible at $SigNozUrl" -ForegroundColor Red
    $ImportStatus.recommendations += "Start SigNoz stack (docker-compose up -d)"
}

# Clean: Import dashboard if prerequisites are met
if ($ImportStatus.api_token_set -and $ImportStatus.dashboard_file_exists -and $ImportStatus.signoz_accessible) {
    Write-Host "`nClean: Importing dashboard to SigNoz..." -ForegroundColor Green
    
    try {
        # Read dashboard configuration
        $DashboardConfig = Get-Content $DashboardFile -Raw | ConvertFrom-Json
        
        # Prepare headers for API request
        $Headers = @{
            "Authorization" = "Bearer $ApiToken"
            "Content-Type" = "application/json"
        }
        
        # Import dashboard via API
        Write-Host "Importing dashboard via API..." -ForegroundColor Yellow
        $ImportResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/dashboards/db" -Method POST -Headers $Headers -Body ($DashboardConfig | ConvertTo-Json -Depth 10) -TimeoutSec 30
        
        if ($ImportResponse) {
            Write-Host "  ✅ Dashboard imported successfully" -ForegroundColor Green
            $ImportStatus.import_successful = $true
            
            # Get dashboard URL
            $DashboardUrl = "$SigNozUrl/d/$($ImportResponse.uid)/otel-queue-pressure"
            Write-Host "  Dashboard URL: $DashboardUrl" -ForegroundColor Cyan
            
            # Open dashboard in browser
            if (-not $SkipBrowser) {
                Write-Host "Opening dashboard in browser..." -ForegroundColor Yellow
                Start-Process $DashboardUrl
            }
        }
    } catch {
        Write-Host "  ❌ Dashboard import failed" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $ImportStatus.recommendations += "Check dashboard configuration and API permissions"
        
        # Try manual import guidance
        Write-Host "`n=== MANUAL IMPORT GUIDANCE ===" -ForegroundColor Cyan
        Write-Host "If API import fails, import manually:" -ForegroundColor White
        Write-Host "1. Open SigNoz UI: $SigNozUrl" -ForegroundColor White
        Write-Host "2. Navigate to Dashboards → Import Dashboard" -ForegroundColor White
        Write-Host "3. Upload file: $DashboardFile" -ForegroundColor White
        Write-Host "4. Verify dashboard name: OTel Queue Pressure Monitor" -ForegroundColor White
        Write-Host "5. Check panels are displaying data" -ForegroundColor White
    }
} else {
    Write-Host "`nClean: Prerequisites not met for dashboard import" -ForegroundColor Yellow
    
    if (-not $ImportStatus.api_token_set) {
        Write-Host "`n=== API TOKEN SETUP ===" -ForegroundColor Cyan
        Write-Host "Run authentication setup first:" -ForegroundColor White
        Write-Host "pwsh -File scripts/setup-signoz-authentication.ps1" -ForegroundColor Yellow
    }
    
    if (-not $ImportStatus.dashboard_file_exists) {
        Write-Host "`n=== DASHBOARD FILE CREATION ===" -ForegroundColor Cyan
        Write-Host "Dashboard file not found. Creating basic dashboard..." -ForegroundColor White
        
        # Create basic dashboard configuration
        $BasicDashboard = @{
            dashboard = @{
                id = $null
                uid = "otel-queue-pressure"
                title = "OTel Queue Pressure Monitor"
                description = "Monitor OpenTelemetry collector queue utilization"
                tags = @("otel", "queue", "pressure")
                timezone = "browser"
                refresh = "30s"
                time = @{
                    from = "now-1h"
                    to = "now"
                }
                panels = @(
                    @{
                        id = 1
                        title = "Queue Utilization Ratio"
                        type = "stat"
                        targets = @(
                            @{
                                expr = "otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100"
                                legendFormat = "Queue Utilization %"
                            }
                        )
                        fieldConfig = @{
                            defaults = @{
                                unit = "percent"
                                thresholds = @{
                                    steps = @(
                                        @{ color = "green"; value = $null }
                                        @{ color = "yellow"; value = 70 }
                                        @{ color = "red"; value = 90 }
                                    )
                                }
                            }
                        }
                        gridPos = @{
                            h = 8
                            w = 12
                            x = 0
                            y = 0
                        }
                    }
                )
            }
        }
        
        $BasicDashboard | ConvertTo-Json -Depth 10 | Out-File $DashboardFile -Encoding UTF8
        Write-Host "  ✅ Basic dashboard file created: $DashboardFile" -ForegroundColor Green
        $ImportStatus.dashboard_file_exists = $true
    }
}

# Report: Generate import status report
Write-Host "`nReport: Dashboard import status summary" -ForegroundColor Green

Write-Host "`nImport Status:" -ForegroundColor Cyan
Write-Host "  API Token: $(if ($ImportStatus.api_token_set) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($ImportStatus.api_token_set) { 'Green' } else { 'Red' })
Write-Host "  Dashboard File: $(if ($ImportStatus.dashboard_file_exists) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($ImportStatus.dashboard_file_exists) { 'Green' } else { 'Red' })
Write-Host "  SigNoz Access: $(if ($ImportStatus.signoz_accessible) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($ImportStatus.signoz_accessible) { 'Green' } else { 'Red' })
Write-Host "  Import Success: $(if ($ImportStatus.import_successful) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($ImportStatus.import_successful) { 'Green' } else { 'Red' })

if ($ImportStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $ImportStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save import status report
$ImportStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/dashboard-import-status.json" -Encoding UTF8

Write-Host "`nReport saved to: artifacts/dashboard-import-status.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

if ($ImportStatus.import_successful) {
    Write-Host "Next: Dashboard imported successfully - configure webhook notifications" -ForegroundColor Green
    Write-Host "Then: Test end-to-end pipeline with dashboard monitoring" -ForegroundColor Green
} else {
    Write-Host "Next: Complete dashboard import manually or fix prerequisites" -ForegroundColor Yellow
    Write-Host "Then: Re-run this script to verify import" -ForegroundColor Yellow
}

# Dashboard verification guidance
if ($ImportStatus.import_successful) {
    Write-Host "`n=== DASHBOARD VERIFICATION ===" -ForegroundColor Cyan
    Write-Host "1. Check dashboard displays data correctly" -ForegroundColor White
    Write-Host "2. Verify queue utilization shows current metrics" -ForegroundColor White
    Write-Host "3. Test panel interactions and time ranges" -ForegroundColor White
    Write-Host "4. Configure alert thresholds if needed" -ForegroundColor White
}