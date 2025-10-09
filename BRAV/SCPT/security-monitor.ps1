# Enhanced Security Monitoring
# Part of 30-day remediation plan
# Monitors for DoS patterns, abnormal behavior, and security incidents
# BossCat OEM - Post-Gate Security Monitoring

param(
    [int]$DurationMinutes = 10,
    [switch]$ExportReport,
    [string]$OutputDir = "artifacts/security-monitoring"
)

$ErrorActionPreference = "Stop"

Write-Host "🛡️ BossCat Security Monitor" -ForegroundColor Cyan
Write-Host "Monitoring for DoS patterns and abnormal behavior" -ForegroundColor Gray
Write-Host "Duration: $DurationMinutes minutes" -ForegroundColor Gray
Write-Host ""

# Ensure output directory exists
if ($ExportReport -and -not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$startTime = Get-Date
$endTime = $startTime.AddMinutes($DurationMinutes)
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"

# Initialize metrics
$metrics = @{
    start_time = $startTime.ToString("o")
    duration_minutes = $DurationMinutes
    checks_performed = 0
    anomalies_detected = 0
    dos_patterns = @()
    resource_spikes = @()
    failed_requests = @()
    health_degradations = @()
}

Write-Host "🔍 Monitoring started at $($startTime.ToString('HH:mm:ss'))" -ForegroundColor Green
Write-Host "Will run until $($endTime.ToString('HH:mm:ss'))" -ForegroundColor Gray
Write-Host ""

# Baseline resource usage
$baselineContainers = docker stats --no-stream --format "{{.Container}},{{.CPUPerc}},{{.MemUsage}}" 2>$null

while ((Get-Date) -lt $endTime) {
    $metrics.checks_performed++
    $checkTime = Get-Date
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Check #$($metrics.checks_performed)" -ForegroundColor Cyan
    
    # 1. Check SigNoz Health
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 3 -ErrorAction Stop
        if ($health.status -ne "ok") {
            Write-Host "  ⚠️  SigNoz health: $($health.status)" -ForegroundColor Yellow
            $metrics.health_degradations += @{
                time = $checkTime.ToString("o")
                status = $health.status
                expected = "ok"
            }
            $metrics.anomalies_detected++
        } else {
            Write-Host "  ✅ SigNoz health: ok" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  🔴 SigNoz health check FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $metrics.failed_requests += @{
            time = $checkTime.ToString("o")
            endpoint = "/api/v1/health"
            error = $_.Exception.Message
        }
        $metrics.anomalies_detected++
    }
    
    # 2. Monitor Docker Resource Usage (DoS detection)
    try {
        $containerStats = docker stats --no-stream --format "{{.Container}},{{.CPUPerc}},{{.MemUsage}}" 2>$null
        
        foreach ($line in $containerStats) {
            if ($line) {
                $parts = $line -split ','
                $containerName = $parts[0]
                $cpuPercStr = $parts[1]
                $memUsage = $parts[2]
                
                # Parse CPU percentage
                $cpuPerc = [double]($cpuPercStr -replace '%', '')
                
                # Alert on high CPU (potential DoS)
                if ($cpuPerc -gt 80) {
                    Write-Host "  ⚠️  HIGH CPU: $containerName at $cpuPercStr" -ForegroundColor Yellow
                    $metrics.resource_spikes += @{
                        time = $checkTime.ToString("o")
                        container = $containerName
                        type = "cpu"
                        value = $cpuPerc
                        threshold = 80
                    }
                    $metrics.anomalies_detected++
                }
            }
        }
    }
    catch {
        Write-Host "  ⚠️  Docker stats check failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # 3. Check Windows Collector Service
    $service = Get-Service otelcol-contrib -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.Status -ne "Running") {
            Write-Host "  🔴 Windows Collector STOPPED" -ForegroundColor Red
            $metrics.anomalies_detected++
        } else {
            Write-Host "  ✅ Windows Collector: Running" -ForegroundColor Green
        }
    }
    
    # 4. Check OTLP Endpoints
    $endpoints = @(
        @{ Port = 14317; Name = "OTLP gRPC" },
        @{ Port = 14318; Name = "OTLP HTTP" }
    )
    
    foreach ($ep in $endpoints) {
        $test = Test-NetConnection localhost -Port $ep.Port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if (-not $test.TcpTestSucceeded) {
            Write-Host "  🔴 $($ep.Name) unreachable (port $($ep.Port))" -ForegroundColor Red
            $metrics.anomalies_detected++
        }
    }
    
    Write-Host ""
    
    # Sleep between checks (10 seconds)
    $remaining = ($endTime - (Get-Date)).TotalSeconds
    if ($remaining -gt 10) {
        Start-Sleep -Seconds 10
    } else {
        break
    }
}

$metrics.end_time = (Get-Date).ToString("o")
$metrics.total_duration_minutes = ((Get-Date) - $startTime).TotalMinutes

Write-Host "🏁 Monitoring complete" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "  Checks performed: $($metrics.checks_performed)" -ForegroundColor Gray
Write-Host "  Anomalies detected: $($metrics.anomalies_detected)" -ForegroundColor $(if ($metrics.anomalies_detected -eq 0) { "Green" } else { "Yellow" })
Write-Host "  DoS patterns: $($metrics.dos_patterns.Count)" -ForegroundColor $(if ($metrics.dos_patterns.Count -eq 0) { "Green" } else { "Red" })
Write-Host "  Resource spikes: $($metrics.resource_spikes.Count)" -ForegroundColor $(if ($metrics.resource_spikes.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Failed requests: $($metrics.failed_requests.Count)" -ForegroundColor $(if ($metrics.failed_requests.Count -eq 0) { "Green" } else { "Red" })
Write-Host "  Health degradations: $($metrics.health_degradations.Count)" -ForegroundColor $(if ($metrics.health_degradations.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($metrics.anomalies_detected -gt 0) {
    Write-Host "⚠️  $($metrics.anomalies_detected) anomalies detected during monitoring period" -ForegroundColor Yellow
    Write-Host "   Review exported report for details" -ForegroundColor Gray
} else {
    Write-Host "✅ No anomalies detected - all systems nominal" -ForegroundColor Green
}

if ($ExportReport) {
    $reportFile = Join-Path $OutputDir "security-monitor-$timestamp.json"
    $metrics | ConvertTo-Json -Depth 10 | Out-File $reportFile -Encoding UTF8
    Write-Host ""
    Write-Host "💾 Report exported: $reportFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "🐾 BossCat Security Monitor - Session complete" -ForegroundColor Cyan

# Exit code based on anomalies
if ($metrics.anomalies_detected -eq 0) {
    exit 0  # GREEN
} elseif ($metrics.anomalies_detected -le 3) {
    exit 10  # AMBER (soft warnings)
} else {
    exit 20  # RED (multiple anomalies)
}

