# scripts/agent/doctor.ps1
# codex-local Local Workflow Custodian - Full environment diagnostic sweep
# This script performs comprehensive health checks of the local development setup
# Updated with progress indicators for better user experience

# Import progress indicators module
. .\scripts\progress-indicators.ps1

[CmdletBinding()]
param(
    [switch]$Detailed,
    [switch]$Fix
)

$ErrorActionPreference = "Stop"

Write-Host "[agent:doctor] codex-local Local Workflow Custodian - Health Diagnostics" -ForegroundColor Cyan
Write-Host "[agent:doctor] ==================================================================" -ForegroundColor Cyan

# 1. Check for .agent/LOCK kill-switch
$lockPath = ".agent/LOCK"
if (Test-Path $lockPath) {
    Write-Host "[agent:doctor] ✗ Agent is LOCKED. Remove .agent/LOCK to proceed." -ForegroundColor Red
    Write-Host "[agent:doctor] Lock file found at: $lockPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "[agent:doctor] ✓ No lock file detected, proceeding with diagnostics..." -ForegroundColor Green

# Initialize results tracking
$diagnosticsResults = @{
    runtime_versions = @{ status = "unknown"; details = @() }
    agent_state_files = @{ status = "unknown"; details = @() }
    security_policy = @{ status = "unknown"; details = @() }
    accessibility_audit = @{ status = "unknown"; details = @() }
    dev_environment = @{ status = "unknown"; details = @() }
    guardrails = @{ status = "unknown"; details = @() }
}

# 2. Verify runtime versions
Write-Host "[agent:doctor] Checking runtime versions..." -ForegroundColor Yellow
$spinnerJob = Start-SpinnerJob -Message "Checking runtime versions..." -UpdateIntervalMs 150

# Check Node.js version
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVersion = (node --version)
    $nodeMatch = $nodeVersion -match "v(\d+)\.(\d+)\.(\d+)"
    if ($nodeMatch) {
        $majorVersion = [int]$matches[1]
        if ($majorVersion -ge 18) {
            $diagnosticsResults.runtime_versions.details += "✓ Node.js: $nodeVersion (meets requirement >=18.0.0)"
            Write-Host "[agent:doctor] ✓ Node.js: $nodeVersion" -ForegroundColor Green
        } else {
            $diagnosticsResults.runtime_versions.details += "✗ Node.js: $nodeVersion (below required v18.0.0)"
            Write-Host "[agent:doctor] ✗ Node.js: $nodeVersion (below required v18.0.0)" -ForegroundColor Red
            $diagnosticsResults.runtime_versions.status = "fail"
        }
    }
} else {
    $diagnosticsResults.runtime_versions.details += "✗ Node.js not found in PATH"
    Write-Host "[agent:doctor] ✗ Node.js not found in PATH" -ForegroundColor Red
    $diagnosticsResults.runtime_versions.status = "fail"
}

# Check PNPM version
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    $pnpmVersion = (pnpm --version)
    $diagnosticsResults.runtime_versions.details += "✓ PNPM: $pnpmVersion"
    Write-Host "[agent:doctor] ✓ PNPM: $pnpmVersion" -ForegroundColor Green
} else {
    $diagnosticsResults.runtime_versions.details += "✗ PNPM not found in PATH"
    Write-Host "[agent:doctor] ✗ PNPM not found in PATH" -ForegroundColor Red
    $diagnosticsResults.runtime_versions.status = "fail"
}

if ($diagnosticsResults.runtime_versions.status -eq "unknown") {
    $diagnosticsResults.runtime_versions.status = "pass"
}

Stop-SpinnerJob -Job $spinnerJob

# 3. Check agent state files
Write-Host "[agent:doctor] Checking agent state files..." -ForegroundColor Yellow
$spinnerJob = Start-SpinnerJob -Message "Checking agent state files..." -UpdateIntervalMs 150

