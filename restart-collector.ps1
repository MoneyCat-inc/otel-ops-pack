# Restart Windows OTel Collector (requires elevated privileges)
# This script must be run as Administrator

Write-Host "Restarting Windows OTel Collector..." -ForegroundColor Green

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Stop the service
Write-Host "Stopping otelcol-contrib service..." -ForegroundColor Yellow
try {
    Stop-Service -Name "otelcol-contrib" -Force
    Start-Sleep -Seconds 3
    Write-Host "Service stopped successfully" -ForegroundColor Green
} catch {
    Write-Host "Error stopping service: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Start the service
Write-Host "Starting otelcol-contrib service..." -ForegroundColor Yellow
try {
    Start-Service -Name "otelcol-contrib"
    Start-Sleep -Seconds 5
    Write-Host "Service started successfully" -ForegroundColor Green
} catch {
    Write-Host "Error starting service: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify service status
Write-Host "Verifying service status..." -ForegroundColor Yellow
$service = Get-Service -Name "otelcol-contrib"
if ($service.Status -eq "Running") {
    Write-Host "Service is running successfully" -ForegroundColor Green
} else {
    Write-Host "Service status: $($service.Status)" -ForegroundColor Red
    exit 1
}

# Check if ports are listening
Write-Host "Checking OTLP ports..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

$port5317 = Test-NetConnection -ComputerName localhost -Port 5317 -InformationLevel Quiet -WarningAction SilentlyContinue
$port5318 = Test-NetConnection -ComputerName localhost -Port 5318 -InformationLevel Quiet -WarningAction SilentlyContinue

if ($port5317) {
    Write-Host "Port 5317 (gRPC) is listening" -ForegroundColor Green
} else {
    Write-Host "Port 5317 (gRPC) is not listening" -ForegroundColor Red
}

if ($port5318) {
    Write-Host "Port 5318 (HTTP) is listening" -ForegroundColor Green
} else {
    Write-Host "Port 5318 (HTTP) is not listening" -ForegroundColor Red
}

Write-Host "`nCollector restart complete!" -ForegroundColor Green
Write-Host "Run verify-integration.ps1 to test the integration" -ForegroundColor Yellow


