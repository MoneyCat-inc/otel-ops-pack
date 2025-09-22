# Quarterly Archive Audit Script
# Purpose: Review docs/archive/ contents to determine if files can be safely deleted
# Schedule: Run quarterly (Jan, Apr, Jul, Oct)

param(
    [switch]$DryRun = $false,
    [switch]$Force = $false
)

Write-Host "=== Quarterly Archive Audit ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd')" -ForegroundColor Gray
Write-Host ""

# Check if archive directory exists
$archivePath = "docs/archive"
if (-not (Test-Path $archivePath)) {
    Write-Host "❌ Archive directory not found: $archivePath" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Archive Directory: $archivePath" -ForegroundColor Green
Write-Host ""

# List archived files
$archivedFiles = Get-ChildItem -Path $archivePath -Filter "*.md" | Where-Object { $_.Name -ne "README.md" }
Write-Host "📋 Archived Files:" -ForegroundColor Yellow
foreach ($file in $archivedFiles) {
    $lastModified = $file.LastWriteTime.ToString("yyyy-MM-dd")
    $size = [math]::Round($file.Length / 1KB, 1)
    Write-Host "  • $($file.Name) (Modified: $lastModified, Size: ${size}KB)" -ForegroundColor Gray
}

Write-Host ""

# Check for references to archived files
Write-Host "🔍 Checking for active references..." -ForegroundColor Yellow
$references = @()

# Search for references in markdown files
$mdFiles = Get-ChildItem -Path "." -Filter "*.md" -Recurse | Where-Object { $_.FullName -notlike "*\docs\archive\*" }
foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        foreach ($archivedFile in $archivedFiles) {
            if ($content -match [regex]::Escape($archivedFile.Name)) {
                $match = $content -split "`n" | Select-String -Pattern [regex]::Escape($archivedFile.Name) | Select-Object -First 1
                $references += @{
                    File = $file.FullName
                    Referenced = $archivedFile.Name
                    Line = if ($match) { $match.LineNumber } else { "Unknown" }
                }
            }
        }
    }
}

if ($references.Count -gt 0) {
    Write-Host "⚠️  Found $($references.Count) active references to archived files:" -ForegroundColor Yellow
    foreach ($ref in $references) {
        Write-Host "  • $($ref.File):$($ref.Line) → $($ref.Referenced)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "❌ Cannot safely delete archived files - active references exist" -ForegroundColor Red
    Write-Host "   Update references to point to active runbooks before deletion" -ForegroundColor Gray
} else {
    Write-Host "✅ No active references found to archived files" -ForegroundColor Green
    Write-Host ""
    
    # Check file age
    $oldestFile = $archivedFiles | Sort-Object LastWriteTime | Select-Object -First 1
    $daysSinceModified = (Get-Date) - $oldestFile.LastWriteTime
    $daysSinceModified = $daysSinceModified.Days
    
    Write-Host "📅 Oldest archived file: $($oldestFile.Name) (${daysSinceModified} days ago)" -ForegroundColor Gray
    
    if ($daysSinceModified -ge 90) {
        Write-Host "✅ Files have been archived for $daysSinceModified days (≥90 days)" -ForegroundColor Green
        Write-Host ""
        
        if ($Force) {
            Write-Host "🗑️  DELETING archived files..." -ForegroundColor Red
            foreach ($file in $archivedFiles) {
                Remove-Item $file.FullName -Force
                Write-Host "  • Deleted: $($file.Name)" -ForegroundColor Gray
            }
            Write-Host "✅ Archive cleanup completed" -ForegroundColor Green
        } elseif ($DryRun) {
            Write-Host "🔍 DRY RUN - Would delete the following files:" -ForegroundColor Yellow
            foreach ($file in $archivedFiles) {
                Write-Host "  • $($file.Name)" -ForegroundColor Gray
            }
            Write-Host ""
            Write-Host "To actually delete, run with -Force parameter" -ForegroundColor Gray
        } else {
            Write-Host "💡 Files are ready for deletion. Run with -Force to delete or -DryRun to preview" -ForegroundColor Cyan
        }
    } else {
        Write-Host "⏳ Files archived for $daysSinceModified days (<90 days) - keep for now" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Audit Complete ===" -ForegroundColor Cyan

# Generate audit report
$reportPath = "docs/archive/audit-report-$(Get-Date -Format 'yyyy-MM').md"
$report = @"
# Archive Audit Report - $(Get-Date -Format 'yyyy-MM')

## Summary
- **Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **Archived Files**: $($archivedFiles.Count)
- **Active References**: $($references.Count)
- **Oldest File Age**: $daysSinceModified days

## Archived Files
$($archivedFiles | ForEach-Object { "- $($_.Name) (Modified: $($_.LastWriteTime.ToString('yyyy-MM-dd')))" } | Out-String)

## Active References
$($references | ForEach-Object { "- $($_.File):$($_.Line) → $($_.Referenced)" } | Out-String)

## Recommendation
$(
    if ($references.Count -gt 0) {
        "❌ Keep archived files - active references exist"
    } elseif ($daysSinceModified -ge 90) {
        "✅ Safe to delete archived files"
    } else {
        "⏳ Keep archived files - not old enough for deletion"
    }
)

---
*Generated by quarterly-archive-audit.ps1*
"@

Set-Content -Path $reportPath -Value $report -Encoding UTF8
Write-Host "📄 Audit report saved: $reportPath" -ForegroundColor Green
