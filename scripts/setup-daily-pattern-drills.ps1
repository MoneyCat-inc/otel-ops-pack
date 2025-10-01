# Setup Daily Canary Pattern Drills Automation
# Creates Windows Task Scheduler job for automated daily fractal analysis

param(
    [string]$TaskName = "Daily Canary Pattern Drills",
    [string]$ScriptPath = "scripts\canary-pattern-drills.ps1",
    [string]$StartTime = "09:00",
    [switch]$Force = $false
)

# ECRR - Examine → Clean → Report → Role
Write-Host "🔍 Examine Daily Pattern Drills Automation - ECRR Framework" -ForegroundColor Cyan
Write-Host "🎭 Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Check if script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "❌ Script not found: $ScriptPath" -ForegroundColor Red
    exit 1
}

# Check if task already exists
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($ExistingTask -and -not $Force) {
    Write-Host "⚠️ Task '$TaskName' already exists. Use -Force to replace." -ForegroundColor Yellow
    Write-Host "Current task status: $($ExistingTask.State)" -ForegroundColor Cyan
    exit 1
}

if ($ExistingTask -and $Force) {
    Write-Host "🗑️ Removing existing task: $TaskName" -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create the action
$Action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$ScriptPath`" -Pattern All -Duration 300 -Analyze" -WorkingDirectory (Get-Location)

# Create the trigger (daily at specified time)
$Trigger = New-ScheduledTaskTrigger -Daily -At $StartTime

# Create task settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

# Create task principal (run as SYSTEM)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the scheduled task
try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Daily automated canary pattern drills for fractal self-similarity validation"
    
    Write-Host "✅ Daily Pattern Drills task created successfully!" -ForegroundColor Green
    Write-Host "📋 Task Details:" -ForegroundColor Cyan
    Write-Host "  Name: $TaskName" -ForegroundColor White
    Write-Host "  Script: $ScriptPath" -ForegroundColor White
    Write-Host "  Schedule: Daily at $StartTime" -ForegroundColor White
    Write-Host "  User: SYSTEM" -ForegroundColor White
    Write-Host "  Arguments: -Pattern All -Duration 300 -Analyze" -ForegroundColor White
    
} catch {
    Write-Host "❌ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create management script
$ManagementScript = @"
# Daily Pattern Drills Management Script
# Use this script to manage the automated daily pattern drills

param(
    [ValidateSet("start", "stop", "status", "logs", "run-now")]
    [string]`$Action = "status"
)

