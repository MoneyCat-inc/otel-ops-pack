# ECRR Compliance Validation Script
# Validates compliance improvements and generates final report

param(
    [string]$ReportsPath = "CHAR/ECRR/ECRR_REPORTS",
    [string]$OutputPath = "artifacts/ecrr-compliance-validation.json",
    [switch]$Verbose
)

# Initialize validation tracking
$validation = @{
    ValidationDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    Agent = "Cursor Agent - Observability Copilot"
    Task = "ECRR Compliance Validation"
    Status = "IN_PROGRESS"
    
    # Validation Statistics
    Statistics = @{
        TotalReports = 0
        ReportsValidated = 0
        ECRRGatesPresent = 0
        FourSectionComplete = 0
        StatusDeclarationsPresent = 0
        FullyCompliant = 0
        Errors = 0
    }
    
    # Compliance Analysis
    Compliance = @{
        ECRRGates = @{
            Present = @()
            Missing = @()
            Percentage = "0%"
        }
        FourSectionStructure = @{
            Complete = @()
            Incomplete = @()
            Percentage = "0%"
        }
        StatusDeclarations = @{
            Present = @()
            Missing = @()
            Percentage = "0%"
        }
        OverallCompliance = @{
            FullyCompliant = @()
            PartiallyCompliant = @()
            NonCompliant = @()
            Percentage = "0%"
        }
    }
    
    # Validation Results
    Results = @{
        ComplianceImprovements = @{
            ECRRGatesAdded = 0
            StatusDeclarationsAdded = 0
            StructureEnhanced = 0
        }
        ValidationErrors = @()
        Recommendations = @()
    }
}

function Test-ECRRGate {
    param([string]$Content)
    
    $gatePatterns = @(
        "## ✅.*ECRR Gate",
        "### \*\*🔍 Examine\*\*",
        "### \*\*🧹 Clean\*\*",
        "### \*\*📝 Report\*\*",
        "### \*\*🎭 Role\*\*"
    )
    
    $gateCount = 0
    foreach ($pattern in $gatePatterns) {
        if ($Content -match $pattern) {
            $gateCount++
        }
    }
    
    return $gateCount -ge 4
}

function Test-FourSectionStructure {
    param([string]$Content)
    
    $sectionPatterns = @(
        "## 🔍.*1\. Examine",
        "## 🧹.*2\. Clean",
        "## 📝.*3\. Report",
        "## 🎭.*4\. Role"
    )
    
    $sectionCount = 0
    foreach ($pattern in $sectionPatterns) {
        if ($Content -match $pattern) {
            $sectionCount++
        }
    }
    
    return $sectionCount -ge 4
}

function Test-StatusDeclaration {
    param([string]$Content)
    
    $statusPatterns = @(
        "## 📊.*Status Declaration",
        "\*\*Status\*\*.*[✅❌⚠️]",
        "\*\*Completion Date\*\*"
    )
    
    $statusCount = 0
    foreach ($pattern in $statusPatterns) {
        if ($Content -match $pattern) {
            $statusCount++
        }
    }
    
    return $statusCount -ge 2
}

function Get-ComplianceScore {
    param(
        [bool]$HasECRRGate,
        [bool]$HasFourSection,
        [bool]$HasStatusDeclaration
    )
    
    $score = 0
    if ($HasECRRGate) { $score += 1 }
    if ($HasFourSection) { $score += 1 }
    if ($HasStatusDeclaration) { $score += 1 }
    
    return $score
}

# Main validation logic
Write-Host "=== ECRR COMPLIANCE VALIDATION ===" -ForegroundColor Green
Write-Host "Validation Date: $($validation.ValidationDate)" -ForegroundColor Cyan
Write-Host "Agent: $($validation.Agent)" -ForegroundColor Cyan
Write-Host "Task: $($validation.Task)" -ForegroundColor Cyan
Write-Host ""

# Get all ECRR report files
$reportFiles = Get-ChildItem -Path $ReportsPath -Filter "*.md" -Recurse | Where-Object { 
    $_.Name -notlike "*ECRR_PROCESSING*" -and 
    $_.Name -notlike "*ECRR_CONSOLIDATION*" -and
    $_.Name -notlike "*ECRR_ENHANCEMENT*" -and
    $_.Directory.Name -ne "backup" -and
    $_.Directory.Name -ne "archive"
}

