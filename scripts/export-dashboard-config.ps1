#Requires -Version 7.0

<#
.SYNOPSIS
    Export SigNoz dashboard configuration based on latency baselines

.DESCRIPTION
    Creates a SigNoz dashboard configuration JSON file that includes latency metrics,
    alerts, and saved searches based on current baseline data.

.PARAMETER BaselineFile
    Path to baseline file. Default: artifacts/doe/baselines/latency.json

.PARAMETER OutputFile
    Output file path. Default: artifacts/signoz-dashboard-config.json

.PARAMETER SigNozUrl
    SigNoz base URL. Default: http://localhost:8080

.EXAMPLE
    .\export-dashboard-config.ps1 -BaselineFile artifacts/doe/baselines/latency.json
    Export dashboard config using default baseline file

.EXAMPLE
    .\export-dashboard-config.ps1 -OutputFile custom-dashboard.json
    Export to custom output file
#>

param(
    [string]$BaselineFile = "artifacts/doe/baselines/latency.json",
    [string]$OutputFile = "artifacts/signoz-dashboard-config.json",
    [string]$SigNozUrl = "http://localhost:8080"
)

# Initialize script
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "SigNoz Dashboard Configuration Export" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Function to load baseline
function Get-Baseline {
    param([string]$Path)
    
    if (Test-Path $Path) {
        try {
            return Get-Content $Path | ConvertFrom-Json
        } catch {
            Write-Warning "Failed to load baseline from $Path`: $($_.Exception.Message)"
            return $null
        }
    }
    return $null
}

