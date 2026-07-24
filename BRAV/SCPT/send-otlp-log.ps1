# HISTORICAL (Gate-era): ports 5317/5318 predate the 5320/5321 move. Do not use as reference. See windows/otelcol/README.md.
<#
Direct OTLP Log Ingestion Script
------------------------------
Sends logs directly to the Windows OTel Collector OTLP HTTP endpoint.
Usage: pwsh -File scripts/send-otlp-log.ps1 -Message "Your log message" -Level "INFO"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Message,
    
    [Parameter(Mandatory=$false)]
    [string]$Level = "INFO",
    
    [Parameter(Mandatory=$false)]
    [string]$ServiceName = "direct-ingestion",
    
    [Parameter(Mandatory=$false)]
    [string]$Endpoint = "http://localhost:5318/v1/logs"
)

function Send-OTLPLog {
    param(
        [string]$LogMessage,
        [string]$SeverityLevel,
        [string]$Service,
        [string]$Url
    )
    
    $otlpPayload = @{
        resourceLogs = @(
            @{
                resource = @{
                    attributes = @(
                        @{ key = "service.name"; value = @{ stringValue = $Service } }
                        @{ key = "deployment.environment"; value = @{ stringValue = "local" } }
                    )
                }
                scopeLogs = @(
                    @{
                        logRecords = @(
                            @{
                                body = @{ stringValue = $LogMessage }
                                severityText = $SeverityLevel.ToUpper()
                                observedTimeUnixNano = [long]((Get-Date).ToUniversalTime() - [datetime]"1970-01-01").TotalMilliseconds * 1000000
                                attributes = @(
                                    @{ key = "ingestion.method"; value = @{ stringValue = "direct-otlp" } }
                                    @{ key = "ingestion.source"; value = @{ stringValue = "observability-copilot" } }
                                )
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $headers = @{ 'Content-Type' = 'application/json' }
    
    try {
        $response = Invoke-RestMethod -Uri $Url -Method Post -Body $otlpPayload -Headers $headers -TimeoutSec 5
        Write-Host "✅ Log sent successfully to $Url" -ForegroundColor Green
        Write-Host "📝 Message: $LogMessage" -ForegroundColor Cyan
        Write-Host "🔍 Verify in SigNoz UI -> Logs -> filter: body contains `"$LogMessage`"" -ForegroundColor Yellow
        return $true
    } catch {
        Write-Host "❌ Failed to send log: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Send the log
Write-Host "🚀 Sending OTLP log to Windows Collector..." -ForegroundColor Cyan
$success = Send-OTLPLog -LogMessage $Message -SeverityLevel $Level -Service $ServiceName -Url $Endpoint

if ($success) {
    Write-Host "✅ Direct OTLP ingestion test completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Direct OTLP ingestion test failed!" -ForegroundColor Red
    exit 1
}
