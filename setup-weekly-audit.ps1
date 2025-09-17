# Weekly Auto-Audit Setup
# Creates hands-off evidence trail for compliance and change management

Write-Host "Setting up weekly auto-audit schedule..." -ForegroundColor Green

# Create scheduled task for weekly audit
$exe = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$script = 'C:\otel\make-audit-pack.ps1'
$A = New-ScheduledTaskAction -Execute $exe -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script`""
$T = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 02:20
$P = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

try {
    Register-ScheduledTask -TaskName "otel_audit_weekly" -Action $A -Trigger $T -Principal $P -Force
    Write-Host "✅ Weekly audit task created successfully" -ForegroundColor Green
    Write-Host "   Task: otel_audit_weekly" -ForegroundColor Cyan
    Write-Host "   Schedule: Every Sunday at 02:20" -ForegroundColor Cyan
    Write-Host "   User: SYSTEM (elevated)" -ForegroundColor Cyan
    Write-Host "   Script: $script" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Failed to create weekly audit task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`nWeekly audit will quietly create audit-pack_*.zip + sha256 files" -ForegroundColor Yellow
Write-Host "These can be attached to change logs, prove uptime, and show config lineage during reviews." -ForegroundColor Yellow
