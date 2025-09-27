param(
  [switch]$Fix,       # use -Fix to apply safe autofixes (alt/aria placeholders only)
  [switch]$Detached,  # use -Detached to run watchdog in a separate process
  [switch]$Quiet,     # minimal output, only final results
  [switch]$Json,      # output single JSON object for CI/parsers
  [switch]$Verbose    # detailed progress information
)

$ErrorActionPreference = "Stop"

# Import utilities
. "$PSScriptRoot\utils\terminal.ps1"
. "$PSScriptRoot\utils\progress.ps1"
. "$PSScriptRoot\utils\logging.ps1"

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $repoRoot

# Initialize terminal cleanup
Initialize-TerminalCleanup

function Step($msg) { 
    if (-not $Quiet) {
        Write-Colored -Message "==> $msg" -Color "cyan"
    }
}

function Write-FinalResult {
    param([hashtable]$Results)
    
    if ($Json) {
        $Results | ConvertTo-Json -Depth 6
        return
    }
    
    if ($Quiet) {
        $status = if ($Results.success) { "SUCCESS" } else { "FAILED" }
        Write-Host "$status - $($Results.message)"
        exit $Results.exitCode
    }
    
    Write-Colored -Message "[SUCCESS] Demo completed successfully!" -Color "green"
    Write-Colored -Message "[INFO] Watchdog will resume on next cycle (every 5 minutes)" -Color "cyan"
}

# Initialize results tracking
$results = @{
    success = $true
    message = "Demo completed"
    exitCode = 0
    steps = @{}
    violations = 0
    tasksProcessed = 0
}

# 0) Kill-switch check
if (Test-Path ".agent/LOCK") {
    $results.success = $false
    $results.message = "Agent is locked"
    $results.exitCode = 2
    Write-FinalResult -Results $results
}

# 1) Initialize agent directory
$initStartTime = Get-Date
Step "Initializing agent directory structure"

if (-not (Test-Path ".agent")) { New-Item -ItemType Directory ".agent" | Out-Null }
$defaults = @{
  ".agent/config.json"       = '{"budgets":{"files":10,"loc":200},"intervalSec":300}'
  ".agent/state.json"        = '{"cycles":0,"lastDoctor":null}'
  ".agent/agent_queue.json"  = '[]'
}
foreach ($p in $defaults.Keys) {
  if (-not (Test-Path $p)) { $defaults[$p] | Set-Content -Path $p -Encoding UTF8 -NoNewline }
}

$initDuration = ((Get-Date) - $initStartTime).TotalSeconds
$results.steps.initialization = $initDuration
Update-EmaOnCompletion -EmaKey "initSecs" -ObservedSeconds $initDuration

# 2) Runtime versions
Step "Checking runtime versions"
$nodeVersion = node -v
$pnpmVersion = pnpm -v
$results.steps.versions = @{ node = $nodeVersion; pnpm = $pnpmVersion }

# 3) Setup with enhanced progress
Step "Running pnpm setup-local"
$setupStartTime = Get-Date

try {
    $setupJob = Start-Job -ScriptBlock { 
        Set-Location $using:repoRoot
        pnpm run setup-local 2>&1
    }
    
    $setupStep = 0
    while ($setupJob.State -eq "Running") {
        Show-EnhancedProgress -Activity "Environment Setup" -Status "Setting up local environment" -Current $setupStep -Total 0 -EmaKey "setupSecs" -SubStatus "Installing dependencies"
        Start-Sleep -Milliseconds 500
        $setupStep++
    }
    
    $setupResult = Receive-Job $setupJob
    Remove-Job $setupJob
    
    if (-not $Quiet) {
        Write-Host $setupResult
    }
    
    $setupDuration = ((Get-Date) - $setupStartTime).TotalSeconds
    $results.steps.setup = $setupDuration
    Update-EmaOnCompletion -EmaKey "setupSecs" -ObservedSeconds $setupDuration
    
} catch {
    $results.success = $false
    $results.message = "Setup failed: $($_.Exception.Message)"
    $results.exitCode = 1
    Write-FinalResult -Results $results
}

# 4) Doctor with enhanced progress
Step "Running pnpm agent:doctor (detailed)"
$doctorStartTime = Get-Date

try {
    $doctorJob = Start-Job -ScriptBlock { 
        Set-Location $using:repoRoot
        pnpm run agent:doctor -- -Detailed 2>&1
    }
    
    $doctorStep = 0
    while ($doctorJob.State -eq "Running") {
        Show-EnhancedProgress -Activity "Health Diagnostics" -Status "Running comprehensive health check" -Current $doctorStep -Total 0 -EmaKey "doctorSecs" -SubStatus "Checking runtime versions"
        Start-Sleep -Milliseconds 500
        $doctorStep++
    }
    
    $doctorResult = Receive-Job $doctorJob
    Remove-Job $doctorJob
    
    if (-not $Quiet) {
        Write-Host $doctorResult
    }
    
    $doctorDuration = ((Get-Date) - $doctorStartTime).TotalSeconds
    $results.steps.doctor = $doctorDuration
    Update-EmaOnCompletion -EmaKey "doctorSecs" -ObservedSeconds $doctorDuration
    
} catch {
    $results.success = $false
    $results.message = "Doctor check failed: $($_.Exception.Message)"
    $results.exitCode = 1
    Write-FinalResult -Results $results
}

