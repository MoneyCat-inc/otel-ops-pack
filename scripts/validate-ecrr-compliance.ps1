# ECRR Compliance Validation Script
# Validates ECRR reports against the enhanced template requirements

param(
    [string]$ReportPath = "docs/ECRR_REPORTS",
    [string]$OutputPath = "artifacts/ecrr-compliance-report.json",
    [switch]$Verbose
)

# ECRR Compliance Requirements
$ECRR_REQUIREMENTS = @{
    "Structure" = @{
        "4_Section_Structure" = @("## 🔍 **1. Examine", "## 🧹 **2. Clean", "## 📝 **3. Report", "## 🎭 **4. Role")
        "ECRR_Gate" = "## ✅ **ECRR Gate"
        "Status_Declaration" = "**Status**:"
    }
    "Content" = @{
        "Actor_Declaration" = @("**Agent**:", "**Actor**:")
        "Evidence_Attachment" = @("Screenshots:", "Console logs:", "Configuration files:", "Test outputs:")
        "Guardrail_Compliance" = @("Local-First:", "Safety:", "Idempotence:", "Verification:")
        "Artifact_Documentation" = @("## 📋 **Artifacts Created", "### **Artifacts Created")
        "Reproducible_Validation" = @("Validation Results", "Runnable checks")
    }
    "Quality" = @{
        "Root_Cause_Analysis" = @("Root Cause Analysis", "Key Findings")
        "Before_After_Comparison" = @("Before/After Comparison", "Before:", "After:")
        "Validation_Results" = @("Validation Results", "All verification steps")
        "Next_Actions" = @("Next Actions", "Immediate", "Short-term", "Long-term")
    }
}

function Test-ECRRCompliance {
    param(
        [string]$FilePath,
        [hashtable]$Requirements
    )
    
    $content = Get-Content -Path $FilePath -Raw
    $results = @{
        "File" = $FilePath
        "Compliance" = @{}
        "Score" = 0
        "Total" = 0
        "Issues" = @()
    }
    
    foreach ($category in $Requirements.Keys) {
        $results.Compliance[$category] = @{}
        $categoryScore = 0
        $categoryTotal = 0
        
        foreach ($requirement in $Requirements[$category].Keys) {
            $categoryTotal++
            $results.Total++
            
            $requirementValue = $Requirements[$category][$requirement]
            $found = $false
            
            if ($requirementValue -is [array]) {
                foreach ($pattern in $requirementValue) {
                    if ($content -match [regex]::Escape($pattern)) {
                        $found = $true
                        break
                    }
                }
            } else {
                $found = $content -match [regex]::Escape($requirementValue)
            }
            
            $results.Compliance[$category][$requirement] = $found
            if ($found) {
                $categoryScore++
                $results.Score++
            } else {
                $results.Issues += "$category - $requirement"
            }
        }
        
        $results.Compliance[$category]["_Score"] = $categoryScore
        $results.Compliance[$category]["_Total"] = $categoryTotal
    }
    
    return $results
}

function Get-ECRRReportFiles {
    param([string]$Path)
    
    $files = @()
    if (Test-Path $Path) {
        $files = Get-ChildItem -Path $Path -Filter "*.md" -Recurse | Where-Object { 
            $_.Name -notlike "*template*" -and 
            $_.Name -notlike "*analysis*" -and
            $_.Name -notlike "*summary*" -and
            $_.Directory.Name -ne "archive"
        }
    }
    return $files
}

