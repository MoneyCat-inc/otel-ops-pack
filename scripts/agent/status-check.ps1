# scripts/agent/status-check.ps1
# Quick status checker with progress indicators and estimated completion times
# Updated to use shared progress indicators module

# Import progress indicators module
. .\scripts\progress-indicators.ps1

param(
    [switch]$Detailed,
    [switch]$Continuous
)

$ErrorActionPreference = "Stop"

function Show-StatusProgress {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$Seconds,
        [int]$Id = 1
    )
    
    $totalSteps = $Seconds * 2  # Update every 500ms
    for ($i = 0; $i -le $totalSteps; $i++) {
        $percentComplete = ($i / $totalSteps) * 100
        $remainingTime = [Math]::Max(0, $Seconds - ($i * 0.5))
        $currentStatus = "$Status (ETA: $([Math]::Round($remainingTime, 1))s)"
        
        Write-Progress -Activity $Activity -Status $currentStatus -PercentComplete $percentComplete -Id $Id
        Start-Sleep -Milliseconds 500
    }
    Write-Progress -Activity $Activity -Completed -Id $Id
}

function Get-AgentStatus {
    param([bool]$ShowProgress = $true)
    
    if ($ShowProgress) {
        Write-Host "[STATUS] Checking agent status..." -ForegroundColor Yellow
        $spinnerJob = Start-SpinnerJob -Message "Reading status files..." -UpdateIntervalMs 150
    }
    
    $status = @{
        timestamp = (Get-Date).ToString("o")
        lock = $false
        status = "unknown"
        sections = @{}
        queue = @{}
        lastActivity = "unknown"
    }
    
    # Check lock file
    if (Test-Path ".agent/LOCK") {
        $status.lock = $true
        $status.status = "locked"
        $lockContent = Get-Content ".agent/LOCK" -Raw
        $status.lockReason = $lockContent.Trim()
    }
    
    # Check status.json
    if (Test-Path ".agent/status.json") {
        try {
            $statusData = Get-Content ".agent/status.json" -Raw | ConvertFrom-Json
            $status.sections = $statusData.sections
            $status.lastUpdate = $statusData.updatedAt
        } catch {
            $status.status = "corrupted"
        }
    }
    
    # Check agent queue
    if (Test-Path ".agent/agent_queue.json") {
        try {
            $queueData = Get-Content ".agent/agent_queue.json" -Raw | ConvertFrom-Json
            $status.queue = @{
                total = $queueData.jobs.Count
                queued = ($queueData.jobs | Where-Object { $_.status -eq "queued" }).Count
                running = ($queueData.jobs | Where-Object { $_.status -eq "running" }).Count
                completed = ($queueData.jobs | Where-Object { $_.status -eq "completed" }).Count
                failed = ($queueData.jobs | Where-Object { $_.status -eq "failed" }).Count
            }
        } catch {
            $status.queue = @{ error = "corrupted" }
        }
    }
    
    # Check last activity from TASKS.md
    if (Test-Path "TASKS.md") {
        $lastLine = Get-Content "TASKS.md" -Tail 1
        $status.lastActivity = $lastLine
    }
    
    if ($ShowProgress) {
        Stop-SpinnerJob -Job $spinnerJob
    }
    
    return $status
}

function Display-Status {
    param([hashtable]$Status, [bool]$Detailed)
    
    Write-Host "`n[STATUS REPORT] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    
    # Lock status
    if ($Status.lock) {
        Write-Host "🔒 AGENT STATUS: LOCKED" -ForegroundColor Red
        Write-Host "   Reason: $($Status.lockReason)" -ForegroundColor Yellow
        Write-Host "   Remove .agent/LOCK to resume operations" -ForegroundColor Yellow
    } else {
        Write-Host "🟢 AGENT STATUS: ACTIVE" -ForegroundColor Green
    }
    
    # Section statuses
    if ($Status.sections.Count -gt 0) {
        Write-Host "`n📊 SECTION STATUS:" -ForegroundColor White
        foreach ($section in $Status.sections.PSObject.Properties.Name) {
            $sectionData = $Status.sections.$section
            $icon = if ($sectionData.ok) { "✅" } else { "❌" }
            $color = if ($sectionData.ok) { "Green" } else { "Red" }
            Write-Host "   $icon $($section.ToUpper()): $($sectionData.detail)" -ForegroundColor $color
            if ($sectionData.ts) {
                Write-Host "      Last update: $($sectionData.ts)" -ForegroundColor Gray
            }
        }
    }
    
    # Queue status
    if ($Status.queue.Count -gt 0 -and -not $Status.queue.error) {
        Write-Host "`n📋 TASK QUEUE:" -ForegroundColor White
        Write-Host "   Total tasks: $($Status.queue.total)" -ForegroundColor Gray
        Write-Host "   Queued: $($Status.queue.queued)" -ForegroundColor Yellow
        Write-Host "   Running: $($Status.queue.running)" -ForegroundColor Blue
        Write-Host "   Completed: $($Status.queue.completed)" -ForegroundColor Green
        Write-Host "   Failed: $($Status.queue.failed)" -ForegroundColor Red
    }
    
    # Last activity
    if ($Status.lastActivity -ne "unknown") {
        Write-Host "`n📝 LAST ACTIVITY:" -ForegroundColor White
        Write-Host "   $($Status.lastActivity)" -ForegroundColor Gray
    }
    
    if ($Detailed) {
        Write-Host "`n🔍 DETAILED INFO:" -ForegroundColor White
        Write-Host "   Status file: $(if (Test-Path '.agent/status.json') { 'Present' } else { 'Missing' })" -ForegroundColor Gray
        Write-Host "   Queue file: $(if (Test-Path '.agent/agent_queue.json') { 'Present' } else { 'Missing' })" -ForegroundColor Gray
        Write-Host "   Tasks log: $(if (Test-Path 'TASKS.md') { 'Present' } else { 'Missing' })" -ForegroundColor Gray
        Write-Host "   Lock file: $(if (Test-Path '.agent/LOCK') { 'Present' } else { 'Missing' })" -ForegroundColor Gray
    }
    
    Write-Host "`n================================================" -ForegroundColor Cyan
}

# Main execution
Write-Host "[codex-local] Status Checker with Progress Indicators" -ForegroundColor Cyan
Write-Host "[codex-local] ==========================================" -ForegroundColor Cyan

if ($Continuous) {
    Write-Host "[STATUS] Starting continuous monitoring (press Ctrl+C to stop)" -ForegroundColor Yellow
    $cycleCount = 0
    
    while ($true) {
        $cycleCount++
        Write-Host "`n[STATUS] Cycle #$cycleCount - $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
        
        $status = Get-AgentStatus -ShowProgress $true
        Display-Status -Status $status -Detailed $Detailed
        
        Write-Host "[STATUS] Waiting 30 seconds for next check..." -ForegroundColor Yellow
        Show-StatusProgress -Activity "Continuous Monitoring" -Status "Next check in" -Seconds 30
    }
} else {
    $status = Get-AgentStatus -ShowProgress $true
    Display-Status -Status $status -Detailed $Detailed
}

Write-Host "[STATUS] Status check completed" -ForegroundColor Green
