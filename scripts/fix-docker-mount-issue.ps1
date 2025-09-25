# Fix Docker Mount Path Issue for SigNoz Collector
# Resolves: mkdir /run/desktop/mnt/host/c: file exists

param(
    [switch]$Verbose,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$startTime = Get-Date

Write-Host "🔧 Fixing Docker Mount Path Issue..." -ForegroundColor Cyan

# Progress animation function
function Write-Progress-Animation {
    param($Message, $Percent = -1)
    $spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $spinnerIndex = ($spinnerIndex + 1) % $spinner.Count
    
    if ($Percent -ge 0) {
        Write-Host "`r$($spinner[$spinnerIndex]) $Message ($Percent%)" -NoNewline -ForegroundColor Cyan
    } else {
        Write-Host "`r$($spinner[$spinnerIndex]) $Message" -NoNewline -ForegroundColor Cyan
    }
}

try {
    # Step 1: Stop and remove existing containers
    Write-Progress-Animation "Stopping existing containers..." 10
    docker-compose down --remove-orphans 2>$null
    
    # Step 2: Remove the problematic container specifically
    Write-Progress-Animation "Removing problematic container..." 20
    docker rm -f signoz-otel-collector 2>$null
    
    # Step 3: Clean up Docker networks
    Write-Progress-Animation "Cleaning up networks..." 30
    docker network rm otel_default 2>$null
    
    # Step 4: Reset Docker Desktop mount paths (Windows-specific)
    Write-Progress-Animation "Resetting Docker Desktop..." 40
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        # Restart Docker Desktop service to clear mount path cache
        try {
            Restart-Service -Name "com.docker.service" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 5
        } catch {
            Write-Host "`n⚠️  Could not restart Docker service automatically. Please restart Docker Desktop manually." -ForegroundColor Yellow
        }
    }
    
    # Step 5: Verify temporary config file exists and is accessible
    Write-Progress-Animation "Verifying config file..." 50
    $configPath = "C:\otel\signoz-collector-temp.yaml"
    if (-not (Test-Path $configPath)) {
        throw "Configuration file not found: $configPath"
    }
    
    # Check file permissions and accessibility
    try {
        $configContent = Get-Content $configPath -Raw
        if ($configContent.Length -lt 100) {
            throw "Configuration file appears to be empty or corrupted"
        }
        Write-Host "`n✅ Config file verified ($($configContent.Length) bytes)" -ForegroundColor Green
    } catch {
        throw "Cannot read configuration file: $($_.Exception.Message)"
    }
    
    # Step 6: Create Docker network
    Write-Progress-Animation "Creating Docker network..." 60
    docker network create otel_default 2>$null
    
    # Step 7: Alternative approach - use relative path instead of absolute
    Write-Progress-Animation "Preparing alternative mount approach..." 70
    
    # Create a local copy with a different name to avoid mount conflicts
    $altConfigPath = "C:\otel\collector-config.yaml"
    Copy-Item $configPath $altConfigPath -Force
    
    # Step 8: Modify docker-compose to use alternative approach
    Write-Progress-Animation "Updating Docker Compose configuration..." 80
    
    # Create a temporary docker-compose override
    $composeOverride = @"
version: '3.8'
services:
  otel-collector:
    volumes:
      - ./collector-config.yaml:/etc/otel-collector-config.yaml:ro
"@
    
    $composeOverride | Out-File -FilePath "docker-compose.override.yml" -Encoding UTF8
    
    # Step 9: Start services with the fixed configuration
    Write-Progress-Animation "Starting SigNoz stack..." 90
    docker-compose up -d
    
    # Step 10: Verify the fix
    Write-Progress-Animation "Verifying services..." 100
    Start-Sleep -Seconds 10
    
    $containers = docker ps --format "{{.Names}}\t{{.Status}}"
    $otelCollector = $containers | Where-Object { $_ -match "signoz-otel-collector" }
    
    if ($otelCollector -and $otelCollector -match "Up") {
        Write-Host "`n✅ SUCCESS: SigNoz OTel Collector is now running!" -ForegroundColor Green
        Write-Host "Container status: $otelCollector" -ForegroundColor Green
        
        # Show all running containers
        Write-Host "`n📊 All SigNoz containers:" -ForegroundColor Cyan
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Select-Object -Skip 1
        
    } else {
        throw "OTel Collector still not running. Container status: $otelCollector"
    }
    
    # Cleanup temporary files
    if (Test-Path "docker-compose.override.yml") {
        Remove-Item "docker-compose.override.yml" -Force
    }
    
    Write-Host "`n🎉 Docker mount path issue resolved!" -ForegroundColor Green
    Write-Host "The SigNoz stack is now running successfully." -ForegroundColor Green
    
} catch {
    Write-Host "`n❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    
    # Provide troubleshooting steps
    Write-Host "`n🔍 Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Restart Docker Desktop completely" -ForegroundColor White
    Write-Host "2. Check if C:\ drive is properly shared with Docker Desktop" -ForegroundColor White
    Write-Host "3. Try running: docker system prune -f" -ForegroundColor White
    Write-Host "4. Verify the config file exists: Test-Path 'C:\otel\signoz-collector-temp.yaml'" -ForegroundColor White
    
    exit 1
}

$elapsed = (Get-Date) - $startTime
Write-Host "`n⏱️  Fix completed in $([int]$elapsed.TotalSeconds) seconds" -ForegroundColor Gray




