# Simple Health Check Script for Observability Pipeline
# Usage: pwsh -File scripts/health-check-observability.ps1

Write-Host "=== Observability Pipeline Health Check ===" -ForegroundColor Cyan
Write-Host "Timestamp: 2025-09-28 16:25:52" -ForegroundColor White

# 1. Windows Collector Service
Write-Host "
1. Windows Collector Service:" -ForegroundColor Yellow
try {
     = Get-Service -Name "otelcol-contrib" -ErrorAction Stop
    if (.Status -eq "Running") {
        Write-Host "   ✅ RUNNING" -ForegroundColor Green
    } else {
        Write-Host "   ❌ NOT RUNNING" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ NOT FOUND" -ForegroundColor Red
}

# 2. Collector Health Endpoint
Write-Host "
2. Collector Health Endpoint:" -ForegroundColor Yellow
try {
     = Invoke-WebRequest -Uri "http://localhost:13134/healthz" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    if (.StatusCode -eq 200) {
        Write-Host "   ✅ HEALTHY" -ForegroundColor Green
    } else {
        Write-Host "   ❌ UNHEALTHY" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ UNREACHABLE" -ForegroundColor Red
}

# 3. SigNoz UI
Write-Host "
3. SigNoz UI:" -ForegroundColor Yellow
try {
     = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    if (.StatusCode -eq 200) {
        Write-Host "   ✅ ACCESSIBLE" -ForegroundColor Green
    } else {
        Write-Host "   ❌ NOT ACCESSIBLE" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ UNREACHABLE" -ForegroundColor Red
}

# 4. SigNoz API
Write-Host "
4. SigNoz API:" -ForegroundColor Yellow
try {
     = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    if (.StatusCode -eq 200) {
        Write-Host "   ✅ HEALTHY" -ForegroundColor Green
    } else {
        Write-Host "   ❌ UNHEALTHY" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ UNREACHABLE" -ForegroundColor Red
}

# 5. Docker Containers
Write-Host "
5. Docker Containers:" -ForegroundColor Yellow
try {
     = docker ps --format "table {{.Names}}\t{{.Status}}"
    Write-Host "   ✅ AVAILABLE" -ForegroundColor Green
    Write-Host  -ForegroundColor White
} catch {
    Write-Host "   ❌ NOT AVAILABLE" -ForegroundColor Red
}

# 6. Canary Generation
Write-Host "
6. Canary Generation:" -ForegroundColor Yellow
try {
     = & canary 2>&1
     =  | Select-String -Pattern "token=([a-f0-9]+)" -AllMatches
    if (.Matches.Count -gt 0) {
         = .Matches[0].Groups[1].Value
        Write-Host "   ✅ SUCCESS (Token: )" -ForegroundColor Green
    } else {
        Write-Host "   ❌ FAILED" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ ERROR" -ForegroundColor Red
}

# 7. Event Log
Write-Host "
7. Event Log Entries:" -ForegroundColor Yellow
try {
     = Get-WinEvent -LogName Application -MaxEvents 5 | Where-Object { .ProviderName -eq "SigNoz-Canary" }
    if (.Count -gt 0) {
        Write-Host "   ✅ ENTRIES FOUND (0)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  NO ENTRIES FOUND" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ ERROR" -ForegroundColor Red
}

Write-Host "
=== Health Check Complete ===" -ForegroundColor Cyan