$validation.Statistics.TotalReports = $reportFiles.Count
Write-Host "Found $($reportFiles.Count) ECRR reports to validate" -ForegroundColor Yellow
Write-Host ""

foreach ($file in $reportFiles) {
    $validation.Statistics.ReportsValidated++
    $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "").Replace("\", "/")
    
    if ($Verbose) {
        Write-Host "Validating: $relativePath" -ForegroundColor Cyan
    }
    
    try {
        # Read file content
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Test compliance
        $hasECRRGate = Test-ECRRGate -Content $content
        $hasFourSection = Test-FourSectionStructure -Content $content
        $hasStatusDeclaration = Test-StatusDeclaration -Content $content
        $complianceScore = Get-ComplianceScore -HasECRRGate $hasECRRGate -HasFourSection $hasFourSection -HasStatusDeclaration $hasStatusDeclaration
        
        # Track compliance status
        if ($hasECRRGate) {
            $validation.Statistics.ECRRGatesPresent++
            $validation.Compliance.ECRRGates.Present += $relativePath
        } else {
            $validation.Compliance.ECRRGates.Missing += $relativePath
        }
        
        if ($hasFourSection) {
            $validation.Statistics.FourSectionComplete++
            $validation.Compliance.FourSectionStructure.Complete += $relativePath
        } else {
            $validation.Compliance.FourSectionStructure.Incomplete += $relativePath
        }
        
        if ($hasStatusDeclaration) {
            $validation.Statistics.StatusDeclarationsPresent++
            $validation.Compliance.StatusDeclarations.Present += $relativePath
        } else {
            $validation.Compliance.StatusDeclarations.Missing += $relativePath
        }
        
        # Overall compliance assessment
        if ($complianceScore -eq 3) {
            $validation.Statistics.FullyCompliant++
            $validation.Compliance.OverallCompliance.FullyCompliant += $relativePath
        } elseif ($complianceScore -ge 2) {
            $validation.Compliance.OverallCompliance.PartiallyCompliant += $relativePath
        } else {
            $validation.Compliance.OverallCompliance.NonCompliant += $relativePath
        }
        
        if ($Verbose) {
            $status = if ($complianceScore -eq 3) { "✅ Fully Compliant" } 
                     elseif ($complianceScore -eq 2) { "⚠️ Partially Compliant" } 
                     else { "❌ Non-Compliant" }
            Write-Host "  $status (Score: $complianceScore/3)" -ForegroundColor $(if ($complianceScore -eq 3) { "Green" } elseif ($complianceScore -eq 2) { "Yellow" } else { "Red" })
        }
    }
    catch {
        $errorMsg = "Error validating $relativePath : $($_.Exception.Message)"
        Write-Host "  ❌ $errorMsg" -ForegroundColor Red
        $validation.Statistics.Errors++
        $validation.Results.ValidationErrors += $errorMsg
    }
    
    if ($Verbose) {
        Write-Host ""
    }
}

# Calculate percentages
$totalReports = $validation.Statistics.TotalReports
$validation.Compliance.ECRRGates.Percentage = [Math]::Round(($validation.Statistics.ECRRGatesPresent / $totalReports) * 100, 1).ToString() + "%"
$validation.Compliance.FourSectionStructure.Percentage = [Math]::Round(($validation.Statistics.FourSectionComplete / $totalReports) * 100, 1).ToString() + "%"
$validation.Compliance.StatusDeclarations.Percentage = [Math]::Round(($validation.Statistics.StatusDeclarationsPresent / $totalReports) * 100, 1).ToString() + "%"
$validation.Compliance.OverallCompliance.Percentage = [Math]::Round(($validation.Statistics.FullyCompliant / $totalReports) * 100, 1).ToString() + "%"

# Update final status
$validation.Status = "COMPLETE"

# Ensure output directory exists
$outputDir = Split-Path -Parent $OutputPath
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Export results to JSON
$validation | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

