# Simple Health Check Script
Write-Host "=== Windows Collector + SigNoz Health Check ===" -ForegroundColor Cyan

# Check Windows Collector Service
Write-Host "`n1. Checking Windows Collector Service..." -ForegroundColor Yellow
try {
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction Stop
    Write-Host "   Service Status: $($service.Status)" -ForegroundColor Green
    Write-Host "   Service Name: $($service.Name)" -ForegroundColor White
    if ($service.Status -eq "Running") {
        Write-Host "   ✓ Windows Collector is RUNNING" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Windows Collector is NOT running" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ Service not found or error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check Config File
Write-Host "`n2. Checking Configuration File..." -ForegroundColor Yellow
$configPath = "C:\otel\config.yaml"
if (Test-Path $configPath) {
    $configInfo = Get-Item $configPath
    Write-Host "   Config File: $($configInfo.FullName)" -ForegroundColor White
    Write-Host "   Last Modified: $($configInfo.LastWriteTime)" -ForegroundColor White
    
    # Check for correct endpoint
    $endpointLine = Select-String -Path $configPath -Pattern "endpoint: 127.0.0.1:14318" -Quiet
    if ($endpointLine) {
        Write-Host "   ✓ Exporter endpoint correctly set to 127.0.0.1:14318" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Exporter endpoint not found or incorrect" -ForegroundColor Red
    }
} else {
    Write-Host "   ✗ Config file not found at $configPath" -ForegroundColor Red
}

# Check Docker Context
Write-Host "`n3. Checking Docker Context..." -ForegroundColor Yellow
try {
    $dockerContext = docker context ls --format "{{.Name}}" | Select-String "desktop-linux"
    if ($dockerContext) {
        Write-Host "   ✓ Docker context 'desktop-linux' found" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ Docker context 'desktop-linux' not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ✗ Docker not available or error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check SigNoz Containers
Write-Host "`n4. Checking SigNoz Containers..." -ForegroundColor Yellow
try {
    $containers = docker --context desktop-linux ps --format "{{.Names}}|{{.Status}}|{{.Ports}}" 2>$null
    if ($containers) {
        Write-Host "   Container Status:" -ForegroundColor White
        $containers | ForEach-Object {
            $parts = $_ -split '\|'
            $name = $parts[0]
            $status = $parts[1]
            $ports = $parts[2]
            Write-Host "     $name : $status" -ForegroundColor White
            if ($ports -like "*14317*" -or $ports -like "*14318*") {
                Write-Host "       Ports: $ports" -ForegroundColor Green
            }
        }
        
        # Check for collector specifically
        $collector = $containers | Where-Object { $_ -like "*collector*" }
        if ($collector) {
            Write-Host "   ✓ SigNoz collector container found" -ForegroundColor Green
        } else {
            Write-Host "   ✗ SigNoz collector container not found" -ForegroundColor Red
        }
    } else {
        Write-Host "   ✗ No containers found or Docker error" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ Error checking containers: $($_.Exception.Message)" -ForegroundColor Red
}

# Check SigNoz UI
Write-Host "`n5. Checking SigNoz UI..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✓ SigNoz UI is accessible at http://localhost:8080" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ SigNoz UI returned status: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ✗ SigNoz UI not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Health Check Complete ===" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. If all checks pass, run: pwsh -Command canary" -ForegroundColor White
Write-Host "2. Check SigNoz UI: http://localhost:8080" -ForegroundColor White
Write-Host "3. Filter logs: message contains 'SigNoz test error'" -ForegroundColor White
