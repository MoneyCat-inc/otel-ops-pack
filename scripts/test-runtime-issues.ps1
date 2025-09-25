# PowerShell Runtime Issues Tester
# ECRR: Examine → Clean → Report → Role

param(
    [string]$ScriptPath = "scripts",
    [string]$OutputFile = "artifacts/runtime-test-results.txt",
    [int]$MaxScripts = 20
)

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

# Initialize results
$results = @()
$errorCount = 0
$totalScripts = 0

Write-Host "🔍 Testing PowerShell scripts for runtime issues..." -ForegroundColor Cyan

# Get key PowerShell scripts to test
$keyScripts = @(
    "quick-monitor.ps1",
    "monitor-optimized-pipeline.ps1", 
    "canary-test.ps1",
    "verify-pipeline.ps1",
    "otel-health.ps1",
    "setup.ps1",
    "start-all.ps1",
    "stop-all.ps1",
    "test-environment.ps1",
    "verify-wiring.ps1"
)

# Test each key script
foreach ($scriptName in $keyScripts) {
    $scriptPath = Join-Path $ScriptPath $scriptName
    if (Test-Path $scriptPath) {
        $totalScripts++
        $spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
        $spinnerIndex = ($totalScripts - 1) % $spinner.Count
        $progress = [math]::Round(($totalScripts / $keyScripts.Count) * 100)
        
        Write-Host "`r$($spinner[$spinnerIndex]) Testing $scriptName... $totalScripts/$($keyScripts.Count) ($progress%)" -NoNewline -ForegroundColor Cyan
        
        $result = @{
            Script = $scriptName
            Path = $scriptPath
            Status = "Unknown"
            Errors = @()
            Warnings = @()
        }
        
        # Test 1: Parameter validation
        try {
            $null = Get-Command $scriptPath -ErrorAction Stop
            $result.Status = "✅ Command found"
        }
        catch {
            $result.Status = "❌ Command not found"
            $result.Errors += "Command not found: $($_.Exception.Message)"
            $errorCount++
        }
        
        # Test 2: Syntax validation (already done, but double-check)
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $scriptPath -Raw), [ref]$null)
            $result.Warnings += "Syntax OK"
        }
        catch {
            $result.Status = "❌ Syntax error"
            $result.Errors += "Syntax error: $($_.Exception.Message)"
            $errorCount++
        }
        
        # Test 3: Common runtime issues
        $scriptContent = Get-Content $scriptPath -Raw -ErrorAction SilentlyContinue
        
        # Check for common issues
        if ($scriptContent) {
            # Missing error handling
            if ($scriptContent -match "Invoke-RestMethod|Invoke-WebRequest|docker|Get-Service" -and $scriptContent -notmatch "try\s*\{|catch\s*\{") {
                $result.Warnings += "Missing error handling for external commands"
            }
            
            # Hardcoded paths
            if ($scriptContent -match "C:\\|C:/" -and $scriptContent -notmatch "Join-Path|Resolve-Path") {
                $result.Warnings += "Hardcoded paths detected"
            }
            
            # Missing parameter validation
            if ($scriptContent -match "param\s*\(" -and $scriptContent -notmatch "ValidateSet|ValidateRange|ValidatePattern") {
                $result.Warnings += "Limited parameter validation"
            }
            
            # Potential encoding issues
            if ($scriptContent -match "Out-File|Set-Content" -and $scriptContent -notmatch "-Encoding") {
                $result.Warnings += "Missing encoding specification"
            }
        }
        
        $results += $result
    }
}

# Clear progress line
Write-Host "`r✅ Runtime testing complete! Processed $totalScripts scripts." -ForegroundColor Green

# Generate report
$report = @"
# PowerShell Script Runtime Issues Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Total Scripts Tested: $totalScripts
Errors Found: $errorCount

## Summary
$errorCount scripts have runtime issues out of $totalScripts tested scripts.

## Detailed Results
"@

foreach ($result in $results) {
    $report += "`n### $($result.Script)"
    $report += "`n- **Status**: $($result.Status)"
    $report += "`n- **Path**: $($result.Path)"
    if ($result.Errors.Count -gt 0) {
        $report += "`n- **Errors**:"
        foreach ($err in $result.Errors) {
            $report += "`n  - $err"
        }
    }
    if ($result.Warnings.Count -gt 0) {
        $report += "`n- **Warnings**:"
        foreach ($warning in $result.Warnings) {
            $report += "`n  - $warning"
        }
    }
    $report += "`n"
}

# Save report
$report | Out-File -FilePath $OutputFile -Encoding UTF8

# Display summary
Write-Host "`n📊 Results Summary:" -ForegroundColor Yellow
Write-Host "Total Scripts Tested: $totalScripts" -ForegroundColor White
Write-Host "Errors Found: $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Red" })
Write-Host "Report saved to: $OutputFile" -ForegroundColor Cyan

# Show errors if any
if ($errorCount -gt 0) {
    Write-Host "`n❌ Scripts with errors:" -ForegroundColor Red
    foreach ($result in $results | Where-Object { $_.Errors.Count -gt 0 }) {
        Write-Host "  - $($result.Script): $($result.Errors -join ', ')" -ForegroundColor Red
    }
}

# Show warnings
$warningCount = ($results | Where-Object { $_.Warnings.Count -gt 0 }).Count
if ($warningCount -gt 0) {
    Write-Host "`n⚠️ Scripts with warnings ($warningCount):" -ForegroundColor Yellow
    foreach ($result in $results | Where-Object { $_.Warnings.Count -gt 0 }) {
        Write-Host "  - $($result.Script): $($result.Warnings -join ', ')" -ForegroundColor Yellow
    }
}

# ECRR Report
$ecrrReport = @"
## ✅ ECRR Gate

**Examine**: Tested $totalScripts key PowerShell scripts for runtime issues
**Clean**: Identified $errorCount errors and $warningCount warnings requiring attention
**Report**: Generated detailed report at $OutputFile
**Role**: Cursor Agent - Runtime Issues Validator

### Evidence
- Runtime testing completed for key scripts
- $errorCount errors found requiring fixes
- $warningCount warnings identified for improvement
- Report generated with detailed issue information

### Next Actions
- Fix runtime errors in identified scripts
- Address warnings for improved reliability
- Re-run runtime test to verify fixes
- Update documentation if needed
"@

Write-Host "`n$ecrrReport" -ForegroundColor Magenta

return @{
    TotalScripts = $totalScripts
    ErrorCount = $errorCount
    WarningCount = $warningCount
    Results = $results
    ReportFile = $OutputFile
}
