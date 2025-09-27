#Requires -Version 7.0

<#
.SYNOPSIS
    Generate Windows Event Log canary entries for testing ingestion pipeline

.DESCRIPTION
    This script creates canary entries in Windows Event Logs to test the 
    observability pipeline. It writes entries to both Application and System logs
    with specific canary identifiers that can be monitored via SigNoz.

.PARAMETER Count
    Number of canary entries to create (default: 5)

.PARAMETER LogName
    Windows Event Log name (default: Application)

.EXAMPLE
    .\windows-logs-canary-test.ps1
    .\windows-logs-canary-test.ps1 -Count 10 -LogName System
#>

param(
    [ValidateRange(1, 100)]
    [int]$Count = 5,
    [ValidateSet("Application", "System", "Security")]
    [string]$LogName = "Application"
)

$ErrorActionPreference = 'Stop'

# Color functions for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

Write-Info "🚨 Starting Windows Logs Canary Test"
Write-Info "====================================="
Write-Info "Count: $Count entries"
Write-Info "Log: $LogName"
Write-Info "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

$canarySource = "Windows-Logs-Canary"
$successCount = 0
$errorCount = 0

try {
    # Ensure event source exists
    if (-not [System.Diagnostics.EventLog]::SourceExists($canarySource)) {
        Write-Info "Creating event source: $canarySource"
        New-EventLog -LogName $LogName -Source $canarySource -ErrorAction Stop
        Write-Success "Event source created successfully"
    }

    # Generate canary entries
    for ($i = 1; $i -le $Count; $i++) {
        $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        $canaryId = "windows-logs-canary-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$i"
        
        $message = @"
Windows Logs Canary Test Entry #$i
Canary ID: $canaryId
Timestamp: $timestamp
Test Type: ingestion-pipeline-verification
Service: windows-logs-canary
Level: INFO
"@

        try {
            Write-EventLog -LogName $LogName -Source $canarySource -EventId (1000 + $i) -EntryType Information -Message $message -ErrorAction Stop
            Write-Success "Created canary entry #$i (ID: $canaryId)"
            $successCount++
        } catch {
            Write-Warning "Failed to create canary entry #$i`: $($_.Exception.Message)"
            $errorCount++
        }
        
        # Small delay between entries
        Start-Sleep -Milliseconds 100
    }

    Write-Info "`n📊 Canary Test Summary:"
    Write-Success "  Successful entries: $successCount"
    if ($errorCount -gt 0) {
        Write-Warning "  Failed entries: $errorCount"
    }

    # Generate verification instructions
    Write-Info "`n🔍 Verification Steps:"
    Write-Info "1. SigNoz UI → Logs"
    Write-Info "2. Filter: attributes.log.source = 'windows_event_log' AND body LIKE '%windows-logs-canary%'"
    Write-Info "3. Expected: $successCount entries with canary IDs"
    Write-Info "4. Time range: Last 5 minutes"

    # Create artifacts report
    $artifactsDir = "artifacts"
    if (-not (Test-Path $artifactsDir)) {
        New-Item -Path $artifactsDir -ItemType Directory | Out-Null
    }

    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        test_type = "windows-logs-canary"
        log_name = $LogName
        requested_count = $Count
        success_count = $successCount
        error_count = $errorCount
        canary_source = $canarySource
        status = if ($errorCount -eq 0) { "success" } else { "partial_success" }
    }

    $reportFile = Join-Path $artifactsDir "windows-logs-canary-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Info "Report saved to: $reportFile"

    if ($successCount -gt 0) {
        Write-Success "`n✅ Windows Logs Canary Test completed successfully!"
        Write-Info "Check SigNoz in 1-2 minutes for the generated canary entries"
        exit 0
    } else {
        Write-Error "`n❌ Windows Logs Canary Test failed - no entries created"
        exit 1
    }

} catch {
    Write-Error "Windows Logs Canary Test failed: $($_.Exception.Message)"
    Write-Info "Make sure you have permission to write to Windows Event Logs"
    exit 2
}
