<#
.SYNOPSIS
  Scheduled clean-host E2E automation wrapper.
  Phase-0 contamination checkpoint -> Phases 1-4 gate clock -> artifacts.

.DESCRIPTION
  Orchestrates a clean-host E2E gate run. Designed to be invoked elevated on the
  Hyper-V guest after Phase 0 is complete and the checkpoint is at expected state.

  Outputs:
    - artifacts/clean-host-e2e-<YYYYMMDD>.json (timing JSON)
    - CHAR/ECRR/ECRR_REPORTS/ECRR_CLEAN_HOST_E2E_<YYYYMMDD>.md (ECRR stub)
    - docs/BossCat/BOSSCAT_LOG.md (appended one-liner)

  Exit codes:
    0  = GREEN (all pass, clock <= 30 min)
    1  = RED (verify != 0 or critical step failed)
    2  = RED (clock exceeded 30 min)
    10 = CONTAMINATED (Phase-0 check failed)

.PARAMETER RepoUrl
  Git clone URL. Default: https://github.com/MoneyCat-inc/otel-ops-pack.git

.PARAMETER RepoPath
  Local clone target. Default: C:\otel

.PARAMETER RunId
  Override run ID. Default: clean-host-e2e-<YYYYMMDD>

.PARAMETER MaxMinutes
  Hard cap in minutes. Default: 30

.PARAMETER SkipBosscatLog
  Skip appending to BOSSCAT_LOG (useful for dry-run testing).

.NOTES
  Actor: Kiro{Implementer} (provisional -- pilot-scoped)
  Spec: .kiro/specs/clean-host-e2e-automation.md
  Briefing: docs/BossCat/BRIEFING_KIRO_PILOT_CLEAN_HOST_E2E_AUTOMATION.md
#>
[CmdletBinding()]
param(
    [string]$RepoUrl = 'https://github.com/MoneyCat-inc/otel-ops-pack.git',
    [string]$RepoPath = 'C:\otel',
    [string]$RunId = '',
    [int]$MaxMinutes = 30,
    [switch]$SkipBosscatLog
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

Import-Module (Join-Path $PSScriptRoot '..\..\BRAV\SCPT\lib\OtelPorts.psm1') -Force
$script:OtelPorts = Get-OtelPorts

# --- Constants ---
$stamp = Get-Date -Format 'yyyyMMdd'
if (-not $RunId) { $RunId = "clean-host-e2e-$stamp" }
$Actor = 'Kiro{Implementer}'

# --- Utility functions ---

function Write-Step {
    param([string]$Message, [string]$Color = 'Cyan')
    Write-Host "`n=== $Message ===" -ForegroundColor $Color
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
    [Console]::Error.WriteLine("CONTAMINATION: $Message")
}

function Test-PortFree {
    param([int]$Port)
    $listener = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
        Where-Object { $_.State -eq 'Listen' }
    return ($null -eq $listener -or $listener.Count -eq 0)
}

# ============================================================================
# PHASE 0 - Contamination Checkpoint
# ============================================================================

function Invoke-ContaminationCheck {
    Write-Step 'Phase-0 Contamination Checkpoint'

    $checks = [ordered]@{
        repo_absent        = $false
        no_signoz_containers = $false
        collector_not_running = $false
        docker_ok          = $false
        ports_free         = $false
    }
    $failures = @()

    # Check 1: C:\otel must not exist
    if (Test-Path $RepoPath) {
        $failures += "Repository path '$RepoPath' already exists"
    } else {
        $checks.repo_absent = $true
    }

    # Check 2: No SigNoz containers
    try {
        $containers = & docker ps -a --filter 'name=signoz' --format '{{.Names}}' 2>&1
        if ($LASTEXITCODE -ne 0) {
            $failures += "docker ps failed (exit $LASTEXITCODE)"
        } elseif ($containers -and ($containers | Where-Object { $_ -match '\S' })) {
            $failures += "SigNoz containers found: $($containers -join ', ')"
        } else {
            $checks.no_signoz_containers = $true
        }
    } catch {
        $failures += "Docker command failed: $($_.Exception.Message)"
    }

    # Check 3: Collector service not RUNNING
    $svc = Get-Service -Name 'otelcol-contrib' -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq 'Running') {
        $failures += "otelcol-contrib service is Running (expected Stopped or absent)"
    } else {
        $checks.collector_not_running = $true
    }
    $checks['collector_state'] = if ($svc) { $svc.Status.ToString() } else { 'NotInstalled' }

    # Check 4: Docker engine responsive
    try {
        & docker info *>$null
        if ($LASTEXITCODE -eq 0) {
            $checks.docker_ok = $true
        } else {
            $failures += "docker info exit $LASTEXITCODE"
        }
    } catch {
        $failures += "Docker not responsive: $($_.Exception.Message)"
    }

    # Check 5: Required ports free
    $requiredPorts = @(
        $script:OtelPorts.SignozOtlpGrpc,
        $script:OtelPorts.SignozOtlpHttp,
        $script:OtelPorts.IngestGrpc,
        $script:OtelPorts.IngestHttp,
        $script:OtelPorts.SignozUiHttp
    )
    $boundPorts = @()
    foreach ($port in $requiredPorts) {
        if (-not (Test-PortFree $port)) {
            $boundPorts += $port
        }
    }
    if ($boundPorts.Count -gt 0) {
        $failures += "Ports bound: $($boundPorts -join ', ')"
    } else {
        $checks.ports_free = $true
    }

    return @{
        Passed   = ($failures.Count -eq 0)
        Checks   = $checks
        Failures = $failures
    }
}

