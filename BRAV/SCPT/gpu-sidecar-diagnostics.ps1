# GPU Sidecar Diagnostics Script
# Collects diagnostic information for GPU sidecar containers

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$outputFile = "CHAR\EVID\diagnostics\gpu-sidecars-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"

Write-Host "🐾 BossCat GPU Sidecar Diagnostics" -ForegroundColor Cyan
Write-Host "Timestamp: $timestamp" -ForegroundColor Gray
Write-Host ""

# Ensure output directory exists
New-Item -ItemType Directory -Force -Path "CHAR\EVID\diagnostics" | Out-Null

# Start output file
@"
GPU Sidecar Diagnostics Report
Generated: $timestamp
===============================================

"@ | Set-Content -Path $outputFile -Encoding UTF8

# GPU Sidecar containers to check
$sidecars = @(
    'otel-gpu-aggregation',
    'otel-gpu-compression',
    'otel-gpu-inference'
)

# Check if Docker is available
Write-Host "[1/5] Checking Docker availability..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>&1
    Write-Host "  ✅ Docker: $dockerVersion" -ForegroundColor Green
    "Docker Version: $dockerVersion`n" | Add-Content -Path $outputFile -Encoding UTF8
} catch {
    Write-Host "  ❌ Docker not available: $_" -ForegroundColor Red
    "ERROR: Docker not available - $_`n" | Add-Content -Path $outputFile -Encoding UTF8
    Write-Host ""
    Write-Host "Diagnostics incomplete - Docker required" -ForegroundColor Red
    return
}

# Check each sidecar
Write-Host "[2/5] Checking sidecar containers..." -ForegroundColor Yellow
foreach ($container in $sidecars) {
    "==============================================`n" | Add-Content -Path $outputFile -Encoding UTF8
    "Container: $container`n" | Add-Content -Path $outputFile -Encoding UTF8
    "----------------------------------------------`n" | Add-Content -Path $outputFile -Encoding UTF8
    
    Write-Host "  Checking $container..." -ForegroundColor Cyan
    
    # Check if container exists
    $exists = docker ps -a --filter "name=$container" --format "{{.Names}}" 2>$null
    if (-not $exists) {
        Write-Host "    ⚠️  Container not found" -ForegroundColor Yellow
        "Status: NOT FOUND`n`n" | Add-Content -Path $outputFile -Encoding UTF8
        continue
    }
    
    # Get container status
    try {
        $status = docker ps --filter "name=$container" --format "{{.Status}}" 2>$null
        if ($status) {
            Write-Host "    ✅ Status: $status" -ForegroundColor Green
            "Status: $status`n" | Add-Content -Path $outputFile -Encoding UTF8
        } else {
            Write-Host "    ❌ Container stopped" -ForegroundColor Red
            "Status: STOPPED`n" | Add-Content -Path $outputFile -Encoding UTF8
        }
        
        # Get restart count
        $restartCount = docker inspect -f '{{.RestartCount}}' $container 2>$null
        if ($restartCount) {
            Write-Host "    📊 Restart count: $restartCount" -ForegroundColor $(if ([int]$restartCount -gt 5) { 'Yellow' } else { 'Gray' })
            "Restart Count: $restartCount`n" | Add-Content -Path $outputFile -Encoding UTF8
        }
    } catch {
        Write-Host "    ⚠️  Error getting status: $_" -ForegroundColor Yellow
    }
    
    # Get last 200 lines of logs
    try {
        Write-Host "    📝 Collecting logs (last 200 lines)..." -ForegroundColor Gray
        "`nLast 200 Log Lines:" | Add-Content -Path $outputFile -Encoding UTF8
        "----------------------------------------------`n" | Add-Content -Path $outputFile -Encoding UTF8
        $logs = docker logs --tail 200 $container 2>&1
        $logs | Add-Content -Path $outputFile -Encoding UTF8
        "`n" | Add-Content -Path $outputFile -Encoding UTF8
    } catch {
        Write-Host "    ⚠️  Error collecting logs: $_" -ForegroundColor Yellow
        "ERROR collecting logs: $_`n`n" | Add-Content -Path $outputFile -Encoding UTF8
    }
}

