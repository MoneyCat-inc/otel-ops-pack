Write-Host "== Starting Observability Canary Test ==" -ForegroundColor Cyan

$logDir = "C:\\logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
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

try {
    Add-Content -Path $logFile -Value $logContent
    Write-Host "[OK] Wrote canary log entry to $logFile" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Failed to write canary log file: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Windows Event Log entry
$eventSource = "SigNoz-Canary"
try {
    if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
        New-EventLog -LogName Application -Source $eventSource
    }
    Write-EventLog -LogName Application -Source $eventSource -EventId 1001 -EntryType Error -Message "SigNoz canary test - observability pipeline verification"
    Write-Host "[OK] Created Windows Event Log entry" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Unable to write Windows Event Log entry (permission required): $($_.Exception.Message)" -ForegroundColor Yellow
}

function Invoke-OtlpPayload {
    param(
        [string]$Suffix,
        [string]$Body
    )

    $endpoints = @(
        "http://localhost:5318/$Suffix",
        "http://localhost:4318/$Suffix"
    )

    foreach ($endpoint in $endpoints) {
        try {
            Invoke-RestMethod -Uri $endpoint -Method Post -Body $Body -ContentType "application/json" -TimeoutSec 5 | Out-Null
            return $endpoint
        } catch {
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

try {
    $traceEndpoint = Invoke-OtlpPayload -Suffix "v1/traces" -Body $tracePayload
    Write-Host "[OK] Sent OTLP trace ($traceEndpoint)" -ForegroundColor Green
} catch {
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

try {
    $logEndpoint = Invoke-OtlpPayload -Suffix "v1/logs" -Body $logPayload
    Write-Host "[OK] Sent OTLP log ($logEndpoint)" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Failed to send OTLP log: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "-- Verification Steps --" -ForegroundColor Cyan
Write-Host "1. SigNoz UI -> Logs -> filter: message contains 'canary test'" -ForegroundColor White
Write-Host "2. SigNoz UI -> Traces -> filter: canary='true'" -ForegroundColor White
Write-Host "3. Windows Event Viewer -> Application -> Source 'SigNoz-Canary'" -ForegroundColor White
Write-Host "4. Confirm canary log file updated at $logFile" -ForegroundColor White

Write-Host "Run verify-pipeline.ps1 and verify-integration.ps1 after a few seconds to confirm ingestion." -ForegroundColor Yellow


