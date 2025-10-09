param(
  [switch]$Fix,       # use -Fix to apply safe autofixes (alt/aria placeholders only)
  [switch]$Detached   # use -Detached to run watchdog in a separate process
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)  # ..\.. from scripts/agent
Set-Location $repoRoot

function Step($msg){ Write-Host "==> $msg" -ForegroundColor Cyan }

function Show-ProgressBar {
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

function Wait-WithProgress {
    param(
        [string]$Message,
        [int]$Seconds,
        [string]$SuccessMessage = "Completed"
    )
    
    Write-Host "[WAIT] $Message" -ForegroundColor Yellow
    Show-ProgressBar -Activity "Waiting" -Status $Message -Seconds $Seconds
    Write-Host "[DONE] $SuccessMessage" -ForegroundColor Green
}

# 0) Kill-switch
if (Test-Path ".agent/LOCK") {
  Write-Warning "'.agent/LOCK' present — agent paused. Remove the file to resume."
  exit 2
}

# 1) Ensure .agent basics exist (idempotent)
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
Write-Host "[INIT] Agent directory structure ready" -ForegroundColor Green

# 2) Versions
Step "Checking runtime versions"
node -v
pnpm -v

# 3) Setup + Doctor
Step "Running pnpm setup-local"
try {
    $setupJob = Start-Job -ScriptBlock { 
        Set-Location $using:repoRoot
        pnpm run setup-local 2>&1
    }
    
    # Show progress while setup runs
    $startTime = Get-Date
    while ($setupJob.State -eq "Running") {
        $elapsed = (Get-Date) - $startTime
        $estimated = [TimeSpan]::FromSeconds(30)  # Estimate 30 seconds for setup
        $percent = [Math]::Min(($elapsed.TotalSeconds / $estimated.TotalSeconds) * 100, 95)
        $remaining = [Math]::Max(0, $estimated.TotalSeconds - $elapsed.TotalSeconds)
        
        Write-Progress -Activity "Environment Setup" -Status "Setting up local environment (ETA: $([Math]::Round($remaining, 1))s)" -PercentComplete $percent
        Start-Sleep -Milliseconds 500
    }
    Write-Progress -Activity "Environment Setup" -Completed
    
    $setupResult = Receive-Job $setupJob
    Remove-Job $setupJob
    Write-Host $setupResult
} catch {
    Write-Host "[ERROR] Setup failed: $($_.Exception.Message)" -ForegroundColor Red
}

Step "Running pnpm agent:doctor (detailed)"
try {
    $doctorJob = Start-Job -ScriptBlock { 
        Set-Location $using:repoRoot
        pnpm run agent:doctor -- -Detailed 2>&1
    }
    
    # Show progress while doctor runs
    $startTime = Get-Date
    while ($doctorJob.State -eq "Running") {
        $elapsed = (Get-Date) - $startTime
        $estimated = [TimeSpan]::FromSeconds(45)  # Estimate 45 seconds for doctor
        $percent = [Math]::Min(($elapsed.TotalSeconds / $estimated.TotalSeconds) * 100, 95)
        $remaining = [Math]::Max(0, $estimated.TotalSeconds - $elapsed.TotalSeconds)
        
        Write-Progress -Activity "Health Diagnostics" -Status "Running comprehensive health check (ETA: $([Math]::Round($remaining, 1))s)" -PercentComplete $percent
        Start-Sleep -Milliseconds 500
    }
    Write-Progress -Activity "Health Diagnostics" -Completed
    
    $doctorResult = Receive-Job $doctorJob
    Remove-Job $doctorJob
    Write-Host $doctorResult
} catch {
    Write-Host "[ERROR] Doctor check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 4) Guardrails (report only by default)
$enforcer = "scripts/agent/enforce-guardrails-hardened.ps1"
if (Test-Path $enforcer) {
  Step "Running guardrail scan"
  try {
    $guardrailJob = Start-Job -ScriptBlock { 
        Set-Location $using:repoRoot
        $args = @("-ReportOnly")
        if ($using:Fix) { $args = @("-Fix") }
        pwsh -NoProfile -File $using:enforcer @args 2>&1
    }
    
    # Show progress while guardrail scan runs
    $startTime = Get-Date
    while ($guardrailJob.State -eq "Running") {
        $elapsed = (Get-Date) - $startTime
        $estimated = [TimeSpan]::FromSeconds(20)  # Estimate 20 seconds for guardrail scan
        $percent = [Math]::Min(($elapsed.TotalSeconds / $estimated.TotalSeconds) * 100, 95)
        $remaining = [Math]::Max(0, $estimated.TotalSeconds - $elapsed.TotalSeconds)
        
        Write-Progress -Activity "Guardrail Enforcement" -Status "Scanning for violations (ETA: $([Math]::Round($remaining, 1))s)" -PercentComplete $percent
        Start-Sleep -Milliseconds 500
    }
    Write-Progress -Activity "Guardrail Enforcement" -Completed
    
    $guardrailResult = Receive-Job $guardrailJob
    Remove-Job $guardrailJob
    Write-Host $guardrailResult
  } catch {
    Write-Host "[ERROR] Guardrail scan failed: $($_.Exception.Message)" -ForegroundColor Red
  }
} else {
  Write-Warning "Guardrail script not found at $enforcer"
}

# 5) Start watchdog
Step "Starting watchdog process"
if ($Detached) {
  Start-Process -FilePath "pnpm" -ArgumentList "agent:start" -NoNewWindow
  Write-Host "[WATCHDOG] Started in detached mode" -ForegroundColor Green
} else {
  $watchdogJob = Start-Job -Name "codex-local-watchdog" -ScriptBlock { 
      Set-Location $using:repoRoot
      pnpm run agent:start 2>&1
  }
  Write-Host "[WATCHDOG] Started as background job" -ForegroundColor Green
}

# 6) Wait for status.json with progress
Step "Waiting for agent status updates"
$statusPath = ".agent/status.json"
$deadline = (Get-Date).AddSeconds(25)
$waitTime = 25

Write-Host "[WAIT] Waiting for status.json to be created/updated..." -ForegroundColor Yellow
$startTime = Get-Date
while ((Get-Date) -lt $deadline) {
    $elapsed = (Get-Date) - $startTime
    $remaining = [Math]::Max(0, $waitTime - $elapsed.TotalSeconds)
    $percent = ($elapsed.TotalSeconds / $waitTime) * 100
    
    Write-Progress -Activity "Status Monitoring" -Status "Waiting for agent status (ETA: $([Math]::Round($remaining, 1))s)" -PercentComplete $percent
    
    if (Test-Path $statusPath) {
        try {
            $status = Get-Content $statusPath -Raw | ConvertFrom-Json
            Write-Progress -Activity "Status Monitoring" -Completed
            Step "Status: $($status.sections.env.detail)"
            if ($status.sections.analytics.detail) { Write-Host "Analytics: $($status.sections.analytics.detail)" -ForegroundColor White }
            if ($status.sections.otel.detail) { Write-Host "OTel: $($status.sections.otel.detail)" -ForegroundColor White }
            break
        } catch { 
            Start-Sleep -Milliseconds 300 
        }
    }
    Start-Sleep -Milliseconds 500
}
Write-Progress -Activity "Status Monitoring" -Completed

# 7) Tail human logs
Step "Displaying recent activity log"
if (Test-Path "TASKS.md") { 
    Write-Host "[LOG] Last 30 lines from TASKS.md:" -ForegroundColor Yellow
    Get-Content TASKS.md -Tail 30 
} else { 
    Write-Host "[LOG] No TASKS.md yet" -ForegroundColor Yellow 
}

# 8) Exercise kill-switch with progress
Step "Testing .agent/LOCK kill-switch"
Write-Host "[TEST] Creating lock file..." -ForegroundColor Yellow
"Paused by demo $(Get-Date -Format o)" | Set-Content ".agent/LOCK"

Wait-WithProgress -Message "Agent paused - testing lock mechanism" -Seconds 3 -SuccessMessage "Lock test completed"

if (Test-Path $statusPath) {
  try {
    $status = Get-Content $statusPath -Raw | ConvertFrom-Json
    Write-Host "[LOCK] State after LOCK: $($status.sections.env.detail)" -ForegroundColor Yellow
  } catch {}
}

Write-Host "[TEST] Removing lock file..." -ForegroundColor Yellow
Remove-Item ".agent/LOCK" -ErrorAction SilentlyContinue
Wait-WithProgress -Message "Lock removed - agent resuming" -Seconds 2 -SuccessMessage "Agent resumed"

Write-Host "[SUCCESS] Demo completed successfully!" -ForegroundColor Green
Write-Host "[INFO] Watchdog will resume on next cycle (every 5 minutes)" -ForegroundColor Cyan
