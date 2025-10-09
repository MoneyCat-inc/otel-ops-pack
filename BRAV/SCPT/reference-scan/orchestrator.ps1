# Reference Scan Orchestrator
# Master script that coordinates all scan phases
param(
    [switch]$SkipScan,
    [switch]$SkipReport,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$ROOT = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent

Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                          ║" -ForegroundColor Cyan
Write-Host "║   🔍 INTERNAL REFERENCES MAPPING - ORCHESTRATOR 🔍      ║" -ForegroundColor Cyan
Write-Host "║                                                          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "`nStarted: $timestamp" -ForegroundColor Gray

# Phase 1: Setup
Write-Host "`n📋 Phase 1: Setup & Preparation" -ForegroundColor Yellow
if (-not (Test-Path "artifacts/reference-scan")) {
    New-Item -ItemType Directory -Force -Path "artifacts/reference-scan" | Out-Null
}
Write-Host "  ✓ Workspace ready" -ForegroundColor Green

# Phase 2: Scanning (6 scanners)
if (-not $SkipScan) {
    Write-Host "`n🔍 Phase 2: Scanning Repository Files" -ForegroundColor Yellow
    
    $scanners = @(
        @{Name="TypeScript/JavaScript"; Script="scan-typescript.ps1"},
        @{Name="PowerShell"; Script="scan-powershell.ps1"},
        @{Name="Python"; Script="scan-python.ps1"},
        @{Name="YAML"; Script="scan-yaml.ps1"},
        @{Name="Markdown"; Script="scan-markdown.ps1"}
    )
    
    foreach ($scanner in $scanners) {
        Write-Host "`n  Running: $($scanner.Name) Scanner..." -ForegroundColor Cyan
        $scriptPath = Join-Path $PSScriptRoot $scanner.Script
        if (Test-Path $scriptPath) {
            & $scriptPath
        } else {
            Write-Host "    ⚠️  Scanner not found: $scriptPath" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n  ✓ All scanners complete" -ForegroundColor Green
} else {
    Write-Host "`n⏭️  Phase 2: SKIPPED (using cached scan data)" -ForegroundColor Yellow
}

# Phase 3: Consolidation
Write-Host "`n📊 Phase 3: Consolidating Scan Results" -ForegroundColor Yellow

$allRefs = @()
$allRefs += "Source,Target,Type,FileType,Line`n"

$scanFiles = Get-ChildItem "artifacts/reference-scan/*-refs.csv" -ErrorAction SilentlyContinue
foreach ($scanFile in $scanFiles) {
    $fileType = $scanFile.BaseName -replace '-refs$',''
    $content = Get-Content $scanFile.FullName | Select-Object -Skip 1
    foreach ($line in $content) {
        if ($line.Trim()) {
            # Parse CSV line: Source,Target,Type,Pattern
            $parts = $line -split ','
            if ($parts.Count -ge 4) {
                # Insert FileType between Type and Line
                $allRefs += "$($parts[0]),$($parts[1]),$($parts[2]),$fileType,$($parts[3])`n"
            }
        }
    }
}

$masterFile = "artifacts/reference-scan/master-references.csv"
$allRefs | Out-File -FilePath $masterFile -Encoding UTF8 -NoNewline
Write-Host "  ✓ Consolidated $($allRefs.Count - 1) references" -ForegroundColor Green
Write-Host "  📄 Master file: $masterFile" -ForegroundColor Gray

# Phase 4: Analysis
Write-Host "`n📈 Phase 4: Analyzing References" -ForegroundColor Yellow

$refs = Import-Csv $masterFile
$totalRefs = $refs.Count

# Most referenced files
$targetCounts = $refs | Group-Object Target | 
    Sort-Object Count -Descending | 
    Select-Object -First 20 Name, Count

# Most referencing files  
$sourceCounts = $refs | Group-Object Source |
    Sort-Object Count -Descending |
    Select-Object -First 20 Name, Count

# References by type
$typeCounts = $refs | Group-Object FileType | Select-Object Name, Count

Write-Host "  ✓ Analysis complete" -ForegroundColor Green
Write-Host "    • Total references: $totalRefs" -ForegroundColor Gray
Write-Host "    • Unique sources: $(($refs | Select-Object Source -Unique).Count)" -ForegroundColor Gray
Write-Host "    • Unique targets: $(($refs | Select-Object Target -Unique).Count)" -ForegroundColor Gray

# Phase 5: Report Generation
if (-not $SkipReport) {
    Write-Host "`n📝 Phase 5: Generating Markdown Report" -ForegroundColor Yellow
    
    $reportPath = "docs/planning/INTERNAL_REFERENCES_MAP.md"
    
    $report = @"
# Internal References Map
**Generated:** $timestamp  
**Total References:** $totalRefs  
**Tool:** BossCat OEM Reference Scanner

---

## 📊 Executive Summary

This document maps all internal file references across the repository, identifying which files reference other files. This is essential for refactoring, migration (like tetragram), and understanding code dependencies.

### Statistics

| Metric | Count |
|--------|-------|
| Total References | $totalRefs |
| Unique Source Files | $(($refs | Select-Object Source -Unique).Count) |
| Unique Target Files | $(($refs | Select-Object Target -Unique).Count) |

### References by File Type

| Type | Count |
|------|-------|
"@

    foreach ($type in $typeCounts) {
        $report += "| $($type.Name) | $($type.Count) |`n"
    }

    $report += @"

---

## 🎯 Top 20 Most Referenced Files

These files are referenced most often across the codebase. Changes to these files will have wide-reaching impact.

| Rank | File | References |
|------|------|------------|
"@

    $rank = 1
    foreach ($target in $targetCounts) {
        $report += "| $rank | ``$($target.Name)`` | $($target.Count) |`n"
        $rank++
    }

    $report += @"

---

## 📁 Top 20 Files With Most References

These files reference many other files. They are highly coupled to the rest of the codebase.

| Rank | File | Outgoing Refs |
|------|------|---------------|
"@

    $rank = 1
    foreach ($source in $sourceCounts) {
        $report += "| $rank | ``$($source.Name)`` | $($source.Count) |`n"
        $rank++
    }

    $report += @"

---

## 📋 Complete Reference List

### CSV Format

The complete reference data is available in CSV format:
- **Master File:** ``artifacts/reference-scan/master-references.csv``
- **Individual Scans:** ``artifacts/reference-scan/*-refs.csv``

### Query Examples

**Find all references TO a file:**
``````powershell
Import-Csv artifacts/reference-scan/master-references.csv | Where-Object { `$_.Target -like "*filename*" }
``````

**Find all references FROM a file:**
``````powershell
Import-Csv artifacts/reference-scan/master-references.csv | Where-Object { `$_.Source -like "*filename*" }
``````

**Count references by type:**
``````powershell
Import-Csv artifacts/reference-scan/master-references.csv | Group-Object Type | Sort-Object Count -Descending
``````

---

## 🔧 Usage for Tetragram Migration

This reference map is critical for the tetragram migration (ALFA/BRAV/CHAR/DELT structure):

1. **Pre-Migration:** Identify all files that reference a directory you plan to move
2. **Path Rewriter:** Use this data to update all references automatically
3. **Validation:** After migration, re-run scanner to detect broken references

### Migration Impact Analysis

Before moving a directory, query references:
``````powershell
`$refs = Import-Csv artifacts/reference-scan/master-references.csv
`$impactedFiles = `$refs | Where-Object { `$_.Target -like "scripts/*" } | Select-Object Source -Unique
Write-Host "Moving scripts/ will impact `$(`$impactedFiles.Count) files"
``````

---

## 🐾 BossCat Notes

**Maintenance:**
- Re-run scanner after major refactoring: ``pwsh scripts/reference-scan/orchestrator.ps1``
- Commit updated map to track changes over time
- Use in CI to detect broken references

**Generated:** $timestamp  
**Next Scan:** Run after major file moves or refactoring
"@

    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "  ✓ Report generated" -ForegroundColor Green
    Write-Host "  📄 Location: $reportPath" -ForegroundColor Gray
} else {
    Write-Host "`n⏭️  Phase 5: SKIPPED (report generation disabled)" -ForegroundColor Yellow
}

# Phase 6: Summary
Write-Host "`n✅ SCAN COMPLETE" -ForegroundColor Green
Write-Host "`n📊 Final Statistics:" -ForegroundColor Cyan
Write-Host "  • Total references found: $totalRefs" -ForegroundColor White
Write-Host "  • File types scanned: $($typeCounts.Count)" -ForegroundColor White
Write-Host "  • Output artifacts: $((Get-ChildItem artifacts/reference-scan -File).Count)" -ForegroundColor White
Write-Host "  • Report location: docs/planning/INTERNAL_REFERENCES_MAP.md" -ForegroundColor White

Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review the report: docs/planning/INTERNAL_REFERENCES_MAP.md" -ForegroundColor White
Write-Host "  2. Use CSV data for path rewriting: artifacts/reference-scan/master-references.csv" -ForegroundColor White
Write-Host "  3. Commit to repository for team access" -ForegroundColor White

Write-Host "`n🐾 BossCat: Reference mapping complete!" -ForegroundColor Magenta

