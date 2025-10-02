# Create Scheduled Task for Automated Service Monitoring
# This script sets up a Windows scheduled task to run continuous monitoring

param(
    [string]$TaskName = "OTel-Service-Monitoring",
    [string]$ScriptPath = "C:\otel\scripts\automated-service-monitoring.ps1",
    [int]$IntervalMinutes = 5
)

Write-Host "📅 Setting up Scheduled Task for Service Monitoring" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script requires administrator privileges" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    exit 1
}

# Create the scheduled task action
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$ScriptPath`" -Continuous -CheckIntervalSeconds 300"

# Create the scheduled task trigger (every 5 minutes)
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 365)

# Create the scheduled task settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

# Create the scheduled task principal (run as SYSTEM)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the scheduled task
try {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Automated monitoring of OTel observability stack services"
    
    Write-Host "✅ Scheduled task '$TaskName' created successfully" -ForegroundColor Green
    Write-Host "   - Runs every $IntervalMinutes minutes" -ForegroundColor Gray
    Write-Host "   - Monitors SigNoz, Windows Collector, and Docker services" -ForegroundColor Gray
    Write-Host "   - Logs to artifacts/service-monitoring.log" -ForegroundColor Gray
    Write-Host "   - Alerts saved to artifacts/alerts-*.json" -ForegroundColor Gray
    
    # Start the task immediately
    Start-ScheduledTask -TaskName $TaskName
    Write-Host "✅ Task started successfully" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n📋 Management Commands:" -ForegroundColor Cyan
Write-Host "  View task: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
Write-Host "  Start task: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
Write-Host "  Stop task: Stop-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
Write-Host "  Remove task: Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false" -ForegroundColor White

Write-Host "`n📊 Monitoring Output:" -ForegroundColor Cyan
Write-Host "  Log file: artifacts/service-monitoring.log" -ForegroundColor White
Write-Host "  Alerts: artifacts/alerts-*.json" -ForegroundColor White
Write-Host "  Health checks: artifacts/health-check-*.json" -ForegroundColor White

Write-Host "`n✅ Automated Service Monitoring Setup Complete!" -ForegroundColor Green