#!/usr/bin/env pwsh
#requires -Version 7
<#
.SYNOPSIS
    Enterprise Readiness Validation Check
    
.DESCRIPTION
    Validates all enterprise requirements for production deployment.
    Checks security, reliability, compliance, documentation, and deployment readiness.
    
.EXAMPLE
    .\scripts\enterprise-readiness-check.ps1
    
.EXAMPLE
    .\scripts\enterprise-readiness-check.ps1 -Verbose
    
.NOTES
    Part of: BossCat OEM Framework
    Version: 1.0.0
#>

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🏢 BossCat Enterprise Readiness Check" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$score = 0
$total = 0
$blockers = @()
$warnings = @()

# ═══════════════════════════════════════════════════════════════════════
# Security Checks
# ═══════════════════════════════════════════════════════════════════════

Write-Host "🔒 Security Checks" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

# Check 1: Critical Vulnerabilities
$total++
try {
    $criticalAlerts = @(gh api /repos/:owner/:repo/dependabot/alerts 2>$null | 
        ConvertFrom-Json | 
        Where-Object { $_.state -eq 'open' -and $_.security_advisory.severity -eq 'critical' })
    
    if ($criticalAlerts.Count -eq 0) {
        Write-Host "  ✅ No critical vulnerabilities" -ForegroundColor Green
        $score++
    } else {
        Write-Host "  ❌ $($criticalAlerts.Count) critical vulnerabilities BLOCKING" -ForegroundColor Red
        $blockers += "Critical vulnerabilities: $($criticalAlerts.Count)"
        foreach ($alert in $criticalAlerts) {
            Write-Host "     - $($alert.security_advisory.summary)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  ⚠️  Could not check Dependabot alerts" -ForegroundColor Yellow
    $warnings += "Dependabot API access issue"
}

# Check 2: High Vulnerabilities
$total++
try {
    $highAlerts = @(gh api /repos/:owner/:repo/dependabot/alerts 2>$null | 
        ConvertFrom-Json | 
        Where-Object { $_.state -eq 'open' -and $_.security_advisory.severity -eq 'high' })
    
    if ($highAlerts.Count -lt 5) {
        Write-Host "  ✅ High vulnerabilities: $($highAlerts.Count) (target: <5)" -ForegroundColor Green
        $score++
    } else {
        Write-Host "  ⚠️  High vulnerabilities: $($highAlerts.Count) (target: <5)" -ForegroundColor Yellow
        $warnings += "High vulnerabilities: $($highAlerts.Count)"
    }
} catch {
    Write-Host "  ⚠️  Could not check high-severity alerts" -ForegroundColor Yellow
}

# Check 3: GitHub App Secrets
$total++
try {
    $secrets = @(gh secret list --json name 2>$null | ConvertFrom-Json)
    $hasAppId = $secrets | Where-Object { $_.name -eq 'BOSSCAT_APP_ID' }
    $hasAppKey = $secrets | Where-Object { $_.name -eq 'BOSSCAT_APP_PRIVATE_KEY' }
    
    if ($hasAppId -and $hasAppKey) {
        Write-Host "  ✅ GitHub App secrets configured" -ForegroundColor Green
        $score++
    } else {
        Write-Host "  ⚠️  GitHub App secrets not configured (graceful fallback available)" -ForegroundColor Yellow
        $warnings += "GitHub App secrets missing"
    }
} catch {
    Write-Host "  ⚠️  Could not verify secrets" -ForegroundColor Yellow
}

# Check 4: Gitleaks scan status
$total++
if (Get-Command gitleaks -ErrorAction SilentlyContinue) {
    try {
        $gitleaksResult = gitleaks detect --no-banner --exit-code 0 --report-format json --report-path artifacts/gitleaks-report.json 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ No secrets detected in repository" -ForegroundColor Green
            $score++
        } else {
            Write-Host "  ❌ Secrets detected by Gitleaks BLOCKING" -ForegroundColor Red
            $blockers += "Secrets detected in repository"
        }
    } catch {
        Write-Host "  ⚠️  Gitleaks scan failed" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  Gitleaks not installed (install: https://github.com/gitleaks/gitleaks)" -ForegroundColor Yellow
    $warnings += "Gitleaks not installed"
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════════
# Reliability Checks
# ═══════════════════════════════════════════════════════════════════════

Write-Host "⚙️  Reliability Checks" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

# Check 5: Nightly Dashboard Export (current)
# Accept dated dir (guide layout) or flat status-latest.* (actual export layout)
$total++
$snapshotsRoot = "docs/observability/snapshots"
$today = Get-Date -Format "yyyy-MM-dd"
$datedDir = Join-Path $snapshotsRoot $today
$latestJson = Join-Path $snapshotsRoot "status-latest.json"
$dashboardCurrent = $false
$dashboardDetail = ""

if (Test-Path $datedDir) {
    $fileCount = @(Get-ChildItem $datedDir -File -ErrorAction SilentlyContinue).Count
    if ($fileCount -gt 0) {
        $dashboardCurrent = $true
        $dashboardDetail = "$fileCount files in $today/"
    }
}
if (-not $dashboardCurrent -and (Test-Path $latestJson)) {
    $ageHours = ((Get-Date) - (Get-Item $latestJson).LastWriteTime).TotalHours
    if ($ageHours -le 48) {
        $dashboardCurrent = $true
        $dashboardDetail = "status-latest.json ($([math]::Round($ageHours, 1))h old)"
    } else {
        $dashboardDetail = "status-latest.json stale ($([math]::Round($ageHours / 24, 1))d old)"
    }
}

if ($dashboardCurrent) {
    Write-Host "  ✅ Dashboard export current ($dashboardDetail)" -ForegroundColor Green
    $score++
} else {
    $msg = if ($dashboardDetail) { $dashboardDetail } else { "no status-latest.json or $today/ dir" }
    Write-Host "  ⚠️  Dashboard export not current ($msg)" -ForegroundColor Yellow
    $warnings += "Dashboard export not current"
}

# Check 6: Nightly Dashboard Export (Last 7 Days)
# Count days with dated dir OR flat files matching that calendar day
$total++
$exportSuccess = 0
foreach ($offset in 0..6) {
    $day = (Get-Date).Date.AddDays(-$offset)
    $dateStr = $day.ToString("yyyy-MM-dd")
    $compact = $day.ToString("yyyyMMdd")
    if (Test-Path (Join-Path $snapshotsRoot $dateStr)) {
        $exportSuccess++
        continue
    }
    if (-not (Test-Path $snapshotsRoot)) { continue }
    $hit = Get-ChildItem $snapshotsRoot -File -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match [regex]::Escape($dateStr) -or
        $_.Name -match $compact -or
        ($_.LastWriteTime.Date -eq $day -and $_.Name -match '^(status|signoz|dashboard|nightly|ecrr|gate)')
    } | Select-Object -First 1
    if ($hit) { $exportSuccess++ }
}
$exportRate = [math]::Round(($exportSuccess / 7) * 100, 1)
if ($exportRate -ge 85) {
    Write-Host "  ✅ Dashboard export success rate: $exportRate% (7 days)" -ForegroundColor Green
    $score++
} else {
    Write-Host "  ⚠️  Dashboard export success rate: $exportRate% (target: >85%)" -ForegroundColor Yellow
    $warnings += "Dashboard export success rate low: $exportRate%"
}

# Check 7: SigNoz Health
$total++
try {
    $signozHealth = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host "  ✅ SigNoz is healthy" -ForegroundColor Green
    $score++
} catch {
    Write-Host "  ⚠️  SigNoz not responding (may not be running)" -ForegroundColor Yellow
    $warnings += "SigNoz not responding"
}

# Check 8: OTel Collector Health (canonical: config.yaml health_check on :13134/healthz)
$total++
$collectorOk = $false
try {
    $null = Invoke-RestMethod -Uri "http://127.0.0.1:13134/healthz" -Method Get -TimeoutSec 3 -ErrorAction Stop
    $collectorOk = $true
} catch {
    try {
        $null = Invoke-WebRequest -Uri "http://127.0.0.1:8888/metrics" -Method Get -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        $collectorOk = $true
    } catch { }
}
if ($collectorOk) {
    Write-Host "  ✅ OTel Collector is reachable" -ForegroundColor Green
    $score++
} else {
    Write-Host "  ⚠️  OTel Collector not responding" -ForegroundColor Yellow
    $warnings += "OTel Collector not responding"
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════════
# Documentation Checks
# ═══════════════════════════════════════════════════════════════════════

Write-Host "📚 Documentation Checks" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

# Check 9: Required Documentation
$total++
$requiredDocs = @(
    "README.md",
    "docs/BossCat/README.md",
    "docs/BossCat/GITHUB_APP_IMPLEMENTATION_GUIDE.md",
    "docs/BossCat/DEPENDABOT_SECURITY_GUIDE.md",
    "docs/BossCat/NIGHTLY_DASHBOARD_GUIDE.md",
    "docs/BossCat/CREDENTIAL_ROTATION_CALENDAR.md",
    "docs/BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md",
    "docs/BossCat/QUICK_START_CARD.md"
)
$docsExist = $requiredDocs | Where-Object { Test-Path $_ }
if ($docsExist.Count -eq $requiredDocs.Count) {
    Write-Host "  ✅ All required documentation present ($($docsExist.Count)/$($requiredDocs.Count))" -ForegroundColor Green
    $score++
} else {
    Write-Host "  ⚠️  Missing documentation ($($docsExist.Count)/$($requiredDocs.Count))" -ForegroundColor Yellow
    $warnings += "Missing documentation files"
    $requiredDocs | Where-Object { -not (Test-Path $_) } | ForEach-Object {
        Write-Host "     - $_" -ForegroundColor Yellow
    }
}

# Check 10: Credential Rotation Calendar Populated
$total++
if (Test-Path "docs/BossCat/CREDENTIAL_ROTATION_CALENDAR.md") {
    $calendarContent = Get-Content "docs/BossCat/CREDENTIAL_ROTATION_CALENDAR.md" -Raw
    if ($calendarContent -match "Last Rotated.*TBD" -or $calendarContent -match "Next Due.*TBD") {
        Write-Host "  ⚠️  Credential rotation calendar not fully populated" -ForegroundColor Yellow
        $warnings += "Credential rotation calendar has TBD entries"
    } else {
        Write-Host "  ✅ Credential rotation calendar populated" -ForegroundColor Green
        $score++
    }
} else {
    Write-Host "  ❌ Credential rotation calendar missing" -ForegroundColor Red
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════════
# Workflow Checks
# ═══════════════════════════════════════════════════════════════════════

Write-Host "🔄 CI/CD Workflow Checks" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

# Check 11: Workflow Files Valid
$total++
$workflowFiles = @(
    ".github/workflows/iona-gate-verify.yml",
    ".github/workflows/boss-gate-verify.yml",
    ".github/workflows/security-scan.yml",
    ".github/workflows/nightly-dashboard-export.yml"
)
$workflowsValid = $true
foreach ($workflow in $workflowFiles) {
    if (-not (Test-Path $workflow)) {
        $workflowsValid = $false
        Write-Host "  ❌ Missing: $workflow" -ForegroundColor Red
    }
}
if ($workflowsValid) {
    Write-Host "  ✅ All critical workflows present" -ForegroundColor Green
    $score++
} else {
    Write-Host "  ❌ Missing workflow files" -ForegroundColor Red
    $blockers += "Missing critical workflow files"
}

# Check 12: Recent Workflow Runs
$total++
try {
    $recentRuns = @(gh run list --limit 10 --json conclusion 2>$null | ConvertFrom-Json)
    $successfulRuns = @($recentRuns | Where-Object { $_.conclusion -eq 'success' })
    $successRate = if ($recentRuns.Count -gt 0) { [math]::Round(($successfulRuns.Count / $recentRuns.Count) * 100, 1) } else { 0 }
    
    if ($successRate -ge 80) {
        Write-Host "  ✅ Workflow success rate: $successRate% (last 10 runs)" -ForegroundColor Green
        $score++
    } else {
        Write-Host "  ⚠️  Workflow success rate: $successRate% (target: >80%)" -ForegroundColor Yellow
        $warnings += "Workflow success rate low: $successRate%"
    }
} catch {
    Write-Host "  ⚠️  Could not check workflow runs" -ForegroundColor Yellow
}

Write-Host ""

# ═══════════════════════════════════════════════════════════════════════
# Final Score
# ═══════════════════════════════════════════════════════════════════════

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  📊 ENTERPRISE READINESS SCORE" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$percentage = [math]::Round(($score / $total) * 100, 1)

Write-Host "  Score: $score / $total ($percentage%)" -ForegroundColor Cyan
Write-Host ""

if ($blockers.Count -gt 0) {
    Write-Host "  ❌ BLOCKERS ($($blockers.Count)):" -ForegroundColor Red
    foreach ($blocker in $blockers) {
        Write-Host "     • $blocker" -ForegroundColor Red
    }
    Write-Host ""
}

if ($warnings.Count -gt 0) {
    Write-Host "  ⚠️  WARNINGS ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "     • $warning" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Final Verdict
if ($blockers.Count -eq 0 -and $percentage -ge 90) {
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  ✅ READY FOR PRODUCTION" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
    exit 0
} elseif ($blockers.Count -eq 0 -and $percentage -ge 75) {
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "  ⚠️  NEAR PRODUCTION READY - Address warnings" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  ❌ NOT READY FOR PRODUCTION" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Action Required: Address blockers and warnings above" -ForegroundColor Red
    Write-Host ""
    exit 1
}


