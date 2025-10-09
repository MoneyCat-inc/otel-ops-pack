# scripts/agent/policy-check.ps1 - OPA Policy validation for guardrails

param(
    [string]$ReportPath = ".agent/guardrails_report.json",
    [string]$PolicyPath = "policies/codex.rego",
    [string]$OpaPath = "$PSScriptRoot\opa.exe",
    [switch]$Json,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Write-PolicyResult {
    param(
        [string]$Message,
        [bool]$Success = $true
    )
    
    $color = if ($Success) { "Green" } else { "Red" }
    $icon = if ($Success) { "✅" } else { "❌" }
    Write-Host "$icon $Message" -ForegroundColor $color
}

# Import hardening utilities
. "$PSScriptRoot\utils\output-guard.ps1" -Json:$Json

if (-not $Json) {
    Write-Host "📋 codex-local Policy Check" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
}

# Check if OPA is available
if (-not (Test-Path $OpaPath)) {
    Write-PolicyResult -Message "OPA not found at $OpaPath" -Success $false
    if (-not $Json) {
        Write-Host "Please download OPA from: https://www.openpolicyagent.org/docs/latest/#running-opa" -ForegroundColor Yellow
        Write-Host "Extract opa.exe to: $PSScriptRoot" -ForegroundColor Yellow
    }
    exit 1
}

# Check if policy file exists
if (-not (Test-Path $PolicyPath)) {
    Write-PolicyResult -Message "Policy file not found: $PolicyPath" -Success $false
    exit 1
}

# Check if report file exists
if (-not (Test-Path $ReportPath)) {
    Write-PolicyResult -Message "Guardrails report not found: $ReportPath" -Success $false
    exit 1
}

# Read and validate report
try {
    $reportContent = Get-Content $ReportPath -Raw
    $report = $reportContent | ConvertFrom-Json
    
    if (-not $report.items) {
        $report.items = @()
    }
    if (-not $report.summary) {
        $report.summary = @{
            files_touched = 0
            lines_touched = 0
            violations = $report.items.Count
        }
    }
    
    Write-PolicyResult -Message "Report loaded: $($report.items.Count) violations"
} catch {
    Write-PolicyResult -Message "Failed to parse report: $($_.Exception.Message)" -Success $false
    exit 1
}

# Prepare input for OPA
$opaInput = @{
    items = $report.items
    summary = $report.summary
    metadata = @{
        timestamp = (Get-Date).ToString("o")
        report_path = $ReportPath
        policy_path = $PolicyPath
    }
} | ConvertTo-Json -Depth 10

# Run OPA evaluation
try {
    if (-not $Json) {
        Write-Host "`n🔍 Evaluating policy compliance..." -ForegroundColor Yellow
    }
    
    # Create temporary input file for OPA
    $tempInputFile = [System.IO.Path]::GetTempFileName()
    $opaInput | Set-Content $tempInputFile -Encoding UTF8
    
    # Run OPA eval for deny rules
    $denyQuery = "data.codex.guardrails.deny"
    $denyResult = & $OpaPath eval --format=json --data $PolicyPath --input $tempInputFile $denyQuery 2>$null
    
    # Run OPA eval for warn rules
    $warnQuery = "data.codex.guardrails.warn"
    $warnResult = & $OpaPath eval --format=json --data $PolicyPath --input $tempInputFile $warnQuery 2>$null
    
    # Run OPA eval for policy summary
    $summaryQuery = "data.codex.guardrails.policy_summary"
    $summaryResult = & $OpaPath eval --format=json --data $PolicyPath --input $tempInputFile $summaryQuery 2>$null
    
    # Run OPA eval for compliance status
    $complianceQuery = "data.codex.guardrails.compliant"
    $complianceResult = & $OpaPath eval --format=json --data $PolicyPath --input $tempInputFile $complianceQuery 2>$null
    
    # Clean up temp file
    Remove-Item $tempInputFile -Force -ErrorAction SilentlyContinue
    
    # Parse results
    $denyRules = $denyResult | ConvertFrom-Json
    $warnRules = $warnResult | ConvertFrom-Json
    $policySummary = $summaryResult | ConvertFrom-Json
    $compliant = $complianceResult | ConvertFrom-Json
    
    # Count violations
    $denyCount = if ($denyRules.result -and $denyRules.result.Count -gt 0) { $denyRules.result[0].expressions[0].value.Count } else { 0 }
    $warnCount = if ($warnRules.result -and $warnRules.result.Count -gt 0) { $warnRules.result[0].expressions[0].value.Count } else { 0 }
    
    # JSON output mode
    if ($Json) {
        $jsonOutput = @{
            compliant = $compliant.result[0].expressions[0].value
            deny_count = $denyCount
            warn_count = $warnCount
            policy_summary = $policySummary.result[0].expressions[0].value
            violations = if ($denyCount -gt 0) { $denyRules.result[0].expressions[0].value } else { @() }
            warnings = if ($warnCount -gt 0) { $warnRules.result[0].expressions[0].value } else { @() }
            timestamp = (Get-Date).ToString("o")
        }
        
        $jsonOutput | ConvertTo-Json -Depth 5
        exit $(if ($compliant.result[0].expressions[0].value) { 0 } else { 1 })
    }
    
    # Display results
    Write-Host "`n📊 Policy Evaluation Results:" -ForegroundColor White
    
    # Compliance status
    $complianceStatus = $compliant.result[0].expressions[0].value
    $complianceColor = if ($complianceStatus) { "Green" } else { "Red" }
    $complianceIcon = if ($complianceStatus) { "✅" } else { "❌" }
    Write-Host "$complianceIcon Compliance: $complianceStatus" -ForegroundColor $complianceColor
    
    # Violation counts
    Write-Host "🚫 Deny violations: $denyCount" -ForegroundColor $(if ($denyCount -eq 0) { "Green" } else { "Red" })
    Write-Host "⚠️  Warning violations: $warnCount" -ForegroundColor $(if ($warnCount -eq 0) { "Green" } else { "Yellow" })
    
    # Policy summary
    if ($policySummary.result -and $policySummary.result.Count -gt 0) {
        $summary = $policySummary.result[0].expressions[0].value
        Write-Host "`n📈 Policy Summary:" -ForegroundColor Cyan
        Write-Host "   Total violations: $($summary.total_violations)" -ForegroundColor Gray
        Write-Host "   Security violations: $($summary.security_violations)" -ForegroundColor Gray
        Write-Host "   Accessibility violations: $($summary.accessibility_violations)" -ForegroundColor Gray
        Write-Host "   Performance violations: $($summary.performance_violations)" -ForegroundColor Gray
        Write-Host "   Risk level: $($summary.risk_level)" -ForegroundColor Gray
    }
    
    # Display deny violations
    if ($denyCount -gt 0) {
        Write-Host "`n🚫 Policy Violations (Must Fix):" -ForegroundColor Red
        foreach ($violation in $denyRules.result[0].expressions[0].value) {
            Write-Host "   • $violation" -ForegroundColor Red
        }
    }
    
    # Display warnings
    if ($warnCount -gt 0) {
        Write-Host "`n⚠️  Policy Warnings (Should Fix):" -ForegroundColor Yellow
        foreach ($warning in $warnRules.result[0].expressions[0].value) {
            Write-Host "   • $warning" -ForegroundColor Yellow
        }
    }
    
    # Final result
    Write-Host "`n🎯 Policy Check Result: " -NoNewline
    Write-Host $(if ($complianceStatus) { "PASS" } else { "FAIL" }) -ForegroundColor $complianceColor
    
    # Exit with appropriate code
    exit $(if ($complianceStatus) { 0 } else { 1 })
    
} catch {
    Write-PolicyResult -Message "Policy evaluation failed: $($_.Exception.Message)" -Success $false
    if (-not $Json) {
        Write-Host "OPA command error details:" -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor Gray
    }
    exit 1
}
