# BRAV/SCPT/watchdog-site.ps1
# SITE Bot - Windows Collector Observer
# Monitors health endpoints and collects diagnostic evidence
# ECRR: Examine (probe) → Clean (diagnose) → Report (evidence) → Role (SITE observer)

[CmdletBinding()]
param(
    [int]$IntervalSeconds = 30,
    [string]$HealthEndpoint = "http://localhost:13134/healthz",
    [string]$MetricsEndpoint = "http://localhost:8888/metrics",
    [string]$LogPath = "DELT/ARTF/watchdog-site.log",
    [string]$SnapshotDir = "docs/observability/snapshots/site-observations"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Write-SiteLog($message, $level = "INFO") {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "[$timestamp] [SITE:$level] $message"
    Write-Host $entry
    Add-Content -Path $LogPath -Value $entry -Encoding UTF8
}

function Test-KillSwitch {
    if (Test-Path ".agent/LOCK") {
        Write-SiteLog "Kill-switch engaged (.agent/LOCK) - SITE shutting down" "WARN"
        return $true
    }
    return $false
}

function Test-Endpoint {
    param([string]$Url, [int]$TimeoutSec = 5)
    
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $TimeoutSec -ErrorAction Stop
        return [PSCustomObject]@{
            Reachable = $true
            StatusCode = $response.StatusCode
            ResponseTime = $response.Headers.'X-Response-Time'
            ContentLength = $response.Content.Length
            Timestamp = Get-Date -Format "o"
        }
    } catch {
        return [PSCustomObject]@{
            Reachable = $false
            Error = $_.Exception.Message
            ErrorType = $_.Exception.GetType().Name
            Timestamp = Get-Date -Format "o"
        }
    }
}

function Get-ServiceDiagnostics {
    param([string]$ServiceName = "otelcol-contrib")
    
    $diagnostics = @{
        timestamp = Get-Date -Format "o"
        service = @{}
        ports = @{}
        processes = @{}
    }
    
    # Service status
    try {
        $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($svc) {
            $diagnostics.service = @{
                status = $svc.Status.ToString()
                startType = $svc.StartType.ToString()
                canStop = $svc.CanStop
                displayName = $svc.DisplayName
            }
        } else {
            $diagnostics.service = @{ status = "NotInstalled" }
        }
    } catch {
        $diagnostics.service = @{ error = $_.Exception.Message }
    }
    
    # Port listeners
    $ports = @(13133, 8888, 4317, 4318, 55679)
    foreach ($port in $ports) {
        try {
            $listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
            $diagnostics.ports["$port"] = if ($listener) { "Listening" } else { "Closed" }
        } catch {
            $diagnostics.ports["$port"] = "Unknown"
        }
    }
    
    # Process info
    try {
        $proc = Get-Process -Name "otelcol-contrib" -ErrorAction SilentlyContinue
        if ($proc) {
            $diagnostics.processes = @{
                pid = $proc.Id
                cpu = $proc.CPU
                workingSet = $proc.WorkingSet64
                startTime = $proc.StartTime
            }
        } else {
            $diagnostics.processes = @{ status = "NotRunning" }
        }
    } catch {
        $diagnostics.processes = @{ error = $_.Exception.Message }
    }
    
    return $diagnostics
}

function Export-SiteSnapshot {
    param($observations)
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $snapshotPath = Join-Path $SnapshotDir "site-snapshot-$timestamp.json"
    
    New-Item -ItemType Directory -Path $SnapshotDir -Force -ErrorAction SilentlyContinue | Out-Null
    $observations | ConvertTo-Json -Depth 5 | Set-Content -Path $snapshotPath -Encoding UTF8
    
    return $snapshotPath
}

function Analyze-Observations {
    param($history)
    
    $analysis = @{
        totalObservations = $history.Count
        healthyCount = ($history | Where-Object { $_.health.Reachable }).Count
        unhealthyCount = ($history | Where-Object { -not $_.health.Reachable }).Count
        patterns = @()
    }
    
    # Detect patterns
    if ($history.Count -ge 3) {
        $recent = $history | Select-Object -Last 3
        $allDown = ($recent | Where-Object { -not $_.health.Reachable }).Count -eq 3
        
        if ($allDown) {
            $analysis.patterns += "PATTERN: Service consistently unreachable (3+ checks)"
        }
    }
    
    return $analysis
}

