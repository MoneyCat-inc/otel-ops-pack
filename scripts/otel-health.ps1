# OTel Health Check - Comprehensive Collector Status
# Checks Windows Collector service, endpoints, and SigNoz connectivity

param(
    [switch]$ExportReport = $false,
    [string]$ReportPath = "artifacts\otel-health-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

$ErrorActionPreference = 'Stop'
$startTime = Get-Date

Write-Host "🔍 OTel Health Check" -ForegroundColor Cyan
Write-Host "Checking collector service, endpoints, and pipeline connectivity" -ForegroundColor Gray
Write-Host ""

$healthResults = @{
    Timestamp = $startTime
    Components = @{}
    OverallStatus = "UNKNOWN"
    Checks = @()
}

# Check Windows Collector Service
function Test-CollectorService {
    Write-Host "📋 Windows Collector Service:" -ForegroundColor Cyan
    try {
        $service = Get-Service -Name "otelcol-contrib" -ErrorAction Stop
        if ($service.Status -eq "Running") {
            Write-Host "   ✅ Status: $($service.Status)" -ForegroundColor Green
            Write-Host "   📊 Start Type: $($service.StartType)" -ForegroundColor White
            Write-Host "   🕒 Started: $($service.StartTime)" -ForegroundColor White
            
            $healthResults.Components.CollectorService = @{
                Status = "Running"
                StartType = $service.StartType
                StartTime = $service.StartTime
                Color = "Green"
            }
            return $true
        } else {
            Write-Host "   ❌ Status: $($service.Status)" -ForegroundColor Red
            $healthResults.Components.CollectorService = @{
                Status = $service.Status
                Color = "Red"
            }
            return $false
        }
    }
    catch {
        Write-Host "   ❌ Service not found or error: $($_.Exception.Message)" -ForegroundColor Red
        $healthResults.Components.CollectorService = @{
            Status = "Not Found"
            Error = $_.Exception.Message
            Color = "Red"
        }
        return $false
    }
}

# Check OTLP Endpoints
function Test-OTLPEndpoints {
    Write-Host ""
    Write-Host "🌐 OTLP Endpoints:" -ForegroundColor Cyan
    
    $endpoints = @(
        @{ Name = "HTTP OTLP"; Port = 5318; Protocol = "HTTP" },
        @{ Name = "gRPC OTLP"; Port = 5317; Protocol = "TCP" }
    )
    
    $endpointResults = @{}
    $allEndpointsOK = $true
    
    foreach ($endpoint in $endpoints) {
        try {
            if ($endpoint.Protocol -eq "HTTP") {
                # Test HTTP endpoint
                $response = Invoke-WebRequest -Uri "http://localhost:$($endpoint.Port)" -Method Get -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
                if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 404) {
                    Write-Host "   ✅ $($endpoint.Name): Port $($endpoint.Port) responding" -ForegroundColor Green
                    $endpointResults[$endpoint.Name] = @{ Status = "OK"; Color = "Green" }
                } else {
                    Write-Host "   ⚠️  $($endpoint.Name): Port $($endpoint.Port) returned $($response.StatusCode)" -ForegroundColor Yellow
                    $endpointResults[$endpoint.Name] = @{ Status = "Unexpected Response"; Color = "Yellow" }
                    $allEndpointsOK = $false
                }
            } else {
                # Test TCP port availability
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $result = $tcpClient.BeginConnect("localhost", $endpoint.Port, $null, $null)
                $success = $result.AsyncWaitHandle.WaitOne(3000, $false)
                
                if ($success -and $tcpClient.Connected) {
                    Write-Host "   ✅ $($endpoint.Name): Port $($endpoint.Port) open" -ForegroundColor Green
                    $endpointResults[$endpoint.Name] = @{ Status = "OK"; Color = "Green" }
                    $tcpClient.Close()
                } else {
                    Write-Host "   ❌ $($endpoint.Name): Port $($endpoint.Port) not responding" -ForegroundColor Red
                    $endpointResults[$endpoint.Name] = @{ Status = "Not Responding"; Color = "Red" }
                    $allEndpointsOK = $false
                }
            }
        }
        catch {
            Write-Host "   ❌ $($endpoint.Name): $($_.Exception.Message)" -ForegroundColor Red
            $endpointResults[$endpoint.Name] = @{ Status = "Error"; Error = $_.Exception.Message; Color = "Red" }
            $allEndpointsOK = $false
        }
    }
    
    $healthResults.Components.OTLPEndpoints = $endpointResults
    return $allEndpointsOK
}

