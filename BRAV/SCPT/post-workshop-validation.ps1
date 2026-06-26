# Post-Workshop ECRR Compliance Validation Script
# Automatically validates compliance after workshop sessions

param(
    [string]$WorkshopName = "workshop-$(Get-Date -Format 'yyyy-MM-dd-HHmm')",
    [string]$ReportsPath = "CHAR/ECRR/ECRR_REPORTS",
    [switch]$GenerateTrends,
    [switch]$SendAlerts,
    [int]$ComplianceThreshold = 80
)

# Initialize OpenTelemetry functions
. $PSScriptRoot\..\otel\otel-functions.ps1

Write-Host "🎓 Post-Workshop ECRR Compliance Validation" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Workshop: $WorkshopName" -ForegroundColor Yellow

# Function to validate workshop reports
function Test-WorkshopReports {
    param($Path)
    
    Write-Host "🔍 Validating workshop reports..." -ForegroundColor Yellow
    
    # Find workshop reports created today
    $today = Get-Date -Format "yyyy-MM-dd"
    $workshopReports = Get-ChildItem $Path -Filter "workshop-*" | Where-Object { 
        $_.LastWriteTime.Date -eq (Get-Date).Date 
    }
    
    if ($workshopReports.Count -eq 0) {
        Write-Warning "No workshop reports found for today"
        return @{
            Success = $false
            Message = "No workshop reports found"
            Reports = @()
        }
    }
    
    Write-Host "Found $($workshopReports.Count) workshop reports:" -ForegroundColor Green
    foreach ($report in $workshopReports) {
        Write-Host "  - $($report.Name)" -ForegroundColor White
    }
    
    # Run compliance validation
    $validationResult = & $PSScriptRoot\validate-ecrr-compliance.ps1 -Path $Path -OutputPath "artifacts/ecrr-compliance-report.json"
    
    # Accept exit codes 0 (good), 1 (warning), 2 (poor) as valid
    if ($LASTEXITCODE -gt 2) {
        Write-Warning "Compliance validation failed with exit code $LASTEXITCODE"
        return @{
            Success = $false
            Message = "Validation failed"
            Reports = $workshopReports
        }
    }
    
    # Load compliance results
    $reportPath = "artifacts/ecrr-compliance-report.json"
    if (-not (Test-Path $reportPath)) {
        Write-Error "Compliance report not found"
        return @{
            Success = $false
            Message = "Compliance report not found"
            Reports = $workshopReports
        }
    }
    
    $complianceReport = Get-Content $reportPath -Raw | ConvertFrom-Json
    
    # Filter workshop reports from compliance results
    $workshopCompliance = $complianceReport.Reports | Where-Object { 
        $_.File -like "workshop-*" 
    }
    
    return @{
        Success = $true
        Message = "Validation completed"
        Reports = $workshopReports
        ComplianceResults = $workshopCompliance
        OverallScore = $complianceReport.Overall_Score
        TotalReports = $complianceReport.Total_Reports
    }
}

# Function to generate workshop summary
function New-WorkshopSummary {
    param($ValidationResults, $WorkshopName)
    
    $summaryPath = "artifacts/workshop-summary-$WorkshopName.json"
    
    $summary = @{
        WorkshopName = $WorkshopName
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        ValidationResults = $ValidationResults
        Summary = @{
            TotalWorkshopReports = $ValidationResults.Reports.Count
            PerfectComplianceReports = ($ValidationResults.ComplianceResults | Where-Object { $_.Score -eq $_.Total }).Count
            FailedComplianceReports = ($ValidationResults.ComplianceResults | Where-Object { $_.Score -lt $_.Total }).Count
            AverageScore = if ($ValidationResults.ComplianceResults.Count -gt 0) { 
                [math]::Round(($ValidationResults.ComplianceResults | Measure-Object -Property Score -Average).Average, 2) 
            } else { 0 }
            ComplianceRate = if ($ValidationResults.ComplianceResults.Count -gt 0) {
                [math]::Round((($ValidationResults.ComplianceResults | Where-Object { $_.Score -eq $_.Total }).Count / $ValidationResults.ComplianceResults.Count) * 100, 2)
            } else { 0 }
        }
    }
    
    $summary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath
    Write-Host "📄 Workshop summary saved: $summaryPath" -ForegroundColor Green
    
    return $summary
}