$requiredFiles = @(
    @{ path = ".agent/config.json"; description = "Agent configuration" }
    @{ path = ".agent/state.json"; description = "Agent state tracking" }
    @{ path = ".agent/status.json"; description = "Agent status" }
    @{ path = ".agent/agent_queue.json"; description = "Agent task queue" }
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file.path) {
        try {
            $content = Get-Content $file.path -Raw | ConvertFrom-Json
            $diagnosticsResults.agent_state_files.details += "✓ $($file.description): Present and valid JSON"
            Write-Host "[agent:doctor] ✓ $($file.description): Present and valid" -ForegroundColor Green
        } catch {
            $diagnosticsResults.agent_state_files.details += "✗ $($file.description): Invalid JSON format"
            Write-Host "[agent:doctor] ✗ $($file.description): Invalid JSON format" -ForegroundColor Red
            $diagnosticsResults.agent_state_files.status = "fail"
        }
    } else {
        $diagnosticsResults.agent_state_files.details += "✗ $($file.description): Missing"
        Write-Host "[agent:doctor] ✗ $($file.description): Missing" -ForegroundColor Red
        $diagnosticsResults.agent_state_files.status = "fail"
    }
}

if ($diagnosticsResults.agent_state_files.status -eq "unknown") {
    $diagnosticsResults.agent_state_files.status = "pass"
}

Stop-SpinnerJob -Job $spinnerJob

# 4. Security policy validation (CSP and Cross-Origin Isolation)
Write-Host "[agent:doctor] Checking security policies..." -ForegroundColor Yellow
$spinnerJob = Start-SpinnerJob -Message "Checking security policies..." -UpdateIntervalMs 150

# Check for inline styles in frontend code
$inlineStyleViolations = @()
$htmlFiles = Get-ChildItem -Recurse -Include "*.html", "*.jsx", "*.tsx", "*.js", "*.ts" | Where-Object { $_.FullName -notmatch "node_modules|\.git|third_party" }

foreach ($file in $htmlFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match 'style\s*=\s*["'']') {
        $inlineStyleViolations += "$($file.Name): Inline style detected"
    }
    if ($content -match 'dangerouslySetInnerHTML') {
        $inlineStyleViolations += "$($file.Name): dangerouslySetInnerHTML usage detected"
    }
}

if ($inlineStyleViolations.Count -eq 0) {
    $diagnosticsResults.security_policy.details += "✓ No inline styles detected"
    Write-Host "[agent:doctor] ✓ No inline styles detected" -ForegroundColor Green
} else {
    $diagnosticsResults.security_policy.details += "✗ Found $($inlineStyleViolations.Count) inline style violations"
    Write-Host "[agent:doctor] ✗ Found $($inlineStyleViolations.Count) inline style violations" -ForegroundColor Red
    foreach ($violation in $inlineStyleViolations) {
        $diagnosticsResults.security_policy.details += "  - $violation"
        Write-Host "[agent:doctor]   - $violation" -ForegroundColor Yellow
    }
    $diagnosticsResults.security_policy.status = "fail"
}

# Check for CSP configuration in config files
$configFiles = Get-ChildItem -Recurse -Include "*.json", "*.yaml", "*.yml", "*.js", "*.ts" | Where-Object { $_.Name -match "(config|next|webpack)" -and $_.FullName -notmatch "node_modules" }
$cspFound = $false

foreach ($file in $configFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match 'Content-Security-Policy|CSP') {
        $cspFound = $true
        break
    }
}

if ($cspFound) {
    $diagnosticsResults.security_policy.details += "✓ CSP configuration detected"
    Write-Host "[agent:doctor] ✓ CSP configuration detected" -ForegroundColor Green
} else {
    $diagnosticsResults.security_policy.details += "⚠ CSP configuration not found (may be configured elsewhere)"
    Write-Host "[agent:doctor] ⚠ CSP configuration not found" -ForegroundColor Yellow
}

if ($diagnosticsResults.security_policy.status -eq "unknown") {
    $diagnosticsResults.security_policy.status = if ($inlineStyleViolations.Count -eq 0) { "pass" } else { "fail" }
}

