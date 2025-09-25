#Requires -Version 7.0

<#
.SYNOPSIS
    Test and verify pattern drill execution and results

.DESCRIPTION
    This script tests the pattern drill execution, verifies results in SigNoz,
    and provides comprehensive reporting on drill effectiveness and pipeline health.

.PARAMETER TestType
    Type of test to run: 'all', 'quick', 'comprehensive', 'verification-only'

.PARAMETER DrillType
    Specific drill type to test: 'error-patterns', 'performance-patterns', etc.

.PARAMETER Scenario
    Specific scenario to test: 'web-application', 'microservices', etc.

.PARAMETER VerifyInSigNoz
    Verify results in SigNoz UI (default: true)

.PARAMETER GenerateReport
    Generate detailed test report (default: true)

.EXAMPLE
    .\test-pattern-drills.ps1 -TestType "quick"
    .\test-pattern-drills.ps1 -TestType "comprehensive" -DrillType "error-patterns"
    .\test-pattern-drills.ps1 -TestType "verification-only" -Scenario "web-application"
#>

param(
    [ValidateSet("all", "quick", "comprehensive", "verification-only")]
    [string]$TestType = "quick",
    [ValidateSet("error-patterns", "performance-patterns", "format-variations", "volume-spikes", "edge-cases", "multiline-patterns")]
    [string]$DrillType = $null,
    [ValidateSet("web-application", "microservices", "security-incident", "performance-degradation", "business-transaction", "mixed-workload")]
    [string]$Scenario = $null,
    [switch]$VerifyInSigNoz = $true,
    [switch]$GenerateReport = $true
)

# Color functions for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Test { param($Message) Write-Host "🧪 $Message" -ForegroundColor Magenta }

# Configuration
$ArtifactsDir = "artifacts"
$LogDir = "C:\logs"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$TestId = "test-$Timestamp"

# Ensure directories exist
if (-not (Test-Path $ArtifactsDir)) { New-Item -Path $ArtifactsDir -ItemType Directory -Force | Out-Null }

Write-Test "Starting Pattern Drill Testing - Type: $TestType, Test ID: $TestId"

# Test execution tracking
$testResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    testType = $TestType
    testId = $TestId
    results = @()
    summary = @{}
}

function Test-PipelineHealth {
    Write-Test "Testing Pipeline Health"
    
    $healthResults = @{
        sigNozHealth = $false
        collectorHealth = $false
        logIngestion = $false
        traceIngestion = $false
        metricsCollection = $false
    }
    
    # Test SigNoz health
    try {
        $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 5
        if ($healthResponse.status -eq "ok") {
            $healthResults.sigNozHealth = $true
            Write-Success "SigNoz health check passed"
        } else {
            Write-Warning "SigNoz health check failed: $($healthResponse.status)"
        }
    } catch {
        Write-Warning "SigNoz health check failed: $($_.Exception.Message)"
    }
    
    # Test collector health
    try {
        $collectorResponse = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -Method Get -TimeoutSec 5
        if ($collectorResponse -eq "OK") {
            $healthResults.collectorHealth = $true
            Write-Success "Collector health check passed"
        } else {
            Write-Warning "Collector health check failed: $collectorResponse"
        }
    } catch {
        Write-Warning "Collector health check failed: $($_.Exception.Message)"
    }
    
    # Test log ingestion
    try {
        $logQuery = @{
            query = "count(*) where timestamp > now() - INTERVAL 5 MINUTE"
            startTime = ([DateTimeOffset]::UtcNow.AddMinutes(-5).ToUnixTimeMilliseconds() * 1000000)
            endTime = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
        }
        
        $logResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs/search" -Method Post -Body ($logQuery | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
        if ($logResponse.data -and $logResponse.data.Count -gt 0) {
            $healthResults.logIngestion = $true
            Write-Success "Log ingestion test passed - $($logResponse.data.Count) recent logs found"
        } else {
            Write-Warning "Log ingestion test failed - no recent logs found"
        }
    } catch {
        Write-Warning "Log ingestion test failed: $($_.Exception.Message)"
    }
    
    # Test trace ingestion
    try {
        $traceQuery = @{
            query = "count(*) where timestamp > now() - INTERVAL 5 MINUTE"
            startTime = ([DateTimeOffset]::UtcNow.AddMinutes(-5).ToUnixTimeMilliseconds() * 1000000)
            endTime = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
        }
        
        $traceResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/traces/search" -Method Post -Body ($traceQuery | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
        if ($traceResponse.data -and $traceResponse.data.Count -gt 0) {
            $healthResults.traceIngestion = $true
            Write-Success "Trace ingestion test passed - $($traceResponse.data.Count) recent traces found"
        } else {
            Write-Warning "Trace ingestion test failed - no recent traces found"
        }
    } catch {
        Write-Warning "Trace ingestion test failed: $($_.Exception.Message)"
    }
    
    # Test metrics collection
    try {
        $metricsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/metrics" -Method Get -TimeoutSec 5
        if ($metricsResponse.data -and $metricsResponse.data.Count -gt 0) {
            $healthResults.metricsCollection = $true
            Write-Success "Metrics collection test passed - $($metricsResponse.data.Count) metrics available"
        } else {
            Write-Warning "Metrics collection test failed - no metrics available"
        }
    } catch {
        Write-Warning "Metrics collection test failed: $($_.Exception.Message)"
    }
    
    return $healthResults
}

