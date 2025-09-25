#Requires -Version 7.0

<#
.SYNOPSIS
    Automated Conflict Detection and Resolution Script

.DESCRIPTION
    Scans repository for common conflicts and inconsistencies, optionally fixes them,
    and generates ECRR reports. Designed for CI/CD integration and scheduled runs.

.PARAMETER Fix
    Automatically fix safe issues (path normalization, endpoint corrections)

.PARAMETER GenerateECRR
    Generate ECRR reports for detected issues

.PARAMETER OutputDir
    Directory for ECRR reports (default: docs/ECRR_REPORTS)

.PARAMETER ExcludePatterns
    Comma-separated patterns to exclude from scanning

.EXAMPLE
    .\automated-conflict-detector.ps1
    Scan and report issues without fixing

.EXAMPLE
    .\automated-conflict-detector.ps1 -Fix -GenerateECRR
    Scan, fix safe issues, and generate ECRR reports
#>

param(
    [switch]$Fix,
    [switch]$GenerateECRR,
    [string]$OutputDir = "docs/ECRR_REPORTS",
    [string]$ExcludePatterns = "node_modules,*.log,*.tmp,archive,test-conflict-resolution.md"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Initialize results
$script:Issues = @()
$script:FixedIssues = @()
$script:ECRRReports = @()

function Write-Issue {
    param(
        [string]$Type,
        [string]$Severity,
        [string]$File,
        [string]$Description,
        [string]$Fix = $null
    )
    
    $issue = @{
        Type = $Type
        Severity = $Severity
        File = $File
        Description = $Description
        Fix = $Fix
        Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    
    $script:Issues += $issue
    
    $color = switch ($Severity) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "[$Severity] $Type in $File" -ForegroundColor $color
    Write-Host "  $Description" -ForegroundColor Gray
    if ($Fix) {
        Write-Host "  Fix: $Fix" -ForegroundColor DarkGray
    }
}

function Test-MergeMarkers {
    Write-Host "`nScanning for merge markers..." -ForegroundColor Yellow
    
    $excludeList = $ExcludePatterns -split ","
    $excludeArgs = $excludeList | ForEach-Object { "--glob", "!$_" }
    
    try {
        $mergeMarkers = & rg "^<<<<<<< |^======= |^>>>>>>> " --files-with-matches @excludeArgs 2>$null
        
        foreach ($file in $mergeMarkers) {
            Write-Issue -Type "MergeMarkers" -Severity "ERROR" -File $file -Description "Contains unresolved merge markers"
        }
        
        if ($mergeMarkers.Count -eq 0) {
            Write-Host "✓ No merge markers found" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠ Could not scan for merge markers: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Test-IncorrectEndpoints {
    Write-Host "`nScanning for incorrect OTLP endpoints..." -ForegroundColor Yellow
    
    try {
        $incorrectEndpoints = & rg "http://localhost:4317" --files-with-matches --glob "*.ps1" --glob "*.py" --glob "*.md" --glob "*.yaml" 2>$null
        
        foreach ($file in $incorrectEndpoints) {
            Write-Issue -Type "IncorrectEndpoint" -Severity "WARNING" -File $file -Description "Uses HTTP schema for gRPC endpoint (4317)" -Fix "Change to localhost:4317"
        }
        
        if ($incorrectEndpoints.Count -eq 0) {
            Write-Host "✓ No incorrect endpoints found" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠ Could not scan for endpoints: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Test-PathInconsistencies {
    Write-Host "`nScanning for path inconsistencies..." -ForegroundColor Yellow
    
    try {
        # Check for mixed path styles in YAML files
        $yamlFiles = & rg "C:\\\\" --files-with-matches --glob "*.yaml" 2>$null
        
        foreach ($file in $yamlFiles) {
            Write-Issue -Type "PathStyle" -Severity "INFO" -File $file -Description "Uses backslash paths (C:\\)" -Fix "Normalize to forward slashes (C:/)"
        }
        
        if ($yamlFiles.Count -eq 0) {
            Write-Host "✓ No path inconsistencies found" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠ Could not scan for path issues: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Test-DuplicateDirectories {
    Write-Host "`nScanning for duplicate directories..." -ForegroundColor Yellow
    
    try {
        $projectDirs = Get-ChildItem -Path "projects" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match " " }
        
        foreach ($dir in $projectDirs) {
            $hyphenated = $dir.Name -replace " ", "-"
            $hyphenatedPath = Join-Path "projects" $hyphenated
            
            if (Test-Path $hyphenatedPath) {
                Write-Issue -Type "DuplicateDirectory" -Severity "WARNING" -File $dir.FullName -Description "Duplicate directory with spaces vs hyphens" -Fix "Consolidate to hyphenated version"
            }
        }
        
        if ($projectDirs.Count -eq 0) {
            Write-Host "✓ No duplicate directories found" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠ Could not scan for duplicates: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Test-CorruptedFiles {
    Write-Host "`nScanning for corrupted files..." -ForegroundColor Yellow
    
    try {
        $markdownFiles = Get-ChildItem -Path "." -Recurse -Include "*.md" | Where-Object { $_.Length -gt 0 }
        
        foreach ($file in $markdownFiles) {
            try {
                $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
                
                # Check for non-printable characters at end
                if ($content -match "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]$") {
                    Write-Issue -Type "CorruptedFile" -Severity "WARNING" -File $file.FullName -Description "Contains non-printable characters" -Fix "Clean file content"
                }
                
                # Check for excessive empty lines
                if ($content -match "\n\s*\n\s*\n\s*\n\s*\n\s*\n\s*\n\s*\n") {
                    Write-Issue -Type "ExcessiveEmptyLines" -Severity "INFO" -File $file.FullName -Description "Contains excessive empty lines" -Fix "Trim trailing whitespace"
                }
                
            } catch {
                Write-Host "⚠ Could not read $($file.FullName): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
        
        Write-Host "✓ File corruption scan completed" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Could not scan for corruption: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Invoke-SafeFixes {
    Write-Host "`nApplying safe fixes..." -ForegroundColor Yellow
    
    foreach ($issue in $script:Issues) {
        if ($issue.Severity -eq "INFO" -and $issue.Fix) {
            try {
                switch ($issue.Type) {
                    "PathStyle" {
                        if ($issue.File -like "*.yaml") {
                            $content = Get-Content -Path $issue.File -Raw
                            $fixed = $content -replace "C:\\\\", "C:/"
                            if ($fixed -ne $content) {
                                Set-Content -Path $issue.File -Value $fixed -NoNewline
                                Write-Host "✓ Fixed path style in $($issue.File)" -ForegroundColor Green
                                $script:FixedIssues += $issue
                            }
                        }
                    }
                    "ExcessiveEmptyLines" {
                        if ($issue.File -like "*.md") {
                            $content = Get-Content -Path $issue.File -Raw
                            $fixed = $content -replace "\n\s*\n\s*\n\s*\n\s*\n\s*\n\s*\n\s*\n", "`n`n"
                            if ($fixed -ne $content) {
                                Set-Content -Path $issue.File -Value $fixed -NoNewline
                                Write-Host "✓ Fixed excessive empty lines in $($issue.File)" -ForegroundColor Green
                                $script:FixedIssues += $issue
                            }
                        }
                    }
                }
            } catch {
                Write-Host "⚠ Failed to fix $($issue.File): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
}

function New-ECRRReport {
    param(
        [string]$ReportType,
        [array]$Issues
    )
    
    if (-not $GenerateECRR) { return }
    
    $timestamp = (Get-Date).ToString("yyyy-MM-dd")
    $reportFile = Join-Path $OutputDir "$timestamp-$ReportType-ecrr.md"
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    
    $reportContent = @"
# ECRR Report — $ReportType (2025-09-24)

## Examine

- Automated scan detected $($Issues.Count) issues:
"@

    foreach ($issue in $Issues) {
        $reportContent += "`n- **$($issue.Type)** in `$($issue.File): $($issue.Description)"
    }

    $reportContent += @"

## Clean

- Applied fixes: $($script:FixedIssues.Count)
- Manual review required: $($Issues.Count - $script:FixedIssues.Count)

## Report

- Scan completed: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')
- Total issues found: $($Issues.Count)
- Issues fixed: $($script:FixedIssues.Count)

## Role

- Actor: Automated Conflict Detector
- Scope: Repository hygiene and consistency

## ✅ ECRR Gate

- Examine: automated scan completed
- Clean: safe fixes applied
- Report: this document
- Role: declared

## Next Actions

- Review unfixed issues manually
- Consider adding to CI pipeline
"@

    Set-Content -Path $reportFile -Value $reportContent
    Write-Host "✓ Generated ECRR report: $reportFile" -ForegroundColor Green
    $script:ECRRReports += $reportFile
}

# Main execution
Write-Host "=== Automated Conflict Detection ===" -ForegroundColor Green
Write-Host "Repository: $(Get-Location)" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')" -ForegroundColor Cyan

# Run all tests
Test-MergeMarkers
Test-IncorrectEndpoints
Test-PathInconsistencies
Test-DuplicateDirectories
Test-CorruptedFiles

# Apply fixes if requested
if ($Fix) {
    Invoke-SafeFixes
}

# Generate ECRR report if requested
if ($GenerateECRR -and $script:Issues.Count -gt 0) {
    New-ECRRReport -ReportType "automated-conflict-scan" -Issues $script:Issues
}

# Summary
Write-Host "`n=== Scan Summary ===" -ForegroundColor Green
Write-Host "Total issues found: $($script:Issues.Count)" -ForegroundColor Cyan
Write-Host "Issues fixed: $($script:FixedIssues.Count)" -ForegroundColor Cyan
Write-Host "ECRR reports generated: $($script:ECRRReports.Count)" -ForegroundColor Cyan

if ($script:Issues.Count -gt 0) {
    Write-Host "`nIssues by severity:" -ForegroundColor Yellow
    $script:Issues | Group-Object Severity | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White
    }
}

# Exit with appropriate code
if ($script:Issues | Where-Object { $_.Severity -eq "ERROR" }) {
    Write-Host "`n❌ Critical issues found - manual intervention required" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ Scan completed successfully" -ForegroundColor Green
    exit 0
}
