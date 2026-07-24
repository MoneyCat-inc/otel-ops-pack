# GPU Sidecar Setup Script
# Builds base image and validates GPU environment for OpenTelemetry sidecars

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

Write-Host "=== GPU Sidecar Setup ===" -ForegroundColor Green

function Write-Pass { param([string]$Message) Write-Host "   [OK] $Message" -ForegroundColor Green }
function Write-Detail { param([string]$Message) if ($Message) { Write-Host "      $Message" -ForegroundColor DarkGray } }
function Write-Fail { param([string]$Message) Write-Host "   [FAIL] $Message" -ForegroundColor Red }

# Check prerequisites
Write-Host "`n1. Checking Prerequisites:" -ForegroundColor Yellow

# Check NVIDIA driver
try {
    $nvidiaOutput = & nvidia-smi --query-gpu=name,driver_version --format=csv,noheader,nounits
    if ($nvidiaOutput) {
        $gpuInfo = $nvidiaOutput.Split(',')
        Write-Pass "NVIDIA GPU: $($gpuInfo[0].Trim())"
        Write-Detail "Driver: $($gpuInfo[1].Trim())"
    } else {
        Write-Fail "No GPU information available"
        exit 1
    }
} catch {
    Write-Fail "nvidia-smi not available: $($_.Exception.Message)"
    exit 1
}

# Check WSL2 GPU support
try {
    $wslNvidiaOutput = wsl.exe --distribution Ubuntu -- nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>&1
    if ($wslNvidiaOutput -and $wslNvidiaOutput -notmatch "error") {
        Write-Pass "WSL2 GPU support available"
    } else {
        Write-Fail "WSL2 GPU support not available: $wslNvidiaOutput"
        exit 1
    }
} catch {
    Write-Fail "WSL2 GPU check failed: $($_.Exception.Message)"
    exit 1
}

# Check Docker NVIDIA runtime
try {
    $dockerInfo = docker info --format "{{.Runtimes}}" 2>&1
    if ($dockerInfo -match "nvidia") {
        Write-Pass "Docker NVIDIA runtime available"
    } else {
        Write-Fail "Docker NVIDIA runtime not found"
        exit 1
    }
} catch {
    Write-Fail "Docker GPU runtime check failed: $($_.Exception.Message)"
    exit 1
}

# Create directories
Write-Host "`n2. Creating Directory Structure:" -ForegroundColor Yellow
$directories = @(
    "sidecars",
    "sidecars/compression",
    "sidecars/aggregation", 
    "sidecars/inference",
    "gpu-buffers",
    "gpu-buffers/logs",
    "gpu-buffers/traces",
    "gpu-buffers/compressed",
    "gpu-buffers/analytics",
    "gpu-buffers/inference"
)

foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Write-Detail "Directory exists: $dir"
    } else {
        try {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Pass "Created directory: $dir"
        } catch {
            Write-Fail "Failed to create directory $dir`: $($_.Exception.Message)"
        }
    }
}

# Build GPU base image
Write-Host "`n3. Building GPU Base Image:" -ForegroundColor Yellow
if (Test-Path "Dockerfile.gpu-base") {
    try {
        Write-Detail "Building otel-gpu-sidecar:latest..."
        $buildOutput = docker build -f Dockerfile.gpu-base -t otel-gpu-sidecar:latest . 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Pass "GPU base image built successfully"
        } else {
            Write-Fail "GPU base image build failed"
            $buildOutput | ForEach-Object { Write-Detail $_ }
            exit 1
        }
    } catch {
        Write-Fail "Docker build error: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Fail "Dockerfile.gpu-base not found"
    exit 1
}

# Test GPU base image
Write-Host "`n4. Testing GPU Base Image:" -ForegroundColor Yellow
try {
    $testOutput = docker run --rm --runtime=nvidia --gpus all otel-gpu-sidecar:latest python3 -c "import cudf, nvcomp; print('GPU libraries available')" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "GPU base image test passed"
        Write-Detail $testOutput
    } else {
        Write-Fail "GPU base image test failed"
        $testOutput | ForEach-Object { Write-Detail $_ }
    }
} catch {
    Write-Fail "GPU base image test error: $($_.Exception.Message)"
}

