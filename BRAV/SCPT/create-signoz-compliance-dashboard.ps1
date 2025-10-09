# SigNoz Dashboard Configuration for ECRR Compliance Monitoring
# Creates dashboard panels for compliance trends and threshold breaches

param(
    [string]$SigNozAPIKey = "YMJnm6c+/poKMuEGsjOQZCKrOealu8NjX22QE66VdnQ=",
    [string]$SigNozBaseURL = "http://localhost:8080",
    [string]$DashboardName = "ECRR Compliance Monitoring",
    [switch]$CreateDashboard,
    [switch]$TestQueries
)

Write-Host "📊 SigNoz ECRR Compliance Dashboard Creator" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Function to create SigNoz dashboard configuration
function New-SigNozDashboard {
    $dashboardConfig = @{
        name = $DashboardName
        description = "ECRR Compliance Trends and Threshold Monitoring Dashboard"
        panels = @(
            @{
                id = "compliance-rate-overview"
                title = "Compliance Rate Overview"
                type = "stat"
                targets = @(
                    @{
                        expr = 'avg_over_time(({dataset="ecrr_compliance"} | json | unwrap compliance_rate [5m]))'
                        legendFormat = "Current Compliance Rate"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit = "percent"
                        min = 0
                        max = 100
                        thresholds = @{
                            steps = @(
                                @{ color = "red"; value = 0 }
                                @{ color = "yellow"; value = 60 }
                                @{ color = "green"; value = 80 }
                            )
                        }
                    }
                }
                gridPos = @{ h = 8; w = 12; x = 0; y = 0 }
            },
            @{
                id = "compliance-trend-chart"
                title = "Compliance Rate Trend"
                type = "timeseries"
                targets = @(
                    @{
                        expr = 'avg_over_time(({dataset="ecrr_compliance"} | json | unwrap compliance_rate [5m]))'
                        legendFormat = "Compliance Rate %"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit = "percent"
                        min = 0
                        max = 100
                        color = @{ mode = "palette-classic" }
                    }
                }
                gridPos = @{ h = 8; w = 12; x = 12; y = 0 }
            },
            @{
                id = "threshold-breaches"
                title = "Threshold Breaches"
                type = "stat"
                targets = @(
                    @{
                        expr = 'count_over_time(({dataset="ecrr_compliance"} | json | compliance_rate < 80 [1h]))'
                        legendFormat = "Breaches (Last Hour)"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        color = @{ mode = "thresholds" }
                        thresholds = @{
                            steps = @(
                                @{ color = "green"; value = 0 }
                                @{ color = "yellow"; value = 1 }
                                @{ color = "red"; value = 5 }
                            )
                        }
                    }
                }
                gridPos = @{ h = 8; w = 8; x = 0; y = 8 }
            },
            @{
                id = "trend-direction"
                title = "Trend Direction"
                type = "stat"
                targets = @(
                    @{
                        expr = 'last_over_time(({dataset="ecrr_compliance"} | json | unwrap trend_percentage [5m]))'
                        legendFormat = "Trend Change %"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit = "percent"
                        color = @{ mode = "thresholds" }
                        thresholds = @{
                            steps = @(
                                @{ color = "red"; value = -100 }
                                @{ color = "yellow"; value = -2 }
                                @{ color = "green"; value = 2 }
                            )
                        }
                    }
                }
                gridPos = @{ h = 8; w = 8; x = 8; y = 8 }
            },
            @{
                id = "reports-status"
                title = "Reports Status"
                type = "stat"
                targets = @(
                    @{
                        expr = 'last_over_time(({dataset="ecrr_compliance"} | json | unwrap passed_reports [5m]))'
                        legendFormat = "Passed Reports"
                    },
                    @{
                        expr = 'last_over_time(({dataset="ecrr_compliance"} | json | unwrap failed_reports [5m]))'
                        legendFormat = "Failed Reports"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit = "short"
                        color = @{ mode = "palette-classic" }
                    }
                }
                gridPos = @{ h = 8; w = 8; x = 16; y = 8 }
            },
            @{
                id = "compliance-timeline"
                title = "Compliance Timeline"
                type = "timeseries"
                targets = @(
                    @{
                        expr = 'avg_over_time(({dataset="ecrr_compliance"} | json | unwrap compliance_rate [1m]))'
                        legendFormat = "Compliance Rate"
                    },
                    @{
                        expr = 'avg_over_time(({dataset="ecrr_compliance"} | json | unwrap threshold [1m]))'
                        legendFormat = "Threshold"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        unit = "percent"
                        min = 0
                        max = 100
                        color = @{ mode = "palette-classic" }
                    }
                }
                gridPos = @{ h = 8; w = 24; x = 0; y = 16 }
            },
            @{
                id = "trend-analysis"
                title = "Trend Analysis"
                type = "table"
                targets = @(
                    @{
                        expr = 'last_over_time(({dataset="ecrr_compliance"} | json | unwrap trend [5m]))'
                        legendFormat = "Trend"
                    },
                    @{
                        expr = 'last_over_time(({dataset="ecrr_compliance"} | json | unwrap trend_direction [5m]))'
                        legendFormat = "Direction"
                    },
                    @{
                        expr = 'last_over_time(({dataset="ecrr_compliance"} | json | unwrap trend_percentage [5m]))'
                        legendFormat = "Change %"
                    },
                    @{
                        expr = 'last_over_time(({dataset="ecrr_compliance"} | json | unwrap recommendation [5m]))'
                        legendFormat = "Recommendation"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        custom = @{
                            displayMode = "table"
                        }
                    }
                }
                gridPos = @{ h = 8; w = 24; x = 0; y = 24 }
            }
        )
        time = @{
            from = "now-1h"
            to = "now"
        }
        refresh = "30s"
        tags = @("ecrr", "compliance", "monitoring")
    }

    return $dashboardConfig
}

