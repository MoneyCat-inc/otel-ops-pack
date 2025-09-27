# Create GPU Dashboard for SigNoz
# ECRR-compliant GPU dashboard creation with comprehensive monitoring panels

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$DashboardName = "GPU Monitoring Dashboard"
)

Write-Host "=== GPU Dashboard Creation ===" -ForegroundColor Cyan
Write-Host "ECRR: Creating comprehensive GPU monitoring dashboard..." -ForegroundColor Yellow

# Animation characters for progress indication
$spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
$spinnerIndex = 0

function Show-Progress {
    param([string]$Message, [int]$Current, [int]$Total)
    $spinnerIndex = ($spinnerIndex + 1) % $spinner.Count
    $progress = [math]::Round(($Current / $Total) * 100)
    Write-Host "`r$($spinner[$spinnerIndex]) $Message... $Current/$Total ($progress%)" -NoNewline -ForegroundColor Cyan
}

# Create comprehensive GPU dashboard configuration
Write-Host "`n🎨 Creating GPU dashboard panels..." -ForegroundColor Yellow

$dashboardConfig = @{
    name = $DashboardName
    description = "Comprehensive GPU monitoring dashboard for Cat Nap Control Room"
    tags = @("gpu", "monitoring", "observability", "automated")
    panels = @()
    layout = @{
        rows = @()
        columns = 12
    }
    refreshInterval = "30s"
    timeRange = @{
        from = "now-1h"
        to = "now"
    }
    createdAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
}

# Panel 1: GPU Utilization Overview
Show-Progress "Creating panels" 1 8
$utilizationPanel = @{
    id = "gpu-utilization-overview"
    title = "GPU Utilization Overview"
    type = "timeseries"
    span = 6
    targets = @(
        @{
            expr = "gpu.utilization.percent"
            legendFormat = "{{service.name}} - {{service.namespace}}"
        }
    )
    yAxes = @(
        @{
            min = 0
            max = 100
            unit = "%"
        }
    )
    thresholds = @(
        @{
            value = 80
            color = "yellow"
            label = "High Usage"
        },
        @{
            value = 95
            color = "red"
            label = "Critical"
        }
    )
    gridPos = @{
        h = 8
        w = 6
        x = 0
        y = 0
    }
}

# Panel 2: GPU Memory Usage
Show-Progress "Creating panels" 2 8
$memoryPanel = @{
    id = "gpu-memory-usage"
    title = "GPU Memory Usage"
    type = "timeseries"
    span = 6
    targets = @(
        @{
            expr = "gpu.memory.utilization.percent"
            legendFormat = "{{service.name}} Memory %"
        },
        @{
            expr = "gpu.memory.used.bytes / 1024 / 1024 / 1024"
            legendFormat = "{{service.name}} Used (GB)"
        }
    )
    yAxes = @(
        @{
            min = 0
            max = 100
            unit = "%"
        }
    )
    thresholds = @(
        @{
            value = 90
            color = "red"
            label = "High Memory"
        }
    )
    gridPos = @{
        h = 8
        w = 6
        x = 6
        y = 0
    }
}

# Panel 3: GPU Temperature Monitoring
Show-Progress "Creating panels" 3 8
$temperaturePanel = @{
    id = "gpu-temperature"
    title = "GPU Temperature Monitoring"
    type = "timeseries"
    span = 6
    targets = @(
        @{
            expr = "gpu.temperature.celsius"
            legendFormat = "{{service.name}} Temperature"
        }
    )
    yAxes = @(
        @{
            min = 0
            max = 100
            unit = "°C"
        }
    )
    thresholds = @(
        @{
            value = 85
            color = "red"
            label = "Overheating"
        },
        @{
            value = 75
            color = "yellow"
            label = "Warm"
        }
    )
    gridPos = @{
        h = 8
        w = 6
        x = 0
        y = 8
    }
}

# Panel 4: Sidecar Health Status
Show-Progress "Creating panels" 4 8
$healthPanel = @{
    id = "gpu-sidecar-health"
    title = "GPU Sidecar Health Status"
    type = "stat"
    span = 6
    targets = @(
        @{
            expr = "gpu.sidecar.health"
            legendFormat = "{{service.name}} Health"
        }
    )
    fieldConfig = @{
        defaults = @{
            color = @{
                mode = "thresholds"
            }
            thresholds = @{
                steps = @(
                    @{
                        color = "red"
                        value = 0
                    },
                    @{
                        color = "green"
                        value = 1
                    }
                )
            }
        }
    }
    gridPos = @{
        h = 8
        w = 6
        x = 6
        y = 8
    }
}

# Panel 5: GPU Metrics Summary
Show-Progress "Creating panels" 5 8
$summaryPanel = @{
    id = "gpu-metrics-summary"
    title = "GPU Metrics Summary"
    type = "table"
    span = 12
    targets = @(
        @{
            expr = "gpu.utilization.percent"
            format = "table"
            instant = $true
        },
        @{
            expr = "gpu.memory.utilization.percent"
            format = "table"
            instant = $true
        },
        @{
            expr = "gpu.temperature.celsius"
            format = "table"
            instant = $true
        }
    )
    gridPos = @{
        h = 8
        w = 12
        x = 0
        y = 16
    }
}

