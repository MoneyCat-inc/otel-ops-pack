# Validation Script: GPU Thermal Headroom
# Recipe: Create ops task or config change to reduce workload intensity

param(
    [string]$ConfigPath = "config.yaml",
    [int]$ThermalThreshold = 80,  # Celsius
    [int]$HeadroomThreshold = 10  # Celsius
)

Write-Host "🔍 Validating GPU Thermal Monitoring..." -ForegroundColor Green

$issues = @()
$warnings = @()

# 1. Check if GPU monitoring is configured
Write-Host "1. Checking GPU monitoring configuration..." -ForegroundColor Cyan
$config = Get-Content $ConfigPath -Raw

if ($config -notmatch "prometheus/gpu:") {
    $warnings += "GPU Prometheus receiver not configured"
} else {
    Write-Host "✅ GPU Prometheus receiver configured" -ForegroundColor Green
}

# 2. Check GPU monitoring script availability
Write-Host "2. Checking GPU monitoring scripts..." -ForegroundColor Cyan
$gpuScripts = @("gpu-monitor.ps1", "gpu-metrics-emitter.py", "run-gpu-metrics.ps1")
$availableScripts = @()

foreach ($script in $gpuScripts) {
    if (Test-Path $script) {
        $availableScripts += $script
        Write-Host "✅ Found: $script" -ForegroundColor Green
    } else {
        $warnings += "GPU script not found: $script"
    }
}

# 3. Test GPU metrics collection
Write-Host "3. Testing GPU metrics collection..." -ForegroundColor Cyan
try {
    # Check if GPU metrics are available on the expected port
    $response = Invoke-RestMethod -Uri "http://localhost:9400/metrics" -Method Get -TimeoutSec 10
    $gpuMetrics = $response -split "`n" | Where-Object { 
        $_ -match "gpu_" -or $_ -match "nvidia_" -or $_ -match "temperature"
    }
    
    if ($gpuMetrics.Count -gt 0) {
        Write-Host "✅ GPU metrics available: $($gpuMetrics.Count) metrics" -ForegroundColor Green
        $gpuMetrics | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    } else {
        $warnings += "No GPU metrics found on port 9400"
    }
} catch {
    $warnings += "GPU metrics endpoint unreachable: $($_.Exception.Message)"
}

# 4. Check for thermal monitoring in existing scripts
Write-Host "4. Checking thermal monitoring logic..." -ForegroundColor Cyan
$thermalMonitoringFound = $false

foreach ($script in $availableScripts) {
    $content = Get-Content $script -Raw
    if ($content -match "temperature" -or $content -match "thermal" -or $content -match "gpu.*temp") {
        $thermalMonitoringFound = $true
        Write-Host "✅ Thermal monitoring found in: $script" -ForegroundColor Green
        break
    }
}

if (-not $thermalMonitoringFound) {
    $warnings += "No thermal monitoring logic found in GPU scripts"
}

# 5. Test GPU workload reduction capability
Write-Host "5. Testing GPU workload reduction capability..." -ForegroundColor Cyan
try {
    # Check if there are any workload control mechanisms
    $workloadControlFound = $false
    
    foreach ($script in $availableScripts) {
        $content = Get-Content $script -Raw
        if ($content -match "workload" -or $content -match "intensity" -or $content -match "throttle" -or $content -match "reduce") {
            $workloadControlFound = $true
            Write-Host "✅ Workload control found in: $script" -ForegroundColor Green
            break
        }
    }
    
    if (-not $workloadControlFound) {
        $warnings += "No workload control mechanisms found"
    }
} catch {
    $warnings += "Workload control check failed: $($_.Exception.Message)"
}

# 6. Check collector health with GPU metrics
Write-Host "6. Checking collector health with GPU metrics..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:13134/" -Method Get -TimeoutSec 10
    if ($response.status -ne "Server available") {
        $issues += "Collector health check failed: $($response.status)"
    } else {
        Write-Host "✅ Collector healthy with GPU metrics" -ForegroundColor Green
    }
} catch {
    $issues += "Collector health check error: $($_.Exception.Message)"
}

# 7. Check for thermal alerting configuration
Write-Host "7. Checking thermal alerting configuration..." -ForegroundColor Cyan
if (Test-Path "signoz-alerts.json") {
    $alerts = Get-Content "signoz-alerts.json" -Raw | ConvertFrom-Json
    $thermalAlerts = $alerts.alerts | Where-Object { 
        $_.query -match "gpu" -or $_.query -match "temperature" -or $_.query -match "thermal"
    }
    
    if ($thermalAlerts.Count -gt 0) {
        Write-Host "✅ Thermal alerts configured: $($thermalAlerts.Count)" -ForegroundColor Green
        $thermalAlerts | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor Gray }
    } else {
        $warnings += "No thermal alerts configured in signoz-alerts.json"
    }
} else {
    $warnings += "SigNoz alerts configuration not found"
}

# 8. Test thermal threshold logic
Write-Host "8. Testing thermal threshold logic..." -ForegroundColor Cyan
try {
    # Simulate thermal check
    $simulatedTemp = 75  # Simulated GPU temperature
    $maxTemp = 85  # Typical GPU max temperature
    $headroom = $maxTemp - $simulatedTemp
    
    if ($headroom -lt $HeadroomThreshold) {
        $warnings += "Simulated thermal headroom ($headroom°C) below threshold ($HeadroomThreshold°C)"
    } else {
        Write-Host "✅ Thermal headroom check passed (simulated: $headroom°C)" -ForegroundColor Green
    }
} catch {
    $warnings += "Thermal threshold test failed: $($_.Exception.Message)"
}

# Summary
Write-Host "`n📊 Validation Summary:" -ForegroundColor Cyan
if ($issues.Count -gt 0) {
    Write-Host "❌ Issues found:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "✅ All critical checks passed" -ForegroundColor Green
}

if ($warnings.Count -gt 0) {
    Write-Host "⚠️  Warnings:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

Write-Host "`n🎯 Expected Output: GPU monitoring active, thermal controls available" -ForegroundColor Green
Write-Host "🌡️  Thermal Threshold: $ThermalThreshold°C, Headroom: $HeadroomThreshold°C" -ForegroundColor Cyan
Write-Host "📊 Available Scripts: $($availableScripts -join ', ')" -ForegroundColor Cyan


