# See C:\otel\docs\comfort cat
# Verify Scheduled Tasks Deployment
# Quick verification script for OTel monitoring tasks

Write-Host "🔍 OTel Scheduled Tasks Verification" -ForegroundColor Cyan
Write-Host "Checking deployment status and task health" -ForegroundColor Gray
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
Write-Host "🔐 Administrator Privileges: $(if($isAdmin) {'✅ Yes'} else {'❌ No'})" -ForegroundColor $(if($isAdmin) {'Green'} else {'Red'})

# List OTel tasks
Write-Host ""
Write-Host "📋 OTel Scheduled Tasks:" -ForegroundColor Cyan
$tasks = Get-ScheduledTask -TaskName "*OTel*" -ErrorAction SilentlyContinue
if ($tasks) {
    foreach ($task in $tasks) {
        $status = $task.State
        $lastRun = (Get-ScheduledTaskInfo -TaskName $task.TaskName -ErrorAction SilentlyContinue).LastRunTime
        $nextRun = (Get-ScheduledTaskInfo -TaskName $task.TaskName -ErrorAction SilentlyContinue).NextRunTime
        
        Write-Host "   ✅ $($task.TaskName)" -ForegroundColor Green
        Write-Host "      Status: $status" -ForegroundColor White
        Write-Host "      Last Run: $($lastRun.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
        Write-Host "      Next Run: $($nextRun.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    }
} else {
    Write-Host "   ❌ No OTel tasks found" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 To create tasks, run as Administrator:" -ForegroundColor Blue
    Write-Host "   pwsh -File scripts\setup-scheduled-monitoring-admin.ps1" -ForegroundColor Gray
}

# Check recent artifacts
Write-Host ""
Write-Host "📁 Recent Monitoring Artifacts:" -ForegroundColor Cyan
$artifacts = Get-ChildItem -Path "artifacts" -Filter "*.json" -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 5

if ($artifacts) {
    foreach ($artifact in $artifacts) {
        $age = (Get-Date) - $artifact.LastWriteTime
        $ageStr = if ($age.TotalMinutes -lt 60) { 
            "$([math]::Round($age.TotalMinutes, 1)) min ago" 
        } elseif ($age.TotalHours -lt 24) { 
            "$([math]::Round($age.TotalHours, 1)) hours ago" 
        } else { 
            "$([math]::Round($age.TotalDays, 1)) days ago" 
        }
        
        Write-Host "   📄 $($artifact.Name) ($ageStr)" -ForegroundColor White
    }
} else {
    Write-Host "   ❌ No monitoring artifacts found" -ForegroundColor Red
}

# Check SigNoz connectivity
Write-Host ""
Write-Host "🌐 SigNoz Connectivity:" -ForegroundColor Cyan
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 3
    Write-Host "   ✅ SigNoz healthy at http://localhost:8080" -ForegroundColor Green
} catch {
    Write-Host "   ❌ SigNoz not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Check OTLP endpoints
Write-Host ""
Write-Host "🔗 OTLP Endpoints:" -ForegroundColor Cyan
$grpcTest = Test-NetConnection -ComputerName localhost -Port 14317 -WarningAction SilentlyContinue
$httpTest = Test-NetConnection -ComputerName localhost -Port 14318 -WarningAction SilentlyContinue

Write-Host "   OTLP gRPC (14317): $(if($grpcTest.TcpTestSucceeded) {'✅ Accessible'} else {'❌ Unreachable'})" -ForegroundColor $(if($grpcTest.TcpTestSucceeded) {'Green'} else {'Red'})
Write-Host "   OTLP HTTP (14318): $(if($httpTest.TcpTestSucceeded) {'✅ Accessible'} else {'❌ Unreachable'})" -ForegroundColor $(if($httpTest.TcpTestSucceeded) {'Green'} else {'Red'})

# Test task execution (if tasks exist)
if ($tasks) {
    Write-Host ""
    Write-Host "🧪 Test Task Execution:" -ForegroundColor Cyan
    Write-Host "   To test a task manually, run:" -ForegroundColor Gray
    Write-Host "   Start-ScheduledTask -TaskName 'OTel-QuickHealthCheck'" -ForegroundColor White
    Write-Host ""
    Write-Host "   To check task history:" -ForegroundColor Gray
    Write-Host "   Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TaskScheduler/Operational'; ID=200,201} | Where-Object {`$_.Message -like '*OTel*'}" -ForegroundColor White
}

Write-Host ""
Write-Host "💡 Quick Commands:" -ForegroundColor Blue
Write-Host "   Deploy tasks: pwsh -File scripts\setup-scheduled-monitoring-admin.ps1" -ForegroundColor Gray
Write-Host "   List tasks: Get-ScheduledTask -TaskName '*OTel*'" -ForegroundColor Gray
Write-Host "   Test task: Start-ScheduledTask -TaskName 'OTel-QuickHealthCheck'" -ForegroundColor Gray
Write-Host "   Check artifacts: Get-ChildItem artifacts\*.json | Sort-Object LastWriteTime -Descending" -ForegroundColor Gray
