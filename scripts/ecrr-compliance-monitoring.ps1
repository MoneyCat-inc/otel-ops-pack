# ECRR Automated Compliance Monitoring System

param(
    [string]$ReportPath = "docs/ECRR_REPORTS",
    [string]$OutputPath = "artifacts/ecrr-compliance-monitoring",
    [string]$ConfigPath = "config/ecrr-monitoring.json",
    [switch]$Continuous,
    [switch]$Alert,
    [switch]$Dashboard,
    [int]$Threshold = 80
)

# ECRR Compliance Monitoring Configuration
$MONITORING_CONFIG = @{
    "Thresholds" = @{
        "Critical" = 50
        "Warning" = 70
        "Target" = 80
        "Excellent" = 90
    }
    "Metrics" = @{
        "Overall_Score" = @{
            "Weight" = 0.3
            "Target" = 80
        }
        "Structure_Compliance" = @{
            "Weight" = 0.25
            "Target" = 80
        }
        "Content_Compliance" = @{
            "Weight" = 0.25
            "Target" = 80
        }
        "Quality_Compliance" = @{
            "Weight" = 0.2
            "Target" = 80
        }
    }
    "Alerts" = @{
        "Regression_Threshold" = 5
        "Critical_Threshold" = 50
        "Notification_Channels" = @("console", "file", "webhook")
    }
    "Dashboard" = @{
        "Update_Interval" = 300
        "Retention_Days" = 30
        "Export_Formats" = @("json", "html", "csv")
    }
}

# Load existing compliance validation script
. "$PSScriptRoot/validate-ecrr-compliance.ps1"

function Initialize-ECRRMonitoring {
    param(
        [string]$ConfigPath,
        [string]$OutputPath
    )
    
    Write-Host "🔧 Initializing ECRR Compliance Monitoring System..." -ForegroundColor Cyan
    
    # Create output directories
    $directories = @(
        "$OutputPath",
        "$OutputPath/history",
        "$OutputPath/dashboard",
        "$OutputPath/alerts",
        "$OutputPath/exports"
    )
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "✅ Created directory: $dir" -ForegroundColor Green
        }
    }
    
    # Save monitoring configuration
    $MONITORING_CONFIG | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
    Write-Host "✅ Configuration saved: $ConfigPath" -ForegroundColor Green
    
    # Initialize monitoring state
    $monitoringState = @{
        "LastRun" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        "TotalRuns" = 0
        "LastScore" = 0
        "Trend" = "stable"
        "Alerts" = @()
        "History" = @()
    }
    
    $monitoringState | ConvertTo-Json -Depth 10 | Out-File -FilePath "$OutputPath/monitoring-state.json" -Encoding UTF8
    Write-Host "✅ Monitoring state initialized" -ForegroundColor Green
}

function Get-ComplianceTrend {
    param(
        [array]$History,
        [double]$CurrentScore
    )
    
    if ($History.Count -lt 2) {
        return "insufficient_data"
    }
    
    $recentScores = $History | Select-Object -Last 5 | ForEach-Object { $_.Overall_Score }
    $averageRecent = ($recentScores | Measure-Object -Average).Average
    $previousAverage = if ($History.Count -ge 10) { 
        ($History | Select-Object -Skip ($History.Count - 10) | Select-Object -First 5 | ForEach-Object { $_.Overall_Score } | Measure-Object -Average).Average 
    } else { 
        $averageRecent 
    }
    
    $difference = $CurrentScore - $previousAverage
    
    if ($difference -gt 5) { return "improving" }
    elseif ($difference -lt -5) { return "declining" }
    else { return "stable" }
}

function Test-ComplianceRegression {
    param(
        [double]$CurrentScore,
        [double]$PreviousScore,
        [double]$Threshold
    )
    
    $regression = $PreviousScore - $CurrentScore
    return $regression -gt $Threshold
}

