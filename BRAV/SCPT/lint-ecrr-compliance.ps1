# ECRR Compliance Lint Script for CI/CD
# This script validates ECRR reports against compliance requirements
# and fails CI if any report is missing required patterns

param(
    [string]$ReportPath = "docs/ECRR_REPORTS",
    [switch]$FailOnError = $true,
    [switch]$Verbose = $false
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
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $false
    }
    
    $content = Get-Content $FilePath -Raw
    $issues = @()
    $score = 0
    $total = 0
    
    foreach ($category in $ECRR_REQUIREMENTS.Keys) {
        $categoryScore = 0
        $categoryTotal = 0
        
        foreach ($requirement in $ECRR_REQUIREMENTS[$category].Keys) {
            $patterns = $ECRR_REQUIREMENTS[$category][$requirement]
            $categoryTotal++
            $total++
            
            $found = $false
            foreach ($pattern in $patterns) {
                if ($content -match [regex]::Escape($pattern)) {
                    $found = $true
                    break
                }
            }
            
            if ($found) {
                $categoryScore++
                $score++
            } else {
                $issues += "$category - $requirement"
            }
        }
        
        if ($Verbose) {
            Write-Host "  $category`: $categoryScore/$categoryTotal" -ForegroundColor $(if ($categoryScore -eq $categoryTotal) { "Green" } else { "Yellow" })
        }
    }
    
    return @{
        File = $FilePath
        Score = $score
        Total = $total
        Issues = $issues
        Passed = $issues.Count -eq 0
    }
}

function Write-ComplianceReport {
    param(
        [array]$Results
    )
    
    $totalReports = $Results.Count
    $passedReports = ($Results | Where-Object { $_.Passed }).Count
    $failedReports = $totalReports - $passedReports
    
    Write-Host "`n📋 ECRR Compliance Lint Report" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "Total Reports: $totalReports" -ForegroundColor White
    Write-Host "Passed: $passedReports" -ForegroundColor Green
    Write-Host "Failed: $failedReports" -ForegroundColor Red
    
    if ($failedReports -gt 0) {
        Write-Host "`n❌ Failed Reports:" -ForegroundColor Red
        foreach ($result in $Results | Where-Object { -not $_.Passed }) {
            Write-Host "  $(Split-Path $result.File -Leaf): $($result.Score)/$($result.Total)" -ForegroundColor Red
            foreach ($issue in $result.Issues) {
                Write-Host "    - $issue" -ForegroundColor Yellow
            }
        }
    }
    
    if ($passedReports -gt 0) {
        Write-Host "`n✅ Passed Reports:" -ForegroundColor Green
        foreach ($result in $Results | Where-Object { $_.Passed }) {
            Write-Host "  $(Split-Path $result.File -Leaf): $($result.Score)/$($result.Total)" -ForegroundColor Green
        }
    }
    
    $overallScore = if ($totalReports -gt 0) { [math]::Round(($passedReports / $totalReports) * 100, 2) } else { 0 }
    Write-Host "`nOverall Compliance: $overallScore%" -ForegroundColor $(if ($overallScore -ge 80) { "Green" } else { "Red" })
    
    return $overallScore
}

# Main execution
Write-Host "🔍 ECRR Compliance Lint Check" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Find all ECRR reports
$reportFiles = Get-ChildItem -Path $ReportPath -Filter "*.md" -File | Where-Object { $_.Name -match "ecrr" -or $_.Name -match "ECRR" }

if ($reportFiles.Count -eq 0) {
    Write-Warning "No ECRR reports found in $ReportPath"
    exit 0
}

Write-Host "Found $($reportFiles.Count) ECRR reports to validate..." -ForegroundColor White

# Validate each report
$results = @()
foreach ($file in $reportFiles) {
    if ($Verbose) {
        Write-Host "`nValidating: $($file.Name)" -ForegroundColor Cyan
    }
    
    $result = Test-ECRRCompliance -FilePath $file.FullName
    $results += $result
    
    if ($Verbose) {
        Write-Host "  Score: $($result.Score)/$($result.Total)" -ForegroundColor $(if ($result.Passed) { "Green" } else { "Red" })
        if ($result.Issues.Count -gt 0) {
            Write-Host "  Issues: $($result.Issues.Count)" -ForegroundColor Yellow
        }
    }
}

# Generate compliance report
$overallScore = Write-ComplianceReport -Results $results

# Determine exit code
if ($FailOnError -and $overallScore -lt 80) {
    Write-Host "`n❌ CI FAILED: Overall compliance below 80% threshold" -ForegroundColor Red
    exit 1
} elseif ($overallScore -lt 80) {
    Write-Host "`n⚠️ WARNING: Overall compliance below 80% threshold" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n✅ CI PASSED: All ECRR reports meet compliance requirements" -ForegroundColor Green
    exit 0
}
