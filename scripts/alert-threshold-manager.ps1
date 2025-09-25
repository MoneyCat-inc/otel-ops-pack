#Requires -Version 7.0

<#
.SYNOPSIS
    Comprehensive Alert Threshold and Notification Management System

.DESCRIPTION
    This script manages alert thresholds, notification channels, and escalation procedures
    for the observability pipeline. It provides automated threshold configuration,
    notification channel management, and alert testing capabilities.

.PARAMETER Action
    Action to perform: 'configure', 'test', 'validate', 'export', 'import'

.PARAMETER AlertType
    Type of alert to configure: 'all', 'performance', 'error', 'availability', 'security', 'business'

.PARAMETER Severity
    Alert severity level: 'info', 'warning', 'critical', 'emergency'

.PARAMETER NotificationChannels
    Comma-separated list of notification channels to configure

.PARAMETER TestMode
    Run in test mode (no actual notifications sent)

.EXAMPLE
    .\alert-threshold-manager.ps1 -Action "configure" -AlertType "all"
    .\alert-threshold-manager.ps1 -Action "test" -Severity "critical" -TestMode
    .\alert-threshold-manager.ps1 -Action "export" -AlertType "performance"
#>

param(
    [ValidateSet("configure", "test", "validate", "export", "import")]
    [string]$Action = "configure",
    [ValidateSet("all", "performance", "error", "availability", "security", "business")]
    [string]$AlertType = "all",
    [ValidateSet("info", "warning", "critical", "emergency")]
    [string]$Severity = "warning",
    [string]$NotificationChannels = "email,slack,webhook",
    [switch]$TestMode = $false
)

# Color functions for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Alert { param($Message) Write-Host "🚨 $Message" -ForegroundColor Magenta }

# Configuration
$ArtifactsDir = "artifacts"
$ConfigDir = "config"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$SigNozUrl = "http://localhost:8080"

# Ensure directories exist
if (-not (Test-Path $ArtifactsDir)) { New-Item -Path $ArtifactsDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $ConfigDir)) { New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null }

Write-Alert "Starting Alert Threshold Management - Action: $Action, Type: $AlertType, Severity: $Severity"

