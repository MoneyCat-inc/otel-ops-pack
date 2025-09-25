# Simple collector status test
Write-Host "Testing OTel Collector Status" -ForegroundColor Green

try {
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction Stop
    Write-Host "Service Status: $($service.Status)" -ForegroundColor Green
    
    if ($service.Status -eq "Running") {
        Write-Host "✓ Collector service is running" -ForegroundColor Green
    } else {
        Write-Host "✗ Collector service is not running" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Cannot check service status: $($_.Exception.Message)" -ForegroundColor Red
}

# Check ports
try {
    $port5317 = Test-NetConnection -ComputerName localhost -Port 5317 -InformationLevel Quiet -WarningAction SilentlyContinue
    $port5318 = Test-NetConnection -ComputerName localhost -Port 5318 -InformationLevel Quiet -WarningAction SilentlyContinue
    
    Write-Host "Port 5317 (gRPC): $(if($port5317) {'✓ Listening'} else {'✗ Not listening'})" -ForegroundColor $(if($port5317) {'Green'} else {'Red'})
    Write-Host "Port 5318 (HTTP): $(if($port5318) {'✓ Listening'} else {'✗ Not listening'})" -ForegroundColor $(if($port5318) {'Green'} else {'Red'})
} catch {
    Write-Host "✗ Cannot check ports: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Test complete" -ForegroundColor Cyan
