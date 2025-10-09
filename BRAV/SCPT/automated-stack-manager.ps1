# Automated SigNoz/OTel Stack Manager
# Continuous monitoring, health checks, and automated remediation

param(
    [int]$MonitorIntervalSeconds = 60,
    [switch]$EnableAutoRemediation = $true,
    [switch]$EnableMetricsExport = $true,
    [string]$LogLevel = "INFO",
    [string]$ConfigFile = "docker-compose-optimized.yml"
)

# Set error action preference
$ErrorActionPreference = "Continue"

# Color functions for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor $Color
    
    # Log to file
    if (-not (Test-Path "artifacts")) {
        New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
    }
    Add-Content -Path "artifacts/stack-manager.log" -Value $logMessage
}

function Write-Info { param([string]$msg) Write-ColorOutput "ℹ️  $msg" "Cyan" }
function Write-Success { param([string]$msg) Write-ColorOutput "✅ $msg" "Green" }
function Write-Warning { param([string]$msg) Write-ColorOutput "⚠️  $msg" "Yellow" }
function Write-Error { param([string]$msg) Write-ColorOutput "❌ $msg" "Red" }
function Write-Critical { param([string]$msg) Write-ColorOutput "🚨 $msg" "Red" }

# Service health monitoring
class ServiceHealthMonitor {
    [string]$ServiceName
    [string]$ExpectedStatus
    [string]$HealthEndpoint
    [int]$Port
    [int]$FailureCount
    [DateTime]$LastFailure
    [bool]$IsCritical
    
    ServiceHealthMonitor([string]$name, [string]$status, [string]$endpoint, [int]$port, [bool]$critical) {
        $this.ServiceName = $name
        $this.ExpectedStatus = $status
        $this.HealthEndpoint = $endpoint
        $this.Port = $port
        $this.FailureCount = 0
        $this.LastFailure = [DateTime]::MinValue
        $this.IsCritical = $critical
    }
    
    [bool] CheckHealth() {
        try {
            # Check Docker container status
            $containerStatus = docker compose -f $ConfigFile ps $this.ServiceName --format "{{.State}}" 2>$null
            if ($containerStatus -ne $this.ExpectedStatus) {
                $this.RecordFailure("Container status: $containerStatus (expected: $($this.ExpectedStatus))")
                return $false
            }

            # Check health endpoint if provided
            if ($this.HealthEndpoint -and $this.Port -gt 0) {
                try {
                    $response = Invoke-WebRequest -Uri "http://localhost:$($this.Port)$($this.HealthEndpoint)" -TimeoutSec 10 -UseBasicParsing
                    if ($response.StatusCode -ne 200) {
                        $this.RecordFailure("Health endpoint returned: $($response.StatusCode)")
                        return $false
                    }
                } catch {
                    $this.RecordFailure("Health endpoint unreachable: $($_.Exception.Message)")
                    return $false
                }
            }

            # Reset failure count on success
            $this.FailureCount = 0
            return $true
        } catch {
            $this.RecordFailure("Health check error: $($_.Exception.Message)")
            return $false
        }
    }
    
    [void] RecordFailure([string]$reason) {
        $this.FailureCount++
        $this.LastFailure = Get-Date
        Write-Warning "$($this.ServiceName) health check failed: $reason (failure #$($this.FailureCount))"
    }
    
    [bool] ShouldRemediate() {
        return $this.FailureCount -ge 2 -and (Get-Date).Subtract($this.LastFailure).TotalMinutes -lt 10
    }
}

# Initialize service monitors
$serviceMonitors = @(
    [ServiceHealthMonitor]::new("signoz-zookeeper", "running", "/commands/ruok", 8080, $true),
    [ServiceHealthMonitor]::new("signoz-clickhouse", "running", "/ping", 8123, $true),
    [ServiceHealthMonitor]::new("signoz", "running", "/api/v1/health", 8080, $true),
    [ServiceHealthMonitor]::new("signoz-otel-collector", "running", "", 0, $true),
    [ServiceHealthMonitor]::new("demo-app", "running", "/health", 3001, $false)
)

# Remediation functions
function Invoke-ServiceRemediation {
    param([ServiceHealthMonitor]$monitor)
    
    Write-Warning "Attempting remediation for $($monitor.ServiceName)..."
    
    try {
        switch ($monitor.ServiceName) {
            "signoz-zookeeper" {
                Write-Info "Restarting Zookeeper..."
                docker compose -f $ConfigFile restart signoz-zookeeper
            }
            "signoz-clickhouse" {
                Write-Info "Restarting ClickHouse..."
                docker compose -f $ConfigFile restart signoz-clickhouse
            }
            "signoz" {
                Write-Info "Restarting SigNoz..."
                docker compose -f $ConfigFile restart signoz
            }
            "signoz-otel-collector" {
                Write-Info "Restarting OTel Collector..."
                docker compose -f $ConfigFile restart signoz-otel-collector
            }
            "demo-app" {
                Write-Info "Restarting Demo App..."
                docker compose -f $ConfigFile restart demo-app
            }
        }
        
        Start-Sleep -Seconds 30
        Write-Success "Remediation completed for $($monitor.ServiceName)"
        return $true
    } catch {
        Write-Error "Remediation failed for $($monitor.ServiceName): $($_.Exception.Message)"
        return $false
    }
}

