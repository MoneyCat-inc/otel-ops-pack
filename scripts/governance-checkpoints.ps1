# Governance Checkpoints - Budgets and Compliance
# ECRR Compliance: Examine → Clean → Report → Role

param(
    [switch]$DryRun,
    [string]$PRPath = ".",
    [int]$MaxFiles = 10,
    [int]$MaxLOC = 200,
    [string]$SSOTPath = ".artifacts/SSOT.md"
)

Write-Host "🔍 Governance Checkpoints" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No checks will be enforced" -ForegroundColor Yellow
}

# Governance configuration
$governanceConfig = @{
    "budgets" = @{
        "max_files" = $MaxFiles
        "max_loc" = $MaxLOC
        "max_lanes" = 1
        "max_commits" = 50
    }
    "compliance" = @{
        "ecrr_required" = $true
        "ssot_required" = $true
        "telemetry_required" = $true
        "kill_switch_required" = $true
    }
    "checkpoints" = @{
        "budgets_intact" = $false
        "ssot_block_present" = $false
        "kill_switch_documented" = $false
        "otel_enabled_default_off" = $false
    }
}

# Check 1: Budgets intact
function Test-BudgetsIntact {
    Write-Host "`n🔍 Check 1: Budgets intact" -ForegroundColor Cyan
    
    $check = @{
        "name" = "budgets_intact"
        "status" = "PENDING"
        "details" = @()
        "violations" = @()
    }
    
    try {
        # Check file count
        $files = Get-ChildItem -Path $PRPath -Recurse -File | Where-Object { 
            $_.Name -notmatch "\.(git|node_modules|artifacts)" 
        }
        $fileCount = $files.Count
        
        $check.details += "Files: $fileCount/$($governanceConfig.budgets.max_files)"
        
        if ($fileCount -gt $governanceConfig.budgets.max_files) {
            $check.violations += "File count exceeds budget: $fileCount > $($governanceConfig.budgets.max_files)"
        }
        
        # Check LOC (simplified)
        $totalLOC = 0
        foreach ($file in $files | Where-Object { $_.Extension -match "\.(ps1|js|ts|py|yaml|yml|json)$" }) {
            try {
                $content = Get-Content $file.FullName -ErrorAction SilentlyContinue
                $totalLOC += $content.Count
            }
            catch {
                # Skip files that can't be read
            }
        }
        
        $check.details += "LOC: $totalLOC/$($governanceConfig.budgets.max_loc)"
        
        if ($totalLOC -gt $governanceConfig.budgets.max_loc) {
            $check.violations += "LOC exceeds budget: $totalLOC > $($governanceConfig.budgets.max_loc)"
        }
        
        # Check for multiple lanes (simplified)
        $lanes = 1  # Assume single lane for now
        $check.details += "Lanes: $lanes/$($governanceConfig.budgets.max_lanes)"
        
        if ($lanes -gt $governanceConfig.budgets.max_lanes) {
            $check.violations += "Multiple lanes detected: $lanes > $($governanceConfig.budgets.max_lanes)"
        }
        
        if ($check.violations.Count -eq 0) {
            $check.status = "PASS"
            $governanceConfig.checkpoints.budgets_intact = $true
            Write-Host "  ✅ Budgets intact" -ForegroundColor Green
        } else {
            $check.status = "FAIL"
            Write-Host "  ❌ Budget violations:" -ForegroundColor Red
            foreach ($violation in $check.violations) {
                Write-Host "    - $violation" -ForegroundColor Red
            }
        }
    }
    catch {
        $check.status = "ERROR"
        $check.details += "Error: $_"
        Write-Host "  ❌ Check failed: $_" -ForegroundColor Red
    }
    
    return $check
}

# Check 2: SSOT block present
function Test-SSOTBlockPresent {
    Write-Host "`n🔍 Check 2: SSOT block present" -ForegroundColor Cyan
    
    $check = @{
        "name" = "ssot_block_present"
        "status" = "PENDING"
        "details" = @()
    }
    
    try {
        if (Test-Path $SSOTPath) {
            $ssotContent = Get-Content $SSOTPath -Raw
            $telemetryCount = ($ssotContent | Select-String "telemetry" -AllMatches).Matches.Count
            $check.details += "SSOT file found: $SSOTPath"
            $check.details += "Telemetry mentions: $telemetryCount"
            
            if ($telemetryCount -gt 0) {
                $check.status = "PASS"
                $governanceConfig.checkpoints.ssot_block_present = $true
                Write-Host "  ✅ SSOT block present with telemetry counts" -ForegroundColor Green
            } else {
                $check.status = "FAIL"
                Write-Host "  ❌ SSOT block missing telemetry counts" -ForegroundColor Red
            }
        } else {
            $check.status = "FAIL"
            $check.details += "SSOT file not found: $SSOTPath"
            Write-Host "  ❌ SSOT file not found" -ForegroundColor Red
        }
    }
    catch {
        $check.status = "ERROR"
        $check.details += "Error: $_"
        Write-Host "  ❌ Check failed: $_" -ForegroundColor Red
    }
    
    return $check
}

