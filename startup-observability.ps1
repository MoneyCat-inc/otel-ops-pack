# Complete Observability Stack Startup Script
# Handles Docker Desktop, SigNoz, and Windows Collector setup

param(
    [switch]$SkipDocker,
    [switch]$SkipCollector,
    [switch]$Force
)

Write-Host "🚀 Starting Complete Observability Stack..." -ForegroundColor Green

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-DockerDesktop {
    Write-Host "🐳 Checking Docker Desktop..." -ForegroundColor Cyan
    
    # Check if Docker is already running
    try {
        $null = docker ps 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker is already running" -ForegroundColor Green
            return $true
        }
    } catch {
        # Docker not running
    }
    
    # Try to start Docker Desktop
    $dockerPaths = @(
        "C:\Program Files\Docker\Docker\Docker Desktop.exe",
        "C:\Program Files (x86)\Docker\Docker\Docker Desktop.exe",
        "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
    )
    
    foreach ($path in $dockerPaths) {
        if (Test-Path $path) {
            Write-Host "🔄 Starting Docker Desktop from $path..." -ForegroundColor Yellow
            Start-Process -FilePath $path -WindowStyle Hidden
            Write-Host "⏳ Waiting for Docker Desktop to start..." -ForegroundColor Yellow
            
            # Wait up to 2 minutes for Docker to start
            $timeout = 120
            $elapsed = 0
            while ($elapsed -lt $timeout) {
                try {
                    $null = docker ps 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "✅ Docker Desktop started successfully" -ForegroundColor Green
                        return $true
                    }
                } catch {
                    # Still starting
                }
                Start-Sleep -Seconds 5
                $elapsed += 5
                Write-Host "." -NoNewline -ForegroundColor Yellow
            }
            Write-Host "`n⚠️  Docker Desktop may still be starting up" -ForegroundColor Yellow
            return $false
        }
    }
    
    Write-Host "❌ Docker Desktop not found. Please install Docker Desktop first." -ForegroundColor Red
    Write-Host "Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    return $false
}

function Start-SigNozStack {
    Write-Host "📊 Starting SigNoz Stack..." -ForegroundColor Cyan
    
    if (-not (Test-Path "docker-compose.yml")) {
        Write-Host "❌ docker-compose.yml not found" -ForegroundColor Red
        return $false
    }
    
    try {
        Write-Host "🔄 Starting SigNoz containers..." -ForegroundColor Yellow
        docker-compose up -d
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ SigNoz stack started successfully" -ForegroundColor Green
            
            # Wait for services to be ready
            Write-Host "⏳ Waiting for SigNoz UI to be ready..." -ForegroundColor Yellow
            $timeout = 60
            $elapsed = 0
            while ($elapsed -lt $timeout) {
                try {
                    $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5
                    if ($response.StatusCode -eq 200) {
                        Write-Host "✅ SigNoz UI is ready" -ForegroundColor Green
                        return $true
                    }
                } catch {
                    # Still starting
                }
                Start-Sleep -Seconds 5
                $elapsed += 5
                Write-Host "." -NoNewline -ForegroundColor Yellow
            }
            Write-Host "`n⚠️  SigNoz may still be starting up" -ForegroundColor Yellow
            return $false
        } else {
            Write-Host "❌ Failed to start SigNoz stack" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Error starting SigNoz: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-WindowsCollector {
    Write-Host "🔧 Installing Windows OTEL Collector..." -ForegroundColor Cyan
    
    # Check if already installed
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "✅ Windows OTEL Collector already installed" -ForegroundColor Green
        return $true
    }
    
    # Check if we have admin rights
    if (-not (Test-Administrator)) {
        Write-Host "❌ Administrator rights required to install Windows Collector" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator" -ForegroundColor Yellow
        return $false
    }
    
    # Download and install OTEL Collector
    $downloadUrl = "https://github.com/open-telemetry/opentelemetry-collector-contrib/releases/latest/download/otelcol-contrib_windows_amd64.msi"
    $installerPath = "$env:TEMP\otelcol-contrib.msi"
    
    try {
        Write-Host "📥 Downloading OTEL Collector..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath
        
        Write-Host "🔧 Installing OTEL Collector..." -ForegroundColor Yellow
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /quiet" -Wait
        
        Write-Host "✅ Windows OTEL Collector installed successfully" -ForegroundColor Green
        
        # Clean up
        Remove-Item $installerPath -Force
        
        return $true
    } catch {
        Write-Host "❌ Failed to install Windows Collector: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Start-WindowsCollector {
    Write-Host "🚀 Starting Windows OTEL Collector..." -ForegroundColor Cyan
    
    # Check if service exists
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    if (-not $service) {
        Write-Host "❌ Windows OTEL Collector not installed" -ForegroundColor Red
        return $false
    }
    
    # Start the service
    try {
        if ($service.Status -ne "Running") {
            Start-Service -Name "otelcol-contrib"
            Write-Host "✅ Windows OTEL Collector started" -ForegroundColor Green
        } else {
            Write-Host "✅ Windows OTEL Collector already running" -ForegroundColor Green
        }
        return $true
    } catch {
        Write-Host "❌ Failed to start Windows Collector: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
$success = $true

# Step 1: Docker Desktop
if (-not $SkipDocker) {
    if (-not (Start-DockerDesktop)) {
        $success = $false
    }
}

# Step 2: SigNoz Stack
if ($success -and -not $SkipDocker) {
    if (-not (Start-SigNozStack)) {
        $success = $false
    }
}

# Step 3: Windows Collector
if (-not $SkipCollector) {
    if (-not (Install-WindowsCollector)) {
        $success = $false
    } elseif (-not (Start-WindowsCollector)) {
        $success = $false
    }
}

# Summary
Write-Host "`n📋 Startup Summary:" -ForegroundColor Cyan
if ($success) {
    Write-Host "✅ All components started successfully!" -ForegroundColor Green
    Write-Host "`n🎯 Next steps:" -ForegroundColor Yellow
    Write-Host "1. Run: .\verify-integration.ps1" -ForegroundColor White
    Write-Host "2. Open SigNoz UI: http://localhost:8080" -ForegroundColor White
    Write-Host "3. Check logs for 'windows-canary-' entries" -ForegroundColor White
} else {
    Write-Host "❌ Some components failed to start" -ForegroundColor Red
    Write-Host "`n🔧 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Check Docker Desktop installation" -ForegroundColor White
    Write-Host "2. Run PowerShell as Administrator for Windows Collector" -ForegroundColor White
    Write-Host "3. Check logs: docker-compose logs" -ForegroundColor White
}

exit $(if ($success) { 0 } else { 1 })


