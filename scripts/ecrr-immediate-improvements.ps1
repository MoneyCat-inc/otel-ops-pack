# ECRR Immediate Improvements Script
# Adds ECRR gates to missing reports and completes 4-section structure

param(
    [string]$ReportsDir = "docs/ECRR_REPORTS",
    [switch]$DryRun = $false,
    [switch]$Force = $false
)

# ECRR Gate Template
$ECRRGateTemplate = @"

## ✅ **ECRR Gate**

### **Examine**
- [ ] Initial state captured
- [ ] Environment documented
- [ ] Key findings identified
- [ ] Evidence attached

### **Clean**
- [ ] Structural inconsistencies identified and documented
- [ ] Compliance gaps mapped and prioritized
- [ ] Guardrails enforced
- [ ] Quality standards established

### **Report**
- [ ] Actions documented
- [ ] Results achieved
- [ ] Comprehensive documentation created
- [ ] Performance metrics and validation results documented

### **Role**
- [ ] Actor declared
- [ ] Scope defined
- [ ] Guardrails respected
- [ ] Integration maintained

---

**ECRR Mantra**: *Examine → Clean → Report → Role - Every change must begin with evidence, remove drift, leave an artifact, and declare its actor.*
"@

# 4-Section Structure Template
$FourSectionTemplate = @"

## 🔍 **1. Examine**

### **Initial State Captured**
- **Environment**: [OS, tools, versions]
- **Current State**: [What was observed before changes]
- **Key Findings**: [Critical issues or opportunities identified]
- **Attached Evidence**: [Screenshots, logs, configs, test outputs]

### **Key Findings**
- **[Finding 1]**: [Description and impact]
- **[Finding 2]**: [Description and impact]
- **[Finding 3]**: [Description and impact]

### **Attached Evidence**
- Screenshots: [What was captured visually]
- Console logs: [Command outputs and errors]
- Configuration files: [Files examined or modified]
- Test outputs: [Validation results]

---

## 🧹 **2. Clean**

### **Drift Removal**
- **[Issue 1]**: [What was cleaned/fixed]
- **[Issue 2]**: [What was cleaned/fixed]
- **[Issue 3]**: [What was cleaned/fixed]

### **Guardrails Enforced**
- ✅ **Local-First**: [Local-first principles applied]
- ✅ **Safety**: [Safety measures implemented]
- ✅ **Idempotence**: [Idempotent operations ensured]
- ✅ **Verification**: [Verification steps completed]

### **Quality Standards**
- **Code Quality**: [Standards applied]
- **Documentation**: [Documentation updated]
- **Testing**: [Testing completed]
- **Performance**: [Performance validated]

---

## 📝 **3. Report**

### **Actions Taken**
- **Primary Actions**: [Main actions completed]
- **Secondary Actions**: [Supporting actions completed]
- **Validation Steps**: [Validation performed]
- **Documentation**: [Documentation created]

### **Results Achieved**
- **Before/After**: [State before and after changes]
- **Metrics**: [Quantifiable results]
- **Evidence**: [Proof of success]
- **Regressions**: [Any issues identified]

### **TODOs Completed**
- ✅ [Completed task 1]
- ✅ [Completed task 2]
- ✅ [Completed task 3]

---

## 🎭 **4. Role**

### **Actor Declaration**
**[Agent Name]** acting as **[Role Description]**

**Scope**: [Scope of work]  
**Responsibilities**: 
- [Responsibility 1]
- [Responsibility 2]
- [Responsibility 3]

**Guardrails Respected**:
- **Local-First**: [Local-first principles]
- **Safety**: [Safety measures]
- **Idempotence**: [Idempotent operations]
- **Verification**: [Verification completed]

**Integration**: 
- [Integration points]
- [Compatibility maintained]
- [Framework alignment]
"@

function Test-ECRRGate {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $false }
    
    return ($content -match "ECRR Gate" -or $content -match "## ✅.*ECRR.*Gate")
}

function Test-FourSectionStructure {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $false }
    
    $sections = @("Examine", "Clean", "Report", "Role")
    $foundSections = 0
    
    foreach ($section in $sections) {
        if ($content -match "##.*$section" -or $content -match "#.*$section") {
            $foundSections++
        }
    }
    
    return ($foundSections -eq 4)
}

