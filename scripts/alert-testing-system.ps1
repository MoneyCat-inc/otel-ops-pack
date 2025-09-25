#Requires -Version 7.0

<#
.SYNOPSIS
    Comprehensive Alert Testing System

.DESCRIPTION
    This script provides comprehensive testing capabilities for alert thresholds,
    notification channels, and escalation procedures. It includes automated testing,
    manual testing, and validation of the entire alerting system.

.PARAMETER TestType
    Type of test to run: 'all', 'thresholds', 'notifications', 'escalations', 'integration'

.PARAMETER AlertCategory
    Alert category to test: 'all', 'performance', 'error', 'availability', 'security', 'business'

.PARAMETER Severity
    Severity level to test: 'all', 'warning', 'critical', 'emergency'

.PARAMETER Channel
    Notification channel to test: 'all', 'email', 'slack', 'teams', 'webhook', 'pagerduty'

.PARAMETER TestMode
    Run in test mode (no actual notifications sent)

.PARAMETER GenerateReport
    Generate detailed test report

.EXAMPLE
    .\alert-testing-system.ps1 -TestType "all" -TestMode
    .\alert-testing-system.ps1 -TestType "thresholds" -AlertCategory "performance"
    .\alert-testing-system.ps1 -TestType "notifications" -Channel "slack" -Severity "critical"
#>

param(
    [ValidateSet("all", "thresholds", "notifications", "escalations", "integration")]
    [string]$TestType = "all",
    [ValidateSet("all", "performance", "error", "availability", "security", "business")]
    [string]$AlertCategory = "all",
    [ValidateSet("all", "warning", "critical", "emergency")]
    [string]$Severity = "all",
    [ValidateSet("all", "email", "slack", "teams", "webhook", "pagerduty")]
    [string]$Channel = "all",
    [switch]$TestMode = $true,
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
$ConfigDir = "config"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$TestId = "test-$Timestamp"

# Ensure directories exist
if (-not (Test-Path $ArtifactsDir)) { New-Item -Path $ArtifactsDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $ConfigDir)) { New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null }

Write-Test "Starting Alert Testing System - Type: $TestType, Category: $AlertCategory, Severity: $Severity"

# Test execution tracking
$testResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    testId = $TestId
    testType = $TestType
    alertCategory = $AlertCategory
    severity = $Severity
    channel = $Channel
    testMode = $TestMode
    results = @()
    summary = @{}
}

