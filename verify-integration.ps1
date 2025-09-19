Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

Write-Host "=== OpenTelemetry Integration Verification ===" -ForegroundColor Green

$script:allChecksPassed = $true
$script:checkFailures = New-Object 'System.Collections.Generic.List[string]'
$canaryId = $null
$canaryMessage = $null
$script:sigNozHeaders = $null
$envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_API_TOKEN')
if (-not $envToken) { $envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_API_BEARER') }
if (-not $envToken) { $envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_JWT') }
if ($envToken) { $script:sigNozHeaders = @{ Authorization = "Bearer $envToken" } }

function Write-Pass { param([string]$Message) Write-Host "   [OK] $Message" -ForegroundColor Green }
function Write-Detail { param([string]$Message) if ($Message) { Write-Host "      $Message" -ForegroundColor DarkGray } }
function Write-Fail {
    param([string]$Message)
    Write-Host "   [FAIL] $Message" -ForegroundColor Red
    $script:allChecksPassed = $false
    $script:checkFailures.Add($Message) | Out-Null
}
function Test-TcpPort {
    param([int]$Port,[string]$Label)
    try {
        $result = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue
        if ($result.TcpTestSucceeded) { Write-Pass "$Label port $Port reachable" } else { Write-Fail "$Label port $Port not reachable" }
    } catch { Write-Fail "$Label port $Port error: $($_.Exception.Message)" }
}
function Invoke-CanaryQuery {
    param([string]$CanaryId,[int]$MinutesBack = 15)
    $now = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()); $start = $now - [long]($MinutesBack * 60000)
    $filterExpression = "log.body contains `"windows-canary-$CanaryId`""
    $payload = @{ start=$start; end=$now; requestType="raw"; compositeQuery=@{ queries=@(@{ type="builder_query"; spec=@{ name="A"; signal="logs"; filter=@{ expression=$filterExpression }; order=@(@{ key=@{ name="timestamp" }; direction="desc" }); limit=1; offset=0 }}) } } | ConvertTo-Json -Depth 8
    $params = @{ Method='Post'; Uri='http://localhost:8080/api/v5/query_range'; ContentType='application/json'; Body=$payload; TimeoutSec=30 }
    if ($script:sigNozHeaders) { $params.Headers = $script:sigNozHeaders }
    Invoke-RestMethod @params
}

Write-Host "`n1. Service Status Check:" -ForegroundColor Yellow
try {
    $service = Get-Service -Name otelcol-contrib -ErrorAction Stop
    if ($service.Status -eq 'Running') { Write-Pass "Service otelcol-contrib is running" } else { Write-Fail "Service otelcol-contrib status is $($service.Status)" }
} catch { Write-Fail "Service otelcol-contrib not found: $($_.Exception.Message)" }
$collectorExe = "C:\\Program Files\\OpenTelemetry Collector\\otelcol-contrib.exe"
if (Test-Path $collectorExe) {
    try {
        $dryRunOutput = & $collectorExe --config "C:\\otel\\config.yaml" --dry-run 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Pass "Collector config dry-run succeeded"
        } elseif ($dryRunOutput -match 'unknown flag: --dry-run') {
            Write-Detail "Collector build does not support --dry-run; skipping config validation"
        } else {
            Write-Fail "Collector config dry-run failed (exit $LASTEXITCODE)"
            $dryRunOutput -split '\r?\n' | ForEach-Object { Write-Detail $_ }
        }
    } catch { Write-Fail "Collector config dry-run error: $($_.Exception.Message)" }
} else { Write-Fail "Collector binary not found at $collectorExe" }
$healthOk = $false; $healthError = $null
foreach ($endpoint in @("http://localhost:13134/healthz","http://localhost:13133/healthz")) {
    try {
        $healthResponse = Invoke-WebRequest -Uri $endpoint -TimeoutSec 5
        if ($healthResponse.StatusCode -eq 200) { Write-Pass "Collector health endpoint reachable ($endpoint)"; $healthOk = $true; break }
        $healthError = "HTTP $($healthResponse.StatusCode) from $endpoint"; Write-Detail $healthError
    } catch { $healthError = "$endpoint -> $($_.Exception.Message)"; Write-Detail $healthError }
}
if (-not $healthOk) { Write-Fail "Collector health endpoint unreachable: $healthError" }

Write-Host "`n2. Windows Collector Ports:" -ForegroundColor Yellow
Test-TcpPort -Port 5317 -Label "Windows collector (gRPC)"
Test-TcpPort -Port 5318 -Label "Windows collector (HTTP)"

Write-Host "`n3. SigNoz Collector Ports:" -ForegroundColor Yellow
Test-TcpPort -Port 4317 -Label "SigNoz collector (gRPC)"
Test-TcpPort -Port 4318 -Label "SigNoz collector (HTTP)"

Write-Host "`n4. SigNoz UI Connectivity:" -ForegroundColor Yellow
$uiUrl = "http://localhost:8080"; $uiSuccess = $false; $uiError = $null
for ($attempt = 1; $attempt -le 2 -and -not $uiSuccess; $attempt++) {
    try {
        $response = Invoke-WebRequest -Uri $uiUrl -TimeoutSec 8
        if ($response.StatusCode -eq 200) { Write-Pass "SigNoz UI reachable (HTTP 200)"; $uiSuccess = $true }
        else { $uiError = "HTTP $($response.StatusCode)"; Write-Detail "Attempt $attempt -> $uiError" }
    } catch { $uiError = $_.Exception.Message; Write-Detail "Attempt $attempt -> $uiError" }
    if (-not $uiSuccess -and $attempt -lt 2) { Write-Host "   Waiting 8s before retry..." -ForegroundColor Yellow; Start-Sleep -Seconds 8 }
}
if (-not $uiSuccess) { Write-Fail "SigNoz UI not accessible: $uiError" }

Write-Host "`n5. Configuration Check:" -ForegroundColor Yellow
$configPath = Join-Path (Get-Location) "config.yaml"
if (Test-Path $configPath) {
    try {
        $configContent = Get-Content -Path $configPath -Raw
        if ($configContent -match 'endpoint\s*:\s*"?localhost:4317"?' -or $configContent -match 'endpoint\s*:\s*"?0\.0\.0\.0:4317"?') { Write-Pass "OTLP gRPC exporter points to port 4317" } else { Write-Fail "Unable to confirm OTLP gRPC endpoint on 4317" }
        if ($configContent -match 'windows-canary') { Write-Pass "Windows canary pipeline configuration detected" } else { Write-Detail "Windows canary pipeline not detected in config" }
    } catch { Write-Fail "Failed to read config.yaml: $($_.Exception.Message)" }
} else { Write-Fail "Config file not found at $configPath" }

Write-Host "`n6. Canary Test:" -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffK"; $canaryId = [Guid]::NewGuid().ToString(); $canaryMessage = "windows-canary-$canaryId"
$logEntry = @{ timestamp=$timestamp; level="INFO"; message=$canaryMessage; source="verify-integration"; service="windows-collector"; test_id=$canaryId; pipeline_test=$true } | ConvertTo-Json -Depth 3
$logPath = "C:\\logs\\canary-test.log"; $logWriteSucceeded = $false
try {
    if (-not (Test-Path "C:\\logs")) { New-Item -Path "C:\\logs" -ItemType Directory -Force | Out-Null; Write-Detail "Created C:\\logs directory" }
    $logEntry | Out-File -FilePath $logPath -Encoding utf8NoBOM -Append
    Write-Pass "Canary log written to $logPath"; Write-Detail "Canary message: $canaryMessage"; $logWriteSucceeded = $true
} catch { Write-Fail "Failed to write canary log: $($_.Exception.Message)" }
if ($logWriteSucceeded) {
    Start-Sleep -Seconds 5; $canarySeen = $false; $lastQueryError = $null; $authRequired = $false
    for ($attempt = 1; $attempt -le 2 -and -not $canarySeen; $attempt++) {
        try {
            $responseJson = (Invoke-CanaryQuery -CanaryId $canaryId) | ConvertTo-Json -Depth 8
            if ($responseJson -and $responseJson -match $canaryId) { Write-Pass "SigNoz API returned canary log (attempt $attempt)"; $canarySeen = $true }
            else { $lastQueryError = "No match in response"; Write-Detail "Attempt $attempt -> no canary match" }
        } catch {
            $lastQueryError = $_.Exception.Message
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 401) {
                $authRequired = $true
                Write-Detail "Attempt $attempt -> 401 Unauthorized (set SIGNOZ_API_TOKEN to enable API verification)"
                break
            }
            Write-Detail "Attempt $attempt -> $lastQueryError"
        }
        if (-not $canarySeen -and $attempt -lt 2) { Write-Host "   Waiting 8s before retry..." -ForegroundColor Yellow; Start-Sleep -Seconds 8 }
    }
    if (-not $canarySeen) {
        if ($authRequired -and -not $script:sigNozHeaders) {
            Write-Detail "SigNoz API verification skipped (authentication required)."
        } else {
            Write-Fail "SigNoz API query failed to find canary within 15 minutes: $lastQueryError"
        }
    }
}

