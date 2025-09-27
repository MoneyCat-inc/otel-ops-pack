# scripts/agent/setup-local.ps1
# codex-local Local Workflow Custodian - Bootstrap the local dev environment
# This script performs first-time setup tasks and environment validation

[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "[setup-local] codex-local Local Workflow Custodian - Environment Bootstrap" -ForegroundColor Cyan
Write-Host "[setup-local] ================================================================" -ForegroundColor Cyan

# 1. Check for .agent/LOCK kill-switch
$lockPath = ".agent/LOCK"
if (Test-Path $lockPath) {
    Write-Host "[setup-local] ✗ Agent is LOCKED. Remove .agent/LOCK to proceed." -ForegroundColor Red
    Write-Host "[setup-local] Lock file found at: $lockPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "[setup-local] ✓ No lock file detected, proceeding with setup..." -ForegroundColor Green

# 2. Initialize .agent/ directory with default files if they don't exist
Write-Host "[setup-local] Initializing .agent/ directory structure..." -ForegroundColor Yellow

$agentDir = ".agent"
if (-not (Test-Path $agentDir)) {
    Write-Host "[setup-local] Creating .agent directory..."
    New-Item -ItemType Directory -Path $agentDir -Force | Out-Null
}

# Initialize default configuration files
$configPath = "$agentDir/config.json"
if (-not (Test-Path $configPath) -or $Force) {
    Write-Host "[setup-local] Configuring agent settings..."
    $defaultConfig = @{
        max_jobs_per_run = 3
        max_files_per_job = 15
        max_lines_per_job = 500
        job_ttl_seconds = 86400
        agent_name = "codex-local"
        version = "1.0.0"
        environment = "resonai-otel"
        role = "Local Workflow Custodian"
        capabilities = @(
            "environment_setup",
            "health_diagnostics", 
            "guardrail_enforcement",
            "csp_validation",
            "accessibility_audit",
            "background_watchdog",
            "micro_task_processing"
        )
        safety_settings = @{
            read_only_by_default = $true
            require_confirmation = $true
            max_file_size_mb = 25
            excluded_directories = @("node_modules", ".git", "third_party", ".agent/logs", ".agent/reports", "audit")
        }
        guardrails = @{
            enforce_no_inline_styles = $true
            enforce_csp_strict = $true
            enforce_cross_origin_isolation = $true
            enforce_aria_compliance = $true
            max_inline_style_violations = 0
            max_csp_violations = 0
            max_a11y_violations = 0
        }
        watchdog = @{
            cycle_interval_seconds = 300
            max_tasks_per_cycle = 2
            lock_check_interval_seconds = 30
            auto_cleanup_days = 7
        }
    }
    ($defaultConfig | ConvertTo-Json -Depth 6) | Set-Content $configPath
    Write-Host "[setup-local] ✓ Created default configuration" -ForegroundColor Green
}

# Initialize state.json if it doesn't exist
$statePath = "$agentDir/state.json"
if (-not (Test-Path $statePath)) {
    Write-Host "[setup-local] Initializing agent state..."
    $initialState = @{
        lastDailyRun = $null
        lastWeeklyRun = $null
        lastMonthlyRun = $null
        lastQuarterlyRun = $null
        lastYearlyRun = $null
        setupCompleted = (Get-Date).ToString("o")
        version = "1.0.0"
    }
    ($initialState | ConvertTo-Json -Depth 6) | Set-Content $statePath
    Write-Host "[setup-local] ✓ Initialized agent state" -ForegroundColor Green
}

# Initialize status.json if it doesn't exist
$statusPath = "$agentDir/status.json"
if (-not (Test-Path $statusPath)) {
    Write-Host "[setup-local] Initializing agent status..."
    $initialStatus = @{
        version = 1
        updatedAt = (Get-Date).ToString("o")
        sections = @{
            env = @{ ok = $false; detail = "Not initialized"; ts = $null }
            analytics = @{ ok = $false; detail = "Not initialized"; ts = $null }
            otel = @{ ok = $false; detail = "Not initialized"; ts = $null }
            guardrails = @{ ok = $false; detail = "Not initialized"; ts = $null }
        }
    }
    ($initialStatus | ConvertTo-Json -Depth 6) | Set-Content $statusPath
    Write-Host "[setup-local] ✓ Initialized agent status" -ForegroundColor Green
}

# Initialize agent_queue.json if it doesn't exist
$queuePath = "$agentDir/agent_queue.json"
if (-not (Test-Path $queuePath)) {
    Write-Host "[setup-local] Initializing agent queue..."
    $initialQueue = @{
        version = 1
        lastRun = $null
        jobs = @()
    }
    ($initialQueue | ConvertTo-Json -Depth 6) | Set-Content $queuePath
    Write-Host "[setup-local] ✓ Initialized agent queue" -ForegroundColor Green
}

# 3. Environment bootstrapping
Write-Host "[setup-local] Running environment bootstrapping..." -ForegroundColor Yellow

# Check for pnpm
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Host "[setup-local] ✗ pnpm not found in PATH" -ForegroundColor Red
    Write-Host "[setup-local] Please install pnpm: npm install -g pnpm" -ForegroundColor Yellow
    exit 1
}

$pnpmVersion = (pnpm --version)
Write-Host "[setup-local] ✓ pnpm version: $pnpmVersion" -ForegroundColor Green

# Check for Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "[setup-local] ✗ Node.js not found in PATH" -ForegroundColor Red
    Write-Host "[setup-local] Please install Node.js >= 18.0.0" -ForegroundColor Yellow
    exit 1
}

