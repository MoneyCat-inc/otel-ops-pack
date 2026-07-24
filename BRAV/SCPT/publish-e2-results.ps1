# HISTORICAL (Gate-era): ports 5317/5318 predate the 5320/5321 move. Do not use as reference. See windows/otelcol/README.md.
# Publish E2 Ratio Sweep Results to SigNoz
# Sends E2 test results via OTLP HTTP to SigNoz for dashboard visualization

param(
    [string]$ResultsFile = "artifacts/e2-ratio-sweep-results.json",
    [string]$Endpoint = "http://127.0.0.1:5318/v1/logs"
)

Write-Host "=== Publishing E2 Ratio Sweep Results to SigNoz ===" -ForegroundColor Cyan
Write-Host "Results file: $ResultsFile" -ForegroundColor Yellow
Write-Host "Endpoint: $Endpoint" -ForegroundColor Yellow

# Check if results file exists
if (-not (Test-Path $ResultsFile)) {
    Write-Error "Results file not found: $ResultsFile"
    exit 1
}

# Load results
try {
    $results = Get-Content $ResultsFile | ConvertFrom-Json
    Write-Host "Loaded results for $($results.combinations.Count) combinations" -ForegroundColor Green
} catch {
    Write-Error "Failed to load results file: $($_.Exception.Message)"
    exit 1
}

# Check endpoint connectivity
Write-Host "`nChecking endpoint connectivity..." -ForegroundColor Yellow
try {
    $testConnection = Test-NetConnection -ComputerName 127.0.0.1 -Port 5318 -WarningAction SilentlyContinue
    if (-not $testConnection.TcpTestSucceeded) {
        Write-Warning "Cannot reach OTLP endpoint at $Endpoint. Please ensure collector is running."
        Write-Host "You can manually check SigNoz UI at http://127.0.0.1:8080" -ForegroundColor Cyan
        exit 1
    }
    Write-Host "✓ OTLP endpoint is reachable" -ForegroundColor Green
} catch {
    Write-Warning "Could not test endpoint connectivity: $($_.Exception.Message)"
}

# Create OTLP log records
Write-Host "`nCreating OTLP log records..." -ForegroundColor Yellow

$logRecords = @()
$currentTime = ([UInt64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) * 1000000)

foreach ($combo in $results.combinations) {
    $logRecord = @{
        timeUnixNano = $currentTime.ToString()
        severityText = "INFO"
        body = @{
            stringValue = ($combo | ConvertTo-Json -Compress)
        }
        attributes = @(
            @{
                key = "dataset"
                value = @{
                    stringValue = "e2_ratio_sweep"
                }
            },
            @{
                key = "log_type"
                value = @{
                    stringValue = "e2_result"
                }
            },
            @{
                key = "test_id"
                value = @{
                    stringValue = $combo.test_id
                }
            },
            @{
                key = "agent_timeout"
                value = @{
                    stringValue = $combo.agent_timeout
                }
            },
            @{
                key = "gateway_timeout"
                value = @{
                    stringValue = $combo.gateway_timeout
                }
            },
            @{
                key = "p95_latency_ms"
                value = @{
                    doubleValue = $combo.metrics.p95_latency_ms
                }
            },
            @{
                key = "queue_utilization_percent"
                value = @{
                    doubleValue = $combo.metrics.queue_utilization_percent
                }
            },
            @{
                key = "batch_efficiency_percent"
                value = @{
                    doubleValue = $combo.metrics.batch_efficiency_percent
                }
            }
        )
    }
    
    $logRecords += $logRecord
    $currentTime += 1000000  # Add 1ms in nanoseconds
}

Write-Host "Created $($logRecords.Count) log records" -ForegroundColor Green

# Create OTLP payload
$otlpPayload = @{
    resourceLogs = @(
        @{
            resource = @{
                attributes = @(
                    @{
                        key = "service.name"
                        value = @{
                            stringValue = "e2-ratio-sweep-publisher"
                        }
                    },
                    @{
                        key = "service.namespace"
                        value = @{
                            stringValue = "observability"
                        }
                    },
                    @{
                        key = "deployment.environment"
                        value = @{
                            stringValue = "local"
                        }
                    }
                )
            }
            scopeLogs = @(
                @{
                    scope = @{
                        name = "e2-ratio-sweep"
                        version = "1.0.0"
                    }
                    logRecords = $logRecords
                }
            )
        }
    )
}

# Convert to JSON
$bodyJson = $otlpPayload | ConvertTo-Json -Depth 10

Write-Host "`nPublishing to SigNoz..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri $Endpoint -Method Post -ContentType 'application/json' -Body $bodyJson
    Write-Host "✓ Published $($logRecords.Count) log records to $Endpoint" -ForegroundColor Green
    
    # Display summary
    Write-Host "`n=== Published E2 Results Summary ===" -ForegroundColor Green
    Write-Host "Total combinations: $($logRecords.Count)" -ForegroundColor White
    Write-Host "Dataset: e2_ratio_sweep" -ForegroundColor White
    Write-Host "Log type: e2_result" -ForegroundColor White
    
    # Show optimal configuration
    $optimal = $results.combinations | Where-Object { $_.test_id -eq "E2-005" } | Select-Object -First 1
    if ($optimal) {
        Write-Host "`nOptimal Configuration (E2-005):" -ForegroundColor Yellow
        Write-Host "  Agent Timeout: $($optimal.agent_timeout)" -ForegroundColor White
        Write-Host "  Gateway Timeout: $($optimal.gateway_timeout)" -ForegroundColor White
        Write-Host "  P95 Latency: $($optimal.metrics.p95_latency_ms) ms" -ForegroundColor White
        Write-Host "  Queue Utilization: $($optimal.metrics.queue_utilization_percent)%" -ForegroundColor White
        Write-Host "  Batch Efficiency: $($optimal.metrics.batch_efficiency_percent)%" -ForegroundColor White
    }
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Import dashboard: pwsh -File scripts/import-dashboard.ps1" -ForegroundColor White
    Write-Host "2. Check SigNoz UI: http://127.0.0.1:8080" -ForegroundColor White
    Write-Host "3. Filter logs: dataset = 'e2_ratio_sweep' AND log_type = 'e2_result'" -ForegroundColor White
    
} catch {
    Write-Error "Failed to publish logs: $($_.Exception.Message)"
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
    exit 1
}

Write-Host "`nE2 results published successfully!" -ForegroundColor Green
