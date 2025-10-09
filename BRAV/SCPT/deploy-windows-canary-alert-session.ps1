# Deploy Windows Canary Alert via SigNoz API Script (Session Cookie Method)
# Alternative to Bearer token authentication for local SigNoz instances

param(
    [string]$SessionCookie = "",
    [string]$SigNozUrl = "http://localhost:8080",
    [switch]$DeployAlert,
    [switch]$TestAlert,
    [switch]$GenerateCanary,
    [switch]$FullDeployment,
    [switch]$DryRun,
    [switch]$GetSessionHelp
)

Write-Host "=== Windows Canary Alert API Deployment (Session Method) ===" -ForegroundColor Green
Write-Host "Task: T-2025-01-27-003 - Canary Alert for Windows Logs (Session API)" -ForegroundColor Yellow

if ($GetSessionHelp) {
    Write-Host "`n=== How to Get Session Cookie ===" -ForegroundColor Cyan
    Write-Host "1. Open your browser and go to: $SigNozUrl" -ForegroundColor White
    Write-Host "2. Log in to SigNoz" -ForegroundColor White
    Write-Host "3. Open Developer Tools (F12)" -ForegroundColor White
    Write-Host "4. Go to Application/Storage → Cookies → $SigNozUrl" -ForegroundColor White
    Write-Host "5. Find the session cookie (usually named 'session', 'sid', or similar)" -ForegroundColor White
    Write-Host "6. Copy the cookie value" -ForegroundColor White
    Write-Host "7. Run this script with: -SessionCookie 'your_cookie_value'" -ForegroundColor White
    Write-Host "`nExample:" -ForegroundColor Yellow
    Write-Host "pwsh -File scripts\deploy-windows-canary-alert-session.ps1 -SessionCookie 'eyJ1c2VySWQiOiIxMjM0NTY3ODkwIiwiaWF0IjoxNjQwOTk1MjAwfQ' -DeployAlert" -ForegroundColor Gray
    exit 0
}

if (-not $SessionCookie) {
    Write-Host "❌ Session cookie is required. Use -GetSessionHelp for instructions." -ForegroundColor Red
    Write-Host "Run: pwsh -File scripts\deploy-windows-canary-alert-session.ps1 -GetSessionHelp" -ForegroundColor Yellow
    exit 1
}

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

# API Configuration with session cookie
$Headers = @{
    "Cookie" = "session=$SessionCookie"
    "Content-Type" = "application/json"
}

# Test SigNoz connectivity
Write-Host "`n=== Testing SigNoz API Connectivity ===" -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Headers $Headers -TimeoutSec 10
    Write-Host "✅ SigNoz API accessible" -ForegroundColor Green
    Write-Host "   Status: $($healthResponse.status)" -ForegroundColor Gray
} catch {
    Write-Host "❌ SigNoz API not accessible: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   URL: $SigNozUrl" -ForegroundColor Gray
    Write-Host "   Session Cookie: $($SessionCookie.Substring(0, [Math]::Min(20, $SessionCookie.Length)))..." -ForegroundColor Gray
    exit 1
}

