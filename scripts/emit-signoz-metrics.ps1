# IONA SigNoz Metrics Emitter
# Emits error metrics to SigNoz OTLP endpoint for unified observability

param(
    [Parameter(Mandatory=$true)]
    [string]$MetricType,
    
    [Parameter(Mandatory=$true)]
    [string]$MetricName,
    
    [Parameter(Mandatory=$true)]
    [double]$MetricValue,
    
    [hashtable]$Labels = @{},
    
    [string]$SigNozEndpoint = "http://localhost:14318/v1/metrics",
    
    [switch]$Verbose
)

# Configuration
$Timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$ServiceName = "iona-error-system"
$ServiceVersion = "1.1"

# Default labels
$DefaultLabels = @{
    "service.name" = $ServiceName
    "service.version" = $ServiceVersion
    "environment" = "local"
    "component" = "error-cataloguing"
}

# Merge with provided labels
$AllLabels = $DefaultLabels + $Labels

# Create OTLP metrics payload
$MetricsPayload = @{
    resourceMetrics = @(
        @{
            resource = @{
                attributes = @(
                    @{
                        key = "service.name"
                        value = @{
                            stringValue = $ServiceName
                        }
                    },
                    @{
                        key = "service.version"
                        value = @{
                            stringValue = $ServiceVersion
                        }
                    }
                )
            }
            scopeMetrics = @(
                @{
                    scope = @{
                        name = "iona-error-metrics"
                        version = "1.1"
                    }
                    metrics = @(
                        @{
                            name = $MetricName
                            description = "IONA Error System Metric"
                            unit = "1"
                            gauge = @{
                                dataPoints = @(
                                    @{
                                        timeUnixNano = $Timestamp * 1000000
                                        asDouble = $MetricValue
                                        attributes = @(
                                            foreach ($label in $AllLabels.GetEnumerator()) {
                                                @{
                                                    key = $label.Key
                                                    value = @{
                                                        stringValue = $label.Value.ToString()
                                                    }
                                                }
                                            }
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
}

# Convert to JSON
$JsonPayload = $MetricsPayload | ConvertTo-Json -Depth 10

if ($Verbose) {
    Write-Host "📊 Emitting metric to SigNoz:" -ForegroundColor Cyan
    Write-Host "   Name: $MetricName" -ForegroundColor White
    Write-Host "   Value: $MetricValue" -ForegroundColor White
    Write-Host "   Type: $MetricType" -ForegroundColor White
    Write-Host "   Labels: $($AllLabels.Count)" -ForegroundColor White
    Write-Host "   Endpoint: $SigNozEndpoint" -ForegroundColor White
}

try {
    # Send to SigNoz
    $Response = Invoke-RestMethod -Uri $SigNozEndpoint -Method Post -Body $JsonPayload -ContentType "application/json" -TimeoutSec 10
    
    if ($Verbose) {
        Write-Host "✅ Metric emitted successfully!" -ForegroundColor Green
    }
    
    return $true
} catch {
    Write-Host "❌ Failed to emit metric to SigNoz: $($_.Exception.Message)" -ForegroundColor Red
    if ($Verbose) {
        Write-Host "   Payload: $JsonPayload" -ForegroundColor Yellow
    }
    return $false
}
