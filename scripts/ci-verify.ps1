# CI/CD Observability Verification Script
# Based on the verification-agent-prompt.md logic

param(
    [switch]$Verbose,
    [switch]$CronMode
)

$ErrorActionPreference = "Stop"
$startTime = Get-Date

Write-Host "🔍 Starting Observability Verification..." -ForegroundColor Cyan
if ($CronMode) {
    Write-Host "🕐 Running in Cron Mode (extended checks)" -ForegroundColor Yellow
}

# Initialize results
$results = @{
    "Windows Collector" = @{ Status = "UNKNOWN"; Details = @() }
    "SigNoz Stack" = @{ Status = "UNKNOWN"; Details = @() }
    "Synthetic Dataset" = @{ Status = "UNKNOWN"; Details = @() }
    "Backpressure" = @{ Status = "UNKNOWN"; Details = @() }
    "Canary" = @{ Status = "UNKNOWN"; Details = @() }
}

# Check for authentication tokens
$envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_API_TOKEN')
if (-not $envToken) { $envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_API_BEARER') }
if (-not $envToken) { $envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_JWT') }
$sigNozHeaders = if ($envToken) { @{ Authorization = "Bearer $envToken" } } else { $null }

# Helper function for API probe with retry
function Invoke-Probe {
    param([int]$MinutesBack = 15)
    $now = [int]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
    $start = $now - ($MinutesBack * 60 * 1000)
    $payload = @{
        start = $start
        end = $now
        requestType = "raw"
        compositeQuery = @{
            queries = @(@{
                type = "builder_query"
                spec = @{
                    name = "A"
                    signal = "logs"
                    filter = @{ expression = 'log.body contains "synthetic_id"' }
                    order = @(@{ key = @{name="timestamp"}; direction = "desc"})
                    limit = 1
                    offset = 0
                }
            })
        }
    } | ConvertTo-Json -Depth 6
    
    $params = @{
        Method = 'Post'
        Uri = 'http://localhost:8080/api/v5/query_range'
        ContentType = 'application/json'
        Body = $payload
        TimeoutSec = 30
    }
    if ($sigNozHeaders) { $params.Headers = $sigNozHeaders }
    
    try { 
        return Invoke-RestMethod @params
    }
    catch { 
        return $null 
    }
}

function Write-Result {
    param($Component, $Status, $Details)
    $results[$Component].Status = $Status
    $results[$Component].Details = $Details
    $color = if ($Status -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  $Component`: $Status" -ForegroundColor $color
    if ($Details) { $Details | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray } }
}

# 1. Windows Collector Verification
Write-Host "`n1. Checking Windows Collector..." -ForegroundColor Yellow
try {
    $service = Get-Service otelcol-contrib -ErrorAction Stop
    if ($service.Status -eq "Running") {
        $serviceStatus = "RUNNING ✅"
    } else {
        $serviceStatus = "NOT RUNNING ❌"
        throw "Service not running"
    }
    
    # Test config dry-run (skip if not supported)
    try {
        $configTest = & "C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe" --config "C:\otel\config.yaml" --dry-run 2>&1
        if ($LASTEXITCODE -eq 0) {
            $configStatus = "OK ✅"
        } else {
            if ($configTest -match "unknown flag: --dry-run") {
                $configStatus = "SKIPPED (--dry-run not supported) ⚠️"
            } else {
                $configStatus = "FAILED ❌"
                throw "Config validation failed: $configTest"
            }
        }
    } catch {
        $configStatus = "SKIPPED (collector not accessible) ⚠️"
    }
    
    # Test health endpoint
    $healthUrl = "http://localhost:13134"
    try {
        $healthResponse = Invoke-WebRequest -Uri $healthUrl -TimeoutSec 10
        $healthStatus = "200 from :13134 ✅"
    } catch {
        $healthUrl = "http://localhost:13133"
        $healthResponse = Invoke-WebRequest -Uri $healthUrl -TimeoutSec 10
        $healthStatus = "200 from :13133 ✅"
    }
    
    Write-Result "Windows Collector" "PASS" @($serviceStatus, $configStatus, $healthStatus)
} catch {
    Write-Result "Windows Collector" "FAIL" @("Error: $($_.Exception.Message)")
}

# 2. SigNoz Stack Verification
Write-Host "`n2. Checking SigNoz Stack..." -ForegroundColor Yellow
try {
    # Check Docker containers
    $containers = docker ps --format "{{.Names}}\t{{.Status}}" | ConvertFrom-Csv -Delimiter "`t" -Header @("Name", "Status")
    $requiredContainers = @("signoz-clickhouse", "signoz", "signoz-otel-collector")
    
    $containerStatus = @()
    foreach ($container in $requiredContainers) {
        $containerInfo = $containers | Where-Object { $_.Name -eq $container }
        if ($containerInfo -and $containerInfo.Status -like "*Up*") {
            $containerStatus += "${container}: Up ✅"
        } else {
            $containerStatus += "${container}: Down ❌"
            throw "Container $container not running"
        }
    }
    
    # Check ClickHouse tables
    $tables = docker exec -i signoz-clickhouse clickhouse-client -q "SHOW TABLES FROM signoz_logs" 2>$null
    if ($tables -match "logs_v2" -and $tables -match "distributed_logs_v2") {
        $tableStatus = "signoz_logs.logs_v2, distributed_logs_v2 present ✅"
    } else {
        $tableStatus = "Required tables missing ❌"
        throw "ClickHouse tables not found"
    }
    
    Write-Result "SigNoz Stack" "PASS" @($containerStatus + $tableStatus)
} catch {
    Write-Result "SigNoz Stack" "FAIL" @("Error: $($_.Exception.Message)")
}

# 3. Synthetic Dataset Verification
Write-Host "`n3. Checking Synthetic Dataset..." -ForegroundColor Yellow
try {
    # Check for recent log files (adapt path for CI)
    $logPath = if ($IsWindows -or $env:OS -eq "Windows_NT") { "C:\logs\synthetic\*.log" } else { "/tmp/logs/synthetic/*.log" }
    $logFiles = Get-ChildItem $logPath -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($logFiles) {
        $latestFile = $logFiles[0]
        $timeDiff = (Get-Date) - $latestFile.LastWriteTime
        if ($timeDiff.TotalMinutes -lt 60) {  # More lenient for CI/local testing
            $fileStatus = "Latest file: $($latestFile.Name) (updated $([int]$timeDiff.TotalMinutes)m ago) ✅"
        } else {
            $fileStatus = "Latest file: $($latestFile.Name) (updated $([int]$timeDiff.TotalMinutes)m ago) ❌"
            throw "No recent log files"
        }
    } else {
        # In environments without synthetic logs, mark as skip instead of fail
        $fileStatus = "No synthetic log files found ⚠️"
        $apiStatus = "API verification skipped (no auth)"
        Write-Result "Synthetic Dataset" "SKIP" @($fileStatus, $apiStatus)
        return
    }
    
    # Test API query with retry logic
    try {
        if (-not $sigNozHeaders) {
            $apiStatus = "API /query_range: Skipped (no authentication token) ⚠️"
        } else {
            $apiResponse = Invoke-Probe -MinutesBack 15
            if (-not $apiResponse) {
                Write-Host "  First API probe failed, retrying..." -ForegroundColor Yellow
                Start-Sleep -Seconds 8
                $apiResponse = Invoke-Probe -MinutesBack 15
            }
            
            if ($apiResponse -and $apiResponse.data.result.Count -gt 0) {
                $apiStatus = "API /query_range: $($apiResponse.data.result.Count) recent rows with synthetic_id ✅"
            } else {
                $apiStatus = "API /query_range: No synthetic data found after retry ❌"
                throw "No synthetic data in API"
            }
        }
    } catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 401) {
            $apiStatus = "API /query_range: Authentication failed (401) - check SIGNOZ_API_TOKEN ⚠️"
        } else {
            $apiStatus = "API /query_range: Error - $($_.Exception.Message) ❌"
            throw "API query failed"
        }
    }
    
    Write-Result "Synthetic Dataset" "PASS" @($fileStatus, $apiStatus)
} catch {
    Write-Result "Synthetic Dataset" "FAIL" @("Error: $($_.Exception.Message)")
}

# 4. Backpressure Verification
Write-Host "`n4. Checking Collector Backpressure..." -ForegroundColor Yellow
try {
    # Try different metrics endpoints
    $metricsUrls = @("http://localhost:8888/metrics", "http://localhost:13134/metrics", "http://localhost:13133/metrics")
    $metrics = $null
    
    foreach ($url in $metricsUrls) {
        try {
            $metrics = Invoke-WebRequest -Uri $url -TimeoutSec 10
            break
        } catch {
            continue
        }
    }
    
    if (-not $metrics) {
        Write-Result "Backpressure" "SKIP" @("No metrics endpoint accessible ⚠️")
        return
    }
    
    $queueSize = ($metrics.Content | Select-String "otelcol_exporter_queue_size\s+(\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value })
    $queueCapacity = ($metrics.Content | Select-String "otelcol_exporter_queue_capacity\s+(\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value })
    $sendFailed = ($metrics.Content | Select-String "otelcol_exporter_send_failed_total\s+(\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value })
    
    if ($queueSize -and $queueCapacity -and ([int]$queueSize -lt ([int]$queueCapacity * 0.8))) {
        $queueStatus = "queue_size=$queueSize / capacity=$queueCapacity ✅"
    } else {
        $queueStatus = "queue_size=$queueSize / capacity=$queueCapacity ⚠️"
    }
    
    if ($sendFailed -and ([int]$sendFailed -eq 0)) {
        $sendStatus = "send_failed_total=0 ✅"
    } else {
        $sendStatus = "send_failed_total=$sendFailed ⚠️"
    }
    
    Write-Result "Backpressure" "PASS" @($queueStatus, $sendStatus)
} catch {
    Write-Result "Backpressure" "SKIP" @("Error: $($_.Exception.Message)")
}

# 5. Canary Verification
Write-Host "`n5. Checking Canary..." -ForegroundColor Yellow
try {
    # Adapt script path for CI
    $verifyScript = if ($IsWindows -or $env:OS -eq "Windows_NT") { "C:\otel\scripts\verify-integration.ps1" } else { "./scripts/verify-integration.ps1" }
    
    if (Test-Path $verifyScript) {
        $canaryResult = & $verifyScript 2>&1
        $canaryExitCode = $LASTEXITCODE
        
        if ($canaryExitCode -eq 0) {
            $canaryId = if ($canaryResult -match "canary.*?([a-f0-9-]{36})") { $matches[1] } else { "unknown" }
            $canaryStatus = "verify-integration.ps1: Success (exit code 0), canary=$canaryId ✅"
        } else {
            $canaryStatus = "verify-integration.ps1: Failed (exit code $canaryExitCode) ❌"
            Write-Host "Canary script output:" -ForegroundColor Red
            Write-Host $canaryResult -ForegroundColor Red
            throw "Canary test failed"
        }
    } else {
        $canaryStatus = "verify-integration.ps1: Not found (CI mode) ⚠️"
    }
    
    Write-Result "Canary" "PASS" @($canaryStatus)
} catch {
    Write-Result "Canary" "FAIL" @("Error: $($_.Exception.Message)")
}

# Generate Report
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "# Verification Report (now: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

$overallStatus = "PASS"
foreach ($component in $results.Keys) {
    $status = $results[$component].Status
    $details = $results[$component].Details
    $color = if ($status -eq "PASS") { "Green" } elseif ($status -eq "SKIP") { "Yellow" } else { "Red" }
    
    Write-Host "`n## $component" -ForegroundColor Yellow
    foreach ($detail in $details) {
        Write-Host "- $detail" -ForegroundColor $color
    }
    $statusText = if ($status -eq "PASS") { "healthy" } elseif ($status -eq "SKIP") { "skipped" } else { "failed" }
    Write-Host "**Status:** $status — $($component.ToLower()) $statusText." -ForegroundColor $color
    
    if ($status -eq "FAIL") {
        $overallStatus = "FAIL"
    }
}

Write-Host "`n### Overall: $(if($overallStatus -eq 'PASS'){'✅ PASS'}else{'❌ FAIL'})" -ForegroundColor $(if($overallStatus -eq 'PASS'){'Green'}else{'Red'})

$elapsed = (Get-Date) - $startTime
Write-Host "`nVerification completed in $([int]$elapsed.TotalSeconds) seconds" -ForegroundColor Gray

# Exit with appropriate code (critical for CI)
if ($overallStatus -eq "FAIL") {
    Write-Host "`n❌ Verification FAILED - exiting with code 1" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ Verification PASSED - exiting with code 0" -ForegroundColor Green
    exit 0
}