# Initialize
New-Item -ItemType Directory -Path (Split-Path $LogPath -Parent) -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path $SnapshotDir -Force -ErrorAction SilentlyContinue | Out-Null

$script:startTime = Get-Date
$observationHistory = @()
$checkCount = 0
$healthyCount = 0
$unhealthyCount = 0

Write-SiteLog "========================================" "INIT"
Write-SiteLog "SITE Bot Starting" "INIT"
Write-SiteLog "Health Endpoint: $HealthEndpoint" "INIT"
Write-SiteLog "Metrics Endpoint: $MetricsEndpoint" "INIT"
Write-SiteLog "Interval: $IntervalSeconds seconds" "INIT"
Write-SiteLog "========================================" "INIT"

Write-SiteLog "Entering observation loop (Ctrl+C to stop)..." "INFO"

try {
    while ($true) {
        # Check kill-switch
        if (Test-KillSwitch) {
            break
        }
        
        $checkCount++
        Write-SiteLog "Observation #$checkCount starting..." "CHECK"
        
        # Examine - Probe all endpoints and collect diagnostics
        $observation = @{
            checkNumber = $checkCount
            timestamp = Get-Date -Format "o"
            health = Test-Endpoint -Url $HealthEndpoint
            metrics = Test-Endpoint -Url $MetricsEndpoint
            diagnostics = Get-ServiceDiagnostics
        }
        
        $observationHistory += $observation
        
        # Report status
        if ($observation.health.Reachable) {
            $healthyCount++
            Write-SiteLog "Health check OK: HTTP $($observation.health.StatusCode)" "OK"
        } else {
            $unhealthyCount++
            Write-SiteLog "Health check FAIL: $($observation.health.Error)" "ALERT"
            $listeningPorts = @($observation.diagnostics.ports.GetEnumerator() | Where-Object { $_.Value -eq 'Listening' })
            $portCount = $listeningPorts.Count
            Write-SiteLog "Diagnostics - Service: $($observation.diagnostics.service.status), Listening Ports: $portCount" "INFO"
        }
        
        # Clean - Analyze patterns every 5 observations
        if ($checkCount % 5 -eq 0) {
            $analysis = Analyze-Observations -history $observationHistory
            Write-SiteLog "Analysis - Total: $($analysis.totalObservations), Healthy: $healthyCount, Unhealthy: $unhealthyCount" "REPORT"
            
            foreach ($pattern in $analysis.patterns) {
                Write-SiteLog $pattern "PATTERN"
            }
        }
        
        # Report - Export snapshot every 10 observations
        if ($checkCount % 10 -eq 0) {
            $snapshot = @{
                bot = "SITE"
                startTime = $script:startTime
                currentTime = Get-Date -Format "o"
                statistics = @{
                    totalChecks = $checkCount
                    healthy = $healthyCount
                    unhealthy = $unhealthyCount
                    healthPercentage = if ($checkCount -gt 0) { [math]::Round(($healthyCount / $checkCount) * 100, 2) } else { 0 }
                }
                recentObservations = $observationHistory | Select-Object -Last 10
            }
            
            $snapshotPath = Export-SiteSnapshot -observations $snapshot
            Write-SiteLog "Snapshot exported to $snapshotPath" "REPORT"
        }
        
        # Wait for next observation
        Start-Sleep -Seconds $IntervalSeconds
    }
} catch {
    Write-SiteLog "SITE Bot interrupted: $($_.Exception.Message)" "ERROR"
} finally {
    Write-SiteLog "SITE Bot shutting down..." "SHUTDOWN"
    
    # Final snapshot
    $finalSnapshot = @{
        bot = "SITE"
        session = @{
            startTime = $script:startTime
            endTime = Get-Date -Format "o"
            duration = (Get-Date) - $script:startTime
        }
        statistics = @{
            totalChecks = $checkCount
            healthy = $healthyCount
            unhealthy = $unhealthyCount
            healthPercentage = if ($checkCount -gt 0) { [math]::Round(($healthyCount / $checkCount) * 100, 2) } else { 0 }
        }
        allObservations = $observationHistory
    }
    
    $finalPath = Export-SiteSnapshot -observations $finalSnapshot
    Write-SiteLog "Final snapshot exported to $finalPath" "FINAL"
    Write-SiteLog "Final stats - Checks: $checkCount, Healthy: $healthyCount ($($finalSnapshot.statistics.healthPercentage)%), Unhealthy: $unhealthyCount" "FINAL"
}

