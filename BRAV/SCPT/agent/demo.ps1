param(
  [switch]$Fix,       # use -Fix to apply safe autofixes (alt/aria placeholders only)
  [switch]$Detached   # use -Detached to run watchdog in a separate process
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)  # ..\.. from scripts/agent
Set-Location $repoRoot

function Step($msg){ Write-Host "==> $msg" -ForegroundColor Cyan }

# 0) Kill-switch
if (Test-Path ".agent/LOCK") {
  Write-Warning "'.agent/LOCK' present — agent paused. Remove the file to resume."
  exit 2
}

# 1) Ensure .agent basics exist (idempotent)
if (-not (Test-Path ".agent")) { New-Item -ItemType Directory ".agent" | Out-Null }
$defaults = @{
  ".agent/config.json"       = '{"budgets":{"files":10,"loc":200},"intervalSec":300}'
  ".agent/state.json"        = '{"cycles":0,"lastDoctor":null}'
  ".agent/agent_queue.json"  = '[]'
}
foreach ($p in $defaults.Keys) {
  if (-not (Test-Path $p)) { $defaults[$p] | Set-Content -Path $p -Encoding UTF8 -NoNewline }
}

# 2) Versions
Step "Runtime versions"
node -v
pnpm -v

# 3) Setup + Doctor
Step "pnpm setup-local"
pnpm run setup-local

Step "pnpm agent:doctor (detailed)"
pnpm run agent:doctor -- -Detailed

# 4) Guardrails (report only by default)
$enforcer = "scripts/agent/enforce-guardrails.ps1"
if (Test-Path $enforcer) {
  Step "Guardrail scan"
  $args = @("-ReportOnly")
  if ($Fix) { $args = @("-Fix") }
  pwsh -NoProfile -File $enforcer @args
} else {
  Write-Warning "Guardrail script not found at $enforcer"
}

# 5) Start watchdog
Step "Start watchdog"
if ($Detached) {
  Start-Process -FilePath "pnpm" -ArgumentList "agent:start" -NoNewWindow
} else {
  Start-Job -Name "codex-local-watchdog" -ScriptBlock { pnpm run agent:start }
}

# 6) Wait briefly for status.json and print state
$statusPath = ".agent/status.json"
$deadline = (Get-Date).AddSeconds(25)
while ((Get-Date) -lt $deadline) {
  if (Test-Path $statusPath) {
    try {
      $status = Get-Content $statusPath -Raw | ConvertFrom-Json
      Step "Status: $($status.state)"
      if ($status.queue) { Write-Host "Queue length:" $status.queue.length }
      break
    } catch { Start-Sleep -Milliseconds 300 }
  }
  Start-Sleep -Milliseconds 500
}

# 7) Tail human logs
Step "TASKS.md (last 30 lines)"
if (Test-Path "TASKS.md") { Get-Content TASKS.md -Tail 30 } else { Write-Host "No TASKS.md yet" }

# 8) Exercise kill-switch
Step "Exercise .agent/LOCK kill-switch"
"Paused by demo $(Get-Date -Format o)" | Set-Content ".agent/LOCK"
Start-Sleep -Seconds 2
if (Test-Path $statusPath) {
  try {
    $status = Get-Content $statusPath -Raw | ConvertFrom-Json
    Write-Host "State after LOCK:" $status.state
  } catch {}
}
Remove-Item ".agent/LOCK" -ErrorAction SilentlyContinue
Write-Host "LOCK removed; watchdog will resume on next cycle."