# ============================================================================
# GATE CLOCK - Phases 1-4
# ============================================================================

function Invoke-GateClock {
    param([hashtable]$Phase0Result)

    $clockStart = Get-Date
    $steps = [System.Collections.ArrayList]::new()
    $failed = $false
    $headSha = ''
    $abortReason = ''

    # Resolve pwsh path
    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $pwsh) { $pwsh = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe' }
    if (-not (Test-Path $pwsh)) { $pwsh = 'powershell.exe' }

    # Step runner with clock check
    function Run-Step {
        param([string]$Name, [scriptblock]$Body)

        # Check hard cap before each step
        $elapsed = ((Get-Date) - $clockStart).TotalMinutes
        if ($elapsed -ge $MaxMinutes) {
            $script:abortReason = "Clock exceeded $MaxMinutes min at step '$Name' ($([math]::Round($elapsed, 2)) min elapsed)"
            return @{ Aborted = $true }
        }

        Write-Step $Name
        $t0 = Get-Date
        $exitCode = 0
        try {
            & $Body
            if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                $exitCode = $LASTEXITCODE
            }
        } catch {
            Write-Host "STEP FAILED: $($_.Exception.Message)" -ForegroundColor Red
            $exitCode = 1
        }
        $mins = [math]::Round(((Get-Date) - $t0).TotalMinutes, 2)
        $stepResult = [ordered]@{
            name      = $Name
            minutes   = $mins
            exit_code = $exitCode
            ended_utc = (Get-Date).ToUniversalTime().ToString('o')
        }
        $steps.Add($stepResult) | Out-Null
        Write-Host "--- $Name done in $mins min exit=$exitCode ---" -ForegroundColor Yellow
        return @{ Aborted = $false; ExitCode = $exitCode }
    }

    # --- Phase 1: Clone ---
    $r = Run-Step 'git-clone' {
        git clone --single-branch $RepoUrl $RepoPath
        if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit $LASTEXITCODE)" }
        Set-Location $RepoPath
        $script:headSha = (git rev-parse --short HEAD).Trim()
        Write-Host "HEAD=$script:headSha"
    }
    if ($r.Aborted) { $failed = $true }
    elseif ($r.ExitCode -ne 0) { $failed = $true }

    if (-not $failed) {
        Set-Location $RepoPath

        # --- Phase 2: SigNoz ---
        $r = Run-Step 'start-signoz' {
            & $pwsh -NoProfile -File .\start-signoz.ps1
        }
        if ($r.Aborted) { $failed = $true }

        if (-not $failed) {
            $r = Run-Step 'preflight' {
                & $pwsh -NoProfile -File .\scripts\preflight-health-check.ps1
            }
            if ($r.Aborted) { $failed = $true }
        }

        # --- Phase 3: Collector ---
        if (-not $failed) {
            $r = Run-Step 'enable-collector-service' {
                Set-Service otelcol-contrib -StartupType Automatic -ErrorAction SilentlyContinue
                sc.exe config otelcol-contrib start= delayed-auto | Out-Null
            }
            if ($r.Aborted) { $failed = $true }
        }

        if (-not $failed) {
            $r = Run-Step 'install-or-repair-collector' {
                & $pwsh -NoProfile -File .\scripts\windows\install-or-repair-otel-collector.ps1 -ConfigSource '.\config.yaml'
                if ($LASTEXITCODE -ne 0) { throw "install-or-repair exit $LASTEXITCODE" }
            }
            if ($r.Aborted) { $failed = $true }
            elseif ($r.ExitCode -ne 0) { $failed = $true }
        }

        if (-not $failed) {
            $r = Run-Step 'health-check-collector-config' {
                & $pwsh -NoProfile -File .\scripts\windows\health-check-collector-config.ps1
                if ($LASTEXITCODE -ne 0) { throw "health-check exit $LASTEXITCODE" }
            }
            if ($r.Aborted) { $failed = $true }
            elseif ($r.ExitCode -ne 0) { $failed = $true }
        }

        # --- Phase 4: Prove ---
        if (-not $failed) {
            $r = Run-Step 'quick-monitor' {
                & $pwsh -NoProfile -File .\scripts\quick-monitor.ps1
            }
            if ($r.Aborted) { $failed = $true }
        }

        if (-not $failed) {
            $r = Run-Step 'canary-test' {
                & $pwsh -NoProfile -File .\canary-test.ps1
            }
            if ($r.Aborted) { $failed = $true }
        }

        if (-not $failed) {
            $r = Run-Step 'verify-pipeline' {
                & $pwsh -NoProfile -File .\BRAV\SCPT\verify-pipeline.ps1
                if ($LASTEXITCODE -ne 0) { throw "verify-pipeline exit $LASTEXITCODE" }
            }
            if ($r.Aborted) { $failed = $true }
            elseif ($r.ExitCode -ne 0) { $failed = $true }
        }
    }

    $clockEnd = Get-Date
    $totalMinutes = [math]::Round(($clockEnd - $clockStart).TotalMinutes, 2)

    # Final clock check
    $clockExceeded = $totalMinutes -gt $MaxMinutes

    # Determine verify exit
    $verifyStep = $steps | Where-Object { $_.name -eq 'verify-pipeline' } | Select-Object -Last 1
    $verifyExit = if ($verifyStep) { $verifyStep.exit_code } else { 1 }

    # Determine status
    $status = if ($clockExceeded -or $abortReason) {
        'RED'
    } elseif ($verifyExit -ne 0 -or $failed) {
        'RED'
    } else {
        'GREEN'
    }

    return @{
        Status        = $status
        ClockMinutes  = $totalMinutes
        ClockStartUtc = $clockStart.ToUniversalTime().ToString('o')
        ClockStopUtc  = $clockEnd.ToUniversalTime().ToString('o')
        VerifyExit    = $verifyExit
        HeadSha       = $headSha
        Steps         = $steps
        ClockExceeded = $clockExceeded
        AbortReason   = $abortReason
        Failed        = $failed
    }
}