function Generate-ComplianceReport {
    param(
        [array]$Results,
        [string]$OutputPath
    )
    
    $report = @{
        "Generated" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "Total_Reports" = $Results.Count
        "Compliance_Summary" = @{
            "Structure" = @{ "Compliant" = 0; "Total" = 0 }
            "Content" = @{ "Compliant" = 0; "Total" = 0 }
            "Quality" = @{ "Compliant" = 0; "Total" = 0 }
        }
        "Overall_Score" = 0
        "Reports" = $Results
    }
    
    foreach ($result in $Results) {
        foreach ($category in $result.Compliance.Keys) {
            if ($category -notlike "_*") {
                $report.Compliance_Summary[$category].Total += $result.Compliance[$category]["_Total"]
                $report.Compliance_Summary[$category].Compliant += $result.Compliance[$category]["_Score"]
            }
        }
        $report.Overall_Score += $result.Score
    }
    
    $report.Overall_Score = [math]::Round(($report.Overall_Score / ($report.Total_Reports * $report.Compliance_Summary.Structure.Total)) * 100, 2)
    
    # Ensure output directory exists
    $outputDir = Split-Path $OutputPath -Parent
    if (!(Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    
    return $report
}

function Show-ComplianceSummary {
    param([hashtable]$Report)
    
    Write-Host "`n🔍 ECRR Compliance Validation Results" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    Write-Host "`n📊 Overall Compliance Score: $($Report.Overall_Score)%" -ForegroundColor $(if ($Report.Overall_Score -ge 80) { "Green" } elseif ($Report.Overall_Score -ge 60) { "Yellow" } else { "Red" })
    
    Write-Host "`n📋 Category Breakdown:" -ForegroundColor White
    foreach ($category in $Report.Compliance_Summary.Keys) {
        $compliant = $Report.Compliance_Summary[$category].Compliant
        $total = $Report.Compliance_Summary[$category].Total
        $percentage = if ($total -gt 0) { [math]::Round(($compliant / $total) * 100, 1) } else { 0 }
        $color = if ($percentage -ge 80) { "Green" } elseif ($percentage -ge 60) { "Yellow" } else { "Red" }
        
        Write-Host "  $category`: $compliant/$total ($percentage%)" -ForegroundColor $color
    }
    
    Write-Host "`n📁 Reports Analyzed: $($Report.Total_Reports)" -ForegroundColor White
    
    # Show top issues
    $allIssues = @()
    foreach ($report in $Report.Reports) {
        $allIssues += $report.Issues
    }
    
    $issueGroups = $allIssues | Group-Object | Sort-Object Count -Descending | Select-Object -First 5
    
    if ($issueGroups.Count -gt 0) {
        Write-Host "`n⚠️  Top Compliance Issues:" -ForegroundColor Yellow
        foreach ($issue in $issueGroups) {
            Write-Host "  $($issue.Name): $($issue.Count) reports" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n📄 Detailed report saved to: $OutputPath" -ForegroundColor Green
}

# Main execution
try {
    Write-Host "🔍 ECRR Compliance Validation Starting..." -ForegroundColor Cyan
    
    # Get all ECRR report files
    $reportFiles = Get-ECRRReportFiles -Path $ReportPath
    
    if ($reportFiles.Count -eq 0) {
        Write-Warning "No ECRR report files found in $ReportPath"
        exit 1
    }
    
    Write-Host "Found $($reportFiles.Count) ECRR report files to validate" -ForegroundColor Green
    
    # Validate each report
    $results = @()
    foreach ($file in $reportFiles) {
        if ($Verbose) {
            Write-Host "Validating: $($file.Name)" -ForegroundColor Gray
        }
        
        $result = Test-ECRRCompliance -FilePath $file.FullName -Requirements $ECRR_REQUIREMENTS
        $results += $result
    }
    
    # Generate compliance report
    $report = Generate-ComplianceReport -Results $results -OutputPath $OutputPath
    
    # Show summary
    Show-ComplianceSummary -Report $report
    
    # Exit with appropriate code
    if ($report.Overall_Score -ge 80) {
        Write-Host "`n✅ ECRR Compliance: EXCELLENT" -ForegroundColor Green
        exit 0
    } elseif ($report.Overall_Score -ge 60) {
        Write-Host "`n⚠️  ECRR Compliance: NEEDS IMPROVEMENT" -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host "`n❌ ECRR Compliance: POOR" -ForegroundColor Red
        exit 2
    }
    
} catch {
    Write-Error "ECRR compliance validation failed: $($_.Exception.Message)"
    exit 3
}
