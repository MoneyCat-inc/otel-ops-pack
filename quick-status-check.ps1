# Quick Status Check
Write-Host "=== Observability Stack Status ===" -ForegroundColor Cyan

# Check Windows Collector Service
Write-Host "`n1. Windows Collector Service:" -ForegroundColor Yellow
try {
    $service = Get-Service otelcol-contrib -ErrorAction Stop
    Write-Host "   Status: $($service.Status)" -ForegroundColor $(if($service.Status -eq 'Running'){'Green'}else{'Red'})
} catch {
    Write-Host "   Service not found or error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check Docker Containers
Write-Host "`n2. Docker Containers:" -ForegroundColor Yellow
try {
    $containers = docker ps --format "{{.Names}} {{.Status}} {{.Ports}}" 2>$null
    if ($containers) {
        $containers | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
    } else {
        Write-Host "   No containers running" -ForegroundColor Red
    }
} catch {
    Write-Host "   Docker not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Check Key Ports
Write-Host "`n3. Key Ports:" -ForegroundColor Yellow
$ports = @(3301, 5317, 5318, 4317, 4318)
foreach ($port in $ports) {
    try {
        $result = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
        $status = if($result){"Listening"}else{"Not listening"}
        $color = if($result){"Green"}else{"Red"}
        Write-Host "   Port $port : $status" -ForegroundColor $color
    } catch {
        Write-Host "   Port $port : Error checking" -ForegroundColor Red
    }
}

# Check SigNoz UI
Write-Host "`n4. SigNoz UI Access:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3301" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    Write-Host "   UI Status: $($response.StatusCode) OK" -ForegroundColor Green
} catch {
    Write-Host "   UI Status: Not accessible - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Status Check Complete ===" -ForegroundColor Cyan