# ============================================================================
# ARTIFACT GENERATION
# ============================================================================

function Write-TimingJson {
    param(
        [string]$Status,
        [hashtable]$ClockResult,
        [hashtable]$Phase0Result
    )

    $artifactsDir = Join-Path $RepoPath 'artifacts'
    if (-not (Test-Path $artifactsDir)) { New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null }

    $jsonPath = Join-Path $artifactsDir "clean-host-e2e-$stamp.json"

    $timing = [ordered]@{
        run_id               = $RunId
        status               = $Status
        gate_clock_minutes   = $ClockResult.ClockMinutes
        gate_clock_start_utc = $ClockResult.ClockStartUtc
        gate_clock_stop_utc  = $ClockResult.ClockStopUtc
        verify_exit          = $ClockResult.VerifyExit
        target_minutes       = $MaxMinutes
        head_sha             = $ClockResult.HeadSha
        steps                = [array]$ClockResult.Steps
        phase0_checkpoint    = [ordered]@{
            contamination_checks_passed = $Phase0Result.Passed
            docker_ok                   = $Phase0Result.Checks.docker_ok
            collector_state             = $Phase0Result.Checks.collector_state
            ports_free                  = $Phase0Result.Checks.ports_free
        }
        actor                = $Actor
        recorded_utc         = (Get-Date).ToUniversalTime().ToString('o')
    }

    if ($ClockResult.AbortReason) {
        $timing.abort_reason = $ClockResult.AbortReason
    }

    $timing | ConvertTo-Json -Depth 6 | Set-Content $jsonPath -Encoding utf8
    Write-Host "Timing JSON: $jsonPath" -ForegroundColor Green
    return $jsonPath
}