function Get-SystemMetrics {
    $metrics = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Services = @{}
        System = @{}
    }
    
    # Get service metrics
    foreach ($monitor in $serviceMonitors) {
        try {
            $stats = docker stats $monitor.ServiceName --no-stream --format "table {{.CPUPerc}},{{.MemUsage}},{{.MemPerc}}" 2>$null
            if ($stats) {
                $lines = $stats -split "`n"
                if ($lines.Count -gt 1) {
                    $values = $lines[1] -split ","
                    $metrics.Services[$monitor.ServiceName] = @{
                        CPU = $values[0]
                        MemoryUsage = $values[1]
                        MemoryPercent = $values[2]
                        FailureCount = $monitor.FailureCount
                        LastFailure = $monitor.LastFailure
                    }
                }
            }
        } catch {
            # Ignore metrics collection errors
        }
    }
    
    # Get system metrics
    try {
        $metrics.System = @{
            DockerContainers = (docker ps -q | Measure-Object).Count
            DockerImages = (docker images -q | Measure-Object).Count
            SystemLoad = [System.Environment]::ProcessorCount
        }
    } catch {
        # Ignore system metrics errors
    }
    
    return $metrics
}

function Export-Metrics {
    param([hashtable]$metrics)
    
    if ($EnableMetricsExport) {
        $metricsPath = "artifacts/metrics-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $metrics | ConvertTo-Json -Depth 4 | Out-File -FilePath $metricsPath -Encoding UTF8
        Write-Info "Metrics exported to: $metricsPath"
    }
}

function Test-EndpointConnectivity {
    $endpoints = @(
        @{ Name = "SigNoz UI"; Url = "http://localhost:8080" },
        @{ Name = "Demo App"; Url = "http://localhost:3001" },
        @{ Name = "ClickHouse HTTP"; Url = "http://localhost:8123/ping" }
    )
    
    $connectivity = @{}
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint.Url -TimeoutSec 5 -UseBasicParsing
            $connectivity[$endpoint.Name] = @{
                Status = "OK"
                ResponseTime = $response.Headers.'X-Response-Time'
                StatusCode = $response.StatusCode
            }
            Write-Success "$($endpoint.Name): OK"
        } catch {
            $connectivity[$endpoint.Name] = @{
                Status = "FAILED"
                Error = $_.Exception.Message
            }
            Write-Warning "$($endpoint.Name): FAILED - $($_.Exception.Message)"
        }
    }
    
    return $connectivity
}

# Main monitoring loop
Write-Info "Starting automated stack manager..."
Write-Info "Monitor interval: $MonitorIntervalSeconds seconds"
Write-Info "Auto-remediation: $EnableAutoRemediation"
Write-Info "Metrics export: $EnableMetricsExport"

$cycleCount = 0
$lastHealthReport = $null

while ($true) {
    $cycleCount++
    Write-Info "=== Health Check Cycle #$cycleCount ==="
    
    $overallHealth = "healthy"
    $unhealthyServices = @()
    $criticalIssues = @()
    
    # Check each service
    foreach ($monitor in $serviceMonitors) {
        $isHealthy = $monitor.CheckHealth()
        
        if (-not $isHealthy) {
            $unhealthyServices += $monitor.ServiceName
            if ($monitor.IsCritical) {
                $criticalIssues += $monitor.ServiceName
                $overallHealth = "critical"
            } elseif ($overallHealth -eq "healthy") {
                $overallHealth = "degraded"
            }
            
            # Attempt remediation if enabled and conditions are met
            if ($EnableAutoRemediation -and $monitor.ShouldRemediate()) {
                Write-Warning "Triggering auto-remediation for $($monitor.ServiceName)"
                $remediated = Invoke-ServiceRemediation -monitor $monitor
                if ($remediated) {
                    Write-Success "Auto-remediation successful for $($monitor.ServiceName)"
                }
            }
        }
    }
    
    # Test endpoint connectivity
    Write-Info "Testing endpoint connectivity..."
    $connectivity = Test-EndpointConnectivity
    
    # Collect system metrics
    $metrics = Get-SystemMetrics
    $metrics.OverallHealth = $overallHealth
    $metrics.UnhealthyServices = $unhealthyServices
    $metrics.CriticalIssues = $criticalIssues
    $metrics.Connectivity = $connectivity
    
    # Export metrics
    Export-Metrics -metrics $metrics
    
    # Generate health report
    $healthReport = @{
        Cycle = $cycleCount
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        OverallHealth = $overallHealth
        HealthyServices = ($serviceMonitors.Count - $unhealthyServices.Count)
        TotalServices = $serviceMonitors.Count
        UnhealthyServices = $unhealthyServices
        CriticalIssues = $criticalIssues
        Connectivity = $connectivity
    }
    
    # Alert on health changes
    if ($lastHealthReport -and $lastHealthReport.OverallHealth -ne $overallHealth) {
        if ($overallHealth -eq "critical") {
            Write-Critical "🚨 CRITICAL: Stack health degraded to critical level!"
            Write-Critical "Critical issues: $($criticalIssues -join ', ')"
        } elseif ($overallHealth -eq "healthy") {
            Write-Success "🎉 Stack health restored to healthy state!"
        }
    }
    
    $lastHealthReport = $healthReport
    
    # Summary
    $healthyCount = $serviceMonitors.Count - $unhealthyServices.Count
    Write-Info "Health Summary: $healthyCount/$($serviceMonitors.Count) services healthy"
    Write-Info "Overall Status: $overallHealth"
    
    if ($criticalIssues.Count -gt 0) {
        Write-Critical "Critical services down: $($criticalIssues -join ', ')"
    }
    
    # Wait for next cycle
    Start-Sleep -Seconds $MonitorIntervalSeconds
}