function Test-PatternDrillExecution {
    param([string]$DrillType, [int]$Duration = 30)
    
    Write-Test "Testing Pattern Drill Execution: $DrillType"
    
    $drillScript = Join-Path $PSScriptRoot "canary-pattern-drills.ps1"
    if (-not (Test-Path $drillScript)) {
        Write-Error "Drill script not found: $drillScript"
        return $false
    }
    
    try {
        $startTime = Get-Date
        $drillResult = & $drillScript -DrillType $DrillType -Duration $Duration -Intensity "low" -VerifyInSigNoz:$false
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalSeconds
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Pattern drill execution completed successfully in $executionTime seconds"
            return @{ success = $true; executionTime = $executionTime; exitCode = $LASTEXITCODE }
        } else {
            Write-Warning "Pattern drill execution completed with exit code: $LASTEXITCODE"
            return @{ success = $false; executionTime = $executionTime; exitCode = $LASTEXITCODE }
        }
    } catch {
        Write-Error "Pattern drill execution failed: $($_.Exception.Message)"
        return @{ success = $false; executionTime = 0; exitCode = -1; error = $_.Exception.Message }
    }
}

function Test-ScenarioExecution {
    param([string]$Scenario, [int]$Duration = 2)
    
    Write-Test "Testing Scenario Execution: $Scenario"
    
    $scenarioScript = Join-Path $PSScriptRoot "execute-pattern-drills.ps1"
    if (-not (Test-Path $scenarioScript)) {
        Write-Error "Scenario script not found: $scenarioScript"
        return $false
    }
    
    try {
        $startTime = Get-Date
        $scenarioResult = & $scenarioScript -Scenario $Scenario -Duration $Duration -Intensity "low" -VerifyResults:$false
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalSeconds
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Scenario execution completed successfully in $executionTime seconds"
            return @{ success = $true; executionTime = $executionTime; exitCode = $LASTEXITCODE }
        } else {
            Write-Warning "Scenario execution completed with exit code: $LASTEXITCODE"
            return @{ success = $false; executionTime = $executionTime; exitCode = $LASTEXITCODE }
        }
    } catch {
        Write-Error "Scenario execution failed: $($_.Exception.Message)"
        return @{ success = $false; executionTime = 0; exitCode = -1; error = $_.Exception.Message }
    }
}