function Write-EcrrStub {
    param(
        [string]$Status,
        [hashtable]$ClockResult,
        [hashtable]$Phase0Result
    )

    $ecrrDir = Join-Path $RepoPath 'CHAR\ECRR\ECRR_REPORTS'
    if (-not (Test-Path $ecrrDir)) { New-Item -ItemType Directory -Path $ecrrDir -Force | Out-Null }

    $ecrrPath = Join-Path $ecrrDir "ECRR_CLEAN_HOST_E2E_$stamp.md"
    $today = Get-Date -Format 'yyyy-MM-dd'

    $verdictLine = switch ($Status) {
        'GREEN' { "**GREEN** -- clone -> first span **$($ClockResult.ClockMinutes) min** (target <=$MaxMinutes)" }
        'RED'   { "**RED** -- $($ClockResult.AbortReason; if (-not $ClockResult.AbortReason) { "verify exit $($ClockResult.VerifyExit)" })" }
        default { "**$Status** -- see details below" }
    }

    $stepsTable = ($ClockResult.Steps | ForEach-Object {
        "| $($_.name) | $($_.minutes) | $($_.exit_code) |"
    }) -join "`n"

    $content = @"
<!-- markdownlint-disable MD013 MD031 MD034 -->
# ECRR -- Clean-Host E2E (``$RunId``)

**Date:** $today
**Actor:** $Actor
**Verdict:** $verdictLine
**Artifacts:** ``artifacts/clean-host-e2e-$stamp.json``

---

## Examine

- Phase-0 contamination checkpoint: **PASSED**
- Docker: $( if ($Phase0Result.Checks.docker_ok) { 'responsive' } else { 'NOT responsive' } )
- Collector state at start: $($Phase0Result.Checks.collector_state)
- Ports $($script:OtelPorts.SignozOtlpGrpc)/$($script:OtelPorts.SignozOtlpHttp)/$($script:OtelPorts.IngestGrpc)/$($script:OtelPorts.IngestHttp)/$($script:OtelPorts.SignozUiHttp): $( if ($Phase0Result.Checks.ports_free) { 'all free' } else { 'BOUND (see failures)' } )
- HEAD: ``$($ClockResult.HeadSha)``

## Clean

| Step | Minutes | Exit |
|------|---------|------|
$stepsTable

Gate clock total: **$($ClockResult.ClockMinutes) min** (target <=$MaxMinutes)

## Report

- **Status:** $Status
- **Gate clock:** $($ClockResult.ClockMinutes) min
- **verify-pipeline exit:** $($ClockResult.VerifyExit)
$(if ($ClockResult.AbortReason) { "- **Abort reason:** $($ClockResult.AbortReason)" })

### Operator-only boundaries (not automation failures)

If this run stopped early, the following require human intervention:
1. Hyper-V snapshot restore (contamination recovery)
2. Elevated MSI install / service repair (Phase 0 setup)
3. Gate clock physical execution (elevated on guest)

## Role

- **Actor:** $Actor
- **Machine operator:** @fubumaki (elevated launch, Phase 0)
- **Spec:** ``.kiro/specs/clean-host-e2e-automation.md``
- **Briefing:** ``docs/BossCat/BRIEFING_KIRO_PILOT_CLEAN_HOST_E2E_AUTOMATION.md``
"@

    $content | Set-Content $ecrrPath -Encoding utf8
    Write-Host "ECRR stub: $ecrrPath" -ForegroundColor Green
    return $ecrrPath
}

