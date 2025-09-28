# ECRR CI/CD Integration Script
# Integrates ECRR compliance monitoring with CI/CD pipeline

param(
    [string]$Action = "check",
    [string]$Branch = "main",
    [string]$CommitHash = "",
    [string]$WebhookUrl = "",
    [switch]$FailOnRegression,
    [switch]$GenerateReport,
    [int]$RegressionThreshold = 5
)

# CI/CD Configuration
$CICD_CONFIG = @{
    "Thresholds" = @{
        "Critical" = 50
        "Warning" = 70
        "Target" = 80
        "Regression" = 5
    }
}

function Get-GitInfo {
    try {
        $branch = if ($Branch -eq "main") { 
            git rev-parse --abbrev-ref HEAD 2>$null
        } else { 
            $Branch 
        }
        
        $commitHash = if ($CommitHash -eq "") { 
            git rev-parse HEAD 2>$null
        } else { 
            $CommitHash 
        }
        
        return @{
            "Branch" = $branch
            "CommitHash" = $commitHash
            "Timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
    }
    catch {
        return @{
            "Branch" = "unknown"
            "CommitHash" = "unknown"
            "Timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
    }
}

function Invoke-ComplianceCheck {
    param([hashtable]$GitInfo)
    
    Write-Host "🔍 Running ECRR Compliance Check for CI/CD..." -ForegroundColor Cyan
    
    # Run compliance validation
    $complianceResults = & "$PSScriptRoot/validate-ecrr-compliance.ps1" -ReportPath "docs/ECRR_REPORTS" -OutputPath "artifacts/ci-compliance-report.json"
    
    $overallScore = $complianceResults.Overall_Score
    $totalReports = $complianceResults.Total_Reports
    
    # Load previous score
    $previousScore = 0
    $statePath = "artifacts/ecrr-compliance-monitoring/monitoring-state.json"
    if (Test-Path $statePath) {
        $monitoringState = Get-Content $statePath | ConvertFrom-Json
        $previousScore = $monitoringState.LastScore
    }
    
    $regression = $previousScore - $overallScore
    $hasRegression = $regression -gt $RegressionThreshold
    
    $status = if ($overallScore -lt $CICD_CONFIG.Thresholds.Critical) {
        "CRITICAL"
    } elseif ($overallScore -lt $CICD_CONFIG.Thresholds.Warning) {
        "WARNING"
    } elseif ($hasRegression) {
        "REGRESSION"
    } else {
        "PASS"
    }
    
    $cicdReport = @{
        "GitInfo" = $GitInfo
        "Compliance" = @{
            "OverallScore" = $overallScore
            "PreviousScore" = $previousScore
            "Regression" = $regression
            "HasRegression" = $hasRegression
            "TotalReports" = $totalReports
            "Status" = $status
        }
        "Timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    
    $reportPath = "artifacts/cicd-compliance-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $cicdReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host "📊 CI/CD Compliance Results:" -ForegroundColor Green
    Write-Host "   Status: $status" -ForegroundColor $(if ($status -eq "PASS") { "Green" } elseif ($status -eq "WARNING") { "Yellow" } else { "Red" })
    Write-Host "   Overall Score: $([math]::Round($overallScore, 1))%" -ForegroundColor $(if ($overallScore -lt 50) { "Red" } elseif ($overallScore -lt 70) { "Yellow" } else { "Green" })
    Write-Host "   Regression: $([math]::Round($regression, 1))%" -ForegroundColor $(if ($hasRegression) { "Red" } else { "Green" })
    
    return $cicdReport
}

function Invoke-ComplianceGate {
    param([hashtable]$CICDReport)
    
    $status = $CICDReport.Compliance.Status
    $score = $CICDReport.Compliance.OverallScore
    $hasRegression = $CICDReport.Compliance.HasRegression
    
    Write-Host "🚪 ECRR Compliance Gate Check..." -ForegroundColor Cyan
    
    $gatePassed = $true
    $gateMessage = ""
    
    if ($score -lt $CICD_CONFIG.Thresholds.Critical) {
        $gatePassed = $false
        $gateMessage = "CRITICAL: Compliance score $([math]::Round($score, 1))% is below critical threshold"
    }
    elseif ($FailOnRegression -and $hasRegression) {
        $gatePassed = $false
        $gateMessage = "REGRESSION: Compliance decreased by $([math]::Round($CICDReport.Compliance.Regression, 1))%"
    }
    else {
        $gateMessage = "PASS: Compliance score $([math]::Round($score, 1))% meets requirements"
    }
    
    Write-Host "🚪 Compliance Gate: $(if ($gatePassed) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($gatePassed) { 'Green' } else { 'Red' })
    Write-Host "   $gateMessage" -ForegroundColor $(if ($gatePassed) { 'Green' } else { 'Red' })
    
    if (-not $gatePassed) {
        Write-Host "❌ CI/CD pipeline will fail due to compliance gate" -ForegroundColor Red
        exit 1
    }
    else {
        Write-Host "✅ CI/CD pipeline can proceed" -ForegroundColor Green
        exit 0
    }
}

# Main execution
Write-Host "🚀 Starting ECRR CI/CD Integration..." -ForegroundColor Cyan

$gitInfo = Get-GitInfo
$cicdReport = Invoke-ComplianceCheck -GitInfo $gitInfo

switch ($Action.ToLower()) {
    "check" {
        Write-Host "✅ Compliance check completed" -ForegroundColor Green
    }
    "gate" {
        Invoke-ComplianceGate -CICDReport $cicdReport
    }
    default {
        Write-Host "❌ Unknown action: $Action" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ ECRR CI/CD Integration Complete" -ForegroundColor Green