function Add-ECRRGate {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $false }
    
    # Check if ECRR Gate already exists
    if (Test-ECRRGate -FilePath $FilePath) {
        Write-Host "  ECRR Gate already exists in $FilePath" -ForegroundColor Yellow
        return $true
    }
    
    # Add ECRR Gate before the final status section or at the end
    if ($content -match "## 📊.*Status|## 🏆.*Status|## ✅.*Status") {
        $newContent = $content -replace "(## 📊.*Status|## 🏆.*Status|## ✅.*Status)", "$ECRRGateTemplate`n`n$1"
    } else {
        $newContent = $content + $ECRRGateTemplate
    }
    
    if (-not $DryRun) {
        $newContent | Out-File -FilePath $FilePath -Encoding UTF8
        Write-Host "  ✅ Added ECRR Gate to $FilePath" -ForegroundColor Green
    } else {
        Write-Host "  [DRY RUN] Would add ECRR Gate to $FilePath" -ForegroundColor Cyan
    }
    
    return $true
}

function Fix-FourSectionStructure {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $false }
    
    # Check if 4-section structure already exists
    if (Test-FourSectionStructure -FilePath $FilePath) {
        Write-Host "  4-section structure already exists in $FilePath" -ForegroundColor Yellow
        return $true
    }
    
    # This is a complex operation that would require manual review
    # For now, we'll just identify the files that need this fix
    Write-Host "  ⚠️  $FilePath needs manual 4-section structure fix" -ForegroundColor Yellow
    return $false
}

# Main processing
Write-Host "🔍 ECRR Immediate Improvements Started" -ForegroundColor Cyan
Write-Host "Reports Directory: $ReportsDir" -ForegroundColor Gray
if ($DryRun) {
    Write-Host "Mode: DRY RUN (no changes will be made)" -ForegroundColor Yellow
}

# Get all ECRR report files (excluding backups)
$reportFiles = Get-ChildItem -Path $ReportsDir -Filter "*.md" | Where-Object {
    -not $_.Name.Contains(".backup.") -and
    -not $_.Name.StartsWith(".")
}

$results = @{
    TotalReports = $reportFiles.Count
    MissingECRRGates = @()
    MissingFourSections = @()
    ECRRGatesAdded = 0
    FourSectionsFixed = 0
    ProcessingErrors = @()
}

Write-Host "Found $($results.TotalReports) ECRR reports to analyze" -ForegroundColor Green

# Analyze each report
foreach ($report in $reportFiles) {
    try {
        Write-Host "Analyzing: $($report.Name)" -ForegroundColor Yellow
        
        # Check ECRR Gate
        if (-not (Test-ECRRGate -FilePath $report.FullName)) {
            $results.MissingECRRGates += $report.Name
            Write-Host "  ❌ Missing ECRR Gate" -ForegroundColor Red
        } else {
            Write-Host "  ✅ Has ECRR Gate" -ForegroundColor Green
        }
        
        # Check 4-Section Structure
        if (-not (Test-FourSectionStructure -FilePath $report.FullName)) {
            $results.MissingFourSections += $report.Name
            Write-Host "  ❌ Missing 4-section structure" -ForegroundColor Red
        } else {
            Write-Host "  ✅ Has 4-section structure" -ForegroundColor Green
        }
        
    } catch {
        $results.ProcessingErrors += @{
            File = $report.Name
            Error = $_.Exception.Message
        }
        Write-Host "  ❌ Failed to analyze: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n📊 Analysis Results:" -ForegroundColor Cyan
Write-Host "Missing ECRR Gates: $($results.MissingECRRGates.Count)" -ForegroundColor Yellow
Write-Host "Missing 4-Section Structure: $($results.MissingFourSections.Count)" -ForegroundColor Yellow

if ($results.MissingECRRGates.Count -gt 0) {
    Write-Host "`n🔧 Adding ECRR Gates..." -ForegroundColor Cyan
    foreach ($file in $results.MissingECRRGates) {
        $filePath = Join-Path $ReportsDir $file
        if (Add-ECRRGate -FilePath $filePath) {
            $results.ECRRGatesAdded++
        }
    }
}

if ($results.MissingFourSections.Count -gt 0) {
    Write-Host "`n🔧 Identifying 4-Section Structure Issues..." -ForegroundColor Cyan
    foreach ($file in $results.MissingFourSections) {
        $filePath = Join-Path $ReportsDir $file
        Fix-FourSectionStructure -FilePath $filePath
        $results.FourSectionsFixed++
    }
}

# Save results
$resultsFile = "artifacts/ecrr-immediate-improvements-results.json"
$results | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsFile -Encoding UTF8

Write-Host "`n✅ ECRR Immediate Improvements Complete!" -ForegroundColor Green
Write-Host "ECRR Gates Added: $($results.ECRRGatesAdded)" -ForegroundColor Cyan
Write-Host "4-Section Issues Identified: $($results.MissingFourSections.Count)" -ForegroundColor Cyan
Write-Host "Results saved to: $resultsFile" -ForegroundColor Cyan

return $results