# Function to create dashboard configuration
function New-DashboardConfig {
    param([object]$Baseline)
    
    $currentTime = Get-Date
    $baselineP95 = if ($Baseline -and $Baseline.latency) { $Baseline.latency.p95_ms } else { 100 }
    $baselineP50 = if ($Baseline -and $Baseline.latency) { $Baseline.latency.p50_ms } else { 50 }
    $threshold = if ($Baseline -and $Baseline.metadata) { $Baseline.metadata.threshold } else { 10 }
    
    $config = @{
        name = "OTel Latency Monitoring Dashboard"
        description = "Comprehensive latency monitoring dashboard with baseline comparisons"
        tags = @("otel", "latency", "monitoring", "baseline")
        time = @{
            from = "now-24h"
            to = "now"
        }
        refresh = "30s"
        schemaVersion = 27
        version = 1
        panels = @(
            @{
                id = 1
                title = "Latency P95 (24h)"
                type = "graph"
                gridPos = @{ h = 8; w = 12; x = 0; y = 0 }
                targets = @(
                    @{
                        expr = "p95(latency_ms)"
                        legendFormat = "P95 Latency"
                        refId = "A"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit = "ms"
                        color = @{ mode = "palette-classic" }
                        thresholds = @{
                            steps = @(
                                @{ color = "green"; value = $null }
                                @{ color = "yellow"; value = $baselineP95 }
                                @{ color = "red"; value = [math]::Round($baselineP95 * (1 + $threshold / 100), 2) }
                            )
                        }
                    }
                }
            },
            @{
                id = 2
                title = "Latency P50 (24h)"
                type = "graph"
                gridPos = @{ h = 8; w = 12; x = 12; y = 0 }
                targets = @(
                    @{
                        expr = "p50(latency_ms)"
                        legendFormat = "P50 Latency"
                        refId = "A"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit = "ms"
                        color = @{ mode = "palette-classic" }
                        thresholds = @{
                            steps = @(
                                @{ color = "green"; value = $null }
                                @{ color = "yellow"; value = $baselineP50 }
                                @{ color = "red"; value = [math]::Round($baselineP50 * (1 + $threshold / 100), 2) }
                            )
                        }
                    }
                }
            },
            @{
                id = 3
                title = "Baseline Comparison"
                type = "stat"
                gridPos = @{ h = 4; w = 6; x = 0; y = 8 }
                targets = @(
                    @{
                        expr = "p95(latency_ms)"
                        legendFormat = "Current P95"
                        refId = "A"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit = "ms"
                        color = @{ mode = "thresholds" }
                        thresholds = @{
                            steps = @(
                                @{ color = "green"; value = $null }
                                @{ color = "yellow"; value = $baselineP95 }
                                @{ color = "red"; value = [math]::Round($baselineP95 * (1 + $threshold / 100), 2) }
                            )
                        }
                    }
                }
            },
            @{
                id = 4
                title = "Regression Alert"
                type = "stat"
                gridPos = @{ h = 4; w = 6; x = 6; y = 8 }
                targets = @(
                    @{
                        expr = "((p95(latency_ms) - $baselineP95) / $baselineP95) * 100"
                        legendFormat = "Regression %"
                        refId = "A"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit = "percent"
                        color = @{ mode = "thresholds" }
                        thresholds = @{
                            steps = @(
                                @{ color = "green"; value = $null }
                                @{ color = "yellow"; value = $threshold }
                                @{ color = "red"; value = [math]::Round($threshold * 1.5, 1) }
                            )
                        }
                    }
                }
            },
            @{
                id = 5
                title = "Request Volume (24h)"
                type = "graph"
                gridPos = @{ h = 8; w = 12; x = 12; y = 8 }
                targets = @(
                    @{
                        expr = "rate(count(*), 5m)"
                        legendFormat = "Requests/min"
                        refId = "A"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit = "reqps"
                        color = @{ mode = "palette-classic" }
                    }
                }
            },
            @{
                id = 6
                title = "Error Rate (24h)"
                type = "stat"
                gridPos = @{ h = 4; w = 6; x = 0; y = 12 }
                targets = @(
                    @{
                        expr = "count(*) where level = 'ERROR' / count(*) * 100"
                        legendFormat = "Error Rate %"
                        refId = "A"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit = "percent"
                        color = @{ mode = "thresholds" }
                        thresholds = @{
                            steps = @(
                                @{ color = "green"; value = $null }
                                @{ color = "yellow"; value = 2 }
                                @{ color = "red"; value = 5 }
                            )
                        }
                    }
                }
            },
            @{
                id = 7
                title = "Pipeline Health"
                type = "stat"
                gridPos = @{ h = 4; w = 6; x = 6; y = 12 }
                targets = @(
                    @{
                        expr = "count(*) where message contains 'canary test'"
                        legendFormat = "Canary Events"
                        refId = "A"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit = "short"
                        color = @{ mode = "palette-classic" }
                    }
                }
            }
        )
        annotations = @{
            list = @(
                @{
                    name = "Baseline Update"
                    titleFormat = "Baseline Updated: {{text}}"
                    text = if ($Baseline) { $Baseline.updated } else { "No baseline" }
                    tags = @("baseline")
                }
            )
        }
    }
    
    return $config
}

# Function to create alerts configuration
function New-AlertsConfig {
    param([object]$Baseline)
    
    $baselineP95 = if ($Baseline -and $Baseline.latency) { $Baseline.latency.p95_ms } else { 100 }
    $threshold = if ($Baseline -and $Baseline.metadata) { $Baseline.metadata.threshold } else { 10 }
    
    $alerts = @(
        @{
            name = "OTel Latency Regression"
            description = "P95 latency exceeds baseline threshold"
            query = "p95(latency_ms) > $([math]::Round($baselineP95 * (1 + $threshold / 100), 2))"
            evaluationWindow = "5m"
            severity = "warning"
            threshold = [math]::Round($baselineP95 * (1 + $threshold / 100), 2)
        },
        @{
            name = "OTel High Error Rate"
            description = "Error rate exceeds 5%"
            query = "count(*) where level = 'ERROR' / count(*) * 100 > 5"
            evaluationWindow = "5m"
            severity = "critical"
            threshold = 5
        },
        @{
            name = "OTel Pipeline Stalled"
            description = "No canary events detected"
            query = "count(*) where message contains 'canary test' == 0"
            evaluationWindow = "10m"
            severity = "warning"
            threshold = 0
        },
        @{
            name = "OTel Data Flow Interrupted"
            description = "No events detected for extended period"
            query = "count(*) == 0"
            evaluationWindow = "15m"
            severity = "critical"
            threshold = 0
        }
    )
    
    return $alerts
}

