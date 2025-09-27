# Enforce 4-Section Structure in ECRR Reports
# Ensures all reports follow the Examine → Clean → Report → Role structure

param(
    [string]$ReportPath = "docs/ECRR_REPORTS",
    [string]$OutputPath = "artifacts/ecrr-structure-enforcement-report.json",
    [switch]$DryRun,
    [switch]$Verbose
)

# 4-Section Structure Requirements
$SECTION_STRUCTURE = @{
    "Examine" = @{
        "Pattern" = "## 🔍 \*\*1\. Examine"
        "Alternative" = @("## 🔍 \*\*Examine", "## 1\. Examine", "## Examine")
        "Required" = $true
    }
    "Clean" = @{
        "Pattern" = "## 🧹 \*\*2\. Clean"
        "Alternative" = @("## 🧹 \*\*Clean", "## 2\. Clean", "## Clean")
        "Required" = $true
    }
    "Report" = @{
        "Pattern" = "## 📝 \*\*3\. Report"
        "Alternative" = @("## 📝 \*\*Report", "## 3\. Report", "## Report")
        "Required" = $true
    }
    "Role" = @{
        "Pattern" = "## 🎭 \*\*4\. Role"
        "Alternative" = @("## 🎭 \*\*Role", "## 4\. Role", "## Role")
        "Required" = $true
    }
}

function Test-ReportHas4SectionStructure {
    param([string]$FilePath)
    
    $content = Get-Content -Path $FilePath -Raw
    $fileName = Split-Path $FilePath -Leaf
    
    $results = @{
        "File" = $fileName
        "HasExamine" = $false
        "HasClean" = $false
        "HasReport" = $false
        "HasRole" = $false
        "IsCompliant" = $false
        "MissingSections" = @()
        "Issues" = @()
    }
    
    # Check for each required section
    foreach ($sectionName in $SECTION_STRUCTURE.Keys) {
        $section = $SECTION_STRUCTURE[$sectionName]
        $found = $false
        
        # Check primary pattern
        if ($content -match [regex]::Escape($section.Pattern)) {
            $found = $true
        } else {
            # Check alternative patterns
            foreach ($altPattern in $section.Alternative) {
                if ($content -match [regex]::Escape($altPattern)) {
                    $found = $true
                    $results.Issues += "Uses alternative pattern for $sectionName`: $altPattern"
                    break
                }
            }
        }
        
        $results["Has$sectionName"] = $found
        
        if (-not $found) {
            $results.MissingSections += $sectionName
        }
    }
    
    # Determine overall compliance
    $results.IsCompliant = $results.HasExamine -and $results.HasClean -and $results.HasReport -and $results.HasRole
    
    return $results
}

function Fix-Report4SectionStructure {
    param(
        [string]$FilePath,
        [hashtable]$StructureResults,
        [bool]$DryRun
    )
    
    $fileName = Split-Path $FilePath -Leaf
    
    if ($StructureResults.IsCompliant) {
        return @{
            "File" = $fileName
            "Status" = "Already compliant"
            "Action" = "Skipped"
        }
    }
    
    $content = Get-Content -Path $FilePath -Raw
    $originalContent = $content
    
    # Fix missing sections
    foreach ($missingSection in $StructureResults.MissingSections) {
        $section = $SECTION_STRUCTURE[$missingSection]
        $sectionHeader = $section.Pattern -replace "\\", ""
        
        # Create section content based on missing section
        $sectionContent = Get-SectionTemplate -SectionName $missingSection
        
        # Find insertion point
        $insertionPoint = Find-InsertionPoint -Content $content -SectionName $missingSection
        
        # Insert section
        $content = $content.Insert($insertionPoint, $sectionContent)
    }
    
    # Fix alternative patterns
    foreach ($issue in $StructureResults.Issues) {
        if ($issue -match "Uses alternative pattern for (\w+): (.+)") {
            $sectionName = $matches[1]
            $oldPattern = $matches[2]
            $newPattern = $SECTION_STRUCTURE[$sectionName].Pattern -replace "\\", ""
            
            $content = $content -replace [regex]::Escape($oldPattern), $newPattern
        }
    }
    
    if (-not $DryRun) {
        # Backup original file
        $backupPath = $FilePath + ".backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -Path $FilePath -Destination $backupPath
        
        # Write updated content
        $content | Out-File -FilePath $FilePath -Encoding UTF8
    }
    
    return @{
        "File" = $fileName
        "Status" = if ($DryRun) { "Would fix structure" } else { "Structure fixed" }
        "Action" = if ($DryRun) { "Dry run" } else { "Modified" }
        "MissingSections" = $StructureResults.MissingSections
        "Issues" = $StructureResults.Issues
        "Backup" = if (-not $DryRun) { Split-Path $backupPath -Leaf } else { $null }
    }
}