# 5. Accessibility (a11y) audit
Write-Host "[agent:doctor] Running accessibility audit..." -ForegroundColor Yellow

$a11yViolations = @()
foreach ($file in $htmlFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Check for missing alt text on images
        if ($content -match '<img[^>]*(?<!alt\s*=\s*["'']*["''])[^>]*>') {
        $a11yViolations += "$($file.Name): Image without alt text"
    }
    
    # Check for buttons without discernible text or aria-label
    if ($content -match '<button[^>]*(?<!aria-label\s*=\s*["'']*["''])(?<!aria-labelledby\s*=\s*["'']*["''])[^>]*>(?!\s*<[^>]*>.*</[^>]*>|\s*\w+\s*)') {
        $a11yViolations += "$($file.Name): Button without discernible text or aria-label"
    }
    
    # Check for form inputs without labels
    if ($content -match '<input[^>]*(?<!aria-label\s*=\s*["'']*["''])(?<!aria-labelledby\s*=\s*["'']*["''])[^>]*>') {
        $a11yViolations += "$($file.Name): Input without label or aria-label"
    }
}

if ($a11yViolations.Count -eq 0) {
    $diagnosticsResults.accessibility_audit.details += "✓ No obvious accessibility violations detected"
    Write-Host "[agent:doctor] ✓ No obvious accessibility violations detected" -ForegroundColor Green
} else {
    $diagnosticsResults.accessibility_audit.details += "✗ Found $($a11yViolations.Count) accessibility violations"
    Write-Host "[agent:doctor] ✗ Found $($a11yViolations.Count) accessibility violations" -ForegroundColor Red
    foreach ($violation in $a11yViolations) {
        $diagnosticsResults.accessibility_audit.details += "  - $violation"
        Write-Host "[agent:doctor]   - $violation" -ForegroundColor Yellow
    }
    $diagnosticsResults.accessibility_audit.status = "fail"
}

if ($diagnosticsResults.accessibility_audit.status -eq "unknown") {
    $diagnosticsResults.accessibility_audit.status = "pass"
}

# 6. Dev environment health
Write-Host "[agent:doctor] Checking development environment..." -ForegroundColor Yellow

# Check if pnpm install worked
if (Test-Path "node_modules") {
    $diagnosticsResults.dev_environment.details += "✓ node_modules directory exists"
    Write-Host "[agent:doctor] ✓ node_modules directory exists" -ForegroundColor Green
} else {
    $diagnosticsResults.dev_environment.details += "✗ node_modules directory missing"
    Write-Host "[agent:doctor] ✗ node_modules directory missing" -ForegroundColor Red
    $diagnosticsResults.dev_environment.status = "fail"
}

# Check for package.json
if (Test-Path "package.json") {
    $diagnosticsResults.dev_environment.details += "✓ package.json exists"
    Write-Host "[agent:doctor] ✓ package.json exists" -ForegroundColor Green
} else {
    $diagnosticsResults.dev_environment.details += "✗ package.json missing"
    Write-Host "[agent:doctor] ✗ package.json missing" -ForegroundColor Red
    $diagnosticsResults.dev_environment.status = "fail"
}

# Check for OTel collector service (Windows specific)
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    try {
        $service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -eq "Running") {
                $diagnosticsResults.dev_environment.details += "✓ OTel Collector service is running"
                Write-Host "[agent:doctor] ✓ OTel Collector service is running" -ForegroundColor Green
            } else {
                $diagnosticsResults.dev_environment.details += "⚠ OTel Collector service exists but is $($service.Status)"
                Write-Host "[agent:doctor] ⚠ OTel Collector service is $($service.Status)" -ForegroundColor Yellow
            }
        } else {
            $diagnosticsResults.dev_environment.details += "⚠ OTel Collector service not found"
            Write-Host "[agent:doctor] ⚠ OTel Collector service not found" -ForegroundColor Yellow
        }
    } catch {
        $diagnosticsResults.dev_environment.details += "⚠ Could not check OTel Collector service status"
        Write-Host "[agent:doctor] ⚠ Could not check OTel Collector service status" -ForegroundColor Yellow
    }
}

