# See C:\otel\docs\comfort cat
# Weekly OTel Pipeline Report Generator
# Aggregates monitoring data and generates comprehensive weekly reports

param(
    [int]$DaysBack = 7,
    [switch]$IncludeCharts = $false,
    [string]$OutputPath = "artifacts\weekly-report-$(Get-Date -Format 'yyyyMMdd').json"
)

Write-Host "📊 Weekly OTel Pipeline Report Generator" -ForegroundColor Cyan
Write-Host "Generating report for last $DaysBack days" -ForegroundColor Gray
Write-Host ""

$startTime = Get-Date
$reportData = @{
    ReportInfo = @{
        GeneratedAt = $startTime
        PeriodDays = $DaysBack
        GeneratedBy = "OTel Weekly Report Generator"
    }
    Summary = @{}
    HealthTrends = @{}
    CanaryActivity = @{}
    Alerts = @{}
    Recommendations = @()
}

# Create artifacts directory if it doesn't exist
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

# Collect monitoring reports from artifacts
Write-Host "📁 Collecting monitoring artifacts..." -ForegroundColor Yellow
$monitoringReports = Get-ChildItem -Path "artifacts" -Filter "monitoring-report-*.json" | 
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-$DaysBack) } |
    Sort-Object LastWriteTime -Descending

$quickMonitorReports = Get-ChildItem -Path "artifacts" -Filter "quick-monitor-*.json" | 
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-$DaysBack) } |
    Sort-Object LastWriteTime -Descending

$canaryReports = Get-ChildItem -Path "artifacts" -Filter "canary-ecrr-report.txt" | 
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-$DaysBack) } |
    Sort-Object LastWriteTime -Descending

Write-Host "   Found $($monitoringReports.Count) detailed monitoring reports" -ForegroundColor White
Write-Host "   Found $($quickMonitorReports.Count) quick monitor reports" -ForegroundColor White
Write-Host "   Found $($canaryReports.Count) canary reports" -ForegroundColor White

# Analyze health trends
Write-Host ""
Write-Host "📈 Analyzing health trends..." -ForegroundColor Yellow
$healthTrends = @{
    TotalChecks = 0
    HealthyChecks = 0
    DegradedChecks = 0
    FailedChecks = 0
    AverageResponseTime = 0
    Components = @{
        SigNoz = @{ Healthy = 0; Degraded = 0; Failed = 0 }
        WindowsCollector = @{ Healthy = 0; Degraded = 0; Failed = 0 }
        DockerServices = @{ Healthy = 0; Degraded = 0; Failed = 0 }
        OTLP_GRPC = @{ Accessible = 0; Unreachable = 0 }
        OTLP_HTTP = @{ Accessible = 0; Unreachable = 0 }
    }
}

foreach ($report in $monitoringReports) {
    try {
        $data = Get-Content $report.FullName | ConvertFrom-Json
        if ($data.MonitoringData) {
            foreach ($check in $data.MonitoringData.Checks) {
                $healthTrends.TotalChecks++
                foreach ($component in $check.Checks) {
                    switch ($component.Status) {
                        "Healthy" { 
                            $healthTrends.Components.$($component.Component).Healthy++
                            $healthTrends.HealthyChecks++
                        }
                        "Running" { 
                            $healthTrends.Components.$($component.Component).Healthy++
                            $healthTrends.HealthyChecks++
                        }
                        "Unreachable" { 
                            $healthTrends.Components.$($component.Component).Failed++
                            $healthTrends.FailedChecks++
                        }
                        default { 
                            $healthTrends.Components.$($component.Component).Degraded++
                            $healthTrends.DegradedChecks++
                        }
                    }
                }
            }
            
            # Analyze OTLP endpoint availability
            foreach ($metric in $data.MonitoringData.Metrics) {
                if ($metric.Data.OTLP_GRPC_14317 -eq $true) {
                    $healthTrends.Components.OTLP_GRPC.Accessible++
                } else {
                    $healthTrends.Components.OTLP_GRPC.Unreachable++
                }
                
                if ($metric.Data.OTLP_HTTP_14318 -eq $true) {
                    $healthTrends.Components.OTLP_HTTP.Accessible++
                } else {
                    $healthTrends.Components.OTLP_HTTP.Unreachable++
                }
            }
        }
    } catch {
        Write-Host "   ⚠️  Could not parse report: $($report.Name)" -ForegroundColor Yellow
    }
}

$reportData.HealthTrends = $healthTrends

# Calculate health percentage
$healthPercentage = if ($healthTrends.TotalChecks -gt 0) { 
    [math]::Round(($healthTrends.HealthyChecks / $healthTrends.TotalChecks) * 100, 2) 
} else { 0 }

# Analyze canary activity
Write-Host "🧪 Analyzing canary activity..." -ForegroundColor Yellow
$canaryActivity = @{
    TotalRuns = 0
    SuccessfulRuns = 0
    FailedRuns = 0
    AverageExecutionTime = 0
    Issues = @()
    Warnings = @()
}

