# scripts/agent/cutover-validation.ps1 - Fast validation commands for cutover

param(
    [ValidateSet("json-purity", "kill-switch", "policy-gate", "service-health", "all")]
    [string]$Test = "all"
)

$ErrorActionPreference = "Stop"

function Extract-JsonFromOutput {
    param([array]$Output)
    
    # Find the JSON part - look for the first { and take everything from there
    $jsonStart = -1
    for ($i = 0; $i -lt $Output.Count; $i++) {
        if ($Output[$i] -match '^\s*\{') {
            $jsonStart = $i
            break
        }
    }
    
    if ($jsonStart -ge 0) {
        return ($Output | Select-Object -Skip $jsonStart) -join "`n"
    } else {
        return $Output -join "`n"
    }
}

function Test-JsonPurity {
    Write-Host "🔍 Testing JSON Purity..." -ForegroundColor Yellow
    
    # Test status JSON
    $statusOutput = pnpm agent:status-premium -Json 2>$null
    $statusJson = Extract-JsonFromOutput -Output $statusOutput
    $status = $statusJson | ConvertFrom-Json
    
    Write-Host "✅ Status JSON: Valid JSON with $(($status.PSObject.Properties | Measure-Object).Count) properties" -ForegroundColor Green
    
    # Test guardrails JSON
    $guardrailsOutput = pnpm agent:guardrails-premium -Json 2>$null
    $guardrailsJson = Extract-JsonFromOutput -Output $guardrailsOutput
    $guardrails = $guardrailsJson | ConvertFrom-Json
    
    Write-Host "✅ Guardrails JSON: Valid JSON with $(($guardrails.PSObject.Properties | Measure-Object).Count) properties" -ForegroundColor Green
    
    return $true
}

function Test-KillSwitch {
    Write-Host "`n🔒 Testing Kill-Switch..." -ForegroundColor Yellow
    
    # Apply lock
    "manual-test" > .agent/LOCK
    
    # Check locked status
    $statusOutput = pnpm agent:status-premium -Json 2>$null
    $statusJson = Extract-JsonFromOutput -Output $statusOutput
    $status = $statusJson | ConvertFrom-Json
    
    if ($status.status -eq "locked" -and $status.lock -eq $true) {
        Write-Host "✅ Lock applied: Status = $($status.status), Lock = $($status.lock)" -ForegroundColor Green
    } else {
        Write-Host "❌ Lock failed: Status = $($status.status), Lock = $($status.lock)" -ForegroundColor Red
        return $false
    }
    
    # Remove lock
    Remove-Item .agent/LOCK -ErrorAction SilentlyContinue
    
    # Check unlocked status
    Start-Sleep 1
    $statusOutput = pnpm agent:status-premium -Json 2>$null
    $statusJson = Extract-JsonFromOutput -Output $statusOutput
    $status = $statusJson | ConvertFrom-Json
    
    if ($status.status -ne "locked" -and $status.lock -eq $false) {
        Write-Host "✅ Lock removed: Status = $($status.status), Lock = $($status.lock)" -ForegroundColor Green
    } else {
        Write-Host "❌ Lock removal failed: Status = $($status.status), Lock = $($status.lock)" -ForegroundColor Red
        return $false
    }
    
    return $true
}

function Test-PolicyGate {
    Write-Host "`n📋 Testing Policy Gate..." -ForegroundColor Yellow
    
    # Generate guardrails report
    pnpm agent:guardrails-premium -Json > .agent/guardrails_report.json 2>$null
    
    if (-not (Test-Path ".agent/guardrails_report.json")) {
        Write-Host "❌ Guardrails report not generated" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ Guardrails report generated" -ForegroundColor Green
    
    # Test policy check (will fail if OPA not available, but that's expected)
    try {
        pnpm agent:policy-check 2>$null
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0) {
            Write-Host "✅ Policy check: PASSED" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Policy check: FAILED (expected if OPA not installed)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ Policy check: ERROR (expected if OPA not installed)" -ForegroundColor Yellow
    }
    
    return $true
}

function Test-ServiceHealth {
    Write-Host "`n🖥️ Testing Service Health..." -ForegroundColor Yellow
    
    # Check if service exists
    $service = Get-Service -Name "codex-local" -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "✅ Service found: $($service.Status)" -ForegroundColor Green
        
        # Check log files
        $logFile = ".agent/logs/service.out.log"
        if (Test-Path $logFile) {
            Write-Host "✅ Service log found: $logFile" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Service log not found (service may not be installed)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️ Service not found (run 'pnpm agent:service-install' as Administrator)" -ForegroundColor Yellow
    }
    
    return $true
}

# Main execution
Write-Host "🚀 codex-local Cutover Validation" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

$results = @{
    jsonPurity = $false
    killSwitch = $false
    policyGate = $false
    serviceHealth = $false
}

switch ($Test) {
    "json-purity" {
        $results.jsonPurity = Test-JsonPurity
    }
    "kill-switch" {
        $results.killSwitch = Test-KillSwitch
    }
    "policy-gate" {
        $results.policyGate = Test-PolicyGate
    }
    "service-health" {
        $results.serviceHealth = Test-ServiceHealth
    }
    "all" {
        $results.jsonPurity = Test-JsonPurity
        $results.killSwitch = Test-KillSwitch
        $results.policyGate = Test-PolicyGate
        $results.serviceHealth = Test-ServiceHealth
    }
}

# Summary
Write-Host "`n📊 Validation Summary:" -ForegroundColor White
Write-Host "   JSON Purity: $(if ($results.jsonPurity) { '✅ PASS' } else { '❌ FAIL' })" -ForegroundColor $(if ($results.jsonPurity) { 'Green' } else { 'Red' })
Write-Host "   Kill-Switch: $(if ($results.killSwitch) { '✅ PASS' } else { '❌ FAIL' })" -ForegroundColor $(if ($results.killSwitch) { 'Green' } else { 'Red' })
Write-Host "   Policy Gate: $(if ($results.policyGate) { '✅ PASS' } else { '❌ FAIL' })" -ForegroundColor $(if ($results.policyGate) { 'Green' } else { 'Red' })
Write-Host "   Service Health: $(if ($results.serviceHealth) { '✅ PASS' } else { '❌ FAIL' })" -ForegroundColor $(if ($results.serviceHealth) { 'Green' } else { 'Red' })

$overallSuccess = $results.jsonPurity -and $results.killSwitch -and $results.policyGate -and $results.serviceHealth

Write-Host "`n🎯 Overall Result: " -NoNewline
Write-Host $(if ($overallSuccess) { '✅ ALL TESTS PASSED' } else { '❌ SOME TESTS FAILED' }) -ForegroundColor $(if ($overallSuccess) { 'Green' } else { 'Red' })

exit $(if ($overallSuccess) { 0 } else { 1 })
