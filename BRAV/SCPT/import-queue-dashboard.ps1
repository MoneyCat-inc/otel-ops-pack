param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$DashboardFile = "docs/queue-steward-dashboard.json"
)

function Import-QueueDashboard {
    param(
        [string]$Url,
        [string]$DashboardPath
    )
    
    if (-not (Test-Path $DashboardPath)) {
        Write-Error "Dashboard file not found: $DashboardPath"
        return $false
    }
    
    try {
        $dashboardContent = Get-Content $DashboardPath -Raw -Encoding UTF8
        $dashboardJson = $dashboardContent | ConvertFrom-Json
        
        Write-Host "Dashboard Configuration:"
        Write-Host "  Title: $($dashboardJson.title)"
        Write-Host "  Panels: $($dashboardJson.panels.Count)"
        Write-Host "  Refresh: $($dashboardJson.refresh)"
        Write-Host ""
        
        # Test SigNoz connectivity
        Write-Host "Testing SigNoz connectivity..."
        $healthResponse = Invoke-WebRequest -Uri "$Url/api/v1/health" -UseBasicParsing -TimeoutSec 10
        if ($healthResponse.StatusCode -eq 200) {
            Write-Host "✅ SigNoz is accessible at $Url"
        } else {
            Write-Warning "⚠️ SigNoz returned status: $($healthResponse.StatusCode)"
        }
        
        Write-Host ""
        Write-Host "=== Manual Import Instructions ==="
        Write-Host "1. Open SigNoz UI: $Url"
        Write-Host "2. Go to Dashboards → New Dashboard"
        Write-Host "3. Create panels with the following queries:"
        Write-Host ""
        
        foreach ($panel in $dashboardJson.panels) {
            Write-Host "Panel: $($panel.title)"
            Write-Host "Query: $($panel.targets[0].query)"
            Write-Host "Type: $($panel.type)"
            Write-Host ""
        }
        
        Write-Host "=== Quick Test Queries ==="
        Write-Host "Test queue telemetry exists:"
        Write-Host "SELECT count(*) FROM signoz_logs.logs_v2 WHERE JSONExtractString(body, 'dataset') = 'agent_queue' AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 1 HOUR;"
        Write-Host ""
        
        Write-Host "Test queue depth:"
        Write-Host "SELECT avg(JSONExtractInt(body, 'queueLength')) AS queue_depth FROM signoz_logs.logs_v2 WHERE JSONExtractString(body, 'dataset') = 'agent_queue' AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 5 MINUTE;"
        Write-Host ""
        
        return $true
        
    } catch {
        Write-Error "Failed to process dashboard: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
Write-Host "=== Queue Steward Dashboard Import ==="
Write-Host "SigNoz URL: $SigNozUrl"
Write-Host "Dashboard File: $DashboardFile"
Write-Host ""

$success = Import-QueueDashboard -Url $SigNozUrl -DashboardPath $DashboardFile

if ($success) {
    Write-Host "✅ Dashboard import instructions generated successfully"
    Write-Host "📋 Next: Follow the manual import instructions above"
} else {
    Write-Host "❌ Failed to generate dashboard import instructions"
}
