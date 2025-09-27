# Add ECRR Gates to Missing Reports
# Automatically adds ECRR Gate sections to reports that are missing them

param(
    [string]$ReportPath = "docs/ECRR_REPORTS",
    [string]$OutputPath = "artifacts/ecrr-gate-addition-report.json",
    [switch]$DryRun,
    [switch]$Verbose
)

# ECRR Gate Template
$ECRR_GATE_TEMPLATE = @"

## ✅ **ECRR Gate - MANDATORY VALIDATION**

> **⚠️ CRITICAL**: This section is MANDATORY for all ECRR reports. All checkboxes must be completed for report compliance.

### **🔍 Examine**
- [ ] **Initial State Captured**: Environment state documented before changes
- [ ] **Environment Documented**: OS, tools, versions, and system status recorded
- [ ] **Key Findings Identified**: Critical issues or opportunities documented
- [ ] **Evidence Attached**: Screenshots, logs, configs, test outputs included
- [ ] **Root Cause Analysis**: Underlying causes identified and documented

### **🧹 Clean**
- [ ] **Drift Removed**: All identified issues addressed and resolved
- [ ] **Guardrails Enforced**: Local-first, safety, idempotence, verification principles followed
- [ ] **Service Management**: Services restarted, ports cleared, conflicts resolved
- [ ] **File Cleanup**: Temporary files, caches, and artifacts cleaned
- [ ] **Process Management**: Background processes and conflicts resolved

### **📝 Report**
- [ ] **Actions Documented**: All actions taken clearly described
- [ ] **Results Achieved**: Before/after comparison with quantifiable improvements
- [ ] **TODOs Completed**: All planned tasks marked as completed
- [ ] **Comprehensive Documentation**: All changes and artifacts documented
- [ ] **Validation Results**: All verification steps completed successfully

### **🎭 Role**
- [ ] **Actor Declared**: Agent name and role clearly stated in header and Role section
- [ ] **Scope Defined**: Clear boundaries of responsibility established
- [ ] **Guardrails Respected**: All ECRR principles followed throughout
- [ ] **Integration Maintained**: Compatibility with existing systems preserved
- [ ] **Accountability Established**: Clear ownership and responsibility declared

### **📊 Quality Assurance**
- [ ] **4-Section Structure**: Complete Examine → Clean → Report → Role format followed
- [ ] **Status Declaration**: Clear success/failure/completion status specified
- [ ] **Artifact Documentation**: All files, scripts, and changes documented
- [ ] **Reproducible Validation**: Runnable checks provided for every change
- [ ] **ECRR Compliance**: All mandatory elements included and validated
- [ ] **Template Adherence**: Report follows enhanced ECRR template structure
- [ ] **Evidence Quality**: All evidence is relevant, clear, and properly documented
- [ ] **Action Clarity**: All actions taken are clearly described and justified

---
"@

function Test-ReportHasECRRGate {
    param([string]$FilePath)
    
    $content = Get-Content -Path $FilePath -Raw
    return $content -match "## ✅ \*\*ECRR Gate"
}

