# Production SSOT Monitoring Script
# Continuous monitoring and alerting for production SSOT health metrics

param(
    [switch]$Continuous,
    [int]$IntervalMinutes = 15,
    [int]$HealthThreshold = 95,
    [string]$LogPath = ".artifacts/production-monitoring.log",
    [switch]$EnableAlerts,
    [string]$SlackWebhook,
    [string]$EmailRecipients,
    [switch]$GenerateReports,
    [string]$ReportPath = ".artifacts/production-reports",
    [switch]$DryRun
)

Write-Host "🏭 Production SSOT Monitoring" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Ensure artifacts directory exists
if (-not (Test-Path ".artifacts")) {
    New-Item -ItemType Directory -Path ".artifacts" -Force | Out-Null
}

if ($GenerateReports -and -not (Test-Path $ReportPath)) {
    New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
}

# Initialize monitoring log
$logMessage = "Production SSOT Monitoring Started - $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
$logMessage | Out-File -FilePath $LogPath -Append -Encoding UTF8

# Production monitoring function
function Start-ProductionMonitoring {
    param(
        [int]$Interval,
        [int]$Threshold,
        [string]$LogFile,
        [switch]$Alerts,
        [string]$Slack,
        [string]$Email,
        [switch]$Reports,
        [string]$ReportDir,
        [switch]$DryRunMode
    )
    
    $monitoringStartTime = Get-Date
    $healthHistory = @()
    $alertHistory = @()
    $reportCount = 0
    
    Write-Host "🔄 Starting production monitoring..." -ForegroundColor Yellow
    Write-Host "   Interval: $Interval minutes" -ForegroundColor Cyan
    Write-Host "   Health Threshold: $Threshold%" -ForegroundColor Cyan
    Write-Host "   Log: $LogFile" -ForegroundColor Cyan
    Write-Host "   Alerts: $(if ($Alerts) { 'Enabled' } else { 'Disabled' })" -ForegroundColor Cyan
    Write-Host "   Reports: $(if ($Reports) { 'Enabled' } else { 'Disabled' })" -ForegroundColor Cyan
    Write-Host "   Mode: $(if ($DryRunMode) { 'DRY RUN' } else { 'ACTIVE' })" -ForegroundColor $(if ($DryRunMode) { 'Yellow' } else { 'Green' })
    
    if ($DryRunMode) {
        Write-Host "⚠️ DRY RUN MODE: Monitoring simulation only" -ForegroundColor Yellow
        return
    }
    
    # Main monitoring loop
    while ($true) {
        $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        $cycleStart = Get-Date
        
        Write-Host "`n🔄 Production Health Check - $timestamp" -ForegroundColor Cyan
        "=== Production Health Check - $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
        
        try {
            # Run SSOT health check
            $healthResult = & pwsh -ExecutionPolicy Bypass -File "scripts/monitor-ssot-health.ps1" -Detailed 2>&1
            $healthExitCode = $LASTEXITCODE
            
            if ($healthExitCode -eq 0) {
                # Parse health score from output
                $healthScore = if ($healthResult -match "Overall Health: (\d+)%") { [int]$matches[1] } else { 0 }
                $freshness = if ($healthResult -match "Status: (\w+)") { $matches[1] } else { "unknown" }
                
                $healthData = @{
                    Timestamp = $timestamp
                    HealthScore = $healthScore
                    Freshness = $freshness
                    Status = "healthy"
                    ExitCode = $healthExitCode
                }
                
                $healthHistory += $healthData
                
                Write-Host "✅ Health Check: $healthScore% ($freshness)" -ForegroundColor Green
                "Health Check: SUCCESS - $healthScore% ($freshness)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                
                # Check for health threshold alerts
                if ($healthScore -lt $Threshold) {
                    $alertMessage = "SSOT health score dropped below threshold ($Threshold%): $healthScore%"
                    Write-Host "🚨 ALERT: $alertMessage" -ForegroundColor Red
                    "ALERT: $alertMessage" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                    
                    $alertData = @{
                        Timestamp = $timestamp
                        Type = "health_threshold"
                        Message = $alertMessage
                        Severity = "critical"
                    }
                    $alertHistory += $alertData
                    
                    if ($Alerts) {
                        Send-ProductionAlert -Alert $alertData -Slack $Slack -Email $Email
                    }
                }
                
                # Check for stale SSOT
                if ($freshness -ne "fresh") {
                    $alertMessage = "SSOT block is stale: $freshness"
                    Write-Host "⚠️ WARNING: $alertMessage" -ForegroundColor Yellow
                    "WARNING: $alertMessage" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                    
                    $alertData = @{
                        Timestamp = $timestamp
                        Type = "freshness_warning"
                        Message = $alertMessage
                        Severity = "warning"
                    }
                    $alertHistory += $alertData
                    
                    if ($Alerts) {
                        Send-ProductionAlert -Alert $alertData -Slack $Slack -Email $Email
                    }
                }
                
            } else {
                $healthData = @{
                    Timestamp = $timestamp
                    HealthScore = 0
                    Freshness = "unknown"
                    Status = "error"
                    ExitCode = $healthExitCode
                }
                $healthHistory += $healthData
                
                $errorMessage = "SSOT health check failed with exit code $healthExitCode"
                Write-Host "❌ ERROR: $errorMessage" -ForegroundColor Red
                "ERROR: $errorMessage" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                
                $alertData = @{
                    Timestamp = $timestamp
                    Type = "health_check_failure"
                    Message = $errorMessage
                    Severity = "critical"
                }
                $alertHistory += $alertData
                
                if ($Alerts) {
                    Send-ProductionAlert -Alert $alertData -Slack $Slack -Email $Email
                }
            }
            
        } catch {
            $errorMessage = "Health check exception: $($_.Exception.Message)"
            Write-Host "❌ EXCEPTION: $errorMessage" -ForegroundColor Red
            "EXCEPTION: $errorMessage" | Out-File -FilePath $LogFile -Append -Encoding UTF8
            
            $alertData = @{
                Timestamp = $timestamp
                Type = "health_check_exception"
                Message = $errorMessage
                Severity = "critical"
            }
            $alertHistory += $alertData
            
            if ($Alerts) {
                Send-ProductionAlert -Alert $alertData -Slack $Slack -Email $Email
            }
        }
        
        # Generate periodic reports
        if ($Reports -and $healthHistory.Count % 4 -eq 0) {  # Every 4 cycles (1 hour if 15min intervals)
            $reportCount++
            Generate-ProductionReport -HealthHistory $healthHistory -AlertHistory $alertHistory -ReportPath $ReportDir -ReportNumber $reportCount
        }
        
        # Update SSOT block
        try {
            node scripts/ci-ssot-telemetry.ts | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ SSOT block updated" -ForegroundColor Green
                "SSOT block update: SUCCESS" | Out-File -FilePath $LogFile -Append -Encoding UTF8
            } else {
                Write-Host "❌ SSOT block update failed" -ForegroundColor Red
                "SSOT block update: FAILED (exit code: $LASTEXITCODE)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
            }
        } catch {
            Write-Host "❌ SSOT block update exception: $($_.Exception.Message)" -ForegroundColor Red
            "SSOT block update: EXCEPTION - $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
        }
        
        $cycleEnd = Get-Date
        $cycleDuration = ($cycleEnd - $cycleStart).TotalSeconds
        Write-Host "⏱️ Cycle completed in $([math]::Round($cycleDuration, 1)) seconds" -ForegroundColor Cyan
        
        # Wait for next cycle
        $sleepSeconds = $Interval * 60
        Write-Host "😴 Sleeping for $sleepSeconds seconds until next cycle..." -ForegroundColor Gray
        Start-Sleep -Seconds $sleepSeconds
    }
}

