# Dashboard Import Verification - ECRR Framework
# Actor: Cursor-Local (Observability Copilot)
# Purpose: Verify dashboard import and functionality

param(
    [string]$DashboardName = "OTel Queue Pressure Monitoring",
    [switch]$CheckPanels = $true,
    [switch]$TestQueries = $true
)

Write-Host "📊 Dashboard Import Verification - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔍 Verifying Dashboard Import" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Check if API token is set
if (-not $env:SIGNOZ_API_TOKEN) {
    Write-Host "⚠️  API token not set - cannot verify dashboard via API" -ForegroundColor Yellow
    Write-Host "   Please verify manually in SigNoz UI:" -ForegroundColor White
    Write-Host "   1. Open http://localhost:8080" -ForegroundColor Gray
    Write-Host "   2. Go to Dashboards" -ForegroundColor Gray
    Write-Host "   3. Look for: $DashboardName" -ForegroundColor Gray
    Write-Host "   4. Verify all 5 panels are visible" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   Expected panels:" -ForegroundColor Cyan
    Write-Host "   - Queue Utilization Ratio" -ForegroundColor White
    Write-Host "   - Queue Size vs Capacity" -ForegroundColor White
    Write-Host "   - Send Failure Rate" -ForegroundColor White
    Write-Host "   - Batch Timeout Triggers" -ForegroundColor White
    Write-Host "   - Log Processing Rate" -ForegroundColor White
    Write-Host ""
    return
}

# Verify dashboard via API
try {
    $Headers = @{ "Authorization" = "Bearer $env:SIGNOZ_API_TOKEN" }
    
    Write-Host "🔍 Checking dashboard list..." -ForegroundColor Cyan
    $DashboardsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/dashboards" -Headers $Headers -TimeoutSec 10
    
    $Dashboard = $DashboardsResponse.data | Where-Object { $_.title -eq $DashboardName }
    
    if ($Dashboard) {
        Write-Host "✅ Dashboard found: $($Dashboard.title)" -ForegroundColor Green
        Write-Host "   ID: $($Dashboard.id)" -ForegroundColor White
        Write-Host "   UID: $($Dashboard.uid)" -ForegroundColor White
        Write-Host "   Created: $($Dashboard.created)" -ForegroundColor White
        
        if ($CheckPanels) {
            Write-Host ""
            Write-Host "📊 Checking dashboard panels..." -ForegroundColor Cyan
            
            $DashboardResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/dashboards/$($Dashboard.uid)" -Headers $Headers -TimeoutSec 10
            
            $Panels = $DashboardResponse.dashboard.panels
            Write-Host "   Total panels: $($Panels.Count)" -ForegroundColor White
            
            $ExpectedPanels = @(
                "Queue Utilization Ratio",
                "Queue Size vs Capacity", 
                "Send Failure Rate",
                "Batch Timeout Triggers",
                "Log Processing Rate"
            )
            
            foreach ($ExpectedPanel in $ExpectedPanels) {
                $FoundPanel = $Panels | Where-Object { $_.title -eq $ExpectedPanel }
                if ($FoundPanel) {
                    Write-Host "   ✅ $ExpectedPanel" -ForegroundColor Green
                } else {
                    Write-Host "   ❌ $ExpectedPanel (not found)" -ForegroundColor Red
                }
            }
        }
        
        if ($TestQueries) {
            Write-Host ""
            Write-Host "🧪 Testing dashboard queries..." -ForegroundColor Cyan
            
            $TestQueries = @(
                @{ Name = "Queue Utilization"; Query = "otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100" },
                @{ Name = "Queue Size"; Query = "otelcol_exporter_queue_size" },
                @{ Name = "Queue Capacity"; Query = "otelcol_exporter_queue_capacity" },
                @{ Name = "Send Failures"; Query = "rate(otelcol_exporter_send_failed_log_records_total[5m])" },
                @{ Name = "Batch Timeouts"; Query = "rate(otelcol_processor_batch_timeout_trigger_send_total[5m])" },
                @{ Name = "Log Processing"; Query = "rate(otelcol_receiver_accepted_log_records_total[5m])" }
            )
            
            foreach ($TestQuery in $TestQueries) {
                try {
                    $QueryResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/query" -Headers $Headers -Method POST -Body (@{ query = $TestQuery.Query } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
                    
                    if ($QueryResponse.data.result -and $QueryResponse.data.result.Count -gt 0) {
                        Write-Host "   ✅ $($TestQuery.Name): Data available" -ForegroundColor Green
                    } else {
                        Write-Host "   ⚠️  $($TestQuery.Name): No data (may be normal)" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "   ❌ $($TestQuery.Name): Query failed" -ForegroundColor Red
                }
            }
        }
        
    } else {
        Write-Host "❌ Dashboard not found: $DashboardName" -ForegroundColor Red
        Write-Host "   Available dashboards:" -ForegroundColor Yellow
        foreach ($Dash in $DashboardsResponse.data) {
            Write-Host "   - $($Dash.title)" -ForegroundColor White
        }
    }
    
} catch {
    Write-Host "❌ Error verifying dashboard: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Please verify manually in SigNoz UI" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Manual Verification Steps" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green
Write-Host "1. Open http://localhost:8080" -ForegroundColor White
Write-Host "2. Go to Dashboards" -ForegroundColor White
Write-Host "3. Find: $DashboardName" -ForegroundColor White
Write-Host "4. Click to open the dashboard" -ForegroundColor White
Write-Host "5. Verify all 5 panels are visible" -ForegroundColor White
Write-Host "6. Check that panels show data (may take a few minutes)" -ForegroundColor White
Write-Host "7. Test different time ranges (1h, 6h, 24h)" -ForegroundColor White

Write-Host ""
Write-Host "🎯 Dashboard Verification Completed!" -ForegroundColor Green
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow