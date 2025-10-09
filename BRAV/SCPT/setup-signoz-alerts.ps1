# SigNoz Alert Configuration for ECRR Compliance Monitoring
# Generates alert artifacts and provides verification helpers

param(
    [string]$SigNozBaseURL = "http://localhost:8080",
    [switch]$CreateAlerts,
    [switch]$ListAlerts,
    [switch]$CopyJson,
    [switch]$TestAlerts,
    [string]$SigNozApiToken = $env:SIGNOZ_API_TOKEN
)

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:AlertsDirectory = Join-Path $script:RepoRoot 'alerts'
$script:ThresholdAlertPath = Join-Path $script:AlertsDirectory 'ecrr-compliance-threshold.json'

Write-Host "?? SigNoz ECRR Compliance Alert Configuration" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   Base URL : $SigNozBaseURL" -ForegroundColor Gray
Write-Host "   Alerts   : $script:AlertsDirectory" -ForegroundColor Gray
Write-Host ""

function Get-ComplianceThresholdAlert {
    param(
        [int]$ThresholdPercent = 80,
        [int]$DurationMinutes = 5
    )

    return [ordered]@{
        name = "ECRR Compliance Threshold Breach"
        description = "Alert when ECRR compliance rate drops below 80% for 5 minutes"
        state = "active"
        labels = [ordered]@{
            service = "ecrr-compliance"
            component = "monitoring"
            severity = "warning"
            dataset = "ecrr_compliance"
        }
        compositeQuery = [ordered]@{
            queryType = "builder"
            panelType = "time_series"
            builderQueries = [ordered]@{
                A = [ordered]@{
                    queryName = "A"
                    dataSource = "logs"
                    aggregateOperator = "avg"
                    aggregateAttribute = "json.compliance_rate"
                    expression = ""
                    filters = [ordered]@{
                        items = @(
                            @{ id = "dataset"; key = "json.dataset"; op = "="; value = "ecrr_compliance"; disabled = $false },
                            @{ id = "path"; key = "log.file.path"; op = "="; value = "C:/logs/ecrr/compliance-trends.log"; disabled = $false }
                        )
                        op = "AND"
                    }
                    groupBy = @()
                    stepInterval = 60
                }
            }
        }
        condition = [ordered]@{
            op = "<"
            lhs = "A"
            rhs = $ThresholdPercent
        }
        evaluationWindow = "${DurationMinutes}m"
        checkFrequency = "1m"
        notifications = @()
        disabled = $false
    }
}

function Write-AlertArtifact {
    param(
        [Parameter(Mandatory = $true)]$AlertDefinition,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (-not (Test-Path $script:AlertsDirectory)) {
        New-Item -Path $script:AlertsDirectory -ItemType Directory -Force | Out-Null
    }

    $AlertDefinition | ConvertTo-Json -Depth 6 | Set-Content -Path $Destination -Encoding UTF8
    Write-Host "?? Alert JSON written: $Destination" -ForegroundColor Green
}

function Copy-AlertJsonToClipboard {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        throw "Alert file not found: $FilePath"
    }

    $json = Get-Content -Path $FilePath -Raw
    Set-Clipboard -Value $json
    Write-Host "?? Alert JSON copied to clipboard" -ForegroundColor Green
    Write-Host "   Paste into SigNoz -> Alerts -> Create Alert (JSON mode)" -ForegroundColor White
}

function Show-AlertArtifacts {
    if (-not (Test-Path $script:AlertsDirectory)) {
        Write-Host "No alert artifacts generated yet." -ForegroundColor Yellow
        return
    }

    Get-ChildItem -Path $script:AlertsDirectory -Filter 'ecrr-compliance-*.json' | ForEach-Object {
        Write-Host " - $($_.FullName)" -ForegroundColor White
    }
}

function Show-VerificationTips {
    $logFile = 'C:/logs/ecrr/compliance-trends.log'
    Write-Host "?? Verification" -ForegroundColor Cyan
    if (Test-Path $logFile) {
        $latest = Get-Content -Path $logFile -Tail 1 | ConvertFrom-Json
        Write-Host ("   Latest compliance_rate : {0}%" -f $latest.compliance_rate) -ForegroundColor White
        Write-Host ("   Threshold               : {0}%" -f $latest.threshold) -ForegroundColor White
    } else {
        Write-Host "   Log file not found at $logFile" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "   SigNoz UI -> Alerts" -ForegroundColor White
    Write-Host "     - Click 'Create Alert Rule' -> 'Logs'" -ForegroundColor Gray
    Write-Host '     - Query: avg_over_time(({dataset="ecrr_compliance"} | json | unwrap compliance_rate [5m]))' -ForegroundColor Gray
    Write-Host "     - Condition: < 80, Evaluation window: 5m, Frequency: 1m" -ForegroundColor Gray
    Write-Host "     - Labels: severity=warning, dataset=ecrr_compliance" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   Logs Explorer filter" -ForegroundColor White
    Write-Host '     log.file.path = "C:/logs/ecrr/compliance-trends.log"' -ForegroundColor Gray
    Write-Host '     Quick search: body contains "compliance_trend_calculated"' -ForegroundColor Gray
}

try {
    Write-Host "?? Starting SigNoz alert configuration..." -ForegroundColor Green

    if ($CreateAlerts) {
        $alert = Get-ComplianceThresholdAlert
        Write-AlertArtifact -AlertDefinition $alert -Destination $script:ThresholdAlertPath
        Write-Host ""
        Write-Host "Next step: import JSON in SigNoz or use UI builder with the query above." -ForegroundColor Yellow
    }
    elseif ($CopyJson) {
        Copy-AlertJsonToClipboard -FilePath $script:ThresholdAlertPath
    }
    elseif ($ListAlerts) {
        Show-AlertArtifacts
    }
    elseif ($TestAlerts) {
        Show-VerificationTips
        if ($SigNozApiToken) {
            Write-Host ""
            Write-Host "Attempting API query (requires valid SigNoz API token)..." -ForegroundColor Gray
            $headers = @{
                'Content-Type' = 'application/json'
                'Accept' = 'application/json'
                'X-Signoz-API-Key' = $SigNozApiToken
            }
            $payload = @{
                query = 'body contains "compliance_trend_calculated" AND json.compliance_rate < 80'
                start = (Get-Date).AddHours(-1).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                end = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                limit = 5
            } | ConvertTo-Json
            try {
                $response = Invoke-RestMethod -Uri "$SigNozBaseURL/api/v1/logs" -Method Post -Headers $headers -Body $payload -TimeoutSec 10
                Write-Host "   API query succeeded. Logs returned: $($response.logs.Count)" -ForegroundColor Green
            }
            catch {
                Write-Host "   Could not query SigNoz API: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    else {
        Write-Host "?? Available Operations:" -ForegroundColor Cyan
        Write-Host "   -CreateAlerts : Generate/refresh JSON artifact for threshold alert" -ForegroundColor White
        Write-Host "   -ListAlerts   : Show generated alert JSON files" -ForegroundColor White
        Write-Host "   -CopyJson     : Copy threshold alert JSON to clipboard" -ForegroundColor White
        Write-Host "   -TestAlerts   : Show verification tips (optionally query API)" -ForegroundColor White
        Write-Host ""
        Write-Host "Example: pwsh -File scripts/setup-signoz-alerts.ps1 -CreateAlerts" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "?? SigNoz Alert Configuration Complete!" -ForegroundColor Green
    exit 0
}
catch {
    Write-Error "Alert configuration failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}







