# Comprehensive Internal Reference Scanner
# Scans repository for all internal file references
# BossCat OEM - Repository Analysis Tool

param(
    [string]$OutputDir = "docs/planning",
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$ROOT = $PSScriptRoot | Split-Path -Parent

Write-Host "`n🔍 Comprehensive Internal Reference Scanner" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Initialize results
$results = @{
    TypeScript = @()
    JavaScript = @()
    PowerShell = @()
    Python = @()
    YAML = @()
    JSON = @()
    Markdown = @()
    Other = @()
}

$stats = @{
    TotalFiles = 0
    FilesWithRefs = 0
    TotalRefs = 0
    ByType = @{}
}

# Helper function to resolve relative paths
function Resolve-RepoPath {
    param($BasePath, $RefPath)
    
    if ([System.IO.Path]::IsPathRooted($RefPath)) {
        return $RefPath
    }
    
    $baseDir = Split-Path -Parent $BasePath
    $combined = Join-Path $baseDir $RefPath
    
    try {
        $resolved = [System.IO.Path]::GetFullPath($combined)
        return $resolved.Replace($ROOT, "").TrimStart("\", "/")
    } catch {
        return $RefPath
    }
}

Write-Host "`n📁 Scanning TypeScript/JavaScript files..." -ForegroundColor Yellow

# Scan TypeScript/JavaScript files
$tsJsFiles = Get-ChildItem -Path $ROOT -Recurse -Include *.ts,*.tsx,*.js,*.jsx,*.mjs -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '(node_modules|\.next|dist|build|out)' }

foreach ($file in $tsJsFiles) {
    $stats.TotalFiles++
    $relativePath = $file.FullName.Replace($ROOT, "").TrimStart("\", "/")
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    
    if (-not $content) { continue }
    
    # Match import/require statements
    $imports = [regex]::Matches($content, "(?:import|require|from)\s+['\`"]([^'\`"]+)['\`"]") | 
        ForEach-Object { $_.Groups[1].Value }
    
    # Match dynamic imports
    $dynamicImports = [regex]::Matches($content, "import\s*\(['\`"]([^'\`"]+)['\`"]\)") |
        ForEach-Object { $_.Groups[1].Value }
    
    $allImports = $imports + $dynamicImports | 
        Where-Object { $_ -match '^\.' -or $_ -match '^@/' } |
        Select-Object -Unique
    
    if ($allImports.Count -gt 0) {
        $stats.FilesWithRefs++
        $stats.TotalRefs += $allImports.Count
        
        foreach ($imp in $allImports) {
            $results.TypeScript += [PSCustomObject]@{
                Source = $relativePath
                Target = $imp
                Type = "import/require"
                Line = ($content -split "`n" | Select-String -Pattern [regex]::Escape($imp) -List).LineNumber
            }
        }
    }
}

Write-Host "  ✓ Found $($results.TypeScript.Count) TypeScript/JavaScript references" -ForegroundColor Green

Write-Host "`n📜 Scanning PowerShell scripts..." -ForegroundColor Yellow

# Scan PowerShell files
$psFiles = Get-ChildItem -Path $ROOT -Recurse -Include *.ps1,*.psm1 -File -ErrorAction SilentlyContinue

foreach ($file in $psFiles) {
    $stats.TotalFiles++
    $relativePath = $file.FullName.Replace($ROOT, "").TrimStart("\", "/")
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    
    if (-not $content) { continue }
    
    # Match script calls and paths
    $patterns = @(
        '(?:\.\\|pwsh\s+-File\s+|powershell\s+-File\s+)([\w\-/\\\.]+\.ps1)',
        '(?:Join-Path|Set-Location|Push-Location|cd)\s+["'']([\w\-/\\\.]+)["'']',
        '\$PSScriptRoot[\\\/]([\w\-/\\\.]+)',
        '(?:Import-Module|. )\s+["'']([\w\-/\\\.]+\.ps(?:m)?1)["'']'
    )
    
    $allRefs = @()
    foreach ($pattern in $patterns) {
        $matches = [regex]::Matches($content, $pattern)
        foreach ($match in $matches) {
            $allRefs += $match.Groups[1].Value
        }
    }
    
    $allRefs = $allRefs | Where-Object { $_ } | Select-Object -Unique
    
    if ($allRefs.Count -gt 0) {
        $stats.FilesWithRefs++
        $stats.TotalRefs += $allRefs.Count
        
        foreach ($ref in $allRefs) {
            $results.PowerShell += [PSCustomObject]@{
                Source = $relativePath
                Target = $ref
                Type = "script-call"
                Line = ($content -split "`n" | Select-String -Pattern [regex]::Escape($ref) -List).LineNumber
            }
        }
    }
}

Write-Host "  ✓ Found $($results.PowerShell.Count) PowerShell references" -ForegroundColor Green

Write-Host "`n🐍 Scanning Python files..." -ForegroundColor Yellow

# Scan Python files
$pyFiles = Get-ChildItem -Path $ROOT -Recurse -Include *.py -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '(venv|\.venv|__pycache__)' }

foreach ($file in $pyFiles) {
    $stats.TotalFiles++
    $relativePath = $file.FullName.Replace($ROOT, "").TrimStart("\", "/")
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    
    if (-not $content) { continue }
    
    # Match import statements
    $imports = [regex]::Matches($content, "(?:from|import)\s+([\w\.]+)") |
        ForEach-Object { $_.Groups[1].Value } |
        Where-Object { $_ -notmatch '^(os|sys|json|re|datetime|pathlib|typing)' } |
        Select-Object -Unique
    
    if ($imports.Count -gt 0) {
        $stats.FilesWithRefs++
        $stats.TotalRefs += $imports.Count
        
        foreach ($imp in $imports) {
            $results.Python += [PSCustomObject]@{
                Source = $relativePath
                Target = $imp
                Type = "import"
                Line = ($content -split "`n" | Select-String -Pattern [regex]::Escape($imp) -List).LineNumber
            }
        }
    }
}

Write-Host "  ✓ Found $($results.Python.Count) Python references" -ForegroundColor Green

Write-Host "`n📋 Scanning YAML/JSON configuration files..." -ForegroundColor Yellow

# Scan YAML/JSON files
$configFiles = Get-ChildItem -Path $ROOT -Recurse -Include *.yml,*.yaml,*.json -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '(node_modules|\.next|dist|package-lock)' }

foreach ($file in $configFiles) {
    $stats.TotalFiles++
    $relativePath = $file.FullName.Replace($ROOT, "").TrimStart("\", "/")
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    
    if (-not $content) { continue }
    
    # Match file paths in configs
    $paths = [regex]::Matches($content, '["\''](\.{1,2}/[\w\-/\\\.]+)["\''](') |
        ForEach-Object { $_.Groups[1].Value } |
        Select-Object -Unique
    
    if ($paths.Count -gt 0) {
        $stats.FilesWithRefs++
        $stats.TotalRefs += $paths.Count
        
        foreach ($path in $paths) {
            $type = if ($file.Extension -eq '.json') { 'JSON' } else { 'YAML' }
            $results.$type += [PSCustomObject]@{
                Source = $relativePath
                Target = $path
                Type = "config-path"
                Line = ($content -split "`n" | Select-String -Pattern [regex]::Escape($path) -List).LineNumber
            }
        }
    }
}

Write-Host "  ✓ Found $($results.YAML.Count) YAML and $($results.JSON.Count) JSON references" -ForegroundColor Green

Write-Host "`n📝 Scanning Markdown documentation..." -ForegroundColor Yellow

# Scan Markdown files
$mdFiles = Get-ChildItem -Path $ROOT -Recurse -Include *.md -File -ErrorAction SilentlyContinue

foreach ($file in $mdFiles) {
    $stats.TotalFiles++
    $relativePath = $file.FullName.Replace($ROOT, "").TrimStart("\", "/")
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    
    if (-not $content) { continue }
    
    # Match markdown links to internal files
    $links = [regex]::Matches($content, '\[([^\]]+)\]\(([^\)]+)\)') |
        ForEach-Object { $_.Groups[2].Value } |
        Where-Object { $_ -match '^\.' -or ($_ -notmatch '^http' -and $_ -match '\.(md|ps1|ts|js|py|yml|yaml|json)') } |
        Select-Object -Unique
    
    if ($links.Count -gt 0) {
        $stats.FilesWithRefs++
        $stats.TotalRefs += $links.Count
        
        foreach ($link in $links) {
            $results.Markdown += [PSCustomObject]@{
                Source = $relativePath
                Target = $link
                Type = "markdown-link"
                Line = ($content -split "`n" | Select-String -Pattern [regex]::Escape($link) -List).LineNumber
            }
        }
    }
}

Write-Host "  ✓ Found $($results.Markdown.Count) Markdown references" -ForegroundColor Green

# Calculate statistics by type
$stats.ByType = @{
    TypeScript = $results.TypeScript.Count
    JavaScript = 0  # Combined with TS
    PowerShell = $results.PowerShell.Count
    Python = $results.Python.Count
    YAML = $results.YAML.Count
    JSON = $results.JSON.Count
    Markdown = $results.Markdown.Count
}

Write-Host "`n📊 Generating report..." -ForegroundColor Yellow

# Generate comprehensive report
$reportPath = Join-Path $OutputDir "INTERNAL_REFERENCES_MAP.md"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$report = @"
# Internal References Map
**Generated:** $timestamp  
**Tool:** BossCat OEM Reference Scanner  
**Repository:** otel-ops-pack

---

## 📊 Summary Statistics

``````
Total Files Scanned:        $($stats.TotalFiles)
Files With References:      $($stats.FilesWithRefs)
Total References Found:     $($stats.TotalRefs)
``````

### References by File Type

| Type       | Count |
|------------|-------|
| TypeScript/JavaScript | $($stats.ByType.TypeScript) |
| PowerShell | $($stats.ByType.PowerShell) |
| Python     | $($stats.ByType.Python) |
| YAML       | $($stats.ByType.YAML) |
| JSON       | $($stats.ByType.JSON) |
| Markdown   | $($stats.ByType.Markdown) |

---

## 📁 TypeScript/JavaScript References

### Import/Require Statements

``````csv
Source,Target,Type,Line
"@

foreach ($ref in $results.TypeScript | Sort-Object Source) {
    $report += "`n$($ref.Source),$($ref.Target),$($ref.Type),$($ref.Line)"
}

$report += @"
``````

---

## 📜 PowerShell Script References

### Script Calls & Path References

``````csv
Source,Target,Type,Line
"@

foreach ($ref in $results.PowerShell | Sort-Object Source) {
    $report += "`n$($ref.Source),$($ref.Target),$($ref.Type),$($ref.Line)"
}

$report += @"
``````

---

## 🐍 Python References

### Import Statements

``````csv
Source,Target,Type,Line
"@

foreach ($ref in $results.Python | Sort-Object Source) {
    $report += "`n$($ref.Source),$($ref.Target),$($ref.Type),$($ref.Line)"
}

$report += @"
``````

---

## 📋 YAML Configuration References

### File Paths in YAML

``````csv
Source,Target,Type,Line
"@

foreach ($ref in $results.YAML | Sort-Object Source) {
    $report += "`n$($ref.Source),$($ref.Target),$($ref.Type),$($ref.Line)"
}

$report += @"
``````

---

## 📋 JSON Configuration References

### File Paths in JSON

``````csv
Source,Target,Type,Line
"@

foreach ($ref in $results.JSON | Sort-Object Source) {
    $report += "`n$($ref.Source),$($ref.Target),$($ref.Type),$($ref.Line)"
}

$report += @"
``````

---

## 📝 Markdown Documentation References

### Internal File Links

``````csv
Source,Target,Type,Line
"@

foreach ($ref in $results.Markdown | Sort-Object Source) {
    $report += "`n$($ref.Source),$($ref.Target),$($ref.Type),$($ref.Line)"
}

$report += @"
``````

---

## 🔍 How to Use This Map

### Finding References TO a File
``````bash
# PowerShell
Select-String "path/to/file" docs/planning/INTERNAL_REFERENCES_MAP.md

# Grep
grep "path/to/file" docs/planning/INTERNAL_REFERENCES_MAP.md
``````

### Finding References FROM a File
Look for the file path in the "Source" column of each section.

### Updating References After Migration
1. Use this map to identify all files that need updating
2. Update references in source files
3. Re-run scanner to verify: ``````pwsh scripts/analyze-internal-references.ps1``````

---

## 📊 Reference Density (Top 20 Most Referenced Files)

*(Analysis of which files are referenced most often)*

Coming soon - requires additional analysis pass.

---

## 🐾 BossCat Notes

This map is essential for:
- **Tetragram Migration** - Identify all 18k+ path references before restructuring
- **Refactoring** - Understand impact of moving/renaming files
- **Documentation** - Track doc links and keep them updated
- **Dependency Analysis** - Visualize module relationships

**Generated by:** BossCat OEM Reference Scanner  
**Last Updated:** $timestamp
"@

# Save report
$report | Out-File -FilePath $reportPath -Encoding UTF8 -Force

Write-Host "`n✅ Report generated: $reportPath" -ForegroundColor Green
Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "  • Total files scanned: $($stats.TotalFiles)" -ForegroundColor White
Write-Host "  • Files with references: $($stats.FilesWithRefs)" -ForegroundColor White
Write-Host "  • Total references: $($stats.TotalRefs)" -ForegroundColor White
Write-Host "  • TypeScript/JS: $($stats.ByType.TypeScript)" -ForegroundColor White
Write-Host "  • PowerShell: $($stats.ByType.PowerShell)" -ForegroundColor White
Write-Host "  • Python: $($stats.ByType.Python)" -ForegroundColor White
Write-Host "  • YAML: $($stats.ByType.YAML)" -ForegroundColor White
Write-Host "  • JSON: $($stats.ByType.JSON)" -ForegroundColor White
Write-Host "  • Markdown: $($stats.ByType.Markdown)" -ForegroundColor White

Write-Host "`n🎯 Next: Review the report and use it for migration planning" -ForegroundColor Yellow

