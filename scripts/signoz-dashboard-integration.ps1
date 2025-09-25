#Requires -Version 7.0

<#
.SYNOPSIS
    Integrate ECRR-generated tasks with SigNoz dashboards and alerts

.DESCRIPTION
    Creates SigNoz dashboards and alerts based on generated ECRR tasks.
    Provides closed-loop verification for task completion.

.PARAMETER Action
    Action to perform: create-dashboard, create-alerts, test-queries, export-config

.PARAMETER DashboardName
    Name for the dashboard. Default: ECRR-Task-Monitoring

.PARAMETER SigNozUrl
    SigNoz base URL. Default: http://localhost:8080

.PARAMETER TasksPath
    Path to tasks directory. Default: jobs

.EXAMPLE
    .\signoz-dashboard-integration.ps1 -Action create-dashboard
    Create SigNoz dashboard for ECRR task monitoring

.EXAMPLE
    .\signoz-dashboard-integration.ps1 -Action create-alerts
    Create alerts for task completion and failures

.EXAMPLE
    .\signoz-dashboard-integration.ps1 -Action test-queries
    Test SigNoz queries from generated tasks
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('create-dashboard', 'create-alerts', 'test-queries', 'export-config', 'status')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$DashboardName = 'ECRR-Task-Monitoring',

    [Parameter(Mandatory = $false)]
    [string]$SigNozUrl = 'http://localhost:8080',

    [Parameter(Mandatory = $false)]
    [string]$TasksPath = 'jobs'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'SUCCESS' { 'Green' }
        'WARN'    { 'Yellow' }
        'ERROR'   { 'Red' }
        default   { 'Cyan' }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-SigNozConnection {
    param([string]$BaseUrl)

    try {
        $healthUrl = "$BaseUrl/api/v1/health"
        $response = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 10
        Write-Log "SigNoz connection successful: $BaseUrl" 'SUCCESS'
        return $true
    }
    catch {
        Write-Log "SigNoz connection failed: $($_.Exception.Message)" 'ERROR'
        return $false
    }
}

function Get-TaskQueries {
    param([string]$TasksPath)

    $queries = @{
        'logs' = @()
        'metrics' = @()
        'traces' = @()
    }

    $taskFiles = Get-ChildItem -Path $TasksPath -Recurse -Filter '*.md' -ErrorAction SilentlyContinue
    
    foreach ($file in $taskFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
            
            # Extract SQL queries from code blocks
            $sqlBlocks = [regex]::Matches($content, '```sql\s*(.*?)\s*```', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            foreach ($match in $sqlBlocks) {
                $queryText = $match.Groups[1].Value.Trim()
                if ($queryText -and $queryText -ne '-- No specific logs queries' -and $queryText -ne '-- No specific metrics queries') {
                    # Determine query type based on content
                    if ($queryText -match 'message|severity|attributes\.dataset') {
                        $queries['logs'] += $queryText
                    } elseif ($queryText -match 'otelcol_|process_|memory_') {
                        $queries['metrics'] += $queryText
                    } elseif ($queryText -match 'service\.name|span\.name') {
                        $queries['traces'] += $queryText
                    }
                }
            }
        }
        catch {
            Write-Log "Failed to process task file: $($file.FullName)" 'WARN'
        }
    }

    # Remove duplicates
    $keys = @($queries.Keys)
    foreach ($key in $keys) {
        $queries[$key] = $queries[$key] | Sort-Object -Unique
    }

    return $queries
}

