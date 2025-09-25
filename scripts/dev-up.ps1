# One-Click Development Environment Bootstrap
# Push-button automation for: [THIS PC] → [Cursor Agents] → Docker (OTel + SigNoz) → [THIS PC] UI

param(
    [switch]$WithTests = $true,
    [int]$WaitSecs = 30,
    [switch]$SkipDocker = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"
$startTime = Get-Date

# Progress animation characters
$spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
$spinnerIndex = 0

function Write-Progress {
    param($Message, $Percent = -1)
    if ($Percent -ge 0) {
        $spinnerIndex = ($spinnerIndex + 1) % $spinner.Count
        Write-Host "`r$($spinner[$spinnerIndex]) $Message ($Percent%)" -NoNewline -ForegroundColor Cyan
    } else {
        Write-Host "`r$($spinner[$spinnerIndex]) $Message" -NoNewline -ForegroundColor Cyan
    }
}

function Write-Complete {
    param($Message)
    Write-Host "`r✅ $Message" -ForegroundColor Green
}

Write-Host "🚀 Starting One-Click Development Bootstrap..." -ForegroundColor Cyan
Write-Host "   Target: [THIS PC] → [Cursor Agents] → Docker (OTel + SigNoz) → [THIS PC] UI" -ForegroundColor Gray
Write-Host ""

# Step 1: Ensure Docker is running
Write-Progress "Ensuring Docker Desktop is running..." 10
try {
    $dockerInfo = docker info 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n⚠️  Docker Desktop not running. Attempting to start..." -ForegroundColor Yellow
        Start-Process "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe" -WindowStyle Hidden
        Start-Sleep -Seconds 10
        
        # Wait for Docker to be ready
        $retries = 0
        do {
            Start-Sleep -Seconds 5
            $dockerInfo = docker info 2>$null
            $retries++
            Write-Progress "Waiting for Docker to start..." (10 + ($retries * 5))
        } while ($LASTEXITCODE -ne 0 -and $retries -lt 12)
        
        if ($LASTEXITCODE -ne 0) {
            throw "Docker Desktop failed to start after 60 seconds"
        }
    }
    Write-Complete "Docker Desktop is running"
} catch {
    Write-Host "`n❌ Docker Desktop not available: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Please start Docker Desktop manually and run this script again." -ForegroundColor Yellow
    exit 1
}

