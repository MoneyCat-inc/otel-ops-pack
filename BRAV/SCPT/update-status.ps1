# Tetragram Health Status Update Script
# Generates comprehensive health snapshot for CHAR/EVID/health/

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$commit = (git rev-parse HEAD 2>$null) -replace "`n", ""

Write-Host "🐾 BossCat Health Status Update" -ForegroundColor Cyan
Write-Host "Timestamp: $timestamp" -ForegroundColor Gray
Write-Host "Commit: $commit" -ForegroundColor Gray
Write-Host ""

# Ensure output directory exists
New-Item -ItemType Directory -Force -Path "CHAR\EVID\health" | Out-Null

# 1. Guardrails Check (Strict)
Write-Host "[1/4] Running guardrails check..." -ForegroundColor Yellow
$guardrailsResult = @{
    timestamp = $timestamp
    commit = $commit
    strict = $true
    exit_code = 1
    ok = $false
    violations = @()
}

try {
    $output = python BRAV\SCPT\check_guardrails.py --config BRAV\SCPT\guardrails.json --strict 2>&1
    if ($LASTEXITCODE -eq 0) {
        $guardrailsResult.exit_code = 0
        $guardrailsResult.ok = $true
        Write-Host "  ✅ Guardrails PASS" -ForegroundColor Green
    } else {
        $guardrailsResult.exit_code = $LASTEXITCODE
        Write-Host "  ❌ Guardrails FAIL (exit $LASTEXITCODE)" -ForegroundColor Red
        if ($Verbose) {
            Write-Host $output -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  ⚠️  Guardrails check error: $_" -ForegroundColor Yellow
}

$guardrailsResult | ConvertTo-Json -Depth 10 | 
    Set-Content -Path "CHAR\EVID\health\guardrails.json" -Encoding UTF8

# 2. Docker Services Status
Write-Host "[2/4] Checking Docker services..." -ForegroundColor Yellow
$dockerResult = @()

try {
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $containers = docker ps --format "{{.Names}}|{{.Status}}|{{.Image}}" --filter "name=signoz" 2>$null
        if ($containers) {
            foreach ($line in $containers) {
                $parts = $line -split '\|'
                if ($parts.Length -ge 3) {
                    $dockerResult += @{
                        name = $parts[0]
                        status = $parts[1]
                        image = $parts[2]
                    }
                }
            }
            Write-Host "  ✅ Found $($dockerResult.Count) Docker containers" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  No signoz containers running" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ⚠️  Docker not available" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  Docker check error: $_" -ForegroundColor Yellow
}

$dockerResult | ConvertTo-Json -Depth 10 | 
    Set-Content -Path "CHAR\EVID\health\docker.json" -Encoding UTF8

# 3. Windows Services Status
Write-Host "[3/4] Checking Windows services..." -ForegroundColor Yellow
$windowsResult = @()

try {
    $services = Get-Service | Where-Object { 
        $_.Name -match 'otel|signoz' 
    } | Select-Object Name, Status, DisplayName
    
    foreach ($svc in $services) {
        $windowsResult += @{
            name = $svc.Name
            status = $svc.Status.ToString()
            display_name = $svc.DisplayName
        }
    }
    
    if ($windowsResult.Count -gt 0) {
        Write-Host "  ✅ Found $($windowsResult.Count) Windows services" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  No otel/signoz services found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  Windows services check error: $_" -ForegroundColor Yellow
}

$windowsResult | ConvertTo-Json -Depth 10 | 
    Set-Content -Path "CHAR\EVID\health\windows.json" -Encoding UTF8

# 4. Combined Test Status
Write-Host "[4/4] Generating combined status..." -ForegroundColor Yellow

$testResult = @{
    last_update = $timestamp
    commit = $commit
    guardrails = @{
        ok = $guardrailsResult.ok
        exit_code = $guardrailsResult.exit_code
    }
    docker = @{
        container_count = $dockerResult.Count
        healthy = ($dockerResult | Where-Object { $_.status -match 'healthy' }).Count
    }
    windows = @{
        service_count = $windowsResult.Count
        running = ($windowsResult | Where-Object { $_.status -eq 'Running' }).Count
    }
    summary = @{
        overall_health = if ($guardrailsResult.ok -and $dockerResult.Count -gt 0) { "PASS" } else { "WARN" }
    }
}

$testResult | ConvertTo-Json -Depth 10 | 
    Set-Content -Path "CHAR\EVID\health\tests.json" -Encoding UTF8

Write-Host ""
Write-Host "✅ Health status updated successfully" -ForegroundColor Green
Write-Host "   Guardrails: $($guardrailsResult.ok ? 'PASS' : 'FAIL')" -ForegroundColor $(if ($guardrailsResult.ok) { 'Green' } else { 'Red' })
Write-Host "   Docker: $($dockerResult.Count) containers" -ForegroundColor Gray
Write-Host "   Windows: $($windowsResult.Count) services" -ForegroundColor Gray
Write-Host "   Output: CHAR\EVID\health\" -ForegroundColor Gray
Write-Host ""
Write-Host "View dashboard: CHAR\EVID\health\status.html" -ForegroundColor Cyan

