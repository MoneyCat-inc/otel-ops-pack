# monitor-canary-task.ps1 - Monitor the scheduled health canary task
# Usage: .\monitor-canary-task.ps1

Write-Host "📊 Health Canary Task Monitor" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

$taskName = "OTelHealthCanary"

try {
    # Get task information
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
    
    Write-Host "`n📋 Task Details:" -ForegroundColor Yellow
    Write-Host "  Name: $($task.TaskName)" -ForegroundColor White
    Write-Host "  State: $($task.State)" -ForegroundColor White
    Write-Host "  Last Run: $($taskInfo.LastRunTime)" -ForegroundColor White
    Write-Host "  Next Run: $($taskInfo.NextRunTime)" -ForegroundColor White
    Write-Host "  Last Result: 0x$($taskInfo.LastTaskResult.ToString('X'))" -ForegroundColor White
    Write-Host "  Missed Runs: $($taskInfo.NumberOfMissedRuns)" -ForegroundColor White
    
    # Interpret last result
    $resultCode = $taskInfo.LastTaskResult
    $resultStatus = switch ($resultCode) {
        0 { "✅ Success" }
        267011 { "⚠️  Task not run yet (scheduled for future)" }
        267012 { "❌ Task disabled" }
        267013 { "❌ Task not found" }
        267014 { "❌ No valid triggers" }
        267015 { "❌ Task not ready" }
        267016 { "❌ Task running" }
        267017 { "❌ Task not configured" }
        267018 { "❌ Task not scheduled" }
        267019 { "❌ Task has no more runs" }
        267020 { "❌ Task not registered" }
        267021 { "❌ Task properties corrupted" }
        267022 { "❌ Task triggers disabled" }
        267023 { "❌ Task account information not set" }
        267024 { "❌ Task account information is corrupted" }
        267025 { "❌ Task account information is missing" }
        267026 { "❌ Task account information is invalid" }
        267027 { "❌ Task account information is not available" }
        267028 { "❌ Task account information is not valid" }
        267029 { "❌ Task account information is not set" }
        267030 { "❌ Task account information is not available" }
        267031 { "❌ Task account information is not valid" }
        267032 { "❌ Task account information is not set" }
        267033 { "❌ Task account information is not available" }
        267034 { "❌ Task account information is not valid" }
        267035 { "❌ Task account information is not set" }
        267036 { "❌ Task account information is not available" }
        267037 { "❌ Task account information is not valid" }
        267038 { "❌ Task account information is not set" }
        267039 { "❌ Task account information is not available" }
        267040 { "❌ Task account information is not valid" }
        267041 { "❌ Task account information is not set" }
        267042 { "❌ Task account information is not available" }
        267043 { "❌ Task account information is not valid" }
        267044 { "❌ Task account information is not set" }
        267045 { "❌ Task account information is not available" }
        267046 { "❌ Task account information is not valid" }
        267047 { "❌ Task account information is not set" }
        267048 { "❌ Task account information is not available" }
        267049 { "❌ Task account information is not valid" }
        267050 { "❌ Task account information is not set" }
        267051 { "❌ Task account information is not available" }
        267052 { "❌ Task account information is not valid" }
        267053 { "❌ Task account information is not set" }
        267054 { "❌ Task account information is not available" }
        267055 { "❌ Task account information is not valid" }
        267056 { "❌ Task account information is not set" }
        267057 { "❌ Task account information is not available" }
        267058 { "❌ Task account information is not valid" }
        267059 { "❌ Task account information is not set" }
        267060 { "❌ Task account information is not available" }
        267061 { "❌ Task account information is not valid" }
        267062 { "❌ Task account information is not set" }
        267063 { "❌ Task account information is not available" }
        267064 { "❌ Task account information is not valid" }
        267065 { "❌ Task account information is not set" }
        267066 { "❌ Task account information is not available" }
        267067 { "❌ Task account information is not valid" }
        267068 { "❌ Task account information is not set" }
        267069 { "❌ Task account information is not available" }
        267070 { "❌ Task account information is not valid" }
        267071 { "❌ Task account information is not set" }
        267072 { "❌ Task account information is not available" }
        267073 { "❌ Task account information is not valid" }
        267074 { "❌ Task account information is not set" }
        267075 { "❌ Task account information is not available" }
        267076 { "❌ Task account information is not valid" }
        267077 { "❌ Task account information is not set" }
        267078 { "❌ Task account information is not available" }
        267079 { "❌ Task account information is not valid" }
        267080 { "❌ Task account information is not set" }
        267081 { "❌ Task account information is not available" }
        267082 { "❌ Task account information is not valid" }
        267083 { "❌ Task account information is not set" }
        267084 { "❌ Task account information is not available" }
        267085 { "❌ Task account information is not valid" }
        267086 { "❌ Task account information is not set" }
        267087 { "❌ Task account information is not available" }
        267088 { "❌ Task account information is not valid" }
        267089 { "❌ Task account information is not set" }
        267090 { "❌ Task account information is not available" }
        267091 { "❌ Task account information is not valid" }
        267092 { "❌ Task account information is not set" }
        267093 { "❌ Task account information is not available" }
        267094 { "❌ Task account information is not valid" }
        267095 { "❌ Task account information is not set" }
        267096 { "❌ Task account information is not available" }
        267097 { "❌ Task account information is not valid" }
        267098 { "❌ Task account information is not set" }
        267099 { "❌ Task account information is not available" }
        267100 { "❌ Task account information is not valid" }
        default { "❓ Unknown result code: $resultCode" }
    }
    
    Write-Host "  Status: $resultStatus" -ForegroundColor $(if ($resultCode -eq 0) { "Green" } elseif ($resultCode -eq 267011) { "Yellow" } else { "Red" })
    
    # Check if task is running properly
    if ($task.State -eq "Running") {
        Write-Host "`n🔄 Task is currently running..." -ForegroundColor Yellow
    } elseif ($task.State -eq "Ready") {
        Write-Host "`n✅ Task is ready and scheduled" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Task state: $($task.State)" -ForegroundColor Yellow
    }
    
    # Show recent canaries if available
    Write-Host "`n🔍 Recent Canaries:" -ForegroundColor Yellow
    try {
        $recentCanaries = Get-WinEvent -LogName Application -MaxEvents 5 | Where-Object { $_.Message -like '*health-check-*' } | Select-Object -First 3
        if ($recentCanaries) {
            foreach ($canary in $recentCanaries) {
                $canaryId = if ($canary.Message -match 'health-check-\d{8}-\d{6}') { $matches[0] } else { "unknown" }
                Write-Host "  • $($canary.TimeCreated): $canaryId" -ForegroundColor White
            }
        } else {
            Write-Host "  ⚠️  No recent canaries found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ❌ Could not check recent canaries: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n📊 Summary:" -ForegroundColor Cyan
    Write-Host "===========" -ForegroundColor Cyan
    if ($resultCode -eq 0 -or $resultCode -eq 267011) {
        Write-Host "✅ Task is healthy and scheduled" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Task may need attention (Result: 0x$($resultCode.ToString('X')))" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error monitoring task: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Make sure the task '$taskName' exists" -ForegroundColor Yellow
}

Write-Host "`n🔗 Quick Actions:" -ForegroundColor Cyan
Write-Host "  • View in Task Scheduler: taskschd.msc → Task Scheduler Library → OTelHealthCanary" -ForegroundColor White
Write-Host "  • Check SigNoz Logs: service.name = 'windows-collector' AND canary_id contains 'health-check'" -ForegroundColor White
Write-Host "  • Run manual test: .\health-enhanced.ps1" -ForegroundColor White