if ($diagnosticsResults.dev_environment.status -eq "unknown") {
    $diagnosticsResults.dev_environment.status = "pass"
}

# 7. Guardrails enforcement check
Write-Host "[agent:doctor] Checking guardrails enforcement..." -ForegroundColor Yellow

$guardrailViolations = 0
$totalChecks = 3

# CSP violations
if ($inlineStyleViolations.Count -gt 0) {
    $guardrailViolations++
}

# A11y violations  
if ($a11yViolations.Count -gt 0) {
    $guardrailViolations++
}

# Runtime version issues
if ($diagnosticsResults.runtime_versions.status -eq "fail") {
    $guardrailViolations++
}

if ($guardrailViolations -eq 0) {
    $diagnosticsResults.guardrails.details += "✓ All guardrails passed ($totalChecks/$totalChecks)"
    Write-Host "[agent:doctor] ✓ All guardrails passed ($totalChecks/$totalChecks)" -ForegroundColor Green
    $diagnosticsResults.guardrails.status = "pass"
} else {
    $diagnosticsResults.guardrails.details += "✗ $guardrailViolations/$totalChecks guardrails failed"
    Write-Host "[agent:doctor] ✗ $guardrailViolations/$totalChecks guardrails failed" -ForegroundColor Red
    $diagnosticsResults.guardrails.status = "fail"
}

# 8. Summary and status update
Write-Host "[agent:doctor] ==================================================================" -ForegroundColor Cyan
Write-Host "[agent:doctor] DIAGNOSTICS SUMMARY" -ForegroundColor Cyan
Write-Host "[agent:doctor] ==================================================================" -ForegroundColor Cyan

$overallStatus = "pass"
foreach ($category in $diagnosticsResults.Keys) {
    $result = $diagnosticsResults[$category]
    $status = if ($result.status -eq "pass") { "✓" } elseif ($result.status -eq "fail") { "✗" } else { "⚠" }
    $color = if ($result.status -eq "pass") { "Green" } elseif ($result.status -eq "fail") { "Red" } else { "Yellow" }
    
    Write-Host "[agent:doctor] $status $($category.Replace('_', ' ').ToUpper()): $($result.status.ToUpper())" -ForegroundColor $color
    
    if ($result.status -eq "fail") {
        $overallStatus = "fail"
    }
    
    if ($Detailed -and $result.details.Count -gt 0) {
        foreach ($detail in $result.details) {
            Write-Host "[agent:doctor]   $detail" -ForegroundColor White
        }
    }
}

Write-Host "[agent:doctor] ==================================================================" -ForegroundColor Cyan
Write-Host "[agent:doctor] OVERALL STATUS: $($overallStatus.ToUpper())" -ForegroundColor $(if ($overallStatus -eq "pass") { "Green" } else { "Red" })
Write-Host "[agent:doctor] ==================================================================" -ForegroundColor Cyan

# Update agent status
try {
    pwsh -File scripts/agent/update-status.ps1 -section env -ok ($overallStatus -eq "pass") -detail "Health diagnostics: $overallStatus"
    pwsh -File scripts/agent/update-status.ps1 -section guardrails -ok ($diagnosticsResults.guardrails.status -eq "pass") -detail "Guardrails: $($diagnosticsResults.guardrails.status)"
} catch {
    Write-Host "[agent:doctor] ⚠ Status update failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Log diagnostics completion
$logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') – Health diagnostics completed: $overallStatus"
if (Test-Path "TASKS.md") {
    $logEntry | Add-Content "TASKS.md"
} else {
    $logEntry | Set-Content "TASKS.md"
}

# Exit with appropriate code
if ($overallStatus -eq "fail") {
    exit 1
} else {
    exit 0
}