foreach ($canaryReport in $canaryReports) {
    try {
        $content = Get-Content $canaryReport.FullName -Raw
        $canaryActivity.TotalRuns++
        
        if ($content -match "ECRR Canary Test completed successfully") {
            $canaryActivity.SuccessfulRuns++
        } else {
            $canaryActivity.FailedRuns++
        }
        
        # Extract issues and warnings
        $issues = [regex]::Matches($content, "\[FAIL\] (.+)") | ForEach-Object { $_.Groups[1].Value }
        $warnings = [regex]::Matches($content, "\[WARN\] (.+)") | ForEach-Object { $_.Groups[1].Value }
        
        $canaryActivity.Issues += $issues
        $canaryActivity.Warnings += $warnings
    } catch {
        Write-Host "   ⚠️  Could not parse canary report: $($canaryReport.Name)" -ForegroundColor Yellow
    }
}

$reportData.CanaryActivity = $canaryActivity

# Analyze alerts
Write-Host "🚨 Analyzing alerts..." -ForegroundColor Yellow
$alerts = @{
    TotalAlerts = 0
    CriticalAlerts = 0
    WarningAlerts = 0
    InfoAlerts = 0
    AlertTypes = @{}
}

foreach ($report in $monitoringReports) {
    try {
        $data = Get-Content $report.FullName | ConvertFrom-Json
        if ($data.MonitoringData -and $data.MonitoringData.Alerts) {
            foreach ($alert in $data.MonitoringData.Alerts) {
                $alerts.TotalAlerts++
                switch ($alert.Severity) {
                    "High" { $alerts.CriticalAlerts++ }
                    "Medium" { $alerts.WarningAlerts++ }
                    "Low" { $alerts.InfoAlerts++ }
                }
                
                if (-not $alerts.AlertTypes.ContainsKey($alert.Type)) {
                    $alerts.AlertTypes[$alert.Type] = 0
                }
                $alerts.AlertTypes[$alert.Type]++
            }
        }
    } catch {
        Write-Host "   ⚠️  Could not parse alerts from: $($report.Name)" -ForegroundColor Yellow
    }
}

$reportData.Alerts = $alerts

# Generate recommendations
Write-Host "💡 Generating recommendations..." -ForegroundColor Yellow
$recommendations = @()

if ($healthPercentage -lt 95) {
    $recommendations += "Health percentage is below 95% ($healthPercentage%). Consider investigating component failures."
}

if ($healthTrends.Components.OTLP_GRPC.Unreachable -gt 0) {
    $recommendations += "OTLP gRPC endpoint has unreachable instances. Check Docker port mapping and collector configuration."
}

if ($healthTrends.Components.OTLP_HTTP.Unreachable -gt 0) {
    $recommendations += "OTLP HTTP endpoint has unreachable instances. Verify collector HTTP receiver configuration."
}

if ($canaryActivity.FailedRuns -gt 0) {
    $recommendations += "Some canary tests failed. Review canary test logs and fix identified issues."
}

if ($alerts.CriticalAlerts -gt 0) {
    $recommendations += "Critical alerts detected. Review alert conditions and take corrective action."
}

if ($recommendations.Count -eq 0) {
    $recommendations += "System is performing well. Continue current monitoring practices."
}

$reportData.Recommendations = $recommendations

# Generate summary
$reportData.Summary = @{
    OverallHealth = $healthPercentage
    MonitoringReports = $monitoringReports.Count
    CanaryRuns = $canaryActivity.TotalRuns
    CanarySuccessRate = if ($canaryActivity.TotalRuns -gt 0) { [math]::Round(($canaryActivity.SuccessfulRuns / $canaryActivity.TotalRuns) * 100, 2) } else { 0 }
    TotalAlerts = $alerts.TotalAlerts
    CriticalIssues = $alerts.CriticalAlerts
    Recommendations = $recommendations.Count
}

# Export report
Write-Host ""
Write-Host "📄 Exporting report..." -ForegroundColor Yellow
$reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host ""
Write-Host "✅ Weekly Report Generated" -ForegroundColor Green
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   Overall Health: $healthPercentage%" -ForegroundColor White
Write-Host "   Monitoring Reports: $($monitoringReports.Count)" -ForegroundColor White
Write-Host "   Canary Success Rate: $($reportData.Summary.CanarySuccessRate)%" -ForegroundColor White
Write-Host "   Total Alerts: $($alerts.TotalAlerts)" -ForegroundColor White
Write-Host "   Critical Issues: $($alerts.CriticalAlerts)" -ForegroundColor White
Write-Host "   Recommendations: $($recommendations.Count)" -ForegroundColor White

Write-Host ""
Write-Host "📁 Report saved to: $OutputPath" -ForegroundColor Green
Write-Host "⏱️  Generation time: $((Get-Date) - $startTime)" -ForegroundColor Gray

# Display key recommendations
if ($recommendations.Count -gt 0) {
    Write-Host ""
    Write-Host "💡 Key Recommendations:" -ForegroundColor Blue
    foreach ($rec in $recommendations[0..2]) {  # Show top 3
        Write-Host "   • $rec" -ForegroundColor Gray
    }
    if ($recommendations.Count -gt 3) {
        Write-Host "   • ... and $($recommendations.Count - 3) more (see full report)" -ForegroundColor Gray
    }
}
