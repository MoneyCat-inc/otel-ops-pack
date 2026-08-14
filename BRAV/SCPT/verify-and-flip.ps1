# BossCat OEM - Verify and Flip Gate
# One-command verification with automatic gate status update

<#
.SYNOPSIS
  Runs verification and automatically updates gate status based on outcome.

.DESCRIPTION
  This wrapper script:
  1. Runs verify-pipeline.ps1 to perform full verification
  2. Reads the outcome from gate_verification.json
  3. Automatically updates gate status (APPROVED/HOLD) with reason
  4. Returns appropriate exit code for CI/CD

.PARAMETER Strict
  If set, treats WARN outcomes as HOLD instead of APPROVED.
  Recommended for production environments.

.EXAMPLE
  pwsh -File BRAV\SCPT\verify-and-flip.ps1
  # Non-strict: WARN keeps APPROVED but annotated

.EXAMPLE
  pwsh -File BRAV\SCPT\verify-and-flip.ps1 -Strict
  # Strict: WARN forces HOLD
#>

[CmdletBinding()]
param(
  [switch]$Strict  # Treat WARN as HOLD
)

$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "🐾 BossCat OEM - Verify and Flip Gate" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray

if ($Strict) {
  Write-Host "⚠️  STRICT MODE: WARN outcomes will trigger HOLD" -ForegroundColor Yellow
  Write-Host ""
}

# --- 0) Preflight check (fail fast with actionable fixes) ---
Write-Host "[verify-and-flip] Running preflight check..." -ForegroundColor Cyan
& pwsh -NoProfile -File (Join-Path $here "preflight.ps1")

if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "❌ Preflight failed - fix issues above before verification" -ForegroundColor Red
  exit 2
}

Write-Host "[verify-and-flip] ✅ Preflight passed" -ForegroundColor Green
Write-Host ""

# --- 1) Run verification ---
Write-Host "[verify-and-flip] Running pipeline verification..." -ForegroundColor Cyan
& pwsh -NoProfile -File (Join-Path $here "verify-pipeline.ps1")
$verifyExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "[verify-and-flip] Verification completed with exit code: $verifyExitCode" -ForegroundColor Gray

# --- 2) Read outcome from JSON ---
$jsonPath = Join-Path $here "..\out\gate_verification.json"
if (-not (Test-Path $jsonPath)) {
  Write-Error "Verification JSON not found at: $jsonPath"
  exit 2
}

try {
  $j = Get-Content $jsonPath -Raw | ConvertFrom-Json
  $outcome = $j.outcome
  $exitCode = $j.exit_code
  
  Write-Host "[verify-and-flip] Outcome: $outcome (exit code: $exitCode)" -ForegroundColor Cyan
} catch {
  Write-Error "Failed to read verification JSON: $_"
  exit 2
}

# --- 3) Decide gate status ---
$toStatus = $null
$reason = $null

switch ($outcome) {
  "OK" {
    $toStatus = "APPROVED"
    $reason = "Forensic-grade verification passed"
    Write-Host "[verify-and-flip] ✅ Verification passed - setting gate to APPROVED" -ForegroundColor Green
  }
  "WARN" {
    if ($Strict) {
      $toStatus = "HOLD"
      $reason = "Verification WARN under strict policy"
      Write-Host "[verify-and-flip] ⚠️  Verification WARN - setting gate to HOLD (strict mode)" -ForegroundColor Yellow
    } else {
      $toStatus = "APPROVED"
      $reason = "Verification WARN; approved under non-strict policy"
      Write-Host "[verify-and-flip] ⚠️  Verification WARN - keeping gate APPROVED (non-strict mode)" -ForegroundColor Yellow
    }
  }
  "FAIL" {
    $toStatus = "HOLD"
    $reason = "Verification failed; holding gate"
    Write-Host "[verify-and-flip] ❌ Verification FAILED - setting gate to HOLD" -ForegroundColor Red
  }
  default {
    $toStatus = "HOLD"
    $reason = "Unknown verification outcome: $outcome"
    Write-Host "[verify-and-flip] ❌ Unknown outcome - setting gate to HOLD" -ForegroundColor Red
  }
}

# --- 4) Flip gate with reason ---
Write-Host ""
Write-Host "[verify-and-flip] Updating gate status..." -ForegroundColor Cyan

try {
  & pwsh -NoProfile -File (Join-Path $here "set-gate-status.ps1") `
    -Status $toStatus `
    -Reason $reason
  
  Write-Host "[verify-and-flip] ✅ Gate status updated" -ForegroundColor Green
} catch {
  Write-Warning "[verify-and-flip] Failed to update gate status: $_"
}

# --- 5) Display summary ---
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   Verification Outcome: $outcome" -ForegroundColor White
Write-Host "   Gate Status: $toStatus" -ForegroundColor White
Write-Host "   Reason: $reason" -ForegroundColor White
Write-Host "   Exit Code: $exitCode" -ForegroundColor White

# Add forensic details if available
if ($j.steps.canary_send.trace_id) {
  Write-Host ""
  Write-Host "🔬 Forensic Details:" -ForegroundColor Cyan
  Write-Host "   Trace ID: $($j.steps.canary_send.trace_id.Substring(0,16))..." -ForegroundColor White
  Write-Host "   Canary ID: $($j.steps.canary_send.canary_id)" -ForegroundColor White
  Write-Host "   API Mode: $($j.steps.canary_send.api_mode)" -ForegroundColor White
  if ($j.steps.canary_send.ingest_latency_ms) {
    Write-Host "   Ingest Latency: $($j.steps.canary_send.ingest_latency_ms) ms" -ForegroundColor White
  }
}

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray

# --- 6) Exit with appropriate code ---
# Exit 0 if OK, non-zero otherwise (for CI/CD)
$finalExitCode = if ($outcome -eq "OK") { 0 } else { 1 }
Write-Host ""
Write-Host "🐾 BossCat OEM - Complete (exit $finalExitCode)" -ForegroundColor Cyan
exit $finalExitCode

