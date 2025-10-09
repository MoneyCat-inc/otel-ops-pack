# See C:\otel\docs\comfort cat
# Quick Monitor - Fast Pipeline Health Check
# Lightweight version of the enhanced monitor for quick status checks
# Updated with progress indicators for better user experience

param(
    [switch]$ExportReport = $false,
    [switch]$PreflightCheck = $false,
    [string]$ReportPath = "artifacts\quick-monitor-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

# Import progress indicators module
. .\BRAV\SCPT\progress-indicators.ps1

Write-Host "⚡ Quick Pipeline Monitor" -ForegroundColor Cyan
Write-Host "Fast health check with ECRR reporting" -ForegroundColor Gray
if ($PreflightCheck) {
    Write-Host "🔍 Including preflight OTLP endpoint checks" -ForegroundColor Yellow
}
Write-Host ""

$startTime = Get-Date
$checks = @()

# Quick health checks
function Test-QuickHealth {
    $results = @{}
    
    # SigNoz health
    $spinnerJob = Start-SpinnerJob -Message "Checking SigNoz health..." -UpdateIntervalMs 150
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 3
        Stop-SpinnerJob -Job $spinnerJob
        $results.SigNoz = @{ Status = "Healthy"; Color = "Green" }
    }
    catch {
        Stop-SpinnerJob -Job $spinnerJob
        $results.SigNoz = @{ Status = "Unreachable"; Color = "Red"; Error = $_.Exception.Message }
    }
    
    # Windows Collector
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        $results.WindowsCollector = @{ Status = "Running"; Color = "Green" }
    } else {
        $results.WindowsCollector = @{ Status = "Not Running"; Color = "Red" }
    }
    
    # Docker services
    $spinnerJob = Start-SpinnerJob -Message "Checking Docker services..." -UpdateIntervalMs 150
    try {
        $dockerPs = docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String "signoz"
        Stop-SpinnerJob -Job $spinnerJob
        if ($dockerPs) {
            $results.Docker = @{ Status = "Running"; Color = "Green" }
        } else {
            $results.Docker = @{ Status = "No SigNoz containers"; Color = "Yellow" }
        }
    }
    catch {
        Stop-SpinnerJob -Job $spinnerJob
        $results.Docker = @{ Status = "Unavailable"; Color = "Red" }
    }
    
    return $results
}

# Run preflight check if requested
if ($PreflightCheck) {
    Write-Host "🔍 Running Preflight OTLP Endpoint Check" -ForegroundColor Cyan
    try {
        $preflightResult = & ".\scripts\preflight-health-check.ps1" -Verbose
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Preflight check passed" -ForegroundColor Green
        } else {
            Write-Host "❌ Preflight check failed" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Preflight check error: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

# Run quick health check
$healthResults = Test-QuickHealth

# Display results
Write-Host "📊 Quick Health Check:" -ForegroundColor Cyan
foreach ($component in $healthResults.GetEnumerator()) {
    $color = $component.Value.Color
    $status = $component.Value.Status
    Write-Host "   $($component.Key): $status" -ForegroundColor $color
    if ($component.Value.Error) {
        Write-Host "     Error: $($component.Value.Error)" -ForegroundColor Red
    }
}

# Quick metrics check - simplified approach
Write-Host ""
Write-Host "📈 Quick Metrics:" -ForegroundColor Cyan
try {
    # Check SigNoz version and setup status
    $versionResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/version" -Method Get -TimeoutSec 3
    
    if ($versionResponse) {
        Write-Host "   SigNoz Version: $($versionResponse.version)" -ForegroundColor White
        Write-Host "   Setup Completed: $($versionResponse.setupCompleted)" -ForegroundColor White
        
        # Check if we can access the logs page (UI endpoint)
        $logsPage = Invoke-WebRequest -Uri "http://localhost:8080/logs" -Method Get -TimeoutSec 3 -UseBasicParsing
        if ($logsPage.StatusCode -eq 200) {
            Write-Host "   Logs UI: Accessible" -ForegroundColor Green
        } else {
            Write-Host "   Logs UI: Not accessible" -ForegroundColor Yellow
        }
        
        $checks += @{
            Timestamp = Get-Date
            SigNozVersion = $versionResponse.version
            SetupCompleted = $versionResponse.setupCompleted
            LogsUIAccessible = ($logsPage.StatusCode -eq 200)
        }
    }
}
catch {
    Write-Host "   Metrics: Unable to query SigNoz" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   💡 Manual check: Visit http://localhost:8080/logs" -ForegroundColor Blue
}

# ECRR Report
if ($ExportReport) {
    $ecrrReport = @{
        Examine = @{
            Environment = "Windows 11 + OTel + SigNoz"
            Timestamp = $startTime
            Pipeline = "Windows Events → OTel Collector → SigNoz → ClickHouse"
        }
        Clean = @{
            Actions = @("Quick health check performed", "Real-time metrics queried")
            DriftRemoved = @()
        }
        Report = @{
            Artifacts = @("quick-monitor.ps1", "Health check results")
            Evidence = @("Health check completed in $((Get-Date) - $startTime)")
        }
        Role = "Cursor Agent - Observability Copilot"
    }
    
    $monitoringReport = @{
        ECRR = $ecrrReport
        HealthResults = $healthResults
        Checks = $checks
        Summary = @{
            StartTime = $startTime
            EndTime = Get-Date
            Duration = (Get-Date) - $startTime
            TotalChecks = $checks.Count
        }
    }
    
    # Create artifacts directory if it doesn't exist
    if (-not (Test-Path "artifacts")) {
        New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
    }
    
    $monitoringReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host ""
    Write-Host "📄 Quick Report exported to: $ReportPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ Quick check complete" -ForegroundColor Green
Write-Host "💡 For detailed monitoring: pwsh -File scripts\monitor-optimized-pipeline.ps1" -ForegroundColor Blue
Write-Host "💡 SigNoz UI: http://localhost:8080" -ForegroundColor Blue