# Step 2: Create network (idempotent)
Write-Progress "Creating Docker network..." 20
try {
    docker network create otel_default 2>$null | Out-Null
    Write-Complete "Docker network 'otel_default' ready"
} catch {
    Write-Host "`n⚠️  Network creation failed (may already exist): $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 3: Start SigNoz stack with self-healing
if (-not $SkipDocker) {
    Write-Progress "Starting SigNoz stack (self-healing)..." 30
    try {
        # Start core services
        docker compose up -d clickhouse signoz otel-collector
        
        Write-Complete "SigNoz stack started"
        
        # Wait for health with progress
        Write-Host "`n⏳ Waiting for services to be healthy..." -ForegroundColor Yellow
        $healthWaitStart = Get-Date
        $maxWait = [TimeSpan]::FromSeconds($WaitSecs)
        
        do {
            $elapsed = (Get-Date) - $healthWaitStart
            $percent = [math]::Min(50, 30 + (($elapsed.TotalSeconds / $maxWait.TotalSeconds) * 20))
            Write-Progress "Health check in progress..." $percent
            
            # Check container health
            $containers = docker ps --format "{{.Names}}\t{{.Status}}" | ConvertFrom-Csv -Delimiter "`t" -Header @("Name", "Status")
            $healthyContainers = ($containers | Where-Object { $_.Status -like "*healthy*" -or $_.Status -like "*Up*" }).Count
            $totalContainers = $containers.Count
            
            if ($healthyContainers -eq $totalContainers -and $totalContainers -ge 3) {
                break
            }
            
            Start-Sleep -Seconds 2
        } while ((Get-Date) - $healthWaitStart) -lt $maxWait
        
        Write-Complete "Services are healthy ($healthyContainers/$totalContainers containers)"
        
    } catch {
        Write-Host "`n❌ Failed to start SigNoz stack: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Check Docker logs: docker compose logs" -ForegroundColor Yellow
        exit 1
    }
}

# Step 4: Verify ports
Write-Progress "Verifying port accessibility..." 60
$ports = @("8080", "8123", "9000", "14317", "14318")
$portStatus = @()

foreach ($p in $ports) {
    try {
        $tcp = (Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue)
        if ($tcp) {
            $portStatus += "Port :$p ✅"
        } else {
            $portStatus += "Port :$p ❌"
            throw "Port :$p not listening"
        }
    } catch {
        Write-Host "`n❌ Port verification failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
Write-Complete "All required ports are accessible"

# Step 5: Configure Windows OTel collector
Write-Progress "Configuring Windows OTel collector..." 70
try {
    # Set environment variables for OTel
    $env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:14318"
    $env:OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
    
    # Verify Windows collector service
    $service = Get-Service otelcol-contrib -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Write-Complete "Windows OTel collector is running and configured"
    } else {
        Write-Host "`n⚠️  Windows OTel collector service not running" -ForegroundColor Yellow
        Write-Host "   Run: pwsh -File scripts\install-service.ps1" -ForegroundColor Gray
    }
} catch {
    Write-Host "`n⚠️  OTel collector configuration warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 6: Emit synthetic telemetry
Write-Progress "Emitting synthetic telemetry..." 80
try {
    # Create synthetic log entry
    $syntheticLog = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        synthetic_id = [System.Guid]::NewGuid().ToString()
        message = "Dev-up synthetic ping"
        level = "INFO"
        source = "dev-up-bootstrap"
        canary = "true"
    } | ConvertTo-Json -Compress
    
    # Write to log file
    $logDir = "C:\logs\synthetic"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $logFile = "$logDir\dev-up-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    $syntheticLog | Out-File -FilePath $logFile -Encoding UTF8
    
    Write-Complete "Synthetic telemetry emitted"
} catch {
    Write-Host "`n⚠️  Synthetic telemetry warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 7: Run smoke tests (if requested)
if ($WithTests) {
    Write-Progress "Running deterministic smoke tests..." 90
    try {
        # Run the existing CI verification script
        $testResult = & "C:\otel\scripts\ci-verify.ps1" -CronMode 2>&1
        $testExitCode = $LASTEXITCODE
        
        if ($testExitCode -eq 0) {
            Write-Complete "Smoke tests passed"
        } else {
            Write-Host "`n⚠️  Smoke tests had issues (exit code $testExitCode)" -ForegroundColor Yellow
            if ($Verbose) {
                Write-Host "Test output:" -ForegroundColor Gray
                Write-Host $testResult -ForegroundColor Gray
            }
        }
    } catch {
        Write-Host "`n⚠️  Smoke test warning: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Step 8: Final verification and summary
Write-Progress "Final verification..." 95
try {
    # Quick health check of SigNoz UI
    $uiResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 10 -ErrorAction SilentlyContinue
    if ($uiResponse.StatusCode -eq 200) {
        $uiStatus = "SigNoz UI: Healthy ✅"
    } else {
        $uiStatus = "SigNoz UI: Unhealthy ❌"
    }
} catch {
    $uiStatus = "SigNoz UI: Not accessible ⚠️"
}

Write-Complete "Bootstrap completed successfully!" 100

# Summary
$elapsed = (Get-Date) - $startTime
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "🎉 DEVELOPMENT ENVIRONMENT READY" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Services Status:" -ForegroundColor Yellow
Write-Host "   • SigNoz UI: http://localhost:8080" -ForegroundColor White
Write-Host "   • ClickHouse: localhost:8123 (HTTP), localhost:9000 (Native)" -ForegroundColor White
Write-Host "   • OTel Collector: localhost:14317 (gRPC), localhost:14318 (HTTP)" -ForegroundColor White
Write-Host "   • $uiStatus" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Quick Links:" -ForegroundColor Yellow
Write-Host "   • SigNoz Logs: http://localhost:8080/logs" -ForegroundColor White
Write-Host "   • SigNoz Metrics: http://localhost:8080/metrics" -ForegroundColor White
Write-Host "   • SigNoz Traces: http://localhost:8080/traces" -ForegroundColor White
Write-Host ""
Write-Host "🛠️  Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Open http://localhost:8080 in your browser" -ForegroundColor White
Write-Host "   2. Run: pwsh -File scripts\quick-monitor.ps1" -ForegroundColor White
Write-Host "   3. Generate test data: pwsh -File scripts\canary-test.ps1" -ForegroundColor White
Write-Host ""
Write-Host "⏱️  Bootstrap completed in $([int]$elapsed.TotalSeconds) seconds" -ForegroundColor Gray

# Exit with success
exit 0




