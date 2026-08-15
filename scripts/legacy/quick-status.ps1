Import-Module (Join-Path $PSScriptRoot '..\..\BRAV\SCPT\lib\OtelPorts.psm1') -Force
$script:OtelPorts = Get-OtelPorts

# Quick Status Check
Write-Host "=== Quick Status Check ===" -ForegroundColor Cyan

# Check Docker
Write-Host "Docker:" -ForegroundColor Yellow
try {
    $null = docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Docker available" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Docker not available" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Docker not found" -ForegroundColor Red
}

# Check Windows Collector
Write-Host "Windows Collector:" -ForegroundColor Yellow
$service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "  ✅ Service installed (Status: $($service.Status))" -ForegroundColor Green
} else {
    Write-Host "  ❌ Service not installed" -ForegroundColor Red
}

# Check ports
Write-Host "Ports:" -ForegroundColor Yellow
$ports = @(
    $script:OtelPorts.IngestGrpc,
    $script:OtelPorts.IngestHttp,
    $script:OtelPorts.SignozOtlpGrpc,
    $script:OtelPorts.SignozOtlpHttp,
    $script:OtelPorts.SignozUiHttp,
    8888,
    13134
)
foreach ($port in $ports) {
    $ok = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
    $status = if ($ok) { "✅" } else { "❌" }
    $color = if ($ok) { "Green" } else { "Red" }
    Write-Host "  $status Port $port" -ForegroundColor $color
}

Write-Host "=== Status Complete ===" -ForegroundColor Cyan
