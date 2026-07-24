# HISTORICAL (Gate-era): ports 5317/5318 predate the 5320/5321 move. Do not use as reference. See windows/otelcol/README.md.
# Simple environment test script
Write-Host "=== Environment Test ===" -ForegroundColor Green
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
Write-Host "Execution policy: $(Get-ExecutionPolicy)" -ForegroundColor Yellow

# Test file operations
Write-Host "`nTesting file operations..." -ForegroundColor Green
if (Test-Path "config.yaml") {
    Write-Host "✓ config.yaml exists" -ForegroundColor Green
} else {
    Write-Host "✗ config.yaml not found" -ForegroundColor Red
}

if (Test-Path "scripts") {
    Write-Host "✓ scripts directory exists" -ForegroundColor Green
} else {
    Write-Host "✗ scripts directory not found" -ForegroundColor Red
}

# Test service status
Write-Host "`nTesting service status..." -ForegroundColor Green
try {
    $service = Get-Service otelcol-contrib -ErrorAction Stop
    Write-Host "✓ otelcol-contrib service: $($service.Status)" -ForegroundColor Green
} catch {
    Write-Host "✗ otelcol-contrib service error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test port connectivity
Write-Host "`nTesting port connectivity..." -ForegroundColor Green
$ports = @(5317, 5318, 4317, 8080)
foreach ($port in $ports) {
    try {
        $result = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
        if ($result.TcpTestSucceeded) {
            Write-Host "✓ Port $port is open" -ForegroundColor Green
        } else {
            Write-Host "✗ Port $port is closed" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Port $port test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nEnvironment test completed!" -ForegroundColor Green
