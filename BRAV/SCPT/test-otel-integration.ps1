# Standalone test for OTel integration without requiring dev server
# Tests the OTLP/HTTP endpoint directly

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

Write-Host "=== OTel Integration Direct Test ===" -ForegroundColor Green

Import-Module (Join-Path $PSScriptRoot 'lib\OtelPorts.psm1') -Force
$script:OtelPorts = Get-OtelPorts

$testEventId = [Guid]::NewGuid().ToString()
$script:artifactsDir = Join-Path (Get-Location) "artifacts"

# Ensure artifacts directory exists
if (-not (Test-Path $script:artifactsDir)) {
    New-Item -Path $script:artifactsDir -ItemType Directory -Force | Out-Null
}

function Write-Pass { param([string]$Message) Write-Host "   [OK] $Message" -ForegroundColor Green }
function Write-Detail { param([string]$Message) if ($Message) { Write-Host "      $Message" -ForegroundColor DarkGray } }
function Write-Fail {
    param([string]$Message)
    Write-Host "   [FAIL] $Message" -ForegroundColor Red
}

Write-Host "`n1. Testing OTLP/HTTP Endpoint:" -ForegroundColor Yellow

# Create a test OTLP payload similar to what our integration sends
$testPayload = @{
    resourceLogs = @(
        @{
            resource = @{
                attributes = @(
                    @{ key = "service.name"; value = @{ stringValue = "resonai-analytics" } },
                    @{ key = "service.namespace"; value = @{ stringValue = "platform" } },
                    @{ key = "deployment.environment"; value = @{ stringValue = "local" } }
                )
            }
            scopeLogs = @(
                @{
                    scope = @{
                        name = "resonai-analytics-client"
                        version = "1.0.0"
                    }
                    logRecords = @(
                        @{
                            timeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000).ToString()
                            observedTimeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000).ToString()
                            severityNumber = 9
                            severityText = "INFO"
                            body = @{
                                stringValue = (@{
                                    event = "wiring_verification_test"
                                    event_id = $testEventId
                                    session_id = "test-session-$testEventId"
                                    variant = "test"
                                    ttv_ms = 150
                                    ua = "PowerShell-Test-Script"
                                    cohort = "test-cohort"
                                    props = @{
                                        test_type = "direct_otlp_test"
                                        timestamp = (Get-Date).ToString("o")
                                    }
                                } | ConvertTo-Json -Compress)
                            }
                            attributes = @(
                                @{ key = "dataset"; value = @{ stringValue = "resonai_analytics" } },
                                @{ key = "event"; value = @{ stringValue = "wiring_verification_test" } },
                                @{ key = "event_id"; value = @{ stringValue = $testEventId } },
                                @{ key = "session_id"; value = @{ stringValue = "test-session-$testEventId" } },
                                @{ key = "variant"; value = @{ stringValue = "test" } },
                                @{ key = "ttv_ms"; value = @{ intValue = 150 } },
                                @{ key = "ua"; value = @{ stringValue = "PowerShell-Test-Script" } },
                                @{ key = "cohort"; value = @{ stringValue = "test-cohort" } }
                            )
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

$otlpUrl = "$(Get-OtelIngestHttpBase -HostName 'localhost' -Ports $script:OtelPorts)/v1/logs"

try {
    Write-Detail "Sending test OTLP payload to $otlpUrl"
    $response = Invoke-RestMethod -Uri $otlpUrl -Method POST -Body $testPayload -ContentType "application/json" -TimeoutSec 10
    
    Write-Pass "OTLP/HTTP endpoint accepted test payload"
    Write-Detail "Response: $($response | ConvertTo-Json)"
    
    # Write test artifact
    $testArtifact = @"
== OTel Integration Direct Test Results ==
Timestamp: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffK")
Test Event ID: $testEventId

OTLP/HTTP Test: PASSED
- Payload sent to $otlpUrl
- Response: $($response | ConvertTo-Json -Compress)

This confirms the OTel Collector is accepting OTLP/HTTP logs
and the integration code should work when the dev server is running.

== Direct OTLP test PASSED ==
"@
    
    $testArtifact | Out-File -FilePath (Join-Path $script:artifactsDir "otlp-direct-test.txt") -Encoding utf8NoBOM
    Write-Pass "Test artifact written to artifacts/otlp-direct-test.txt"
    
} catch {
    Write-Fail "OTLP/HTTP test failed: $($_.Exception.Message)"
    
    $failureArtifact = @"
== OTel Integration Direct Test Results ==
Timestamp: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffK")
Test Event ID: $testEventId

OTLP/HTTP Test: FAILED
- Error: $($_.Exception.Message)
- URL: $otlpUrl

Check:
1. OTel Collector service is running
2. Windows collector OTLP/HTTP ingest port is accessible
3. OTLP HTTP receiver is configured

== Direct OTLP test FAILED ==
"@
    
    $failureArtifact | Out-File -FilePath (Join-Path $script:artifactsDir "otlp-direct-test.txt") -Encoding utf8NoBOM
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "Test Event ID: $testEventId" -ForegroundColor Yellow
Write-Host "Check artifacts/otlp-direct-test.txt for details" -ForegroundColor Yellow
