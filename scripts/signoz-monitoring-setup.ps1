# SigNoz Monitoring Setup Script
# Configures scheduled canary generation and monitoring

param(
    [switch]$SetupScheduledJob,
    [switch]$CreateTaskScheduler,
    [switch]$TestCanary,
    [switch]$ShowStatus,
    [switch]$Help
)

if ($Help) {
    Write-Host "SigNoz Monitoring Setup Script" -ForegroundColor Green
    Write-Host "Usage: .\signoz-monitoring-setup.ps1 [options]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -SetupScheduledJob    Create PowerShell scheduled job (every 4 hours)" -ForegroundColor White
    Write-Host "  -CreateTaskScheduler  Create Windows Task Scheduler task" -ForegroundColor White
    Write-Host "  -TestCanary          Generate test canary and verify" -ForegroundColor White
    Write-Host "  -ShowStatus          Show current monitoring status" -ForegroundColor White
    Write-Host "  -Help                Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\signoz-monitoring-setup.ps1 -SetupScheduledJob" -ForegroundColor White
    Write-Host "  .\signoz-monitoring-setup.ps1 -TestCanary" -ForegroundColor White
    Write-Host "  .\signoz-monitoring-setup.ps1 -ShowStatus" -ForegroundColor White
    exit 0
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if ($SetupScheduledJob) {
    Write-Host "`n=== Setting Up PowerShell Scheduled Job ===" -ForegroundColor Green
    
    if (-not (Test-Administrator)) {
        Write-Host "✗ Administrator privileges required for scheduled job creation" -ForegroundColor Red
        Write-Host "  Please run PowerShell as Administrator" -ForegroundColor Yellow
        exit 1
    }
    
    try {
        # Remove existing job if it exists
        $existingJob = Get-ScheduledJob -Name "SigNozCanary" -ErrorAction SilentlyContinue
        if ($existingJob) {
            Unregister-ScheduledJob -Name "SigNozCanary" -Force
            Write-Host "✓ Removed existing scheduled job" -ForegroundColor Yellow
        }
        
        # Create trigger for every 4 hours
        $trigger = New-JobTrigger -Daily -At "00:00", "04:00", "08:00", "12:00", "16:00", "20:00"
        
        # Create script block
        $scriptBlock = {
            Set-Location "C:\otel"
            $result = pwsh -NoLogo -NoProfile -Command "./scripts/signoz-canary-monitor.ps1 -GenerateCanary" 2>&1
            Write-Output "SigNoz Canary Job - $(Get-Date): $result"
        }
        
        # Register scheduled job
        Register-ScheduledJob -Name "SigNozCanary" -Trigger $trigger -ScriptBlock $scriptBlock -RunNow
        
        Write-Host "✓ PowerShell scheduled job created" -ForegroundColor Green
        Write-Host "  Name: SigNozCanary" -ForegroundColor Gray
        Write-Host "  Schedule: Every 4 hours (00:00, 04:00, 08:00, 12:00, 16:00, 20:00)" -ForegroundColor Gray
        Write-Host "  Script: C:\otel\scripts\signoz-canary-monitor.ps1 -GenerateCanary" -ForegroundColor Gray
        
    } catch {
        Write-Host "✗ Failed to create scheduled job" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($CreateTaskScheduler) {
    Write-Host "`n=== Creating Task Scheduler Task ===" -ForegroundColor Green
    
    try {
        # Remove existing task if it exists
        $existingTask = Get-ScheduledTask -TaskName "SigNozCanary" -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName "SigNozCanary" -Confirm:$false
            Write-Host "✓ Removed existing Task Scheduler task" -ForegroundColor Yellow
        }
        
        # Create action
        $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoLogo -NoProfile -Command `"C:\otel\scripts\signoz-canary-monitor.ps1 -GenerateCanary`"" -WorkingDirectory "C:\otel"
        
        # Create trigger (every 4 hours)
        $trigger = New-ScheduledTaskTrigger -Daily -At "00:00" -RepetitionInterval (New-TimeSpan -Hours 4) -RepetitionDuration (New-TimeSpan -Days 365)
        
        # Create settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        # Register task
        Register-ScheduledTask -TaskName "SigNozCanary" -Action $action -Trigger $trigger -Settings $settings -Description "Generate SigNoz canary test logs every 4 hours"
        
        Write-Host "✓ Task Scheduler task created" -ForegroundColor Green
        Write-Host "  Name: SigNozCanary" -ForegroundColor Gray
        Write-Host "  Schedule: Every 4 hours starting at 00:00" -ForegroundColor Gray
        Write-Host "  Command: pwsh.exe with canary generation script" -ForegroundColor Gray
        
    } catch {
        Write-Host "✗ Failed to create Task Scheduler task" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($TestCanary) {
    Write-Host "`n=== Testing Canary Generation ===" -ForegroundColor Green
    
    # Generate canary
    Write-Host "Generating canary..." -ForegroundColor Yellow
    $result = pwsh -NoLogo -NoProfile -Command "./scripts/signoz-canary-monitor.ps1 -GenerateCanary" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Canary generated successfully" -ForegroundColor Green
        
        # Check recent logs
        Write-Host "`nChecking recent logs..." -ForegroundColor Yellow
        pwsh -NoLogo -NoProfile -Command "./scripts/signoz-canary-monitor.ps1 -CheckRecent"
        
        # Verify SigNoz connectivity
        Write-Host "`nVerifying SigNoz connectivity..." -ForegroundColor Yellow
        pwsh -NoLogo -NoProfile -Command "./scripts/signoz-canary-monitor.ps1 -VerifySigNoz"
        
    } else {
        Write-Host "✗ Canary generation failed" -ForegroundColor Red
        Write-Host "  Error: $result" -ForegroundColor Red
    }
}

if ($ShowStatus) {
    Write-Host "`n=== Monitoring Status ===" -ForegroundColor Green
    
    # Check PowerShell scheduled jobs
    Write-Host "`nPowerShell Scheduled Jobs:" -ForegroundColor Yellow
    $jobs = Get-ScheduledJob -Name "SigNozCanary" -ErrorAction SilentlyContinue
    if ($jobs) {
        Write-Host "✓ SigNozCanary job exists" -ForegroundColor Green
        Write-Host "  Next Run: $($jobs.NextRun)" -ForegroundColor Gray
        Write-Host "  Last Run: $($jobs.LastRun)" -ForegroundColor Gray
    } else {
        Write-Host "✗ No SigNozCanary scheduled job found" -ForegroundColor Red
    }
    
    # Check Task Scheduler tasks
    Write-Host "`nTask Scheduler Tasks:" -ForegroundColor Yellow
    $tasks = Get-ScheduledTask -TaskName "SigNozCanary" -ErrorAction SilentlyContinue
    if ($tasks) {
        Write-Host "✓ SigNozCanary task exists" -ForegroundColor Green
        Write-Host "  State: $($tasks.State)" -ForegroundColor Gray
        Write-Host "  Last Run: $($tasks.LastRunTime)" -ForegroundColor Gray
    } else {
        Write-Host "✗ No SigNozCanary Task Scheduler task found" -ForegroundColor Red
    }
    
    # Check recent canary logs
    Write-Host "`nRecent Canary Logs:" -ForegroundColor Yellow
    if (Test-Path 'C:\logs\test.log') {
        $recentLogs = Get-Content -Path 'C:\logs\test.log' -Tail 3
        foreach ($log in $recentLogs) {
            try {
                $logObj = $log | ConvertFrom-Json
                if ($logObj.message -like "*SigNoz test*") {
                    Write-Host "  [$($logObj.timestamp)] Test ID: $($logObj.test_id)" -ForegroundColor White
                }
            } catch {
                # Skip non-JSON lines
            }
        }
    } else {
        Write-Host "✗ No canary log file found" -ForegroundColor Red
    }
    
    # Check SigNoz connectivity
    Write-Host "`nSigNoz Connectivity:" -ForegroundColor Yellow
    pwsh -NoLogo -NoProfile -Command "./scripts/signoz-canary-monitor.ps1 -VerifySigNoz"
}

# If no parameters provided, show help
if (-not ($SetupScheduledJob -or $CreateTaskScheduler -or $TestCanary -or $ShowStatus)) {
    Write-Host "SigNoz Monitoring Setup Script" -ForegroundColor Green
    Write-Host "Use -Help for usage information" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Quick setup:" -ForegroundColor Cyan
    Write-Host "  .\signoz-monitoring-setup.ps1 -SetupScheduledJob" -ForegroundColor White
    Write-Host "  .\signoz-monitoring-setup.ps1 -TestCanary" -ForegroundColor White
    Write-Host "  .\signoz-monitoring-setup.ps1 -ShowStatus" -ForegroundColor White
}
