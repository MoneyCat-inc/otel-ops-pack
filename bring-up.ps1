# Complete Observability Stack Bring-Up Script
# Executes Phase 1 runbook with all steps

param(
    [switch]$SkipDocker,
    [switch]$SkipCollector,
    [switch]$SkipSigNoz,
    [switch]$AutoStart
)

Write-Host "🚀 Starting Complete Observability Stack Bring-Up..." -ForegroundColor Green

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-DockerDesktop {
    Write-Host "🐳 Starting Docker Desktop..." -ForegroundColor Cyan
    
    # Check if Docker is already running
    try {
        $null = docker info 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker Desktop already running" -ForegroundColor Green
            return $true
        }
    } catch {
        # Docker not running
    }
    
    # Start Docker Desktop
    try {
        Write-Host "🔄 Launching Docker Desktop..." -ForegroundColor Yellow
        Start-Process "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
        
        Write-Host "⏳ Waiting for Docker Desktop to start (this may take 1-2 minutes)..." -ForegroundColor Yellow
        
        # Wait up to 3 minutes for Docker to start
        $timeout = 180
        $elapsed = 0
        while ($elapsed -lt $timeout) {
            try {
                $null = docker info 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Docker Desktop started successfully" -ForegroundColor Green
                    return $true
                }
            } catch {
                # Still starting
            }
            Start-Sleep -Seconds 10
            $elapsed += 10
            Write-Host "." -NoNewline -ForegroundColor Yellow
        }
        
        Write-Host "`n⚠️  Docker Desktop may still be starting up" -ForegroundColor Yellow
        Write-Host "Check system tray for green whale icon" -ForegroundColor Yellow
        return $false
    } catch {
        Write-Host "❌ Failed to start Docker Desktop: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Start-WindowsCollector {
    Write-Host "🔧 Starting Windows OTEL Collector..." -ForegroundColor Cyan
    
    # Check if service exists
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    if (-not $service) {
        Write-Host "❌ Windows OTEL Collector service not installed" -ForegroundColor Red
        return $false
    }
    
    # Start the service
    try {
        if ($service.Status -ne "Running") {
            Write-Host "🔄 Starting otelcol-contrib service..." -ForegroundColor Yellow
            Start-Service otelcol-contrib
            Start-Sleep -Seconds 3
        }
        
        $service = Get-Service -Name "otelcol-contrib"
        if ($service.Status -eq "Running") {
            Write-Host "✅ Windows OTEL Collector started successfully" -ForegroundColor Green
            
            # Set to auto-start if requested
            if ($AutoStart) {
                Set-Service otelcol-contrib -StartupType Automatic
                Write-Host "✅ Set collector to auto-start on boot" -ForegroundColor Green
            }
            
            return $true
        } else {
            Write-Host "❌ Failed to start Windows Collector (Status: $($service.Status))" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Error starting Windows Collector: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
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
            $timeout = 120
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

function Test-Integration {
    Write-Host "🔍 Running Integration Tests..." -ForegroundColor Cyan
    
    if (Test-Path "verify-integration.ps1") {
        Write-Host "🔄 Running verify-integration.ps1..." -ForegroundColor Yellow
        try {
            & .\verify-integration.ps1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Integration verification passed" -ForegroundColor Green
                return $true
            } else {
                Write-Host "⚠️  Integration verification had issues" -ForegroundColor Yellow
                return $false
            }
        } catch {
            Write-Host "❌ Integration verification failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "⚠️  verify-integration.ps1 not found, running basic checks..." -ForegroundColor Yellow
        
        # Basic port checks
        $ports = @(
            @{ Port = 8080; Name = "SigNoz UI" }
            @{ Port = 4317; Name = "SigNoz gRPC" }
            @{ Port = 4318; Name = "SigNoz HTTP" }
            @{ Port = 5317; Name = "Windows OTEL gRPC" }
            @{ Port = 5318; Name = "Windows OTEL HTTP" }
        )
        
        $allOk = $true
        foreach ($portInfo in $ports) {
            $ok = Test-NetConnection -ComputerName localhost -Port $portInfo.Port -InformationLevel Quiet -WarningAction SilentlyContinue
            if ($ok) {
                Write-Host "✅ $($portInfo.Name) (Port $($portInfo.Port))" -ForegroundColor Green
            } else {
                Write-Host "❌ $($portInfo.Name) (Port $($portInfo.Port))" -ForegroundColor Red
                $allOk = $false
            }
        }
        
        return $allOk
    }
}

function Show-Status {
    Write-Host "`n📋 Final Status Check:" -ForegroundColor Cyan
    
    # Docker status
    try {
        $null = docker info 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker Desktop: Running" -ForegroundColor Green
        } else {
            Write-Host "❌ Docker Desktop: Not running" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Docker Desktop: Not available" -ForegroundColor Red
    }
    
    # Windows Collector status
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Write-Host "✅ Windows Collector: Running" -ForegroundColor Green
    } else {
        Write-Host "❌ Windows Collector: Not running" -ForegroundColor Red
    }
    
    # SigNoz UI
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ SigNoz UI: Accessible" -ForegroundColor Green
        } else {
            Write-Host "❌ SigNoz UI: Not accessible" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ SigNoz UI: Not accessible" -ForegroundColor Red
    }
}

# Main execution
$success = $true

# Check if running as administrator
if (-not (Test-Administrator)) {
    Write-Host "⚠️  Not running as Administrator. Some operations may fail." -ForegroundColor Yellow
}

# Step 1: Docker Desktop
if (-not $SkipDocker) {
    if (-not (Start-DockerDesktop)) {
        $success = $false
    }
}

# Step 2: Windows Collector
if (-not $SkipCollector) {
    if (-not (Start-WindowsCollector)) {
        $success = $false
    }
}

# Step 3: SigNoz Stack
if ($success -and -not $SkipSigNoz) {
    if (-not (Start-SigNozStack)) {
        $success = $false
    }
}

# Step 4: Integration Test
if ($success) {
    if (-not (Test-Integration)) {
        $success = $false
    }
}

# Final status
Show-Status

# Summary
Write-Host "`n📋 Bring-Up Summary:" -ForegroundColor Cyan
if ($success) {
    Write-Host "✅ All components started successfully!" -ForegroundColor Green
    Write-Host "`n🎯 Next steps:" -ForegroundColor Yellow
    Write-Host "1. Open SigNoz UI: http://localhost:8080" -ForegroundColor White
    Write-Host "2. Check logs for 'windows-canary-' entries" -ForegroundColor White
    Write-Host "3. Monitor system with your verification scripts" -ForegroundColor White
} else {
    Write-Host "❌ Some components failed to start" -ForegroundColor Red
    Write-Host "`n🔧 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Check Docker Desktop tray icon (should be green)" -ForegroundColor White
    Write-Host "2. Run PowerShell as Administrator for Windows Collector" -ForegroundColor White
    Write-Host "3. Check logs: docker-compose logs" -ForegroundColor White
}

exit $(if ($success) { 0 } else { 1 })

