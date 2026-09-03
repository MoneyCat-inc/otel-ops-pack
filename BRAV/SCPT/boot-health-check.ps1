#Requires -Version 7.0

<#
.SYNOPSIS
    Automatic health check and initialization for IONA + BossCat framework
.DESCRIPTION
    Runs on every boot to verify and start all observability components.
    Integrates with IONA app and BossCat parallel agent framework.
.PARAMETER Environment
    Target environment: dev, staging, production (default: dev)
.PARAMETER SkipDocker
    Skip Docker/SigNoz checks (for CI/CD environments)
.PARAMETER SendTelemetry
    Send boot telemetry to SigNoz
#>

[CmdletBinding()]
param(
    [ValidateSet('dev', 'staging', 'production')]
    [string]$Environment = 'dev',
    
    [switch]$SkipDocker,
    
    [switch]$SendTelemetry
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$bootSession = @{
    SessionId = (New-Guid).ToString()
    StartTime = Get-Date
    Environment = $Environment
    Checks = @()
    Status = 'running'
}

function Write-BootLog {
    param([string]$Message, [string]$Level = 'INFO')
    $colors = @{ INFO = 'Cyan'; SUCCESS = 'Green'; WARN = 'Yellow'; ERROR = 'Red' }
    $timestamp = Get-Date -Format 'HH:mm:ss'
    Write-Host "[$timestamp] [BOOT-$Level] $Message" -ForegroundColor $colors[$Level]
}

function Test-ComponentHealth {
    param(
        [string]$Name,
        [scriptblock]$Check,
        [bool]$Required = $true
    )
    
    Write-BootLog "Checking: $Name..." -Level INFO
    $startTime = Get-Date
    
    try {
        $result = & $Check
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        
        $checkResult = @{
            Name = $Name
            Status = if ($result) { 'healthy' } else { 'unhealthy' }
            Required = $Required
            Duration = $duration
            Timestamp = (Get-Date).ToString('o')
        }
        
        $bootSession.Checks += $checkResult
        
        if ($result) {
            $checkmark = [char]0x2713
            $msg = "$checkmark ${Name}: healthy ($([math]::Round($duration,0))ms)"
            Write-BootLog $msg -Level SUCCESS
            return $true
        } else {
            if ($Required) {
                $cross = [char]0x2717
                $msg = "$cross ${Name}: unhealthy (required)"
                Write-BootLog $msg -Level ERROR
            } else {
                $warning = [char]0x26A0
                $msg = "$warning ${Name}: unhealthy (optional)"
                Write-BootLog $msg -Level WARN
            }
            return $false
        }
    } catch {
        $bootSession.Checks += @{
            Name = $Name
            Status = 'error'
            Required = $Required
            Error = $_.Exception.Message
            Timestamp = (Get-Date).ToString('o')
        }
        $cross = [char]0x2717
        $msg = "$cross ${Name}: $($_.Exception.Message)"
        Write-BootLog $msg -Level ERROR
        return $false
    }
}

Write-BootLog "Starting IONA + BossCat Boot Health Check" -Level INFO
Write-BootLog "Environment: $Environment | Session: $($bootSession.SessionId)" -Level INFO

# ============================================================================
# 1. CORE INFRASTRUCTURE
# ============================================================================

$coreHealthy = $true

# Docker (if not skipped)
if (-not $SkipDocker) {
    $dockerHealthy = Test-ComponentHealth -Name "Docker Desktop" -Required $true -Check {
        $dockerInfo = docker info 2>&1
        return $LASTEXITCODE -eq 0
    }
    $coreHealthy = $coreHealthy -and $dockerHealthy
    
    # SigNoz Stack
    if ($dockerHealthy) {
        $signozHealthy = Test-ComponentHealth -Name "SigNoz Stack" -Required $true -Check {
            $containers = docker ps --filter "name=signoz" --format "{{.Names}}" 2>&1
            return ($containers -and $containers.Count -gt 0)
        }
        $coreHealthy = $coreHealthy -and $signozHealthy
    }
}

# Windows OTel Collector
$collectorHealthy = Test-ComponentHealth -Name "Windows OTel Collector" -Required $true -Check {
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    if (-not $service) { return $false }
    
    # Auto-start if stopped
    if ($service.Status -ne 'Running') {
        try {
            Start-Service -Name "otelcol-contrib" -ErrorAction Stop
            Start-Sleep -Seconds 2
            $service = Get-Service -Name "otelcol-contrib"
        } catch {
            return $false
        }
    }
    return $service.Status -eq 'Running'
}
$coreHealthy = $coreHealthy -and $collectorHealthy

# ============================================================================
# 2. BOSSCAT FRAMEWORK
# ============================================================================

Write-BootLog "Initializing BossCat Framework..." -Level INFO

# Agent Configuration
$configHealthy = Test-ComponentHealth -Name "Agent Configuration" -Required $true -Check {
    return (Test-Path ".agent/config.json")
}

# Agent Queue
$queueHealthy = Test-ComponentHealth -Name "Agent Queue" -Required $true -Check {
    if (-not (Test-Path ".agent/agent_queue.json")) { return $false }
    try {
        $queue = Get-Content ".agent/agent_queue.json" -Raw | ConvertFrom-Json
        return $queue.PSObject.Properties.Name -contains 'jobs'
    } catch {
        return $false
    }
}

# Watchdog auto-start REMOVED 2026-09-03 (ECRR_READY_FOR_GATE_AUDIT_20260903.md, P1-2).
# This block used to Start-Process agent/watchdog.ps1 (the codex-local "Local
# Workflow Custodian": a 300 s loop appending to TASKS.md and rewriting a queue
# JSON in the working tree). Roadmap 2026 H2 Phase 0 closed on "no recurring
# writer left running against the working tree"; the spawn only failed at logon
# because the task's cwd hid .agent/config.json. A health check must not start
# services. The live watchdog for the collector is the SYSTEM scheduled task
# BossCat-OtelcolWatchdog, which this script neither starts nor needs.

# ============================================================================
# 3. IONA APP INTEGRATION
# ============================================================================

Write-BootLog "Checking IONA Integration..." -Level INFO

# IONA Boot Telemetry
if ($SendTelemetry) {
    Test-ComponentHealth -Name "IONA Boot Telemetry" -Required $false -Check {
        $ionaScript = Join-Path $PSScriptRoot "send_iona_boot_span.mjs"
        if (Test-Path $ionaScript) {
            try {
                & node $ionaScript 2>&1 | Out-Null
                return $LASTEXITCODE -eq 0
            } catch {
                return $false
            }
        }
        return $false
    } | Out-Null
}

# ============================================================================
# 4. VERIFICATION & SUMMARY
# ============================================================================

$bootSession.EndTime = Get-Date
$bootSession.Duration = (($bootSession.EndTime - $bootSession.StartTime).TotalMilliseconds)
$bootSession.Status = if ($coreHealthy) { 'healthy' } else { 'degraded' }

Write-BootLog "`nBoot Health Check Summary:" -Level INFO
Write-BootLog "Session: $($bootSession.SessionId)" -Level INFO
Write-BootLog "Duration: $([math]::Round($bootSession.Duration,0))ms" -Level INFO
Write-BootLog "Environment: $Environment" -Level INFO

$healthyCount = ($bootSession.Checks | Where-Object { $_.Status -eq 'healthy' }).Count
$totalCount = $bootSession.Checks.Count
$healthPercentage = if ($totalCount -gt 0) { [math]::Round(($healthyCount / $totalCount) * 100, 0) } else { 0 }

Write-BootLog "Health: $healthyCount/$totalCount checks passed ($healthPercentage%)" -Level $(if ($healthPercentage -ge 80) { 'SUCCESS' } else { 'WARN' })

# Save boot report
$reportDir = "artifacts/boot-reports"
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}
$reportFile = Join-Path $reportDir "boot-health-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$bootSession | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile -Encoding UTF8

Write-BootLog "Report saved: $reportFile" -Level INFO

# Exit with appropriate status
if ($coreHealthy) {
    Write-BootLog "✅ IONA + BossCat boot sequence complete" -Level SUCCESS
    Write-BootLog "SigNoz UI: http://localhost:8080" -Level INFO
    exit 0
} else {
    Write-BootLog "⚠️ Boot sequence completed with issues" -Level WARN
    Write-BootLog "Review: $reportFile" -Level INFO
    exit 1
}