function Append-BosscatLog {
    param(
        [string]$Status,
        [hashtable]$ClockResult
    )

    $logPath = Join-Path $RepoPath 'docs\BossCat\BOSSCAT_LOG.md'
    if (-not (Test-Path $logPath)) {
        Write-Host "WARNING: BOSSCAT_LOG.md not found at $logPath -- skipping append" -ForegroundColor Yellow
        return $null
    }

    $utcNow = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $details = if ($ClockResult.AbortReason) {
        $ClockResult.AbortReason
    } elseif ($Status -eq 'GREEN') {
        "all checks passed"
    } else {
        "verify exit $($ClockResult.VerifyExit)"
    }

    $entry = "- $utcNow -- **[CLEAN-HOST E2E $Status]** Run ``$RunId``: clone->first span **$($ClockResult.ClockMinutes) min** (target <=$MaxMinutes), verify exit $($ClockResult.VerifyExit). $details. ECRR: ``CHAR/ECRR/ECRR_REPORTS/ECRR_CLEAN_HOST_E2E_$stamp.md``; artifact ``artifacts/clean-host-e2e-$stamp.json``. -- **$Actor**"

    # Insert after the first bullet (newest-first order)
    $lines = Get-Content $logPath -Encoding utf8
    $insertIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^- \d{4}-') {
            $insertIdx = $i
            break
        }
    }

    if ($insertIdx -ge 0) {
        $newLines = @()
        $newLines += $lines[0..($insertIdx - 1)]
        $newLines += $entry
        $newLines += $lines[$insertIdx..($lines.Count - 1)]
        $newLines | Set-Content $logPath -Encoding utf8
    } else {
        # Append at end if no existing entries found
        Add-Content $logPath -Value "`n$entry" -Encoding utf8
    }

    Write-Host "BOSSCAT_LOG appended: $logPath" -ForegroundColor Green
    return $logPath
}

# ============================================================================
# MAIN
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  Clean-Host E2E Automation Wrapper" -ForegroundColor Magenta
Write-Host "  Run: $RunId" -ForegroundColor Magenta
Write-Host "  Actor: $Actor" -ForegroundColor Magenta
Write-Host "  Max: $MaxMinutes min" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

# --- Phase 0: Contamination check ---
$phase0 = Invoke-ContaminationCheck

if (-not $phase0.Passed) {
    Write-Host "`nCONTAMINATION DETECTED -- aborting" -ForegroundColor Red
    foreach ($f in $phase0.Failures) {
        Write-Fail $f
    }
    Write-Host "`nRemediation: Restore Hyper-V checkpoint to clean state (operator-only)." -ForegroundColor Yellow
    Write-Host "  Restore-VMSnapshot -VMName clean-host-e2e -Name phase0-ready-<date> -Confirm:`$false" -ForegroundColor DarkGray
    exit 10
}

Write-Host "Phase-0 checkpoint: ALL CLEAR" -ForegroundColor Green

# --- Gate clock: Phases 1-4 ---
Write-Host "`nGATE CLOCK START $(Get-Date -Format 'o')" -ForegroundColor Green
$clockResult = Invoke-GateClock -Phase0Result $phase0
Write-Host "`nGATE CLOCK STOP status=$($clockResult.Status) minutes=$($clockResult.ClockMinutes)" -ForegroundColor Green

# --- Generate artifacts ---
$status = $clockResult.Status

$jsonPath = Write-TimingJson -Status $status -ClockResult $clockResult -Phase0Result $phase0
$ecrrPath = Write-EcrrStub -Status $status -ClockResult $clockResult -Phase0Result $phase0

if (-not $SkipBosscatLog) {
    $logPath = Append-BosscatLog -Status $status -ClockResult $clockResult
}

# --- Summary ---
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  RESULT: $status" -ForegroundColor $(if ($status -eq 'GREEN') { 'Green' } else { 'Red' })
Write-Host "  Clock: $($clockResult.ClockMinutes) min" -ForegroundColor White
Write-Host "  Verify: exit $($clockResult.VerifyExit)" -ForegroundColor White
Write-Host "  JSON: $jsonPath" -ForegroundColor White
Write-Host "  ECRR: $ecrrPath" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Magenta

# --- Exit with appropriate code ---
if ($clockResult.ClockExceeded -or $clockResult.AbortReason) {
    exit 2
} elseif ($clockResult.VerifyExit -ne 0 -or $clockResult.Failed) {
    exit 1
} else {
    exit 0
}
