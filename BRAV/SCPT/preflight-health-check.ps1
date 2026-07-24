# OTel Preflight Health Check
# Ensures SigNoz OTLP endpoints are ready before starting Windows collector

param(
    [string]$SigNozHost = "localhost",
    [int]$OtlpGrpcPort = 4317,
    [int]$OtlpHttpPort = 4318,
    [int]$MaxWaitSeconds = 60,
    [switch]$Verbose
)

Write-Host "🔍 OTel Preflight Health Check" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

$startTime = Get-Date
$checks = @()

# Check 1: SigNoz Docker containers
Write-Host "`n📦 Checking SigNoz Docker Containers" -ForegroundColor Cyan
try {
    $containers = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Select-String "signoz"
    if ($containers) {
        Write-Host "✅ SigNoz containers running:" -ForegroundColor Green
        $containers | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
        $checks += @{Name="Docker Containers"; Status="PASS"; Details="SigNoz containers detected"}
    }
    else {
        Write-Host "❌ No SigNoz containers found" -ForegroundColor Red
        $checks += @{Name="Docker Containers"; Status="FAIL"; Details="No SigNoz containers running"}
    }
}
catch {
    Write-Host "❌ Docker check failed: $($_.Exception.Message)" -ForegroundColor Red
    $checks += @{Name="Docker Containers"; Status="ERROR"; Details=$_.Exception.Message}
}

# Check 2: OTLP gRPC Port
Write-Host "`n🔌 Checking OTLP gRPC Port ($OtlpGrpcPort)" -ForegroundColor Cyan
$grpcReady = $false
$attempts = 0
$maxAttempts = [math]::Ceiling($MaxWaitSeconds / 3)

while (-not $grpcReady -and $attempts -lt $maxAttempts) {
    $attempts++
    if ($Verbose) { Write-Host "  Attempt $attempts/$maxAttempts..." -ForegroundColor Yellow }
    
    try {
        $connection = Test-NetConnection -ComputerName $SigNozHost -Port $OtlpGrpcPort -WarningAction SilentlyContinue
        if ($connection.TcpTestSucceeded) {
            Write-Host "  ✅ OTLP gRPC port $OtlpGrpcPort is reachable" -ForegroundColor Green
            $grpcReady = $true
            $checks += @{Name="OTLP gRPC"; Status="PASS"; Details="Port $OtlpGrpcPort reachable"}
        }
        else {
            if ($Verbose) { Write-Host "  ❌ Port $OtlpGrpcPort not reachable" -ForegroundColor Red }
            Start-Sleep -Seconds 3
        }
    }
    catch {
        if ($Verbose) { Write-Host "  ❌ Connection test failed: $($_.Exception.Message)" -ForegroundColor Red }
        Start-Sleep -Seconds 3
    }
}

if (-not $grpcReady) {
    Write-Host "❌ OTLP gRPC port $OtlpGrpcPort not ready after $maxAttempts attempts" -ForegroundColor Red
    $checks += @{Name="OTLP gRPC"; Status="FAIL"; Details="Port $OtlpGrpcPort not reachable"}
}

# Check 3: OTLP HTTP Port
Write-Host "`n🌐 Checking OTLP HTTP Port ($OtlpHttpPort)" -ForegroundColor Cyan
$httpReady = $false
$attempts = 0

while (-not $httpReady -and $attempts -lt $maxAttempts) {
    $attempts++
    if ($Verbose) { Write-Host "  Attempt $attempts/$maxAttempts..." -ForegroundColor Yellow }
    
    try {
        $connection = Test-NetConnection -ComputerName $SigNozHost -Port $OtlpHttpPort -WarningAction SilentlyContinue
        if ($connection.TcpTestSucceeded) {
            Write-Host "  ✅ OTLP HTTP port $OtlpHttpPort is reachable" -ForegroundColor Green
            $httpReady = $true
            $checks += @{Name="OTLP HTTP"; Status="PASS"; Details="Port $OtlpHttpPort reachable"}
        }
        else {
            if ($Verbose) { Write-Host "  ❌ Port $OtlpHttpPort not reachable" -ForegroundColor Red }
            Start-Sleep -Seconds 3
        }
    }
    catch {
        if ($Verbose) { Write-Host "  ❌ Connection test failed: $($_.Exception.Message)" -ForegroundColor Red }
        Start-Sleep -Seconds 3
    }
}

if (-not $httpReady) {
    Write-Host "❌ OTLP HTTP port $OtlpHttpPort not ready after $maxAttempts attempts" -ForegroundColor Red
    $checks += @{Name="OTLP HTTP"; Status="FAIL"; Details="Port $OtlpHttpPort not reachable"}
}

# Check 4: SigNoz UI Health
Write-Host "`n🏥 Checking SigNoz UI Health" -ForegroundColor Cyan
try {
    $uiResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 10 -ErrorAction Stop
    if ($uiResponse.StatusCode -eq 200) {
        Write-Host "✅ SigNoz UI health endpoint responding" -ForegroundColor Green
        $checks += @{Name="SigNoz UI"; Status="PASS"; Details="Health endpoint responding"}
    }
    else {
        Write-Host "⚠️  SigNoz UI returned status: $($uiResponse.StatusCode)" -ForegroundColor Yellow
        $checks += @{Name="SigNoz UI"; Status="WARN"; Details="Status $($uiResponse.StatusCode)"}
    }
}
catch {
    Write-Host "❌ SigNoz UI health check failed: $($_.Exception.Message)" -ForegroundColor Red
    $checks += @{Name="SigNoz UI"; Status="FAIL"; Details=$_.Exception.Message}
}

# Summary
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host "`n📊 Preflight Check Summary" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "Duration: $([math]::Round($duration, 2)) seconds" -ForegroundColor White

$passedChecks = ($checks | Where-Object { $_.Status -eq "PASS" }).Count
$totalChecks = $checks.Count
$successRate = [math]::Round(($passedChecks / $totalChecks) * 100, 1)

Write-Host "Success Rate: $passedChecks/$totalChecks ($successRate%)" -ForegroundColor $(if ($successRate -ge 75) { "Green" } elseif ($successRate -ge 50) { "Yellow" } else { "Red" })

foreach ($check in $checks) {
    $statusColor = switch ($check.Status) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
        "ERROR" { "Red" }
        default { "White" }
    }
    Write-Host "  $($check.Name): " -NoNewline -ForegroundColor White
    Write-Host "$($check.Status)" -ForegroundColor $statusColor
    if ($Verbose) {
        Write-Host "    Details: $($check.Details)" -ForegroundColor Gray
    }
}

# Exit code based on critical checks
$criticalChecks = $checks | Where-Object { $_.Name -in @("OTLP gRPC", "OTLP HTTP") }
$criticalFailures = ($criticalChecks | Where-Object { $_.Status -eq "FAIL" }).Count

if ($criticalFailures -eq 0) {
    Write-Host "`n✅ Preflight check PASSED - Safe to start Windows collector" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n❌ Preflight check FAILED - Do not start Windows collector" -ForegroundColor Red
    Write-Host "💡 Ensure SigNoz is running: docker-compose -f compose/docker-compose-signoz.yml up -d" -ForegroundColor Yellow
    exit 1
}
