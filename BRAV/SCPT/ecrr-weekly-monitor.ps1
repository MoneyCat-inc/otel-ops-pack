# ECRR Weekly Compliance Monitoring Script
# Automated weekly monitoring with trend analysis and alerting

param(
    [string]$OutputPath = "artifacts/ecrr-weekly-monitor-$(Get-Date -Format 'yyyy-MM-dd').json",
    [switch]$GenerateReport = $true,
    [switch]$SendAlerts = $false,
    [int]$ComplianceThreshold = 70
)

# ECRR Weekly Monitoring Functions
function Get-WeeklyComplianceData {
    $reportsPath = "CHAR/ECRR/ECRR_REPORTS"
    if (-not (Test-Path $reportsPath)) {
        Write-Warning "ECRR reports directory not found: $reportsPath"
        return @{}
    }
    
    $reports = Get-ChildItem -Path $reportsPath -Filter "*.md" | Where-Object { $_.Name -ne "ECRR_PROCESSING_ANALYSIS.md" }
    
    $weeklyData = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        WeekOf = (Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
        TotalReports = $reports.Count
        RecentReports = 0
        ComplianceMetrics = @{
            ECRRGateCompliance = 0
            FourSectionStructure = 0
            ActorDeclaration = 0
            EvidenceAttachment = 0
            StatusDeclaration = 0
            OverallCompliance = 0
        }
        TrendAnalysis = @{
            ECRRGateTrend = "stable"
            StructureTrend = "stable"
            ActorTrend = "stable"
            EvidenceTrend = "stable"
            StatusTrend = "stable"
            OverallTrend = "stable"
        }
        AgentPerformance = @{}
        QualityAlerts = @()
        Recommendations = @()
    }
    
    # Count recent reports (last 7 days)
    $oneWeekAgo = (Get-Date).AddDays(-7)
    foreach ($report in $reports) {
        if ($report.LastWriteTime -gt $oneWeekAgo) {
            $weeklyData.RecentReports++
        }
    }
    
    # Run compliance analysis
    $complianceResults = & pwsh -File scripts/ecrr-compliance-monitor.ps1 -OutputPath "temp-compliance.json" 2>$null
    if (Test-Path "temp-compliance.json") {
        $complianceData = Get-Content "temp-compliance.json" | ConvertFrom-Json
        $weeklyData.ComplianceMetrics = $complianceData.ComplianceMetrics
        Remove-Item "temp-compliance.json" -Force
    }
    
    # Analyze agent performance
    foreach ($report in $reports) {
        $content = Get-Content $report.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        
        # Extract agent name
        if ($content -match "\*\*Agent\*\*:\s*([^\n]+)") {
            $agentName = $matches[1].Trim()
            if (-not $weeklyData.AgentPerformance.ContainsKey($agentName)) {
                $weeklyData.AgentPerformance[$agentName] = @{
                    ReportCount = 0
                    ComplianceScore = 0
                    LastReport = $null
                }
            }
            
            $weeklyData.AgentPerformance[$agentName].ReportCount++
            $weeklyData.AgentPerformance[$agentName].LastReport = $report.LastWriteTime
        }
    }
    
    # Calculate agent compliance scores
    foreach ($agentName in $weeklyData.AgentPerformance.Keys) {
        $agentReports = $reports | Where-Object { 
            $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            $content -match "\*\*Agent\*\*:\s*$([regex]::Escape($agentName))"
        }
        
        $compliantReports = 0
        foreach ($report in $agentReports) {
            $content = Get-Content $report.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -and $content -match "ECRR Gate.*MANDATORY VALIDATION") {
                $compliantReports++
            }
        }
        
        if ($agentReports.Count -gt 0) {
            $weeklyData.AgentPerformance[$agentName].ComplianceScore = [math]::Round(($compliantReports / $agentReports.Count) * 100, 1)
        }
    }
    
    return $weeklyData
}

