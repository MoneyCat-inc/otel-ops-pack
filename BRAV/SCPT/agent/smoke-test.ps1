# scripts/agent/smoke-test.ps1 - Quick smoke matrix for premium features

param(
    [switch]$All,
    [switch]$Demo,
    [switch]$Status,
    [switch]$Guardrails,
    [switch]$Lock
)

$ErrorActionPreference = "Stop"

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    $color = if ($Passed) { "Green" } else { "Red" }
    $icon = if ($Passed) { "✅" } else { "❌" }
    Write-Host "$icon $TestName" -ForegroundColor $color
    if ($Details) {
        Write-Host "   $Details" -ForegroundColor Gray
    }
}

function Test-ExitCode {
    param(
        [string]$Command,
        [int]$ExpectedExitCode = 0,
        [string]$TestName
    )
    
    try {
        $result = Invoke-Expression $Command
        $actualExitCode = $LASTEXITCODE
        
        if ($actualExitCode -eq $ExpectedExitCode) {
            Write-TestResult -TestName $TestName -Passed $true -Details "Exit code: $actualExitCode"
            return $true
        } else {
            Write-TestResult -TestName $TestName -Passed $false -Details "Expected: $ExpectedExitCode, Got: $actualExitCode"
            return $false
        }
    } catch {
        Write-TestResult -TestName $TestName -Passed $false -Details "Error: $($_.Exception.Message)"
        return $false
    }
}

function Test-JsonOutput {
    param(
        [string]$Command,
        [string]$TestName
    )
    
    try {
        $output = Invoke-Expression $Command 2>$null
        # Clean the output - remove any PowerShell header text
        $cleanOutput = $output | Where-Object { $_ -match '^[\s]*[{\[]' } | Select-Object -First 1
        if (-not $cleanOutput) {
            $cleanOutput = $output -join "`n"
        }
        
        $json = $cleanOutput | ConvertFrom-Json
        
        if ($json) {
            Write-TestResult -TestName $TestName -Passed $true -Details "Valid JSON with $(($json.PSObject.Properties | Measure-Object).Count) properties"
            return $true
        } else {
            Write-TestResult -TestName $TestName -Passed $false -Details "Invalid or empty JSON"
            return $false
        }
    } catch {
        Write-TestResult -TestName $TestName -Passed $false -Details "JSON parse error: $($_.Exception.Message)"
        return $false
    }
}

function Test-QuietOutput {
    param(
        [string]$Command,
        [string]$ExpectedPattern,
        [string]$TestName
    )
    
    try {
        $output = Invoke-Expression $Command 2>$null
        # Clean the output - get just the last line which should contain the result
        $cleanOutput = $output | Where-Object { $_ -match $ExpectedPattern } | Select-Object -Last 1
        
        if ($cleanOutput) {
            Write-TestResult -TestName $TestName -Passed $true -Details "Output: $cleanOutput"
            return $true
        } else {
            Write-TestResult -TestName $TestName -Passed $false -Details "Output doesn't match pattern: '$ExpectedPattern'. Got: '$($output -join ' ')'"
            return $false
        }
    } catch {
        Write-TestResult -TestName $TestName -Passed $false -Details "Error: $($_.Exception.Message)"
        return $false
    }
}

Write-Host "🔥 codex-local Premium Features Smoke Test" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$totalTests = 0
$passedTests = 0

# Demo tests
if ($All -or $Demo) {
    Write-Host "`n📋 Testing Demo Features" -ForegroundColor Yellow
    
    # Basic demo (should succeed)
    $totalTests++
    if (Test-ExitCode -Command "pnpm agent:demo-premium -Quiet" -ExpectedExitCode 0 -TestName "Demo Premium (Quiet)") {
        $passedTests++
    }
    
    # Demo with detached (should succeed)
    $totalTests++
    if (Test-ExitCode -Command "pnpm agent:demo-premium -Fix -Detached -Quiet" -ExpectedExitCode 0 -TestName "Demo Premium (Detached)") {
        $passedTests++
    }
}

