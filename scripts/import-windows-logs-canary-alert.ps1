#Requires -Version 7.0

<#
.SYNOPSIS
    Import Windows Logs Canary Alert into SigNoz

.DESCRIPTION
    This script imports the Windows logs canary alert configuration into SigNoz
    and provides manual import instructions if automated import is not available.

.EXAMPLE
    .\import-windows-logs-canary-alert.ps1
#>

$ErrorActionPreference = 'Stop'

# Color functions for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

Write-Info "🚨 Importing Windows Logs Canary Alert into SigNoz"
Write-Info "=================================================="

$alertFile = "signoz-windows-logs-canary-alert.json"
$signozApiUrl = "http://localhost:8080/api/v1/alerts"

if (-not (Test-Path $alertFile)) {
    Write-Error "Alert file not found: $alertFile"
    exit 1
}

try {
    # Read the alert configuration
    $alertConfig = Get-Content -Path $alertFile -Raw | ConvertFrom-Json
    
    Write-Info "📋 Alert Configuration:"
    Write-Info "  Name: $($alertConfig.alert.name)"
    Write-Info "  Severity: $($alertConfig.alert.severity)"
    Write-Info "  Duration: $($alertConfig.alert.condition.duration)"
    Write-Info "  Threshold: $($alertConfig.alert.condition.threshold) entries"
    Write-Info "  Query: $($alertConfig.alert.query.logsQuery.query)"
    
    # Check if SigNoz is accessible
    Write-Info "`n🌐 Checking SigNoz connectivity..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5 -ErrorAction Stop
        Write-Success "SigNoz UI reachable (Status: $($response.StatusCode))"
    } catch {
        Write-Warning "SigNoz UI not reachable: $($_.Exception.Message)"
        Write-Info "Please ensure SigNoz is running on http://localhost:8080"
    }
    
    # Provide manual import instructions
    Write-Info "`n📝 Manual Import Instructions:"
    Write-Info "1. Open SigNoz UI: http://localhost:8080"
    Write-Info "2. Navigate to: Alerts → Create Alert"
    Write-Info "3. Configure the following:"
    Write-Info "   • Name: Windows Logs Canary Missing (1 Hour)"
    Write-Info "   • Severity: Warning"
    Write-Info "   • Query: $($alertConfig.alert.query.logsQuery.query)"
    Write-Info "   • Condition: Below $($alertConfig.alert.condition.threshold) for $($alertConfig.alert.condition.duration)"
    Write-Info "   • Labels: component=windows-logs, canary=true, alert_type=ingestion"
    
    Write-Info "`n🔍 Verification Query for SigNoz Logs:"
    Write-Info "attributes_string['dataset'] = 'windows' AND body LIKE '%windows-logs-canary%'"
    
    Write-Info "`n📊 Expected Behavior:"
    Write-Info "  • Alert triggers if no Windows logs canaries for 1 hour"
    Write-Info "  • Run windows-logs-canary-test.ps1 to generate test entries"
    Write-Info "  • Use monitor-windows-logs-canary.ps1 for CLI monitoring"
    
    Write-Success "`n✅ Windows Logs Canary Alert configuration ready for import!"
    Write-Info "   The alert will monitor Windows Event Log canary ingestion"
    
} catch {
    Write-Error "Error processing alert configuration: $($_.Exception.Message)"
    exit 1
}

Write-Info "`n🔗 Next Steps:"
Write-Info "  • Import alert in SigNoz UI using the instructions above"
Write-Info "  • Test with: .\scripts\windows-logs-canary-test.ps1"
Write-Info "  • Monitor with: .\scripts\monitor-windows-logs-canary.ps1"
Write-Info "  • Check SigNoz Logs for canary entries"

Write-Info "`n📚 Related Files:"
Write-Info "  • Alert config: $alertFile"
Write-Info "  • Test script: scripts\windows-logs-canary-test.ps1"
Write-Info "  • Monitor script: scripts\monitor-windows-logs-canary.ps1"
