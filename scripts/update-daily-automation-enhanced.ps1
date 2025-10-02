# Update Daily Automation with Enhanced Statistical Validation
# Modifies the existing daily automation to use enhanced validation

param(
    [string]$TaskName = "Daily Canary Pattern Drills",
    [switch]$Force = $false
)

# ECRR - Examine → Clean → Report → Role
Write-Host "🔍 Examine Daily Automation Enhancement - ECRR Framework" -ForegroundColor Cyan
Write-Host "🎭 Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

Write-Host "`n📊 Updating Daily Automation with Enhanced Statistical Validation" -ForegroundColor Green

# Check if task exists
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if (-not $ExistingTask) {
    Write-Host "❌ Task '$TaskName' not found. Please run setup-daily-pattern-drills.ps1 first." -ForegroundColor Red
    exit 1
}

if ($ExistingTask -and -not $Force) {
    Write-Host "⚠️ Task '$TaskName' already exists. Use -Force to update." -ForegroundColor Yellow
    Write-Host "Current task status: $($ExistingTask.State)" -ForegroundColor Cyan
    exit 1
}

# Stop and remove existing task
Write-Host "`n🛑 Stopping and removing existing task..." -ForegroundColor Yellow
try {
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "✅ Existing task removed" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Error removing existing task: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Create enhanced action with improved parameters
$EnhancedAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"scripts\canary-pattern-drills.ps1`" -Pattern All -Duration 600 -Analyze" -WorkingDirectory (Get-Location)

# Create the trigger (daily at 09:00)
$Trigger = New-ScheduledTaskTrigger -Daily -At "09:00"

# Create enhanced task settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 15)

# Create task principal (run as SYSTEM)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the enhanced scheduled task
try {
    Register-ScheduledTask -TaskName $TaskName -Action $EnhancedAction -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Daily automated canary pattern drills with enhanced statistical validation (600s duration, improved analysis)"
    
    Write-Host "✅ Enhanced daily automation task created successfully!" -ForegroundColor Green
    Write-Host "📋 Enhanced Task Details:" -ForegroundColor Cyan
    Write-Host "  Name: $TaskName" -ForegroundColor White
    Write-Host "  Schedule: Daily at 09:00" -ForegroundColor White
    Write-Host "  Duration: 600 seconds (10 minutes)" -ForegroundColor White
    Write-Host "  Enhanced Analysis: Enabled" -ForegroundColor White
    Write-Host "  Execution Limit: 15 minutes" -ForegroundColor White
    
} catch {
    Write-Host "❌ Failed to create enhanced scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Update management script with enhanced features
$EnhancedManagementScript = @"
# Enhanced Daily Pattern Drills Management Script
# Updated with enhanced statistical validation capabilities

param(
    [ValidateSet("start", "stop", "status", "logs", "run-now", "run-enhanced", "validate")]
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
        Write-Host "📊 Enhanced Daily Pattern Drills Task Status:" -ForegroundColor Cyan
        `$Task = Get-ScheduledTask -TaskName `$TaskName -ErrorAction SilentlyContinue
        if (`$Task) {
            Write-Host "  State: `$(`$Task.State)" -ForegroundColor White
            Write-Host "  Last Run: `$(`$Task.LastRunTime)" -ForegroundColor White
            Write-Host "  Next Run: `$(`$Task.NextRunTime)" -ForegroundColor White
            Write-Host "  Last Result: `$(`$Task.LastTaskResult)" -ForegroundColor White
            Write-Host "  Duration: 600 seconds (Enhanced)" -ForegroundColor White
        } else {
            Write-Host "  Task not found" -ForegroundColor Red
        }
    }
    "logs" {
        Write-Host "📋 Recent Enhanced Pattern Drill Results:" -ForegroundColor Cyan
        `$LatestResults = Get-ChildItem "artifacts\canary-pattern-results.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (`$LatestResults) {
            Write-Host "  Latest Results: `$(`$LatestResults.Name) (`$(`$LatestResults.LastWriteTime))" -ForegroundColor White
            `$Results = Get-Content `$LatestResults.FullName -Raw | ConvertFrom-Json
            Write-Host "  Total Events: `$(`$Results.pattern_results | Measure-Object count -Sum).Sum" -ForegroundColor White
            Write-Host "  Test Duration: `$(`$Results.total_duration) seconds" -ForegroundColor White
            
            # Show Hurst values with interpretation
            Write-Host "`n  Pattern Analysis:" -ForegroundColor Yellow
            foreach (`$Pattern in `$Results.pattern_results) {
                `$Hurst = `$Pattern.hurst_estimate
                `$Interpretation = if (`$Hurst -lt 0.4) { "Anti-persistent" } 
                                  elseif (`$Hurst -gt 0.6) { "Persistent" }
                                  else { "Random walk" }
                Write-Host "    `$(`$Pattern.pattern): H=`$Hurst (`$Interpretation)" -ForegroundColor White
            }
        } else {
            Write-Host "  No results found" -ForegroundColor Yellow
        }
    }
    "run-now" {
        Write-Host "🏃 Running pattern drills now (standard)..." -ForegroundColor Green
        pwsh -File "scripts/canary-pattern-drills.ps1" -Pattern All -Duration 300 -Analyze
    }
    "run-enhanced" {
        Write-Host "🚀 Running enhanced pattern drills now..." -ForegroundColor Green
        pwsh -File "scripts/canary-pattern-drills.ps1" -Pattern All -Duration 600 -Analyze
        Write-Host "`n📊 Running enhanced statistical validation..." -ForegroundColor Cyan
        pwsh -File "scripts/enhanced-statistical-validation.ps1" -MinSampleSize 50 -TestDuration 600 -GenerateReport
    }
    "validate" {
        Write-Host "🔍 Running enhanced statistical validation..." -ForegroundColor Green
        pwsh -File "scripts/enhanced-statistical-validation.ps1" -MinSampleSize 50 -TestDuration 600 -GenerateReport
        
        Write-Host "`n📋 Validation Summary:" -ForegroundColor Cyan
        `$ValidationResults = Get-Content "artifacts\enhanced-statistical-validation.json" -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
        if (`$ValidationResults) {
            Write-Host "  Validations: `$(`$ValidationResults.enhanced_results.Count)" -ForegroundColor White
            Write-Host "  Reliable Samples: `$(`$ValidationResults.reliability_metrics.reliable_samples)" -ForegroundColor White
            Write-Host "  Mean Hurst: `$(`$ValidationResults.statistical_summary.hurst_mean)" -ForegroundColor White
            Write-Host "  Mean CV: `$(`$ValidationResults.statistical_summary.cv_mean)" -ForegroundColor White
        }
    }
}
"@

$EnhancedManagementScriptPath = "scripts\manage-daily-pattern-drills-enhanced.ps1"
Set-Content -Path $EnhancedManagementScriptPath -Value $EnhancedManagementScript -Encoding UTF8
Write-Host "✅ Enhanced management script created: $EnhancedManagementScriptPath" -ForegroundColor Green

# Update verification script
$EnhancedVerificationScript = @"
# Enhanced Daily Pattern Drills Verification Script
# Updated to verify enhanced statistical validation capabilities

Write-Host "🔍 Verifying Enhanced Daily Pattern Drills Automation..." -ForegroundColor Cyan

# Check if task exists
`$Task = Get-ScheduledTask -TaskName "$TaskName" -ErrorAction SilentlyContinue
if (-not `$Task) {
    Write-Host "❌ Scheduled task not found" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Scheduled task exists" -ForegroundColor Green

# Check enhanced task configuration
Write-Host "📋 Enhanced Task Configuration:" -ForegroundColor Cyan
Write-Host "  State: `$(`$Task.State)" -ForegroundColor White
Write-Host "  Last Run: `$(`$Task.LastRunTime)" -ForegroundColor White
Write-Host "  Next Run: `$(`$Task.NextRunTime)" -ForegroundColor White
Write-Host "  Duration: 600 seconds (Enhanced)" -ForegroundColor White

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

# Check for enhanced validation results
`$EnhancedResults = Get-ChildItem "artifacts\enhanced-statistical-validation.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (`$EnhancedResults) {
    `$Age = (Get-Date) - `$EnhancedResults.LastWriteTime
    Write-Host "📈 Enhanced Validation: `$(`$EnhancedResults.Name) (`$(`$Age.TotalHours.ToString('F1')) hours ago)" -ForegroundColor White
    Write-Host "✅ Enhanced validation results found" -ForegroundColor Green
} else {
    Write-Host "⚠️ No enhanced validation results found" -ForegroundColor Yellow
}

Write-Host "🎯 Enhanced Verification Complete!" -ForegroundColor Green
"@

$EnhancedVerificationScriptPath = "scripts\verify-daily-pattern-drills-enhanced.ps1"
Set-Content -Path $EnhancedVerificationScriptPath -Value $EnhancedVerificationScript -Encoding UTF8
Write-Host "✅ Enhanced verification script created: $EnhancedVerificationScriptPath" -ForegroundColor Green

# Test the enhanced task creation
Write-Host "`n🧪 Testing enhanced task creation..." -ForegroundColor Yellow
$TestTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($TestTask) {
    Write-Host "✅ Enhanced task verification successful" -ForegroundColor Green
    Write-Host "📊 Task Status: $($TestTask.State)" -ForegroundColor Cyan
} else {
    Write-Host "❌ Enhanced task verification failed" -ForegroundColor Red
}

Write-Host "`n🎯 Enhanced Daily Automation Update Complete!" -ForegroundColor Green
Write-Host "📋 Summary:" -ForegroundColor Cyan
Write-Host "  Enhanced Task: $TaskName" -ForegroundColor White
Write-Host "  Duration: 600 seconds (10 minutes)" -ForegroundColor White
Write-Host "  Enhanced Management: scripts\manage-daily-pattern-drills-enhanced.ps1" -ForegroundColor White
Write-Host "  Enhanced Verification: scripts\verify-daily-pattern-drills-enhanced.ps1" -ForegroundColor White

Write-Host "`n📝 Enhanced Usage Examples:" -ForegroundColor Yellow
Write-Host "  Check status: pwsh -File scripts\manage-daily-pattern-drills-enhanced.ps1 -Action status" -ForegroundColor White
Write-Host "  Run enhanced: pwsh -File scripts\manage-daily-pattern-drills-enhanced.ps1 -Action run-enhanced" -ForegroundColor White
Write-Host "  Validate stats: pwsh -File scripts\manage-daily-pattern-drills-enhanced.ps1 -Action validate" -ForegroundColor White
Write-Host "  Verify setup: pwsh -File scripts\verify-daily-pattern-drills-enhanced.ps1" -ForegroundColor White

Write-Host "`n🎭 Role: Cursor-Local (Observability Copilot) - Enhanced Daily Automation Update Complete" -ForegroundColor Magenta