# Status tests
if ($All -or $Status) {
    Write-Host "`n📊 Testing Status Features" -ForegroundColor Yellow
    
    # Status detailed
    $totalTests++
    if (Test-ExitCode -Command "pnpm agent:status-premium -Detailed" -ExpectedExitCode 0 -TestName "Status Premium (Detailed)") {
        $passedTests++
    }
    
    # Status continuous (quick test)
    $totalTests++
    if (Test-ExitCode -Command "Start-Process -FilePath 'pnpm' -ArgumentList 'agent:status-premium','-Continuous','-Quiet' -Wait -TimeoutSec 5 -PassThru | ForEach-Object { $_.ExitCode }" -ExpectedExitCode 0 -TestName "Status Premium (Continuous)") {
        $passedTests++
    }
    
    # Status JSON output
    $totalTests++
    if (Test-JsonOutput -Command "pnpm agent:status-premium -Json" -TestName "Status Premium (JSON)") {
        $passedTests++
    }
    
    # Status quiet output
    $totalTests++
    if (Test-QuietOutput -Command "pnpm agent:status-premium -Quiet" -ExpectedPattern "^ACTIVE - \d+ violations$|^LOCKED - \d+ violations$" -TestName "Status Premium (Quiet)") {
        $passedTests++
    }
}

# Guardrails tests
if ($All -or $Guardrails) {
    Write-Host "`n🛡️ Testing Guardrails Features" -ForegroundColor Yellow
    
    # Guardrails report-only
    $totalTests++
    if (Test-ExitCode -Command "pnpm agent:guardrails-premium -ReportOnly" -ExpectedExitCode 0 -TestName "Guardrails Premium (Report-Only)") {
        $passedTests++
    }
    
    # Guardrails with budget
    $totalTests++
    if (Test-ExitCode -Command "pnpm agent:guardrails-premium -Fix -MaxFiles 5 -MaxLines 100" -ExpectedExitCode 0 -TestName "Guardrails Premium (Budgeted)") {
        $passedTests++
    }
    
    # Guardrails JSON output
    $totalTests++
    if (Test-JsonOutput -Command "pnpm agent:guardrails-premium -Json" -TestName "Guardrails Premium (JSON)") {
        $passedTests++
    }
    
    # Guardrails quiet output
    $totalTests++
    if (Test-QuietOutput -Command "pnpm agent:guardrails-premium -Quiet" -ExpectedPattern "^PASS - \d+ violations found$|^FAIL - \d+ violations found$" -TestName "Guardrails Premium (Quiet)") {
        $passedTests++
    }
}

# Lock tests
if ($All -or $Lock) {
    Write-Host "`n🔒 Testing Lock Features" -ForegroundColor Yellow
    
    # Create lock file
    "manual lock test" | Set-Content .agent/LOCK
    
    # Status should show locked
    $totalTests++
    if (Test-QuietOutput -Command "pnpm agent:status-premium -Quiet" -ExpectedPattern "^LOCKED - \d+ violations$" -TestName "Status with Lock File") {
        $passedTests++
    }
    
    # Status JSON should show locked state
    $totalTests++
    $lockJson = pnpm agent:status-premium -Json | ConvertFrom-Json
    if ($lockJson.lock -eq $true -and $lockJson.status -eq "locked") {
        Write-TestResult -TestName "Status JSON with Lock" -Passed $true -Details "Lock detected correctly"
        $passedTests++
    } else {
        Write-TestResult -TestName "Status JSON with Lock" -Passed $false -Details "Lock not detected in JSON"
    }
    $totalTests++
    
    # Remove lock file
    Remove-Item .agent/LOCK -ErrorAction SilentlyContinue
    
    # Status should show active again
    $totalTests++
    if (Test-QuietOutput -Command "pnpm agent:status-premium -Quiet" -ExpectedPattern "^ACTIVE - \d+ violations$" -TestName "Status after Lock Removal") {
        $passedTests++
    }
}

# Summary
Write-Host "`n📈 Test Summary" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
Write-Host "Tests Run: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $($totalTests - $passedTests)" -ForegroundColor Red

$successRate = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -eq 100) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })

if ($passedTests -eq $totalTests) {
    Write-Host "`n🎉 All tests passed! Premium features are working correctly." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️ Some tests failed. Check the output above for details." -ForegroundColor Yellow
    exit 1
}