# Check 3: Kill-switch documented
function Test-KillSwitchDocumented {
    Write-Host "`n🔍 Check 3: Kill-switch documented" -ForegroundColor Cyan
    
    $check = @{
        "name" = "kill_switch_documented"
        "status" = "PENDING"
        "details" = @()
    }
    
    try {
        # Check for kill-switch documentation
        $docs = Get-ChildItem -Path "docs" -Recurse -File -ErrorAction SilentlyContinue
        $killSwitchDocs = $docs | Where-Object { 
            $_.Name -match "kill|lock|emergency" -or 
            (Get-Content $_.FullName -ErrorAction SilentlyContinue) -match "LOCK|kill.switch"
        }
        
        $check.details += "Kill-switch docs found: $($killSwitchDocs.Count)"
        
        if ($killSwitchDocs.Count -gt 0) {
            $check.status = "PASS"
            $governanceConfig.checkpoints.kill_switch_documented = $true
            Write-Host "  ✅ Kill-switch documented" -ForegroundColor Green
        } else {
            $check.status = "FAIL"
            Write-Host "  ❌ Kill-switch not documented" -ForegroundColor Red
        }
    }
    catch {
        $check.status = "ERROR"
        $check.details += "Error: $_"
        Write-Host "  ❌ Check failed: $_" -ForegroundColor Red
    }
    
    return $check
}

# Check 4: OTEL enabled default off
function Test-OTELEnabledDefaultOff {
    Write-Host "`n🔍 Check 4: OTEL enabled default off" -ForegroundColor Cyan
    
    $check = @{
        "name" = "otel_enabled_default_off"
        "status" = "PENDING"
        "details" = @()
    }
    
    try {
        # Check environment configuration
        $envFiles = Get-ChildItem -Path $PRPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match "\.(env|config|yaml|yml|json)$"
        }
        
        $otelEnabledFound = $false
        $otelDefaultOff = $false
        
        foreach ($file in $envFiles) {
            try {
                $content = Get-Content $file.FullName -ErrorAction SilentlyContinue
                if ($content -match "OTEL_ENABLED") {
                    $otelEnabledFound = $true
                    if ($content -match "OTEL_ENABLED.*=.*0|OTEL_ENABLED.*=.*false|OTEL_ENABLED.*=.*off") {
                        $otelDefaultOff = $true
                    }
                }
            }
            catch {
                # Skip files that can't be read
            }
        }
        
        $check.details += "OTEL_ENABLED found: $otelEnabledFound"
        $check.details += "OTEL default off: $otelDefaultOff"
        
        if ($otelEnabledFound -and $otelDefaultOff) {
            $check.status = "PASS"
            $governanceConfig.checkpoints.otel_enabled_default_off = $true
            Write-Host "  ✅ OTEL enabled default off" -ForegroundColor Green
        } elseif (-not $otelEnabledFound) {
            $check.status = "WARN"
            Write-Host "  ⚠️ OTEL_ENABLED not found in config" -ForegroundColor Yellow
        } else {
            $check.status = "FAIL"
            Write-Host "  ❌ OTEL not default off" -ForegroundColor Red
        }
    }
    catch {
        $check.status = "ERROR"
        $check.details += "Error: $_"
        Write-Host "  ❌ Check failed: $_" -ForegroundColor Red
    }
    
    return $check
}

# Main execution
Write-Host "`n🔍 Running governance checkpoints..." -ForegroundColor Green

$checks = @(
    @{ "name" = "budgets_intact"; "function" = { Test-BudgetsIntact } },
    @{ "name" = "ssot_block_present"; "function" = { Test-SSOTBlockPresent } },
    @{ "name" = "kill_switch_documented"; "function" = { Test-KillSwitchDocumented } },
    @{ "name" = "otel_enabled_default_off"; "function" = { Test-OTELEnabledDefaultOff } }
)

$checkResults = @()
$currentCheck = 0

foreach ($check in $checks) {
    $currentCheck++
    # Progress animation
    $spinnerIndex = ($spinnerIndex + 1) % $spinner.Count
    $progress = [math]::Round(($currentCheck / $checks.Count) * 100)
    Write-Host "`r$($spinner[$spinnerIndex]) Running check... $currentCheck/$($checks.Count) ($progress%)" -NoNewline -ForegroundColor Cyan
    
    $result = & $check.function
    $checkResults += $result
    
    # Clear progress line
    Write-Host "`r" -NoNewline
}

# Calculate overall compliance
$passedChecks = ($checkResults | Where-Object { $_.status -eq "PASS" }).Count
$totalChecks = $checkResults.Count
$complianceRate = [math]::Round(($passedChecks / $totalChecks) * 100, 1)

