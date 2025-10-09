# SigNoz Dashboard Import Script
# Usage: pwsh -File scripts/import-signoz-dashboards.ps1

param(
    [switch]$SystemHealth,
    [switch]$Performance,
    [switch]$Application,
    [switch]$Triton,
    [switch]$All,
    [switch]$DryRun
)

# Set working directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
Set-Location $RepoRoot

# SigNoz configuration
$SigNozBaseUrl = "http://localhost:8080"
$SigNozApiUrl = "$SigNozBaseUrl/api/v1"

# Dashboard templates
$SystemHealthDashboard = @{
    dashboard = @{
        title = "Observability Pipeline Health"
        description = "Core system health monitoring"
        panels = @(
            @{
                title = "Windows Collector Status"
                type = "stat"
                gridPos = @{ h = 8; w = 6; x = 0; y = 0 }
                targets = @(
                    @{
                        expr = "up{job=`"otelcol-contrib`"}"
                        legendFormat = "Collector Status"
                    }
                )
                fieldConfig = @{
                    defaults = @{
                        color = @{ mode = "thresholds" }
                        thresholds = @{
                            steps = @(
                                @{ color = "red"; value = 0 }
                                @{ color = "green"; value = 1 }
                            )
                        }
                    }
                }
            },
            @{
                title = "SigNoz Container Health"
                type = "stat"
                gridPos = @{ h = 8; w = 6; x = 6; y = 0 }
                targets = @(
                    @{
                        expr = "up{job=`"signoz`"}"
                        legendFormat = "SigNoz Status"
                    }
                )
            },
            @{
                title = "Log Ingestion Rate"
                type = "graph"
                gridPos = @{ h = 8; w = 12; x = 12; y = 0 }
                targets = @(
                    @{
                        expr = "rate(otelcol_receiver_accepted_log_records[5m])"
                        legendFormat = "Logs/sec"
                    }
                )
            },
            @{
                title = "Canary Generation Success"
                type = "stat"
                gridPos = @{ h = 8; w = 6; x = 0; y = 8 }
                targets = @(
                    @{
                        expr = "rate(otelcol_receiver_accepted_log_records{source=`"canary`"}[5m])"
                        legendFormat = "Canary Events/sec"
                    }
                )
            },
            @{
                title = "Error Rate"
                type = "graph"
                gridPos = @{ h = 8; w = 12; x = 6; y = 8 }
                targets = @(
                    @{
                        expr = "rate(otelcol_receiver_refused_log_records[5m])"
                        legendFormat = "Errors/sec"
                    }
                )
            }
        )
        refresh = "30s"
        time = @{
            from = "now-1h"
            to = "now"
        }
    }
}

$PerformanceDashboard = @{
    dashboard = @{
        title = "Performance Metrics"
        description = "System performance monitoring"
        panels = @(
            @{
                title = "CPU Usage"
                type = "graph"
                gridPos = @{ h = 8; w = 12; x = 0; y = 0 }
                targets = @(
                    @{
                        expr = "rate(process_cpu_seconds_total[5m]) * 100"
                        legendFormat = "CPU %"
                    }
                )
                yAxes = @(
                    @{
                        max = 100
                        min = 0
                        unit = "percent"
                    }
                )
            },
            @{
                title = "Memory Usage"
                type = "graph"
                gridPos = @{ h = 8; w = 12; x = 12; y = 0 }
                targets = @(
                    @{
                        expr = "process_resident_memory_bytes / 1024 / 1024"
                        legendFormat = "Memory MB"
                    }
                )
                yAxes = @(
                    @{
                        unit = "MB"
                    }
                )
            },
            @{
                title = "Network I/O"
                type = "graph"
                gridPos = @{ h = 8; w = 12; x = 0; y = 8 }
                targets = @(
                    @{
                        expr = "rate(otelcol_exporter_sent_log_records[5m])"
                        legendFormat = "Sent Logs/sec"
                    }
                )
            },
            @{
                title = "Disk I/O"
                type = "graph"
                gridPos = @{ h = 8; w = 12; x = 12; y = 8 }
                targets = @(
                    @{
                        expr = "rate(otelcol_receiver_accepted_log_records[5m])"
                        legendFormat = "Processed Logs/sec"
                    }
                )
            }
        )
        refresh = "30s"
        time = @{
            from = "now-1h"
            to = "now"
        }
    }
}

$ApplicationDashboard = @{
    dashboard = @{
        title = "Application Metrics"
        description = "Application-specific monitoring"
        panels = @(
            @{
                title = "Service Worker Status"
                type = "stat"
                gridPos = @{ h = 8; w = 6; x = 0; y = 0 }
                targets = @(
                    @{
                        expr = "service_worker_supported"
                        legendFormat = "SW Supported"
                    }
                )
            },
            @{
                title = "Cross-Origin Isolation"
                type = "stat"
                gridPos = @{ h = 8; w = 6; x = 6; y = 0 }
                targets = @(
                    @{
                        expr = "cross_origin_isolated"
                        legendFormat = "COI Status"
                    }
                )
            },
            @{
                title = "Audio Latency"
                type = "graph"
                gridPos = @{ h = 8; w = 12; x = 12; y = 0 }
                targets = @(
                    @{
                        expr = "audio_latency_p50"
                        legendFormat = "P50 Latency"
                    },
                    @{
                        expr = "audio_latency_p90"
                        legendFormat = "P90 Latency"
                    },
                    @{
                        expr = "audio_latency_p99"
                        legendFormat = "P99 Latency"
                    }
                )
                yAxes = @(
                    @{
                        unit = "ms"
                    }
                )
            },
            @{
                title = "WASM Heap Usage"
                type = "graph"
                gridPos = @{ h = 8; w = 12; x = 0; y = 8 }
                targets = @(
                    @{
                        expr = "wasm_heap_used_bytes"
                        legendFormat = "Heap Used"
                    },
                    @{
                        expr = "wasm_heap_total_bytes"
                        legendFormat = "Heap Total"
                    }
                )
                yAxes = @(
                    @{
                        unit = "bytes"
                    }
                )
            },
            @{
                title = "SharedArrayBuffer Usage"
                type = "stat"
                gridPos = @{ h = 8; w = 12; x = 12; y = 8 }
                targets = @(
                    @{
                        expr = "shared_array_buffer_available"
                        legendFormat = "SAB Available"
                    }
                )
            }
        )
        refresh = "5s"
        time = @{
            from = "now-1h"
            to = "now"
        }
    }
}

# Triton Health Dashboard (uses placeholder expressions; wire to your metrics/logs as needed)
$TritonHealthDashboard = @{
    dashboard = @{
        title = "Triton Health"
        description = "Triton availability and model status from gpu-inference-sidecar"
        panels = @(
            @{
                title = "Triton Available"
                type = "stat"
                gridPos = @{ h = 8; w = 6; x = 0; y = 0 }
                targets = @(
                    @{ expr = "triton_available"; legendFormat = "Available (1/0)" }
                )
                fieldConfig = @{ defaults = @{ color = @{ mode = "thresholds" }; thresholds = @{ steps = @(@{ color = "red"; value = 0 }, @{ color = "green"; value = 1 }) } } }
            },
            @{
                title = "Model Count"
                type = "stat"
                gridPos = @{ h = 8; w = 6; x = 6; y = 0 }
                targets = @(
                    @{ expr = "model_count"; legendFormat = "Models" }
                )
            },
            @{
                title = "Inference Sidecar Health"
                type = "table"
                gridPos = @{ h = 10; w = 12; x = 0; y = 8 }
                targets = @(
                    @{ expr = "sidecar_health_deep"; legendFormat = "Deep Health (wire to logs query)" }
                )
            }
        )
        refresh = "30s"
        time = @{ from = "now-1h"; to = "now" }
    }
}

function Test-SigNozConnection {
    try {
        $response = Invoke-WebRequest -Uri "$SigNozApiUrl/health" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ SigNoz API accessible" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ SigNoz API returned status: $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ SigNoz API not accessible: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Import-Dashboard {
    param($DashboardName, $DashboardConfig)
    
    Write-Host "`n📊 Importing $DashboardName Dashboard..." -ForegroundColor Cyan
    
    if ($DryRun) {
        Write-Host "🔍 DRY RUN: Would import $DashboardName dashboard" -ForegroundColor Yellow
        Write-Host "   Title: $($DashboardConfig.dashboard.title)" -ForegroundColor White
        Write-Host "   Panels: $($DashboardConfig.dashboard.panels.Count)" -ForegroundColor White
        return
    }
    
    try {
        $jsonBody = $DashboardConfig | ConvertTo-Json -Depth 10
        $response = Invoke-WebRequest -Uri "$SigNozApiUrl/dashboards" -Method POST -ContentType "application/json" -Body $jsonBody -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
        
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 201) {
            Write-Host "✅ $DashboardName dashboard imported successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Failed to import $DashboardName dashboard. Status: $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Error importing $DashboardName dashboard: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-Host "=== SigNoz Dashboard Import Script ===" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White

# Test SigNoz connection
if (-not (Test-SigNozConnection)) {
    Write-Host "`n❌ Cannot connect to SigNoz. Please ensure SigNoz is running on $SigNozBaseUrl" -ForegroundColor Red
    exit 1
}

# Determine which dashboards to import
$dashboardsToImport = @()

if ($All) {
    $dashboardsToImport = @("SystemHealth", "Performance", "Application", "Triton")
} else {
    if ($SystemHealth) { $dashboardsToImport += "SystemHealth" }
    if ($Performance) { $dashboardsToImport += "Performance" }
    if ($Application) { $dashboardsToImport += "Application" }
    if ($Triton) { $dashboardsToImport += "Triton" }
}

# If no specific dashboards selected, import all
if ($dashboardsToImport.Count -eq 0) {
    $dashboardsToImport = @("SystemHealth", "Performance", "Application")
}

# Import dashboards
$successCount = 0
$totalCount = $dashboardsToImport.Count

foreach ($dashboard in $dashboardsToImport) {
    switch ($dashboard) {
        "SystemHealth" {
            if (Import-Dashboard "System Health" $SystemHealthDashboard) { $successCount++ }
        }
        "Performance" {
            if (Import-Dashboard "Performance" $PerformanceDashboard) { $successCount++ }
        }
        "Application" {
            if (Import-Dashboard "Application" $ApplicationDashboard) { $successCount++ }
        }
        "Triton" {
            if (Import-Dashboard "Triton Health" $TritonHealthDashboard) { $successCount++ }
        }
    }
}

# Summary
Write-Host "`n=== Import Summary ===" -ForegroundColor Cyan
Write-Host "Total Dashboards: $totalCount" -ForegroundColor White
Write-Host "Successfully Imported: $successCount" -ForegroundColor Green
Write-Host "Failed: $($totalCount - $successCount)" -ForegroundColor Red

if ($successCount -eq $totalCount) {
    Write-Host "`n🎉 All dashboards imported successfully!" -ForegroundColor Green
    Write-Host "Access SigNoz at: $SigNozBaseUrl" -ForegroundColor White
} else {
    Write-Host "`n⚠️ Some dashboards failed to import. Check SigNoz logs for details." -ForegroundColor Yellow
}

Write-Host "`n=== Dashboard Import Complete ===" -ForegroundColor Cyan