function Test-SigNozVerification {
    param([string]$DrillType = $null, [string]$Scenario = $null)
    
    Write-Test "Testing SigNoz Verification"
    
    $verificationResults = @{
        logSearch = $false
        traceSearch = $false
        metricsQuery = $false
        alertCheck = $false
    }
    
    # Test log search
    try {
        $searchQuery = if ($DrillType) { "message contains '$DrillType'" } elseif ($Scenario) { "message contains '$Scenario'" } else { "message contains 'drill' OR message contains 'scenario'" }
        
        $logQuery = @{
            query = $searchQuery
            startTime = ([DateTimeOffset]::UtcNow.AddMinutes(-10).ToUnixTimeMilliseconds() * 1000000)
            endTime = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
            limit = 10
        }
        
        $logResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs/search" -Method Post -Body ($logQuery | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
        
        if ($logResponse.data -and $logResponse.data.Count -gt 0) {
            $verificationResults.logSearch = $true
            Write-Success "Log search verification passed - $($logResponse.data.Count) matching logs found"
        } else {
            Write-Warning "Log search verification failed - no matching logs found"
        }
    } catch {
        Write-Warning "Log search verification failed: $($_.Exception.Message)"
    }
    
    # Test trace search
    try {
        $traceQuery = @{
            query = "service.name = 'pattern-drill-scenario' OR service.name = 'canary-test'"
            startTime = ([DateTimeOffset]::UtcNow.AddMinutes(-10).ToUnixTimeMilliseconds() * 1000000)
            endTime = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
            limit = 10
        }
        
        $traceResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/traces/search" -Method Post -Body ($traceQuery | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
        
        if ($traceResponse.data -and $traceResponse.data.Count -gt 0) {
            $verificationResults.traceSearch = $true
            Write-Success "Trace search verification passed - $($traceResponse.data.Count) matching traces found"
        } else {
            Write-Warning "Trace search verification failed - no matching traces found"
        }
    } catch {
        Write-Warning "Trace search verification failed: $($_.Exception.Message)"
    }
    
    # Test metrics query
    try {
        $metricsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/metrics" -Method Get -TimeoutSec 5
        
        if ($metricsResponse.data -and $metricsResponse.data.Count -gt 0) {
            $verificationResults.metricsQuery = $true
            Write-Success "Metrics query verification passed - $($metricsResponse.data.Count) metrics available"
        } else {
            Write-Warning "Metrics query verification failed - no metrics available"
        }
    } catch {
        Write-Warning "Metrics query verification failed: $($_.Exception.Message)"
    }
    
    # Test alert check
    try {
        $alertsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/alerts" -Method Get -TimeoutSec 5
        
        if ($alertsResponse.data -and $alertsResponse.data.Count -gt 0) {
            $verificationResults.alertCheck = $true
            Write-Success "Alert check verification passed - $($alertsResponse.data.Count) alerts configured"
        } else {
            Write-Warning "Alert check verification failed - no alerts configured"
        }
    } catch {
        Write-Warning "Alert check verification failed: $($_.Exception.Message)"
    }
    
    return $verificationResults
}

function Test-PatternLibrary {
    Write-Test "Testing Pattern Library"
    
    $libraryScript = Join-Path $PSScriptRoot "canary-pattern-library.ps1"
    if (-not (Test-Path $libraryScript)) {
        Write-Error "Pattern library script not found: $libraryScript"
        return $false
    }
    
    try {
        # Import the pattern library
        . $libraryScript
        
        # Test pattern generation
        $testPattern = Get-RandomPattern
        if ($testPattern) {
            Write-Success "Pattern library loaded successfully"
            Write-Info "Test pattern: $($testPattern.Category).$($testPattern.Subcategory).$($testPattern.PatternName)"
            
            # Test log entry generation
            $logEntry = Generate-LogEntry -Category $testPattern.Category -Subcategory $testPattern.Subcategory -PatternName $testPattern.PatternName
            if ($logEntry) {
                Write-Success "Log entry generation test passed"
                return @{ success = $true; patternCount = $Script:PatternCategories.Count; testPattern = $testPattern }
            } else {
                Write-Warning "Log entry generation test failed"
                return @{ success = $false; error = "Log entry generation failed" }
            }
        } else {
            Write-Warning "Pattern library test failed - no patterns available"
            return @{ success = $false; error = "No patterns available" }
        }
    } catch {
        Write-Error "Pattern library test failed: $($_.Exception.Message)"
        return @{ success = $false; error = $_.Exception.Message }
    }
}

function Generate-TestReport {
    param($Results)
    
    if (-not $GenerateReport) { return }
    
    Write-Info "Generating comprehensive test report..."
    
    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        testId = $TestId
        testType = $TestType
        summary = @{
            totalTests = $Results.Count
            passedTests = ($Results | Where-Object { $_.success -eq $true }).Count
            failedTests = ($Results | Where-Object { $_.success -eq $false }).Count
            successRate = if ($Results.Count -gt 0) { (($Results | Where-Object { $_.success -eq $true }).Count / $Results.Count * 100).ToString("F1") + "%" } else { "0%" }
        }
        details = $Results
        recommendations = @()
    }
    
    # Generate recommendations based on test results
    $failedTests = $Results | Where-Object { $_.success -eq $false }
    if ($failedTests.Count -gt 0) {
        $report.recommendations += "Review failed tests and address underlying issues"
        $report.recommendations += "Check SigNoz and collector health status"
        $report.recommendations += "Verify network connectivity and service availability"
    }
    
    if ($report.summary.successRate -eq "100%") {
        $report.recommendations += "All tests passed - system is healthy"
        $report.recommendations += "Consider running comprehensive tests regularly"
    }
    
    # Save report
    $reportFile = Join-Path $ArtifactsDir "pattern-drill-test-report-$Timestamp.json"
    $report | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportFile -Encoding UTF8
    
    Write-Success "Test report generated: $reportFile"
    return $reportFile
}

