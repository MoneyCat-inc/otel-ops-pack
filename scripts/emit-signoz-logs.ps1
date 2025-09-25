# IONA SigNoz Logs Emitter
# Emits structured error logs to SigNoz OTLP endpoint for complete observability correlation

param(
    [Parameter(Mandatory=$true)]
    [string]$LogLevel,
    
    [Parameter(Mandatory=$true)]
    [string]$LogMessage,
    
    [Parameter(Mandatory=$true)]
    [string]$ErrorId,
    
    [Parameter(Mandatory=$true)]
    [string]$LogEvent,
    
    [hashtable]$Attributes = @{},
    
    [string]$SigNozEndpoint = "http://localhost:14318/v1/logs",
    
    [switch]$Verbose
)

# Configuration
$Timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeNano()
$ServiceName = "iona-error-system"
$ServiceVersion = "1.1"

# Default attributes
$DefaultAttributes = @{
    "service.name" = $ServiceName
    "service.version" = $ServiceVersion
    "error.id" = $ErrorId
    "log.event" = $LogEvent
    "log.level" = $LogLevel
    "environment" = "local"
    "component" = "error-cataloguing"
}

# Merge with provided attributes
$AllAttributes = $DefaultAttributes + $Attributes

# Create OTLP logs payload
$LogsPayload = @{
    resourceLogs = @(
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
            scopeLogs = @(
                @{
                    scope = @{
                        name = "iona-error-logging"
                        version = "1.1"
                    }
                    logRecords = @(
                        @{
                            timeUnixNano = $Timestamp
                            severityNumber = switch ($LogLevel) {
                                "ERROR" { 17 }
                                "WARN" { 13 }
                                "INFO" { 9 }
                                "DEBUG" { 5 }
                                default { 9 }
                            }
                            severityText = $LogLevel
                            body = @{
                                stringValue = $LogMessage
                            }
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
                        }
                    )
                }
            )
        }
    )
}

# Convert to JSON
$JsonPayload = $LogsPayload | ConvertTo-Json -Depth 10

if ($Verbose) {
    Write-Host "📝 Emitting log to SigNoz:" -ForegroundColor Cyan
    Write-Host "   Level: $LogLevel" -ForegroundColor White
    Write-Host "   Event: $LogEvent" -ForegroundColor White
    Write-Host "   Error ID: $ErrorId" -ForegroundColor White
    Write-Host "   Message: $LogMessage" -ForegroundColor White
    Write-Host "   Attributes: $($AllAttributes.Count)" -ForegroundColor White
    Write-Host "   Endpoint: $SigNozEndpoint" -ForegroundColor White
}

try {
    # Send to SigNoz
    $Response = Invoke-RestMethod -Uri $SigNozEndpoint -Method Post -Body $JsonPayload -ContentType "application/json" -TimeoutSec 10
    
    if ($Verbose) {
        Write-Host "✅ Log emitted successfully!" -ForegroundColor Green
    }
    
    return $true
} catch {
    Write-Host "❌ Failed to emit log to SigNoz: $($_.Exception.Message)" -ForegroundColor Red
    if ($Verbose) {
        Write-Host "   Payload: $JsonPayload" -ForegroundColor Yellow
    }
    return $false
}