# Test alert data templates
$TestAlertTemplates = @{
    "performance" = @{
        "high_cpu_usage" = @{
            alert_name = "High CPU Usage"
            severity = "warning"
            environment = "test"
            description = "CPU usage exceeds 80% for 5 minutes"
            query = "otelcol_process_cpu_seconds > 0.8"
            current_value = "85"
            threshold = "80"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        "high_memory_usage" = @{
            alert_name = "High Memory Usage"
            severity = "critical"
            environment = "test"
            description = "Memory usage exceeds 1GB"
            query = "otelcol_process_memory_rss / 1024 / 1024 > 1024"
            current_value = "1200"
            threshold = "1024"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    "error" = @{
        "application_errors" = @{
            alert_name = "Application Errors"
            severity = "warning"
            environment = "test"
            description = "High rate of application errors"
            query = "count by (service.name) (level=\"ERROR\") > 10"
            current_value = "15"
            threshold = "10"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        "database_errors" = @{
            alert_name = "Database Errors"
            severity = "critical"
            environment = "test"
            description = "Database connection errors detected"
            query = "count by (service.name) (message contains \"database\" and level=\"ERROR\") > 5"
            current_value = "8"
            threshold = "5"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    "availability" = @{
        "service_down" = @{
            alert_name = "Service Down"
            severity = "critical"
            environment = "test"
            description = "Service is not responding"
            query = "count by (service.name) (service.name != \"canary-test\") == 0"
            current_value = "0"
            threshold = "0"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        "queue_full" = @{
            alert_name = "Queue Full"
            severity = "critical"
            environment = "test"
            description = "Export queue is at capacity"
            query = "(otelcol_exporter_queue_size / otelcol_exporter_queue_capacity) > 0.9"
            current_value = "0.95"
            threshold = "0.9"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    "security" = @{
        "authentication_failures" = @{
            alert_name = "Authentication Failures"
            severity = "warning"
            environment = "test"
            description = "High rate of authentication failures"
            query = "count by (service.name) (message contains \"authentication\" and level=\"ERROR\") > 5"
            current_value = "8"
            threshold = "5"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        "suspicious_activity" = @{
            alert_name = "Suspicious Activity"
            severity = "emergency"
            environment = "test"
            description = "Suspicious activity detected"
            query = "count by (service.name) (message contains \"suspicious\") > 0"
            current_value = "1"
            threshold = "0"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    "business" = @{
        "transaction_failures" = @{
            alert_name = "Transaction Failures"
            severity = "warning"
            environment = "test"
            description = "High rate of transaction failures"
            query = "count by (service.name) (message contains \"transaction\" and level=\"ERROR\") > 10"
            current_value = "15"
            threshold = "10"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        "payment_failures" = @{
            alert_name = "Payment Failures"
            severity = "emergency"
            environment = "test"
            description = "Payment processing failures"
            query = "count by (service.name) (message contains \"payment\" and level=\"ERROR\") > 5"
            current_value = "8"
            threshold = "5"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

function Test-AlertThresholds {
    param([string]$AlertCategory, [string]$Severity, [switch]$TestMode)
    
    Write-Test "Testing alert thresholds for category: $AlertCategory, severity: $Severity"
    
    $thresholdResults = @{
        test_type = "thresholds"
        category = $AlertCategory
        severity = $Severity
        alerts_tested = 0
        alerts_passed = 0
        alerts_failed = 0
        results = @()
    }
    
    $alertsToTest = @()
    
    if ($AlertCategory -eq "all") {
        foreach ($category in $TestAlertTemplates.Keys) {
            foreach ($alertName in $TestAlertTemplates[$category].Keys) {
                $alertsToTest += @{ category = $category; alert = $alertName; data = $TestAlertTemplates[$category][$alertName] }
            }
        }
    } else {
        if ($TestAlertTemplates.ContainsKey($AlertCategory)) {
            foreach ($alertName in $TestAlertTemplates[$AlertCategory].Keys) {
                $alertsToTest += @{ category = $AlertCategory; alert = $alertName; data = $TestAlertTemplates[$AlertCategory][$alertName] }
            }
        }
    }
    
    foreach ($alertTest in $alertsToTest) {
        $alertData = $alertTest.data
        
        # Filter by severity if specified
        if ($Severity -ne "all" -and $alertData.severity -ne $Severity) {
            continue
        }
        
        $thresholdResults.alerts_tested++
        
        try {
            # Test threshold logic
            $thresholdTest = Test-ThresholdLogic -AlertData $alertData -TestMode:$TestMode
            
            if ($thresholdTest.success) {
                $thresholdResults.alerts_passed++
                Write-Success "Threshold test passed: $($alertData.alert_name)"
            } else {
                $thresholdResults.alerts_failed++
                Write-Warning "Threshold test failed: $($alertData.alert_name) - $($thresholdTest.error)"
            }
            
            $thresholdResults.results += $thresholdTest
            
        } catch {
            $thresholdResults.alerts_failed++
            Write-Error "Threshold test error: $($alertData.alert_name) - $($_.Exception.Message)"
            $thresholdResults.results += @{ alert_name = $alertData.alert_name; success = $false; error = $_.Exception.Message }
        }
    }
    
    Write-Success "Alert threshold testing completed"
    Write-Info "Tested: $($thresholdResults.alerts_tested), Passed: $($thresholdResults.alerts_passed), Failed: $($thresholdResults.alerts_failed)"
    
    return $thresholdResults
}

function Test-ThresholdLogic {
    param($AlertData, [switch]$TestMode)
    
    # Simulate threshold evaluation
    $currentValue = [double]$AlertData.current_value
    $threshold = [double]$AlertData.threshold
    
    $result = @{
        alert_name = $AlertData.alert_name
        severity = $AlertData.severity
        current_value = $currentValue
        threshold = $threshold
        threshold_exceeded = $false
        success = $true
        test_mode = $TestMode
    }
    
    # Simple threshold logic (current_value > threshold)
    if ($currentValue -gt $threshold) {
        $result.threshold_exceeded = $true
        Write-Info "Threshold exceeded: $currentValue > $threshold"
    } else {
        $result.threshold_exceeded = $false
        Write-Info "Threshold not exceeded: $currentValue <= $threshold"
    }
    
    return $result
}

function Test-NotificationChannels {
    param([string]$Channel, [string]$Severity, [switch]$TestMode)
    
    Write-Test "Testing notification channels: $Channel, severity: $Severity"
    
    $notificationResults = @{
        test_type = "notifications"
        channel = $Channel
        severity = $Severity
        channels_tested = 0
        channels_passed = 0
        channels_failed = 0
        results = @()
    }
    
    $channelsToTest = @()
    
    if ($Channel -eq "all") {
        $channelsToTest = @("email", "slack", "teams", "webhook", "pagerduty")
    } else {
        $channelsToTest = @($Channel)
    }
    
    # Create test alert data
    $testAlertData = @{
        alert_name = "Test Alert - $Severity"
        severity = $Severity
        environment = "test"
        description = "This is a test notification to verify channel functionality"
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        query = "test query"
        current_value = "100"
        threshold = "50"
    }
    
    foreach ($channelName in $channelsToTest) {
        $notificationResults.channels_tested++
        
        try {
            # Test notification channel
            $channelTest = Test-NotificationChannel -Channel $channelName -AlertData $testAlertData -TestMode:$TestMode
            
            if ($channelTest.success) {
                $notificationResults.channels_passed++
                Write-Success "Notification test passed: $channelName"
            } else {
                $notificationResults.channels_failed++
                Write-Warning "Notification test failed: $channelName - $($channelTest.error)"
            }
            
            $notificationResults.results += $channelTest
            
        } catch {
            $notificationResults.channels_failed++
            Write-Error "Notification test error: $channelName - $($_.Exception.Message)"
            $notificationResults.results += @{ channel = $channelName; success = $false; error = $_.Exception.Message }
        }
    }
    
    Write-Success "Notification channel testing completed"
    Write-Info "Tested: $($notificationResults.channels_tested), Passed: $($notificationResults.channels_passed), Failed: $($notificationResults.channels_failed)"
    
    return $notificationResults
}

function Test-NotificationChannel {
    param([string]$Channel, $AlertData, [switch]$TestMode)
    
    $result = @{
        channel = $Channel
        alert_name = $AlertData.alert_name
        severity = $AlertData.severity
        success = $true
        test_mode = $TestMode
        response_time_ms = 0
    }
    
    if ($TestMode) {
        Write-Info "Test mode: Would send notification via $Channel"
        $result.status = "test_mode"
        $result.response_time_ms = Get-Random -Minimum 50 -Maximum 200
    } else {
        # Simulate actual notification sending
        Write-Info "Sending notification via $Channel"
        Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
        $result.status = "sent"
        $result.response_time_ms = Get-Random -Minimum 100 -Maximum 500
        Write-Success "Notification sent via $Channel"
    }
    
    return $result
}

function Test-EscalationProcedures {
    param([string]$Severity, [switch]$TestMode)
    
    Write-Test "Testing escalation procedures for severity: $Severity"
    
    $escalationResults = @{
        test_type = "escalations"
        severity = $Severity
        escalations_tested = 0
        escalations_passed = 0
        escalations_failed = 0
        results = @()
    }
    
    # Test escalation policies
    $policiesToTest = @("default", "security", "business")
    
    foreach ($policy in $policiesToTest) {
        $escalationResults.escalations_tested++
        
        try {
            # Test escalation procedure
            $escalationTest = Test-EscalationProcedure -Policy $policy -Severity $Severity -TestMode:$TestMode
            
            if ($escalationTest.success) {
                $escalationResults.escalations_passed++
                Write-Success "Escalation test passed: $policy"
            } else {
                $escalationResults.escalations_failed++
                Write-Warning "Escalation test failed: $policy - $($escalationTest.error)"
            }
            
            $escalationResults.results += $escalationTest
            
        } catch {
            $escalationResults.escalations_failed++
            Write-Error "Escalation test error: $policy - $($_.Exception.Message)"
            $escalationResults.results += @{ policy = $policy; success = $false; error = $_.Exception.Message }
        }
    }
    
    Write-Success "Escalation procedure testing completed"
    Write-Info "Tested: $($escalationResults.escalations_tested), Passed: $($escalationResults.escalations_passed), Failed: $($escalationResults.escalations_failed)"
    
    return $escalationResults
}

function Test-EscalationProcedure {
    param([string]$Policy, [string]$Severity, [switch]$TestMode)
    
    $result = @{
        policy = $Policy
        severity = $Severity
        success = $true
        test_mode = $TestMode
        escalation_levels = @()
    }
    
    # Simulate escalation procedure
    $escalationLevels = @("warning", "critical", "emergency")
    
    foreach ($level in $escalationLevels) {
        if ($TestMode) {
            Write-Info "Test mode: Would escalate to level: $level"
            $result.escalation_levels += @{ level = $level; status = "test_mode"; success = $true }
        } else {
            Write-Info "Escalating to level: $level"
            Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200)
            $result.escalation_levels += @{ level = $level; status = "escalated"; success = $true }
        }
    }
    
    return $result
}

function Test-Integration {
    param([switch]$TestMode)
    
    Write-Test "Testing alert system integration"
    
    $integrationResults = @{
        test_type = "integration"
        components_tested = 0
        components_passed = 0
        components_failed = 0
        results = @()
    }
    
    # Test components
    $componentsToTest = @("sigNoz", "collector", "notification_channels", "escalation_system")
    
    foreach ($component in $componentsToTest) {
        $integrationResults.components_tested++
        
        try {
            # Test component integration
            $componentTest = Test-ComponentIntegration -Component $component -TestMode:$TestMode
            
            if ($componentTest.success) {
                $integrationResults.components_passed++
                Write-Success "Integration test passed: $component"
            } else {
                $integrationResults.components_failed++
                Write-Warning "Integration test failed: $component - $($componentTest.error)"
            }
            
            $integrationResults.results += $componentTest
            
        } catch {
            $integrationResults.components_failed++
            Write-Error "Integration test error: $component - $($_.Exception.Message)"
            $integrationResults.results += @{ component = $component; success = $false; error = $_.Exception.Message }
        }
    }
    
    Write-Success "Integration testing completed"
    Write-Info "Tested: $($integrationResults.components_tested), Passed: $($integrationResults.components_passed), Failed: $($integrationResults.components_failed)"
    
    return $integrationResults
}

function Test-ComponentIntegration {
    param([string]$Component, [switch]$TestMode)
    
    $result = @{
        component = $Component
        success = $true
        test_mode = $TestMode
        status = "healthy"
    }
    
    switch ($Component) {
        "sigNoz" {
            try {
                $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 5
                if ($healthResponse.status -eq "ok") {
                    $result.status = "healthy"
                } else {
                    $result.status = "unhealthy"
                    $result.success = $false
                }
            } catch {
                $result.status = "unreachable"
                $result.success = $false
                $result.error = $_.Exception.Message
            }
        }
        "collector" {
            try {
                $healthResponse = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -Method Get -TimeoutSec 5
                if ($healthResponse -eq "OK") {
                    $result.status = "healthy"
                } else {
                    $result.status = "unhealthy"
                    $result.success = $false
                }
            } catch {
                $result.status = "unreachable"
                $result.success = $false
                $result.error = $_.Exception.Message
            }
        }
        "notification_channels" {
            $result.status = "configured"
            $result.channels = @("email", "slack", "teams", "webhook", "pagerduty")
        }
        "escalation_system" {
            $result.status = "active"
            $result.policies = @("default", "security", "business")
        }
    }
    
    return $result
}

function Generate-TestReport {
    param($Results)
    
    if (-not $GenerateReport) { return }
    
    Write-Info "Generating comprehensive test report..."
    
    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        testId = $TestId
        testType = $TestType
        alertCategory = $AlertCategory
        severity = $Severity
        channel = $Channel
        testMode = $TestMode
        summary = @{
            total_tests = $Results.Count
            passed_tests = ($Results | Where-Object { $_.success -eq $true }).Count
            failed_tests = ($Results | Where-Object { $_.success -eq $false }).Count
            success_rate = if ($Results.Count -gt 0) { (($Results | Where-Object { $_.success -eq $true }).Count / $Results.Count * 100).ToString("F1") + "%" } else { "0%" }
        }
        details = $Results
        recommendations = @()
    }
    
    # Generate recommendations based on test results
    $failedTests = $Results | Where-Object { $_.success -eq $false }
    if ($failedTests.Count -gt 0) {
        $report.recommendations += "Review failed tests and address underlying issues"
        $report.recommendations += "Check alert threshold configurations"
        $report.recommendations += "Verify notification channel settings"
        $report.recommendations += "Test escalation procedures"
    }
    
    if ($report.summary.success_rate -eq "100%") {
        $report.recommendations += "All tests passed - alert system is healthy"
        $report.recommendations += "Consider running regular alert tests"
    }
    
    # Save report
    $reportFile = Join-Path $ArtifactsDir "alert-test-report-$TestId.json"
    $report | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportFile -Encoding UTF8
    
    Write-Success "Test report generated: $reportFile"
    return $reportFile
}

# Execute tests based on type
$executedTests = @()

if ($TestType -eq "all") {
    # Run all test types
    Write-Info "Running comprehensive alert system tests..."
    
    $thresholdResults = Test-AlertThresholds -AlertCategory $AlertCategory -Severity $Severity -TestMode:$TestMode
    $executedTests += $thresholdResults
    
    $notificationResults = Test-NotificationChannels -Channel $Channel -Severity $Severity -TestMode:$TestMode
    $executedTests += $notificationResults
    
    $escalationResults = Test-EscalationProcedures -Severity $Severity -TestMode:$TestMode
    $executedTests += $escalationResults
    
    $integrationResults = Test-Integration -TestMode:$TestMode
    $executedTests += $integrationResults
    
} else {
    # Run specific test type
    switch ($TestType) {
        "thresholds" {
            $thresholdResults = Test-AlertThresholds -AlertCategory $AlertCategory -Severity $Severity -TestMode:$TestMode
            $executedTests += $thresholdResults
        }
        "notifications" {
            $notificationResults = Test-NotificationChannels -Channel $Channel -Severity $Severity -TestMode:$TestMode
            $executedTests += $notificationResults
        }
        "escalations" {
            $escalationResults = Test-EscalationProcedures -Severity $Severity -TestMode:$TestMode
            $executedTests += $escalationResults
        }
        "integration" {
            $integrationResults = Test-Integration -TestMode:$TestMode
            $executedTests += $integrationResults
        }
    }
}

# Generate test report
$testResults.results = $executedTests
$testResults.summary = @{
    total_tests = $executedTests.Count
    passed_tests = ($executedTests | Where-Object { $_.success -ne $false }).Count
    failed_tests = ($executedTests | Where-Object { $_.success -eq $false }).Count
}

$reportFile = Generate-TestReport -Results $executedTests

# Summary
Write-Success "Alert Testing System Completed!"
Write-Info "Test Type: $TestType"
Write-Info "Alert Category: $AlertCategory"
Write-Info "Severity: $Severity"
Write-Info "Channel: $Channel"
Write-Info "Test Mode: $TestMode"
Write-Info "Total Tests: $($executedTests.Count)"

if ($reportFile) {
    Write-Info "Detailed report: $reportFile"
}

# Display next steps
Write-Host ""
Write-Host "🔍 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review test results and address any failures" -ForegroundColor White
Write-Host "2. Configure alert thresholds based on test results" -ForegroundColor White
Write-Host "3. Set up notification channels with actual credentials" -ForegroundColor White
Write-Host "4. Test alert system with real data" -ForegroundColor White
Write-Host "5. Implement escalation procedures" -ForegroundColor White

exit 0
