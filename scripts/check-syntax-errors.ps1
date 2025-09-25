# PowerShell Script Syntax Checker
# ECRR: Examine → Clean → Report → Role

param(
    [string]$ScriptPath = "scripts",
    [string]$OutputFile = "artifacts/syntax-check-results.txt"
)

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

# Initialize results
$results = @()
$errorCount = 0
$totalScripts = 0

Write-Host "🔍 Examining PowerShell scripts for syntax errors..." -ForegroundColor Cyan

# Get all PowerShell scripts
$scripts = Get-ChildItem -Path $ScriptPath -Filter "*.ps1" -Recurse

foreach ($script in $scripts) {
    $totalScripts++
    $spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $spinnerIndex = ($totalScripts - 1) % $spinner.Count
    $progress = [math]::Round(($totalScripts / $scripts.Count) * 100)
    
    Write-Host "`r$($spinner[$spinnerIndex]) Checking $($script.Name)... $totalScripts/$($scripts.Count) ($progress%)" -NoNewline -ForegroundColor Cyan
    
    try {
        # Try to parse the script for syntax errors
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script.FullName -Raw), [ref]$null)
        
        $result = @{
            Script = $script.Name
            Path = $script.FullName
            Status = "✅ OK"
            Error = $null
        }
    }
    catch {
        $errorCount++
        $result = @{
            Script = $script.Name
            Path = $script.FullName
            Status = "❌ ERROR"
            Error = $_.Exception.Message
        }
    }
    
    $results += $result
}

# Clear progress line
Write-Host "`r✅ Syntax check complete! Processed $totalScripts scripts." -ForegroundColor Green

# Generate report
$report = @"
# PowerShell Script Syntax Check Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Total Scripts: $totalScripts
Errors Found: $errorCount

## Summary
$($errorCount) scripts have syntax errors out of $totalScripts total scripts.

## Detailed Results
"@

foreach ($result in $results) {
    $report += "`n### $($result.Script)"
    $report += "`n- **Status**: $($result.Status)"
    $report += "`n- **Path**: $($result.Path)"
    if ($result.Error) {
        $report += "`n- **Error**: $($result.Error)"
    }
    $report += "`n"
}

# Save report
$report | Out-File -FilePath $OutputFile -Encoding UTF8

# Display summary
Write-Host "`n📊 Results Summary:" -ForegroundColor Yellow
Write-Host "Total Scripts: $totalScripts" -ForegroundColor White
Write-Host "Errors Found: $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Red" })
Write-Host "Report saved to: $OutputFile" -ForegroundColor Cyan

# Show errors if any
if ($errorCount -gt 0) {
    Write-Host "`n❌ Scripts with errors:" -ForegroundColor Red
    foreach ($result in $results | Where-Object { $_.Error }) {
        Write-Host "  - $($result.Script): $($result.Error)" -ForegroundColor Red
    }
}

# ECRR Report
$ecrrReport = @"
## ✅ ECRR Gate

**Examine**: Checked $totalScripts PowerShell scripts for syntax errors
**Clean**: Identified $errorCount scripts with syntax issues
**Report**: Generated detailed report at $OutputFile
**Role**: Cursor Agent - Script Syntax Validator

### Evidence
- Syntax check completed for all .ps1 files in $ScriptPath
- $errorCount errors found requiring fixes
- Report generated with detailed error information

### Next Actions
- Fix syntax errors in identified scripts
- Re-run syntax check to verify fixes
- Update documentation if needed
"@

Write-Host "`n$ecrrReport" -ForegroundColor Magenta

return @{
    TotalScripts = $totalScripts
    ErrorCount = $errorCount
    Results = $results
    ReportFile = $OutputFile
}
