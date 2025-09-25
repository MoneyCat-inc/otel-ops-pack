# IONA SigNoz Trace Emitter
# Emits error lifecycle traces to SigNoz OTLP endpoint for drill-down exploration

param(
    [Parameter(Mandatory=$true)]
    [string]$TraceName,
    
    [Parameter(Mandatory=$true)]
    [string]$ErrorId,
    
    [Parameter(Mandatory=$true)]
    [string]$LifecycleStage,
    
    [hashtable]$Attributes = @{},
    
    [string]$SigNozEndpoint = "http://localhost:14318/v1/traces",
    
    [switch]$Verbose
)

# Configuration
$Timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeNano()
$ServiceName = "iona-error-system"
$ServiceVersion = "1.1"

# Generate trace and span IDs
$TraceId = [System.Guid]::NewGuid().ToString("N")
$SpanId = [System.Guid]::NewGuid().ToString("N").Substring(0, 16)

# Default attributes
$DefaultAttributes = @{
    "service.name" = $ServiceName
    "service.version" = $ServiceVersion
    "error.id" = $ErrorId
    "error.lifecycle_stage" = $LifecycleStage
    "environment" = "local"
    "component" = "error-cataloguing"
}

# Merge with provided attributes
$AllAttributes = $DefaultAttributes + $Attributes

# Create OTLP traces payload
$TracesPayload = @{
    resourceSpans = @(
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
                    },
                    @{
                        key = "deployment.environment"
                        value = @{
                            stringValue = "local"
                        }
                    }
                )
            }
            scopeSpans = @(
                @{
                    scope = @{
                        name = "iona-error-tracing"
                        version = "1.1"
                    }
                    spans = @(
                        @{
                            traceId = $TraceId
                            spanId = $SpanId
                            parentSpanId = ""
                            name = $TraceName
                            kind = 1  # INTERNAL
                            startTimeUnixNano = $Timestamp
                            endTimeUnixNano = $Timestamp + 1000000  # 1ms duration
                            attributes = @(
                                foreach ($attr in $AllAttributes.GetEnumerator()) {
                                    @{
                                        key = $attr.Key
                                        value = @{
                                            stringValue = $attr.Value.ToString()
                                        }
                                    }
                                }
                            )
                            status = @{
                                code = 1  # OK
                            }
                        }
                    )
                }
            )
        }
    )
}

# Convert to JSON
$JsonPayload = $TracesPayload | ConvertTo-Json -Depth 10

if ($Verbose) {
    Write-Host "🔍 Emitting trace to SigNoz:" -ForegroundColor Cyan
    Write-Host "   Trace ID: $TraceId" -ForegroundColor White
    Write-Host "   Span ID: $SpanId" -ForegroundColor White
    Write-Host "   Name: $TraceName" -ForegroundColor White
    Write-Host "   Stage: $LifecycleStage" -ForegroundColor White
    Write-Host "   Error ID: $ErrorId" -ForegroundColor White
    Write-Host "   Attributes: $($AllAttributes.Count)" -ForegroundColor White
    Write-Host "   Endpoint: $SigNozEndpoint" -ForegroundColor White
}

try {
    # Send to SigNoz
    $Response = Invoke-RestMethod -Uri $SigNozEndpoint -Method Post -Body $JsonPayload -ContentType "application/json" -TimeoutSec 10
    
    if ($Verbose) {
        Write-Host "✅ Trace emitted successfully!" -ForegroundColor Green
    }
    
    return @{
        Success = $true
        TraceId = $TraceId
        SpanId = $SpanId
    }
} catch {
    Write-Host "❌ Failed to emit trace to SigNoz: $($_.Exception.Message)" -ForegroundColor Red
    if ($Verbose) {
        Write-Host "   Payload: $JsonPayload" -ForegroundColor Yellow
    }
    return @{
        Success = $false
        Error = $_.Exception.Message
    }
}
