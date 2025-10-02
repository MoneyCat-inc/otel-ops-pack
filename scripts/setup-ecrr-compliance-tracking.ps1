# ECRR Compliance Tracking Setup Script
# Sets up continuous ECRR compliance monitoring and tracking

param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Status,
    [switch]$Test
)

# Configuration
$Config = @{
    MonitorScript = "scripts/continuous-ecrr-compliance-monitor.ps1"
    ArtifactsPath = "artifacts"
    ComplianceThreshold = 95.0
    CheckInterval = 300  # 5 minutes
    MaxHistoryDays = 30
    TaskName = "ECRR-Compliance-Monitor"
    LogPath = "logs/ecrr-compliance-monitor.log"
}

function Write-ECRRLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Prererequisites {
    Write-ECRRLog "Checking prerequisites..." "INFO"
    
    $issues = @()
    
    # Check if monitor script exists
    if (-not (Test-Path $Config.MonitorScript)) {
        $issues += "Monitor script not found: $($Config.MonitorScript)"
    }
    
    # Check if artifacts directory exists
    if (-not (Test-Path $Config.ArtifactsPath)) {
        Write-ECRRLog "Creating artifacts directory..." "INFO"
        New-Item -ItemType Directory -Path $Config.ArtifactsPath -Force | Out-Null
    }
    
    # Check if logs directory exists
    $logsDir = Split-Path -Parent $Config.LogPath
    if (-not (Test-Path $logsDir)) {
        Write-ECRRLog "Creating logs directory..." "INFO"
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    }
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion.Major
    if ($psVersion -lt 5) {
        $issues += "PowerShell 5.0 or higher required (current: $psVersion)"
    }
    
    # Check if running as administrator (for task scheduling)
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-ECRRLog "Warning: Not running as administrator. Task scheduling may fail." "WARN"
    }
    
    if ($issues.Count -gt 0) {
        Write-ECRRLog "Prerequisite issues found:" "ERROR"
        foreach ($issue in $issues) {
            Write-ECRRLog "  • $issue" "ERROR"
        }
        return $false
    }
    
    Write-ECRRLog "All prerequisites satisfied" "SUCCESS"
    return $true
}

