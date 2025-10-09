# Deploy Fractal Drift Monitors Dashboard Script
# Implements T-2025-01-27-005: Fractal Drift Monitors Dashboard

param(
    [switch]$GenerateDashboard,
    [switch]$TestDashboard,
    [switch]$FullDeployment
)

Write-Host "=== Fractal Drift Monitors Dashboard Deployment ===" -ForegroundColor Green
Write-Host "Task: T-2025-01-27-005 - Fractal Drift Monitors Dashboard" -ForegroundColor Yellow

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
    Write-Host "Created artifacts directory" -ForegroundColor Green
}

$dashboardConfigFile = "artifacts/signoz-fractal-drift-dashboard.json"

if ($GenerateDashboard -or $FullDeployment) {
    Write-Host "`n=== Generating Fractal Drift Dashboard Configuration ===" -ForegroundColor Yellow
    
    # Create comprehensive fractal drift dashboard configuration
    $dashboardConfig = @{
        title = "Fractal Drift Monitors"
        description = "Queue pressure, send failure rates, and trace time-to-use monitoring for fractal drift detection"
        version = "1.0.0"
        created = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        panels = @(
            @{
                id = "queue-utilization-ratio"
                title = "Queue Utilization Ratio"
                type = "graph"
                description = "Real-time queue pressure monitoring with 24h trend"
                targets = @(
                    @{
                        queryType = "promql"
                        expr = "otelcol_exporter_queue_size / otelcol_exporter_queue_capacity"
                        legendFormat = "Queue Utilization %"
                    },
                    @{
                        queryType = "promql"
                        expr = "avg_over_time(otelcol_exporter_queue_size / otelcol_exporter_queue_capacity[24h])"
                        legendFormat = "24h Average"
                    }
                )
                thresholds = @(
                    @{ value = 0.7; colorMode = "critical"; op = "gt" },
                    @{ value = 0.5; colorMode = "warning"; op = "gt" }
                )
                yAxes = @(
                    @{
                        min = 0
                        max = 1
                        unit = "percentunit"
                    }
                )
            },
            @{
                id = "send-failure-rate"
                title = "Send Failure Rate"
                type = "graph"
                description = "Monitor exporter failures by type and exporter"
                targets = @(
                    @{
                        queryType = "promql"
                        expr = "rate(otelcol_exporter_send_failed_spans_total[5m]) / rate(otelcol_exporter_sent_spans_total[5m])"
                        legendFormat = "Span Send Failure Rate"
                    },
                    @{
                        queryType = "promql"
                        expr = "rate(otelcol_exporter_send_failed_logs_total[5m]) / rate(otelcol_exporter_sent_logs_total[5m])"
                        legendFormat = "Log Send Failure Rate"
                    },
                    @{
                        queryType = "promql"
                        expr = "rate(otelcol_exporter_send_failed_metrics_total[5m]) / rate(otelcol_exporter_sent_metrics_total[5m])"
                        legendFormat = "Metric Send Failure Rate"
                    }
                )
                thresholds = @(
                    @{ value = 0.05; colorMode = "critical"; op = "gt" },
                    @{ value = 0.01; colorMode = "warning"; op = "gt" }
                )
            },
            @{
                id = "trace-time-to-use"
                title = "Trace Time-to-Use Latency"
                type = "graph"
                description = "Monitor batch processing latency percentiles"
                targets = @(
                    @{
                        queryType = "promql"
                        expr = "histogram_quantile(0.50, rate(otelcol_processor_batch_timeout_trigger_sent_duration_bucket[5m]))"
                        legendFormat = "p50 Latency"
                    },
                    @{
                        queryType = "promql"
                        expr = "histogram_quantile(0.95, rate(otelcol_processor_batch_timeout_trigger_sent_duration_bucket[5m]))"
                        legendFormat = "p95 Latency"
                    },
                    @{
                        queryType = "promql"
                        expr = "histogram_quantile(0.99, rate(otelcol_processor_batch_timeout_trigger_sent_duration_bucket[5m]))"
                        legendFormat = "p99 Latency"
                    }
                )
                thresholds = @(
                    @{ value = 8; colorMode = "critical"; op = "gt" },
                    @{ value = 2; colorMode = "warning"; op = "gt" }
                )
                yAxes = @(
                    @{
                        unit = "s"
                    }
                )
            },
            @{
                id = "fractal-drift-detection"
                title = "Fractal Drift Detection"
                type = "graph"
                description = "Pattern variance analysis for queue behavior"
                targets = @(
                    @{
                        queryType = "promql"
                        expr = "stddev_over_time(otelcol_exporter_queue_size[10m]) / avg_over_time(otelcol_exporter_queue_size[10m])"
                        legendFormat = "Queue Size CV"
                    },
                    @{
                        queryType = "promql"
                        expr = "stddev_over_time(rate(otelcol_exporter_send_failed_spans_total[5m])[10m]) / avg_over_time(rate(otelcol_exporter_send_failed_spans_total[5m])[10m])"
                        legendFormat = "Failure Rate CV"
                    },
                    @{
                        queryType = "promql"
                        expr = "stddev_over_time(histogram_quantile(0.95, rate(otelcol_processor_batch_timeout_trigger_sent_duration_bucket[5m]))[10m]) / avg_over_time(histogram_quantile(0.95, rate(otelcol_processor_batch_timeout_trigger_sent_duration_bucket[5m]))[10m])"
                        legendFormat = "Latency CV"
                    }
                )
                thresholds = @(
                    @{ value = 0.5; colorMode = "critical"; op = "gt" },
                    @{ value = 0.3; colorMode = "warning"; op = "gt" }
                )
            },
            @{
                id = "batch-efficiency"
                title = "Batch Efficiency & Size Distribution"
                type = "graph"
                description = "Monitor batch processing performance"
                targets = @(
                    @{
                        queryType = "promql"
                        expr = "avg_over_time(otelcol_processor_batch_batch_send_size[5m])"
                        legendFormat = "Avg Batch Size"
                    },
                    @{
                        queryType = "promql"
                        expr = "rate(otelcol_processor_batch_batch_send_size_total[5m])"
                        legendFormat = "Batches/sec"
                    },
                    @{
                        queryType = "promql"
                        expr = "histogram_quantile(0.95, rate(otelcol_processor_batch_batch_send_size_bucket[5m]))"
                        legendFormat = "p95 Batch Size"
                    }
                )
                thresholds = @(
                    @{ value = 1000; colorMode = "critical"; op = "gt" },
                    @{ value = 200; colorMode = "warning"; op = "lt" }
                )
            },
            @{
                id = "memory-usage"
                title = "Memory Usage & Limits"
                type = "graph"
                description = "Monitor collector memory consumption"
                targets = @(
                    @{
                        queryType = "promql"
                        expr = "otelcol_process_memory_rss"
                        legendFormat = "RSS Memory"
                    },
                    @{
                        queryType = "promql"
                        expr = "otelcol_process_memory_vms"
                        legendFormat = "VMS Memory"
                    },
                    @{
                        queryType = "promql"
                        expr = "otelcol_exporter_queue_memory_usage"
                        legendFormat = "Queue Memory"
                    }
                )
                thresholds = @(
                    @{ value = 400000000; colorMode = "critical"; op = "gt" },
                    @{ value = 200000000; colorMode = "warning"; op = "gt" }
                )
                yAxes = @(
                    @{
                        unit = "bytes"
                    }
                )
            }
        )
        time = @{
            from = "now-1h"
            to = "now"
        }
        refresh = "5s"
        tags = @("otel", "fractal", "drift", "monitoring", "queue", "latency")
        folderId = $null
        folderTitle = "OTel Monitoring"
    }
    
    $dashboardConfig | ConvertTo-Json -Depth 6 | Set-Content -Path $dashboardConfigFile -Encoding UTF8
    Write-Host "Dashboard configuration saved to: $dashboardConfigFile" -ForegroundColor Green
    
    Write-Host "`n=== SigNoz Dashboard Import Instructions ===" -ForegroundColor Cyan
    Write-Host "1. Open SigNoz UI: http://localhost:8080" -ForegroundColor White
    Write-Host "2. Navigate to: Dashboards -> Import" -ForegroundColor White
    Write-Host "3. Upload the configuration from: $dashboardConfigFile" -ForegroundColor White
    Write-Host "4. Verify all 6 panels load correctly:" -ForegroundColor White
    Write-Host "   - Queue Utilization Ratio" -ForegroundColor Gray
    Write-Host "   - Send Failure Rate" -ForegroundColor Gray
    Write-Host "   - Trace Time-to-Use Latency" -ForegroundColor Gray
    Write-Host "   - Fractal Drift Detection" -ForegroundColor Gray
    Write-Host "   - Batch Efficiency & Size Distribution" -ForegroundColor Gray
    Write-Host "   - Memory Usage & Limits" -ForegroundColor Gray
}

