# Fixed Health Check Script for Observability Pipeline
# Usage: pwsh -File scripts/health-check-observability-fixed.ps1

param(
    [switch]$JsonOutput,
    [switch]$Quiet
)

# Set working directory to script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
Set-Location $RepoRoot

# Initialize results object
$HealthResults = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    OverallStatus = "UNKNOWN"
    Components = @{}
    Summary = @{
        Total = 0
        Healthy = 0
        Unhealthy = 0
        Partial = 0
    }
}

function Test-Service {
    param($ServiceName, $DisplayName)
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        if ($service.Status -eq "Running") {
            $result = @{ Status = "HEALTHY"; Details = "Running" }
            if (-not $Quiet) { Write-Host "   ✅ RUNNING" -ForegroundColor Green }
        } else {
            $result = @{ Status = "UNHEALTHY"; Details = "Stopped" }
            if (-not $Quiet) { Write-Host "   ❌ NOT RUNNING" -ForegroundColor Red }
        }
    } catch {
        $result = @{ Status = "UNHEALTHY"; Details = "Not Found" }
        if (-not $Quiet) { Write-Host "   ❌ NOT FOUND" -ForegroundColor Red }
    }
    
    $HealthResults.Components[$DisplayName] = $result
    return $result
}

function Test-Endpoint {
    param($Uri, $DisplayName)
    
    try {
        $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $result = @{ Status = "HEALTHY"; Details = "HTTP 200 OK" }
            if (-not $Quiet) { Write-Host "   ✅ HEALTHY" -ForegroundColor Green }
        } else {
            $result = @{ Status = "UNHEALTHY"; Details = "HTTP $($response.StatusCode)" }
            if (-not $Quiet) { Write-Host "   ❌ UNHEALTHY" -ForegroundColor Red }
        }
    } catch {
        $result = @{ Status = "UNHEALTHY"; Details = "Unreachable" }
        if (-not $Quiet) { Write-Host "   ❌ UNREACHABLE" -ForegroundColor Red }
    }
    
    $HealthResults.Components[$DisplayName] = $result
    return $result
}

function Test-DockerContainers {
    try {
        $containers = docker ps --format "table {{.Names}}\t{{.Status}}" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $result = @{ Status = "HEALTHY"; Details = "Containers Running"; Data = $containers }
            if (-not $Quiet) { 
                Write-Host "   ✅ AVAILABLE" -ForegroundColor Green
                Write-Host $containers -ForegroundColor White
            }
        } else {
            $result = @{ Status = "UNHEALTHY"; Details = "Docker Not Available" }
            if (-not $Quiet) { Write-Host "   ❌ NOT AVAILABLE" -ForegroundColor Red }
        }
    } catch {
        $result = @{ Status = "UNHEALTHY"; Details = "Docker Error" }
        if (-not $Quiet) { Write-Host "   ❌ NOT AVAILABLE" -ForegroundColor Red }
    }
    
    $HealthResults.Components["Docker Containers"] = $result
    return $result
}

function Test-CanaryGeneration {
    try {
        $canaryOutput = & canary 2>&1
        $tokenMatch = $canaryOutput | Select-String -Pattern "token=([a-f0-9]+)" -AllMatches
        if ($tokenMatch -and $tokenMatch.Matches.Count -gt 0) {
            $token = $tokenMatch.Matches[0].Groups[1].Value
            $result = @{ Status = "HEALTHY"; Details = "Token Generated"; Data = $token }
            if (-not $Quiet) { Write-Host "   ✅ SUCCESS (Token: $token)" -ForegroundColor Green }
        } else {
            # Check if canary ran successfully by looking for "OK delta observed"
            if ($canaryOutput -match "OK delta observed") {
                $result = @{ Status = "HEALTHY"; Details = "Canary Executed Successfully" }
                if (-not $Quiet) { Write-Host "   ✅ SUCCESS (Canary Executed)" -ForegroundColor Green }
            } else {
                $result = @{ Status = "UNHEALTHY"; Details = "No Token Generated" }
                if (-not $Quiet) { Write-Host "   ❌ FAILED" -ForegroundColor Red }
            }
        }
    } catch {
        $result = @{ Status = "UNHEALTHY"; Details = "Execution Error" }
        if (-not $Quiet) { Write-Host "   ❌ ERROR" -ForegroundColor Red }
    }
    
    $HealthResults.Components["Canary Generation"] = $result
    return $result
}