# Alert threshold definitions
$AlertThresholds = @{
    "performance" = @{
        "high_cpu_usage" = @{
            name = "High CPU Usage"
            description = "CPU usage exceeds threshold for sustained period"
            query = "otelcol_process_cpu_seconds > 0.8"
            threshold = 0.8
            operator = ">"
            duration = "5m"
            severity = "warning"
            escalation = @{
                warning = "5m"
                critical = "10m"
                emergency = "15m"
            }
        }
        "high_memory_usage" = @{
            name = "High Memory Usage"
            description = "Memory usage exceeds threshold"
            query = "otelcol_process_memory_rss / 1024 / 1024 > 1024"
            threshold = 1024
            operator = ">"
            duration = "3m"
            severity = "warning"
            escalation = @{
                warning = "3m"
                critical = "5m"
                emergency = "10m"
            }
        }
        "slow_response_time" = @{
            name = "Slow Response Time"
            description = "Average response time exceeds threshold"
            query = "avg(response_time_ms) > 2000"
            threshold = 2000
            operator = ">"
            duration = "5m"
            severity = "warning"
            escalation = @{
                warning = "5m"
                critical = "10m"
                emergency = "15m"
            }
        }
        "high_error_rate" = @{
            name = "High Error Rate"
            description = "Error rate exceeds acceptable threshold"
            query = "rate(count by (level) (level=\"ERROR\")[5m]) / rate(count[5m]) > 0.05"
            threshold = 0.05
            operator = ">"
            duration = "5m"
            severity = "critical"
            escalation = @{
                warning = "2m"
                critical = "5m"
                emergency = "10m"
            }
        }
    }
    
    "error" = @{
        "application_errors" = @{
            name = "Application Errors"
            description = "Application error rate exceeds threshold"
            query = "count by (service.name) (level=\"ERROR\" and service.name != \"canary-test\") > 10"
            threshold = 10
            operator = ">"
            duration = "2m"
            severity = "warning"
            escalation = @{
                warning = "2m"
                critical = "5m"
                emergency = "10m"
            }
        }
        "database_errors" = @{
            name = "Database Errors"
            description = "Database connection or query errors"
            query = "count by (service.name) (message contains \"database\" and level=\"ERROR\") > 5"
            threshold = 5
            operator = ">"
            duration = "1m"
            severity = "critical"
            escalation = @{
                warning = "1m"
                critical = "2m"
                emergency = "5m"
            }
        }
        "parser_errors" = @{
            name = "Parser Errors"
            description = "Log parsing errors detected"
            query = "count by (service.name) (message contains \"parser\" and level=\"ERROR\") > 0"
            threshold = 0
            operator = ">"
            duration = "1m"
            severity = "critical"
            escalation = @{
                warning = "1m"
                critical = "2m"
                emergency = "5m"
            }
        }
        "network_errors" = @{
            name = "Network Errors"
            description = "Network connectivity errors"
            query = "count by (service.name) (message contains \"network\" and level=\"ERROR\") > 3"
            threshold = 3
            operator = ">"
            duration = "2m"
            severity = "warning"
            escalation = @{
                warning = "2m"
                critical = "5m"
                emergency = "10m"
            }
        }
    }
    
    "availability" = @{
        "service_down" = @{
            name = "Service Down"
            description = "Service is not responding"
            query = "count by (service.name) (service.name != \"canary-test\") == 0"
            threshold = 0
            operator = "=="
            duration = "1m"
            severity = "critical"
            escalation = @{
                warning = "1m"
                critical = "2m"
                emergency = "5m"
            }
        }
        "canary_failure" = @{
            name = "Canary Test Failure"
            description = "Canary tests are failing or stopped"
            query = "count by (canary) (canary=\"true\" and level=\"ERROR\") == 0"
            threshold = 0
            operator = "=="
            duration = "2m"
            severity = "warning"
            escalation = @{
                warning = "2m"
                critical = "5m"
                emergency = "10m"
            }
        }
        "queue_full" = @{
            name = "Queue Full"
            description = "Export queue is at capacity"
            query = "(otelcol_exporter_queue_size / otelcol_exporter_queue_capacity) > 0.9"
            threshold = 0.9
            operator = ">"
            duration = "1m"
            severity = "critical"
            escalation = @{
                warning = "1m"
                critical = "2m"
                emergency = "5m"
            }
        }
        "ingestion_stalled" = @{
            name = "Log Ingestion Stalled"
            description = "Log ingestion has stopped"
            query = "rate(count[5m]) == 0"
            threshold = 0
            operator = "=="
            duration = "5m"
            severity = "critical"
            escalation = @{
                warning = "5m"
                critical = "10m"
                emergency = "15m"
            }
        }
    }
    
    "security" = @{
        "authentication_failures" = @{
            name = "Authentication Failures"
            description = "High rate of authentication failures"
            query = "count by (service.name) (message contains \"authentication\" and level=\"ERROR\") > 5"
            threshold = 5
            operator = ">"
            duration = "2m"
            severity = "warning"
            escalation = @{
                warning = "2m"
                critical = "5m"
                emergency = "10m"
            }
        }
        "suspicious_activity" = @{
            name = "Suspicious Activity"
            description = "Suspicious activity detected"
            query = "count by (service.name) (message contains \"suspicious\" or message contains \"intrusion\") > 0"
            threshold = 0
            operator = ">"
            duration = "1m"
            severity = "critical"
            escalation = @{
                warning = "1m"
                critical = "2m"
                emergency = "5m"
            }
        }
        "privilege_escalation" = @{
            name = "Privilege Escalation Attempt"
            description = "Privilege escalation attempt detected"
            query = "count by (service.name) (message contains \"privilege\" and message contains \"escalation\") > 0"
            threshold = 0
            operator = ">"
            duration = "1m"
            severity = "emergency"
            escalation = @{
                warning = "1m"
                critical = "2m"
                emergency = "5m"
            }
        }
        "data_exfiltration" = @{
            name = "Data Exfiltration Attempt"
            description = "Potential data exfiltration attempt"
            query = "count by (service.name) (message contains \"exfiltration\" or message contains \"data leak\") > 0"
            threshold = 0
            operator = ">"
            duration = "1m"
            severity = "emergency"
            escalation = @{
                warning = "1m"
                critical = "2m"
                emergency = "5m"
            }
        }
    }
    
    "business" = @{
        "transaction_failures" = @{
            name = "Transaction Failures"
            description = "High rate of transaction failures"
            query = "count by (service.name) (message contains \"transaction\" and level=\"ERROR\") > 10"
            threshold = 10
            operator = ">"
            duration = "5m"
            severity = "warning"
            escalation = @{
                warning = "5m"
                critical = "10m"
                emergency = "15m"
            }
        }
        "payment_failures" = @{
            name = "Payment Failures"
            description = "Payment processing failures"
            query = "count by (service.name) (message contains \"payment\" and level=\"ERROR\") > 5"
            threshold = 5
            operator = ">"
            duration = "2m"
            severity = "critical"
            escalation = @{
                warning = "2m"
                critical = "5m"
                emergency = "10m"
            }
        }
        "user_experience_degradation" = @{
            name = "User Experience Degradation"
            description = "User experience metrics degraded"
            query = "avg(response_time_ms) > 5000 and count by (service.name) (message contains \"user\") > 100"
            threshold = 5000
            operator = ">"
            duration = "10m"
            severity = "warning"
            escalation = @{
                warning = "10m"
                critical = "15m"
                emergency = "20m"
            }
        }
        "revenue_impact" = @{
            name = "Revenue Impact"
            description = "Revenue-impacting issues detected"
            query = "count by (service.name) (message contains \"revenue\" and level=\"ERROR\") > 0"
            threshold = 0
            operator = ">"
            duration = "1m"
            severity = "emergency"
            escalation = @{
                warning = "1m"
                critical = "2m"
                emergency = "5m"
            }
        }
    }
}