if ($DeployAlert -or $FullDeployment) {
    Write-Host "`n=== Deploying Windows Canary Alert via Session API ===" -ForegroundColor Yellow
    
    # Create alert configuration (same as the main script)
    $canaryLogsFilter = "log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary'"
    $canaryLogsQuery = "$canaryLogsFilter | stats count() as log_count by bin(1m)"
    $canaryLogCountQuery = "$canaryLogsFilter | stats count()"
    $canaryLogRateQuery = "$canaryLogsFilter | stats count() by bin(1m)"
    $canaryLogLastTimestampQuery = "$canaryLogsFilter | stats latest(@timestamp)"
    
    # Main Alert Configuration for SigNoz API
    $alertPayload = @{
        name = "Windows Canary Log Absence"
        description = "Alert when Windows canary logs stop appearing for more than 5 minutes"
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
        severity = "critical"
        labels = @{
            alert_type = "canary"
            service = "windows-logs"
            environment = "local"
        }
        annotations = @{
            summary = "Windows canary logs have stopped appearing"
            description = "No Windows canary logs detected for 5 minutes. This indicates potential issues with Windows log collection or processing."
            runbook_url = "https://github.com/your-org/otel-observability/blob/main/docs/troubleshooting.md#canary-logs"
        }
        notificationChannels = @('email-default', 'slack-default')
    }
    
    $deploymentResults = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        api_url = $SigNozUrl
        authentication_method = "session_cookie"
        alerts_deployed = 0
        alerts_failed = 0
        results = @()
    }
    
    if (-not $DryRun) {
        # Deploy Main Alert
        Write-Host "📋 Deploying main alert: $($alertPayload.name)" -ForegroundColor Cyan
        try {
            $alertResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts" -Method Post -Body ($alertPayload | ConvertTo-Json -Depth 6) -Headers $Headers -TimeoutSec 30
            if ($alertResponse -is [string]) { 
                throw "Unexpected non-JSON response from SigNoz: $alertResponse" 
            }
            $alertId = $alertResponse.id
            if (-not $alertId -and $alertResponse.data) {
                if ($alertResponse.data.id) { $alertId = $alertResponse.data.id }
                elseif ($alertResponse.data.alertId) { $alertId = $alertResponse.data.alertId }
            }
            if (-not $alertId) { 
                $raw = $alertResponse | ConvertTo-Json -Depth 6 -Compress
                throw "SigNoz API returned no alert id. Response: $raw" 
            }
            Write-Host "  ✅ Main alert deployed successfully" -ForegroundColor Green
            Write-Host "     Alert ID: $alertId" -ForegroundColor Gray

            $deploymentResults.alerts_deployed++
            $deploymentResults.results += @{
                alert_name = $alertPayload.name
                status = "success"
                alert_id = $alertId
                timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        } catch {
            Write-Host "  ❌ Main alert deployment failed: $($_.Exception.Message)" -ForegroundColor Red
            $deploymentResults.alerts_failed++
            $deploymentResults.results += @{
                alert_name = $alertPayload.name
                status = "failed"
                error = $_.Exception.Message
                timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        }
    } else {
        Write-Host "🔍 DRY RUN MODE - No actual deployment performed" -ForegroundColor Yellow
        Write-Host "Alert Payload:" -ForegroundColor Cyan
        $alertPayload | ConvertTo-Json -Depth 6 | Write-Host -ForegroundColor White
    }
    
    # Save configuration to file for reference
    $fullConfig = @{
        alert = $alertPayload
        deployment_results = $deploymentResults
        authentication_method = "session_cookie"
    }
    
    $fullConfig | ConvertTo-Json -Depth 6 | Set-Content -Path $alertConfigFile -Encoding UTF8
    Write-Host "`nAlert configuration saved to: $alertConfigFile" -ForegroundColor Green
    
    # Save deployment results
    $deploymentFile = "artifacts/canary-alert-session-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $deploymentResults | ConvertTo-Json -Depth 4 | Set-Content -Path $deploymentFile -Encoding UTF8
    Write-Host "Deployment results saved to: $deploymentFile" -ForegroundColor Blue
    
    Write-Host "`n=== Session API Deployment Summary ===" -ForegroundColor Cyan
    Write-Host "Alerts deployed: $($deploymentResults.alerts_deployed)" -ForegroundColor Green
    Write-Host "Alerts failed: $($deploymentResults.alerts_failed)" -ForegroundColor Red
    Write-Host "API URL: $SigNozUrl" -ForegroundColor Gray
    Write-Host "Auth Method: Session Cookie" -ForegroundColor Gray
    Write-Host "Log Filter: $canaryLogsFilter" -ForegroundColor Gray
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
            test_id = "canary-alert-session-deployment"
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
    Write-Host "3. Check Alerts section for deployed alerts" -ForegroundColor White
    Write-Host "4. Test alert by stopping canary generation for 5+ minutes" -ForegroundColor White
}

Write-Host "`n=== Windows Canary Alert Session API Deployment Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Verify alerts are active in SigNoz UI: $SigNozUrl" -ForegroundColor White
Write-Host "2. Check canary logs are being collected" -ForegroundColor White
Write-Host "3. Test alert by stopping canary generation" -ForegroundColor White
Write-Host "4. Monitor alert status in SigNoz" -ForegroundColor White
Write-Host "5. Review deployment results in artifacts/" -ForegroundColor White
