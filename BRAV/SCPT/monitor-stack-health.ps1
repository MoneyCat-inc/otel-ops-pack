# Monitor SigNoz/OTel Stack Health
# Continuous monitoring with alerting and automated remediation

param(
    [int]$IntervalSeconds = 30,
    [int]$MaxRetries = 3,
    [string]$LogFile = "artifacts/stack-health.log",
    [switch]$EnableAutoRemediation,
    [switch]$ExportMetrics
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
    Add-Content -Path $LogFile -Value $logMessage
}

function Write-Info { param([string]$msg) Write-ColorOutput "ℹ️  $msg" "Cyan" }
function Write-Success { param([string]$msg) Write-ColorOutput "✅ $msg" "Green" }
function Write-Warning { param([string]$msg) Write-ColorOutput "⚠️  $msg" "Yellow" }
function Write-Error { param([string]$msg) Write-ColorOutput "❌ $msg" "Red" }
function Write-Critical { param([string]$msg) Write-ColorOutput "🚨 $msg" "Red" }

# Health check functions
function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$HealthEndpoint = $null,
        [int]$Port = $null
    )
    
    try {
        # Check Docker container status
        $containerStatus = docker compose -f docker-compose.yml ps $ServiceName --format "{{.State}}" 2>$null
        if ($containerStatus -ne "running") {
            return @{ Status = "unhealthy"; Reason = "Container not running: $containerStatus" }
        }

        # Check health endpoint if provided
        if ($HealthEndpoint -and $Port) {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:$Port$HealthEndpoint" -TimeoutSec 5 -UseBasicParsing
                if ($response.StatusCode -eq 200) {
                    return @{ Status = "healthy"; ResponseTime = $response.Headers.'X-Response-Time' }
                } else {
                    return @{ Status = "unhealthy"; Reason = "HTTP $($response.StatusCode)" }
                }
            } catch {
                return @{ Status = "unhealthy"; Reason = "Health endpoint unreachable: $($_.Exception.Message)" }
            }
        }

        return @{ Status = "healthy" }
    } catch {
        return @{ Status = "unhealthy"; Reason = $_.Exception.Message }
    }
}

function Get-ServiceMetrics {
    param([string]$ServiceName)
    
    try {
        $stats = docker stats $ServiceName --no-stream --format "table {{.CPUPerc}},{{.MemUsage}},{{.MemPerc}},{{.NetIO}},{{.BlockIO}}" 2>$null
        if ($stats) {
            $lines = $stats -split "`n"
            if ($lines.Count -gt 1) {
                $metrics = $lines[1] -split ","
                return @{
                    CPU = $metrics[0]
                    MemoryUsage = $metrics[1]
                    MemoryPercent = $metrics[2]
                    NetworkIO = $metrics[3]
                    BlockIO = $metrics[4]
                }
            }
        }
    } catch {
        # Ignore errors in metrics collection
    }
    
    return $null
}

function Invoke-AutoRemediation {
    param(
        [string]$ServiceName,
        [string]$Issue
    )
    
    Write-Warning "Attempting auto-remediation for ${ServiceName}: $Issue"
    
    try {
        switch ($Issue) {
            "Container not running" {
                Write-Info "Restarting $ServiceName..."
                docker compose -f docker-compose.yml restart $ServiceName
                Start-Sleep -Seconds 10
                return $true
            }
            "Health endpoint unreachable" {
                Write-Info "Checking logs for $ServiceName..."
                $logs = docker compose -f docker-compose.yml logs --tail=10 $ServiceName
                Write-Info "Recent logs: $logs"
                return $false
            }
            default {
                Write-Info "No auto-remediation available for: $Issue"
                return $false
            }
        }
    } catch {
        Write-Error "Auto-remediation failed for ${ServiceName}: $($_.Exception.Message)"
        return $false
    }
}

# Service definitions with health check endpoints
$services = @{
    "signoz-zookeeper" = @{ Port = 8080; HealthEndpoint = "/commands/ruok" }
    "signoz-clickhouse" = @{ Port = 8123; HealthEndpoint = "/ping" }
    "signoz" = @{ Port = 8080; HealthEndpoint = "/api/v1/health" }
    "signoz-otel-collector" = @{ Port = 13133; HealthEndpoint = "/" }
    "demo-app" = @{ Port = 3001; HealthEndpoint = "/health" }
}

# Initialize monitoring
Write-Info "Starting stack health monitoring..."
Write-Info "Interval: $IntervalSeconds seconds, Auto-remediation: $EnableAutoRemediation"

$failureCounts = @{}
$lastHealthyState = @{}

# Main monitoring loop
while ($true) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $overallHealth = "healthy"
    $unhealthyServices = @()
    
    Write-Info "=== Health Check Cycle ==="
    
    foreach ($serviceName in $services.Keys) {
        $serviceConfig = $services[$serviceName]
        $health = Test-ServiceHealth -ServiceName $serviceName -HealthEndpoint $serviceConfig.HealthEndpoint -Port $serviceConfig.Port
        
        if ($health.Status -eq "healthy") {
            Write-Success "$serviceName is healthy"
            $failureCounts[$serviceName] = 0
            
            # Collect metrics if enabled
            if ($ExportMetrics) {
                $metrics = Get-ServiceMetrics -ServiceName $serviceName
                if ($metrics) {
                    Write-Info "$serviceName metrics: CPU=$($metrics.CPU), Memory=$($metrics.MemoryPercent)"
                }
            }
        } else {
            Write-Error "$serviceName is unhealthy: $($health.Reason)"
            $unhealthyServices += $serviceName
            $overallHealth = "degraded"
            
            # Track failure count
            if (-not $failureCounts.ContainsKey($serviceName)) {
                $failureCounts[$serviceName] = 0
            }
            $failureCounts[$serviceName]++
            
            # Auto-remediation
            if ($EnableAutoRemediation -and $failureCounts[$serviceName] -le $MaxRetries) {
                $remediated = Invoke-AutoRemediation -ServiceName $serviceName -Issue $health.Reason
                if ($remediated) {
                    Write-Info "Auto-remediation applied for $serviceName"
                }
            } elseif ($failureCounts[$serviceName] -gt $MaxRetries) {
                Write-Critical "$serviceName has failed $($failureCounts[$serviceName]) times - manual intervention required"
            }
        }
    }
    
    # Generate health report
    $healthReport = @{
        Timestamp = $timestamp
        OverallHealth = $overallHealth
        UnhealthyServices = $unhealthyServices
        FailureCounts = $failureCounts
        ServicesChecked = $services.Count
    }
    
    # Export metrics if enabled
    if ($ExportMetrics) {
        $metricsPath = "artifacts/stack-metrics-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $healthReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $metricsPath -Encoding UTF8
    }
    
    # Alert on state changes
    $currentState = $healthReport | ConvertTo-Json -Compress
    if ($lastHealthyState.ContainsKey("state") -and $lastHealthyState.state -ne $currentState) {
        if ($overallHealth -eq "degraded") {
            Write-Critical "Stack health degraded! Unhealthy services: $($unhealthyServices -join ', ')"
        } elseif ($overallHealth -eq "healthy" -and $lastHealthyState.overallHealth -eq "degraded") {
            Write-Success "Stack health restored!"
        }
    }
    $lastHealthyState = @{ state = $currentState; overallHealth = $overallHealth }
    
    # Summary
    $healthyCount = $services.Count - $unhealthyServices.Count
    Write-Info "Health Summary: $healthyCount/$($services.Count) services healthy"
    
    # Wait for next cycle
    Start-Sleep -Seconds $IntervalSeconds
}