# 5) Guardrails with enhanced progress
$enforcer = "scripts/agent/enforce-guardrails-hardened.ps1"
if (Test-Path $enforcer) {
    Step "Running guardrail scan"
    $guardrailsStartTime = Get-Date
    
    try {
        $guardrailsJob = Start-Job -ScriptBlock { 
            Set-Location $using:repoRoot
            $args = @("-ReportOnly")
            if ($using:Fix) { $args = @("-Fix") }
            pwsh -NoProfile -File $using:enforcer @args 2>&1
        }
        
        $guardrailsStep = 0
        while ($guardrailsJob.State -eq "Running") {
            Show-EnhancedProgress -Activity "Guardrail Enforcement" -Status "Scanning for violations" -Current $guardrailsStep -Total 0 -EmaKey "guardrailsSecs" -SubStatus "Checking inline styles"
            Start-Sleep -Milliseconds 500
            $guardrailsStep++
        }
        
        $guardrailsResult = Receive-Job $guardrailsJob
        Remove-Job $guardrailsJob
        
        if (-not $Quiet) {
            Write-Host $guardrailsResult
        }
        
        # Parse violations from result
        if ($guardrailsResult -match "Violations found: (\d+)") {
            $results.violations = [int]$matches[1]
        }
        
        $guardrailsDuration = ((Get-Date) - $guardrailsStartTime).TotalSeconds
        $results.steps.guardrails = $guardrailsDuration
        Update-EmaOnCompletion -EmaKey "guardrailsSecs" -ObservedSeconds $guardrailsDuration
        
    } catch {
        Write-Colored -Message "[ERROR] Guardrail scan failed: $($_.Exception.Message)" -Color "yellow"
    }
} else {
    Write-Colored -Message "[WARNING] Guardrail script not found at $enforcer" -Color "yellow"
}

# 6) Start watchdog
Step "Starting watchdog process"
if ($Detached) {
    Start-Process -FilePath "pnpm" -ArgumentList "agent:start" -NoNewWindow
    $results.steps.watchdog = "detached"
    if (-not $Quiet) {
        Write-Colored -Message "[WATCHDOG] Started in detached mode" -Color "green"
    }
} else {
    $watchdogJob = Start-Job -Name "codex-local-watchdog" -ScriptBlock { 
        Set-Location $using:repoRoot
        pnpm run agent:start 2>&1
    }
    $results.steps.watchdog = "background"
    if (-not $Quiet) {
        Write-Colored -Message "[WATCHDOG] Started as background job" -Color "green"
    }
}

# 7) Status monitoring with enhanced progress
Step "Waiting for agent status updates"
$statusStartTime = Get-Date
$statusPath = ".agent/status.json"
$deadline = (Get-Date).AddSeconds(25)

$statusStep = 0
while ((Get-Date) -lt $deadline) {
    Show-EnhancedProgress -Activity "Status Monitoring" -Status "Waiting for status updates" -Current $statusStep -Total 25 -SubStatus "Checking status.json"
    
    if (Test-Path $statusPath) {
        try {
            $status = Get-Content $statusPath -Raw | ConvertFrom-Json
            if (-not $Quiet) {
                Step "Status: $($status.sections.env.detail)"
                if ($status.sections.analytics.detail) { Write-Host "Analytics: $($status.sections.analytics.detail)" -ForegroundColor White }
                if ($status.sections.otel.detail) { Write-Host "OTel: $($status.sections.otel.detail)" -ForegroundColor White }
            }
            $results.steps.status = $status
            break
        } catch { 
            Start-Sleep -Milliseconds 300 
        }
    }
    Start-Sleep -Milliseconds 500
    $statusStep++
}

# 8) Recent activity log
if (-not $Quiet) {
    Step "Displaying recent activity log"
    if (Test-Path "TASKS.md") { 
        Write-Colored -Message "[LOG] Last 30 lines from TASKS.md:" -Color "yellow"
        Get-Content TASKS.md -Tail 30 
    } else { 
        Write-Colored -Message "[LOG] No TASKS.md yet" -Color "yellow"
    }
}

# 9) Kill-switch test with enhanced progress
Step "Testing .agent/LOCK kill-switch"
Write-Colored -Message "[TEST] Creating lock file..." -Color "yellow"
"Paused by demo $(Get-Date -Format o)" | Set-Content ".agent/LOCK"

# Use adaptive sleep for lock test
Show-AdaptiveSleep -TargetSeconds 3 -CycleStart (Get-Date) -Reason "Agent paused - testing lock mechanism"

if (Test-Path $statusPath) {
    try {
        $status = Get-Content $statusPath -Raw | ConvertFrom-Json
        if (-not $Quiet) {
            Write-Colored -Message "[LOCK] State after LOCK: $($status.sections.env.detail)" -Color "yellow"
        }
    } catch {}
}

Write-Colored -Message "[TEST] Removing lock file..." -Color "yellow"
Remove-Item ".agent/LOCK" -ErrorAction SilentlyContinue

# Final adaptive sleep
Show-AdaptiveSleep -TargetSeconds 2 -CycleStart (Get-Date) -Reason "Lock removed - agent resuming"

# Final results
$results.totalDuration = ((Get-Date) - $initStartTime).TotalSeconds
$results.message = "Demo completed in $([Math]::Round($results.totalDuration, 1))s with $($results.violations) violations found"

Write-FinalResult -Results $results
