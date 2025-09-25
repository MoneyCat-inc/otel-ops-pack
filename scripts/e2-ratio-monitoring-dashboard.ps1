# E2 Ratio Monitoring Dashboard - Cat Nap Control Room
# Creates comprehensive dashboard for E2 ratio analysis with serene monitoring
# T-2025-01-27-001: Dashboard generation for E2 ratio sweep analysis

param(
    [string]$OutputFile = "artifacts/e2-ratio-dashboard.json",
    [string]$SigNozEndpoint = "http://localhost:8080",
    [switch]$ImportDashboard,
    [switch]$DryRun
)

Write-Host "🐱 === Cat Nap Control Room - E2 Ratio Monitoring Dashboard ===" -ForegroundColor Green
Write-Host "Creating serene dashboard for E2 ratio analysis..." -ForegroundColor Cyan

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
}

# Dashboard configuration with Cat Nap Control Room aesthetic
$dashboard = @{
    version = "1.0"
    title = "Cat Nap Control Room - E2 Ratio Analysis"
    description = "Serene observability dashboard for E2 ratio sweep analysis with sub-second harmony"
    tags = @("e2-ratio", "observability", "cat-nap-control-room", "performance")
    time = @{
        from = "now-1h"
        to = "now"
    }
    refresh = "30s"
    panels = @()
    templating = @{
        list = @(
            @{
                name = "test_id"
                type = "query"
                query = "label_values(dataset='e2_ratio_sweep', test_id)"
                refresh = 1
                includeAll = $true
                multi = $true
                label = "Test ID"
            },
            @{
                name = "agent_timeout"
                type = "query"
                query = "label_values(dataset='e2_ratio_sweep', agent_timeout)"
                refresh = 1
                includeAll = $true
                multi = $true
                label = "Agent Timeout"
            },
            @{
                name = "gateway_timeout"
                type = "query"
                query = "label_values(dataset='e2_ratio_sweep', gateway_timeout)"
                refresh = 1
                includeAll = $true
                multi = $true
                label = "Gateway Timeout"
            }
        )
    }
}

# Panel 1: E2 Ratio Sweep Overview
$overviewPanel = @{
    id = 1
    title = "E2 Ratio Sweep Overview"
    type = "stat"
    gridPos = @{
        h = 8
        w = 12
        x = 0
        y = 0
    }
    targets = @(
        @{
            expr = 'count by (test_id) (dataset=''e2_ratio_sweep'')'
            legendFormat = "{{test_id}}"
        }
    )
    fieldConfig = @{
        defaults = @{
            color = @{
                mode = "palette-classic"
            }
            custom = @{
                hideFrom = @{
                    legend = $false
                    tooltip = $false
                    vis = $false
                }
            }
        }
    }
    options = @{
        reduceOptions = @{
            values = $false
            calcs = @("lastNotNull")
            fields = ""
        }
        orientation = "auto"
        textMode = "auto"
        colorMode = "value"
        graphMode = "area"
        justifyMode = "auto"
    }
}

# Panel 2: P95 Latency Trend
$p95LatencyPanel = @{
    id = 2
    title = "P95 Latency Trend - Serenity Monitoring"
    type = "timeseries"
    gridPos = @{
        h = 8
        w = 12
        x = 12
        y = 0
    }
    targets = @(
        @{
            expr = 'avg by (test_id) (p95_latency_ms{dataset="e2_ratio_sweep"})'
            legendFormat = "{{test_id}} P95"
        }
    )
    fieldConfig = @{
        defaults = @{
            color = @{
                mode = "palette-classic"
            }
            custom = @{
                drawStyle = "line"
                lineInterpolation = "smooth"
                lineWidth = 2
                fillOpacity = 10
                gradientMode = "none"
                spanNulls = $false
                insertNulls = $false
                showPoints = "auto"
                pointSize = 5
                stacking = @{
                    mode = "none"
                    group = "A"
                }
                axisPlacement = "auto"
                axisLabel = ""
                scaleDistribution = @{
                    type = "linear"
                }
                hideFrom = @{
                    legend = $false
                    tooltip = $false
                    vis = $false
                }
                thresholdsStyle = @{
                    mode = "off"
                }
            }
            mappings = @()
            thresholds = @{
                mode = "absolute"
                steps = @(
                    @{
                        color = "green"
                        value = $null
                    },
                    @{
                        color = "yellow"
                        value = 1000
                    },
                    @{
                        color = "red"
                        value = 2000
                    }
                )
            }
            unit = "ms"
        }
    }
    options = @{
        legend = @{
            calcs = @()
            displayMode = "list"
            placement = "bottom"
        }
        tooltip = @{
            mode = "single"
            sort = "none"
        }
    }
}