function Add-ECRRGateToReport {
    param(
        [string]$FilePath,
        [string]$GateTemplate,
        [bool]$DryRun
    )
    
    $content = Get-Content -Path $FilePath -Raw
    $fileName = Split-Path $FilePath -Leaf
    
    # Check if ECRR Gate already exists
    if (Test-ReportHasECRRGate -FilePath $FilePath) {
        return @{
            "File" = $fileName
            "Status" = "Already has ECRR Gate"
            "Action" = "Skipped"
        }
    }
    
    # Find insertion point - before the final status or at the end
    $insertionPoint = $content.Length
    
    # Look for common ending patterns
    $endPatterns = @(
        "## 🏆 \*\*Final Status",
        "## 🎉 \*\*Mission Accomplished",
        "## 📋 \*\*Artifacts Created",
        "## 🔄 \*\*Next Actions",
        "---\s*$",
        "\*\*ECRR Mantra\*\*"
    )
    
    foreach ($pattern in $endPatterns) {
        $match = [regex]::Match($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
        if ($match.Success) {
            $insertionPoint = $match.Index
            break
        }
    }
    
    # Insert ECRR Gate
    $newContent = $content.Insert($insertionPoint, $GateTemplate)
    
    if (-not $DryRun) {
        # Backup original file
        $backupPath = $FilePath + ".backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -Path $FilePath -Destination $backupPath
        
        # Write updated content
        $newContent | Out-File -FilePath $FilePath -Encoding UTF8
    }
    
    return @{
        "File" = $fileName
        "Status" = if ($DryRun) { "Would add ECRR Gate" } else { "ECRR Gate added" }
        "Action" = if ($DryRun) { "Dry run" } else { "Modified" }
        "Backup" = if (-not $DryRun) { Split-Path $backupPath -Leaf } else { $null }
    }
}

function Get-ReportsMissingECRRGates {
    param([string]$ReportPath)
    
    # Get compliance report
    $complianceReport = Get-Content "artifacts/ecrr-compliance-report.json" | ConvertFrom-Json
    
    $missingGates = @()
    foreach ($report in $complianceReport.Reports) {
        if ($report.Compliance.Structure.ECRR_Gate -eq $false) {
            $fileName = Split-Path $report.File -Leaf
            $filePath = Join-Path $ReportPath $fileName
            if (Test-Path $filePath) {
                $missingGates += $filePath
            }
        }
    }
    
    return $missingGates
}

# Main execution
try {
    Write-Host "🔍 ECRR Gate Addition Starting..." -ForegroundColor Cyan
    
    # Get reports missing ECRR gates
    $reportsToUpdate = Get-ReportsMissingECRRGates -ReportPath $ReportPath
    
    if ($reportsToUpdate.Count -eq 0) {
        Write-Host "✅ All reports already have ECRR Gates" -ForegroundColor Green
        exit 0
    }
    
    Write-Host "Found $($reportsToUpdate.Count) reports missing ECRR Gates" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "🔍 DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
    }
    
    $results = @()
    $processed = 0
    
    foreach ($reportPath in $reportsToUpdate) {
        $processed++
        $fileName = Split-Path $reportPath -Leaf
        
        if ($Verbose) {
            Write-Host "[$processed/$($reportsToUpdate.Count)] Processing: $fileName" -ForegroundColor Gray
        }
        
        $result = Add-ECRRGateToReport -FilePath $reportPath -GateTemplate $ECRR_GATE_TEMPLATE -DryRun $DryRun
        $results += $result
        
        if (-not $DryRun) {
            Write-Host "✅ Added ECRR Gate to: $fileName" -ForegroundColor Green
        } else {
            Write-Host "🔍 Would add ECRR Gate to: $fileName" -ForegroundColor Yellow
        }
    }
    
    # Generate report
    $report = @{
        "Generated" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "Mode" = if ($DryRun) { "Dry Run" } else { "Live Update" }
        "Total_Reports" = $reportsToUpdate.Count
        "Processed" = $processed
        "Results" = $results
        "Summary" = @{
            "Added" = ($results | Where-Object { $_.Status -like "*added*" }).Count
            "Skipped" = ($results | Where-Object { $_.Status -like "*Already*" }).Count
            "Errors" = ($results | Where-Object { $_.Status -like "*Error*" }).Count
        }
    }
    
    # Ensure output directory exists
    $outputDir = Split-Path $OutputPath -Parent
    if (!(Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    
    # Show summary
    Write-Host "`n📊 ECRR Gate Addition Summary" -ForegroundColor Cyan
    Write-Host "=" * 40 -ForegroundColor Cyan
    Write-Host "Total Reports: $($reportsToUpdate.Count)" -ForegroundColor White
    Write-Host "Processed: $processed" -ForegroundColor White
    Write-Host "Added: $($report.Summary.Added)" -ForegroundColor Green
    Write-Host "Skipped: $($report.Summary.Skipped)" -ForegroundColor Yellow
    Write-Host "Errors: $($report.Summary.Errors)" -ForegroundColor Red
    
    Write-Host "`n📄 Detailed report saved to: $OutputPath" -ForegroundColor Green
    
    if ($DryRun) {
        Write-Host "`n🔍 This was a dry run. Use without -DryRun to apply changes." -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host "`n✅ ECRR Gates added successfully!" -ForegroundColor Green
        exit 0
    }
    
} catch {
    Write-Error "ECRR Gate addition failed: $($_.Exception.Message)"
    exit 3
}