# Execute tests based on type
$executedTests = @()

# Always test pipeline health
Write-Info "Testing pipeline health..."
$healthResults = Test-PipelineHealth
$executedTests += @{ test = "pipeline-health"; success = ($healthResults.sigNozHealth -and $healthResults.collectorHealth); details = $healthResults }

# Test pattern library
Write-Info "Testing pattern library..."
$libraryResults = Test-PatternLibrary
$executedTests += @{ test = "pattern-library"; success = $libraryResults.success; details = $libraryResults }

if ($TestType -eq "quick") {
    # Quick test - basic functionality only
    Write-Info "Running quick tests..."
    
    if ($DrillType) {
        $drillResults = Test-PatternDrillExecution -DrillType $DrillType -Duration 15
        $executedTests += @{ test = "drill-execution-$DrillType"; success = $drillResults.success; details = $drillResults }
    }
    
    if ($Scenario) {
        $scenarioResults = Test-ScenarioExecution -Scenario $Scenario -Duration 1
        $executedTests += @{ test = "scenario-execution-$Scenario"; success = $scenarioResults.success; details = $scenarioResults }
    }
    
} elseif ($TestType -eq "comprehensive") {
    # Comprehensive test - all drills and scenarios
    Write-Info "Running comprehensive tests..."
    
    $drillTypes = @("error-patterns", "performance-patterns", "format-variations")
    foreach ($drill in $drillTypes) {
        if (-not $DrillType -or $DrillType -eq $drill) {
            $drillResults = Test-PatternDrillExecution -DrillType $drill -Duration 30
            $executedTests += @{ test = "drill-execution-$drill"; success = $drillResults.success; details = $drillResults }
        }
    }
    
    $scenarios = @("web-application", "microservices", "security-incident")
    foreach ($scenario in $scenarios) {
        if (-not $Scenario -or $Scenario -eq $scenario) {
            $scenarioResults = Test-ScenarioExecution -Scenario $scenario -Duration 2
            $executedTests += @{ test = "scenario-execution-$scenario"; success = $scenarioResults.success; details = $scenarioResults }
        }
    }
    
} elseif ($TestType -eq "verification-only") {
    # Verification only - check existing data
    Write-Info "Running verification-only tests..."
    
    $verificationResults = Test-SigNozVerification -DrillType $DrillType -Scenario $Scenario
    $executedTests += @{ test = "sigNoz-verification"; success = ($verificationResults.logSearch -or $verificationResults.traceSearch); details = $verificationResults }
}

# Generate test report
$testResults.results = $executedTests
$testResults.summary = @{
    totalTests = $executedTests.Count
    passedTests = ($executedTests | Where-Object { $_.success -eq $true }).Count
    failedTests = ($executedTests | Where-Object { $_.success -eq $false }).Count
}

$reportFile = Generate-TestReport -Results $executedTests

# Summary
Write-Success "Pattern Drill Testing Completed!"
Write-Info "Total tests executed: $($executedTests.Count)"
Write-Info "Tests passed: $($testResults.summary.passedTests)"
Write-Info "Tests failed: $($testResults.summary.failedTests)"
Write-Info "Success rate: $(if ($executedTests.Count -gt 0) { ($testResults.summary.passedTests / $executedTests.Count * 100).ToString("F1") + "%" } else { "0%" })"

if ($reportFile) {
    Write-Info "Detailed report: $reportFile"
}

# Display next steps
Write-Host ""
Write-Host "🔍 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review test results and address any failures" -ForegroundColor White
Write-Host "2. Check SigNoz UI for drill data: http://localhost:8080/logs" -ForegroundColor White
Write-Host "3. Verify alerts are configured and working" -ForegroundColor White
Write-Host "4. Run comprehensive tests regularly" -ForegroundColor White

exit 0