# Check SigNoz Connectivity
function Test-SigNozConnectivity {
    Write-Host ""
    Write-Host "📊 SigNoz Connectivity:" -ForegroundColor Cyan
    
    try {
        # Test SigNoz health endpoint
        $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 5 -ErrorAction Stop
        Write-Host "   ✅ Health API: Responding" -ForegroundColor Green
        
        # Test version endpoint
        $versionResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/version" -Method Get -TimeoutSec 5 -ErrorAction Stop
        Write-Host "   ✅ Version API: $($versionResponse.version)" -ForegroundColor Green
        
        # Test UI accessibility
        $uiResponse = Invoke-WebRequest -Uri "http://localhost:8080" -Method Get -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        Write-Host "   ✅ UI: Accessible (Status: $($uiResponse.StatusCode))" -ForegroundColor Green
        
        $healthResults.Components.SigNoz = @{
            Health = "OK"
            Version = $versionResponse.version
            UIStatus = $uiResponse.StatusCode
            Color = "Green"
        }
        return $true
    }
    catch {
        Write-Host "   ❌ SigNoz: $($_.Exception.Message)" -ForegroundColor Red
        $healthResults.Components.SigNoz = @{
            Status = "Error"
            Error = $_.Exception.Message
            Color = "Red"
        }
        return $false
    }
}

# Check Configuration
function Test-Configuration {
    Write-Host ""
    Write-Host "⚙️  Configuration:" -ForegroundColor Cyan
    
    $configPath = "C:\otel\config.yaml"
    if (Test-Path $configPath) {
        Write-Host "   ✅ Config file: $configPath exists" -ForegroundColor Green
        
        try {
            # Basic YAML validation (check for key sections)
            $configContent = Get-Content $configPath -Raw
            $hasReceivers = $configContent -match "receivers:"
            $hasProcessors = $configContent -match "processors:"
            $hasExporters = $configContent -match "exporters:"
            
            if ($hasReceivers -and $hasProcessors -and $hasExporters) {
                Write-Host "   ✅ Config structure: Valid (has receivers, processors, exporters)" -ForegroundColor Green
                $healthResults.Components.Configuration = @{ Status = "Valid"; Color = "Green" }
                return $true
            } else {
                Write-Host "   ⚠️  Config structure: Missing key sections" -ForegroundColor Yellow
                $healthResults.Components.Configuration = @{ Status = "Incomplete"; Color = "Yellow" }
                return $false
            }
        }
        catch {
            Write-Host "   ❌ Config validation: $($_.Exception.Message)" -ForegroundColor Red
            $healthResults.Components.Configuration = @{ Status = "Error"; Error = $_.Exception.Message; Color = "Red" }
            return $false
        }
    } else {
        Write-Host "   ❌ Config file: $configPath not found" -ForegroundColor Red
        $healthResults.Components.Configuration = @{ Status = "Missing"; Color = "Red" }
        return $false
    }
}

# Run all health checks
Write-Host "Starting OTel health check..." -ForegroundColor Gray
Write-Host ""

$serviceOK = Test-CollectorService
$endpointsOK = Test-OTLPEndpoints
$signozOK = Test-SigNozConnectivity
$configOK = Test-Configuration

# Determine overall status
if ($serviceOK -and $endpointsOK -and $signozOK -and $configOK) {
    $healthResults.OverallStatus = "HEALTHY"
    Write-Host ""
    Write-Host "🎉 Overall Status: HEALTHY" -ForegroundColor Green
    $exitCode = 0
} else {
    $healthResults.OverallStatus = "DEGRADED"
    Write-Host ""
    Write-Host "⚠️  Overall Status: DEGRADED" -ForegroundColor Yellow
    $exitCode = 1
}

# Export report if requested
if ($ExportReport) {
    $healthResults.Duration = (Get-Date) - $startTime
    $healthResults.EndTime = Get-Date
    
    if (-not (Test-Path "artifacts")) {
        New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
    }
    
    $healthResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host ""
    Write-Host "📄 Health report exported to: $ReportPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "💡 Quick status: pwsh -File scripts\quick-monitor.ps1" -ForegroundColor Blue
Write-Host "💡 SigNoz UI: http://localhost:8080" -ForegroundColor Blue

exit $exitCode