# Panel 6: GPU Alert Status
Show-Progress "Creating panels" 6 8
$alertPanel = @{
    id = "gpu-alert-status"
    title = "GPU Alert Status"
    type = "alertlist"
    span = 6
    targets = @(
        @{
            expr = "ALERTS"
            legendFormat = "GPU Alerts"
        }
    )
    gridPos = @{
        h = 8
        w = 6
        x = 0
        y = 24
    }
}

# Panel 7: GPU Performance Trends
Show-Progress "Creating panels" 7 8
$trendsPanel = @{
    id = "gpu-performance-trends"
    title = "GPU Performance Trends (24h)"
    type = "timeseries"
    span = 6
    targets = @(
        @{
            expr = "rate(gpu.utilization.percent[5m])"
            legendFormat = "{{service.name}} Utilization Rate"
        }
    )
    gridPos = @{
        h = 8
        w = 6
        x = 6
        y = 24
    }
}

# Panel 8: GPU Resource Distribution
Show-Progress "Creating panels" 8 8
$distributionPanel = @{
    id = "gpu-resource-distribution"
    title = "GPU Resource Distribution"
    type = "piechart"
    span = 12
    targets = @(
        @{
            expr = "gpu.utilization.percent"
            legendFormat = "{{service.name}}"
        }
    )
    gridPos = @{
        h = 8
        w = 12
        x = 0
        y = 32
    }
}

# Add all panels to dashboard
$dashboardConfig.panels = @(
    $utilizationPanel,
    $memoryPanel,
    $temperaturePanel,
    $healthPanel,
    $summaryPanel,
    $alertPanel,
    $trendsPanel,
    $distributionPanel
)

Write-Host "`r✅ Created 8 comprehensive GPU monitoring panels" -ForegroundColor Green

# Save dashboard configuration
$dashboardPath = "artifacts/signoz-gpu-dashboard.json"
$dashboardConfig | ConvertTo-Json -Depth 6 | Out-File -FilePath $dashboardPath -Encoding UTF8
Write-Host "📁 Dashboard config saved: $dashboardPath" -ForegroundColor Yellow

# Generate import instructions
$importInstructions = @"
=== GPU Dashboard Import Instructions ===

1. Open SigNoz UI: $SigNozUrl
2. Navigate to: Dashboards → Import Dashboard
3. Upload file: $dashboardPath
4. Or create manually using the panel configurations below:

=== Panel Configurations ===

1. GPU Utilization Overview
   - Type: Time Series
   - Query: gpu.utilization.percent
   - Thresholds: 80% (yellow), 95% (red)

2. GPU Memory Usage  
   - Type: Time Series
   - Query: gpu.memory.utilization.percent
   - Threshold: 90% (red)

3. GPU Temperature Monitoring
   - Type: Time Series
   - Query: gpu.temperature.celsius
   - Thresholds: 75°C (yellow), 85°C (red)

4. Sidecar Health Status
   - Type: Stat
   - Query: gpu.sidecar.health
   - Colors: 0=red, 1=green

5. GPU Metrics Summary
   - Type: Table
   - Queries: Multiple GPU metrics

6. GPU Alert Status
   - Type: Alert List
   - Filter: GPU-related alerts

7. GPU Performance Trends
   - Type: Time Series
   - Query: rate(gpu.utilization.percent[5m])

8. GPU Resource Distribution
   - Type: Pie Chart
   - Query: gpu.utilization.percent

=== API Import ===

POST $SigNozUrl/api/v1/dashboards
Content-Type: application/json
Body: $(Get-Content $dashboardPath -Raw)

=== Verification ===

After import, verify dashboard:
- Go to Dashboards → GPU Monitoring Dashboard
- Check all panels are loading data
- Verify time range and refresh settings
"@

$instructionsPath = "artifacts/gpu-dashboard-import-instructions.txt"
$importInstructions | Out-File -FilePath $instructionsPath -Encoding UTF8

Write-Host "`n=== ECRR Report: GPU Dashboard Creation Complete ===" -ForegroundColor Cyan
Write-Host "✅ GPU dashboard configuration created" -ForegroundColor Green
Write-Host "📁 Dashboard config: $dashboardPath" -ForegroundColor Yellow
Write-Host "📋 Import instructions: $instructionsPath" -ForegroundColor Yellow
Write-Host "🎭 ECRR Role: Cursor Agent - Observability Copilot" -ForegroundColor White

# Create ECRR report
$ecrrReport = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    action = "create-gpu-dashboard"
    status = "completed"
    artifacts = @{
        dashboard_config = $dashboardPath
        import_instructions = $instructionsPath
    }
    summary = @{
        panels_created = $dashboardConfig.panels.Count
        dashboard_name = $DashboardName
        signoz_url = $SigNozUrl
    }
}

$reportPath = "artifacts/gpu-dashboard-creation-report.json"
$ecrrReport | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`n✅ GPU Dashboard Creation Complete!" -ForegroundColor Green
Write-Host "📊 Next: Import dashboard into SigNoz UI" -ForegroundColor Yellow
Write-Host "🔗 SigNoz URL: $SigNozUrl" -ForegroundColor Cyan
