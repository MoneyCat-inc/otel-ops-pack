#Requires -Version 7.0

<#
.SYNOPSIS
    Set up SigNoz saved view for canary monitoring with automated instructions.

.DESCRIPTION
    Provides step-by-step instructions and automation for creating a SigNoz
    saved view to monitor canary ingestion. Includes API calls and UI guidance.

.PARAMETER SigNozUrl
    SigNoz UI URL (default: http://localhost:8080).

.PARAMETER ViewName
    Name for the saved view (default: "SigNoz Canary Monitor").

.EXAMPLE
    .\setup-signoz-saved-view.ps1
    Sets up canary monitoring view with default settings.

.EXAMPLE
    .\setup-signoz-saved-view.ps1 -SigNozUrl "http://signoz.company.com" -ViewName "Production Canary Monitor"
    Sets up view with custom URL and name.
#>

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$ViewName = "SigNoz Canary Monitor"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Success {
    param([string]$Message)
    Write-Host "[OK]    $Message" -ForegroundColor Green
}

function Write-WarnMsg {
    param([string]$Message)
    Write-Host "[WARN]  $Message" -ForegroundColor Yellow
}

function Write-Failure {
    param([string]$Message)
    Write-Host "[FAIL]  $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO]  $Message" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host "[STEP]  $Message" -ForegroundColor Magenta
}

Write-Info "Setting up SigNoz saved view for canary monitoring..."
Write-Info "SigNoz URL: $SigNozUrl"
Write-Info "View Name: $ViewName"

# Check SigNoz connectivity
Write-Step "Step 1: Checking SigNoz connectivity..."
try {
    $Response = Invoke-WebRequest -Uri "$SigNozUrl/api/v1/health" -Method GET -TimeoutSec 10
    if ($Response.StatusCode -eq 200) {
        Write-Success "SigNoz is accessible at $SigNozUrl"
    } else {
        Write-WarnMsg "SigNoz responded with status code: $($Response.StatusCode)"
    }
} catch {
    Write-WarnMsg "Could not connect to SigNoz at $SigNozUrl - please ensure it's running"
    Write-Info "You can still create the saved view manually using the instructions below"
}

# Create saved view configuration
$SavedViewConfig = @{
    name = $ViewName
    description = "Monitor SigNoz canary ingestion with real-time filtering"
    filters = @(
        @{
            key = "message"
            operator = "contains"
            value = "SigNoz wiring canary"
        }
    )
    timeRange = @{
        start = "now-1h"
        end = "now"
    }
    refreshInterval = "30s"
    columns = @(
        "timestamp",
        "message",
        "level",
        "source",
        "eventId"
    )
} | ConvertTo-Json -Depth 4

$ConfigFile = Join-Path $PSScriptRoot "..\artifacts\signoz-canary-view-config.json"
$ConfigDir = Split-Path $ConfigFile -Parent
if (-not (Test-Path $ConfigDir)) {
    New-Item -Path $ConfigDir -ItemType Directory | Out-Null
}

$SavedViewConfig | Out-File -FilePath $ConfigFile -Encoding UTF8
Write-Success "Saved view configuration written to: $ConfigFile"

# Generate instructions
Write-Step "Step 2: Manual Setup Instructions"
Write-Host ""
Write-Host "=== SigNoz UI Setup Instructions ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Open SigNoz UI:" -ForegroundColor White
Write-Host "   URL: $SigNozUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Navigate to Logs:" -ForegroundColor White
Write-Host "   Click on 'Logs' in the left sidebar" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Add Filter:" -ForegroundColor White
Write-Host "   Click 'Add Filter' button" -ForegroundColor Cyan
Write-Host "   Select: message" -ForegroundColor Cyan
Write-Host "   Operator: contains" -ForegroundColor Cyan
Write-Host "   Value: SigNoz wiring canary" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Alternative Filter (for file logs):" -ForegroundColor White
Write-Host "   Add another filter:" -ForegroundColor Cyan
Write-Host "   Select: log.file.path" -ForegroundColor Cyan
Write-Host "   Operator: contains" -ForegroundColor Cyan
Write-Host "   Value: C:/logs/signoz-canary/canary.log" -ForegroundColor Cyan
Write-Host ""
Write-Host "5. Save View:" -ForegroundColor White
Write-Host "   Click 'Save View' button" -ForegroundColor Cyan
Write-Host "   Name: $ViewName" -ForegroundColor Cyan
Write-Host "   Description: Monitor SigNoz canary ingestion" -ForegroundColor Cyan
Write-Host ""
Write-Host "6. Set Refresh Interval:" -ForegroundColor White
Write-Host "   Set to 30 seconds for real-time monitoring" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== API Setup (Alternative) ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "You can also create the view via API:" -ForegroundColor White
Write-Host "POST $SigNozUrl/api/v1/logs/views" -ForegroundColor Cyan
Write-Host "Content-Type: application/json" -ForegroundColor Cyan
Write-Host ""
Write-Host "Body:" -ForegroundColor White
Write-Host $SavedViewConfig -ForegroundColor Gray
Write-Host ""

# Create a quick test script
$TestScript = @"
# Quick test for SigNoz canary view
Write-Host "Testing SigNoz canary view..." -ForegroundColor Cyan

# Check if we can see recent canaries
`$Query = @{
    query = "message contains `"SigNoz wiring canary`""
    start = [DateTimeOffset]::UtcNow.AddHours(-1).ToUnixTimeSeconds()
    end = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
} | ConvertTo-Json

try {
    `$Response = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/logs" -Method POST -Body `$Query -ContentType "application/json"
    `$Count = `$Response.data.Count
    Write-Host "Found `$Count canary entries in the last hour" -ForegroundColor Green
} catch {
    Write-Host "Could not query SigNoz API: `$(`$_.Exception.Message)" -ForegroundColor Red
}
"@

$TestScriptPath = Join-Path $PSScriptRoot "test-signoz-canary-view.ps1"
$TestScript | Out-File -FilePath $TestScriptPath -Encoding UTF8
Write-Success "Test script created: $TestScriptPath"

Write-Step "Step 3: Verification"
Write-Host ""
Write-Host "To verify the setup:" -ForegroundColor White
Write-Host "1. Run: pwsh -File scripts\test-signoz-canary-view.ps1" -ForegroundColor Cyan
Write-Host "2. Check SigNoz UI for recent canary entries" -ForegroundColor Cyan
Write-Host "3. Verify saved view appears in SigNoz sidebar" -ForegroundColor Cyan
Write-Host ""

Write-Success "SigNoz saved view setup completed!"
Write-Info "Configuration saved to: $ConfigFile"
Write-Info "Test script created: $TestScriptPath"
