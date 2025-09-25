#Requires -Version 7.0

<#
.SYNOPSIS
    Import Windows Logs Canary Dashboard into SigNoz

.DESCRIPTION
    This script provides instructions for importing the Windows Logs Canary
    monitoring dashboard into SigNoz and configuring it for optimal monitoring.

.EXAMPLE
    .\import-canary-dashboard.ps1
    .\import-canary-dashboard.ps1 -DashboardName "Windows-Logs-Canary-v2"
#>

param(
    [string]$DashboardName = "Windows-Logs-Canary",
    [switch]$ShowInstructions
)

# Color functions for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

Write-Info "📊 Windows Logs Canary Dashboard Import"
Write-Info "======================================"

$dashboardFile = "signoz-windows-logs-canary-dashboard.json"

if (-not (Test-Path $dashboardFile)) {
    Write-Error "Dashboard configuration file not found: $dashboardFile"
    exit 1
}

try {
    $dashboardConfig = Get-Content -Path $dashboardFile -Raw | ConvertFrom-Json
    
    Write-Info "📋 Dashboard Configuration:"
    Write-Info "  Title: $($dashboardConfig.dashboard.title)"
    Write-Info "  Description: $($dashboardConfig.dashboard.description)"
    Write-Info "  Panels: $($dashboardConfig.dashboard.panels.Count)"
    Write-Info "  Refresh Rate: $($dashboardConfig.dashboard.refresh)"
    Write-Info "  Time Range: $($dashboardConfig.dashboard.timeRange.from) to $($dashboardConfig.dashboard.timeRange.to)"
    
    Write-Info "`n📝 Manual Import Instructions:"
    Write-Info "=============================="
    
    Write-Info "1. Open SigNoz UI: http://localhost:8080"
    Write-Info "2. Navigate to: Dashboards"
    Write-Info "3. Click 'Import Dashboard' or 'Create Dashboard'"
    Write-Info "4. Choose 'Import JSON' option"
    Write-Info "5. Copy and paste the contents of: $dashboardFile"
    Write-Info "6. Click 'Import' or 'Save'"
    
    Write-Info "`n📊 Dashboard Panels Overview:"
    Write-Info "============================"
    
    foreach ($panel in $dashboardConfig.dashboard.panels) {
        Write-Info "• Panel $($panel.id): $($panel.title) ($($panel.type))"
    }
    
    Write-Info "`n🔍 Panel Details:"
    Write-Info "================="
    
    Write-Info "1. **Windows Logs Canary Count (Last Hour)**"
    Write-Info "   • Type: Stat panel"
    Write-Info "   • Query: Count of canary entries in last hour"
    Write-Info "   • Thresholds: Red (0), Yellow (1), Green (5+)"
    
    Write-Info "`n2. **Canary Generation Rate (per hour)**"
    Write-Info "   • Type: Graph panel"
    Write-Info "   • Query: Hourly canary generation rate"
    Write-Info "   • Shows: Trend over time"
    
    Write-Info "`n3. **Recent Canary Entries**"
    Write-Info "   • Type: Table panel"
    Write-Info "   • Query: Last 10 canary entries"
    Write-Info "   • Shows: Timestamp and body content"
    
    Write-Info "`n4. **Windows Event Log Volume**"
    Write-Info "   • Type: Graph panel"
    Write-Info "   • Query: Total Windows logs volume"
    Write-Info "   • Context: Compare canary vs total volume"
    
    Write-Info "`n5. **Canary Health Status**"
    Write-Info "   • Type: Stat panel"
    Write-Info "   • Query: Health check (canaries in last 15 min)"
    Write-Info "   • Status: HEALTHY (1) or UNHEALTHY (0)"
    
    Write-Info "`n6. **Alert Status**"
    Write-Info "   • Type: Stat panel"
    Write-Info "   • Query: Alert condition (canaries < 1 in last hour)"
    Write-Info "   • Status: OK (0) or ALERT (1)"
    
    Write-Info "`n7. **Canary Generation Timeline**"
    Write-Info "   • Type: Graph panel"
    Write-Info "   • Query: 6-hour canary generation timeline"
    Write-Info "   • Shows: Long-term trends and patterns"
    
    Write-Info "`n🔗 Dashboard Links:"
    Write-Info "==================="
    
    foreach ($link in $dashboardConfig.dashboard.links) {
        Write-Info "• $($link.title): $($link.url)"
    }
    
    Write-Info "`n⚙️ Configuration Options:"
    Write-Info "========================"
    
    Write-Info "• **Refresh Rate**: 30 seconds (adjustable)"
    Write-Info "• **Time Range**: Last 1 hour (adjustable)"
    Write-Info "• **Thresholds**: Customizable color coding"
    Write-Info "• **Annotations**: Canary test run markers"
    
    Write-Info "`n🧪 Testing Dashboard:"
    Write-Info "===================="
    
    Write-Info "1. **Generate Test Canaries**:"
    Write-Info "   .\scripts\windows-logs-canary-test.ps1 -Count 5"
    
    Write-Info "`n2. **Verify Dashboard Updates**:"
    Write-Info "   • Check canary count increases"
    Write-Info "   • Verify health status shows HEALTHY"
    Write-Info "   • Confirm alert status shows OK"
    
    Write-Info "`n3. **Test Alert Condition**:"
    Write-Info "   • Wait 1+ hours without generating canaries"
    Write-Info "   • Verify alert status changes to ALERT"
    Write-Info "   • Check health status shows UNHEALTHY"
    
    Write-Info "`n📈 Dashboard Customization:"
    Write-Info "==========================="
    
    Write-Info "• **Adjust Time Ranges**: Modify panel queries"
    Write-Info "• **Change Thresholds**: Update color coding"
    Write-Info "• **Add Panels**: Include additional metrics"
    Write-Info "• **Modify Queries**: Customize data sources"
    
    Write-Info "`n🔧 Advanced Configuration:"
    Write-Info "=========================="
    
    Write-Info "• **Variables**: Add dashboard variables for filtering"
    Write-Info "• **Annotations**: Enable/disable annotation layers"
    Write-Info "• **Links**: Add custom navigation links"
    Write-Info "• **Permissions**: Configure dashboard access"
    
    Write-Success "`n✅ Dashboard import instructions completed!"
    
    Write-Info "`n📚 Next Steps:"
    Write-Info "  • Import dashboard into SigNoz UI"
    Write-Info "  • Test with canary generation"
    Write-Info "  • Customize panels and thresholds"
    Write-Info "  • Set up dashboard sharing and permissions"
    Write-Info "  • Add to monitoring runbooks"
    
    if ($ShowInstructions) {
        Write-Info "`n📄 Dashboard JSON Configuration:"
        Write-Info "================================="
        $dashboardConfig | ConvertTo-Json -Depth 10
    }
    
} catch {
    Write-Error "Error processing dashboard configuration: $($_.Exception.Message)"
    exit 1
}