# Panel 3: Queue Utilization Heatmap
$queueUtilizationPanel = @{
    id = 3
    title = "Queue Utilization Heatmap"
    type = "heatmap"
    gridPos = @{
        h = 8
        w = 24
        x = 0
        y = 8
    }
    targets = @(
        @{
            expr = 'sum by (test_id, agent_timeout, gateway_timeout) (queue_utilization_percent{dataset="e2_ratio_sweep"})'
            legendFormat = "{{test_id}}"
        }
    )
    fieldConfig = @{
        defaults = @{
            custom = @{
                hideFrom = @{
                    legend = $false
                    tooltip = $false
                    vis = $false
                }
            }
            unit = "percent"
        }
    }
    options = @{
        calculate = $false
        calculation = @{
            xBuckets = @{
                mode = "count"
                value = "100"
            }
            yBuckets = @{
                mode = "count"
                value = "10"
            }
        }
        color = @{
            mode = "spectrum"
            scheme = "Oranges"
            fill = "dark-orange"
            reverse = $false
        }
        exemplars = @{
            color = "rgba(255,0,255,0.7)"
        }
        filterValues = @{
            le = 1e-9
        }
        legend = @{
            show = $true
        }
        rowsFrame = @{
            layout = "auto"
        }
        tooltip = @{
            show = $true
            yHistogram = $false
        }
        yAxis = @{
            axisPlacement = "left"
            reverse = $false
            unit = ""
        }
    }
}

# Panel 4: Serenity Score Gauge
$serenityScorePanel = @{
    id = 4
    title = "Serenity Score - Cat Nap Control Room"
    type = "gauge"
    gridPos = @{
        h = 8
        w = 6
        x = 0
        y = 16
    }
    targets = @(
        @{
            expr = 'avg(serenity_score{dataset="e2_ratio_sweep"})'
            legendFormat = "Serenity Score"
        }
    )
    fieldConfig = @{
        defaults = @{
            color = @{
                mode = "palette-classic"
            }
            custom = @{
                hideFrom = @{
                    legend = $false
                    tooltip = $false
                    vis = $false
                }
            }
            mappings = @()
            max = 100
            min = 0
            thresholds = @{
                mode = "absolute"
                steps = @(
                    @{
                        color = "red"
                        value = $null
                    },
                    @{
                        color = "yellow"
                        value = 60
                    },
                    @{
                        color = "green"
                        value = 80
                    }
                )
            }
            unit = "short"
        }
    }
    options = @{
        orientation = "auto"
        reduceOptions = @{
            values = $false
            calcs = @("lastNotNull")
            fields = ""
        }
        showThresholdLabels = $false
        showThresholdMarkers = $true
    }
}

# Panel 5: Purr Factor Gauge
$purrFactorPanel = @{
    id = 5
    title = "Purr Factor - Cat Nap Control Room"
    type = "gauge"
    gridPos = @{
        h = 8
        w = 6
        x = 6
        y = 16
    }
    targets = @(
        @{
            expr = 'avg(purr_factor{dataset="e2_ratio_sweep"})'
            legendFormat = "Purr Factor"
        }
    )
    fieldConfig = @{
        defaults = @{
            color = @{
                mode = "palette-classic"
            }
            custom = @{
                hideFrom = @{
                    legend = $false
                    tooltip = $false
                    vis = $false
                }
            }
            mappings = @()
            max = 100
            min = 0
            thresholds = @{
                mode = "absolute"
                steps = @(
                    @{
                        color = "red"
                        value = $null
                    },
                    @{
                        color = "yellow"
                        value = 70
                    },
                    @{
                        color = "green"
                        value = 90
                    }
                )
            }
            unit = "short"
        }
    }
    options = @{
        orientation = "auto"
        reduceOptions = @{
            values = $false
            calcs = @("lastNotNull")
            fields = ""
        }
        showThresholdLabels = $false
        showThresholdMarkers = $true
    }
}

