# Canary Test Script
# Updated with progress indicators for better user experience

# Import progress indicators module
. .\BRAV\SCPT\progress-indicators.ps1
Import-Module (Join-Path $PSScriptRoot 'BRAV\SCPT\lib\OtelPorts.psm1') -Force
$script:OtelPorts = Get-OtelPorts

Write-Host "== Starting Observability Canary Test ==" -ForegroundColor Cyan

$logDir = "C:\\logs"
if (-not (Test-Path $logDir)) {
    $spinnerJob = Start-SpinnerJob -Message "Creating log directory..." -UpdateIntervalMs 150
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Stop-SpinnerJob -Job $spinnerJob
}

$logFile = Join-Path $logDir "canary-test.log"
$logContent = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    level = "ERROR"
    message = "SigNoz canary test error - pipeline verification"
    service = "canary-test"
    canary = "true"
    error_code = "CANARY_001"
} | ConvertTo-Json -Compress

$spinnerJob = Start-SpinnerJob -Message "Writing canary log entry..." -UpdateIntervalMs 150
try {
    Add-Content -Path $logFile -Value $logContent
    Stop-SpinnerJob -Job $spinnerJob
    Write-Host "[OK] Wrote canary log entry to $logFile" -ForegroundColor Green
} catch {
    Stop-SpinnerJob -Job $spinnerJob
    Write-Host "[WARN] Failed to write canary log file: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Windows Event Log entry
$eventSource = "SigNoz-Canary"
$spinnerJob = Start-SpinnerJob -Message "Creating Windows Event Log entry..." -UpdateIntervalMs 150
try {
    if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
        New-EventLog -LogName Application -Source $eventSource
    }
    Write-EventLog -LogName Application -Source $eventSource -EventId 1001 -EntryType Error -Message "SigNoz canary test - observability pipeline verification"
    Stop-SpinnerJob -Job $spinnerJob
    Write-Host "[OK] Created Windows Event Log entry" -ForegroundColor Green
} catch {
    Stop-SpinnerJob -Job $spinnerJob
    Write-Host "[WARN] Unable to write Windows Event Log entry (permission required): $($_.Exception.Message)" -ForegroundColor Yellow
}

function Invoke-OtlpPayload {
    param(
        [string]$Suffix,
        [string]$Body
    )

    $endpoints = @(
        "$(Get-OtelIngestHttpBase -HostName 'localhost' -Ports $script:OtelPorts)/$Suffix",
        "http://localhost:$($script:OtelPorts.SignozOtlpHttp)/$Suffix"
    )

    foreach ($endpoint in $endpoints) {
        $spinnerJob = Start-SpinnerJob -Message "Sending OTLP payload to $endpoint..." -UpdateIntervalMs 150
        try {
            Invoke-RestMethod -Uri $endpoint -Method Post -Body $Body -ContentType "application/json" -TimeoutSec 5 | Out-Null
            Stop-SpinnerJob -Job $spinnerJob
            return $endpoint
        } catch {
            Stop-SpinnerJob -Job $spinnerJob
            $lastError = $_
        }
    }

    throw $lastError
}

# OTLP trace
$tracePayload = @{
    resourceSpans = @(
        @{
            resource = @{
                attributes = @(
                    @{ key = "service.name"; value = @{ stringValue = "canary-test" } },
                    @{ key = "canary"; value = @{ stringValue = "true" } }
                )
            }
            scopeSpans = @(
                @{
                    spans = @(
                        @{
                            traceId = "12345678901234567890123456789012"
                            spanId = "1234567890123456"
                            name = "canary-test-span"
                            kind = 1
                            startTimeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
                            endTimeUnixNano = (([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + 100) * 1000000)
                            attributes = @(
                                @{ key = "canary"; value = @{ stringValue = "true" } },
                                @{ key = "test.type"; value = @{ stringValue = "pipeline-verification" } }
                            )
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

$spinnerJob = Start-SpinnerJob -Message "Sending OTLP trace payload..." -UpdateIntervalMs 150
try {
    $traceEndpoint = Invoke-OtlpPayload -Suffix "v1/traces" -Body $tracePayload
    Stop-SpinnerJob -Job $spinnerJob
    Write-Host "[OK] Sent OTLP trace ($traceEndpoint)" -ForegroundColor Green
} catch {
    Stop-SpinnerJob -Job $spinnerJob
    Write-Host "[WARN] Failed to send OTLP trace: $($_.Exception.Message)" -ForegroundColor Yellow
}

# OTLP log
$logPayload = @{
    resourceLogs = @(
        @{
            resource = @{
                attributes = @(
                    @{ key = "service.name"; value = @{ stringValue = "canary-test" } }
                )
            }
            scopeLogs = @(
                @{
                    logRecords = @(
                        @{
                            timeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
                            severityNumber = 17
                            severityText = "ERROR"
                            body = @{ stringValue = "SigNoz canary test log - pipeline verification" }
                            attributes = @(
                                @{ key = "canary"; value = @{ stringValue = "true" } },
                                @{ key = "test.type"; value = @{ stringValue = "pipeline-verification" } }
                            )
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

$spinnerJob = Start-SpinnerJob -Message "Sending OTLP log payload..." -UpdateIntervalMs 150
try {
    $logEndpoint = Invoke-OtlpPayload -Suffix "v1/logs" -Body $logPayload
    Stop-SpinnerJob -Job $spinnerJob
    Write-Host "[OK] Sent OTLP log ($logEndpoint)" -ForegroundColor Green
} catch {
    Stop-SpinnerJob -Job $spinnerJob
    Write-Host "[WARN] Failed to send OTLP log: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "-- Verification Steps --" -ForegroundColor Cyan
Write-Host "1. SigNoz UI -> Logs -> filter: message contains 'canary test'" -ForegroundColor White
Write-Host "2. SigNoz UI -> Traces -> filter: canary='true'" -ForegroundColor White
Write-Host "3. Windows Event Viewer -> Application -> Source 'SigNoz-Canary'" -ForegroundColor White
Write-Host "4. Confirm canary log file updated at $logFile" -ForegroundColor White

Write-Host "Run operator-pipeline-check.ps1 and scripts\verify-integration.ps1 after a few seconds to confirm ingestion." -ForegroundColor Yellow