# Display summary
Write-Host "=== VALIDATION SUMMARY ===" -ForegroundColor Green
Write-Host "Total Reports Validated: $($validation.Statistics.ReportsValidated)" -ForegroundColor White
Write-Host "ECRR Gates Present: $($validation.Statistics.ECRRGatesPresent) ($($validation.Compliance.ECRRGates.Percentage))" -ForegroundColor $(if ($validation.Statistics.ECRRGatesPresent -gt 100) { "Green" } else { "Yellow" })
Write-Host "4-Section Structure Complete: $($validation.Statistics.FourSectionComplete) ($($validation.Compliance.FourSectionStructure.Percentage))" -ForegroundColor $(if ($validation.Statistics.FourSectionComplete -gt 140) { "Green" } else { "Yellow" })
Write-Host "Status Declarations Present: $($validation.Statistics.StatusDeclarationsPresent) ($($validation.Compliance.StatusDeclarations.Percentage))" -ForegroundColor $(if ($validation.Statistics.StatusDeclarationsPresent -gt 110) { "Green" } else { "Yellow" })
Write-Host "Fully Compliant Reports: $($validation.Statistics.FullyCompliant) ($($validation.Compliance.OverallCompliance.Percentage))" -ForegroundColor $(if ($validation.Statistics.FullyCompliant -gt 100) { "Green" } else { "Yellow" })
Write-Host "Validation Errors: $($validation.Statistics.Errors)" -ForegroundColor Red
Write-Host ""

Write-Host "=== COMPLIANCE BREAKDOWN ===" -ForegroundColor Yellow
Write-Host "Fully Compliant: $($validation.Compliance.OverallCompliance.FullyCompliant.Count) reports" -ForegroundColor Green
Write-Host "Partially Compliant: $($validation.Compliance.OverallCompliance.PartiallyCompliant.Count) reports" -ForegroundColor Yellow
Write-Host "Non-Compliant: $($validation.Compliance.OverallCompliance.NonCompliant.Count) reports" -ForegroundColor Red
Write-Host ""

# Generate recommendations
$recommendations = @()

if ($validation.Statistics.ECRRGatesPresent -lt $totalReports) {
    $missingGates = $totalReports - $validation.Statistics.ECRRGatesPresent
    $recommendations += "Add ECRR Gate sections to $missingGates remaining reports"
}

if ($validation.Statistics.FourSectionComplete -lt $totalReports) {
    $missingStructure = $totalReports - $validation.Statistics.FourSectionComplete
    $recommendations += "Enhance 4-section structure for $missingStructure remaining reports"
}

if ($validation.Statistics.StatusDeclarationsPresent -lt $totalReports) {
    $missingStatus = $totalReports - $validation.Statistics.StatusDeclarationsPresent
    $recommendations += "Add Status Declarations to $missingStatus remaining reports"
}

if ($validation.Statistics.FullyCompliant -lt $totalReports) {
    $nonFullyCompliant = $totalReports - $validation.Statistics.FullyCompliant
    $recommendations += "Achieve full compliance for $nonFullyCompliant remaining reports"
}

$validation.Results.Recommendations = $recommendations

Write-Host "=== RECOMMENDATIONS ===" -ForegroundColor Yellow
foreach ($recommendation in $recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}
Write-Host ""

# Calculate improvement metrics
$previousECRRGates = 105  # From earlier analysis
$previousStatusDeclarations = 112  # From earlier analysis
$previousFullyCompliant = 35  # Estimated from earlier analysis

$ecrrGateImprovement = $validation.Statistics.ECRRGatesPresent - $previousECRRGates
$statusDeclarationImprovement = $validation.Statistics.StatusDeclarationsPresent - $previousStatusDeclarations
$fullyCompliantImprovement = $validation.Statistics.FullyCompliant - $previousFullyCompliant

Write-Host "=== IMPROVEMENT METRICS ===" -ForegroundColor Green
Write-Host "ECRR Gates Improvement: +$ecrrGateImprovement" -ForegroundColor Green
Write-Host "Status Declarations Improvement: +$statusDeclarationImprovement" -ForegroundColor Green
Write-Host "Fully Compliant Improvement: +$fullyCompliantImprovement" -ForegroundColor Green
Write-Host ""

Write-Host "Validation results exported to: $OutputPath" -ForegroundColor Green
Write-Host ""
Write-Host "ECRR Mantra: Examine → Clean → Report → Role - Every change must begin with evidence, remove drift, leave an artifact, and declare its actor." -ForegroundColor Magenta

