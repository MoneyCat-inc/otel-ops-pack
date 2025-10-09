# ECRR Pre-Commit Hook
param(
    [string[]]$ChangedFiles = @()
)

Write-Host "🔍 ECRR Pre-Commit Hook" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

# If no files specified, get staged files from git
if ($ChangedFiles.Count -eq 0) {
    try {
        $ChangedFiles = git diff --cached --name-only --diff-filter=A | Where-Object { $_ -match 'docs/ECRR_REPORTS/.*\.md$' }
    } catch {
        Write-Host "⚠️  Could not get git staged files. Please specify files manually." -ForegroundColor Yellow
        exit 0
    }
}

# Filter for ECRR report files
$ecrrFiles = $ChangedFiles | Where-Object { 
    $_ -match 'docs/ECRR_REPORTS/.*\.md$' -and
    $_ -match '\d{4}-\d{2}-\d{2}'
}

if ($ecrrFiles.Count -eq 0) {
    Write-Host "✅ No ECRR report files in commit" -ForegroundColor Green
    exit 0
}

Write-Host "📁 ECRR Files to check: $($ecrrFiles.Count)" -ForegroundColor Yellow

# Compliance checking functions
function Test-ECRRProductionMarker {
    param([string]$Content)
    return $Content -match '✅.*PRODUCTION READY'
}

function Test-ECRRFourSectionStructure {
    param([string]$Content)
    
    $sections = @(
        "## .*(1\. )?Examine",
        "## .*(2\. )?Clean", 
        "## .*(3\. )?Report",
        "## .*(4\. )?Role"
    )
    
    $foundSections = 0
    foreach ($section in $sections) {
        if ($Content -match $section) {
            $foundSections++
        }
    }
    
    return $foundSections -eq 4
}

function Test-ECRRGate {
    param([string]$Content)
    return $Content -match '## .*ECRR Gate'
}

function Test-ECRRActorDeclaration {
    param([string]$Content)
    return $Content -match '\*\*Actor\*\*:' -or $Content -match 'Actor:'
}

# Check each ECRR file
$failedFiles = @()
$totalFiles = $ecrrFiles.Count

foreach ($file in $ecrrFiles) {
    Write-Host ""
    Write-Host "🔍 Checking: $file" -ForegroundColor Cyan
    
    if (-not (Test-Path $file)) {
        Write-Host "  ❌ File not found: $file" -ForegroundColor Red
        $failedFiles += @{
            File = $file
            Issues = @("File not found")
        }
        continue
    }
    
    $content = Get-Content -Path $file -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        Write-Host "  ❌ Could not read file: $file" -ForegroundColor Red
        $failedFiles += @{
            File = $file
            Issues = @("Could not read file")
        }
        continue
    }
    
    $issues = @()
    
    # Check production marker
    if (-not (Test-ECRRProductionMarker -Content $content)) {
        $issues += "Missing production marker (✅ **PRODUCTION READY**)"
    }
    
    # Check four-section structure
    if (-not (Test-ECRRFourSectionStructure -Content $content)) {
        $issues += "Missing four-section structure (Examine, Clean, Report, Role)"
    }
    
    # Check ECRR Gate
    if (-not (Test-ECRRGate -Content $content)) {
        $issues += "Missing ECRR Gate section"
    }
    
    # Check actor declaration
    if (-not (Test-ECRRActorDeclaration -Content $content)) {
        $issues += "Missing actor declaration (**Actor**: ...)"
    }
    
    if ($issues.Count -eq 0) {
        Write-Host "  ✅ PASS - All compliance checks passed" -ForegroundColor Green
    } else {
        Write-Host "  ❌ FAIL - Compliance issues found:" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "     - $issue" -ForegroundColor DarkRed
        }
        $failedFiles += @{
            File = $file
            Issues = $issues
        }
    }
}

# Summary
Write-Host ""
Write-Host "📊 Pre-Commit Check Summary:" -ForegroundColor Cyan
Write-Host "  Total ECRR Files: $totalFiles" -ForegroundColor Gray
Write-Host "  Passed: $($totalFiles - $failedFiles.Count)" -ForegroundColor Green
Write-Host "  Failed: $($failedFiles.Count)" -ForegroundColor $(if ($failedFiles.Count -eq 0) { "Green" } else { "Red" })

if ($failedFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ COMMIT BLOCKED - ECRR Compliance Issues Found" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Fix the following issues before committing:" -ForegroundColor Yellow
    
    foreach ($file in $failedFiles) {
        Write-Host ""
        Write-Host "📄 $($file.File):" -ForegroundColor Red
        foreach ($issue in $file.Issues) {
            Write-Host "   - $issue" -ForegroundColor DarkRed
        }
    }
    
    Write-Host ""
    Write-Host "💡 Quick Fix Commands:" -ForegroundColor Cyan
    Write-Host "   # Add production marker:" -ForegroundColor Gray
    Write-Host "   # Add **Status**: ✅ **PRODUCTION READY** after the task line" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   # Add four-section structure:" -ForegroundColor Gray
    Write-Host "   # Add ## 🔍 1. Examine, ## 🧹 2. Clean, ## 📝 3. Report, ## 🎭 4. Role sections" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   # Add ECRR Gate:" -ForegroundColor Gray
    Write-Host "   # Add ## ✅ ECRR Gate section with Examine/Clean/Report/Role subsections" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   # Add actor declaration:" -ForegroundColor Gray
    Write-Host "   # Add **Actor**: [Your Agent Name] in the header" -ForegroundColor Gray
    
    exit 1
} else {
    Write-Host ""
    Write-Host "✅ All ECRR files passed compliance checks!" -ForegroundColor Green
    Write-Host "🚀 Commit can proceed" -ForegroundColor Green
    exit 0
}
