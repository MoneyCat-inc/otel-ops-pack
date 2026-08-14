# Test Runbook Execution Script
Write-Host "=== Testing Windows Collector -> SigNoz Runbook ===" -ForegroundColor Green

# 1. Test SigNoz UI accessibility
Write-Host "`n1. Testing SigNoz UI accessibility..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri http://localhost:8080 -UseBasicParsing -TimeoutSec 10
    Write-Host "[OK] SigNoz UI accessible (HTTP $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] SigNoz UI not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Test Windows Event Log canary
Write-Host "`n2. Creating Windows Event Log canary..." -ForegroundColor Yellow
try {
    Write-EventLog -LogName Application -Source SigNozTest -EventId 999 -EntryType Information -Message "SigNoz pipeline test event from Runbook - $(Get-Date)"
    Write-Host "[OK] Windows Event Log canary created" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Windows Event Log canary failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 3. Test file log canary
Write-Host "`n3. Creating file log canary..." -ForegroundColor Yellow
try {
    if (-not (Test-Path "C:\logs")) {
        New-Item -Path "C:\logs" -ItemType Directory -Force | Out-Null
        Write-Host "[INFO] Created C:\logs directory" -ForegroundColor Cyan
    }
    
    $timestamp = (Get-Date).ToString('o')
    $canary = '{"event":"signoz_canary","severity":"ERROR","message":"SigNoz pipeline test from runbook","synthetic_id":"pipeline-check","timestamp":"' + $timestamp + '","service":"canary-test"}'
    Add-Content -Path 'C:\logs\app.json' -Value $canary
    Write-Host "[OK] File log canary created in C:\logs\app.json" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] File log canary failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Test OTLP direct canary
Write-Host "`n4. Testing OTLP direct canary..." -ForegroundColor Yellow
try {
    $otlpPayload = @{
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
                                body = @{ stringValue = "SigNoz pipeline test from runbook execution" }
                                attributes = @(
                                    @{ key = "canary"; value = @{ stringValue = "true" } },
                                    @{ key = "synthetic_id"; value = @{ stringValue = "pipeline-check" } }
                                )
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "http://localhost:5321/v1/logs" -Method Post -Body $otlpPayload -ContentType "application/json" -TimeoutSec 10
    Write-Host "[OK] OTLP direct canary sent successfully" -ForegroundColor Green
} catch {
    Write-Host "[WARN] OTLP direct canary failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 5. Verify file contents
Write-Host "`n5. Verifying canary files..." -ForegroundColor Yellow
if (Test-Path "C:\logs\app.json") {
    $lastEntry = Get-Content "C:\logs\app.json" -Tail 1
    Write-Host "[OK] Last file log entry:" -ForegroundColor Green
    Write-Host $lastEntry -ForegroundColor White
} else {
    Write-Host "[WARN] File log not found" -ForegroundColor Yellow
}

# 6. Wait for processing
Write-Host "`n6. Waiting for log processing (10 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 7. Verification instructions
Write-Host "`n=== Verification Instructions ===" -ForegroundColor Green
Write-Host "1. Open SigNoz UI: http://localhost:8080" -ForegroundColor Cyan
Write-Host "2. Navigate to: Observability -> Logs" -ForegroundColor Cyan
Write-Host "3. Apply filter: message contains 'SigNoz pipeline test'" -ForegroundColor Cyan
Write-Host "4. Alternative filters:" -ForegroundColor Cyan
Write-Host "   - message contains 'pipeline test'" -ForegroundColor White
Write-Host "   - service.name = 'canary-test'" -ForegroundColor White
Write-Host "   - synthetic_id = 'pipeline-check'" -ForegroundColor White
Write-Host "   - log.file.path contains 'C:/logs/app.json'" -ForegroundColor White

Write-Host "`n=== Runbook Test Complete ===" -ForegroundColor Green
Write-Host "Canaries emitted at: $(Get-Date)" -ForegroundColor Yellow