# Panel 6: Batch Efficiency Trend
$batchEfficiencyPanel = @{
    id = 6
    title = "Batch Efficiency Trend"
    type = "timeseries"
    gridPos = @{
        h = 8
        w = 12
        x = 12
        y = 16
    }
    targets = @(
        @{
            expr = 'avg by (test_id) (batch_efficiency_percent{dataset="e2_ratio_sweep"})'
            legendFormat = "{{test_id}} Efficiency"
        }
    )
    fieldConfig = @{
        defaults = @{
            color = @{
                mode = "palette-classic"
            }
            custom = @{
                drawStyle = "line"
                lineInterpolation = "smooth"
                lineWidth = 2
                fillOpacity = 10
                gradientMode = "none"
                spanNulls = $false
                insertNulls = $false
                showPoints = "auto"
                pointSize = 5
                stacking = @{
                    mode = "none"
                    group = "A"
                }
                axisPlacement = "auto"
                axisLabel = ""
                scaleDistribution = @{
                    type = "linear"
                }
                hideFrom = @{
                    legend = $false
                    tooltip = $false
                    vis = $false
                }
                thresholdsStyle = @{
                    mode = "off"
                }
            }
            mappings = @()
            thresholds = @{
                mode = "absolute"
                steps = @(
                    @{
                        color = "red"
                        value = $null
                    },
                    @{
                        color = "yellow"
                        value = 80
                    },
                    @{
                        color = "green"
                        value = 95
                    }
                )
            }
            unit = "percent"
        }
    }
    options = @{
        legend = @{
            calcs = @()
            displayMode = "list"
            placement = "bottom"
        }
        tooltip = @{
            mode = "single"
            sort = "none"
        }
    }
}

# Panel 7: E2 Ratio Comparison Table
$comparisonTablePanel = @{
    id = 7
    title = "E2 Ratio Comparison Table"
    type = "table"
    gridPos = @{
        h = 8
        w = 24
        x = 0
        y = 24
    }
    targets = @(
        @{
            expr = 'topk(10, p95_latency_ms{dataset="e2_ratio_sweep"}) by (test_id, agent_timeout, gateway_timeout)'
            format = "table"
            instant = $true
        }
    )
    fieldConfig = @{
        defaults = @{
            color = @{
                mode = "palette-classic"
            }
            custom = @{
                align = "auto"
                cellOptions = @{
                    type = "auto"
                }
                inspect = $false
            }
            mappings = @()
        }
        overrides = @(
            @{
                matcher = @{
                    id = "byName"
                    options = "p95_latency_ms"
                }
                properties = @(
                    @{
                        id = "unit"
                        value = "ms"
                    },
                    @{
                        id = "custom.cellOptions"
                        value = @{
                            type = "color-background"
                            mode = "continuous-GrYlRd"
                        }
                    }
                )
            }
        )
    }
    options = @{
        cellHeight = "sm"
        footer = @{
            countRows = $false
            fields = ""
            reducer = @("sum")
            show = $false
        }
        showHeader = $true
    }
}