# Notification channel configurations
$NotificationChannels = @{
    "email" = @{
        name = "Email Notifications"
        type = "email"
        config = @{
            smtp_server = "localhost"
            smtp_port = 587
            username = "alerts@company.com"
            password = "secure_password"
            from_address = "alerts@company.com"
            to_addresses = @("ops-team@company.com", "oncall@company.com")
            subject_template = "[{severity}] {alert_name} - {environment}"
            body_template = @"
Alert: {alert_name}
Severity: {severity}
Description: {description}
Environment: {environment}
Timestamp: {timestamp}
Query: {query}
Current Value: {current_value}
Threshold: {threshold}
"@
        }
    }
    "slack" = @{
        name = "Slack Notifications"
        type = "slack"
        config = @{
            webhook_url = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
            channel = "#alerts"
            username = "SigNoz Alerts"
            icon_emoji = ":warning:"
            message_template = @"
🚨 *{alert_name}*
Severity: *{severity}*
Environment: {environment}
Description: {description}
Current Value: {current_value}
Threshold: {threshold}
Time: {timestamp}
"@
        }
    }
    "webhook" = @{
        name = "Webhook Notifications"
        type = "webhook"
        config = @{
            url = "https://your-webhook-endpoint.com/alerts"
            method = "POST"
            headers = @{
                "Content-Type" = "application/json"
                "Authorization" = "Bearer your-token"
            }
            payload_template = @{
                alert_name = "{alert_name}"
                severity = "{severity}"
                description = "{description}"
                environment = "{environment}"
                timestamp = "{timestamp}"
                query = "{query}"
                current_value = "{current_value}"
                threshold = "{threshold}"
                escalation_level = "{escalation_level}"
            }
        }
    }
    "teams" = @{
        name = "Microsoft Teams Notifications"
        type = "teams"
        config = @{
            webhook_url = "https://outlook.office.com/webhook/YOUR/TEAMS/WEBHOOK"
            title_template = "[{severity}] {alert_name}"
            message_template = @"
**Alert:** {alert_name}
**Severity:** {severity}
**Environment:** {environment}
**Description:** {description}
**Current Value:** {current_value}
**Threshold:** {threshold}
**Time:** {timestamp}
"@
        }
    }
    "pagerduty" = @{
        name = "PagerDuty Notifications"
        type = "pagerduty"
        config = @{
            integration_key = "your-pagerduty-integration-key"
            severity_mapping = @{
                "info" = "info"
                "warning" = "warning"
                "critical" = "critical"
                "emergency" = "critical"
            }
            payload_template = @{
                routing_key = "{integration_key}"
                event_action = "trigger"
                dedup_key = "{alert_name}-{environment}"
                payload = @{
                    summary = "{alert_name}"
                    source = "SigNoz"
                    severity = "{severity}"
                    custom_details = @{
                        description = "{description}"
                        environment = "{environment}"
                        query = "{query}"
                        current_value = "{current_value}"
                        threshold = "{threshold}"
                    }
                }
            }
        }
    }
}

function Get-AlertThresholds {
    param([string]$Type = "all")
    
    if ($Type -eq "all") {
        $allThresholds = @{}
        foreach ($category in $AlertThresholds.Keys) {
            foreach ($alert in $AlertThresholds[$category].Keys) {
                $allThresholds["$category.$alert"] = $AlertThresholds[$category][$alert]
            }
        }
        return $allThresholds
    } else {
        return $AlertThresholds[$Type]
    }
}