function Test-EventLog {
    try {
        $events = Get-WinEvent -LogName Application -MaxEvents 5 -ErrorAction Stop | Where-Object { $_.ProviderName -eq "SigNoz-Canary" }
        if ($events.Count -gt 0) {
            $result = @{ Status = "HEALTHY"; Details = "Entries Found"; Data = $events.Count }
            if (-not $Quiet) { Write-Host "   ✅ ENTRIES FOUND ($($events.Count))" -ForegroundColor Green }
        } else {
            $result = @{ Status = "PARTIAL"; Details = "No Recent Entries" }
            if (-not $Quiet) { Write-Host "   ⚠️  NO ENTRIES FOUND" -ForegroundColor Yellow }
        }
    } catch {
        $result = @{ Status = "UNHEALTHY"; Details = "Access Error" }
        if (-not $Quiet) { Write-Host "   ❌ ERROR" -ForegroundColor Red }
    }
    
    $HealthResults.Components["Event Log"] = $result
    return $result
}

# Main execution
if (-not $Quiet) {
    Write-Host "=== Observability Pipeline Health Check (Fixed) ===" -ForegroundColor Cyan
    Write-Host "Timestamp: $($HealthResults.Timestamp)" -ForegroundColor White
}

# Test all components
Write-Host "`n1. Windows Collector Service:" -ForegroundColor Yellow
Test-Service "otelcol-contrib" "Windows Collector"

Write-Host "`n2. Collector Health Endpoint:" -ForegroundColor Yellow
Test-Endpoint "http://localhost:13134/healthz" "Collector Health"

Write-Host "`n3. SigNoz UI:" -ForegroundColor Yellow
Test-Endpoint "http://localhost:8080" "SigNoz UI"

Write-Host "`n4. SigNoz API:" -ForegroundColor Yellow
Test-Endpoint "http://localhost:8080/api/v1/health" "SigNoz API"

Write-Host "`n5. Docker Containers:" -ForegroundColor Yellow
Test-DockerContainers

Write-Host "`n6. Canary Generation:" -ForegroundColor Yellow
Test-CanaryGeneration

Write-Host "`n7. Event Log Entries:" -ForegroundColor Yellow
Test-EventLog

# Calculate summary
foreach ($component in $HealthResults.Components.Values) {
    $HealthResults.Summary.Total++
    switch ($component.Status) {
        "HEALTHY" { $HealthResults.Summary.Healthy++ }
        "UNHEALTHY" { $HealthResults.Summary.Unhealthy++ }
        "PARTIAL" { $HealthResults.Summary.Partial++ }
    }
}

# Determine overall status
if ($HealthResults.Summary.Unhealthy -eq 0) {
    $HealthResults.OverallStatus = "HEALTHY"
} elseif ($HealthResults.Summary.Unhealthy -le 2) {
    $HealthResults.OverallStatus = "DEGRADED"
} else {
    $HealthResults.OverallStatus = "UNHEALTHY"
}

if (-not $Quiet) {
    Write-Host "`n=== Health Check Complete ===" -ForegroundColor Cyan
    Write-Host "Overall Status: $($HealthResults.OverallStatus)" -ForegroundColor $(if ($HealthResults.OverallStatus -eq "HEALTHY") { "Green" } elseif ($HealthResults.OverallStatus -eq "DEGRADED") { "Yellow" } else { "Red" })
    Write-Host "Healthy: $($HealthResults.Summary.Healthy), Unhealthy: $($HealthResults.Summary.Unhealthy), Partial: $($HealthResults.Summary.Partial)" -ForegroundColor White
}

# Output results
if ($JsonOutput) {
    $HealthResults | ConvertTo-Json -Depth 10
} else {
    $HealthResults
}