# Panel 8: System Health Overview
$systemHealthPanel = @{
    id = 8
    title = "System Health Overview"
    type = "stat"
    gridPos = @{
        h = 8
        w = 24
        x = 0
        y = 32
    }
    targets = @(
        @{
            expr = 'avg(memory_usage_mb{dataset="e2_ratio_sweep"})'
            legendFormat = "Memory Usage (MB)"
        },
        @{
            expr = 'avg(cpu_usage_percent{dataset="e2_ratio_sweep"})'
            legendFormat = "CPU Usage (%)"
        },
        @{
            expr = 'avg(disk_free_gb{dataset="e2_ratio_sweep"})'
            legendFormat = "Disk Free (GB)"
        },
        @{
            expr = 'avg(network_connections{dataset="e2_ratio_sweep"})'
            legendFormat = "Network Connections"
        }
    )
    fieldConfig = @{
        defaults = @{
            color = @{
                mode = "palette-classic"
            }
            custom = @{
                hideFrom = @{
                    legend = $false
                    tooltip = $false
                    vis = $false
                }
            }
            mappings = @()
        }
        overrides = @(
            @{
                matcher = @{
                    id = "byName"
                    options = "Memory Usage (MB)"
                }
                properties = @(
                    @{
                        id = "unit"
                        value = "MB"
                    }
                )
            },
            @{
                matcher = @{
                    id = "byName"
                    options = "CPU Usage (%)"
                }
                properties = @(
                    @{
                        id = "unit"
                        value = "percent"
                    }
                )
            },
            @{
                matcher = @{
                    id = "byName"
                    options = "Disk Free (GB)"
                }
                properties = @(
                    @{
                        id = "unit"
                        value = "decbytes"
                    }
                )
            }
        )
    }
    options = @{
        reduceOptions = @{
            values = $false
            calcs = @("lastNotNull")
            fields = ""
        }
        orientation = "auto"
        textMode = "auto"
        colorMode = "value"
        graphMode = "area"
        justifyMode = "auto"
    }
}

# Add all panels to dashboard
$dashboard.panels = @(
    $overviewPanel,
    $p95LatencyPanel,
    $queueUtilizationPanel,
    $serenityScorePanel,
    $purrFactorPanel,
    $batchEfficiencyPanel,
    $comparisonTablePanel,
    $systemHealthPanel
)

# Save dashboard configuration
$dashboard | ConvertTo-Json -Depth 10 | Set-Content $OutputFile
Write-Host "✅ Dashboard configuration saved to: $OutputFile" -ForegroundColor Green

if ($DryRun) {
    Write-Host "`n🌙 === DRY RUN MODE - Dashboard configuration created ===" -ForegroundColor Cyan
    Write-Host "Dashboard would include:" -ForegroundColor Cyan
    Write-Host "  📊 E2 Ratio Sweep Overview" -ForegroundColor White
    Write-Host "  📈 P95 Latency Trend" -ForegroundColor White
    Write-Host "  🔥 Queue Utilization Heatmap" -ForegroundColor White
    Write-Host "  😌 Serenity Score Gauge" -ForegroundColor White
    Write-Host "  🐱 Purr Factor Gauge" -ForegroundColor White
    Write-Host "  ⚡ Batch Efficiency Trend" -ForegroundColor White
    Write-Host "  📋 E2 Ratio Comparison Table" -ForegroundColor White
    Write-Host "  💻 System Health Overview" -ForegroundColor White
    Write-Host "`nDry run complete. Use -ImportDashboard to import to SigNoz." -ForegroundColor Green
    exit 0
}

if ($ImportDashboard) {
    Write-Host "`n📤 Importing dashboard to SigNoz..." -ForegroundColor Yellow
    
    try {
        # Check SigNoz connectivity
        $response = Invoke-RestMethod -Uri "$SigNozEndpoint/api/v1/health" -Method Get -TimeoutSec 10
        Write-Host "✅ SigNoz is accessible" -ForegroundColor Green
        
        # Import dashboard (this would typically be done via SigNoz UI or API)
        Write-Host "📋 Dashboard import instructions:" -ForegroundColor Cyan
        Write-Host "1. Open SigNoz UI: $SigNozEndpoint" -ForegroundColor White
        Write-Host "2. Go to Dashboards → Import" -ForegroundColor White
        Write-Host "3. Upload the file: $OutputFile" -ForegroundColor White
        Write-Host "4. Configure data sources and save" -ForegroundColor White
        
        Write-Host "`n✅ Dashboard import instructions provided!" -ForegroundColor Green
        
    } catch {
        Write-Warning "Failed to connect to SigNoz: $($_.Exception.Message)"
        Write-Host "Dashboard configuration saved locally. Import manually via SigNoz UI." -ForegroundColor Yellow
    }
}

Write-Host "`n🐱 Cat Nap Control Room E2 Ratio Dashboard created successfully!" -ForegroundColor Green
Write-Host "Sleep easy. We've got the signal. 🐱✨" -ForegroundColor Cyan
