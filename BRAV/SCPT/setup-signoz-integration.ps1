# ECRR Monitoring Dashboard Integration
# This script integrates ECRR compliance monitoring with SigNoz dashboard

param(
    [string]$SignozUrl = "http://localhost:8080",
    [string]$DashboardName = "ECRR Compliance Monitoring",
    [string]$OutputDir = "artifacts"
)

$ErrorActionPreference = "Stop"

Write-Host "ECRR SigNoz Dashboard Integration" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Generate SigNoz dashboard configuration
$DashboardConfig = @{
    name = $DashboardName
    description = "ECRR Compliance Monitoring Dashboard"
    panels = @(
        @{
            title = "ECRR Compliance Trend"
            type = "line"
            query = "ecrr_compliance_four_section_pct"
            description = "Four-section structure compliance over time"
        },
        @{
            title = "ECRR Gates Compliance"
            type = "line"
            query = "ecrr_compliance_gate_pct"
            description = "ECRR Gates compliance over time"
        },
        @{
            title = "Total ECRR Reports"
            type = "stat"
            query = "ecrr_total_reports"
            description = "Total number of ECRR reports"
        },
        @{
            title = "Compliance Status"
            type = "stat"
            query = "ecrr_compliance_status"
            description = "Current compliance status (PASS/FAIL)"
        }
    )
    alerts = @(
        @{
            name = "ECRR Compliance Drop"
            condition = "ecrr_compliance_four_section_pct < 95"
            severity = "warning"
            description = "Four-section compliance below 95%"
        },
        @{
            name = "ECRR Gates Drop"
            condition = "ecrr_compliance_gate_pct < 90"
            severity = "warning"
            description = "ECRR Gates compliance below 90%"
        }
    )
}

# Save dashboard configuration
$DashboardConfig | ConvertTo-Json -Depth 3 | Out-File -FilePath "$OutputDir/signoz-ecrr-dashboard.json" -Encoding UTF8

# Generate metrics export script
$MetricsExportScript = @'
# ECRR Metrics Export to SigNoz
# This script exports ECRR compliance metrics to SigNoz for dashboard integration

param(
    [string]$SignozUrl = "http://localhost:8080",
    [string]$ValidationFile = "artifacts/ecrr-ci-validation.json",
    [string]$TrendFile = "artifacts/ecrr-compliance-trends.json"
)

$ErrorActionPreference = "Stop"

# Load validation results
if (-not (Test-Path $ValidationFile)) {
    Write-Host "❌ Validation results not found: $ValidationFile" -ForegroundColor Red
    exit 1
}

$validation = Get-Content $ValidationFile | ConvertFrom-Json

# Load trend data
if (Test-Path $TrendFile) {
    $trends = Get-Content $TrendFile | ConvertFrom-Json
} else {
    $trends = @{}
}

# Prepare metrics for SigNoz
$metrics = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    metrics = @{
        ecrr_compliance_four_section_pct = $validation.fourSection.pct
        ecrr_compliance_gate_pct = $validation.ecrrGate.pct
        ecrr_total_reports = $validation.total
        ecrr_compliance_status = if ($validation.passed) { 1 } else { 0 }
        ecrr_four_section_count = $validation.fourSection.count
        ecrr_gate_count = $validation.ecrrGate.count
        ecrr_actor_declaration_pct = $validation.actorDeclaration.pct
        ecrr_evidence_reference_pct = $validation.evidenceReference.pct
    }
}

# Add trend data if available
if ($trends.PSObject.Properties.Name -contains "averages") {
    $metrics.metrics.ecrr_avg_four_section_pct = $trends.averages.fourSectionPct
    $metrics.metrics.ecrr_avg_gate_pct = $trends.averages.gatePct
    $metrics.metrics.ecrr_trend_four_section = $trends.trends.fourSectionTrend
    $metrics.metrics.ecrr_trend_gate = $trends.trends.gateTrend
}

# Export metrics to SigNoz (OTLP format)
$otlpPayload = @{
    resourceMetrics = @(
        @{
            resource = @{
                attributes = @(
                    @{ key = "service.name"; value = @{ stringValue = "ecrr-compliance" } }
                    @{ key = "service.version"; value = @{ stringValue = "1.0.0" } }
                )
            }
            scopeMetrics = @(
                @{
                    scope = @{ name = "ecrr-compliance-monitor" }
                    metrics = @(
                        foreach ($metric in $metrics.metrics.GetEnumerator()) {
                            @{
                                name = $metric.Key
                                gauge = @{
                                    dataPoints = @(
                                        @{
                                            timeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                                            asDouble = $metric.Value
                                        }
                                    )
                                }
                            }
                        }
                    )
                }
            )
        }
    )
}

# Send to SigNoz OTLP endpoint
try {
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    $response = Invoke-RestMethod -Uri "$SignozUrl/v1/metrics" -Method Post -Body ($otlpPayload | ConvertTo-Json -Depth 10) -Headers $headers
    
    Write-Host "✅ Metrics exported to SigNoz successfully" -ForegroundColor Green
    Write-Host "   Dashboard URL: $SignozUrl/dashboards" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Failed to export metrics to SigNoz: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Metrics data saved locally for manual import" -ForegroundColor Yellow
    
    # Save metrics locally for manual import
    $metrics | ConvertTo-Json -Depth 3 | Out-File -FilePath "artifacts/ecrr-signoz-metrics.json" -Encoding UTF8
}

# Log export
$logEntry = @{
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss UTC")
    signozUrl = $SignozUrl
    metricsCount = $metrics.metrics.Count
    success = $?
}

$logEntry | ConvertTo-Json | Add-Content -Path "artifacts/ecrr-signoz-export-history.jsonl" -Encoding UTF8
'@

$MetricsExportScript | Out-File -FilePath "scripts/export-ecrr-metrics-to-signoz.ps1" -Encoding UTF8

Write-Host "`n✅ SigNoz Integration Created:" -ForegroundColor Green
Write-Host "- Dashboard Config: $OutputDir/signoz-ecrr-dashboard.json" -ForegroundColor White
Write-Host "- Metrics Export: scripts/export-ecrr-metrics-to-signoz.ps1" -ForegroundColor White

Write-Host "`n📊 SigNoz Integration Steps:" -ForegroundColor Yellow
Write-Host "1. Import dashboard: Use $OutputDir/signoz-ecrr-dashboard.json" -ForegroundColor White
Write-Host "2. Export metrics: pwsh -File scripts/export-ecrr-metrics-to-signoz.ps1" -ForegroundColor White
Write-Host "3. Schedule exports: Add to Task Scheduler or cron" -ForegroundColor White
Write-Host "4. View dashboard: $SignozUrl/dashboards" -ForegroundColor White

Write-Host "`n🔧 Usage Examples:" -ForegroundColor Cyan
Write-Host "# Export current metrics to SigNoz" -ForegroundColor White
Write-Host "pwsh -File scripts/export-ecrr-metrics-to-signoz.ps1" -ForegroundColor Gray
Write-Host "" -ForegroundColor White
Write-Host "# Export with custom SigNoz URL" -ForegroundColor White
Write-Host "pwsh -File scripts/export-ecrr-metrics-to-signoz.ps1 -SignozUrl 'http://your-signoz:8080'" -ForegroundColor Gray
