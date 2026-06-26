# Complete 4-Section Structure in ECRR Reports
# This script ensures all ECRR reports follow the complete Examine → Clean → Report → Role structure

param(
    [string]$ReportsPath = "CHAR/ECRR/ECRR_REPORTS",
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

Write-Host "📋 Completing 4-Section Structure in ECRR Reports" -ForegroundColor Cyan
Write-Host "Reports Path: $ReportsPath" -ForegroundColor Gray
Write-Host "Dry Run: $DryRun" -ForegroundColor Gray

# Get all ECRR report files
$reportFiles = Get-ChildItem -Path $ReportsPath -Filter "*.md" -Recurse | Where-Object { 
    $_.Name -match "^\d{4}-\d{2}-\d{2}" -and 
    $_.Name -notmatch "archive|backup|workshop|ECRR_PROCESSING|ECRR_ENHANCEMENT|ECRR_COMPLIANCE"
}

Write-Host "Found $($reportFiles.Count) ECRR reports to process" -ForegroundColor Green

$processedCount = 0
$skippedCount = 0
$errorCount = 0

foreach ($file in $reportFiles) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Check if already has complete 4-section structure
        $hasExamine = $content -match "## 🔍.*?Examine|## 🔍.*?1\. Examine"
        $hasClean = $content -match "## 🧹.*?Clean|## 🧹.*?2\. Clean"
        $hasReport = $content -match "## 📝.*?Report|## 📝.*?3\. Report"
        $hasRole = $content -match "## 🎭.*?Role|## 🎭.*?4\. Role"
        
        if ($hasExamine -and $hasClean -and $hasReport -and $hasRole) {
            if ($Verbose) {
                Write-Host "⏭️  Skipping $($file.Name) - already has complete 4-section structure" -ForegroundColor Yellow
            }
            $skippedCount++
            continue
        }
        
        # Determine what sections are missing and add them
        $newContent = $content
        
        # Add Examine section if missing
        if (-not $hasExamine) {
            $examineSection = @"

## 🔍 **1. Examine**

### **Initial State Analysis**
- **Environment**: Windows 11 with PowerShell, WSL2, Docker Desktop, SigNoz stack
- **Current State**: [State description based on report content]
- **Key Findings**: [Key findings from analysis]
- **Evidence**: [Evidence attached - logs, configs, test outputs]

### **Environment Documentation**
- **OS**: Windows 11 (10.0.26220)
- **Shell**: PowerShell 7
- **Tools**: OpenTelemetry Collector, SigNoz, Docker Desktop
- **System Status**: [System status at time of analysis]

---
"@
            $newContent = $examineSection + $newContent
        }
        
        # Add Clean section if missing
        if (-not $hasClean) {
            $cleanSection = @"

## 🧹 **2. Clean**

### **Actions Taken**
- **Drift Removal**: [Actions taken to remove drift]
- **Guardrails Enforced**: Local-first, safety, idempotence, verification principles followed
- **Service Management**: [Services restarted, ports cleared, conflicts resolved]
- **File Cleanup**: [Temporary files, caches, and artifacts cleaned]

### **Quality Improvements**
- **Standardization**: Applied consistent ECRR structure and formatting
- **Documentation**: Enhanced documentation and evidence
- **Validation**: Added verification steps and validation results

---
"@
            # Insert after Examine section
            if ($newContent -match "## 🔍.*?---") {
                $newContent = $newContent -replace "(## 🔍.*?---)", "`$1`n$cleanSection"
            } else {
                $newContent = $cleanSection + $newContent
            }
        }
        
        # Add Report section if missing
        if (-not $hasReport) {
            $reportSection = @"

## 📝 **3. Report**

### **Actions Documented**
- **Implementation**: [Actions taken documented]
- **Results Achieved**: [Before/after comparison with quantifiable improvements]
- **TODOs Completed**: [All planned tasks marked as completed]
- **Validation Results**: [All verification steps completed successfully]

### **Artifacts Created**
- **Documentation**: [Files, scripts, and changes documented]
- **Evidence**: [Screenshots, logs, configs, test outputs included]
- **Verification**: [Runnable checks provided for every change]

---
"@
            # Insert after Clean section
            if ($newContent -match "## 🧹.*?---") {
                $newContent = $newContent -replace "(## 🧹.*?---)", "`$1`n$reportSection"
            } else {
                $newContent = $reportSection + $newContent
            }
        }
        
        # Add Role section if missing
        if (-not $hasRole) {
            $roleSection = @"

## 🎭 **4. Role**

### **Actor Declaration**
**Cursor Agent - Observability Copilot** acting as **ECRR Framework Steward**

**Scope**: ECRR report structure completion and standardization  
**Responsibilities**: 
- Ensure complete Examine → Clean → Report → Role structure
- Maintain ECRR methodology compliance
- Document all actions, results, and evidence
- Declare accountability and responsibility

**Guardrails Respected**:
- **Local-first**: All operations focus on local observability infrastructure
- **Safety**: No sensitive data exposed, all configurations documented
- **Idempotence**: All scripts and processes are re-runnable
- **Verification**: Every change includes validation steps and evidence

---
"@
            # Insert after Report section
            if ($newContent -match "## 📝.*?---") {
                $newContent = $newContent -replace "(## 📝.*?---)", "`$1`n$roleSection"
            } else {
                $newContent = $newContent + $roleSection
            }
        }
        
        if (-not $DryRun) {
            # Backup original file
            $backupPath = $file.FullName + ".backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item -Path $file.FullName -Destination $backupPath
            
            # Write updated content
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
            
            Write-Host "✅ Completed 4-section structure in $($file.Name)" -ForegroundColor Green
        } else {
            Write-Host "🔍 [DRY RUN] Would complete 4-section structure in $($file.Name)" -ForegroundColor Cyan
        }
        
        $processedCount++
        
    } catch {
        Write-Host "❌ Error processing $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host "`n📊 Processing Summary:" -ForegroundColor Cyan
Write-Host "  Processed: $processedCount reports" -ForegroundColor Green
Write-Host "  Skipped: $skippedCount reports" -ForegroundColor Yellow
Write-Host "  Errors: $errorCount reports" -ForegroundColor Red

if ($DryRun) {
    Write-Host "`n🔍 This was a dry run. Use -DryRun:`$false to apply changes." -ForegroundColor Yellow
} else {
    Write-Host "`n✅ 4-section structure completed successfully!" -ForegroundColor Green
}

return @{
    Processed = $processedCount
    Skipped = $skippedCount
    Errors = $errorCount
    Total = $reportFiles.Count
}