function Install-ComplianceTracking {
    Write-ECRRLog "Installing ECRR compliance tracking..." "INFO"
    
    if (-not (Test-Prererequisites)) {
        Write-ECRRLog "Prerequisites not met. Installation aborted." "ERROR"
        return $false
    }
    
    try {
        # Create scheduled task for continuous monitoring
        $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$((Get-Location).Path)\$($Config.MonitorScript)`" -GenerateReport"
        $taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $Config.CheckInterval) -RepetitionDuration ([TimeSpan]::MaxValue)
        $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        $taskPrincipal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType InteractiveToken
        
        Register-ScheduledTask -TaskName $Config.TaskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Principal $taskPrincipal -Force
        
        Write-ECRRLog "Scheduled task '$($Config.TaskName)' created successfully" "SUCCESS"
        
        # Create configuration file
        $configPath = Join-Path $Config.ArtifactsPath "ecrr-compliance-config.json"
        $Config | ConvertTo-Json -Depth 3 | Out-File -FilePath $configPath -Encoding UTF8
        
        Write-ECRRLog "Configuration saved to: $configPath" "SUCCESS"
        
        # Create initial compliance report
        Write-ECRRLog "Generating initial compliance report..." "INFO"
        & $Config.MonitorScript -GenerateReport -OutputPath (Join-Path $Config.ArtifactsPath "ecrr-compliance-initial.json")
        
        # Create monitoring dashboard HTML
        Create-ComplianceDashboard
        
        Write-ECRRLog "ECRR compliance tracking installed successfully" "SUCCESS"
        return $true
        
    } catch {
        Write-ECRRLog "Installation failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Uninstall-ComplianceTracking {
    Write-ECRRLog "Uninstalling ECRR compliance tracking..." "INFO"
    
    try {
        # Remove scheduled task
        if (Get-ScheduledTask -TaskName $Config.TaskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $Config.TaskName -Confirm:$false
            Write-ECRRLog "Scheduled task '$($Config.TaskName)' removed" "SUCCESS"
        }
        
        # Remove configuration file
        $configPath = Join-Path $Config.ArtifactsPath "ecrr-compliance-config.json"
        if (Test-Path $configPath) {
            Remove-Item -Path $configPath -Force
            Write-ECRRLog "Configuration file removed" "SUCCESS"
        }
        
        Write-ECRRLog "ECRR compliance tracking uninstalled successfully" "SUCCESS"
        return $true
        
    } catch {
        Write-ECRRLog "Uninstall failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Get-ComplianceStatus {
    Write-ECRRLog "Checking ECRR compliance tracking status..." "INFO"
    
    # Check scheduled task
    $task = Get-ScheduledTask -TaskName $Config.TaskName -ErrorAction SilentlyContinue
    if ($task) {
        $taskState = $task.State
        $lastRun = (Get-ScheduledTaskInfo -TaskName $Config.TaskName).LastRunTime
        Write-ECRRLog "Scheduled task: $taskState (Last run: $lastRun)" "INFO"
    } else {
        Write-ECRRLog "Scheduled task not found" "WARN"
    }
    
    # Check configuration
    $configPath = Join-Path $Config.ArtifactsPath "ecrr-compliance-config.json"
    if (Test-Path $configPath) {
        Write-ECRRLog "Configuration file exists: $configPath" "SUCCESS"
    } else {
        Write-ECRRLog "Configuration file not found" "WARN"
    }
    
    # Check recent reports
    $reports = Get-ChildItem -Path $Config.ArtifactsPath -Filter "ecrr-compliance-*.json" | Sort-Object LastWriteTime -Descending
    if ($reports.Count -gt 0) {
        $latestReport = $reports[0]
        $reportAge = (Get-Date) - $latestReport.LastWriteTime
        Write-ECRRLog "Latest compliance report: $($latestReport.Name) (Age: $([math]::Round($reportAge.TotalMinutes, 1)) minutes)" "INFO"
        
        # Show compliance rate from latest report
        try {
            $reportData = Get-Content -Path $latestReport.FullName -Raw | ConvertFrom-Json
            Write-ECRRLog "Current compliance rate: $($reportData.ComplianceRate)%" "SUCCESS"
            Write-ECRRLog "Health status: $($reportData.HealthStatus)" "SUCCESS"
        } catch {
            Write-ECRRLog "Could not parse latest compliance report" "WARN"
        }
    } else {
        Write-ECRRLog "No compliance reports found" "WARN"
    }
    
    # Check monitor script
    if (Test-Path $Config.MonitorScript) {
        Write-ECRRLog "Monitor script exists: $($Config.MonitorScript)" "SUCCESS"
    } else {
        Write-ECRRLog "Monitor script not found: $($Config.MonitorScript)" "ERROR"
    }
}

function Test-ComplianceTracking {
    Write-ECRRLog "Testing ECRR compliance tracking..." "INFO"
    
    if (-not (Test-Path $Config.MonitorScript)) {
        Write-ECRRLog "Monitor script not found: $($Config.MonitorScript)" "ERROR"
        return $false
    }
    
    try {
        # Run monitor script in test mode
        Write-ECRRLog "Running compliance analysis..." "INFO"
        $complianceRate = & $Config.MonitorScript -Verbose -GenerateReport
        
        if ($LASTEXITCODE -eq 0) {
            Write-ECRRLog "Compliance analysis successful. Rate: $complianceRate%" "SUCCESS"
            
            # Check if report was generated
            $reports = Get-ChildItem -Path $Config.ArtifactsPath -Filter "ecrr-compliance-*.json" | Sort-Object LastWriteTime -Descending
            if ($reports.Count -gt 0) {
                $latestReport = $reports[0]
                Write-ECRRLog "Compliance report generated: $($latestReport.Name)" "SUCCESS"
                
                # Show report summary
                try {
                    $reportData = Get-Content -Path $latestReport.FullName -Raw | ConvertFrom-Json
                    Write-ECRRLog "Total reports analyzed: $($reportData.TotalReports)" "INFO"
                    Write-ECRRLog "Compliant reports: $($reportData.CompliantReports)" "INFO"
                    Write-ECRRLog "Compliance rate: $($reportData.ComplianceRate)%" "INFO"
                    Write-ECRRLog "Health status: $($reportData.HealthStatus)" "INFO"
                    
                    if ($reportData.NonCompliantReports.Count -gt 0) {
                        Write-ECRRLog "Non-compliant reports: $($reportData.NonCompliantReports.Count)" "WARN"
                    }
                    
                    return $true
                } catch {
                    Write-ECRRLog "Could not parse compliance report" "ERROR"
                    return $false
                }
            } else {
                Write-ECRRLog "No compliance report generated" "ERROR"
                return $false
            }
        } else {
            Write-ECRRLog "Compliance analysis failed" "ERROR"
            return $false
        }
        
    } catch {
        Write-ECRRLog "Test failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Create-ComplianceDashboard {
    Write-ECRRLog "Creating compliance dashboard..." "INFO"
    
    $dashboardPath = Join-Path $Config.ArtifactsPath "ecrr-compliance-dashboard.html"
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ECRR Compliance Dashboard</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; color: #333; border-bottom: 2px solid #007acc; padding-bottom: 20px; margin-bottom: 30px; }
        .metric-card { background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 6px; padding: 20px; margin: 10px 0; }
        .metric-value { font-size: 2em; font-weight: bold; color: #007acc; }
        .metric-label { color: #666; font-size: 0.9em; }
        .status-healthy { color: #28a745; }
        .status-warning { color: #ffc107; }
        .status-critical { color: #dc3545; }
        .chart-container { margin: 20px 0; }
        .recommendations { background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 6px; padding: 15px; margin: 20px 0; }
        .footer { text-align: center; color: #666; margin-top: 30px; font-size: 0.9em; }
        .refresh-btn { background: #007acc; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; }
        .refresh-btn:hover { background: #0056b3; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 ECRR Compliance Dashboard</h1>
            <p>Real-time monitoring of ECRR report compliance</p>
            <button class="refresh-btn" onclick="location.reload()">🔄 Refresh</button>
        </div>
        
        <div class="metric-card">
            <div class="metric-value" id="compliance-rate">--</div>
            <div class="metric-label">Overall Compliance Rate</div>
        </div>
        
        <div class="metric-card">
            <div class="metric-value" id="health-status">--</div>
            <div class="metric-label">Health Status</div>
        </div>
        
        <div class="chart-container">
            <h3>📊 Compliance Breakdown</h3>
            <div id="compliance-breakdown">Loading...</div>
        </div>
        
        <div class="chart-container">
            <h3>🤖 Agent Distribution</h3>
            <div id="agent-distribution">Loading...</div>
        </div>
        
        <div class="chart-container">
            <h3>📁 Report Categories</h3>
            <div id="report-categories">Loading...</div>
        </div>
        
        <div class="recommendations">
            <h3>💡 Recommendations</h3>
            <div id="recommendations">Loading...</div>
        </div>
        
        <div class="footer">
            <p>Last updated: <span id="last-updated">--</span></p>
            <p>ECRR Compliance Dashboard | Generated by ECRR Compliance Monitor</p>
        </div>
    </div>
    
    <script>
        // Load and display compliance data
        async function loadComplianceData() {
            try {
                // Try to load the latest compliance report
                const response = await fetch('./ecrr-compliance-monitor.json');
                if (!response.ok) {
                    throw new Error('Compliance report not found');
                }
                
                const data = await response.json();
                
                // Update main metrics
                document.getElementById('compliance-rate').textContent = data.ComplianceRate + '%';
                document.getElementById('compliance-rate').className = 'metric-value ' + getStatusClass(data.HealthStatus);
                
                document.getElementById('health-status').textContent = data.HealthStatus;
                document.getElementById('health-status').className = 'metric-value ' + getStatusClass(data.HealthStatus);
                
                // Update compliance breakdown
                const breakdown = data.ComplianceBreakdown;
                let breakdownHtml = '<ul>';
                for (const [criterion, metrics] of Object.entries(breakdown)) {
                    const statusClass = metrics.Rate >= 95 ? 'status-healthy' : metrics.Rate >= 80 ? 'status-warning' : 'status-critical';
                    breakdownHtml += \`<li><strong>\${criterion}</strong>: <span class="\${statusClass}">\${metrics.Rate}%</span> (\${metrics.Compliant}/\${metrics.Total})</li>\`;
                }
                breakdownHtml += '</ul>';
                document.getElementById('compliance-breakdown').innerHTML = breakdownHtml;
                
                // Update agent distribution
                const agents = data.AgentDistribution;
                let agentHtml = '<ul>';
                for (const [agent, count] of Object.entries(agents)) {
                    const percentage = ((count / data.TotalReports) * 100).toFixed(1);
                    agentHtml += \`<li><strong>\${agent}</strong>: \${count} reports (\${percentage}%)</li>\`;
                }
                agentHtml += '</ul>';
                document.getElementById('agent-distribution').innerHTML = agentHtml;
                
                // Update report categories
                const categories = data.ReportCategories;
                let categoryHtml = '<ul>';
                for (const [category, count] of Object.entries(categories)) {
                    const percentage = ((count / data.TotalReports) * 100).toFixed(1);
                    categoryHtml += \`<li><strong>\${category}</strong>: \${count} reports (\${percentage}%)</li>\`;
                }
                categoryHtml += '</ul>';
                document.getElementById('report-categories').innerHTML = categoryHtml;
                
                // Update recommendations
                const recommendations = data.Recommendations;
                let recHtml = '<ul>';
                for (const rec of recommendations) {
                    recHtml += \`<li>\${rec}</li>\`;
                }
                recHtml += '</ul>';
                document.getElementById('recommendations').innerHTML = recHtml;
                
                // Update timestamp
                document.getElementById('last-updated').textContent = new Date(data.Timestamp).toLocaleString();
                
            } catch (error) {
                console.error('Error loading compliance data:', error);
                document.getElementById('compliance-breakdown').innerHTML = '<p style="color: red;">Error loading compliance data</p>';
            }
        }
        
        function getStatusClass(status) {
            switch (status) {
                case 'HEALTHY': return 'status-healthy';
                case 'WARNING': return 'status-warning';
                case 'CRITICAL': return 'status-critical';
                default: return '';
            }
        }
        
        // Load data on page load
        loadComplianceData();
        
        // Auto-refresh every 5 minutes
        setInterval(loadComplianceData, 5 * 60 * 1000);
    </script>
</body>
</html>
"@
    
    $html | Out-File -FilePath $dashboardPath -Encoding UTF8
    Write-ECRRLog "Compliance dashboard created: $dashboardPath" "SUCCESS"
}

# Main execution
try {
    if ($Install) {
        $success = Install-ComplianceTracking
        if ($success) {
            Write-ECRRLog "Installation completed successfully" "SUCCESS"
            Write-ECRRLog "Run 'Get-ComplianceStatus' to check status" "INFO"
            Write-ECRRLog "Run 'Test-ComplianceTracking' to test the system" "INFO"
        } else {
            Write-ECRRLog "Installation failed" "ERROR"
            exit 1
        }
    }
    elseif ($Uninstall) {
        $success = Uninstall-ComplianceTracking
        if ($success) {
            Write-ECRRLog "Uninstall completed successfully" "SUCCESS"
        } else {
            Write-ECRRLog "Uninstall failed" "ERROR"
            exit 1
        }
    }
    elseif ($Status) {
        Get-ComplianceStatus
    }
    elseif ($Test) {
        $success = Test-ComplianceTracking
        if ($success) {
            Write-ECRRLog "Test completed successfully" "SUCCESS"
        } else {
            Write-ECRRLog "Test failed" "ERROR"
            exit 1
        }
    }
    else {
        Write-Host "ECRR Compliance Tracking Setup" -ForegroundColor Cyan
        Write-Host "Usage: $($MyInvocation.MyCommand.Name) [-Install] [-Uninstall] [-Status] [-Test]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Options:" -ForegroundColor Cyan
        Write-Host "  -Install     Install continuous ECRR compliance tracking" -ForegroundColor White
        Write-Host "  -Uninstall   Remove ECRR compliance tracking" -ForegroundColor White
        Write-Host "  -Status      Show current status of compliance tracking" -ForegroundColor White
        Write-Host "  -Test        Test the compliance monitoring system" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Cyan
        Write-Host "  $($MyInvocation.MyCommand.Name) -Install    # Install tracking" -ForegroundColor White
        Write-Host "  $($MyInvocation.MyCommand.Name) -Status     # Check status" -ForegroundColor White
        Write-Host "  $($MyInvocation.MyCommand.Name) -Test       # Test system" -ForegroundColor White
    }
    
} catch {
    Write-ECRRLog "Setup script failed: $($_.Exception.Message)" "ERROR"
    exit 1
}