# Create GPU sidecar health check script
Write-Host "`n5. Creating Health Check Script:" -ForegroundColor Yellow
$healthCheckScript = @'
#!/usr/bin/env python3
"""GPU Sidecar Health Check Script"""

import sys
import requests
import json

def check_sidecar_health(port, name):
    """Check if a sidecar service is healthy"""
    try:
        response = requests.get(f"http://localhost:{port}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✓ {name} (port {port}): {data.get('status', 'unknown')}")
            if 'gpu_available' in data:
                print(f"  GPU available: {data['gpu_available']}")
            return True
        else:
            print(f"✗ {name} (port {port}): HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ {name} (port {port}): {e}")
        return False

def main():
    """Check all GPU sidecar services"""
    services = [
        (8001, "Compression Sidecar"),
        (8002, "Aggregation Sidecar"), 
        (8003, "Inference Sidecar")
    ]
    
    all_healthy = True
    for port, name in services:
        if not check_sidecar_health(port, name):
            all_healthy = False
    
    if all_healthy:
        print("\n✓ All GPU sidecar services are healthy")
        sys.exit(0)
    else:
        print("\n✗ Some GPU sidecar services are unhealthy")
        sys.exit(1)

if __name__ == "__main__":
    main()
'@

$healthCheckScript | Out-File -FilePath "scripts/check-gpu-sidecars.py" -Encoding UTF8
Write-Pass "Created GPU sidecar health check script"

# Create startup script for GPU sidecars
Write-Host "`n6. Creating Startup Script:" -ForegroundColor Yellow
$startupScript = @'
#!/usr/bin/env python3
"""Start GPU Sidecar Services"""

import subprocess
import sys
import time
import requests

def start_sidecar_service(service_name, port):
    """Start a GPU sidecar service"""
    print(f"Starting {service_name}...")
    try:
        # Start the service using docker-compose
        result = subprocess.run([
            "docker-compose", "-f", "compose/docker-compose.gpu.yml", "up", "-d", service_name
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✓ {service_name} started successfully")
            
            # Wait for health check
            for i in range(30):  # Wait up to 30 seconds
                try:
                    response = requests.get(f"http://localhost:{port}/health", timeout=2)
                    if response.status_code == 200:
                        print(f"✓ {service_name} is healthy")
                        return True
                except:
                    pass
                time.sleep(1)
            
            print(f"⚠ {service_name} started but health check failed")
            return False
        else:
            print(f"✗ Failed to start {service_name}: {result.stderr}")
            return False
    except Exception as e:
        print(f"✗ Error starting {service_name}: {e}")
        return False

def main():
    """Start all GPU sidecar services"""
    services = [
        ("gpu-compression-sidecar", 8001),
        ("gpu-aggregation-sidecar", 8002),
        ("gpu-inference-sidecar", 8003)
    ]
    
    all_started = True
    for service_name, port in services:
        if not start_sidecar_service(service_name, port):
            all_started = False
    
    if all_started:
        print("\n✓ All GPU sidecar services started successfully")
        print("\nNext steps:")
        print("1. Check service health: python scripts/check-gpu-sidecars.py")
        print("2. View logs: docker-compose -f compose/docker-compose.gpu.yml logs")
        print("3. Stop services: docker-compose -f compose/docker-compose.gpu.yml down")
    else:
        print("\n✗ Some GPU sidecar services failed to start")
        sys.exit(1)

if __name__ == "__main__":
    main()
'@

$startupScript | Out-File -FilePath "scripts/start-gpu-sidecars.py" -Encoding UTF8
Write-Pass "Created GPU sidecar startup script"

Write-Host "`n=== GPU Sidecar Setup Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Start GPU sidecars: python scripts/start-gpu-sidecars.py" -ForegroundColor Yellow
Write-Host "2. Check health: python scripts/check-gpu-sidecars.py" -ForegroundColor Yellow
Write-Host "3. Run integration test: .\verify-integration.ps1" -ForegroundColor Yellow
Write-Host "4. View SigNoz UI: http://localhost:8080" -ForegroundColor Yellow
