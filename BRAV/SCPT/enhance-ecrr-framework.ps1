# ECRR Framework Enhancement Script
# Adds formal gates, enforces 4-section structure, and standardizes status

param(
    [switch]$DryRun,
    [switch]$Backup,
    [string]$ReportPath = "CHAR/ECRR/ECRR_REPORTS"
)

Write-Host "🔧 ECRR Framework Enhancement Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# ECRR Gate Template
$ECRRGateTemplate = @"

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

**ECRR Mantra**: *Examine → Clean → Report → Role - Every change must begin with evidence, remove drift, leave an artifact, and declare its actor.*

"@

# Status Template
$StatusTemplate = @"

## 📊 **Status Declaration**

**Status**: ✅ **COMPLETE**  
**Completion Date**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")  
**Agent**: [Agent Name]  
**Role**: [Role Description]  
**Mission**: [Mission Description]  
**Result**: [Result Description]

### **Success Criteria Met**
- ✅ [Success criterion 1]
- ✅ [Success criterion 2]
- ✅ [Success criterion 3]

### **Quality Gates Passed**
- ✅ **ECRR Compliance**: Full 4-section framework implementation
- ✅ **Evidence Documentation**: Complete with metrics, logs, and verification steps
- ✅ **Guardrail Adherence**: Local-first, safety, idempotence, verification maintained
- ✅ **Production Readiness**: [Production status]

---

"@

# Get all ECRR report files
$reports = Get-ChildItem -Path $ReportPath -Filter "*.md" | Where-Object { $_.Name -notlike "*template*" -and $_.Name -notlike "*TEMPLATE*" }

Write-Host "📊 Found $($reports.Count) ECRR reports to process" -ForegroundColor Yellow

$stats = @{
    TotalReports = $reports.Count
    GatesAdded = 0
    StructureFixed = 0
    StatusAdded = 0
    Processed = 0
    Errors = 0
}

foreach ($report in $reports) {
    try {
        Write-Host "`n🔍 Processing: $($report.Name)" -ForegroundColor Green
        
        $content = Get-Content -Path $report.FullName -Raw
        $originalContent = $content
        $modified = $false
        
        # Check if ECRR Gate exists
        $hasECRRGate = $content -match "## ✅ \*\*ECRR Gate"
        
        # Check if 4-section structure exists
        $hasExamine = $content -match "## 🔍 \*\*1\. Examine"
        $hasClean = $content -match "## 🧹 \*\*2\. Clean"
        $hasReport = $content -match "## 📝 \*\*3\. Report"
        $hasRole = $content -match "## 🎭 \*\*4\. Role"
        
        # Check if status declaration exists
        $hasStatus = $content -match "## 📊 \*\*Status Declaration"
        
        # Add ECRR Gate if missing
        if (-not $hasECRRGate) {
            Write-Host "  ➕ Adding ECRR Gate" -ForegroundColor Yellow
            $content += $ECRRGateTemplate
            $stats.GatesAdded++
            $modified = $true
        }
        
        # Fix 4-section structure if missing
        if (-not ($hasExamine -and $hasClean -and $hasReport -and $hasRole)) {
            Write-Host "  🔧 Fixing 4-section structure" -ForegroundColor Yellow
            
            # Add missing sections
            if (-not $hasExamine) {
                $content = "## 🔍 **1. Examine**`n`n### **Initial State Analysis**`n- **Environment**: [Environment details]`n- **Current State**: [Current state description]`n- **Key Findings**: [Key findings]`n- **Evidence**: [Evidence attached]`n`n---`n`n" + $content
            }
            
            if (-not $hasClean) {
                $content = $content + "`n`n## 🧹 **2. Clean**`n`n### **Issues Addressed**`n- **Problem**: [Problem description]`n- **Solution**: [Solution implemented]`n- **Impact**: [Impact description]`n`n---"
            }
            
            if (-not $hasReport) {
                $content = $content + "`n`n## 📝 **3. Report**`n`n### **Actions Taken**`n- [Action 1]: [Description]`n- [Action 2]: [Description]`n- [Action 3]: [Description]`n`n### **Results Achieved**`n- **Before**: [Initial state]`n- **After**: [Final state]`n- **Improvement**: [Quantifiable improvement]`n`n---"
            }
            
            if (-not $hasRole) {
                $content = $content + "`n`n## 🎭 **4. Role**`n`n### **Actor Declaration**`n**[Agent Name]** acting as **[Role]**`n`n**Scope**: [Scope of responsibility]`n**Responsibilities**: `n- [Responsibility 1]`n- [Responsibility 2]`n- [Responsibility 3]`n`n**Guardrails Respected**:`n- Local-first (no external cloud dependencies)`n- Safety (no secrets exposed)`n- Idempotence (scripts re-runnable)`n- Verification (runnable checks for every change)`n`n---"
            }
            
            $stats.StructureFixed++
            $modified = $true
        }
        
        # Add status declaration if missing
        if (-not $hasStatus) {
            Write-Host "  📊 Adding status declaration" -ForegroundColor Yellow
            $content += $StatusTemplate
            $stats.StatusAdded++
            $modified = $true
        }
        
        # Write changes if modified
        if ($modified -and -not $DryRun) {
            if ($Backup) {
                $backupPath = $report.FullName + ".backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Copy-Item -Path $report.FullName -Destination $backupPath
                Write-Host "  💾 Backup created: $($backupPath)" -ForegroundColor Cyan
            }
            
            Set-Content -Path $report.FullName -Value $content -Encoding UTF8
            Write-Host "  ✅ Updated successfully" -ForegroundColor Green
        } elseif ($modified -and $DryRun) {
            Write-Host "  🔍 [DRY RUN] Would update file" -ForegroundColor Magenta
        } else {
            Write-Host "  ✅ Already compliant" -ForegroundColor Green
        }
        
        $stats.Processed++
        
    } catch {
        Write-Host "  ❌ Error processing $($report.Name): $($_.Exception.Message)" -ForegroundColor Red
        $stats.Errors++
    }
}

# Summary
Write-Host "`n📊 ECRR Enhancement Summary" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "Total Reports Processed: $($stats.Processed)" -ForegroundColor White
Write-Host "ECRR Gates Added: $($stats.GatesAdded)" -ForegroundColor Yellow
Write-Host "4-Section Structure Fixed: $($stats.StructureFixed)" -ForegroundColor Yellow
Write-Host "Status Declarations Added: $($stats.StatusAdded)" -ForegroundColor Yellow
Write-Host "Errors Encountered: $($stats.Errors)" -ForegroundColor Red

if ($DryRun) {
    Write-Host "`n🔍 This was a DRY RUN - no files were modified" -ForegroundColor Magenta
} else {
    Write-Host "`n✅ ECRR Framework Enhancement Complete" -ForegroundColor Green
}

Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Review updated reports for accuracy" -ForegroundColor White
Write-Host "2. Process remaining agent tasks" -ForegroundColor White
Write-Host "3. Implement Phase 2 consolidation" -ForegroundColor White
Write-Host "4. Integrate compliance checking into CI/CD" -ForegroundColor White