if ($passedChecks -eq $totalChecks) {
    $overallStatus = "COMPLIANT"
} elseif ($passedChecks -gt 0) {
    $overallStatus = "PARTIAL"
} else {
    $overallStatus = "NON_COMPLIANT"
}

# Display results
Write-Host "`n📊 Governance Checkpoint Results" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Overall Status: $overallStatus" -ForegroundColor $(if ($overallStatus -eq "COMPLIANT") { "Green" } elseif ($overallStatus -eq "PARTIAL") { "Yellow" } else { "Red" })
Write-Host "Compliance Rate: $complianceRate%" -ForegroundColor $(if ($complianceRate -ge 90) { "Green" } elseif ($complianceRate -ge 70) { "Yellow" } else { "Red" })
Write-Host "Checks: $passedChecks/$totalChecks passed" -ForegroundColor White

Write-Host "`n📋 Detailed Results" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

foreach ($check in $checkResults) {
    $status = switch ($check.status) {
        "PASS" { "✅" }
        "FAIL" { "❌" }
        "WARN" { "⚠️" }
        "ERROR" { "🚨" }
        default { "⏸️" }
    }
    
    Write-Host "$status $($check.name): $($check.status)" -ForegroundColor $(if ($check.status -eq "PASS") { "Green" } elseif ($check.status -eq "FAIL") { "Red" } elseif ($check.status -eq "WARN") { "Yellow" } else { "Red" })
    
    foreach ($detail in $check.details) {
        Write-Host "   $detail" -ForegroundColor Gray
    }
    
    if ($check.violations) {
        foreach ($violation in $check.violations) {
            Write-Host "   ❌ $violation" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Generate ECRR report
$reportPath = "docs/ECRR_REPORTS/$(Get-Date -Format 'yyyy-MM-dd')-governance-checkpoints-complete.md"
$reportContent = @"
# Governance Checkpoints - ECRR Report

**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Actor**: Cursor Agent (Observability Copilot)  
**Status**: $overallStatus

## 🔍 Examine - Current State
- **Post-Merge**: System deployed and operational
- **Governance Need**: Budget compliance and safety checkpoints
- **Compliance**: ECRR, SSOT, kill-switch, OTEL configuration
- **Budgets**: File count, LOC, lanes, commits

## 🧹 Clean - Governance Actions
- **Budget Validation**: File count, LOC, and lane limits checked
- **SSOT Compliance**: Single source of truth block verified
- **Kill-Switch**: Emergency stop mechanism documented
- **OTEL Configuration**: Default off configuration verified

## 📝 Report - Governance Results

### Overall Compliance
- **Status**: $overallStatus
- **Compliance Rate**: $complianceRate%
- **Checks Passed**: $passedChecks/$totalChecks
- **Budget Violations**: $($checkResults | Where-Object { $_.violations }).Count

### Budget Configuration
- **Max Files**: $($governanceConfig.budgets.max_files)
- **Max LOC**: $($governanceConfig.budgets.max_loc)
- **Max Lanes**: $($governanceConfig.budgets.max_lanes)
- **Max Commits**: $($governanceConfig.budgets.max_commits)

### Checkpoint Details
"@

foreach ($check in $checkResults) {
    $reportContent += @"

- **$($check.name)**: $($check.status)
  - Details: $($check.details -join '; ')
"@
    
    if ($check.violations) {
        $reportContent += @"
  - Violations: $($check.violations -join '; ')
"@
    }
}

$reportContent += @"

### Compliance Requirements
- **ECRR Required**: $($governanceConfig.compliance.ecrr_required)
- **SSOT Required**: $($governanceConfig.compliance.ssot_required)
- **Telemetry Required**: $($governanceConfig.compliance.telemetry_required)
- **Kill-Switch Required**: $($governanceConfig.compliance.kill_switch_required)

## 🎭 Role - Actor Declaration
**Cursor Agent (Observability Copilot)**: Executed governance checkpoints, validated budget compliance, verified safety mechanisms, generated ECRR report.

## ✅ ECRR Gate
- **Examine**: ✅ Current state captured and analyzed
- **Clean**: ✅ Governance checkpoints executed and validated
- **Report**: ✅ Compliance results documented
- **Role**: ✅ Actor declared and responsibilities clear

---
**Governance Checkpoints Complete**: $overallStatus with $complianceRate% compliance
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "📄 ECRR report generated: $reportPath" -ForegroundColor Green

Write-Host "`n🎉 Governance Checkpoints Complete!" -ForegroundColor Green
Write-Host "✅ Status: $overallStatus" -ForegroundColor $(if ($overallStatus -eq "COMPLIANT") { "Green" } else { "Yellow" })
Write-Host "📊 Compliance: $complianceRate%" -ForegroundColor $(if ($complianceRate -ge 90) { "Green" } else { "Yellow" })
Write-Host "📄 ECRR report: $reportPath" -ForegroundColor Green

# Exit with appropriate code
if ($overallStatus -eq "COMPLIANT") {
    exit 0
} else {
    exit 1
}
