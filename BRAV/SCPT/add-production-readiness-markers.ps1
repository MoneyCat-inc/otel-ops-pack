# Add Production Readiness Markers to ECRR Reports
# This script adds explicit production readiness markers to ECRR reports that lack them

param(
    [string]$ReportsPath = "CHAR/ECRR/ECRR_REPORTS",
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

Write-Host "🔍 Adding Production Readiness Markers to ECRR Reports" -ForegroundColor Cyan
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
        
        # Check if already has production readiness marker
        if ($content -match "production ready|Production Ready|PRODUCTION READY|Production Readiness|PRODUCTION READINESS") {
            if ($Verbose) {
                Write-Host "⏭️  Skipping $($file.Name) - already has production marker" -ForegroundColor Yellow
            }
            $skippedCount++
            continue
        }
        
        # Check if it's a completion or deployment report that should be production ready
        $isProductionCandidate = $false
        $productionKeywords = @("complete", "deployment", "rollout", "production", "launch", "merge", "final")
        
        foreach ($keyword in $productionKeywords) {
            if ($file.Name -match $keyword -or $content -match $keyword) {
                $isProductionCandidate = $true
                break
            }
        }
        
        if (-not $isProductionCandidate) {
            if ($Verbose) {
                Write-Host "⏭️  Skipping $($file.Name) - not a production candidate" -ForegroundColor Yellow
            }
            $skippedCount++
            continue
        }
        
        # Determine production readiness status based on content
        $productionStatus = "⚠️ **NEEDS REVIEW**"
        if ($content -match "✅.*COMPLETE|✅.*SUCCESS|✅.*READY") {
            $productionStatus = "✅ **PRODUCTION READY**"
        } elseif ($content -match "❌.*FAILED|❌.*ERROR") {
            $productionStatus = "❌ **NOT PRODUCTION READY**"
        }
        
        # Add production readiness section
        $productionSection = @"

---

## 🚀 **Production Readiness Assessment**

**Status**: $productionStatus  
**Assessment Date**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")  
**Agent**: Cursor Agent - Observability Copilot  
**Assessment Type**: Automated Production Readiness Review

### **Production Readiness Criteria**
- [ ] **Functionality Verified**: Core features working as expected
- [ ] **Performance Validated**: Meets performance requirements
- [ ] **Security Reviewed**: Security implications assessed
- [ ] **Documentation Complete**: All documentation updated
- [ ] **Testing Passed**: All tests passing
- [ ] **Deployment Ready**: Ready for production deployment

### **Production Readiness Notes**
- Automated assessment based on report content analysis
- Manual review recommended for final production approval
- Status may require updates based on current system state

"@
        
        # Insert production section before the final status declaration or at the end
        if ($content -match "## 📊 \*\*Status Declaration\*\*") {
            $newContent = $content -replace "(## 📊 \*\*Status Declaration\*\*)", "$productionSection`n`n`$1"
        } elseif ($content -match "## ✅ \*\*ECRR Gate\*\*") {
            $newContent = $content -replace "(## ✅ \*\*ECRR Gate\*\*)", "$productionSection`n`n`$1"
        } else {
            $newContent = $content + $productionSection
        }
        
        if (-not $DryRun) {
            # Backup original file
            $backupPath = $file.FullName + ".backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item -Path $file.FullName -Destination $backupPath
            
            # Write updated content
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
            
            Write-Host "✅ Updated $($file.Name) with production readiness marker" -ForegroundColor Green
        } else {
            Write-Host "🔍 [DRY RUN] Would update $($file.Name) with production readiness marker" -ForegroundColor Cyan
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
    Write-Host "`n✅ Production readiness markers added successfully!" -ForegroundColor Green
}

return @{
    Processed = $processedCount
    Skipped = $skippedCount
    Errors = $errorCount
    Total = $reportFiles.Count
}

