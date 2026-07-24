# HISTORICAL (Gate-era): ports 5317/5318 predate the 5320/5321 move. Do not use as reference. See windows/otelcol/README.md.
# BOSSCAT-022A: End-to-End OTLP Test
# Purpose: Generate and verify traces, metrics, and logs through Windows collector
# Authority: BossCat OEM | Executor: Cursor{Implementer}

param(
  [string]$SigNozUrl = "http://localhost:8080",
  [int]$WaitSeconds = 15
)

$ErrorActionPreference = "Continue"

Write-Host "=== BOSSCAT-022A :: End-to-End OTLP Test ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Generate Windows Event Log (Logs signal)
Write-Host "[1/3] Generating Windows Event Log..." -ForegroundColor White
try {
  $eid = Get-Random -Minimum 60000 -Maximum 65000
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $message = "BOSSCAT-022A E2E Test | EID=${eid} | Timestamp=${timestamp} | Signal=LOGS"
  
  if (-not [System.Diagnostics.EventLog]::SourceExists("VizCanary")) {
    New-EventLog -LogName Application -Source "VizCanary"
  }
  
  Write-EventLog -LogName Application -Source "VizCanary" -EventId $eid -EntryType Information -Message $message
  Write-Host "  [OK] Event written (EID: $eid)" -ForegroundColor Green
  $logEventId = $eid
} catch {
  Write-Host "  [FAIL] Could not write event: $_" -ForegroundColor Red
  $logEventId = $null
}

# Test 2: Send synthetic metric via OTLP HTTP (Metrics signal)
Write-Host ""
Write-Host "[2/3] Sending synthetic metric via OTLP HTTP..." -ForegroundColor White
try {
  $metricTimestamp = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) * 1000000
  $metricsPayload = @{
    resourceMetrics = @(
      @{
        resource = @{
          attributes = @(
            @{ key = "service.name"; value = @{ stringValue = "bosscat-022a-test" } }
            @{ key = "deployment.environment"; value = @{ stringValue = "local" } }
          )
        }
        scopeMetrics = @(
          @{
            scope = @{ name = "bosscat-022a" }
            metrics = @(
              @{
                name = "bosscat_022a_e2e_metric"
                description = "BOSSCAT-022A E2E metric probe"
                gauge = @{
                  dataPoints = @(
                    @{
                      asInt = 1
                      timeUnixNano = [string]$metricTimestamp
                      attributes = @(
                        @{ key = "test.type"; value = @{ stringValue = "e2e-verification" } }
                      )
                    }
                  )
                }
              }
            )
          }
        )
      }
    )
  } | ConvertTo-Json -Depth 12

  $response = Invoke-WebRequest -Uri "http://127.0.0.1:5318/v1/metrics" `
    -Method POST `
    -Headers @{ "Content-Type" = "application/json" } `
    -Body $metricsPayload `
    -TimeoutSec 5 `
    -UseBasicParsing

  if ($response.StatusCode -eq 200) {
    Write-Host "  [OK] Metric sent via collector OTLP HTTP (5318)" -ForegroundColor Green
    $metricsActive = $true
  } else {
    Write-Host "  [WARN] Unexpected response: $($response.StatusCode)" -ForegroundColor Yellow
    $metricsActive = $false
  }
} catch {
  Write-Host "  [FAIL] Could not send metric: $_" -ForegroundColor Red
  $metricsActive = $false
}

# Test 3: Send synthetic trace via OTLP HTTP (Traces signal)
Write-Host ""
Write-Host "[3/3] Sending synthetic trace..." -ForegroundColor White
try {
  $traceId = -join ((1..32) | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) })
  $spanId = -join ((1..16) | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) })
  $epoch = [DateTimeOffset]::new(1970, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
  $nowSeconds = [Math]::Floor(([DateTimeOffset]::UtcNow - $epoch).TotalSeconds)
  $now = [long]($nowSeconds * 1000000000)
  
  $tracePayload = @{
    resourceSpans = @(
      @{
        resource = @{
          attributes = @(
            @{ key = "service.name"; value = @{ stringValue = "bosscat-022a-test" } }
            @{ key = "service.version"; value = @{ stringValue = "1.0.0" } }
            @{ key = "deployment.environment"; value = @{ stringValue = "local" } }
            @{ key = "host.type"; value = @{ stringValue = "windows" } }
          )
        }
        scopeSpans = @(
          @{
            scope = @{ name = "bosscat-022a" }
            spans = @(
              @{
                traceId = $traceId
                spanId = $spanId
                name = "BOSSCAT-022A-E2E-Test"
                kind = 1
                startTimeUnixNano = [string]$now
                endTimeUnixNano = [string]($now + 100000000)
                attributes = @(
                  @{ key = "test.type"; value = @{ stringValue = "e2e-verification" } }
                  @{ key = "test.timestamp"; value = @{ stringValue = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") } }
                )
              }
            )
          }
        )
      }
    )
  } | ConvertTo-Json -Depth 12
  
  $headers = @{
    "Content-Type" = "application/json"
  }
  
  $response = Invoke-WebRequest -Uri "http://127.0.0.1:5318/v1/traces" `
    -Method POST `
    -Headers $headers `
    -Body $tracePayload `
    -TimeoutSec 5 `
    -UseBasicParsing
  
  if ($response.StatusCode -eq 200) {
    Write-Host "  [OK] Trace sent successfully (TraceID: $($traceId.Substring(0,16))...)" -ForegroundColor Green
    $traceSuccess = $true
    $traceIdShort = $traceId
  } else {
    Write-Host "  [WARN] Unexpected response: $($response.StatusCode)" -ForegroundColor Yellow
    $traceSuccess = $false
    $traceIdShort = $null
  }
} catch {
  Write-Host "  [FAIL] Could not send trace: $_" -ForegroundColor Red
  $traceSuccess = $false
  $traceIdShort = $null
}