function Get-TrendAnalysis {
    param([hashtable]$CurrentData)
    
    # Load historical data
    $historicalFiles = Get-ChildItem -Path "artifacts" -Filter "ecrr-weekly-monitor-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 4
    
    if ($historicalFiles.Count -lt 2) {
        return @{
            ECRRGateTrend = "insufficient_data"
            StructureTrend = "insufficient_data"
            ActorTrend = "insufficient_data"
            EvidenceTrend = "insufficient_data"
            StatusTrend = "insufficient_data"
            OverallTrend = "insufficient_data"
        }
    }
    
    $previousData = Get-Content $historicalFiles[1].FullName | ConvertFrom-Json
    
    $trends = @{}
    $metrics = @("ECRRGateCompliance", "FourSectionStructure", "ActorDeclaration", "EvidenceAttachment", "StatusDeclaration", "OverallCompliance")
    
    foreach ($metric in $metrics) {
        $current = $CurrentData.ComplianceMetrics.$metric
        $previous = $previousData.ComplianceMetrics.$metric
        
        if ($current -gt $previous + 5) {
            $trends["$($metric)Trend"] = "improving"
        } elseif ($current -lt $previous - 5) {
            $trends["$($metric)Trend"] = "declining"
        } else {
            $trends["$($metric)Trend"] = "stable"
        }
    }
    
    return $trends
}

function Generate-QualityAlerts {
    param(
        [hashtable]$WeeklyData,
        [int]$Threshold
    )
    
    $alerts = @()
    
    # Compliance threshold alerts
    foreach ($metric in $WeeklyData.ComplianceMetrics.PSObject.Properties) {
        if ($metric.Value -lt $Threshold) {
            $alerts += "LOW_COMPLIANCE: $($metric.Name) is $($metric.Value)% (below $Threshold% threshold)"
        }
    }
    
    # Agent performance alerts
    foreach ($agentName in $WeeklyData.AgentPerformance.Keys) {
        $agentData = $WeeklyData.AgentPerformance[$agentName]
        if ($agentData.ComplianceScore -lt $Threshold) {
            $alerts += "AGENT_PERFORMANCE: $agentName has $($agentData.ComplianceScore)% compliance (below $Threshold% threshold)"
        }
    }
    
    # Activity alerts
    if ($WeeklyData.RecentReports -eq 0) {
        $alerts += "ACTIVITY: No new ECRR reports in the last 7 days"
    }
    
    return $alerts
}

function Generate-WeeklyReport {
    param([hashtable]$WeeklyData)
    
    $report = @"
# ECRR Weekly Compliance Report

**Generated**: $($WeeklyData.GeneratedAt)  
**Week of**: $($WeeklyData.WeekOf)  
**Total Reports**: $($WeeklyData.TotalReports)  
**Recent Reports (7 days)**: $($WeeklyData.RecentReports)

## 📊 Compliance Metrics

| Metric | Current | Trend | Status |
|--------|---------|-------|--------|
| ECRR Gate Compliance | $($WeeklyData.ComplianceMetrics.ECRRGateCompliance)% | $($WeeklyData.TrendAnalysis.ECRRGateTrend) | $(if ($WeeklyData.ComplianceMetrics.ECRRGateCompliance -ge 80) { "✅ Good" } else { "⚠️ Needs Improvement" }) |
| 4-Section Structure | $($WeeklyData.ComplianceMetrics.FourSectionStructure)% | $($WeeklyData.TrendAnalysis.StructureTrend) | $(if ($WeeklyData.ComplianceMetrics.FourSectionStructure -ge 90) { "✅ Good" } else { "⚠️ Needs Improvement" }) |
| Actor Declaration | $($WeeklyData.ComplianceMetrics.ActorDeclaration)% | $($WeeklyData.TrendAnalysis.ActorTrend) | $(if ($WeeklyData.ComplianceMetrics.ActorDeclaration -ge 95) { "✅ Good" } else { "⚠️ Needs Improvement" }) |
| Evidence Attachment | $($WeeklyData.ComplianceMetrics.EvidenceAttachment)% | $($WeeklyData.TrendAnalysis.EvidenceTrend) | $(if ($WeeklyData.ComplianceMetrics.EvidenceAttachment -ge 85) { "✅ Good" } else { "⚠️ Needs Improvement" }) |
| Status Declaration | $($WeeklyData.ComplianceMetrics.StatusDeclaration)% | $($WeeklyData.TrendAnalysis.StatusTrend) | $(if ($WeeklyData.ComplianceMetrics.StatusDeclaration -ge 75) { "✅ Good" } else { "⚠️ Needs Improvement" }) |
| Overall Compliance | $($WeeklyData.ComplianceMetrics.OverallCompliance)% | $($WeeklyData.TrendAnalysis.OverallTrend) | $(if ($WeeklyData.ComplianceMetrics.OverallCompliance -ge 70) { "✅ Good" } else { "⚠️ Needs Improvement" }) |

## 🎭 Agent Performance

| Agent | Reports | Compliance Score | Last Report |
|-------|---------|------------------|-------------|
"@

    foreach ($agentName in $WeeklyData.AgentPerformance.Keys) {
        $agentData = $WeeklyData.AgentPerformance[$agentName]
        $lastReport = if ($agentData.LastReport) { $agentData.LastReport.ToString("yyyy-MM-dd") } else { "Never" }
        $report += "`n| $agentName | $($agentData.ReportCount) | $($agentData.ComplianceScore)% | $lastReport |"
    }
    
    if ($WeeklyData.QualityAlerts.Count -gt 0) {
        $report += "`n`n## 🚨 Quality Alerts`n`n"
        foreach ($alert in $WeeklyData.QualityAlerts) {
            $report += "- $alert`n"
        }
    }
    
    if ($WeeklyData.Recommendations.Count -gt 0) {
        $report += "`n`n## 💡 Recommendations`n`n"
        foreach ($recommendation in $WeeklyData.Recommendations) {
            $report += "- $recommendation`n"
        }
    }
    
    $report += "`n`n---`n`n**Next Review**: $((Get-Date).AddDays(7).ToString("yyyy-MM-dd"))"
    
    return $report
}