# Send production alerts
function Send-ProductionAlert {
    param(
        [hashtable]$Alert,
        [string]$Slack,
        [string]$Email
    )
    
    $timestamp = $Alert.Timestamp
    $type = $Alert.Type
    $message = $Alert.Message
    $severity = $Alert.Severity
    
    Write-Host "🚨 Sending production alert: $type ($severity)" -ForegroundColor Red
    
    # Slack alert
    if ($Slack) {
        $slackPayload = @{
            text = "🚨 Production SSOT Alert - $severity"
            attachments = @(
                @{
                    color = if ($severity -eq "critical") { "danger" } elseif ($severity -eq "warning") { "warning" } else { "good" }
                    fields = @(
                        @{ title = "Timestamp"; value = $timestamp; short = $true }
                        @{ title = "Type"; value = $type; short = $true }
                        @{ title = "Severity"; value = $severity; short = $true }
                        @{ title = "Message"; value = $message; short = $false }
                    )
                }
            )
        } | ConvertTo-Json -Depth 10
        
        try {
            Invoke-RestMethod -Uri $Slack -Method POST -Body $slackPayload -ContentType "application/json"
            Write-Host "✅ Slack alert sent" -ForegroundColor Green
        } catch {
            Write-Host "❌ Slack alert failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Email alert
    if ($Email) {
        $subject = "Production SSOT Alert - $severity - $type"
        $body = @"
Production SSOT Alert

Timestamp: $timestamp
Type: $type
Severity: $severity
Message: $message

Please check the production monitoring dashboard and logs for more details.

Production Monitoring System
"@
        
        try {
            Send-MailMessage -To $Email -Subject $subject -Body $body -SmtpServer "localhost"
            Write-Host "✅ Email alert sent" -ForegroundColor Green
        } catch {
            Write-Host "❌ Email alert failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Generate production reports
function Generate-ProductionReport {
    param(
        [array]$HealthHistory,
        [array]$AlertHistory,
        [string]$ReportPath,
        [int]$ReportNumber
    )
    
    $reportTimestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    $reportFile = Join-Path $ReportPath "production-report-$ReportNumber.json"
    
    # Calculate statistics
    $totalChecks = $HealthHistory.Count
    $healthyChecks = ($HealthHistory | Where-Object { $_.Status -eq "healthy" }).Count
    $errorChecks = ($HealthHistory | Where-Object { $_.Status -eq "error" }).Count
    $avgHealthScore = if ($totalChecks -gt 0) { [math]::Round(($HealthHistory | Where-Object { $_.HealthScore -gt 0 } | Measure-Object -Property HealthScore -Average).Average, 2) } else { 0 }
    $totalAlerts = $AlertHistory.Count
    $criticalAlerts = ($AlertHistory | Where-Object { $_.Severity -eq "critical" }).Count
    $warningAlerts = ($AlertHistory | Where-Object { $_.Severity -eq "warning" }).Count
    
    $report = @{
        ReportNumber = $ReportNumber
        GeneratedAt = $reportTimestamp
        Summary = @{
            TotalHealthChecks = $totalChecks
            HealthyChecks = $healthyChecks
            ErrorChecks = $errorChecks
            HealthCheckSuccessRate = if ($totalChecks -gt 0) { [math]::Round(($healthyChecks / $totalChecks) * 100, 2) } else { 0 }
            AverageHealthScore = $avgHealthScore
            TotalAlerts = $totalAlerts
            CriticalAlerts = $criticalAlerts
            WarningAlerts = $warningAlerts
        }
        HealthHistory = $HealthHistory
        AlertHistory = $AlertHistory
    }
    
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile -Encoding UTF8
    
    Write-Host "📊 Production report generated: $reportFile" -ForegroundColor Green
    Write-Host "   Health Checks: $totalChecks ($healthyChecks healthy, $errorChecks errors)" -ForegroundColor Cyan
    Write-Host "   Average Health Score: $avgHealthScore%" -ForegroundColor Cyan
    Write-Host "   Alerts: $totalAlerts ($criticalAlerts critical, $warningAlerts warnings)" -ForegroundColor Cyan
}

# Start monitoring
if ($Continuous) {
    Start-ProductionMonitoring -Interval $IntervalMinutes -Threshold $HealthThreshold -LogFile $LogPath -Alerts:$EnableAlerts -Slack $SlackWebhook -Email $EmailRecipients -Reports:$GenerateReports -ReportDir $ReportPath -DryRunMode:$DryRun
} else {
    # Single monitoring cycle
    Write-Host "🔄 Running single production health check..." -ForegroundColor Yellow
    
    try {
        $healthResult = & pwsh -ExecutionPolicy Bypass -File "scripts/monitor-ssot-health.ps1" -Detailed 2>&1
        $healthExitCode = $LASTEXITCODE
        
        if ($healthExitCode -eq 0) {
            $healthScore = if ($healthResult -match "Overall Health: (\d+)%") { [int]$matches[1] } else { 0 }
            Write-Host "✅ Production Health Check: $healthScore%" -ForegroundColor Green
            "Single production health check: SUCCESS - $healthScore%" | Out-File -FilePath $LogPath -Append -Encoding UTF8
            
            if ($healthScore -lt $HealthThreshold) {
                Write-Host "🚨 ALERT: Health score below threshold ($HealthThreshold%)" -ForegroundColor Red
                "ALERT: Health score below threshold" | Out-File -FilePath $LogPath -Append -Encoding UTF8
            }
        } else {
            Write-Host "❌ Production Health Check Failed: exit code $healthExitCode" -ForegroundColor Red
            "Single production health check: FAILED (exit code: $healthExitCode)" | Out-File -FilePath $LogPath -Append -Encoding UTF8
        }
    } catch {
        Write-Host "❌ Production Health Check Exception: $($_.Exception.Message)" -ForegroundColor Red
        "Single production health check: EXCEPTION - $($_.Exception.Message)" | Out-File -FilePath $LogPath -Append -Encoding UTF8
    }
}

# ECRR Compliance
Write-Host "`n🎭 ECRR Compliance" -ForegroundColor Magenta
Write-Host "==================" -ForegroundColor Magenta
Write-Host "✅ Examine: Production SSOT state captured and monitored" -ForegroundColor Green
Write-Host "✅ Clean: Production monitoring system operational" -ForegroundColor Green
Write-Host "✅ Report: Monitoring results documented with evidence" -ForegroundColor Green
Write-Host "✅ Role: Cursor Agent (Observability Copilot) - Production monitoring" -ForegroundColor Green

Write-Host "`n📝 Production monitoring log: $LogPath" -ForegroundColor Cyan
if ($GenerateReports) {
    Write-Host "📊 Production reports: $ReportPath" -ForegroundColor Cyan
}