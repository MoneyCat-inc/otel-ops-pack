# Send Canary Log via Direct OTLP
# This script sends a canary log directly to the Windows collector via OTLP HTTP

param(
    [string]$CanaryId = (New-Guid).ToString().Substring(0,8),
    [string]$Message = "Windows Canary Log Test",
    [string]$ServiceName = "windows-canary",
    [string]$CollectorEndpoint
)

Import-Module (Join-Path $PSScriptRoot 'lib\OtelPorts.psm1') -Force
if (-not $CollectorEndpoint) {
    $CollectorEndpoint = "$(Get-OtelIngestHttpBase -HostName 'localhost')/v1/logs"
}

$timestamp = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalMilliseconds * 1000000

$logPayload = @{
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
                        key = "deployment.environment"
                        value = @{
                            stringValue = "local"
                        }
                    }
                )
            }
            scopeLogs = @(
                @{
                    scope = @{}
                    logRecords = @(
                        @{
                            timeUnixNano = $timestamp
                            severityNumber = 9
                            severityText = "INFO"
                            body = @{
                                stringValue = "$Message - Canary ID: $CanaryId - $(Get-Date)"
                            }
                            attributes = @(
                                @{
                                    key = "canary.id"
                                    value = @{
                                        stringValue = $CanaryId
                                    }
                                },
                                @{
                                    key = "canary.type"
                                    value = @{
                                        stringValue = "windows-direct-otlp"
                                    }
                                },
                                @{
                                    key = "test.framework"
                                    value = @{
                                        stringValue = "ecrr-compliance"
                                    }
                                }
                            )
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri $CollectorEndpoint -Method Post -Body $logPayload -ContentType "application/json" -TimeoutSec 10
    Write-Host "✅ Canary log sent successfully" -ForegroundColor Green
    Write-Host "   Canary ID: $CanaryId" -ForegroundColor Gray
    Write-Host "   Timestamp: $(Get-Date)" -ForegroundColor Gray
    Write-Host "   Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
    
    # Output for SigNoz search
    Write-Host "`n🔍 SigNoz Search Query:" -ForegroundColor Yellow
    Write-Host "   message contains '$CanaryId'" -ForegroundColor White
    Write-Host "   OR canary.id = '$CanaryId'" -ForegroundColor White
    
    return $CanaryId
} catch {
    Write-Host "❌ Failed to send canary log: $($_.Exception.Message)" -ForegroundColor Red
    return $null
}
