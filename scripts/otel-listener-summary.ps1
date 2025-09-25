# OTel Listener Summary - Receiver Status and Metrics
# Provides detailed information about OTel collectors, receivers, and data flow

param(
    [switch]$ExportReport = $false,
    [string]$ReportPath = "artifacts\otel-listener-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

$ErrorActionPreference = 'Stop'
$startTime = Get-Date

Write-Host "📡 OTel Listener Summary" -ForegroundColor Cyan
Write-Host "Analyzing receivers, endpoints, and data flow metrics" -ForegroundColor Gray
Write-Host ""

$summaryResults = @{
    Timestamp = $startTime
    Receivers = @{}
    Endpoints = @{}
    Metrics = @{}
    OverallStatus = "UNKNOWN"
}

# Get Receiver Information
function Get-ReceiverInfo {
    Write-Host "📋 Receiver Configuration:" -ForegroundColor Cyan
    
    $configPath = "C:\otel\config.yaml"
    if (-not (Test-Path $configPath)) {
        Write-Host "   ❌ Config file not found: $configPath" -ForegroundColor Red
        return $false
    }
    
    try {
        $configContent = Get-Content $configPath -Raw
        
        # Parse receivers section
        $receivers = @{}
        
        # Look for OTLP receivers
        if ($configContent -match "otlp:\s*\n\s*protocols:\s*\n\s*http:\s*\n\s*endpoint:\s*([^\n]+)") {
            $receivers.OTLP_HTTP = @{
                Protocol = "HTTP"
                Endpoint = $matches[1].Trim()
                Port = "5318"
                Status = "Configured"
            }
            Write-Host "   ✅ OTLP HTTP: $($matches[1].Trim())" -ForegroundColor Green
        }
        
        if ($configContent -match "grpc:\s*\n\s*endpoint:\s*([^\n]+)") {
            $receivers.OTLP_gRPC = @{
                Protocol = "gRPC"
                Endpoint = $matches[1].Trim()
                Port = "5317"
                Status = "Configured"
            }
            Write-Host "   ✅ OTLP gRPC: $($matches[1].Trim())" -ForegroundColor Green
        }
        
        # Look for other receivers
        if ($configContent -match "windowsperfcounters:") {
            $receivers.WindowsPerfCounters = @{
                Type = "Windows Performance Counters"
                Status = "Configured"
            }
            Write-Host "   ✅ Windows Performance Counters: Configured" -ForegroundColor Green
        }
        
        if ($configContent -match "filelog:") {
            $receivers.FileLog = @{
                Type = "File Log Receiver"
                Status = "Configured"
            }
            Write-Host "   ✅ File Log Receiver: Configured" -ForegroundColor Green
        }
        
        if ($configContent -match "eventlog:") {
            $receivers.EventLog = @{
                Type = "Windows Event Log"
                Status = "Configured"
            }
            Write-Host "   ✅ Windows Event Log: Configured" -ForegroundColor Green
        }
        
        $summaryResults.Receivers = $receivers
        return $true
    }
    catch {
        Write-Host "   ❌ Error parsing config: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Test Endpoint Connectivity
function Test-EndpointConnectivity {
    Write-Host ""
    Write-Host "🌐 Endpoint Connectivity:" -ForegroundColor Cyan
    
    $endpoints = @(
        @{ Name = "OTLP HTTP"; Port = 5318; Protocol = "HTTP" },
        @{ Name = "OTLP gRPC"; Port = 5317; Protocol = "TCP" },
        @{ Name = "SigNoz UI"; Port = 8080; Protocol = "HTTP" },
        @{ Name = "SigNoz Collector"; Port = 14317; Protocol = "TCP" }
    )
    
    $endpointResults = @{}
    
    foreach ($endpoint in $endpoints) {
        try {
            if ($endpoint.Protocol -eq "HTTP") {
                $response = Invoke-WebRequest -Uri "http://localhost:$($endpoint.Port)" -Method Get -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
                $endpointResults[$endpoint.Name] = @{
                    Port = $endpoint.Port
                    Status = "OK"
                    ResponseCode = $response.StatusCode
                    Color = "Green"
                }
                Write-Host "   ✅ $($endpoint.Name): Port $($endpoint.Port) (Status: $($response.StatusCode))" -ForegroundColor Green
            } else {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $result = $tcpClient.BeginConnect("localhost", $endpoint.Port, $null, $null)
                $success = $result.AsyncWaitHandle.WaitOne(3000, $false)
                
                if ($success -and $tcpClient.Connected) {
                    $endpointResults[$endpoint.Name] = @{
                        Port = $endpoint.Port
                        Status = "OK"
                        Color = "Green"
                    }
                    Write-Host "   ✅ $($endpoint.Name): Port $($endpoint.Port) open" -ForegroundColor Green
                    $tcpClient.Close()
                } else {
                    $endpointResults[$endpoint.Name] = @{
                        Port = $endpoint.Port
                        Status = "Not Responding"
                        Color = "Red"
                    }
                    Write-Host "   ❌ $($endpoint.Name): Port $($endpoint.Port) not responding" -ForegroundColor Red
                }
            }
        }
        catch {
            $endpointResults[$endpoint.Name] = @{
                Port = $endpoint.Port
                Status = "Error"
                Error = $_.Exception.Message
                Color = "Red"
            }
            Write-Host "   ❌ $($endpoint.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    $summaryResults.Endpoints = $endpointResults
}

# Get SigNoz Metrics
function Get-SigNozMetrics {
    Write-Host ""
    Write-Host "📊 SigNoz Metrics:" -ForegroundColor Cyan
    
    try {
        # Get SigNoz version and status
        $versionResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/version" -Method Get -TimeoutSec 5 -ErrorAction Stop
        
        $metrics = @{
            Version = $versionResponse.version
            SetupCompleted = $versionResponse.setupCompleted
            Timestamp = Get-Date
        }
        
        Write-Host "   ✅ Version: $($versionResponse.version)" -ForegroundColor Green
        Write-Host "   ✅ Setup: $($versionResponse.setupCompleted)" -ForegroundColor Green
        
        # Try to get basic metrics (this might fail if no data is available yet)
        try {
            $metricsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/metrics" -Method Get -TimeoutSec 5 -ErrorAction Stop
            $metrics.MetricsAvailable = $true
            Write-Host "   ✅ Metrics API: Available" -ForegroundColor Green
        }
        catch {
            $metrics.MetricsAvailable = $false
            Write-Host "   ⚠️  Metrics API: Not available yet" -ForegroundColor Yellow
        }
        
        # Try to get logs (this might fail if no data is available yet)
        try {
            $logsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs" -Method Get -TimeoutSec 5 -ErrorAction Stop
            $metrics.LogsAvailable = $true
            Write-Host "   ✅ Logs API: Available" -ForegroundColor Green
        }
        catch {
            $metrics.LogsAvailable = $false
            Write-Host "   ⚠️  Logs API: Not available yet" -ForegroundColor Yellow
        }
        
        $summaryResults.Metrics = $metrics
        return $true
    }
    catch {
        Write-Host "   ❌ SigNoz: $($_.Exception.Message)" -ForegroundColor Red
        $summaryResults.Metrics = @{
            Status = "Error"
            Error = $_.Exception.Message
        }
        return $false
    }
}

# Get Service Status
function Get-ServiceStatus {
    Write-Host ""
    Write-Host "🔧 Service Status:" -ForegroundColor Cyan
    
    try {
        $service = Get-Service -Name "otelcol-contrib" -ErrorAction Stop
        
        $serviceInfo = @{
            Name = $service.Name
            Status = $service.Status
            StartType = $service.StartType
            StartTime = $service.StartTime
        }
        
        if ($service.Status -eq "Running") {
            Write-Host "   ✅ Windows Collector: $($service.Status)" -ForegroundColor Green
            Write-Host "   📊 Start Type: $($service.StartType)" -ForegroundColor White
            Write-Host "   🕒 Started: $($service.StartTime)" -ForegroundColor White
        } else {
            Write-Host "   ❌ Windows Collector: $($service.Status)" -ForegroundColor Red
        }
        
        $summaryResults.Service = $serviceInfo
        return ($service.Status -eq "Running")
    }
    catch {
        Write-Host "   ❌ Service: $($_.Exception.Message)" -ForegroundColor Red
        $summaryResults.Service = @{
            Status = "Not Found"
            Error = $_.Exception.Message
        }
        return $false
    }
}

# Run all checks
Write-Host "Starting listener summary..." -ForegroundColor Gray
Write-Host ""

$configOK = Get-ReceiverInfo
Test-EndpointConnectivity
$signozOK = Get-SigNozMetrics
$serviceOK = Get-ServiceStatus

# Determine overall status
if ($configOK -and $signozOK -and $serviceOK) {
    $summaryResults.OverallStatus = "HEALTHY"
    Write-Host ""
    Write-Host "🎉 Overall Status: HEALTHY" -ForegroundColor Green
    $exitCode = 0
} else {
    $summaryResults.OverallStatus = "DEGRADED"
    Write-Host ""
    Write-Host "⚠️  Overall Status: DEGRADED" -ForegroundColor Yellow
    $exitCode = 1
}

# Export report if requested
if ($ExportReport) {
    $summaryResults.Duration = (Get-Date) - $startTime
    $summaryResults.EndTime = Get-Date
    
    if (-not (Test-Path "artifacts")) {
        New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
    }
    
    $summaryResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host ""
    Write-Host "📄 Listener summary exported to: $ReportPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "💡 Detailed health: pwsh -File scripts\otel-health.ps1" -ForegroundColor Blue
Write-Host "💡 Quick monitor: pwsh -File scripts\quick-monitor.ps1" -ForegroundColor Blue
Write-Host "💡 SigNoz UI: http://localhost:8080" -ForegroundColor Blue

exit $exitCode


