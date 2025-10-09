# Automated Service Monitoring Script
# This script implements comprehensive health checks and alerting for the observability stack

param(
    [int]$CheckIntervalSeconds = 60,
    [string]$LogFile = "artifacts/service-monitoring.log",
    [switch]$Continuous,
    [switch]$SetupAlerts
)

Write-Host "🔄 Automated Service Monitoring" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Create artifacts directory if it doesn't exist
if (!(Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
}

# Function to log with timestamp
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogFile -Value $logEntry
}

# Function to check service health
function Test-ServiceHealth {
    param([string]$ServiceName, [string]$CheckType, [string]$Endpoint)
    
    try {
        switch ($CheckType) {
            "http" {
                $response = Invoke-WebRequest -Uri $Endpoint -Method GET -TimeoutSec 10 -UseBasicParsing
                return @{
                    Status = "Healthy"
                    ResponseTime = $response.Headers["X-Response-Time"]
                    StatusCode = $response.StatusCode
                }
            }
            "process" {
                $process = Get-Process -Name $ServiceName -ErrorAction SilentlyContinue
                if ($process) {
                    return @{
                        Status = "Healthy"
                        PID = $process.Id
                        CPU = $process.CPU
                        Memory = $process.WorkingSet
                    }
                } else {
                    return @{
                        Status = "Stopped"
                        Error = "Process not found"
                    }
                }
            }
            "port" {
                $connection = Test-NetConnection -ComputerName "localhost" -Port $Endpoint.Split(':')[1] -InformationLevel Quiet
                return @{
                    Status = if ($connection) { "Healthy" } else { "Unreachable" }
                    Port = $Endpoint.Split(':')[1]
                }
            }
        }
    } catch {
        return @{
            Status = "Error"
            Error = $_.Exception.Message
        }
    }
}

# Function to send alert
function Send-Alert {
    param([string]$Service, [string]$Status, [string]$Message)
    
    $alert = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Service = $Service
        Status = $Status
        Message = $Message
        Severity = if ($Status -eq "Error" -or $Status -eq "Stopped") { "HIGH" } else { "MEDIUM" }
    }
    
    Write-Log "ALERT: $($Service) - $($Status): $($Message)" "ALERT"
    
    # Save alert to file
    $alertFile = "artifacts/alerts-$(Get-Date -Format 'yyyy-MM-dd').json"
    $alerts = @()
    if (Test-Path $alertFile) {
        $alerts = Get-Content $alertFile | ConvertFrom-Json
    }
    $alerts += $alert
    $alerts | ConvertTo-Json -Depth 3 | Set-Content $alertFile
    
    # TODO: Add webhook/email notifications here
}

# Define services to monitor
$services = @(
    @{
        Name = "SigNoz UI"
        Type = "http"
        Endpoint = "http://localhost:8080/api/v1/health"
        Critical = $true
    },
    @{
        Name = "SigNoz Collector"
        Type = "port"
        Endpoint = "localhost:14317"
        Critical = $true
    },
    @{
        Name = "Windows Collector"
        Type = "process"
        Endpoint = "otelcol-contrib"
        Critical = $true
    },
    @{
        Name = "Windows Collector Health"
        Type = "http"
        Endpoint = "http://localhost:13134/healthz"
        Critical = $true
    },
    @{
        Name = "Docker Services"
        Type = "process"
        Endpoint = "docker"
        Critical = $false
        Note = "Docker may be intentionally offline in development environments"
    }
)

# Function to run health checks
function Invoke-HealthChecks {
    Write-Log "Starting health checks..." "INFO"
    
    $results = @()
    $criticalFailures = 0
    
    foreach ($service in $services) {
        Write-Log "Checking $($service.Name)..." "INFO"
        
        $result = Test-ServiceHealth -ServiceName $service.Endpoint -CheckType $service.Type -Endpoint $service.Endpoint
        $result.Service = $service.Name
        $result.Critical = $service.Critical
        $result.Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        $results += $result
        
        if ($result.Status -ne "Healthy") {
            if ($service.Critical) {
                $criticalFailures++
                Send-Alert -Service $service.Name -Status $result.Status -Message $result.Error
            } else {
                Write-Log "$($service.Name): $($result.Status) (Non-critical: $($service.Note))" "WARN"
            }
        } else {
            Write-Log "$($service.Name): $($result.Status)" "INFO"
        }
    }
    
    # Save results
    $resultsFile = "artifacts/health-check-$(Get-Date -Format 'yyyy-MM-dd-HH-mm').json"
    $results | ConvertTo-Json -Depth 3 | Set-Content $resultsFile
    
    # Summary
    $healthyCount = ($results | Where-Object { $_.Status -eq "Healthy" }).Count
    $totalCount = $results.Count
    
    Write-Log "Health Check Summary: $healthyCount/$totalCount services healthy" "INFO"
    
    if ($criticalFailures -gt 0) {
        Write-Log "CRITICAL: $criticalFailures critical services failing!" "ERROR"
        return $false
    }
    
    return $true
}

# Function to setup alerts
function Setup-Alerts {
    Write-Log "Setting up alerting configuration..." "INFO"
    
    # Create alert configuration
    $alertConfig = @{
        Webhooks = @(
            @{
                Name = "Slack"
                URL = $env:SLACK_WEBHOOK_URL
                Enabled = $false
            },
            @{
                Name = "Teams"
                URL = $env:TEAMS_WEBHOOK_URL
                Enabled = $false
            }
        )
        Email = @{
            Enabled = $false
            SMTP = $env:SMTP_SERVER
            Recipients = @($env:ALERT_EMAIL)
        }
        Thresholds = @{
            ResponseTime = 5000  # 5 seconds
            MemoryUsage = 80     # 80%
            CPUUsage = 90       # 90%
        }
    }
    
    $configFile = "artifacts/alert-config.json"
    $alertConfig | ConvertTo-Json -Depth 3 | Set-Content $configFile
    
    Write-Log "Alert configuration saved to $configFile" "INFO"
    Write-Log "To enable alerts, set environment variables:" "INFO"
    Write-Log "  SLACK_WEBHOOK_URL, TEAMS_WEBHOOK_URL, SMTP_SERVER, ALERT_EMAIL" "INFO"
}

# Main execution
if ($SetupAlerts) {
    Setup-Alerts
    exit 0
}

Write-Log "Starting automated service monitoring..." "INFO"
Write-Log "Check interval: $CheckIntervalSeconds seconds" "INFO"
Write-Log "Log file: $LogFile" "INFO"

if ($Continuous) {
    Write-Log "Running in continuous mode (Ctrl+C to stop)" "INFO"
    
    while ($true) {
        $success = Invoke-HealthChecks
        
        if (-not $success) {
            Write-Log "Critical failures detected, waiting 30 seconds before next check" "WARN"
            Start-Sleep -Seconds 30
        } else {
            Start-Sleep -Seconds $CheckIntervalSeconds
        }
    }
} else {
    $success = Invoke-HealthChecks
    
    if ($success) {
        Write-Log "All services healthy!" "INFO"
        exit 0
    } else {
        Write-Log "Some services are unhealthy!" "ERROR"
        exit 1
    }
}
