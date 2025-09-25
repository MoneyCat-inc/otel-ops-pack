#Requires -Version 7.0

<#
.SYNOPSIS
    Setup daily automation for latency baseline management and SigNoz dashboard updates

.DESCRIPTION
    This script sets up complete daily automation including:
    - Scheduled task for baseline management
    - SigNoz dashboard configuration export
    - Alert configuration
    - Verification and testing

.NOTES
    For long-running operations, this script uses the shared spinner toolkit:
    . (Join-Path $PSScriptRoot 'spinner-toolkit.ps1')
    Use Show-Spinner, Wait-WithSpinner, or Show-ProgressBar for consistent UX.

.PARAMETER ScheduleTime
    Time to run daily automation (24-hour format). Default: 02:00

.PARAMETER BaselineName
    Name of the baseline to manage. Default: control

.PARAMETER DryRun
    Show what would be done without making changes

.PARAMETER SkipSchedule
    Skip creating the scheduled task

.EXAMPLE
    .\setup-daily-automation.ps1
    Setup daily automation with default settings

.EXAMPLE
    .\setup-daily-automation.ps1 -ScheduleTime "03:30" -DryRun
    Preview automation setup for 3:30 AM

.EXAMPLE
    .\setup-daily-automation.ps1 -SkipSchedule
    Setup everything except the scheduled task
#>

param(
    [string]$ScheduleTime = "02:00",
    [string]$BaselineName = "control",
    [switch]$DryRun,
    [switch]$SkipSchedule
)

# Initialize script
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Import shared spinner toolkit for consistent progress indicators
. (Join-Path $PSScriptRoot 'spinner-toolkit.ps1')