# Check NVIDIA runtime
Write-Host "[3/5] Checking NVIDIA runtime..." -ForegroundColor Yellow
try {
    $dockerInfo = docker info 2>&1 | Select-String -Pattern "nvidia|runtime" -CaseSensitive:$false
    if ($dockerInfo) {
        Write-Host "  ✅ NVIDIA runtime detected" -ForegroundColor Green
        "`n==============================================`n" | Add-Content -Path $outputFile -Encoding UTF8
        "NVIDIA Runtime Information`n" | Add-Content -Path $outputFile -Encoding UTF8
        "----------------------------------------------`n" | Add-Content -Path $outputFile -Encoding UTF8
        $dockerInfo | ForEach-Object { $_.Line } | Add-Content -Path $outputFile -Encoding UTF8
    } else {
        Write-Host "  ⚠️  NVIDIA runtime not detected in Docker info" -ForegroundColor Yellow
        "`nNVIDIA Runtime: NOT DETECTED`n" | Add-Content -Path $outputFile -Encoding UTF8
    }
} catch {
    Write-Host "  ⚠️  Error checking NVIDIA runtime: $_" -ForegroundColor Yellow
}

# Check nvidia-smi
Write-Host "[4/5] Checking nvidia-smi..." -ForegroundColor Yellow
try {
    if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
        $gpuInfo = nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>$null
        if ($gpuInfo) {
            Write-Host "  ✅ GPU detected: $($gpuInfo -split ',')[0]" -ForegroundColor Green
            "`n==============================================`n" | Add-Content -Path $outputFile -Encoding UTF8
            "GPU Information (nvidia-smi)`n" | Add-Content -Path $outputFile -Encoding UTF8
            "----------------------------------------------`n" | Add-Content -Path $outputFile -Encoding UTF8
            $gpuInfo | Add-Content -Path $outputFile -Encoding UTF8
            "`n" | Add-Content -Path $outputFile -Encoding UTF8
        }
    } else {
        Write-Host "  ⚠️  nvidia-smi not found" -ForegroundColor Yellow
        "`nnvidia-smi: NOT FOUND`n" | Add-Content -Path $outputFile -Encoding UTF8
    }
} catch {
    Write-Host "  ⚠️  Error checking GPU: $_" -ForegroundColor Yellow
}

# Summary
Write-Host "[5/5] Generating summary..." -ForegroundColor Yellow
"`n==============================================`n" | Add-Content -Path $outputFile -Encoding UTF8
"Diagnostic Summary`n" | Add-Content -Path $outputFile -Encoding UTF8
"----------------------------------------------`n" | Add-Content -Path $outputFile -Encoding UTF8
"Containers checked: $($sidecars.Count)`n" | Add-Content -Path $outputFile -Encoding UTF8
"Report generated: $timestamp`n" | Add-Content -Path $outputFile -Encoding UTF8
"`nEnd of Report`n" | Add-Content -Path $outputFile -Encoding UTF8

Write-Host ""
Write-Host "✅ Diagnostics complete" -ForegroundColor Green
Write-Host "   Output: $outputFile" -ForegroundColor Gray
Write-Host ""
Write-Host "Common fixes if containers are restarting:" -ForegroundColor Cyan
Write-Host "  1. Check GPU driver compatibility" -ForegroundColor Gray
Write-Host "  2. Verify nvidia-container-toolkit installation" -ForegroundColor Gray
Write-Host "  3. Check docker-compose.yml GPU device mapping" -ForegroundColor Gray
Write-Host "  4. Review logs for config/mount path errors" -ForegroundColor Gray