# Function to test SigNoz queries
function Test-SigNozQueries {
    Write-Host "🧪 Testing SigNoz queries..." -ForegroundColor Yellow
    
    $queries = @(
        @{
            name = "Compliance Rate Query"
            query = '{dataset="ecrr_compliance"} | json | unwrap compliance_rate'
            description = "Get current compliance rate from logs"
        },
        @{
            name = "Trend Analysis Query"
            query = '{dataset="ecrr_compliance"} | json | unwrap trend_percentage'
            description = "Get trend percentage change"
        },
        @{
            name = "Threshold Breach Query"
            query = '{dataset="ecrr_compliance"} | json | compliance_rate < 80'
            description = "Find compliance rate below threshold"
        },
        @{
            name = "Recent Compliance Events"
            query = '{dataset="ecrr_compliance"} | json | event="compliance_trend_calculated"'
            description = "Get recent compliance trend calculations"
        }
    )

    foreach ($query in $queries) {
        Write-Host ""
        Write-Host "📋 $($query.name):" -ForegroundColor Cyan
        Write-Host "   Query: $($query.query)" -ForegroundColor White
        Write-Host "   Description: $($query.description)" -ForegroundColor White
        
        # Test query via SigNoz API
        try {
            $headers = @{
                "Authorization" = "Bearer $SigNozAPIKey"
                "Content-Type" = "application/json"
            }
            
            $body = @{
                query = $query.query
                start = [DateTimeOffset]::UtcNow.AddHours(-1).ToUnixTimeSeconds()
                end = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$SigNozBaseURL/api/v1/query_range" -Method Post -Headers $headers -Body $body -ErrorAction Stop
            
            if ($response.status -eq "success") {
                Write-Host "   ✅ Query successful" -ForegroundColor Green
                if ($response.data.result.Count -gt 0) {
                    Write-Host "   📊 Results: $($response.data.result.Count) data points" -ForegroundColor White
                } else {
                    Write-Host "   ⚠️  No data returned (may be normal if no recent logs)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "   ❌ Query failed: $($response.error)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "   ❌ API Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Function to create dashboard via SigNoz API
function New-SigNozDashboardAPI {
    param($DashboardConfig)
    
    Write-Host "🚀 Creating SigNoz dashboard..." -ForegroundColor Yellow
    
    try {
        $headers = @{
            "Authorization" = "Bearer $SigNozAPIKey"
            "Content-Type" = "application/json"
        }
        
        $body = $DashboardConfig | ConvertTo-Json -Depth 10
        
        $response = Invoke-RestMethod -Uri "$SigNozBaseURL/api/v1/dashboards" -Method Post -Headers $headers -Body $body -ErrorAction Stop
        
        if ($response.status -eq "success") {
            Write-Host "✅ Dashboard created successfully!" -ForegroundColor Green
            Write-Host "   Dashboard ID: $($response.data.uid)" -ForegroundColor White
            Write-Host "   URL: $SigNozBaseURL/d/$($response.data.uid)" -ForegroundColor White
            return $response.data
        } else {
            Write-Host "❌ Dashboard creation failed: $($response.error)" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-Host "❌ API Error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to save dashboard configuration
function Save-DashboardConfig {
    param($DashboardConfig)
    
    $configPath = "artifacts/signoz-ecrr-compliance-dashboard.json"
    $DashboardConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
    Write-Host "📄 Dashboard configuration saved: $configPath" -ForegroundColor Green
}

# Main execution
try {
    Write-Host "🚀 Starting SigNoz dashboard creation..." -ForegroundColor Green
    
    # Create dashboard configuration
    $dashboardConfig = New-SigNozDashboard
    
    # Save configuration
    Save-DashboardConfig -DashboardConfig $dashboardConfig
    
    # Test queries if requested
    if ($TestQueries) {
        Test-SigNozQueries
    }
    
    # Create dashboard via API if requested
    if ($CreateDashboard) {
        $dashboard = New-SigNozDashboardAPI -DashboardConfig $dashboardConfig
        if ($dashboard) {
            Write-Host ""
            Write-Host "🎯 Dashboard Creation Complete!" -ForegroundColor Green
            Write-Host "   Name: $($dashboard.title)" -ForegroundColor White
            Write-Host "   ID: $($dashboard.uid)" -ForegroundColor White
            Write-Host "   URL: $SigNozBaseURL/d/$($dashboard.uid)" -ForegroundColor White
        }
    } else {
        Write-Host ""
        Write-Host "📋 Dashboard Configuration Ready!" -ForegroundColor Green
        Write-Host "   Configuration saved to: artifacts/signoz-ecrr-compliance-dashboard.json" -ForegroundColor White
        Write-Host "   Use -CreateDashboard to deploy via API" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "📊 Dashboard Panels Created:" -ForegroundColor Cyan
    Write-Host "   - Compliance Rate Overview (stat panel)" -ForegroundColor White
    Write-Host "   - Compliance Rate Trend (timeseries chart)" -ForegroundColor White
    Write-Host "   - Threshold Breaches (stat panel)" -ForegroundColor White
    Write-Host "   - Trend Direction (stat panel)" -ForegroundColor White
    Write-Host "   - Reports Status (stat panel)" -ForegroundColor White
    Write-Host "   - Compliance Timeline (timeseries chart)" -ForegroundColor White
    Write-Host "   - Trend Analysis (table panel)" -ForegroundColor White
    
    Write-Host ""
    Write-Host "🔍 SigNoz Queries for Manual Testing:" -ForegroundColor Cyan
    Write-Host "   Compliance Rate: {dataset=\"ecrr_compliance\"} | json | unwrap compliance_rate" -ForegroundColor White
    Write-Host "   Trend Analysis: {dataset=\"ecrr_compliance\"} | json | unwrap trend_percentage" -ForegroundColor White
    Write-Host "   Threshold Breaches: {dataset=\"ecrr_compliance\"} | json | compliance_rate < 80" -ForegroundColor White
    Write-Host "   Recent Events: {dataset=\"ecrr_compliance\"} | json | event=\"compliance_trend_calculated\"" -ForegroundColor White
    
    exit 0
    
} catch {
    Write-Error "Dashboard creation failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