# Main execution
Write-Host "📅 ECRR Weekly Compliance Monitoring" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')" -ForegroundColor Gray

# Get weekly compliance data
Write-Host "📊 Collecting weekly compliance data..." -ForegroundColor Yellow
$weeklyData = Get-WeeklyComplianceData

# Perform trend analysis
Write-Host "📈 Analyzing trends..." -ForegroundColor Yellow
$weeklyData.TrendAnalysis = Get-TrendAnalysis -CurrentData $weeklyData

# Generate quality alerts
Write-Host "🚨 Checking quality alerts..." -ForegroundColor Yellow
$weeklyData.QualityAlerts = Generate-QualityAlerts -WeeklyData $weeklyData -Threshold $ComplianceThreshold

# Generate recommendations
if ($weeklyData.ComplianceMetrics.ECRRGateCompliance -lt 80) {
    $weeklyData.Recommendations += "Focus on ECRR Gate adoption. Deploy enhanced template to all agents."
}
if ($weeklyData.ComplianceMetrics.FourSectionStructure -lt 90) {
    $weeklyData.Recommendations += "Improve 4-section structure compliance. Provide template training."
}
if ($weeklyData.RecentReports -eq 0) {
    $weeklyData.Recommendations += "Increase ECRR report activity. Encourage more frequent reporting."
}

# Save weekly data
$outputDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$weeklyData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "💾 Weekly monitoring data saved to: $OutputPath" -ForegroundColor Green

# Generate report if requested
if ($GenerateReport) {
    $reportPath = $OutputPath -replace '\.json$', '.md'
    $report = Generate-WeeklyReport -WeeklyData $weeklyData
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "📋 Weekly report generated: $reportPath" -ForegroundColor Green
}

# Display summary
Write-Host "`n📊 Weekly Compliance Summary:" -ForegroundColor Cyan
Write-Host "Total Reports: $($weeklyData.TotalReports)" -ForegroundColor White
Write-Host "Recent Reports (7 days): $($weeklyData.RecentReports)" -ForegroundColor White
Write-Host "Overall Compliance: $($weeklyData.ComplianceMetrics.OverallCompliance)%" -ForegroundColor $(if ($weeklyData.ComplianceMetrics.OverallCompliance -ge $ComplianceThreshold) { "Green" } else { "Red" })
Write-Host "Quality Alerts: $($weeklyData.QualityAlerts.Count)" -ForegroundColor $(if ($weeklyData.QualityAlerts.Count -eq 0) { "Green" } else { "Yellow" })

if ($weeklyData.QualityAlerts.Count -gt 0) {
    Write-Host "`n🚨 Quality Alerts:" -ForegroundColor Yellow
    foreach ($alert in $weeklyData.QualityAlerts) {
        Write-Host "  • $alert" -ForegroundColor White
    }
}

Write-Host "`n✅ Weekly compliance monitoring complete!" -ForegroundColor Green