$nodeVersion = (node --version)
Write-Host "[setup-local] ✓ Node.js version: $nodeVersion" -ForegroundColor Green

# Verify Node.js version meets requirements
if ($nodeVersion -match "v(\d+)") {
    $majorVersion = [int]$matches[1]
    if ($majorVersion -lt 18) {
        Write-Host "[setup-local] ✗ Node.js version $nodeVersion is below required v18.0.0" -ForegroundColor Red
        exit 1
    }
}

# Run pnpm install if needed
if (-not (Test-Path "node_modules") -or $Force) {
    Write-Host "[setup-local] Running pnpm install..."
    pnpm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[setup-local] ✗ pnpm install failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "[setup-local] ✓ Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "[setup-local] ✓ Dependencies already installed" -ForegroundColor Green
}

# 4. PowerShell compatibility check
Write-Host "[setup-local] Checking PowerShell execution policy..." -ForegroundColor Yellow
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "Restricted") {
    Write-Host "[setup-local] ⚠ PowerShell execution policy is Restricted" -ForegroundColor Yellow
    Write-Host "[setup-local] Consider running: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
} else {
    Write-Host "[setup-local] ✓ PowerShell execution policy: $executionPolicy" -ForegroundColor Green
}

# Test script execution
Write-Host "[setup-local] Testing script execution..." -ForegroundColor Yellow
try {
    pwsh -File scripts/agent/health-gate.ps1 -ErrorAction Stop | Out-Null
    Write-Host "[setup-local] ✓ Script execution test passed" -ForegroundColor Green
} catch {
    Write-Host "[setup-local] ⚠ Script execution test failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "[setup-local] This may be expected if dependencies are not fully configured" -ForegroundColor Yellow
}

# 5. Update status
Write-Host "[setup-local] Updating agent status..." -ForegroundColor Yellow
try {
    pwsh -File scripts/agent/update-status.ps1 -section env -ok $true -detail "Environment bootstrapped successfully"
    Write-Host "[setup-local] ✓ Status updated" -ForegroundColor Green
} catch {
    Write-Host "[setup-local] ⚠ Status update failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 6. Log setup completion
$logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') – Environment bootstrap completed successfully"
if (Test-Path "TASKS.md") {
    $logEntry | Add-Content "TASKS.md"
} else {
    $logEntry | Set-Content "TASKS.md"
}

Write-Host "[setup-local] ================================================================" -ForegroundColor Cyan
Write-Host "[setup-local] ✓ Local environment bootstrap completed successfully!" -ForegroundColor Green
Write-Host "[setup-local] Next steps:" -ForegroundColor Yellow
Write-Host "[setup-local]   1. Run 'pnpm agent:doctor' to perform health diagnostics" -ForegroundColor White
Write-Host "[setup-local]   2. Run 'pnpm agent:start' to launch the background watchdog" -ForegroundColor White
Write-Host "[setup-local] ================================================================" -ForegroundColor Cyan
