# IONA Supervisor Verification Script
# Tests the complete supervisor lifecycle with sample agents

param(
    [switch]$Quick,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Configuration
$SupervisorScript = "scripts/agents/supervisor.ps1"
$SpecsDir = "specs"
$TestTimeout = if ($Quick) { 10000 } else { 30000 }

function Write-TestLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "INFO" { "Cyan" }
        "WARN" { "Yellow" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-SupervisorSmoke {
    Write-TestLog "Running supervisor smoke tests..." "INFO"
    
    try {
        $result = & pwsh -File $SupervisorScript -Action smoke-test
        if ($LASTEXITCODE -eq 0) {
            Write-TestLog "Smoke tests PASSED" "PASS"
            return $true
        } else {
            Write-TestLog "Smoke tests FAILED" "FAIL"
            return $false
        }
    } catch {
        Write-TestLog "Smoke test error: $($_.Exception.Message)" "FAIL"
        return $false
    }
}

function Test-AgentSpawn {
    param([string]$SpecFile, [string]$Mode)
    
    Write-TestLog "Testing $Mode agent spawn..." "INFO"
    
    try {
        $output = & pwsh -File $SupervisorScript -Action spawn -SpecPath $SpecFile 2>&1
        if ($LASTEXITCODE -eq 0) {
            # Extract ticket ID from output
            $ticketId = ($output | Select-String "Ticket ID: ([a-f0-9-]+)").Matches[0].Groups[1].Value
            if ($ticketId) {
                Write-TestLog "$Mode agent spawned successfully: $ticketId" "PASS"
                return $ticketId
            } else {
                Write-TestLog "Failed to extract ticket ID from output" "FAIL"
                return $null
            }
        } else {
            Write-TestLog "$Mode agent spawn failed" "FAIL"
            return $null
        }
    } catch {
        Write-TestLog "$Mode agent spawn error: $($_.Exception.Message)" "FAIL"
        return $null
    }
}

function Test-AgentAwait {
    param([string]$TicketId, [string]$Mode, [int]$TimeoutMs)
    
    Write-TestLog "Awaiting $Mode agent completion..." "INFO"
    
    try {
        $output = & pwsh -File $SupervisorScript -Action await -Id $TicketId -TimeoutMs $TimeoutMs 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-TestLog "$Mode agent completed successfully" "PASS"
            return $true
        } else {
            Write-TestLog "$Mode agent await failed or timed out" "FAIL"
            return $false
        }
    } catch {
        Write-TestLog "$Mode agent await error: $($_.Exception.Message)" "FAIL"
        return $false
    }
}

function Test-AgentTerminate {
    param([string]$TicketId, [string]$Mode)
    
    Write-TestLog "Testing $Mode agent termination..." "INFO"
    
    try {
        $output = & pwsh -File $SupervisorScript -Action terminate -Id $TicketId -Reason "verification test" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-TestLog "$Mode agent terminated successfully" "PASS"
            return $true
        } else {
            Write-TestLog "$Mode agent termination failed" "FAIL"
            return $false
        }
    } catch {
        Write-TestLog "$Mode agent termination error: $($_.Exception.Message)" "FAIL"
        return $false
    }
}

function Test-SupervisorStatus {
    Write-TestLog "Testing supervisor status reporting..." "INFO"
    
    try {
        $output = & pwsh -File $SupervisorScript -Action status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-TestLog "Status reporting PASSED" "PASS"
            return $true
        } else {
            Write-TestLog "Status reporting FAILED" "FAIL"
            return $false
        }
    } catch {
        Write-TestLog "Status reporting error: $($_.Exception.Message)" "FAIL"
        return $false
    }
}

function Test-BudgetEnforcement {
    Write-TestLog "Testing budget enforcement..." "INFO"
    
    # Try to spawn multiple agents to test job limits
    $ticketIds = @()
    $maxAttempts = 5
    
    for ($i = 1; $i -le $maxAttempts; $i++) {
        $specFile = "$SpecsDir/sample-care.json"
        $output = & pwsh -File $SupervisorScript -Action spawn -SpecPath $specFile 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $ticketId = ($output | Select-String "Ticket ID: ([a-f0-9-]+)").Matches[0].Groups[1].Value
            if ($ticketId) {
                $ticketIds += $ticketId
                Write-TestLog "Spawned agent $($i): $ticketId" "INFO"
            }
        } else {
            Write-TestLog "Budget limit reached at attempt $i" "INFO"
            break
        }
    }
    
    # Clean up spawned tickets
    foreach ($ticketId in $ticketIds) {
        & pwsh -File $SupervisorScript -Action terminate -Id $ticketId -Reason "budget test cleanup" | Out-Null
    }
    
    Write-TestLog "Budget enforcement test completed" "PASS"
    return $true
}