function Send-ComplianceAlert {
    param(
        [string]$AlertType,
        [string]$Message,
        [hashtable]$Data,
        [string]$OutputPath
    )
    
    $alert = @{
        "Timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        "Type" = $AlertType
        "Message" = $Message
        "Data" = $Data
        "Severity" = switch ($AlertType) {
            "critical" { "HIGH" }
            "regression" { "MEDIUM" }
            "warning" { "LOW" }
            default { "INFO" }
        }
    }
    
    # Save alert to file
    $alertPath = "$OutputPath/alerts/alert-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $alert | ConvertTo-Json -Depth 10 | Out-File -FilePath $alertPath -Encoding UTF8
    
    # Console output
    $color = switch ($AlertType) {
        "critical" { "Red" }
        "regression" { "Yellow" }
        "warning" { "Magenta" }
        default { "Cyan" }
    }
    
    Write-Host "🚨 $($alert.Severity) ALERT: $Message" -ForegroundColor $color
    
    return $alert
}

function Export-ComplianceDashboard {
    param(
        [hashtable]$ComplianceData,
        [string]$OutputPath,
        [string]$Format = "html"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    
    switch ($Format) {
        "html" {
            $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>ECRR Compliance Dashboard</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric-card { background: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 4px solid #007bff; }
        .metric-value { font-size: 2em; font-weight: bold; margin-bottom: 10px; }
        .metric-label { color: #666; font-size: 0.9em; }
        .status-critical { border-left-color: #dc3545; }
        .status-warning { border-left-color: #ffc107; }
        .status-good { border-left-color: #28a745; }
        .status-excellent { border-left-color: #17a2b8; }
        .chart-container { margin: 20px 0; }
        .alerts { margin-top: 30px; }
        .alert { padding: 15px; margin: 10px 0; border-radius: 4px; }
        .alert-critical { background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
        .alert-warning { background-color: #fff3cd; border: 1px solid #ffeaa7; color: #856404; }
        .alert-info { background-color: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 ECRR Compliance Dashboard</h1>
            <p>Generated: $timestamp</p>
        </div>
        
        <div class="metrics">
            <div class="metric-card status-$($ComplianceData.Overall_Score -lt 50 ? 'critical' : ($ComplianceData.Overall_Score -lt 70 ? 'warning' : ($ComplianceData.Overall_Score -lt 90 ? 'good' : 'excellent')))">
                <div class="metric-value">$([math]::Round($ComplianceData.Overall_Score, 1))%</div>
                <div class="metric-label">Overall Compliance Score</div>
            </div>
            
            <div class="metric-card status-$($ComplianceData.Structure_Compliance -lt 50 ? 'critical' : ($ComplianceData.Structure_Compliance -lt 70 ? 'warning' : ($ComplianceData.Structure_Compliance -lt 90 ? 'good' : 'excellent')))">
                <div class="metric-value">$([math]::Round($ComplianceData.Structure_Compliance, 1))%</div>
                <div class="metric-label">Structure Compliance</div>
            </div>
            
            <div class="metric-card status-$($ComplianceData.Content_Compliance -lt 50 ? 'critical' : ($ComplianceData.Content_Compliance -lt 70 ? 'warning' : ($ComplianceData.Content_Compliance -lt 90 ? 'good' : 'excellent')))">
                <div class="metric-value">$([math]::Round($ComplianceData.Content_Compliance, 1))%</div>
                <div class="metric-label">Content Compliance</div>
            </div>
            
            <div class="metric-card status-$($ComplianceData.Quality_Compliance -lt 50 ? 'critical' : ($ComplianceData.Quality_Compliance -lt 70 ? 'warning' : ($ComplianceData.Quality_Compliance -lt 90 ? 'good' : 'excellent')))">
                <div class="metric-value">$([math]::Round($ComplianceData.Quality_Compliance, 1))%</div>
                <div class="metric-label">Quality Compliance</div>
            </div>
        </div>
        
        <div class="chart-container">
            <h3>📊 Compliance Breakdown</h3>
            <p><strong>Total Reports:</strong> $($ComplianceData.Total_Reports)</p>
            <p><strong>Trend:</strong> $($ComplianceData.Trend)</p>
            <p><strong>Last Updated:</strong> $($ComplianceData.LastRun)</p>
        </div>
        
        <div class="alerts">
            <h3>🚨 Recent Alerts</h3>
            $(if ($ComplianceData.Alerts.Count -gt 0) {
                $ComplianceData.Alerts | ForEach-Object {
                    "<div class='alert alert-$($_.Type)'>$($_.Message)</div>"
                } -join ""
            } else {
                "<div class='alert alert-info'>No recent alerts</div>"
            })
        </div>
        
        <div class="footer">
            <p>ECRR Automated Compliance Monitoring System</p>
            <p>Generated by Cursor Agent - Observability Copilot</p>
        </div>
    </div>
</body>
</html>
"@
            
            $htmlPath = "$OutputPath/dashboard/compliance-dashboard.html"
            $htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
            Write-Host "✅ HTML dashboard exported: $htmlPath" -ForegroundColor Green
        }
        
        "json" {
            $jsonPath = "$OutputPath/exports/compliance-dashboard-$timestamp.json"
            $ComplianceData | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
            Write-Host "✅ JSON dashboard exported: $jsonPath" -ForegroundColor Green
        }
        
        "csv" {
            $csvData = @(
                [PSCustomObject]@{
                    "Timestamp" = $timestamp
                    "Overall_Score" = $ComplianceData.Overall_Score
                    "Structure_Compliance" = $ComplianceData.Structure_Compliance
                    "Content_Compliance" = $ComplianceData.Content_Compliance
                    "Quality_Compliance" = $ComplianceData.Quality_Compliance
                    "Total_Reports" = $ComplianceData.Total_Reports
                    "Trend" = $ComplianceData.Trend
                }
            )
            
            $csvPath = "$OutputPath/exports/compliance-metrics-$timestamp.csv"
            $csvData | Export-Csv -Path $csvPath -NoTypeInformation
            Write-Host "✅ CSV dashboard exported: $csvPath" -ForegroundColor Green
        }
    }
}

function Start-ECRRComplianceMonitoring {
    param(
        [string]$ReportPath,
        [string]$OutputPath,
        [string]$ConfigPath,
        [switch]$Continuous,
        [switch]$Alert,
        [switch]$Dashboard,
        [int]$Threshold
    )
    
    Write-Host "🚀 Starting ECRR Compliance Monitoring..." -ForegroundColor Cyan
    
    # Initialize monitoring system
    Initialize-ECRRMonitoring -ConfigPath $ConfigPath -OutputPath $OutputPath
    
    # Load monitoring state
    $statePath = "$OutputPath/monitoring-state.json"
    $monitoringState = if (Test-Path $statePath) {
        Get-Content $statePath | ConvertFrom-Json
    } else {
        @{
            "LastRun" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            "TotalRuns" = 0
            "LastScore" = 0
            "Trend" = "stable"
            "Alerts" = @()
            "History" = @()
        }
    }
    
    do {
        Write-Host "🔍 Running compliance validation..." -ForegroundColor Cyan
        
        # Run compliance validation
        $complianceResults = Test-ECRRCompliance -ReportPath $ReportPath -OutputPath "$OutputPath/compliance-report.json"
        
        # Calculate compliance metrics
        $overallScore = $complianceResults.Overall_Score
        $structureCompliance = ($complianceResults.Reports | ForEach-Object { $_.Compliance.Structure._Score } | Measure-Object -Average).Average
        $contentCompliance = ($complianceResults.Reports | ForEach-Object { $_.Compliance.Content._Score } | Measure-Object -Average).Average
        $qualityCompliance = ($complianceResults.Reports | ForEach-Object { $_.Compliance.Quality._Score } | Measure-Object -Average).Average
        
        # Update monitoring state
        $monitoringState.TotalRuns++
        $monitoringState.LastRun = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        
        # Calculate trend
        $trend = Get-ComplianceTrend -History $monitoringState.History -CurrentScore $overallScore
        $monitoringState.Trend = $trend
        
        # Check for regressions
        $regression = Test-ComplianceRegression -CurrentScore $overallScore -PreviousScore $monitoringState.LastScore -Threshold $MONITORING_CONFIG.Alerts.Regression_Threshold
        
        # Generate alerts
        $alerts = @()
        
        if ($overallScore -lt $MONITORING_CONFIG.Thresholds.Critical) {
            $alert = Send-ComplianceAlert -AlertType "critical" -Message "Critical compliance score: $([math]::Round($overallScore, 1))%" -Data @{ "Score" = $overallScore } -OutputPath $OutputPath
            $alerts += $alert
        }
        elseif ($regression) {
            $alert = Send-ComplianceAlert -AlertType "regression" -Message "Compliance regression detected: $([math]::Round($monitoringState.LastScore - $overallScore, 1))% decrease" -Data @{ "PreviousScore" = $monitoringState.LastScore; "CurrentScore" = $overallScore } -OutputPath $OutputPath
            $alerts += $alert
        }
        elseif ($overallScore -lt $MONITORING_CONFIG.Thresholds.Warning) {
            $alert = Send-ComplianceAlert -AlertType "warning" -Message "Compliance below warning threshold: $([math]::Round($overallScore, 1))%" -Data @{ "Score" = $overallScore } -OutputPath $OutputPath
            $alerts += $alert
        }
        
        # Add to history
        $historyEntry = @{
            "Timestamp" = $monitoringState.LastRun
            "Overall_Score" = $overallScore
            "Structure_Compliance" = $structureCompliance
            "Content_Compliance" = $contentCompliance
            "Quality_Compliance" = $qualityCompliance
            "Total_Reports" = $complianceResults.Total_Reports
            "Trend" = $trend
            "Alerts" = $alerts
        }
        
        $monitoringState.History += $historyEntry
        $monitoringState.LastScore = $overallScore
        $monitoringState.Alerts = $alerts
        
        # Keep only last 30 days of history
        $cutoffDate = (Get-Date).AddDays(-30)
        $monitoringState.History = $monitoringState.History | Where-Object { [DateTime]::Parse($_.Timestamp) -gt $cutoffDate }
        
        # Save updated state
        $monitoringState | ConvertTo-Json -Depth 10 | Out-File -FilePath $statePath -Encoding UTF8
        
        # Generate dashboard if requested
        if ($Dashboard) {
            $dashboardData = @{
                "Overall_Score" = $overallScore
                "Structure_Compliance" = $structureCompliance
                "Content_Compliance" = $contentCompliance
                "Quality_Compliance" = $qualityCompliance
                "Total_Reports" = $complianceResults.Total_Reports
                "Trend" = $trend
                "LastRun" = $monitoringState.LastRun
                "Alerts" = $alerts
            }
            
            Export-ComplianceDashboard -ComplianceData $dashboardData -OutputPath $OutputPath -Format "html"
            Export-ComplianceDashboard -ComplianceData $dashboardData -OutputPath $OutputPath -Format "json"
            Export-ComplianceDashboard -ComplianceData $dashboardData -OutputPath $OutputPath -Format "csv"
        }
        
        # Display results
        Write-Host "📊 Compliance Monitoring Results:" -ForegroundColor Green
        Write-Host "   Overall Score: $([math]::Round($overallScore, 1))%" -ForegroundColor $(if ($overallScore -lt 50) { "Red" } elseif ($overallScore -lt 70) { "Yellow" } else { "Green" })
        Write-Host "   Structure: $([math]::Round($structureCompliance, 1))%" -ForegroundColor $(if ($structureCompliance -lt 50) { "Red" } elseif ($structureCompliance -lt 70) { "Yellow" } else { "Green" })
        Write-Host "   Content: $([math]::Round($contentCompliance, 1))%" -ForegroundColor $(if ($contentCompliance -lt 50) { "Red" } elseif ($contentCompliance -lt 70) { "Yellow" } else { "Green" })
        Write-Host "   Quality: $([math]::Round($qualityCompliance, 1))%" -ForegroundColor $(if ($qualityCompliance -lt 50) { "Red" } elseif ($qualityCompliance -lt 70) { "Yellow" } else { "Green" })
        Write-Host "   Trend: $trend" -ForegroundColor $(if ($trend -eq "declining") { "Red" } elseif ($trend -eq "improving") { "Green" } else { "Yellow" })
        Write-Host "   Alerts: $($alerts.Count)" -ForegroundColor $(if ($alerts.Count -gt 0) { "Red" } else { "Green" })
        
        if ($Continuous) {
            Write-Host "⏰ Waiting 5 minutes before next check..." -ForegroundColor Cyan
            Start-Sleep -Seconds 300
        }
        
    } while ($Continuous)
    
    Write-Host "✅ ECRR Compliance Monitoring Complete" -ForegroundColor Green
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    Start-ECRRComplianceMonitoring -ReportPath $ReportPath -OutputPath $OutputPath -ConfigPath $ConfigPath -Continuous:$Continuous -Alert:$Alert -Dashboard:$Dashboard -Threshold $Threshold
}