function Get-SectionTemplate {
    param([string]$SectionName)
    
    $templates = @{
        "Examine" = @"

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
"@
        "Clean" = @"

## 🧹 **2. Clean**

### **Drift Removal**
- **[Issue 1]**: [What was cleaned/fixed]
- **[Issue 2]**: [What was cleaned/fixed]
- **[Issue 3]**: [What was cleaned/fixed]

### **Guardrail Enforcement**
- **Local-First**: [How local-first principle was maintained]
- **Safety**: [Security measures implemented]
- **Idempotence**: [How changes can be safely re-run]
- **Verification**: [How changes were verified]

### **Service Worker & Cache Management**
- **Git Branches**: [Branch cleanup actions]
- **Temporary Files**: [File cleanup performed]
- **Port Conflicts**: [Port management actions]
- **Process Management**: [Background process cleanup]

---
"@
        "Report" = @"

## 📝 **3. Report**

### **Actions Taken**

#### **[Category 1]**
1. **[Action 1]**: [Description]
2. **[Action 2]**: [Description]
3. **[Action 3]**: [Description]

#### **[Category 2]**
1. **[Action 1]**: [Description]
2. **[Action 2]**: [Description]
3. **[Action 3]**: [Description]

### **Results Achieved**

#### **Before/After Comparison**
- **Before**: [Initial state]
- **After**: [Final state]
- **Improvement**: [Quantifiable improvement]

#### **Regression Analysis**
- **No Breaking Changes**: [Compatibility maintained]
- **Enhanced Reliability**: [Reliability improvements]
- **Improved Observability**: [Monitoring enhancements]
- **Better User Experience**: [UX improvements]

#### **TODOs Completed**
- ✅ [Completed task 1]
- ✅ [Completed task 2]
- ✅ [Completed task 3]

---
"@
        "Role" = @"

## 🎭 **4. Role**

### **Actor Declaration**
**[Agent Name]** acting as **[Role]**

**Scope**: [Scope of responsibility]  
**Responsibilities**: 
- [Responsibility 1]
- [Responsibility 2]
- [Responsibility 3]

**Guardrails Respected**:
- Local-first (no external cloud dependencies)
- Safety (no secrets exposed)
- Idempotence (scripts re-runnable)
- Verification (runnable checks for every change)

**Integration**: 
- [How this integrates with existing systems]
- [Compatibility maintained]
- [Environment considerations]

---
"@
    }
    
    return $templates[$SectionName]
}

function Find-InsertionPoint {
    param(
        [string]$Content,
        [string]$SectionName
    )
    
    # Define section order
    $sectionOrder = @("Examine", "Clean", "Report", "Role")
    $currentIndex = $sectionOrder.IndexOf($SectionName)
    
    # Find where to insert based on existing sections
    $insertionPoint = 0
    
    # Look for existing sections that come before this one
    for ($i = 0; $i -lt $currentIndex; $i++) {
        $prevSection = $sectionOrder[$i]
        $pattern = [regex]::Escape($SECTION_STRUCTURE[$prevSection].Pattern)
        $match = [regex]::Match($Content, $pattern)
        if ($match.Success) {
            # Find the end of this section
            $sectionEnd = Find-SectionEnd -Content $Content -StartIndex $match.Index
            $insertionPoint = [Math]::Max($insertionPoint, $sectionEnd)
        }
    }
    
    # If no previous sections found, look for header
    if ($insertionPoint -eq 0) {
        $headerMatch = [regex]::Match($Content, "---\s*$", [System.Text.RegularExpressions.RegexOptions]::Multiline)
        if ($headerMatch.Success) {
            $insertionPoint = $headerMatch.Index + $headerMatch.Length
        }
    }
    
    return $insertionPoint
}

