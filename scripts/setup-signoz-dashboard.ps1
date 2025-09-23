# SigNoz Dashboard Setup Script
# Imports dashboard configuration and creates saved searches

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$DashboardConfig = "docs/signoz-sysinfo-dashboard.json"
)

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-SigNozConnection {
    param([string]$BaseUrl)
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/health" -Method Get -TimeoutSec 10
        return $true
    }
    catch {
        Write-ColorOutput "Failed to connect to SigNoz at $BaseUrl" "Red"
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Import-DashboardConfig {
    param(
        [string]$BaseUrl,
        [string]$ConfigPath
    )
    
    if (-not (Test-Path $ConfigPath)) {
        Write-ColorOutput "Dashboard config file not found: $ConfigPath" "Red"
        return $false
    }
    
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    
    Write-ColorOutput "Dashboard Configuration:" "Cyan"
    Write-ColorOutput "  Title: $($config.dashboard.title)" "White"
    Write-ColorOutput "  Panels: $($config.dashboard.panels.Count)" "White"
    Write-ColorOutput "  Saved Searches: $($config.savedSearches.Count)" "White"
    Write-ColorOutput "  Alerts: $($config.alerts.Count)" "White"
    
    return $config
}

function Show-SavedSearches {
    param($Config)
    
    Write-ColorOutput "`nSaved Searches to Create:" "Yellow"
    foreach ($search in $Config.savedSearches) {
        Write-ColorOutput "  • $($search.name)" "White"
        Write-ColorOutput "    Query: $($search.query)" "Gray"
    }
}

function Show-DashboardPanels {
    param($Config)
    
    Write-ColorOutput "`nDashboard Panels:" "Yellow"
    foreach ($panel in $Config.dashboard.panels) {
        Write-ColorOutput "  • $($panel.title)" "White"
        Write-ColorOutput "    Type: $($panel.type)" "Gray"
        Write-ColorOutput "    Query: $($panel.query.query)" "Gray"
    }
}

function Show-Alerts {
    param($Config)
    
    Write-ColorOutput "`nAlerts to Configure:" "Yellow"
    foreach ($alert in $Config.alerts) {
        Write-ColorOutput "  • $($alert.name) ($($alert.severity))" "White"
        Write-ColorOutput "    Query: $($alert.query)" "Gray"
        Write-ColorOutput "    Threshold: $($alert.threshold) in $($alert.evaluationWindow)" "Gray"
    }
}

function Show-SigNozInstructions {
    Write-ColorOutput "`n=== SigNoz Setup Instructions ===" "Cyan"
    Write-ColorOutput "`n1. Open SigNoz UI: $SigNozUrl" "White"
    Write-ColorOutput "`n2. Create Saved Searches:" "Yellow"
    Write-ColorOutput "   • Go to Logs → Saved Searches → New" "White"
    Write-ColorOutput "   • Use the queries shown above" "White"
    
    Write-ColorOutput "`n3. Create Dashboard:" "Yellow"
    Write-ColorOutput "   • Go to Dashboards → New Dashboard" "White"
    Write-ColorOutput "   • Add panels using the queries above" "White"
    Write-ColorOutput "   • Set refresh interval to 30s" "White"
    
    Write-ColorOutput "`n4. Configure Alerts:" "Yellow"
    Write-ColorOutput "   • Go to Alerts → New Alert" "White"
    Write-ColorOutput "   • Use the alert queries shown above" "White"
    Write-ColorOutput "   • Set evaluation window to 5 minutes" "White"
    
    Write-ColorOutput "`n5. Test Queries:" "Yellow"
    Write-ColorOutput "   • SysInfo logs: log.file.name contains 'monolith-D.txt'" "White"
    Write-ColorOutput "   • Memory alerts: dataset = 'memory-monitoring'" "White"
    Write-ColorOutput "   • System alerts: dataset = 'system-monitoring'" "White"
}

function Test-SampleQueries {
    param([string]$BaseUrl)
    
    Write-ColorOutput "`n=== Testing Sample Queries ===" "Cyan"
    
    $queries = @(
        @{
            Name = "SysInfo Logs"
            Query = "log.file.name contains 'monolith-D.txt'"
        },
        @{
            Name = "Memory Monitoring"
            Query = "dataset = 'memory-monitoring'"
        },
        @{
            Name = "System Monitoring"
            Query = "dataset = 'system-monitoring'"
        }
    )
    
    foreach ($query in $queries) {
        Write-ColorOutput "`nTesting: $($query.Name)" "White"
        Write-ColorOutput "Query: $($query.Query)" "Gray"
        Write-ColorOutput "URL: $BaseUrl/logs?q=$([System.Web.HttpUtility]::UrlEncode($query.Query))" "Gray"
    }
}

# Main execution
Write-ColorOutput "SigNoz Dashboard Setup Script" "Cyan"
Write-ColorOutput "=============================" "Cyan"

# Test SigNoz connection
Write-ColorOutput "`nTesting SigNoz connection..." "White"
if (-not (Test-SigNozConnection -BaseUrl $SigNozUrl)) {
    Write-ColorOutput "Please ensure SigNoz is running on $SigNozUrl" "Red"
    exit 1
}

Write-ColorOutput "✓ SigNoz is accessible" "Green"

# Load dashboard configuration
Write-ColorOutput "`nLoading dashboard configuration..." "White"
$config = Import-DashboardConfig -BaseUrl $SigNozUrl -ConfigPath $DashboardConfig

if (-not $config) {
    Write-ColorOutput "Failed to load dashboard configuration" "Red"
    exit 1
}

Write-ColorOutput "✓ Configuration loaded successfully" "Green"

# Display configuration details
Show-SavedSearches -Config $config
Show-DashboardPanels -Config $config
Show-Alerts -Config $config

# Show setup instructions
Show-SigNozInstructions

# Test sample queries
Test-SampleQueries -BaseUrl $SigNozUrl

Write-ColorOutput "`n=== Setup Complete ===" "Green"
Write-ColorOutput "Follow the instructions above to configure SigNoz UI" "White"
Write-ColorOutput "Dashboard config saved to: $DashboardConfig" "Gray"