# Function to check compliance trends
function Test-ComplianceTrends {
    param($CurrentResults)
    
    Write-Host "📈 Checking compliance trends..." -ForegroundColor Yellow
    
    # Run trends monitoring
    $trendsResult = & $PSScriptRoot\monitor-ecrr-compliance-trends.ps1 -GenerateReport -AlertOnDecline
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Trends analysis completed" -ForegroundColor Green
        
        # Load trends data
        $trendsPath = "artifacts/ecrr-compliance-trends.json"
        if (Test-Path $trendsPath) {
            $trends = Get-Content $trendsPath -Raw | ConvertFrom-Json
            return $trends.CurrentTrend
        }
    }
    
    return $null
}

# Function to send alerts if needed
function Send-ComplianceAlerts {
    param($Summary, $Trends, $Threshold)
    
    if (-not $SendAlerts) {
        return
    }
    
    Write-Host "📢 Checking alert conditions..." -ForegroundColor Yellow
    
    $alerts = @()
    
    # Check workshop compliance rate
    if ($Summary.Summary.ComplianceRate -lt $Threshold) {
        $alerts += "Workshop compliance rate ($($Summary.Summary.ComplianceRate)%) below threshold ($Threshold%)"
    }
    
    # Check overall trends
    if ($Trends -and $Trends.TrendDirection -eq "Downward") {
        $alerts += "Overall compliance trending downward ($($Trends.TrendPercentage)%)"
    }
    
    if ($alerts.Count -gt 0) {
        Write-Host ""
        Write-Host "🚨 ALERTS TRIGGERED:" -ForegroundColor Red
        foreach ($alert in $alerts) {
            Write-Host "   - $alert" -ForegroundColor Red
        }
        
        # Create alert file
        $alertPath = "artifacts/compliance-alerts-$WorkshopName.json"
        @{
            Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            WorkshopName = $WorkshopName
            Alerts = $alerts
            Summary = $Summary
            Trends = $Trends
        } | ConvertTo-Json -Depth 10 | Set-Content -Path $alertPath
        
        Write-Host "📄 Alert details saved: $alertPath" -ForegroundColor Yellow
    } else {
        Write-Host "✅ No alerts triggered" -ForegroundColor Green
    }
}

# Main execution
try {
    Write-Host "🚀 Starting post-workshop validation..." -ForegroundColor Green
    
    # Validate workshop reports
    $validationResults = Test-WorkshopReports -Path $ReportsPath
    
    if (-not $validationResults.Success) {
        Write-Error "Workshop validation failed: $($validationResults.Message)"
        exit 1
    }
    
    # Generate workshop summary
    $summary = New-WorkshopSummary -ValidationResults $validationResults -WorkshopName $WorkshopName
    
    # Display results
    Write-Host ""
    Write-Host "📊 Workshop Validation Results:" -ForegroundColor Cyan
    Write-Host "   Workshop: $WorkshopName" -ForegroundColor White
    Write-Host "   Reports Created: $($summary.Summary.TotalWorkshopReports)" -ForegroundColor White
    Write-Host "   Perfect Compliance: $($summary.Summary.PerfectComplianceReports)" -ForegroundColor White
    Write-Host "   Failed Compliance: $($summary.Summary.FailedComplianceReports)" -ForegroundColor White
    Write-Host "   Average Score: $($summary.Summary.AverageScore)/12" -ForegroundColor White
    Write-Host "   Compliance Rate: $($summary.Summary.ComplianceRate)%" -ForegroundColor White
    
    # Check trends if requested
    $trends = $null
    if ($GenerateTrends) {
        $trends = Test-ComplianceTrends -CurrentResults $validationResults
    }
    
    # Send alerts if needed
    Send-ComplianceAlerts -Summary $summary -Trends $trends -Threshold $ComplianceThreshold
    
    # Display individual report results
    if ($validationResults.ComplianceResults.Count -gt 0) {
        Write-Host ""
        Write-Host "📋 Individual Report Results:" -ForegroundColor Cyan
        foreach ($result in $validationResults.ComplianceResults) {
            $status = if ($result.Score -eq $result.Total) { "✅" } else { "❌" }
            Write-Host "   $status $($result.File): $($result.Score)/$($result.Total)" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "✅ Post-workshop validation complete!" -ForegroundColor Green
    
    # Return success
    exit 0
    
} catch {
    Write-Error "Post-workshop validation failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}