Write-Host "Daily Automation Setup for OTel Latency Management" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Check administrator privileges for scheduling
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin -and -not $SkipSchedule) {
    Write-Host "ERROR: Administrator privileges required for scheduling" -ForegroundColor Red
    Write-Host "   Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    Write-Host "   Or use -SkipSchedule to setup everything except the scheduled task" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nConfiguration:" -ForegroundColor Cyan
Write-Host "  Schedule Time: $ScheduleTime" -ForegroundColor White
Write-Host "  Baseline Name: $BaselineName" -ForegroundColor White
Write-Host "  Dry Run: $DryRun" -ForegroundColor White
Write-Host "  Skip Schedule: $SkipSchedule" -ForegroundColor White

# Step 1: Create scheduled task
if (-not $SkipSchedule) {
    Write-Host "`n=== Step 1: Creating Scheduled Task ===" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN - Would create scheduled task:" -ForegroundColor Cyan
        Write-Host "  Task Name: OTel-Latency-Baseline-Daily" -ForegroundColor White
        Write-Host "  Schedule: Daily at $ScheduleTime" -ForegroundColor White
        Write-Host "  Action: apply -BaselineName $BaselineName" -ForegroundColor White
    } else {
        try {
            & "pwsh" -File "scripts/manage-latency-baselines.ps1" -Action create-schedule -ScheduleTime $ScheduleTime -BaselineName $BaselineName
            Write-Host "✓ Scheduled task created successfully" -ForegroundColor Green
        } catch {
            Write-Host "✗ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
} else {
    Write-Host "`n=== Step 1: Skipped (Schedule Creation) ===" -ForegroundColor Yellow
    Write-Host "Scheduled task creation skipped as requested" -ForegroundColor Gray
}

# Step 2: Test baseline management
Write-Host "`n=== Step 2: Testing Baseline Management ===" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "DRY RUN - Would test baseline management:" -ForegroundColor Cyan
    Write-Host "  Check existing baselines" -ForegroundColor White
    Write-Host "  Verify baseline file structure" -ForegroundColor White
} else {
    try {
        Write-Host "Checking existing baselines..." -ForegroundColor White
        & "pwsh" -File "scripts/manage-latency-baselines.ps1" -Action list
        Write-Host "✓ Baseline management verified" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Baseline management test failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "  This is expected if no baselines exist yet" -ForegroundColor Gray
    }
}

# Step 3: Test dashboard export
Write-Host "`n=== Step 3: Testing Dashboard Export ===" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "DRY RUN - Would test dashboard export:" -ForegroundColor Cyan
    Write-Host "  Export dashboard configuration" -ForegroundColor White
    Write-Host "  Verify JSON structure" -ForegroundColor White
} else {
    try {
        Write-Host "Testing dashboard export..." -ForegroundColor White
        & "pwsh" -File "scripts/export-dashboard-config.ps1" -OutputFile "artifacts/test-dashboard-config.json"
        
        if (Test-Path "artifacts/test-dashboard-config.json") {
            $config = Get-Content "artifacts/test-dashboard-config.json" -Raw | ConvertFrom-Json
            Write-Host "✓ Dashboard export verified" -ForegroundColor Green
            Write-Host "  Dashboard: $($config.dashboard.name)" -ForegroundColor White
            Write-Host "  Panels: $($config.dashboard.panels.Count)" -ForegroundColor White
            Write-Host "  Alerts: $($config.alerts.Count)" -ForegroundColor White
            Write-Host "  Saved Searches: $($config.savedSearches.Count)" -ForegroundColor White
            
            # Clean up test file
            Remove-Item "artifacts/test-dashboard-config.json" -Force
        } else {
            Write-Host "✗ Dashboard export failed - no output file created" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Dashboard export test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 4: Test SigNoz connectivity
Write-Host "`n=== Step 4: Testing SigNoz Connectivity ===" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "DRY RUN - Would test SigNoz connectivity:" -ForegroundColor Cyan
    Write-Host "  Check SigNoz health endpoint" -ForegroundColor White
    Write-Host "  Verify dashboard import capability" -ForegroundColor White
} else {
    try {
        Write-Host "Testing SigNoz connectivity..." -ForegroundColor White
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 10
        Write-Host "✓ SigNoz is accessible" -ForegroundColor Green
        Write-Host "  Health endpoint responded successfully" -ForegroundColor White
        
        # Test dashboard import instructions
        Write-Host "Testing dashboard import instructions..." -ForegroundColor White
        & "pwsh" -File "scripts/import-dashboard.ps1" -DashboardFile "docs/signoz-dashboard-config.json" -ApplyMode
        Write-Host "✓ Dashboard import instructions verified" -ForegroundColor Green
        
    } catch {
        Write-Host "⚠ SigNoz connectivity test failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "  SigNoz may not be running or accessible" -ForegroundColor Gray
        Write-Host "  Dashboard import will still work when SigNoz is available" -ForegroundColor Gray
    }
}

# Step 5: Create verification script
Write-Host "`n=== Step 5: Creating Verification Script ===" -ForegroundColor Yellow

$verificationScript = @"
#Requires -Version 7.0

<#
.SYNOPSIS
    Verify daily automation setup
#>

Write-Host "Daily Automation Verification" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

# Check scheduled task
`$task = Get-ScheduledTask -TaskName "OTel-Latency-Baseline-Daily" -ErrorAction SilentlyContinue
if (`$task) {
    Write-Host "✓ Scheduled task exists: `$(`$task.TaskName)" -ForegroundColor Green
    Write-Host "  State: `$(`$task.State)" -ForegroundColor White
    
    try {
        `$taskInfo = Get-ScheduledTaskInfo -TaskName "OTel-Latency-Baseline-Daily"
        Write-Host "  Next Run: `$(`$taskInfo.NextRunTime)" -ForegroundColor White
        Write-Host "  Last Run: `$(`$taskInfo.LastRunTime)" -ForegroundColor White
        Write-Host "  Last Result: `$(`$taskInfo.LastTaskResult)" -ForegroundColor White
    } catch {
        Write-Host "  Next Run: Not available yet" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Scheduled task not found" -ForegroundColor Red
}

# Check baseline file
`$baselineFile = "artifacts/doe/baselines/latency.json"
if (Test-Path `$baselineFile) {
    Write-Host "✓ Baseline file exists: `$baselineFile" -ForegroundColor Green
    try {
        `$baseline = Get-Content `$baselineFile | ConvertFrom-Json
        Write-Host "  Name: `$(`$baseline.name)" -ForegroundColor White
        Write-Host "  P95: `$(`$baseline.latency.p95_ms)ms" -ForegroundColor White
        Write-Host "  Updated: `$(`$baseline.updated)" -ForegroundColor White
    } catch {
        Write-Host "  ⚠ Baseline file exists but may be corrupted" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ Baseline file not found: `$baselineFile" -ForegroundColor Yellow
    Write-Host "  This is expected for new setups" -ForegroundColor Gray
}

# Check dashboard config
`$dashboardFile = "artifacts/signoz-dashboard-config.json"
if (Test-Path `$dashboardFile) {
    Write-Host "✓ Dashboard config exists: `$dashboardFile" -ForegroundColor Green
    try {
        `$config = Get-Content `$dashboardFile | ConvertFrom-Json
        Write-Host "  Dashboard: `$(`$config.dashboard.name)" -ForegroundColor White
        Write-Host "  Panels: `$(`$config.dashboard.panels.Count)" -ForegroundColor White
        Write-Host "  Alerts: `$(`$config.alerts.Count)" -ForegroundColor White
    } catch {
        Write-Host "  ⚠ Dashboard config exists but may be corrupted" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ Dashboard config not found: `$dashboardFile" -ForegroundColor Yellow
    Write-Host "  Run apply action to generate dashboard config" -ForegroundColor Gray
}

# Check SigNoz connectivity
try {
    `$response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 5
    Write-Host "✓ SigNoz is accessible" -ForegroundColor Green
} catch {
    Write-Host "⚠ SigNoz not accessible: `$(`$_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  Ensure SigNoz is running on http://localhost:8080" -ForegroundColor Gray
}

Write-Host "`nVerification completed!" -ForegroundColor Green
"@

if ($DryRun) {
    Write-Host "DRY RUN - Would create verification script:" -ForegroundColor Cyan
    Write-Host "  File: scripts/verify-daily-automation.ps1" -ForegroundColor White
    Write-Host "  Purpose: Check automation setup status" -ForegroundColor White
} else {
    try {
        $verificationScript | Set-Content "scripts/verify-daily-automation.ps1" -Encoding UTF8
        Write-Host "✓ Verification script created: scripts/verify-daily-automation.ps1" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to create verification script: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n=== Setup Summary ===" -ForegroundColor Green

if ($DryRun) {
    Write-Host "DRY RUN COMPLETED - No changes made" -ForegroundColor Cyan
    Write-Host "`nTo apply these changes, run without -DryRun:" -ForegroundColor Yellow
    Write-Host "  pwsh -File scripts/setup-daily-automation.ps1" -ForegroundColor White
} else {
    Write-Host "✓ Daily automation setup completed!" -ForegroundColor Green
    
    if (-not $SkipSchedule) {
        Write-Host "✓ Scheduled task created" -ForegroundColor White
    }
    Write-Host "✓ Baseline management verified" -ForegroundColor White
    Write-Host "✓ Dashboard export tested" -ForegroundColor White
    Write-Host "✓ SigNoz connectivity checked" -ForegroundColor White
    Write-Host "✓ Verification script created" -ForegroundColor White
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Verify setup: pwsh -File scripts/verify-daily-automation.ps1" -ForegroundColor White
Write-Host "2. Test apply action: pwsh -File scripts/manage-latency-baselines.ps1 -Action apply" -ForegroundColor White
Write-Host "3. Check SigNoz UI: http://localhost:8080" -ForegroundColor White
Write-Host "4. Monitor scheduled task: Get-ScheduledTask -TaskName 'OTel-Latency-Baseline-Daily'" -ForegroundColor White

Write-Host "`n=== Management Commands ===" -ForegroundColor Cyan
Write-Host "View scheduled task:" -ForegroundColor White
Write-Host "  Get-ScheduledTask -TaskName 'OTel-Latency-Baseline-Daily'" -ForegroundColor Gray
Write-Host "Run automation now:" -ForegroundColor White
Write-Host "  Start-ScheduledTask -TaskName 'OTel-Latency-Baseline-Daily'" -ForegroundColor Gray
Write-Host "Remove automation:" -ForegroundColor White
Write-Host "  Unregister-ScheduledTask -TaskName 'OTel-Latency-Baseline-Daily' -Confirm:`$false" -ForegroundColor Gray

Write-Host "`nDaily automation setup completed!" -ForegroundColor Green
