# scripts/agent/status-premium.ps1 - Premium status checker with enhanced UX

param(
    [switch]$Detailed,
    [switch]$Continuous,
    [switch]$Quiet,
    [switch]$Json
)

$ErrorActionPreference = "Stop"

# Import utilities
. "$PSScriptRoot\utils\terminal.ps1"
. "$PSScriptRoot\utils\progress.ps1"
. "$PSScriptRoot\utils\logging.ps1"

function Get-AgentStatus {
    param([bool]$ShowProgress = $true)
    
    if ($ShowProgress -and -not $Quiet) {
        Write-Colored -Message "[STATUS] Checking agent status..." -Color "yellow"
        Show-EnhancedProgress -Activity "Status Check" -Status "Reading status files" -Current 1 -Total 3 -SubStatus "Loading configuration"
    }
    
    $status = @{
        timestamp = (Get-Date).ToString("o")
        lock = $false
        status = "unknown"
        sections = @{}
        queue = @{}
        lastActivity = "unknown"
        ema = @{}
        metrics = @{}
    }
    
    # Check lock file
    if (Test-Path ".agent/LOCK") {
        $status.lock = $true
        $status.status = "locked"
        $lockContent = Get-Content ".agent/LOCK" -Raw
        $status.lockReason = $lockContent.Trim()
    }
    
    if ($ShowProgress -and -not $Quiet) {
        Show-EnhancedProgress -Activity "Status Check" -Status "Reading status files" -Current 2 -Total 3 -SubStatus "Reading status.json"
    }
    
    # Check status.json
    if (Test-Path ".agent/status.json") {
        try {
            $statusData = Get-Content ".agent/status.json" -Raw | ConvertFrom-Json
            $status.sections = $statusData.sections
            $status.lastUpdate = $statusData.updatedAt
            $status.ema = $statusData.ema ?? @{}
            $status.metrics = $statusData.metrics ?? @{}
        } catch {
            $status.status = "corrupted"
        }
    }
    
    if ($ShowProgress -and -not $Quiet) {
        Show-EnhancedProgress -Activity "Status Check" -Status "Reading status files" -Current 3 -Total 3 -SubStatus "Reading queue data"
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
    
    return $status
}

function Display-Status {
    param([hashtable]$Status, [bool]$Detailed)
    
    if ($Json) {
        $Status | ConvertTo-Json -Depth 6
        return
    }
    
    if ($Quiet) {
        $overallStatus = if ($Status.lock) { "LOCKED" } else { "ACTIVE" }
        $violations = $Status.metrics.violationsFound ?? 0
        Write-Host "$overallStatus - $violations violations"
        return
    }
    
    Write-Colored -Message "`n[STATUS REPORT] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Color "cyan"
    Write-Colored -Message "================================================" -Color "cyan"
    
    # Lock status
    if ($Status.lock) {
        Write-Colored -Message "🔒 AGENT STATUS: LOCKED" -Color "red"
        Write-Colored -Message "   Reason: $($Status.lockReason)" -Color "yellow"
        Write-Colored -Message "   Remove .agent/LOCK to resume operations" -Color "yellow"
    } else {
        Write-Colored -Message "🟢 AGENT STATUS: ACTIVE" -Color "green"
    }
    
    # EMA data display
    if ($Status.ema.Count -gt 0) {
        Write-Colored -Message "`n📊 PERFORMANCE METRICS:" -Color "white"
        foreach ($key in $Status.ema.Keys) {
            $value = $Status.ema[$key]
            $formattedKey = $key -replace "Secs", " (seconds)"
            Write-Colored -Message "   📈 $formattedKey`: $([Math]::Round($value, 1))s" -Color "gray"
        }
    }
    
    # Section statuses
    if ($Status.sections.Count -gt 0) {
        Write-Colored -Message "`n📊 SECTION STATUS:" -Color "white"
        foreach ($section in $Status.sections.PSObject.Properties.Name) {
            $sectionData = $Status.sections.$section
            $icon = if ($sectionData.ok) { "✅" } else { "❌" }
            $color = if ($sectionData.ok) { "green" } else { "red" }
            Write-Colored -Message "   $icon $($section.ToUpper()): $($sectionData.detail)" -Color $color
            if ($sectionData.ts) {
                Write-Colored -Message "      Last update: $($sectionData.ts)" -Color "gray"
            }
        }
    }
    
    # Queue status
    if ($Status.queue.Count -gt 0 -and -not $Status.queue.error) {
        Write-Colored -Message "`n📋 TASK QUEUE:" -Color "white"
        Write-Colored -Message "   Total tasks: $($Status.queue.total)" -Color "gray"
        
        if ($Status.queue.queued -gt 0) {
            Write-Colored -Message "   Queued: $($Status.queue.queued)" -Color "yellow"
        }
        if ($Status.queue.running -gt 0) {
            Write-Colored -Message "   Running: $($Status.queue.running)" -Color "blue"
        }
        if ($Status.queue.completed -gt 0) {
            Write-Colored -Message "   Completed: $($Status.queue.completed)" -Color "green"
        }
        if ($Status.queue.failed -gt 0) {
            Write-Colored -Message "   Failed: $($Status.queue.failed)" -Color "red"
        }
    }
    
    # Metrics display
    if ($Status.metrics.Count -gt 0) {
        Write-Colored -Message "`n📈 AGENT METRICS:" -Color "white"
        foreach ($key in $Status.metrics.Keys) {
            $value = $Status.metrics[$key]
            $formattedKey = $key -replace "([A-Z])", " $1" -replace "^ ", ""
            Write-Colored -Message "   📊 $formattedKey`: $value" -Color "gray"
        }
    }
    
    # Last activity
    if ($Status.lastActivity -ne "unknown") {
        Write-Colored -Message "`n📝 LAST ACTIVITY:" -Color "white"
        Write-Colored -Message "   $($Status.lastActivity)" -Color "gray"
    }
    
    if ($Detailed) {
        Write-Colored -Message "`n🔍 DETAILED INFO:" -Color "white"
        Write-Colored -Message "   Status file: $(if (Test-Path '.agent/status.json') { 'Present' } else { 'Missing' })" -Color "gray"
        Write-Colored -Message "   Queue file: $(if (Test-Path '.agent/agent_queue.json') { 'Present' } else { 'Missing' })" -Color "gray"
        Write-Colored -Message "   Tasks log: $(if (Test-Path 'TASKS.md') { 'Present' } else { 'Missing' })" -Color "gray"
        Write-Colored -Message "   Lock file: $(if (Test-Path '.agent/LOCK') { 'Present' } else { 'Missing' })" -Color "gray"
        
        # Show recent violations if available
        if (Test-Path ".agent/guardrails_report.json") {
            try {
                $report = Get-Content ".agent/guardrails_report.json" -Raw | ConvertFrom-Json
                if ($report.summary.violations -gt 0) {
                    Write-Colored -Message "   Recent violations: $($report.summary.violations)" -Color "yellow"
                }
            } catch {}
        }
    }
    
    Write-Colored -Message "`n================================================" -Color "cyan"
}

# Main execution
if (-not $Quiet -and -not $Json) {
    Write-Colored -Message "[codex-local] Premium Status Checker" -Color "cyan"
    Write-Colored -Message "[codex-local] ==========================================" -Color "cyan"
}

if ($Continuous) {
    if (-not $Quiet -and -not $Json) {
        Write-Colored -Message "[STATUS] Starting continuous monitoring (press Ctrl+C to stop)" -Color "yellow"
    }
    $cycleCount = 0
    
    while ($true) {
        $cycleCount++
        if (-not $Quiet -and -not $Json) {
            Write-Colored -Message "`n[STATUS] Cycle #$cycleCount - $(Get-Date -Format 'HH:mm:ss')" -Color "cyan"
        }
        
        $status = Get-AgentStatus -ShowProgress (-not $Quiet)
        Display-Status -Status $status -Detailed $Detailed
        
        if (-not $Quiet -and -not $Json) {
            Write-Colored -Message "[STATUS] Waiting 30 seconds for next check..." -Color "yellow"
        }
        
        Show-AdaptiveSleep -TargetSeconds 30 -CycleStart (Get-Date) -Reason "Next status check"
    }
} else {
    $status = Get-AgentStatus -ShowProgress (-not $Quiet -and -not $Json)
    Display-Status -Status $status -Detailed $Detailed
}

if (-not $Quiet -and -not $Json) {
    Write-Colored -Message "[STATUS] Status check completed" -Color "green"
}