# Wait for ingestion
Write-Host ""
Write-Host "Waiting ${WaitSeconds}s for ingestion..." -ForegroundColor Gray
Start-Sleep -Seconds $WaitSeconds

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor White
Write-Host ""
Write-Host "Signal Status:" -ForegroundColor White
Write-Host "  Logs:    $(if ($logEventId) { '[OK]' } else { '[FAIL]' }) $(if ($logEventId) { "Event ID $logEventId" } else { 'Not generated' })" -ForegroundColor $(if ($logEventId) { 'Green' } else { 'Red' })
Write-Host "  Metrics: $(if ($metricsActive) { '[OK]' } else { '[FAIL]' }) $(if ($metricsActive) { 'Sent via collector OTLP HTTP (5318)' } else { 'Not sent' })" -ForegroundColor $(if ($metricsActive) { 'Green' } else { 'Red' })
Write-Host "  Traces:  $(if ($traceSuccess) { '[OK]' } else { '[FAIL]' }) $(if ($traceSuccess) { "Sent via collector OTLP HTTP (5318)" } else { 'Not sent' })" -ForegroundColor $(if ($traceSuccess) { 'Green' } else { 'Red' })
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Verify in SigNoz UI: $SigNozUrl" -ForegroundColor Gray
Write-Host "  2. Search for 'BOSSCAT-022A' in logs" -ForegroundColor Gray
Write-Host "  3. Check for service 'bosscat-022a-test' in traces" -ForegroundColor Gray
Write-Host "  4. Look for metric 'bosscat_022a_e2e_metric' in SigNoz" -ForegroundColor Gray
Write-Host ""

# Return results
$results = @{
  logs = @{
    success = $null -ne $logEventId
    eventId = $logEventId
  }
  metrics = @{
    success = $metricsActive
  }
  traces = @{
    success = $traceSuccess
    traceId = $traceIdShort
  }
}

return $results

