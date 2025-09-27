# Import Fractal Drift Monitors Dashboard to SigNoz
# Cursor-Local: Observability Copilot

param(
    [string]$DashboardPath = "artifacts/signoz-fractal-drift-dashboard.json",
    [string]$SigNozUrl = "http://localhost:8080"
)

Write-Host "📊 Importing Fractal Drift Monitors Dashboard to SigNoz" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

# Check if dashboard file exists
if (-not (Test-Path $DashboardPath)) {
    Write-Host "❌ Dashboard file not found: $DashboardPath" -ForegroundColor Red
    exit 1
}

# Check SigNoz connectivity
Write-Host "🔍 Checking SigNoz connectivity..." -ForegroundColor Yellow
try {
    $HealthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method Get -TimeoutSec 10
    Write-Host "✅ SigNoz is healthy: $($HealthResponse.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ SigNoz not accessible: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Read dashboard configuration
$DashboardConfig = Get-Content $DashboardPath -Raw | ConvertFrom-Json
Write-Host "📋 Dashboard: $($DashboardConfig.title)" -ForegroundColor Yellow
Write-Host "   Description: $($DashboardConfig.description)" -ForegroundColor Gray
Write-Host "   Panels: $($DashboardConfig.panels.Count)" -ForegroundColor Gray

# Import dashboard via SigNoz API
Write-Host "`n🚀 Importing dashboard to SigNoz..." -ForegroundColor Green

try {
    # Convert to SigNoz dashboard format
    $SigNozDashboard = @{
        title = $DashboardConfig.title
        description = $DashboardConfig.description
        tags = $DashboardConfig.tags
        panels = @()
        time = $DashboardConfig.time
        refresh = $DashboardConfig.refresh
    }
    
    # Convert panels to SigNoz format
    foreach ($Panel in $DashboardConfig.panels) {
        $SigNozPanel = @{
            title = $Panel.title
            type = $Panel.type
            targets = $Panel.targets
            yAxes = $Panel.yAxes
            thresholds = $Panel.thresholds
            gridPos = @{
                h = 8
                w = 12
                x = 0
                y = 0
            }
        }
        
        if ($Panel.alert) {
            $SigNozPanel.alert = $Panel.alert
        }
        
        $SigNozDashboard.panels += $SigNozPanel
    }
    
    # Import via SigNoz API
    $ImportResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/dashboards/db" -Method Post -Body ($SigNozDashboard | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 30
    
    Write-Host "✅ Dashboard imported successfully!" -ForegroundColor Green
    Write-Host "   Dashboard ID: $($ImportResponse.id)" -ForegroundColor Yellow
    Write-Host "   URL: $SigNozUrl/dashboard/$($ImportResponse.slug)" -ForegroundColor Blue
    
    # Save import results
    $ImportResults = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        dashboard_id = $ImportResponse.id
        dashboard_slug = $ImportResponse.slug
        dashboard_url = "$SigNozUrl/dashboard/$($ImportResponse.slug)"
        panels_imported = $DashboardConfig.panels.Count
        status = "success"
    }
    
    $ImportResults | ConvertTo-Json -Depth 3 | Set-Content -Path "artifacts/dashboard-import-results.json"
    
    Write-Host "`n📁 Import results saved to: artifacts/dashboard-import-results.json" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ Dashboard import failed: $($_.Exception.Message)" -ForegroundColor Red
    
    $ImportResults = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        status = "failed"
        error = $_.Exception.Message
    }
    
    $ImportResults | ConvertTo-Json -Depth 3 | Set-Content -Path "artifacts/dashboard-import-results.json"
    exit 1
}

# Verify dashboard is accessible
Write-Host "`n🔍 Verifying dashboard accessibility..." -ForegroundColor Yellow
try {
    $DashboardResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/dashboards/$($ImportResponse.slug)" -Method Get -TimeoutSec 10
    Write-Host "✅ Dashboard verified: $($DashboardResponse.dashboard.title)" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Dashboard verification failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n🎉 Fractal Drift Monitors Dashboard Import Complete!" -ForegroundColor Green
Write-Host "🌐 Access your dashboard at: $SigNozUrl/dashboard/$($ImportResponse.slug)" -ForegroundColor Blue
Write-Host "📊 Monitor queue pressure, failure rates, and time-to-use latency" -ForegroundColor Cyan