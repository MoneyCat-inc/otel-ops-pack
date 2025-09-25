[CmdletBinding()]
param()

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$Message) Write-Host "[Generate] $Message" -ForegroundColor Cyan }

Write-Info "Generating SigNoz alert pack..."

$alertConfig = @{
    alerts = @(
        @{
            name = "Disk Usage Warning"
            description = "Disk usage has exceeded 80% threshold"
            severity = "warning"
            query = 'attributes.dataset = "disk-monitor" AND attributes.status = "warning"'
            evaluationWindow = "5m"
            threshold = @{
                operator = ">="
                value = 1
            }
            notificationChannels = @("email")
            enabled = $true
            tags = @{
                monitoring = "disk"
                threshold = "warning"
                dataset = "disk-monitor"
            }
        },
        @{
            name = "Disk Usage Critical"
            description = "Disk usage has exceeded 90% threshold - immediate action required"
            severity = "critical"
            query = 'attributes.dataset = "disk-monitor" AND attributes.status = "critical"'
            evaluationWindow = "1m"
            threshold = @{
                operator = ">="
                value = 1
            }
            notificationChannels = @("email", "slack")
            enabled = $true
            tags = @{
                monitoring = "disk"
                threshold = "critical"
                dataset = "disk-monitor"
            }
        }
    )
    metadata = @{
        version = "1.0.0"
        created = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        description = "Disk monitoring alerts for SigNoz integration"
        dataset = "disk-monitor"
        thresholds = @{
            warning = 80
            critical = 90
        }
    }
}

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -Path "artifacts" -ItemType Directory -Force | Out-Null
}

# Generate JSON file
$jsonContent = $alertConfig | ConvertTo-Json -Depth 10
$jsonContent | Out-File -FilePath "artifacts/signoz-disk-alerts.json" -Encoding UTF8

Write-Info "Alert pack generated: artifacts/signoz-disk-alerts.json"
Write-Info "Contains $($alertConfig.alerts.Count) alerts:"
foreach ($alert in $alertConfig.alerts) {
    Write-Host "  - $($alert.name) [$($alert.severity)]" -ForegroundColor Green
}

Write-Info "Ready for import into SigNoz!"