`$TaskName = "$TaskName"

switch (`$Action) {
    "start" {
        Write-Host "🚀 Starting daily pattern drills task..." -ForegroundColor Green
        Start-ScheduledTask -TaskName `$TaskName
        Write-Host "✅ Task started" -ForegroundColor Green
    }
    "stop" {
        Write-Host "🛑 Stopping daily pattern drills task..." -ForegroundColor Yellow
        Stop-ScheduledTask -TaskName `$TaskName
        Write-Host "✅ Task stopped" -ForegroundColor Green
    }
    "status" {
        Write-Host "📊 Daily Pattern Drills Task Status:" -ForegroundColor Cyan
        `$Task = Get-ScheduledTask -TaskName `$TaskName -ErrorAction SilentlyContinue
        if (`$Task) {
            Write-Host "  State: `$(`$Task.State)" -ForegroundColor White
            Write-Host "  Last Run: `$(`$Task.LastRunTime)" -ForegroundColor White
            Write-Host "  Next Run: `$(`$Task.NextRunTime)" -ForegroundColor White
            Write-Host "  Last Result: `$(`$Task.LastTaskResult)" -ForegroundColor White
        } else {
            Write-Host "  Task not found" -ForegroundColor Red
        }
    }
    "logs" {
        Write-Host "📋 Recent Pattern Drill Results:" -ForegroundColor Cyan
        `$LatestResults = Get-ChildItem "artifacts\canary-pattern-results.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (`$LatestResults) {
            Write-Host "  Latest Results: `$(`$LatestResults.Name) (`$(`$LatestResults.LastWriteTime))" -ForegroundColor White
            `$Results = Get-Content `$LatestResults.FullName -Raw | ConvertFrom-Json
            Write-Host "  Total Events: `$(`$Results.pattern_results | Measure-Object count -Sum).Sum" -ForegroundColor White
            Write-Host "  Test Duration: `$(`$Results.total_duration) seconds" -ForegroundColor White
        } else {
            Write-Host "  No results found" -ForegroundColor Yellow
        }
    }
    "run-now" {
        Write-Host "🏃 Running pattern drills now..." -ForegroundColor Green
        pwsh -File "$ScriptPath" -Pattern All -Duration 300 -Analyze
    }
}
"@

$ManagementScriptPath = "scripts\manage-daily-pattern-drills.ps1"
Set-Content -Path $ManagementScriptPath -Value $ManagementScript -Encoding UTF8
Write-Host "✅ Management script created: $ManagementScriptPath" -ForegroundColor Green

# Create verification script
$VerificationScript = @"
# Daily Pattern Drills Verification Script
# Verifies the automated daily pattern drills are working correctly

Write-Host "🔍 Verifying Daily Pattern Drills Automation..." -ForegroundColor Cyan

# Check if task exists
`$Task = Get-ScheduledTask -TaskName "$TaskName" -ErrorAction SilentlyContinue
if (-not `$Task) {
    Write-Host "❌ Scheduled task not found" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Scheduled task exists" -ForegroundColor Green

# Check task configuration
Write-Host "📋 Task Configuration:" -ForegroundColor Cyan
Write-Host "  State: `$(`$Task.State)" -ForegroundColor White
Write-Host "  Last Run: `$(`$Task.LastRunTime)" -ForegroundColor White
Write-Host "  Next Run: `$(`$Task.NextRunTime)" -ForegroundColor White

# Check if artifacts directory exists
if (-not (Test-Path "artifacts")) {
    Write-Host "⚠️ Artifacts directory not found" -ForegroundColor Yellow
} else {
    Write-Host "✅ Artifacts directory exists" -ForegroundColor Green
}

# Check for recent results
`$RecentResults = Get-ChildItem "artifacts\canary-pattern-results.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (`$RecentResults) {
    `$Age = (Get-Date) - `$RecentResults.LastWriteTime
    Write-Host "📊 Latest Results: `$(`$RecentResults.Name) (`$(`$Age.TotalHours.ToString('F1')) hours ago)" -ForegroundColor White
    
    if (`$Age.TotalHours -lt 25) {
        Write-Host "✅ Recent results found" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Results are older than 25 hours" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ No pattern drill results found" -ForegroundColor Yellow
}

Write-Host "🎯 Verification Complete!" -ForegroundColor Green
"@

$VerificationScriptPath = "scripts\verify-daily-pattern-drills.ps1"
Set-Content -Path $VerificationScriptPath -Value $VerificationScript -Encoding UTF8
Write-Host "✅ Verification script created: $VerificationScriptPath" -ForegroundColor Green

# Test the task creation
Write-Host "`n🧪 Testing task creation..." -ForegroundColor Yellow
$TestTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($TestTask) {
    Write-Host "✅ Task verification successful" -ForegroundColor Green
    Write-Host "📊 Task Status: $($TestTask.State)" -ForegroundColor Cyan
} else {
    Write-Host "❌ Task verification failed" -ForegroundColor Red
}

Write-Host "`n🎯 Daily Pattern Drills Automation Setup Complete!" -ForegroundColor Green
Write-Host "📋 Summary:" -ForegroundColor Cyan
Write-Host "  Scheduled Task: $TaskName" -ForegroundColor White
Write-Host "  Management Script: scripts\manage-daily-pattern-drills.ps1" -ForegroundColor White
Write-Host "  Verification Script: scripts\verify-daily-pattern-drills.ps1" -ForegroundColor White
Write-Host "  Schedule: Daily at $StartTime" -ForegroundColor White

Write-Host "`n📝 Usage Examples:" -ForegroundColor Yellow
Write-Host "  Check status: pwsh -File scripts\manage-daily-pattern-drills.ps1 -Action status" -ForegroundColor White
Write-Host "  Run now: pwsh -File scripts\manage-daily-pattern-drills.ps1 -Action run-now" -ForegroundColor White
Write-Host "  View logs: pwsh -File scripts\manage-daily-pattern-drills.ps1 -Action logs" -ForegroundColor White
Write-Host "  Verify setup: pwsh -File scripts\verify-daily-pattern-drills.ps1" -ForegroundColor White

Write-Host "`n🎭 Role: Cursor-Local (Observability Copilot) - Daily Pattern Drills Automation Complete" -ForegroundColor Magenta