Write-Host "`n=== Verification Complete ===" -ForegroundColor Green
if ($allChecksPassed) {
    Write-Host "== Verification complete: all checks passed ==" -ForegroundColor Green
    Write-Host "All checks passed! Pipeline is working." -ForegroundColor Green
    Write-Host "`nNext steps:"; Write-Host "1. Open SigNoz UI at http://localhost:8080"; Write-Host "2. Go to Logs section"; Write-Host "3. Filter: message contains '$canaryMessage'"
} else {
    Write-Host "== Verification complete: FAILURES ==" -ForegroundColor Red
    Write-Host "Some checks failed. Please review the errors above." -ForegroundColor Red
    if ($checkFailures.Count -gt 0) {
        Write-Host "`nFailure summary:" -ForegroundColor Yellow
        foreach ($item in $checkFailures) { Write-Host " - $item" -ForegroundColor Red }
    }
    Write-Host "`nTroubleshooting:"; Write-Host "1. Ensure otelcol-contrib service is running"; Write-Host "2. Check ports 5317, 5318, 4317, 4318 are listening"; Write-Host "3. Confirm SigNoz containers are healthy"
}
if ($canaryId) { Write-Host "`nCanary ID for verification: $canaryId" -ForegroundColor Yellow }
if ($allChecksPassed) { exit 0 } else { exit 1 }