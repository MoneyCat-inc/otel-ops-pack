# Security-Focused Repository Cleanup Script
# BossCat OEM - Security Hygiene Automation
# 
# Purpose: Identify and archive potentially vulnerable files
# - Log files (may contain sensitive data)
# - Screenshots (may contain credentials/PII)
# - Backup files (may contain outdated secrets)
# - Temporary files (may contain sensitive data)
# - Debug files (may expose internal details)
#
# Follows ECRR methodology:
# - Examine: Scan for vulnerable file types
# - Clean: Archive and remove from working directory
# - Report: Generate audit trail
# - Role: Security hygiene automation

param(
    [string]$ArchiveRoot = "C:\archive_bin",
    [switch]$DryRun,
    [switch]$Force,
    [switch]$SkipArchive
)

$ErrorActionPreference = "Stop"
$ROOT = $PSScriptRoot | Split-Path -Parent

Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                          ║" -ForegroundColor Cyan
Write-Host "║   🔒 SECURITY CLEANUP - BossCat OEM 🔒                  ║" -ForegroundColor Cyan
Write-Host "║                                                          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host "`nStarted: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

if ($DryRun) {
    Write-Host "`n⚠️  DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════════
# Phase 1: Define Vulnerable File Patterns
# ═══════════════════════════════════════════════════════════════

Write-Host "`n📋 Phase 1: Defining Security Risk Patterns" -ForegroundColor Yellow

$vulnerablePatterns = @{
    'Logs' = @{
        Extensions = @('*.log', '*.txt')
        Exclusions = @('package-lock.json', 'pnpm-lock.yaml', 'yarn.lock', 'requirements*.txt', 'MANIFEST.txt')
        Risk = 'HIGH'
        Reason = 'May contain API keys, tokens, or sensitive runtime data'
        ExcludePaths = @('requirements.txt', 'requirements-dev.txt', 'requirements-gpu.txt', '**/requirements.txt')
    }
    'Screenshots' = @{
        Extensions = @('*.png', '*.jpg', '*.jpeg', '*.gif', '*.bmp')
        Exclusions = @()
        Risk = 'CRITICAL'
        Reason = 'May contain credentials, PII, or internal system details'
    }
    'Backups' = @{
        Extensions = @('*.bak', '*.backup', '*.old', '*.orig')
        Exclusions = @()
        Risk = 'HIGH'
        Reason = 'May contain outdated secrets or deprecated configurations'
    }
    'Temporary' = @{
        Extensions = @('*.tmp', '*.temp', '*.swp', '*.swo')
        Exclusions = @()
        Risk = 'MEDIUM'
        Reason = 'May contain partial sensitive data or editor artifacts'
    }
    'Debug' = @{
        Extensions = @('*.dump', '*.dmp', '*.core')
        Exclusions = @()
        Risk = 'CRITICAL'
        Reason = 'Memory dumps may contain secrets, keys, or sensitive state'
    }
    'Patches' = @{
        Extensions = @('*.diff', '*.patch')
        Exclusions = @()
        Risk = 'MEDIUM'
        Reason = 'May expose internal code or contain temporary credentials'
    }
}

Write-Host "  ✓ Defined $($vulnerablePatterns.Count) risk categories" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# Phase 2: Scan Repository (ECRR: Examine)
# ═══════════════════════════════════════════════════════════════

Write-Host "`n🔍 Phase 2: Scanning Repository (ECRR: Examine)" -ForegroundColor Yellow

$findings = @()
$totalSize = 0