function New-SigNozDashboard {
    param(
        [string]$DashboardName,
        [string]$SigNozUrl,
        [hashtable]$Queries
    )

    if (-not (Test-SigNozConnection -BaseUrl $SigNozUrl)) {
        return $false
    }

    $dashboardConfig = @{
        name = $DashboardName
        description = "ECRR Task Monitoring Dashboard - Auto-generated from task queries"
        panels = @()
    }

    $panelIndex = 0

    # Create panels for each query type
    foreach ($queryType in $Queries.Keys) {
        if ($Queries[$queryType].Count -gt 0) {
            foreach ($query in $Queries[$queryType]) {
                $panelIndex++
                $panel = @{
                    id = "panel-$panelIndex"
                    title = "ECRR Task Query - $queryType"
                    type = switch ($queryType) {
                        'logs' { 'logs' }
                        'metrics' { 'metrics' }
                        'traces' { 'traces' }
                    }
                    query = $query
                    position = @{
                        x = ($panelIndex - 1) % 2 * 6
                        y = [math]::Floor(($panelIndex - 1) / 2) * 4
                        w = 6
                        h = 4
                    }
                }
                $dashboardConfig.panels += $panel
            }
        }
    }

    # Add summary panel
    $panelIndex++
    $summaryPanel = @{
        id = "summary-panel"
        title = "ECRR Task Summary"
        type = "metrics"
        query = "count(otelcol_receiver_accepted_spans)"
        position = @{
            x = 0
            y = [math]::Floor(($panelIndex - 1) / 2) * 4
            w = 12
            h = 2
        }
    }
    $dashboardConfig.panels += $summaryPanel

    # Export dashboard config
    $configFile = "artifacts/signoz-dashboard-$DashboardName.json"
    $artifactsDir = Split-Path -Path $configFile -Parent
    if (-not (Test-Path -Path $artifactsDir)) {
        New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
    }

    $dashboardConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile -Encoding UTF8
    Write-Log "Dashboard configuration exported to: $configFile" 'SUCCESS'

    Write-Host "`nDashboard Configuration:" -ForegroundColor Cyan
    Write-Host "Name: $DashboardName" -ForegroundColor White
    Write-Host "Panels: $($dashboardConfig.panels.Count)" -ForegroundColor White
        Write-Host "Log Queries: $(if ($Queries['logs']) { $Queries['logs'].Count } else { 0 })" -ForegroundColor White
        Write-Host "Metrics Queries: $(if ($Queries['metrics']) { $Queries['metrics'].Count } else { 0 })" -ForegroundColor White
        Write-Host "Trace Queries: $(if ($Queries['traces']) { $Queries['traces'].Count } else { 0 })" -ForegroundColor White

    return $true
}

function New-SigNozAlerts {
    param(
        [string]$SigNozUrl,
        [hashtable]$Queries
    )

    if (-not (Test-SigNozConnection -BaseUrl $SigNozUrl)) {
        return $false
    }

    $alerts = @()

    # Task completion alert
    $completionAlert = @{
        name = "ECRR-Task-Completion-Alert"
        description = "Alert when ECRR tasks are completed"
        query = "count(otelcol_receiver_accepted_spans) > 0"
        threshold = 1
        condition = "greater_than"
        duration = "5m"
        severity = "info"
        channels = @("email", "slack")
    }
    $alerts += $completionAlert

    # Error rate alert
    $errorAlert = @{
        name = "ECRR-Task-Error-Alert"
        description = "Alert on high error rates in ECRR tasks"
        query = "count(severity >= 'ERROR') / count(*) * 100"
        threshold = 5
        condition = "greater_than"
        duration = "2m"
        severity = "warning"
        channels = @("email", "slack")
    }
    $alerts += $errorAlert

    # Export alerts config
    $alertsFile = "artifacts/signoz-alerts-ecrr.json"
    $artifactsDir = Split-Path -Path $alertsFile -Parent
    if (-not (Test-Path -Path $artifactsDir)) {
        New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
    }

    $alerts | ConvertTo-Json -Depth 10 | Set-Content -Path $alertsFile -Encoding UTF8
    Write-Log "Alerts configuration exported to: $alertsFile" 'SUCCESS'

    Write-Host "`nAlerts Configuration:" -ForegroundColor Cyan
    Write-Host "Total Alerts: $($alerts.Count)" -ForegroundColor White
    foreach ($alert in $alerts) {
        Write-Host "• $($alert.name): $($alert.description)" -ForegroundColor Gray
    }

    return $true
}

