# SigNoz Dashboard Configuration
# ECRR Framework Implementation - Dashboard Management

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$ApiToken = "local-signoz-jwt-secret-rotate",
    [switch]$DryRun = $false
)

Write-Host "📊 SigNoz Dashboard Configuration" -ForegroundColor Cyan
Write-Host "ECRR Framework Implementation" -ForegroundColor Yellow
Write-Host ""

# Configuration
$Headers = @{
    "Authorization" = "Bearer $ApiToken"
    "Content-Type" = "application/json"
}

# Dashboard Configuration
$Dashboards = @(
    @{
        name = "Resonai Application Overview"
        description = "Comprehensive overview of Resonai application performance and health"
        tags = @("resonai", "overview", "application")
        panels = @(
            @{
                title = "Request Rate by Service"
                type = "graph"
                query = 'rate(http_requests_total[5m])'
                legend = "{{service_name}}"
                yAxis = "Requests per second"
            },
            @{
                title = "Error Rate by Service"
                type = "graph"
                query = 'rate(http_requests_total{status_code=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100'
                legend = "{{service_name}}"
                yAxis = "Error rate (%)"
            },
            @{
                title = "Response Time P95"
                type = "graph"
                query = 'histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))'
                legend = "{{service_name}}"
                yAxis = "Response time (seconds)"
            },
            @{
                title = "Active Connections"
                type = "stat"
                query = 'prisma_pool_connections_active'
                legend = "Database connections"
            }
        )
    },
    @{
        name = "Infrastructure Health"
        description = "Infrastructure and system health monitoring"
        tags = @("infrastructure", "health", "system")
        panels = @(
            @{
                title = "OTel Collector Queue Utilization"
                type = "graph"
                query = 'otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100'
                legend = "Queue utilization (%)"
                yAxis = "Percentage"
            },
            @{
                title = "Memory Usage"
                type = "graph"
                query = 'process_resident_memory_bytes / (1024*1024*1024)'
                legend = "{{service_name}}"
                yAxis = "Memory (GB)"
            },
            @{
                title = "Log Processing Rate"
                type = "graph"
                query = 'rate(otelcol_receiver_accepted_log_records_total[5m])'
                legend = "Logs per second"
                yAxis = "Logs/sec"
            },
            @{
                title = "Export Success Rate"
                type = "graph"
                query = 'rate(otelcol_exporter_sent_log_records_total[5m]) / (rate(otelcol_exporter_sent_log_records_total[5m]) + rate(otelcol_exporter_send_failed_log_records_total[5m])) * 100'
                legend = "Success rate (%)"
                yAxis = "Percentage"
            }
        )
    },
    @{
        name = "Database Performance"
        description = "Database performance and connection monitoring"
        tags = @("database", "performance", "prisma")
        panels = @(
            @{
                title = "Database Connection Pool"
                type = "graph"
                query = 'prisma_pool_connections_active'
                legend = "Active connections"
                yAxis = "Connections"
            },
            @{
                title = "Query Duration P95"
                type = "graph"
                query = 'histogram_quantile(0.95, rate(prisma_query_duration_seconds_bucket[5m]))'
                legend = "Query duration"
                yAxis = "Duration (seconds)"
            },
            @{
                title = "Query Rate"
                type = "graph"
                query = 'rate(prisma_query_total[5m])'
                legend = "Queries per second"
                yAxis = "Queries/sec"
            },
            @{
                title = "Connection Pool Utilization"
                type = "stat"
                query = 'prisma_pool_connections_active / prisma_pool_connections_max * 100'
                legend = "Pool utilization (%)"
            }
        )
    },
    @{
        name = "User Experience Metrics"
        description = "Frontend user experience and interaction metrics"
        tags = @("frontend", "ux", "user-experience")
        panels = @(
            @{
                title = "Page Load Time"
                type = "graph"
                query = 'histogram_quantile(0.95, rate(document_load_duration_seconds_bucket[5m]))'
                legend = "Page load time"
                yAxis = "Duration (seconds)"
            },
            @{
                title = "User Interactions"
                type = "graph"
                query = 'rate(user_interaction_total[5m])'
                legend = "{{interaction_type}}"
                yAxis = "Interactions/sec"
            },
            @{
                title = "Frontend Error Rate"
                type = "graph"
                query = 'rate(http_requests_total{service_name="resonai-frontend",status_code=~"4..|5.."}[5m]) / rate(http_requests_total{service_name="resonai-frontend"}[5m]) * 100'
                legend = "Frontend errors (%)"
                yAxis = "Error rate (%)"
            },
            @{
                title = "API Response Time"
                type = "graph"
                query = 'histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{service_name="resonai-frontend"}[5m]))'
                legend = "API response time"
                yAxis = "Duration (seconds)"
            }
        )
    },
    @{
        name = "Security & Authentication"
        description = "Security events and authentication monitoring"
        tags = @("security", "auth", "monitoring")
        panels = @(
            @{
                title = "Authentication Failures"
                type = "graph"
                query = 'rate(logs{message=~"auth.*fail|login.*fail"}[5m])'
                legend = "Auth failures/sec"
                yAxis = "Failures/sec"
            },
            @{
                title = "Failed Login Attempts"
                type = "graph"
                query = 'rate(http_requests_total{status_code="401"}[5m])'
                legend = "401 responses/sec"
                yAxis = "Requests/sec"
            },
            @{
                title = "Session Activity"
                type = "graph"
                query = 'rate(session_created_total[5m])'
                legend = "Sessions created/sec"
                yAxis = "Sessions/sec"
            },
            @{
                title = "Security Events"
                type = "logs"
                query = 'logs{message=~"security|unauthorized|forbidden"}'
                legend = "Security events"
            }
        )
    }
)

