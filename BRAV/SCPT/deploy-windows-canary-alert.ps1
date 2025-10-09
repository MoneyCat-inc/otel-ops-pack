# Deploy Windows Canary Alert Script
# Implements T-2025-01-27-003: Canary Alert for Windows Logs

param(
    [switch]$DeployAlert,
    [switch]$TestAlert,
    [switch]$GenerateCanary,
    [switch]$FullDeployment
)

Write-Host "=== Windows Canary Alert Deployment ===" -ForegroundColor Green
Write-Host "Task: T-2025-01-27-003 - Canary Alert for Windows Logs" -ForegroundColor Yellow

# Ensure logs directory exists
if (-not (Test-Path "C:\logs")) {
    New-Item -ItemType Directory -Path "C:\logs" -Force
    Write-Host "Created C:\logs directory" -ForegroundColor Green
}

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
    Write-Host "Created artifacts directory" -ForegroundColor Green
}

$logFile = "C:\logs\windows-canary-test.log"
$alertConfigFile = "artifacts/signoz-windows-canary-alert.json"

if ($DeployAlert -or $FullDeployment) {
    Write-Host "`n=== Deploying Windows Canary Alert ===" -ForegroundColor Yellow
    
        # Create alert configuration
    $canaryLogsQuery = "log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary'"
    $alertConfig = @{
        alert = @{
            name = "Windows Canary Log Absence"
            description = "Alert when Windows canary logs stop appearing for more than 5 minutes"
            severity = "critical"
            labels = @{
                alert_type = "canary"
                service = "windows-logs"
                environment = "production"
            }
            query = @{
                queryType = "logs"
                logsQuery = @{
                    query = $canaryLogsQuery
                    groupBy = @('log.file.path')
                    legendFormat = "{{log.file.path}}"
                }
            }
            condition = @{
                threshold = 1
                operator = "below"
                evaluationWindow = "5m"
                alertFrequency = "1m"
                notificationOnMissingData = $true
                minimumDataPoints = 1
            }
            notificationChannels = @('email-default', 'slack-default')
            annotations = @{
                summary = "Windows canary logs have stopped appearing"
                description = "No Windows canary logs detected for 5 minutes. This indicates potential issues with Windows log collection or processing."
                runbook_url = "https://github.com/your-org/otel-observability/blob/main/docs/troubleshooting.md#canary-logs"
            }
        }
        test_alert = @{
            name = "Windows Canary Test Alert"
            description = "Test alert for Windows canary log absence detection"
            severity = "warning"
            labels = @{
                alert_type = "canary_test"
                service = "windows-logs"
                environment = "test"
            }
            query = @{
                queryType = "logs"
                logsQuery = @{
                    query = $canaryLogsQuery
                    groupBy = @('log.file.path')
                    legendFormat = "{{log.file.path}}"
                }
            }
            condition = @{
                threshold = 1
                operator = "below"
                evaluationWindow = "2m"
                alertFrequency = "1m"
                notificationOnMissingData = $true
                minimumDataPoints = 1
            }
        }
        dashboard_panel = @{
            title = "Windows Canary Log Health"
            description = "Monitor Windows canary log generation and alert status"
            panels = @(
                @{
                    title = "Canary Log Count (Last Hour)"
                    query = $canaryLogsQuery
                    type = "stat"
                    thresholds = @{
                        warning = 10
                        critical = 5
                    }
                },
                @{
                    title = "Canary Log Rate (per minute)"
                    query = $canaryLogsQuery
                    type = "line"
                },
                @{
                    title = "Last Canary Log Timestamp"
                    query = $canaryLogsQuery
                    type = "stat"
                }
            )
        }
    }

    $alertConfig | ConvertTo-Json -Depth 6 | Set-Content -Path $alertConfigFile -Encoding UTF8
    Write-Host "Alert configuration saved to: $alertConfigFile" -ForegroundColor Green
    
    Write-Host "`n=== SigNoz Alert Import Instructions ===" -ForegroundColor Cyan
    Write-Host "1. Open SigNoz UI: http://localhost:8080" -ForegroundColor White
    Write-Host "2. Navigate to: Alerts -> Create Alert" -ForegroundColor White
    Write-Host "3. Use the configuration from: $alertConfigFile" -ForegroundColor White
    Write-Host "4. Alert Filter: $canaryLogsQuery" -ForegroundColor White
    Write-Host "5. Set severity: Critical, Evaluation window: 5m" -ForegroundColor White
}

if ($GenerateCanary -or $FullDeployment) {
    Write-Host "`n=== Generating Windows Canary Logs ===" -ForegroundColor Yellow
    
    # Generate initial canary logs
    for ($i = 1; $i -le 5; $i++) {
        $logEntry = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            level = "INFO"
            message = "windows-canary test log entry $i - $(Get-Date)"
            service = "canary-test"
            canary = "true"
            test_id = "canary-alert-deployment"
            source = "windows-event-log"
        } | ConvertTo-Json -Compress
        
        Add-Content -Path $logFile -Value $logEntry
        Write-Host "Generated canary log $i" -ForegroundColor Green
        Start-Sleep -Seconds 2
    }
    
    Write-Host "Generated 5 initial canary logs" -ForegroundColor Green
}

if ($TestAlert -or $FullDeployment) {
    Write-Host "`n=== Testing Canary Alert ===" -ForegroundColor Yellow
    
    Write-Host "Verification steps:" -ForegroundColor Cyan
    Write-Host "1. Check SigNoz UI -> Logs -> filter: log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary'" -ForegroundColor White
    Write-Host "2. Verify canary logs are visible in SigNoz" -ForegroundColor White
    Write-Host "3. Import the alert configuration from $alertConfigFile" -ForegroundColor White
    Write-Host "4. Test alert by stopping canary generation for 5+ minutes" -ForegroundColor White
    
    # Generate test report
    $testResults = @{
        task_id = "T-2025-01-27-003"
        task_name = "Canary Alert for Windows Logs"
        deployment_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        alert_config_file = $alertConfigFile
        canary_log_file = $logFile
        status = "deployed"
        verification_steps = @(
            "Check SigNoz UI -> Logs with filter: log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary'",
            "Import alert configuration from artifacts/signoz-windows-canary-alert.json",
            "Verify alert triggers after 5 minutes of no canary logs",
            "Test alert resolution when canary logs resume"
        )
        signoz_ui_url = "http://localhost:8080"
        alert_query = "log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary'"
    }
    
    $reportFile = "artifacts/canary-alert-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testResults | ConvertTo-Json -Depth 4 | Set-Content -Path $reportFile -Encoding UTF8
    Write-Host "`nDeployment report saved to: $reportFile" -ForegroundColor Blue
}

Write-Host "`n=== Windows Canary Alert Deployment Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Import alert configuration in SigNoz UI" -ForegroundColor White
Write-Host "2. Verify canary logs are being collected" -ForegroundColor White
Write-Host "3. Test alert by stopping canary generation" -ForegroundColor White
Write-Host "4. Monitor alert status in SigNoz" -ForegroundColor White