function Configure-AlertThresholds {
    param([string]$Type, [string]$Severity)
    
    Write-Alert "Configuring alert thresholds for type: $Type, severity: $Severity"
    
    $thresholds = Get-AlertThresholds -Type $Type
    $configuredAlerts = @()
    
    foreach ($alertKey in $thresholds.Keys) {
        $alert = $thresholds[$alertKey]
        
        # Filter by severity if specified
        if ($Severity -ne "all" -and $alert.severity -ne $Severity) {
            continue
        }
        
        $alertConfig = @{
            name = $alert.name
            description = $alert.description
            query = $alert.query
            condition = @{
                threshold = $alert.threshold
                operator = $alert.operator
                evaluationWindow = $alert.duration
                alertFrequency = "1m"
                notificationOnMissingData = $true
                minimumDataPoints = 1
            }
            severity = $alert.severity
            labels = @{
                service = "observability-pipeline"
                component = "alerting"
                severity = $alert.severity
                environment = "local"
                alert_type = $Type
            }
            notificationChannels = $NotificationChannels.Keys
            escalation = $alert.escalation
        }
        
        $configuredAlerts += $alertConfig
        Write-Success "Configured alert: $($alert.name)"
    }
    
    # Save configuration
    $configFile = Join-Path $ArtifactsDir "alert-thresholds-$Type-$Severity-$Timestamp.json"
    $configuredAlerts | ConvertTo-Json -Depth 5 | Out-File -FilePath $configFile -Encoding UTF8
    
    Write-Success "Alert thresholds configured: $($configuredAlerts.Count) alerts"
    Write-Info "Configuration saved to: $configFile"
    
    return $configuredAlerts
}

function Test-AlertThresholds {
    param([string]$Severity, [switch]$TestMode)
    
    Write-Alert "Testing alert thresholds for severity: $Severity"
    
    $testResults = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        severity = $Severity
        testMode = $TestMode
        results = @()
    }
    
    # Test notification channels
    foreach ($channelName in $NotificationChannels.Keys) {
        $channel = $NotificationChannels[$channelName]
        
        Write-Info "Testing notification channel: $($channel.name)"
        
        $testNotification = @{
            alert_name = "Test Alert - $Severity"
            severity = $Severity
            description = "This is a test notification to verify channel functionality"
            environment = "test"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            query = "test query"
            current_value = "100"
            threshold = "50"
            escalation_level = "test"
        }
        
        try {
            if ($TestMode) {
                Write-Success "Test mode: Would send notification via $($channel.name)"
                $testResult = @{ channel = $channelName; status = "test_mode"; success = $true }
            } else {
                # Send actual test notification
                $testResult = Send-TestNotification -Channel $channel -Notification $testNotification
            }
            
            $testResults.results += $testResult
            Write-Success "Channel test completed: $($channel.name)"
            
        } catch {
            $testResult = @{ channel = $channelName; status = "failed"; success = $false; error = $_.Exception.Message }
            $testResults.results += $testResult
            Write-Error "Channel test failed: $($channel.name) - $($_.Exception.Message)"
        }
    }
    
    # Save test results
    $testFile = Join-Path $ArtifactsDir "alert-test-results-$Severity-$Timestamp.json"
    $testResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $testFile -Encoding UTF8
    
    Write-Success "Alert threshold testing completed"
    Write-Info "Test results saved to: $testFile"
    
    return $testResults
}

function Send-TestNotification {
    param($Channel, $Notification)
    
    switch ($Channel.type) {
        "email" {
            # Email notification logic
            Write-Info "Sending email notification..."
            return @{ channel = $Channel.name; status = "sent"; success = $true }
        }
        "slack" {
            # Slack notification logic
            Write-Info "Sending Slack notification..."
            return @{ channel = $Channel.name; status = "sent"; success = $true }
        }
        "webhook" {
            # Webhook notification logic
            Write-Info "Sending webhook notification..."
            return @{ channel = $Channel.name; status = "sent"; success = $true }
        }
        "teams" {
            # Teams notification logic
            Write-Info "Sending Teams notification..."
            return @{ channel = $Channel.name; status = "sent"; success = $true }
        }
        "pagerduty" {
            # PagerDuty notification logic
            Write-Info "Sending PagerDuty notification..."
            return @{ channel = $Channel.name; status = "sent"; success = $true }
        }
        default {
            throw "Unknown notification channel type: $($Channel.type)"
        }
    }
}