# Create dashboards
Write-Host "📊 Creating dashboards..." -ForegroundColor Yellow
$CreatedDashboards = @()
$FailedDashboards = @()

foreach ($Dashboard in $Dashboards) {
    Write-Host "  Creating dashboard: $($Dashboard.name)" -ForegroundColor Cyan
    
    if (-not $DryRun) {
        try {
            $DashboardConfig = @{
                name = $Dashboard.name
                description = $Dashboard.description
                tags = $Dashboard.tags
                panels = $Dashboard.panels
                isPublic = $true
                createdBy = "system"
                layout = "grid"
            }
            
            $DashboardResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/dashboards" -Method POST -Headers $Headers -Body ($DashboardConfig | ConvertTo-Json -Depth 5) -TimeoutSec 10
            
            Write-Host "    ✅ Dashboard created: $($Dashboard.name)" -ForegroundColor Green
            $CreatedDashboards += $Dashboard.name
            
        } catch {
            Write-Host "    ❌ Failed to create dashboard: $($_.Exception.Message)" -ForegroundColor Red
            $FailedDashboards += $Dashboard.name
        }
    } else {
        Write-Host "    🔍 Dry run: Dashboard would be created" -ForegroundColor Gray
        $CreatedDashboards += $Dashboard.name
    }
}

# Generate summary report
Write-Host "`n📊 Dashboard Summary" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host "✅ Created dashboards: $($CreatedDashboards.Count)" -ForegroundColor Green
Write-Host "❌ Failed dashboards: $($FailedDashboards.Count)" -ForegroundColor Red

if ($CreatedDashboards.Count -gt 0) {
    Write-Host "`n📋 Successfully Created Dashboards:" -ForegroundColor Green
    foreach ($Dashboard in $CreatedDashboards) {
        Write-Host "  • $Dashboard" -ForegroundColor White
    }
}

if ($FailedDashboards.Count -gt 0) {
    Write-Host "`n❌ Failed Dashboard Creation:" -ForegroundColor Red
    foreach ($Dashboard in $FailedDashboards) {
        Write-Host "  • $Dashboard" -ForegroundColor White
    }
}

# Save configuration to artifacts
$ConfigPath = "artifacts/signoz-dashboard-configuration.json"
$DashboardConfiguration = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    signoz_url = $SigNozUrl
    dashboards = $Dashboards
    summary = @{
        total_dashboards = $Dashboards.Count
        created_dashboards = $CreatedDashboards.Count
        failed_dashboards = $FailedDashboards.Count
        success_rate = [math]::Round(($CreatedDashboards.Count / $Dashboards.Count) * 100, 2)
    }
}

$DashboardConfiguration | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath
Write-Host "`n📝 Dashboard configuration saved to: $ConfigPath" -ForegroundColor Green

# Next steps
Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Verify dashboards in SigNoz UI: $SigNozUrl/dashboards" -ForegroundColor White
Write-Host "2. Customize dashboard panels and queries as needed" -ForegroundColor White
Write-Host "3. Set up dashboard refresh intervals" -ForegroundColor White
Write-Host "4. Share dashboards with team members" -ForegroundColor White
Write-Host "5. Create additional custom dashboards for specific use cases" -ForegroundColor White

Write-Host "`n✅ Dashboard setup completed!" -ForegroundColor Green
