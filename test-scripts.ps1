# Test Scripts Functionality
Write-Host "Testing Scripts..." -ForegroundColor Green

# Test 1: Check if our files exist
$files = @(
    "config.yaml",
    "docker-compose.yml", 
    "verify-integration.ps1",
    "startup-observability.ps1"
)

Write-Host "Checking files..." -ForegroundColor Cyan
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  ✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file missing" -ForegroundColor Red
    }
}

# Test 2: Check config.yaml syntax
Write-Host "`nChecking config.yaml..." -ForegroundColor Cyan
try {
    $config = Get-Content "config.yaml" -Raw
    if ($config -match "receivers:" -and $config -match "exporters:" -and $config -match "service:") {
        Write-Host "  ✅ config.yaml structure looks good" -ForegroundColor Green
    } else {
        Write-Host "  ❌ config.yaml structure incomplete" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Error reading config.yaml" -ForegroundColor Red
}

# Test 3: Check docker-compose.yml
Write-Host "`nChecking docker-compose.yml..." -ForegroundColor Cyan
try {
    $compose = Get-Content "docker-compose.yml" -Raw
    if ($compose -match "services:" -and $compose -match "signoz:" -and $compose -match "clickhouse:") {
        Write-Host "  ✅ docker-compose.yml structure looks good" -ForegroundColor Green
    } else {
        Write-Host "  ❌ docker-compose.yml structure incomplete" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Error reading docker-compose.yml" -ForegroundColor Red
}

Write-Host "`nScript test complete!" -ForegroundColor Green


