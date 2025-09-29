# Manual Log Test for SigNoz

## Test 1: Send Log via OTLP HTTP
```powershell
$logData = @{
    resourceLogs = @(
        @{
            resource = @{
                attributes = @(
                    @{ key = "service.name"; value = @{ stringValue = "test-service" } }
                )
            }
            scopeLogs = @(
                @{
                    scope = @{}
                    logRecords = @(
                        @{
                            timeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                            severityNumber = 9
                            severityText = "INFO"
                            body = @{ stringValue = '{"test": "manual log", "queueLength": 14}' }
                            attributes = @(
                                @{ key = "log.file.path"; value = @{ stringValue = "C:/logs/test.log" } }
                            )
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "http://localhost:5318/v1/logs" -Method POST -Body $logData -ContentType "application/json"
```

## Test 2: Check if Log Appears
After running Test 1, check SigNoz Logs Explorer for:
- Search: `body contains "manual log"`
- Time Range: Last 5 minutes

## Expected Results
If this works, we know:
- ✅ OTLP endpoint is working
- ✅ SigNoz can receive logs
- ❌ File log processing has an issue

If this doesn't work:
- ❌ OTLP endpoint issue
- ❌ SigNoz ingestion problem


