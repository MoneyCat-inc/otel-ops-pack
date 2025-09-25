# Windows OTel Collector Health Monitor
# Continuous monitoring for collector stability and health

param(
    [int]$IntervalSeconds = 30,
    [int]$MaxDurationMinutes = 0,  # 0 = run indefinitely
    [switch]$Quiet,
    [switch]$Export
)

# Initialize counters and status
$startTime = Get-Date
$checkCount = 0
$healthyCount = 0
$unhealthyCount = 0
$lastError = $null

# Create artifacts directory if it doesn't exist
$artifactsDir = "artifacts"
if (-not (Test-Path $artifactsDir)) {
    New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
}

# Health check function
function Test-CollectorHealth {
    param([switch]$Detailed)
    
    $health = @{
        ServiceRunning = $false
        PortsListening = @{
            gRPC = $false
            HTTP = $false
        }
        HealthEndpoint = $false
        ProcessActive = $false
        ConfigValid = $false
        LastError = $null
        Timestamp = Get-Date
    }
    
    try {
        # Check service status
        $service = Get-Service -Name "otelcol-contrib" -ErrorAction Stop
        $health.ServiceRunning = ($service.Status -eq "Running")
        
        # Check if process is running
        $process = Get-Process | Where-Object {$_.ProcessName -like "*otel*"}
        $health.ProcessActive = ($process -ne $null)
        
        # Check ports
        try {
            $health.PortsListening.gRPC = Test-NetConnection -ComputerName localhost -Port 5317 -InformationLevel Quiet -WarningAction SilentlyContinue
        } catch { }
        
        try {
            $health.PortsListening.HTTP = Test-NetConnection -ComputerName localhost -Port 5318 -InformationLevel Quiet -WarningAction SilentlyContinue
        } catch { }
        
        # Check health endpoint
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:13134/healthz" -TimeoutSec 5 -ErrorAction Stop
            $health.HealthEndpoint = ($response.StatusCode -eq 200)
        } catch { }
        
        # Check config file exists and is valid YAML
        $configPath = "C:\otel\config.yaml"
        if (Test-Path $configPath) {
            try {
                $content = Get-Content $configPath -Raw
                $health.ConfigValid = ($content -match "receivers:" -and $content -match "exporters:")
            } catch { }
        }
        
    } catch {
        $health.LastError = $_.Exception.Message
    }
    
    return $health
}

# Status display function
function Show-HealthStatus {
    param($Health, $CheckNumber)
    
    $status = "HEALTHY"
    $color = "Green"
    
    if (-not $Health.ServiceRunning) {
        $status = "UNHEALTHY - Service not running"
        $color = "Red"
    } elseif (-not $Health.PortsListening.gRPC -or -not $Health.PortsListening.HTTP) {
        $status = "UNHEALTHY - Ports not listening"
        $color = "Red"
    } elseif (-not $Health.HealthEndpoint) {
        $status = "WARNING - Health endpoint not responding"
        $color = "Yellow"
    }
    
    if (-not $Quiet) {
        $timestamp = $Health.Timestamp.ToString("HH:mm:ss")
        Write-Host "[$timestamp] Check #$CheckNumber - $status" -ForegroundColor $color
        
        if ($Detailed -and $Health.LastError) {
            Write-Host "  Error: $($Health.LastError)" -ForegroundColor Red
        }
    }
    
    return $status
}

# Export health data function
function Export-HealthData {
    param($Health, $CheckNumber)
    
    $exportData = @{
        CheckNumber = $CheckNumber
        Timestamp = $Health.Timestamp.ToString("o")
        ServiceRunning = $Health.ServiceRunning
        PortsListening = $Health.PortsListening
        HealthEndpoint = $Health.HealthEndpoint
        ProcessActive = $Health.ProcessActive
        ConfigValid = $Health.ConfigValid
        LastError = $Health.LastError
    }
    
    $exportFile = "$artifactsDir/collector-health-$($Health.Timestamp.ToString('yyyyMMdd-HHmmss')).json"
    $exportData | ConvertTo-Json -Depth 3 | Out-File -FilePath $exportFile -Encoding UTF8
    
    return $exportFile
}

# Main monitoring loop
Write-Host "Starting OTel Collector Health Monitor" -ForegroundColor Cyan
Write-Host "Check interval: $IntervalSeconds seconds" -ForegroundColor Gray
Write-Host "Max duration: $(if($MaxDurationMinutes -eq 0) {'Unlimited'} else {"$MaxDurationMinutes minutes"})" -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

$endTime = if ($MaxDurationMinutes -gt 0) { $startTime.AddMinutes($MaxDurationMinutes) } else { $null }

try {
    while ($true) {
        $checkCount++
        $health = Test-CollectorHealth -Detailed
        $status = Show-HealthStatus -Health $health -CheckNumber $checkCount
        
        # Update counters
        if ($status -eq "HEALTHY") {
            $healthyCount++
        } else {
            $unhealthyCount++
            $lastError = $health.LastError
        }
        
        # Export data if requested
        if ($Export) {
            $exportFile = Export-HealthData -Health $health -CheckNumber $checkCount
            if (-not $Quiet) {
                Write-Host "  Data exported to: $exportFile" -ForegroundColor Gray
            }
        }
        
        # Check if we should stop
        if ($endTime -and (Get-Date) -gt $endTime) {
            break
        }
        
        Start-Sleep -Seconds $IntervalSeconds
    }
} catch {
    Write-Host "`nMonitor stopped: $($_.Exception.Message)" -ForegroundColor Red
}

# Final summary
$totalChecks = $checkCount
$healthyPercent = if ($totalChecks -gt 0) { [math]::Round(($healthyCount / $totalChecks) * 100, 1) } else { 0 }
$duration = (Get-Date) - $startTime

Write-Host "`n=== Health Monitor Summary ===" -ForegroundColor Cyan
Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
Write-Host "Total checks: $totalChecks" -ForegroundColor Gray
Write-Host "Healthy: $healthyCount ($healthyPercent%)" -ForegroundColor Green
Write-Host "Unhealthy: $unhealthyCount" -ForegroundColor Red

if ($lastError) {
    Write-Host "Last error: $lastError" -ForegroundColor Red
}

Write-Host "`nHealth monitoring complete." -ForegroundColor Cyan