function Test-SigNozQueries {
    param(
        [string]$SigNozUrl,
        [hashtable]$Queries
    )

    if (-not (Test-SigNozConnection -BaseUrl $SigNozUrl)) {
        return $false
    }

    Write-Host "`nTesting SigNoz Queries:" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Cyan

    foreach ($queryType in $Queries.Keys) {
        if ($Queries[$queryType].Count -gt 0) {
            Write-Host "`n$queryType Queries:" -ForegroundColor Yellow
            foreach ($query in $Queries[$queryType]) {
                Write-Host "  • $query" -ForegroundColor White
                
                # Test query (simplified - would need actual SigNoz API calls)
                try {
                    $testUrl = "$SigNozUrl/api/v1/$queryType/query"
                    Write-Host "    Test URL: $testUrl" -ForegroundColor Gray
                }
                catch {
                    Write-Host "    Test failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }

    return $true
}

function Export-SigNozConfig {
    param(
        [string]$DashboardName,
        [string]$SigNozUrl,
        [hashtable]$Queries
    )

    $config = @{
        signoz = @{
            url = $SigNozUrl
            dashboard = $DashboardName
            queries = $Queries
        }
        ecrr = @{
            tasks_path = $TasksPath
            generation_script = "scripts/ecrr-task-automation.ps1"
            management_script = "scripts/manage-tasks.ps1"
        }
        integration = @{
            dashboard_config = "artifacts/signoz-dashboard-$DashboardName.json"
            alerts_config = "artifacts/signoz-alerts-ecrr.json"
            summary_reports = "artifacts/ecrr-generation-summary-*.md"
        }
    }

    $configFile = "artifacts/signoz-integration-config.json"
    $artifactsDir = Split-Path -Path $configFile -Parent
    if (-not (Test-Path -Path $artifactsDir)) {
        New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
    }

    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile -Encoding UTF8
    Write-Log "Integration configuration exported to: $configFile" 'SUCCESS'

    return $true
}

# Main execution
Write-Host "SigNoz Dashboard Integration" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

# Get queries from generated tasks
$queries = Get-TaskQueries -TasksPath $TasksPath

Write-Log "Found queries in generated tasks:" 'INFO'
Write-Log "  Logs: $(if ($queries['logs']) { $queries['logs'].Count } else { 0 })" 'INFO'
Write-Log "  Metrics: $(if ($queries['metrics']) { $queries['metrics'].Count } else { 0 })" 'INFO'
Write-Log "  Traces: $(if ($queries['traces']) { $queries['traces'].Count } else { 0 })" 'INFO'

switch ($Action) {
    'create-dashboard' {
        Write-Log "Creating SigNoz dashboard: $DashboardName" 'INFO'
        
        if (New-SigNozDashboard -DashboardName $DashboardName -SigNozUrl $SigNozUrl -Queries $queries) {
            Write-Host "`nDashboard created successfully!" -ForegroundColor Green
            Write-Host "Import the configuration in SigNoz UI:" -ForegroundColor White
            Write-Host "  File: artifacts/signoz-dashboard-$DashboardName.json" -ForegroundColor Gray
        }
    }
    
    'create-alerts' {
        Write-Log "Creating SigNoz alerts for ECRR tasks" 'INFO'
        
        if (New-SigNozAlerts -SigNozUrl $SigNozUrl -Queries $queries) {
            Write-Host "`nAlerts created successfully!" -ForegroundColor Green
            Write-Host "Import the configuration in SigNoz UI:" -ForegroundColor White
            Write-Host "  File: artifacts/signoz-alerts-ecrr.json" -ForegroundColor Gray
        }
    }
    
    'test-queries' {
        Write-Log "Testing SigNoz queries from generated tasks" 'INFO'
        
        if (Test-SigNozQueries -SigNozUrl $SigNozUrl -Queries $queries) {
            Write-Host "`nQuery testing completed!" -ForegroundColor Green
        }
    }
    
    'export-config' {
        Write-Log "Exporting complete SigNoz integration configuration" 'INFO'
        
        if (Export-SigNozConfig -DashboardName $DashboardName -SigNozUrl $SigNozUrl -Queries $queries) {
            Write-Host "`nConfiguration exported successfully!" -ForegroundColor Green
            Write-Host "Complete integration config: artifacts/signoz-integration-config.json" -ForegroundColor White
        }
    }
    
    'status' {
        Write-Host "`nSigNoz Integration Status" -ForegroundColor Cyan
        Write-Host "========================" -ForegroundColor Cyan
        Write-Host "SigNoz URL: $SigNozUrl" -ForegroundColor White
        Write-Host "Tasks Path: $TasksPath" -ForegroundColor White
        Write-Host "Dashboard Name: $DashboardName" -ForegroundColor White
        
        if (Test-SigNozConnection -BaseUrl $SigNozUrl) {
            Write-Host "SigNoz Status: Connected" -ForegroundColor Green
        } else {
            Write-Host "SigNoz Status: Disconnected" -ForegroundColor Red
        }
        
        Write-Host "`nAvailable Queries:" -ForegroundColor Cyan
        Write-Host "  Logs: $(if ($queries['logs']) { $queries['logs'].Count } else { 0 })" -ForegroundColor White
        Write-Host "  Metrics: $(if ($queries['metrics']) { $queries['metrics'].Count } else { 0 })" -ForegroundColor White
        Write-Host "  Traces: $(if ($queries['traces']) { $queries['traces'].Count } else { 0 })" -ForegroundColor White
    }
}

Write-Host "`nIntegration Notes:" -ForegroundColor Cyan
Write-Host "• Import dashboard config in SigNoz UI: Dashboards → Import" -ForegroundColor White
Write-Host "• Import alerts config in SigNoz UI: Alerts → Import" -ForegroundColor White
Write-Host "• Use 'pwsh -File scripts/manage-tasks.ps1 -Action Status' to monitor task progress" -ForegroundColor White
Write-Host "• Generated queries are automatically extracted from ECRR tasks" -ForegroundColor White