function Find-SectionEnd {
    param(
        [string]$Content,
        [int]$StartIndex
    )
    
    # Look for next section or end of content
    $nextSectionPattern = "## [🔍🧹📝🎭] \*\*[1-4]\. \w+"
    $match = [regex]::Match($Content.Substring($StartIndex), $nextSectionPattern)
    
    if ($match.Success) {
        return $StartIndex + $match.Index
    }
    
    return $Content.Length
}

function Get-AllECRRReports {
    param([string]$ReportPath)
    
    $files = @()
    if (Test-Path $ReportPath) {
        $files = Get-ChildItem -Path $ReportPath -Filter "*.md" -Recurse | Where-Object { 
            $_.Name -notlike "*template*" -and 
            $_.Name -notlike "*analysis*" -and
            $_.Name -notlike "*summary*" -and
            $_.Directory.Name -ne "archive"
        }
    }
    return $files
}

# Main execution
try {
    Write-Host "🔍 ECRR 4-Section Structure Enforcement Starting..." -ForegroundColor Cyan
    
    # Get all ECRR reports
    $reportFiles = Get-AllECRRReports -ReportPath $ReportPath
    
    if ($reportFiles.Count -eq 0) {
        Write-Warning "No ECRR report files found in $ReportPath"
        exit 1
    }
    
    Write-Host "Found $($reportFiles.Count) ECRR report files to validate" -ForegroundColor Green
    
    if ($DryRun) {
        Write-Host "🔍 DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
    }
    
    $results = @()
    $processed = 0
    $compliant = 0
    $nonCompliant = 0
    
    foreach ($file in $reportFiles) {
        $processed++
        $fileName = $file.Name
        
        if ($Verbose) {
            Write-Host "[$processed/$($reportFiles.Count)] Processing: $fileName" -ForegroundColor Gray
        }
        
        # Test current structure
        $structureResults = Test-ReportHas4SectionStructure -FilePath $file.FullName
        
        if ($structureResults.IsCompliant) {
            $compliant++
            $result = @{
                "File" = $fileName
                "Status" = "Already compliant"
                "Action" = "Skipped"
                "MissingSections" = @()
                "Issues" = @()
            }
        } else {
            $nonCompliant++
            $result = Fix-Report4SectionStructure -FilePath $file.FullName -StructureResults $structureResults -DryRun $DryRun
        }
        
        $results += $result
        
        if ($structureResults.IsCompliant) {
            Write-Host "✅ Compliant: $fileName" -ForegroundColor Green
        } else {
            if (-not $DryRun) {
                Write-Host "🔧 Fixed structure: $fileName" -ForegroundColor Yellow
            } else {
                Write-Host "🔍 Would fix structure: $fileName" -ForegroundColor Yellow
            }
        }
    }
    
    # Generate report
    $report = @{
        "Generated" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "Mode" = if ($DryRun) { "Dry Run" } else { "Live Update" }
        "Total_Reports" = $reportFiles.Count
        "Processed" = $processed
        "Compliant" = $compliant
        "NonCompliant" = $nonCompliant
        "Results" = $results
        "Summary" = @{
            "Fixed" = ($results | Where-Object { $_.Status -like "*fixed*" }).Count
            "Skipped" = ($results | Where-Object { $_.Status -like "*compliant*" }).Count
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
    Write-Host "`n📊 ECRR 4-Section Structure Enforcement Summary" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "Total Reports: $($reportFiles.Count)" -ForegroundColor White
    Write-Host "Processed: $processed" -ForegroundColor White
    Write-Host "Compliant: $compliant" -ForegroundColor Green
    Write-Host "Non-Compliant: $nonCompliant" -ForegroundColor Yellow
    Write-Host "Fixed: $($report.Summary.Fixed)" -ForegroundColor Green
    Write-Host "Skipped: $($report.Summary.Skipped)" -ForegroundColor Gray
    Write-Host "Errors: $($report.Summary.Errors)" -ForegroundColor Red
    
    Write-Host "`n📄 Detailed report saved to: $OutputPath" -ForegroundColor Green
    
    if ($DryRun) {
        Write-Host "`n🔍 This was a dry run. Use without -DryRun to apply changes." -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host "`n✅ ECRR 4-Section Structure enforcement completed!" -ForegroundColor Green
        exit 0
    }
    
} catch {
    Write-Error "ECRR 4-Section Structure enforcement failed: $($_.Exception.Message)"
    exit 3
}