# Function to create saved searches configuration
function New-SavedSearchesConfig {
    $searches = @(
        @{
            name = "OTel Latency Events"
            query = "latency_ms > 0"
            description = "All latency measurement events"
        },
        @{
            name = "OTel Error Events"
            query = "level = 'ERROR'"
            description = "Error events in OTel pipeline"
        },
        @{
            name = "OTel Canary Tests"
            query = "message contains 'canary test'"
            description = "Canary test execution events"
        },
        @{
            name = "OTel Baseline Updates"
            query = "message contains 'baseline'"
            description = "Baseline update events"
        },
        @{
            name = "OTel High Latency"
            query = "latency_ms > 1000"
            description = "High latency events (>1s)"
        }
    )
    
    return $searches
}

# Main execution
Write-Host "Loading baseline data..." -ForegroundColor Yellow
$baseline = Get-Baseline -Path $BaselineFile

if ($baseline) {
    Write-Host "✓ Baseline loaded: $($baseline.name)" -ForegroundColor Green
    Write-Host "  P95: $($baseline.latency.p95_ms)ms" -ForegroundColor White
    Write-Host "  P50: $($baseline.latency.p50_ms)ms" -ForegroundColor White
    Write-Host "  Threshold: $($baseline.metadata.threshold)%" -ForegroundColor White
} else {
    Write-Host "⚠ No baseline found, using defaults" -ForegroundColor Yellow
}

Write-Host "`nGenerating dashboard configuration..." -ForegroundColor Yellow
$dashboardConfig = New-DashboardConfig -Baseline $baseline
$alertsConfig = New-AlertsConfig -Baseline $baseline
$savedSearchesConfig = New-SavedSearchesConfig

# Create complete configuration
$completeConfig = @{
    dashboard = $dashboardConfig
    alerts = $alertsConfig
    savedSearches = $savedSearchesConfig
    metadata = @{
        exported = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        baselineFile = $BaselineFile
        signozUrl = $SigNozUrl
        version = "1.0"
    }
}

# Ensure output directory exists
$outputDir = Split-Path -Path $OutputFile -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Export configuration
Write-Host "Exporting to: $OutputFile" -ForegroundColor Yellow
try {
    $completeConfig | ConvertTo-Json -Depth 10 | Set-Content $OutputFile -Encoding UTF8
    Write-Host "✓ Dashboard configuration exported successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to export dashboard configuration: $($_.Exception.Message)"
    exit 1
}

# Display summary
Write-Host "`nExport Summary:" -ForegroundColor Cyan
Write-Host "  Dashboard: $($dashboardConfig.name)" -ForegroundColor White
Write-Host "  Panels: $($dashboardConfig.panels.Count)" -ForegroundColor White
Write-Host "  Alerts: $($alertsConfig.Count)" -ForegroundColor White
Write-Host "  Saved Searches: $($savedSearchesConfig.Count)" -ForegroundColor White
Write-Host "  Output File: $OutputFile" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. Import dashboard: pwsh -File scripts/import-dashboard.ps1 -DashboardFile '$OutputFile'" -ForegroundColor Gray
Write-Host "  2. Configure alerts in SigNoz UI: $SigNozUrl/alerts" -ForegroundColor Gray
Write-Host "  3. Create saved searches in SigNoz UI: $SigNozUrl/logs" -ForegroundColor Gray
Write-Host "  4. View dashboard: $SigNozUrl/dashboards" -ForegroundColor Gray

Write-Host "`nDashboard configuration export completed!" -ForegroundColor Green
