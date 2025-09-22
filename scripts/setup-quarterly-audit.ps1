# Setup Quarterly Archive Audit Scheduled Task
# Purpose: Create Windows scheduled task to run quarterly archive audit

param(
    [switch]$Remove = $false
)

if ($Remove) {
    Write-Host "🗑️  Removing quarterly audit scheduled task..." -ForegroundColor Yellow
    
    try {
        Unregister-ScheduledTask -TaskName "QuarterlyArchiveAudit" -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "✅ Scheduled task removed successfully" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Task may not have existed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    exit 0
}

Write-Host "📅 Setting up quarterly archive audit scheduled task..." -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "❌ This script must be run as Administrator to create scheduled tasks" -ForegroundColor Red
    Write-Host "   Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Gray
    exit 1
}

# Define task parameters
$taskName = "QuarterlyArchiveAudit"
$taskDescription = "Quarterly review of archived runbooks to determine if they can be safely deleted"
$scriptPath = Join-Path $PWD "scripts\quarterly-archive-audit.ps1"

# Check if script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Audit script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Task Details:" -ForegroundColor Yellow
Write-Host "  • Name: $taskName" -ForegroundColor Gray
Write-Host "  • Script: $scriptPath" -ForegroundColor Gray
Write-Host "  • Schedule: Quarterly (Jan 15, Apr 15, Jul 15, Oct 15)" -ForegroundColor Gray
Write-Host ""

# Create trigger for quarterly execution
$trigger = New-ScheduledTaskTrigger -At "2025-01-15 09:00" -RepetitionInterval (New-TimeSpan -Days 90) -RepetitionDuration (New-TimeSpan -Days 365)

# Create action to run PowerShell script
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# Create task settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Create principal (run as current user)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType InteractiveToken

# Create the task
try {
    Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -Principal $principal -Description $taskDescription -Force
    
    Write-Host "✅ Scheduled task created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📅 Next execution: January 15, 2025 at 9:00 AM" -ForegroundColor Cyan
    Write-Host "🔄 Repeats every 90 days (quarterly)" -ForegroundColor Cyan
    Write-Host ""
    
    # Show task details
    $task = Get-ScheduledTask -TaskName $taskName
    Write-Host "📋 Task Status:" -ForegroundColor Yellow
    Write-Host "  • State: $($task.State)" -ForegroundColor Gray
    Write-Host "  • Last Run: $($task.LastRunTime)" -ForegroundColor Gray
    Write-Host "  • Next Run: $($task.NextRunTime)" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔧 Manual Commands:" -ForegroundColor Yellow
Write-Host "  • Run now: .\scripts\quarterly-archive-audit.ps1 -DryRun" -ForegroundColor Gray
Write-Host "  • Remove task: .\scripts\setup-quarterly-audit.ps1 -Remove" -ForegroundColor Gray
Write-Host "  • View task: Get-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray

Write-Host ""
Write-Host "✅ Quarterly audit setup complete!" -ForegroundColor Green
