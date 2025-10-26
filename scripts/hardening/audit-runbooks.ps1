# Gate #024 - Track 2: Runbook Hardening Audit
# Authority: Fubumaki + BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Verify all runbooks have kill-switches, budgets, recovery paths

param(
    [string]$RunbookDir = "docs/runbooks",
    [string]$OutputDir = "DELT/ARTF"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #024 Track 2: Runbook Hardening Audit ===" -ForegroundColor Cyan
Write-Host ""

# Get all runbooks
$runbooks = Get-ChildItem -Path $RunbookDir -Filter "*.md" -File
Write-Host "Found $($runbooks.Count) runbook(s) to audit" -ForegroundColor White
Write-Host ""

$results = @()

foreach ($rb in $runbooks) {
    Write-Host "Auditing: $($rb.Name)" -ForegroundColor Cyan
    $content = Get-Content $rb.FullName -Raw
    
    # Check for required sections
    $hasKillSwitch = $content -match "(?i)(kill.?switch|emergency|halt|stop|disable)"
    $hasRecovery = $content -match "(?i)(recovery|rollback|restore|revert)"
    $hasBudget = $content -match "(?i)(budget|LOC|lines of code|file limit)"
    $hasTroubleshooting = $content -match "(?i)(troubleshoot|debug|common (issues|problems))"
    $hasECRR = $content -match "(?i)(ECRR|evidence|examine|clean|report|role)"
    
    # Count troubleshooting scenarios
    $troubleshootCount = ([regex]::Matches($content, "(?i)###\s+(troubleshoot|symptoms?|diagnosis|resolution|common (cause|issue))")).Count
    
    $audit = [PSCustomObject]@{
        runbook = $rb.Name
        path = $rb.FullName
        has_kill_switch = $hasKillSwitch
        has_recovery = $hasRecovery
        has_budget = $hasBudget
        has_troubleshooting = $hasTroubleshooting
        troubleshooting_scenarios = $troubleshootCount
        has_ecrr = $hasECRR
        compliant = ($hasKillSwitch -and $hasRecovery -and $hasTroubleshooting)
        recommendations = @()
    }
    
    # Generate recommendations
    if (-not $hasKillSwitch) { $audit.recommendations += "Add kill-switch/emergency stop procedure" }
    if (-not $hasRecovery) { $audit.recommendations += "Add recovery/rollback procedure" }
    if (-not $hasBudget) { $audit.recommendations += "Add budget documentation (LOC, files, duration)" }
    if ($troubleshootCount -lt 3) { $audit.recommendations += "Add more troubleshooting scenarios (current: $troubleshootCount, target: ≥3)" }
    if (-not $hasECRR) { $audit.recommendations += "Add ECRR evidence generation guidance" }
    
    # Display results
    Write-Host "  Kill-Switch: $(if ($hasKillSwitch) { '✓' } else { '✗' })" -ForegroundColor $(if ($hasKillSwitch) { 'Green' } else { 'Red' })
    Write-Host "  Recovery: $(if ($hasRecovery) { '✓' } else { '✗' })" -ForegroundColor $(if ($hasRecovery) { 'Green' } else { 'Red' })
    Write-Host "  Budget Docs: $(if ($hasBudget) { '✓' } else { '✗' })" -ForegroundColor $(if ($hasBudget) { 'Green' } else { 'Yellow' })
    Write-Host "  Troubleshooting: $troubleshootCount scenarios $(if ($troubleshootCount -ge 3) { '✓' } else { '✗' })" -ForegroundColor $(if ($troubleshootCount -ge 3) { 'Green' } else { 'Yellow' })
    Write-Host "  ECRR Guidance: $(if ($hasECRR) { '✓' } else { '✗' })" -ForegroundColor $(if ($hasECRR) { 'Green' } else { 'Yellow' })
    Write-Host "  Status: $(if ($audit.compliant) { 'COMPLIANT' } else { 'NEEDS WORK' })" -ForegroundColor $(if ($audit.compliant) { 'Green' } else { 'Yellow' })
    
    if ($audit.recommendations.Count -gt 0) {
        Write-Host "  Recommendations:" -ForegroundColor Yellow
        foreach ($rec in $audit.recommendations) {
            Write-Host "    - $rec" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    $results += $audit
}

# Summary
$compliant = ($results | Where-Object { $_.compliant }).Count
$total = $results.Count
$complianceRate = if ($total -gt 0) { ($compliant / $total) * 100 } else { 0 }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Audit Summary" -ForegroundColor White
Write-Host "  Total runbooks: $total" -ForegroundColor White
Write-Host "  Compliant: $compliant ($($complianceRate.ToString('0'))%)" -ForegroundColor $(if ($complianceRate -ge 80) { 'Green' } else { 'Yellow' })
Write-Host "  Needs work: $($total - $compliant)" -ForegroundColor $(if (($total - $compliant) -eq 0) { 'Green' } else { 'Yellow' })
Write-Host ""

# Generate evidence
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$evidence = @{
    gate = 24
    track = "hardening"
    phase = "runbook-audit"
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
    summary = @{
        total_runbooks = $total
        compliant = $compliant
        compliance_rate = $complianceRate
        needs_work = $total - $compliant
    }
    runbooks = $results | ForEach-Object {
        @{
            name = $_.runbook
            compliant = $_.compliant
            checks = @{
                kill_switch = $_.has_kill_switch
                recovery = $_.has_recovery
                budget = $_.has_budget
                troubleshooting = $_.has_troubleshooting
                troubleshooting_count = $_.troubleshooting_scenarios
                ecrr = $_.has_ecrr
            }
            recommendations = $_.recommendations
        }
    }
} | ConvertTo-Json -Depth 8

$evidencePath = "$OutputDir/gate-024-track2-runbook-audit-$timestamp.json"
$evidence | Out-File -Encoding utf8 $evidencePath

Write-Host "Evidence: $evidencePath" -ForegroundColor White
Write-Host ""

if ($complianceRate -lt 100) {
    Write-Host "⚠️  Some runbooks need updates. Review recommendations above." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✅ All runbooks compliant" -ForegroundColor Green
    exit 0
}

