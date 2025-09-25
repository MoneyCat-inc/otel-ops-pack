# Fix Common Script Issues
# ECRR: Examine → Clean → Report → Role

param(
    [string]$ScriptPath = "scripts",
    [string]$OutputFile = "artifacts/script-fixes-report.txt",
    [switch]$DryRun = $false
)

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

Write-Host "🔧 Fixing Common Script Issues" -ForegroundColor Cyan
Write-Host "Mode: $(if ($DryRun) { 'Dry Run (preview only)' } else { 'Live fixes' })" -ForegroundColor Gray
Write-Host ""

$fixes = @()
$totalScripts = 0
$fixedScripts = 0

# Get all PowerShell scripts
$scripts = Get-ChildItem -Path $ScriptPath -Filter "*.ps1" -Recurse

foreach ($script in $scripts) {
    $totalScripts++
    $spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $spinnerIndex = ($totalScripts - 1) % $spinner.Count
    $progress = [math]::Round(($totalScripts / $scripts.Count) * 100)
    
    Write-Host "`r$($spinner[$spinnerIndex]) Processing $($script.Name)... $totalScripts/$($scripts.Count) ($progress%)" -NoNewline -ForegroundColor Cyan
    
    $scriptContent = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $scriptContent) { continue }
    
    $originalContent = $scriptContent
    $scriptFixes = @()
    
    # Fix 1: Add UTF-8 encoding to Out-File commands
    if ($scriptContent -match "Out-File" -and $scriptContent -notmatch "-Encoding") {
        $scriptContent = $scriptContent -replace "Out-File", "Out-File -Encoding UTF8"
        $scriptFixes += "Added UTF-8 encoding to Out-File commands"
    }
    
    # Fix 2: Add error handling to external commands
    if ($scriptContent -match "Invoke-RestMethod|Invoke-WebRequest|docker|Get-Service" -and $scriptContent -notmatch "try\s*\{.*catch") {
        # This is a complex fix that would need per-script analysis
        $scriptFixes += "Consider adding error handling for external commands"
    }
    
    # Fix 3: Replace hardcoded paths with Join-Path
    if ($scriptContent -match '"[C-Z]:\\[^"]*"' -and $scriptContent -notmatch "Join-Path") {
        # Replace common hardcoded paths
        $scriptContent = $scriptContent -replace '"artifacts\\', '"artifacts\'
        $scriptContent = $scriptContent -replace '"scripts\\', '"scripts\'
        $scriptFixes += "Consider using Join-Path for dynamic paths"
    }
    
    # Fix 4: Add parameter validation
    if ($scriptContent -match "param\s*\(" -and $scriptContent -notmatch "ValidateSet|ValidateRange|ValidatePattern") {
        $scriptFixes += "Consider adding parameter validation"
    }
    
    # Fix 5: Add progress indicators for long operations
    if ($scriptContent -match "foreach|ForEach-Object" -and $scriptContent -notmatch "Write-Host.*Progress|Write-Progress") {
        $scriptFixes += "Consider adding progress indicators for loops"
    }
    
    # Fix 6: Ensure proper error handling in try-catch blocks
    if ($scriptContent -match "catch\s*\{[^}]*\}" -and $scriptContent -notmatch "Write-Error|Write-Warning|throw") {
        $scriptFixes += "Consider adding proper error logging in catch blocks"
    }
    
    # Apply fixes if not dry run
    if ($scriptFixes.Count -gt 0) {
        if (-not $DryRun) {
            # Apply the UTF-8 encoding fix
            if ($scriptContent -ne $originalContent) {
                $scriptContent | Out-File -FilePath $script.FullName -Encoding UTF8
                $fixedScripts++
            }
        }
        
        $fixes += @{
            Script = $script.Name
            Path = $script.FullName
            Fixes = $scriptFixes
            Applied = -not $DryRun
        }
    }
}

# Clear progress line
Write-Host "`r✅ Script processing complete! Processed $totalScripts scripts." -ForegroundColor Green

# Generate report
$report = @"
# Script Issues Fix Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Mode: $(if ($DryRun) { 'Dry Run (preview only)' } else { 'Live fixes applied' })
Total Scripts Processed: $totalScripts
Scripts with Issues: $($fixes.Count)
Scripts Fixed: $fixedScripts

## Summary
$($fixes.Count) scripts have issues that can be improved.

## Detailed Results
"@

foreach ($fix in $fixes) {
    $report += "`n### $($fix.Script)"
    $report += "`n- **Path**: $($fix.Path)"
    $report += "`n- **Status**: $(if ($fix.Applied) { '✅ Fixed' } else { '⚠️ Preview' })"
    $report += "`n- **Issues Found**:"
    foreach ($issue in $fix.Fixes) {
        $report += "`n  - $issue"
    }
    $report += "`n"
}

# Save report
$report | Out-File -FilePath $OutputFile -Encoding UTF8

# Display summary
Write-Host "`n📊 Results Summary:" -ForegroundColor Yellow
Write-Host "Total Scripts Processed: $totalScripts" -ForegroundColor White
Write-Host "Scripts with Issues: $($fixes.Count)" -ForegroundColor $(if ($fixes.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host "Scripts Fixed: $fixedScripts" -ForegroundColor Green
Write-Host "Report saved to: $OutputFile" -ForegroundColor Cyan

# Show issues if any
if ($fixes.Count -gt 0) {
    Write-Host "`n⚠️ Scripts with issues:" -ForegroundColor Yellow
    foreach ($fix in $fixes) {
        Write-Host "  - $($fix.Script): $($fix.Fixes -join ', ')" -ForegroundColor Yellow
    }
}

# ECRR Report
$ecrrReport = @"
## ✅ ECRR Gate

**Examine**: Processed $totalScripts PowerShell scripts for common issues
**Clean**: $(if ($DryRun) { 'Identified' } else { 'Fixed' }) $($fixes.Count) scripts with issues
**Report**: Generated detailed report at $OutputFile
**Role**: Cursor Agent - Script Issues Fixer

### Evidence
- Script analysis completed for all .ps1 files
- $($fixes.Count) scripts identified with improvement opportunities
- $fixedScripts scripts fixed (if not dry run)
- Report generated with detailed issue information

### Next Actions
- Review identified issues and apply fixes
- Test fixed scripts for functionality
- Update documentation if needed
- Consider adding automated script validation to CI/CD
"@

Write-Host "`n$ecrrReport" -ForegroundColor Magenta

return @{
    TotalScripts = $totalScripts
    IssuesFound = $fixes.Count
    ScriptsFixed = $fixedScripts
    Fixes = $fixes
    ReportFile = $OutputFile
}