if ($TestDashboard -or $FullDeployment) {
    Write-Host "`n=== Testing Dashboard Configuration ===" -ForegroundColor Yellow
    
    # Validate JSON configuration
    try {
        $config = Get-Content -Path $dashboardConfigFile -Raw | ConvertFrom-Json
        Write-Host "✅ Dashboard JSON configuration is valid" -ForegroundColor Green
        Write-Host "   Title: $($config.title)" -ForegroundColor Cyan
        Write-Host "   Panels: $($config.panels.Count)" -ForegroundColor Cyan
        Write-Host "   Version: $($config.version)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "❌ Dashboard JSON configuration is invalid: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    
    # Generate test report
    $testResults = @{
        task_id = "T-2025-01-27-005"
        task_name = "Fractal Drift Monitors Dashboard"
        deployment_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        dashboard_config_file = $dashboardConfigFile
        status = "deployed"
        panels_count = $config.panels.Count
        panels = $config.panels | ForEach-Object { @{
            id = $_.id
            title = $_.title
            type = $_.type
            description = $_.description
        }}
        verification_steps = @(
            "Import dashboard configuration in SigNoz UI",
            "Verify all 6 panels load correctly",
            "Check threshold configurations",
            "Test real-time data updates",
            "Validate fractal drift detection queries"
        )
        signoz_ui_url = "http://localhost:8080"
        dashboard_features = @{
            queue_monitoring = "Real-time queue utilization with 24h trends"
            failure_monitoring = "Multi-type failure rate tracking"
            latency_monitoring = "p50/p95/p99 latency percentiles"
            fractal_drift = "Pattern variance analysis with CV metrics"
            batch_efficiency = "Batch size and processing performance"
            memory_monitoring = "Memory usage and limits tracking"
        }
    }
    
    $reportFile = "artifacts/fractal-drift-dashboard-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testResults | ConvertTo-Json -Depth 4 | Set-Content -Path $reportFile -Encoding UTF8
    Write-Host "`nDeployment report saved to: $reportFile" -ForegroundColor Blue
}

Write-Host "`n=== Fractal Drift Monitors Dashboard Deployment Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Import dashboard configuration in SigNoz UI" -ForegroundColor White
Write-Host "2. Verify all 6 panels load correctly" -ForegroundColor White
Write-Host "3. Test real-time data updates" -ForegroundColor White
Write-Host "4. Validate fractal drift detection queries" -ForegroundColor White
