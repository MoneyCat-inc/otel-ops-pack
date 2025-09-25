[CmdletBinding()]
param(
    [string]$SigNozUrl = 'http://localhost:8080',
    [switch]$DryRun,
    [switch]$Import
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$artifactsDir = Join-Path $PSScriptRoot '..' 'artifacts'
if (-not (Test-Path $artifactsDir)) { New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null }

$alerts = @(
    [ordered]@{
        name = 'Disk Usage Warning'
        description = 'Alert when disk usage warning threshold (>=80%) observed in disk-monitor logs.'
        severity = 'warning'
        query = [ordered]@{
            dataSource = 'logs'
            queryType = 'builder'
            filters = @(
                @{ key = 'dataset'; operator = '='; value = 'disk-monitor' }
                @{ key = 'status'; operator = '='; value = 'warning' }
            )
            timeRange = @{ from = 'now-10m'; to = 'now' }
        }
        threshold = @{ operator = '>='; value = 1 }
        evaluationWindow = '5m'
        notificationChannels = @('email')
        tags = @('disk', 'windows', 'warning')
    },
    [ordered]@{
        name = 'Disk Usage Critical'
        description = 'Alert when disk usage critical threshold (>=90%) observed in disk-monitor logs.'
        severity = 'critical'
        query = [ordered]@{
            dataSource = 'logs'
            queryType = 'builder'
            filters = @(
                @{ key = 'dataset'; operator = '='; value = 'disk-monitor' }
                @{ key = 'status'; operator = '='; value = 'critical' }
            )
            timeRange = @{ from = 'now-5m'; to = 'now' }
        }
        threshold = @{ operator = '>='; value = 1 }
        evaluationWindow = '1m'
        notificationChannels = @('email', 'slack')
        tags = @('disk', 'windows', 'critical')
    }
)

$export = [ordered]@{
    generated_at = (Get-Date).ToUniversalTime().ToString('o')
    description = 'Disk usage log alert pack for SigNoz.'
    alerts = $alerts
}

$exportPath = Join-Path $artifactsDir 'signoz-disk-alerts.json'
$export | ConvertTo-Json -Depth 8 | Out-File -FilePath $exportPath -Encoding UTF8

Write-Host "Disk alert configuration exported to $exportPath" -ForegroundColor Green
Write-Host ""
Write-Host "Alerts generated:" -ForegroundColor Cyan
foreach ($alert in $alerts) { Write-Host " - $($alert.name) [$($alert.severity)]" -ForegroundColor White }

Write-Host ""
if ($Import) {
    Write-Warning 'Automated import is not implemented. Import this JSON via SigNoz UI (Alerts -> Import).'
} else {
    Write-Host 'To import alerts:' -ForegroundColor Yellow
    Write-Host "1. Open $SigNozUrl" -ForegroundColor White
    Write-Host '2. Navigate to Alerts -> Import JSON' -ForegroundColor White
    Write-Host '3. Upload artifacts/signoz-disk-alerts.json' -ForegroundColor White
}