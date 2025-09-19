# OTel Management Script
# Start/stop collector, emit canaries, check status

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "stop", "restart", "status", "canary", "health")]
    [string]$Action = "status"
)

function Start-OTelCollector {
    Write-Host "🚀 Starting OTel Collector..." -ForegroundColor Cyan
    
    # Check if service is already running
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Write-Host "✅ OTel Collector service already running" -ForegroundColor Green
        return
    }
    
    # Start service
    try {
        Start-Service -Name "otelcol-contrib"
        Write-Host "✅ OTel Collector started successfully" -ForegroundColor Green
    } catch {
        Write-Error "Failed to start OTel Collector: $($_.Exception.Message)"
    }
}

function Stop-OTelCollector {
    Write-Host "🛑 Stopping OTel Collector..." -ForegroundColor Cyan
    
    try {
        Stop-Service -Name "otelcol-contrib"
        Write-Host "✅ OTel Collector stopped successfully" -ForegroundColor Green
    } catch {
        Write-Error "Failed to stop OTel Collector: $($_.Exception.Message)"
    }
}

function Get-OTelStatus {
    Write-Host "🔍 OTel Collector Status" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    
    # Check service status
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    if ($service) {
        $status = if ($service.Status -eq "Running") { "✅ Running" } else { "❌ Stopped" }
        $color = if ($service.Status -eq "Running") { "Green" } else { "Red" }
        Write-Host "Service: $status" -ForegroundColor $color
        Write-Host "Start Type: $($service.StartType)" -ForegroundColor White
    } else {
        Write-Host "Service: ❌ Not installed" -ForegroundColor Red
    }
    
    # Check ports
    Write-Host "`nPorts:" -ForegroundColor Cyan
    $ports = @(14317, 14318)
    foreach ($port in $ports) {
        $ok = Test-NetConnection -ComputerName "localhost" -Port $port -WarningAction SilentlyContinue
        $status = if ($ok.TcpTestSucceeded) { "✅ Listening" } else { "❌ Closed" }
        $color = if ($ok.TcpTestSucceeded) { "Green" } else { "Red" }
        Write-Host "  Port $port`: $status" -ForegroundColor $color
    }
    
    # Check SigNoz
    Write-Host "`nSigNoz:" -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5
        Write-Host "  Status: ✅ Accessible ($($response.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "  Status: ❌ Not accessible" -ForegroundColor Red
    }
}

function Send-OTelCanary {
    Write-Host "🧪 Sending OTLP canary..." -ForegroundColor Cyan
    
    $nowNs = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()*1000000)
    $body = @{
        resourceLogs = @(@{
            resource  = @{ attributes = @(@{ key="service.name"; value=@{ stringValue="otel-canary" }}) }
            scopeLogs = @(@{
                logRecords = @(@{
                    timeUnixNano = $nowNs
                    body = @{ stringValue = "OTel canary from $(hostname) $(Get-Date -Format o)" }
                    severityText = "INFO"
                })
            })
        })
    } | ConvertTo-Json -Depth 7

    try {
        $resp = Invoke-RestMethod -Method Post -Uri "http://localhost:14318/v1/logs" -ContentType "application/json" -Body $body
        Write-Host "✅ Canary sent successfully" -ForegroundColor Green
        Write-Host "📊 Check SigNoz for 'otel-canary' service logs" -ForegroundColor Yellow
    } catch { 
        Write-Host "❌ Canary failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-OTelHealth {
    Write-Host "🏥 OTel Health Check" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    
    # Test collector endpoint
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:14318/v1/logs" -Method Post -ContentType "application/json" -Body '{"test":"health"}' -TimeoutSec 5
        Write-Host "Collector HTTP: ✅ Responding" -ForegroundColor Green
    } catch {
        Write-Host "Collector HTTP: ❌ Not responding" -ForegroundColor Red
    }
    
    # Test SigNoz
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5
        Write-Host "SigNoz UI: ✅ Accessible" -ForegroundColor Green
    } catch {
        Write-Host "SigNoz UI: ❌ Not accessible" -ForegroundColor Red
    }
    
    # Send test canary
    Send-OTelCanary
}

# Main execution
switch ($Action) {
    "start" { Start-OTelCollector }
    "stop" { Stop-OTelCollector }
    "restart" { Stop-OTelCollector; Start-Sleep -Seconds 2; Start-OTelCollector }
    "status" { Get-OTelStatus }
    "canary" { Send-OTelCanary }
    "health" { Test-OTelHealth }
    default { Get-OTelStatus }
}

Write-Host "`n💡 Usage: .\scripts\otel.ps1 [start|stop|restart|status|canary|health]" -ForegroundColor Yellow