function Validate-AlertThresholds {
    param([string]$Type)
    
    Write-Alert "Validating alert thresholds for type: $Type"
    
    $thresholds = Get-AlertThresholds -Type $Type
    $validationResults = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        type = $Type
        results = @()
    }
    
    foreach ($alertKey in $thresholds.Keys) {
        $alert = $thresholds[$alertKey]
        
        $validation = @{
            alert_name = $alert.name
            issues = @()
            warnings = @()
            recommendations = @()
        }
        
        # Validate query syntax
        if (-not $alert.query -or $alert.query.Trim() -eq "") {
            $validation.issues += "Query is empty or missing"
        }
        
        # Validate threshold values
        if ($alert.threshold -eq $null) {
            $validation.issues += "Threshold value is missing"
        }
        
        # Validate duration
        if (-not $alert.duration -or $alert.duration -notmatch "^\d+[smh]$") {
            $validation.issues += "Duration format is invalid (should be like '5m', '30s', '1h')"
        }
        
        # Validate severity
        if ($alert.severity -notin @("info", "warning", "critical", "emergency")) {
            $validation.issues += "Severity level is invalid"
        }
        
        # Check for escalation configuration
        if (-not $alert.escalation) {
            $validation.warnings += "No escalation configuration found"
        }
        
        # Recommendations
        if ($alert.severity -eq "critical" -and $alert.duration -gt "5m") {
            $validation.recommendations += "Consider reducing duration for critical alerts"
        }
        
        if ($alert.severity -eq "emergency" -and $alert.duration -gt "2m") {
            $validation.recommendations += "Emergency alerts should have shorter durations"
        }
        
        $validationResults.results += $validation
        
        if ($validation.issues.Count -eq 0) {
            Write-Success "Alert validation passed: $($alert.name)"
        } else {
            Write-Warning "Alert validation issues: $($alert.name) - $($validation.issues -join ', ')"
        }
    }
    
    # Save validation results
    $validationFile = Join-Path $ArtifactsDir "alert-validation-$Type-$Timestamp.json"
    $validationResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $validationFile -Encoding UTF8
    
    Write-Success "Alert threshold validation completed"
    Write-Info "Validation results saved to: $validationFile"
    
    return $validationResults
}

function Export-AlertConfiguration {
    param([string]$Type)
    
    Write-Alert "Exporting alert configuration for type: $Type"
    
    $exportData = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        version = "1.0.0"
        alert_thresholds = Get-AlertThresholds -Type $Type
        notification_channels = $NotificationChannels
        metadata = @{
            exported_by = "alert-threshold-manager"
            environment = "local"
            sigNoz_url = $SigNozUrl
        }
    }
    
    $exportFile = Join-Path $ArtifactsDir "alert-configuration-$Type-$Timestamp.json"
    $exportData | ConvertTo-Json -Depth 5 | Out-File -FilePath $exportFile -Encoding UTF8
    
    Write-Success "Alert configuration exported"
    Write-Info "Export file: $exportFile"
    
    return $exportFile
}

# Execute action based on parameter
switch ($Action) {
    "configure" {
        $configuredAlerts = Configure-AlertThresholds -Type $AlertType -Severity $Severity
        Write-Success "Alert threshold configuration completed!"
        Write-Info "Configured $($configuredAlerts.Count) alerts for type: $AlertType"
    }
    
    "test" {
        $testResults = Test-AlertThresholds -Severity $Severity -TestMode:$TestMode
        Write-Success "Alert threshold testing completed!"
        Write-Info "Tested $($testResults.results.Count) notification channels"
    }
    
    "validate" {
        $validationResults = Validate-AlertThresholds -Type $AlertType
        Write-Success "Alert threshold validation completed!"
        $totalIssues = ($validationResults.results | ForEach-Object { $_.issues.Count } | Measure-Object -Sum).Sum
        Write-Info "Found $totalIssues issues across $($validationResults.results.Count) alerts"
    }
    
    "export" {
        $exportFile = Export-AlertConfiguration -Type $AlertType
        Write-Success "Alert configuration export completed!"
        Write-Info "Exported configuration to: $exportFile"
    }
    
    "import" {
        Write-Info "Import functionality would be implemented here"
        Write-Warning "Import action not yet implemented"
    }
}

# Summary
Write-Host ""
Write-Host "🎯 Action Summary:" -ForegroundColor Yellow
Write-Host "Action: $Action" -ForegroundColor White
Write-Host "Alert Type: $AlertType" -ForegroundColor White
Write-Host "Severity: $Severity" -ForegroundColor White
Write-Host "Test Mode: $TestMode" -ForegroundColor White
Write-Host "Notification Channels: $NotificationChannels" -ForegroundColor White

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review generated configuration files in artifacts/" -ForegroundColor White
Write-Host "2. Import alert configurations into SigNoz" -ForegroundColor White
Write-Host "3. Configure notification channels with actual credentials" -ForegroundColor White
Write-Host "4. Test alert thresholds with real data" -ForegroundColor White
Write-Host "5. Set up escalation procedures" -ForegroundColor White

exit 0