foreach ($category in $vulnerablePatterns.Keys) {
    $pattern = $vulnerablePatterns[$category]
    
    Write-Host "`n  Scanning: $category (Risk: $($pattern.Risk))" -ForegroundColor Cyan
    Write-Host "    Reason: $($pattern.Reason)" -ForegroundColor Gray
    
    foreach ($ext in $pattern.Extensions) {
        $files = Get-ChildItem -Path $ROOT -Recurse -File -Filter $ext -ErrorAction SilentlyContinue |
            Where-Object { 
                $_.FullName -notmatch '(node_modules|\.git|\.venv|\.next|dist|build|out)' -and
                -not ($pattern.Exclusions | Where-Object { $_.Name -like $_ }) -and
                -not ($pattern.ExcludePaths | Where-Object { $file.FullName -like "*$_*" })
            }
        
        foreach ($file in $files) {
            $findings += [PSCustomObject]@{
                Category = $category
                Risk = $pattern.Risk
                Path = $file.FullName.Replace($ROOT, "").TrimStart("\", "/")
                FullPath = $file.FullName
                Size = $file.Length
                Modified = $file.LastWriteTime
                Reason = $pattern.Reason
            }
            $totalSize += $file.Length
        }
    }
    
    $categoryCount = ($findings | Where-Object { $_.Category -eq $category }).Count
    Write-Host "    Found: $categoryCount files" -ForegroundColor $(if ($categoryCount -gt 0) { "Yellow" } else { "Green" })
}

Write-Host "`n  ✓ Scan complete: $($findings.Count) vulnerable files identified" -ForegroundColor Green
Write-Host "    Total size: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Gray

# ═══════════════════════════════════════════════════════════════
# Phase 3: Risk Assessment
# ═══════════════════════════════════════════════════════════════

Write-Host "`n📊 Phase 3: Risk Assessment" -ForegroundColor Yellow

$critical = ($findings | Where-Object { $_.Risk -eq 'CRITICAL' }).Count
$high = ($findings | Where-Object { $_.Risk -eq 'HIGH' }).Count
$medium = ($findings | Where-Object { $_.Risk -eq 'MEDIUM' }).Count

Write-Host "  • CRITICAL: $critical files" -ForegroundColor Red
Write-Host "  • HIGH: $high files" -ForegroundColor Yellow
Write-Host "  • MEDIUM: $medium files" -ForegroundColor Cyan

if ($findings.Count -eq 0) {
    Write-Host "`n✅ No vulnerable files found - repository is clean!" -ForegroundColor Green
    exit 0
}

# ═══════════════════════════════════════════════════════════════
# Phase 4: Create Archive (ECRR: Clean)
# ═══════════════════════════════════════════════════════════════

if (-not $SkipArchive) {
    Write-Host "`n📦 Phase 4: Creating Secure Archive (ECRR: Clean)" -ForegroundColor Yellow
    
    $archiveDir = Join-Path $ArchiveRoot "security-cleanup-$timestamp"
    
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path $archiveDir | Out-Null
        
        # Create category subdirectories
        foreach ($category in $vulnerablePatterns.Keys) {
            New-Item -ItemType Directory -Force -Path (Join-Path $archiveDir $category.ToLower()) | Out-Null
        }
    }
    
    Write-Host "  Archive: $archiveDir" -ForegroundColor Gray
    
    # Move files to archive
    $movedCount = 0
    foreach ($finding in $findings) {
        $destDir = Join-Path $archiveDir $finding.Category.ToLower()
        $destPath = Join-Path $destDir (Split-Path -Leaf $finding.FullPath)
        
        if ($DryRun) {
            Write-Host "    [DRY RUN] Would move: $($finding.Path)" -ForegroundColor Gray
        } else {
            try {
                Move-Item -Path $finding.FullPath -Destination $destPath -Force -ErrorAction Stop
                $movedCount++
            } catch {
                Write-Host "    ⚠️  Failed to move: $($finding.Path) - $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    
    if (-not $DryRun) {
        Write-Host "  ✓ Archived $movedCount files" -ForegroundColor Green
    }
} else {
    Write-Host "`n⏭️  Phase 4: SKIPPED (archive disabled)" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════════
# Phase 5: Generate Security Report (ECRR: Report)
# ═══════════════════════════════════════════════════════════════

Write-Host "`n📝 Phase 5: Generating Security Report (ECRR: Report)" -ForegroundColor Yellow

$reportPath = "docs/security/SECURITY_CLEANUP_$timestamp.md"

if (-not (Test-Path "docs/security")) {
    New-Item -ItemType Directory -Force -Path "docs/security" | Out-Null
}

$report = @"
# Security Cleanup Report
**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Operator:** BossCat OEM Security Automation  
**Mode:** $(if ($DryRun) { 'DRY RUN' } else { 'LIVE' })

---

## 🎯 Executive Summary

Automated security cleanup identified and archived **$($findings.Count) potentially vulnerable files** ($([math]::Round($totalSize / 1MB, 2)) MB).

### Risk Breakdown

| Risk Level | Count | Action |
|------------|-------|--------|
| CRITICAL   | $critical | $(if ($DryRun) { 'Would archive' } else { 'Archived' }) |
| HIGH       | $high | $(if ($DryRun) { 'Would archive' } else { 'Archived' }) |
| MEDIUM     | $medium | $(if ($DryRun) { 'Would archive' } else { 'Archived' }) |

---

## 📋 Findings by Category

"@

foreach ($category in $vulnerablePatterns.Keys | Sort-Object) {
    $categoryFindings = $findings | Where-Object { $_.Category -eq $category }
    if ($categoryFindings.Count -gt 0) {
        $pattern = $vulnerablePatterns[$category]
        $report += @"

### $category (Risk: $($pattern.Risk))

**Reason:** $($pattern.Reason)  
**Files Found:** $($categoryFindings.Count)  
**Total Size:** $([math]::Round(($categoryFindings | Measure-Object -Property Size -Sum).Sum / 1KB, 2)) KB

| File | Size (KB) | Last Modified |
|------|-----------|---------------|
"@
        foreach ($file in $categoryFindings | Sort-Object Path) {
            $report += "`n| ``$($file.Path)`` | $([math]::Round($file.Size / 1KB, 2)) | $($file.Modified.ToString('yyyy-MM-dd HH:mm')) |"
        }
        $report += "`n"
    }
}

$report += @"

---

## 📦 Archive Location

$(if ($SkipArchive) {
    "**Archive skipped** (--SkipArchive flag)"
} else {
    "**Location:** ``$archiveDir``  
**Contents:** $($findings.Count) files organized by risk category  
**Total Size:** $([math]::Round($totalSize / 1MB, 2)) MB

### To Review Archive:
``````powershell
explorer $archiveDir
``````

### To Restore a File:
``````powershell
Copy-Item '$archiveDir\category\filename' -Destination 'C:\otel\filename'
``````

### To Permanently Delete (After Review):
``````powershell
Remove-Item '$archiveDir' -Recurse -Force
``````"
})

---

## 🔒 Security Recommendations

### Immediate Actions
1. ✅ Review archived files for sensitive data
2. ✅ Update secrets if any were found in logs/screenshots
3. ✅ Run ```.gitignore`` validation to prevent re-introduction
4. ✅ Enable automated cleanup in CI/CD

### Prevention
- Add file patterns to ``.gitignore``:
  - ``*.log`` (except package locks)
  - ``*.bak``
  - ``*.dump``
  - Debug screenshots
  
- Set up pre-commit hooks:
  ``````bash
  pwsh scripts/security-cleanup.ps1 -DryRun
  ``````

### Regular Maintenance
Run this script monthly:
``````bash
pwsh scripts/security-cleanup.ps1
``````

Or add to nightly automation.

---

## 📊 Compliance

**ECRR Protocol:** ✅ Complete
- **Examine:** $($findings.Count) files scanned
- **Clean:** Files archived to ``$archiveDir``
- **Report:** This document
- **Role:** BossCat OEM Security Automation

**Next Scan:** $(if ($DryRun) { 'Run without -DryRun flag' } else { 'Recommended in 30 days' })

---

🔐 **BossCat Security:** Repository hygiene maintained. Review archive before permanent deletion.
"@

if (-not $DryRun) {
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "  ✓ Report generated: $reportPath" -ForegroundColor Green
} else {
    Write-Host "  [DRY RUN] Report would be saved to: $reportPath" -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════════════════
# Phase 6: Summary & Recommendations
# ═══════════════════════════════════════════════════════════════

Write-Host "`n✅ SECURITY CLEANUP COMPLETE" -ForegroundColor Green

Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "  • Files identified: $($findings.Count)" -ForegroundColor White
Write-Host "  • Total size: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor White
Write-Host "  • CRITICAL risk: $critical files" -ForegroundColor $(if ($critical -gt 0) { "Red" } else { "Green" })
Write-Host "  • HIGH risk: $high files" -ForegroundColor $(if ($high -gt 0) { "Yellow" } else { "Green" })
Write-Host "  • MEDIUM risk: $medium files" -ForegroundColor $(if ($medium -gt 0) { "Cyan" } else { "Green" })

if (-not $SkipArchive -and -not $DryRun) {
    Write-Host "`n📦 Archive:" -ForegroundColor Cyan
    Write-Host "  Location: $archiveDir" -ForegroundColor White
    Write-Host "  Review before: $(Get-Date).AddDays(30).ToString('yyyy-MM-dd')" -ForegroundColor Gray
}

if (-not $DryRun) {
    Write-Host "`n📄 Report:" -ForegroundColor Cyan
    Write-Host "  Location: $reportPath" -ForegroundColor White
    Write-Host "  Commit this report for audit trail" -ForegroundColor Yellow
}

Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  1. Review the findings above" -ForegroundColor White
    Write-Host "  2. Run without -DryRun to archive files: pwsh scripts/security-cleanup.ps1" -ForegroundColor White
} else {
    Write-Host "  1. Review archive: explorer $archiveDir" -ForegroundColor White
    Write-Host "  2. Check for exposed secrets in archived files" -ForegroundColor White
    Write-Host "  3. Update .gitignore to prevent re-introduction" -ForegroundColor White
    Write-Host "  4. Commit the security report: git add $reportPath" -ForegroundColor White
    Write-Host "  5. Delete archive after 30 days (if no issues found)" -ForegroundColor White
}

Write-Host "`n🔐 BossCat Security: Repository hygiene check complete" -ForegroundColor Magenta

# Return findings for automation
return $findings