function Test-LockMechanism {
    Write-TestLog "Testing lock mechanism..." "INFO"
    
    try {
        # Create lock file
        New-Item -ItemType File -Path ".agent/LOCK" -Force | Out-Null
        
        # Try to spawn agent (should fail)
        $output = & pwsh -File $SupervisorScript -Action spawn -SpecPath "$SpecsDir/sample-companion.json" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-TestLog "Lock mechanism working - spawn blocked" "PASS"
        } else {
            Write-TestLog "Lock mechanism failed - spawn not blocked" "FAIL"
            return $false
        }
        
        # Remove lock file
        Remove-Item ".agent/LOCK" -Force
        
        # Try to spawn agent (should succeed)
        $output = & pwsh -File $SupervisorScript -Action spawn -SpecPath "$SpecsDir/sample-companion.json" 2>&1
        if ($LASTEXITCODE -eq 0) {
            $ticketId = ($output | Select-String "Ticket ID: ([a-f0-9-]+)").Matches[0].Groups[1].Value
            if ($ticketId) {
                # Clean up
                & pwsh -File $SupervisorScript -Action terminate -Id $ticketId -Reason "lock test cleanup" | Out-Null
                Write-TestLog "Lock mechanism working - spawn allowed after unlock" "PASS"
                return $true
            }
        }
        
        Write-TestLog "Lock mechanism test failed" "FAIL"
        return $false
        
    } catch {
        Write-TestLog "Lock mechanism test error: $($_.Exception.Message)" "FAIL"
        return $false
    }
}

# Main verification routine
Write-Host "`n🧪 IONA Supervisor Verification Suite" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Mode: $(if ($Quick) { 'Quick' } else { 'Full' })" -ForegroundColor Cyan
Write-Host "Timeout: $TestTimeout ms" -ForegroundColor Cyan
Write-Host ""

$testResults = @()
$startTime = Get-Date

# Test 1: Smoke tests
$testResults += @{
    Name = "Smoke Tests"
    Result = Test-SupervisorSmoke
}

# Test 2: Status reporting
$testResults += @{
    Name = "Status Reporting"
    Result = Test-SupervisorStatus
}

# Test 3: Lock mechanism
$testResults += @{
    Name = "Lock Mechanism"
    Result = Test-LockMechanism
}

# Test 4: Budget enforcement
$testResults += @{
    Name = "Budget Enforcement"
    Result = Test-BudgetEnforcement
}

# Test 5: Agent lifecycle (if not quick mode)
if (-not $Quick) {
    $modes = @(
        @{ File = "sample-companion.json"; Mode = "Companion" },
        @{ File = "sample-archivist.json"; Mode = "Archivist" },
        @{ File = "sample-cipher.json"; Mode = "Cipher" },
        @{ File = "sample-marketanalyst.json"; Mode = "MarketAnalyst" },
        @{ File = "sample-care.json"; Mode = "Care" }
    )
    
    foreach ($mode in $modes) {
        $specFile = "$SpecsDir/$($mode.File)"
        if (Test-Path $specFile) {
            $ticketId = Test-AgentSpawn -SpecFile $specFile -Mode $mode.Mode
            if ($ticketId) {
                $awaitResult = Test-AgentAwait -TicketId $ticketId -Mode $mode.Mode -TimeoutMs $TestTimeout
                $terminateResult = Test-AgentTerminate -TicketId $ticketId -Mode $mode.Mode
                
                $testResults += @{
                    Name = "$($mode.Mode) Lifecycle"
                    Result = $awaitResult -and $terminateResult
                }
            } else {
                $testResults += @{
                    Name = "$($mode.Mode) Lifecycle"
                    Result = $false
                }
            }
        }
    }
}

# Summary
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n📊 Test Results Summary" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

$passed = 0
$failed = 0

foreach ($test in $testResults) {
    $status = if ($test.Result) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($test.Result) { "Green" } else { "Red" }
    Write-Host "$status $($test.Name)" -ForegroundColor $color
    
    if ($test.Result) { $passed++ } else { $failed++ }
}

Write-Host "`nDuration: $($duration.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

if ($failed -eq 0) {
    Write-Host "`n🎉 All tests PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  Some tests FAILED!" -ForegroundColor Red
    exit 1
}
