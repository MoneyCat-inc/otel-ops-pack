# Send OTLP traces directly to SigNoz (Path A smoke test)
# Bypasses Windows otelcol; proves SigNoz ClickHouse ingestion works

$endpoint = "http://localhost:5318/v1/traces"
$traceId = [guid]::NewGuid().ToString("N")
$spanIds = @(
    [guid]::NewGuid().ToString("N").Substring(0, 16),
    [guid]::NewGuid().ToString("N").Substring(0, 16),
    [guid]::NewGuid().ToString("N").Substring(0, 16)
)

$timestamp = [int64]([DateTime]::UtcNow.Ticks - 621355968000000000) * 100

Write-Host "Sending 3 OTLP traces to $endpoint"
Write-Host "TraceID: $traceId"
Write-Host "ServiceName: canary-test"
Write-Host ""

# Build OTLP TraceProto JSON (Protobuf JSON format)
$otlpPayload = @{
    resourceSpans = @(
        @{
            resource = @{
                attributes = @(
                    @{
                        key = "service.name"
                        value = @{ stringValue = "canary-test" }
                    },
                    @{
                        key = "deployment.environment"
                        value = @{ stringValue = "local" }
                    }
                )
            }
            scopeSpans = @(
                @{
                    spans = @(
                        @{
                            traceId = $traceId
                            spanId = $spanIds[0]
                            name = "canary-trace-span-1"
                            kind = 1
                            startTimeUnixNano = $timestamp.ToString()
                            endTimeUnixNano = ($timestamp + 1000000).ToString()
                            attributes = @(
                                @{
                                    key = "canary"
                                    value = @{ stringValue = "true" }
                                }
                            )
                        },
                        @{
                            traceId = $traceId
                            spanId = $spanIds[1]
                            parentSpanId = $spanIds[0]
                            name = "canary-trace-span-2"
                            kind = 1
                            startTimeUnixNano = ($timestamp + 500000).ToString()
                            endTimeUnixNano = ($timestamp + 1500000).ToString()
                        },
                        @{
                            traceId = $traceId
                            spanId = $spanIds[2]
                            parentSpanId = $spanIds[1]
                            name = "canary-trace-span-3"
                            kind = 1
                            startTimeUnixNano = ($timestamp + 1000000).ToString()
                            endTimeUnixNano = ($timestamp + 2000000).ToString()
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10 -Compress

Write-Host "Sending OTLP payload..."
try {
    $response = Invoke-WebRequest -Uri $endpoint `
        -Method POST `
        -ContentType "application/json" `
        -Body $otlpPayload `
        -ErrorAction Stop `
        -TimeoutSec 5

    Write-Host "✅ SUCCESS: HTTP $($response.StatusCode)"
    Write-Host "Traces sent: 3"
    Write-Host "Service name: canary-test"
    Write-Host ""
    Write-Host "Next step: Query ClickHouse to verify ingestion..."
    Write-Host ""
    Write-Host "docker exec signoz-clickhouse clickhouse-client --database=signoz_traces --query 'SELECT COUNT() FROM distributed_signoz_spans WHERE serviceName=''canary-test'' AND timestamp >= now()-INTERVAL 2 MINUTE;'"
}
catch {
    Write-Host "FAILED: $_"
    exit 1
}
