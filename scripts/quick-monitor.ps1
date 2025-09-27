# See C:\otel\docs\comfort cat
# Quick Monitor - Fast Pipeline Health Check
# Lightweight version of the enhanced monitor for quick status checks

param(
    [switch]$ExportReport = $false,
    [ValidateNotNullOrEmpty()]
    [string]$ReportPath = "artifacts\quick-monitor-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

Write-Host "⚡ Quick Pipeline Monitor" -ForegroundColor Cyan
Write-Host "Fast health check with ECRR reporting" -ForegroundColor Gray
Write-Host ""

$startTime = Get-Date
$checks = @()

# Quick health checks
function Test-QuickHealth {
    $results = @{}
    
    # SigNoz health
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 3 -ErrorAction Stop
        $results.SigNoz = @{ Status = "Healthy"; Color = "Green" }
    }
    catch {
        $results.SigNoz = @{ Status = "Unreachable"; Color = "Red"; Error = $_.Exception.Message }
        Write-Warning "SigNoz health check failed: $($_.Exception.Message)"
    }
    
    # Windows Collector
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        $results.WindowsCollector = @{ Status = "Running"; Color = "Green" }
    } else {
        $results.WindowsCollector = @{ Status = "Not Running"; Color = "Red" }
    }
    
    # Docker services
    try {
        $dockerPs = docker ps --format "table {{.Names}}\t{{.Status}}" 2>$null | Select-String "signoz"
        if ($dockerPs) {
            $results.Docker = @{ Status = "Running"; Color = "Green" }
        } else {
            $results.Docker = @{ Status = "No SigNoz containers"; Color = "Yellow" }
        }
    }
    catch {
        $results.Docker = @{ Status = "Unavailable"; Color = "Red" }
        Write-Warning "Docker check failed: $($_.Exception.Message)"
    }
    
    return $results
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
