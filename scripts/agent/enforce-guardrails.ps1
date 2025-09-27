# scripts/agent/enforce-guardrails.ps1
# codex-local Local Workflow Custodian - Guardrail enforcement script
# This script enforces security, accessibility, and code quality guardrails

[CmdletBinding()]
param(
    [switch]$Fix,
    [switch]$ReportOnly,
    [string[]]$FilePatterns = @("*.html", "*.jsx", "*.tsx", "*.js", "*.ts")
)

$ErrorActionPreference = "Stop"

Write-Host "[enforce-guardrails] codex-local Guardrail Enforcement" -ForegroundColor Cyan
Write-Host "[enforce-guardrails] ==========================================================" -ForegroundColor Cyan

# Load configuration
$configPath = ".agent/config.json"
$config = @{}
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "[enforce-guardrails] ⚠ Error reading configuration, using defaults" -ForegroundColor Yellow
    }
}

# Initialize violation tracking
$violations = @{
    inline_styles = @()
    csp_violations = @()
    a11y_violations = @()
    security_violations = @()
}

$totalViolations = 0
$filesProcessed = 0

Write-Host "[enforce-guardrails] Scanning files for guardrail violations..." -ForegroundColor Yellow

# Find files to scan
$filesToScan = @()
foreach ($pattern in $FilePatterns) {
    $files = Get-ChildItem -Recurse -Include $pattern | Where-Object { 
        $_.FullName -notmatch "node_modules|\.git|third_party|\.agent" 
    }
    $filesToScan += $files
}

$filesToScan = $filesToScan | Sort-Object FullName | Get-Unique
Write-Host "[enforce-guardrails] Found $($filesToScan.Count) files to scan" -ForegroundColor White

foreach ($file in $filesToScan) {
    $filesProcessed++
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $fileViolations = 0
    
    Write-Host "[enforce-guardrails] Scanning: $($file.Name)" -ForegroundColor Gray
    
    # 1. Check for inline styles
    if ($config.guardrails.enforce_no_inline_styles -ne $false) {
        $inlineStyleMatches = [regex]::Matches($content, 'style\s*=\s*["'']*["'']')
        foreach ($match in $inlineStyleMatches) {
            $violation = @{
                file = $file.FullName
                line = ($content.Substring(0, $match.Index) -split "`n").Count
                column = $match.Index - ($content.Substring(0, $match.Index).LastIndexOf("`n"))
                message = "Inline style detected: $($match.Value)"
                severity = "error"
            }
            $violations.inline_styles += $violation
            $fileViolations++
            
            if ($Fix -and -not $ReportOnly) {
                # Replace inline style with CSS class
                $styleValue = $match.Groups[1].Value
                $className = "style-$(Get-Random -Minimum 1000 -Maximum 9999)"
                $content = $content -replace [regex]::Escape($match.Value), "class=`"$className`""
                
                # Add CSS rule to a stylesheet (placeholder)
                Write-Host "[enforce-guardrails] ⚠ Inline style replaced with class $className (manual CSS addition required)" -ForegroundColor Yellow
            }
        }
    }
    
    # 2. Check for dangerouslySetInnerHTML
    if ($config.guardrails.enforce_no_inline_styles -ne $false) {
        $dangerousMatches = [regex]::Matches($content, 'dangerouslySetInnerHTML\s*=\s*\{[^}]*\}')
        foreach ($match in $dangerousMatches) {
            $violation = @{
                file = $file.FullName
                line = ($content.Substring(0, $match.Index) -split "`n").Count
                column = $match.Index - ($content.Substring(0, $match.Index).LastIndexOf("`n"))
                message = "dangerouslySetInnerHTML usage detected: $($match.Value)"
                severity = "error"
            }
            $violations.security_violations += $violation
            $fileViolations++
            
            if ($Fix -and -not $ReportOnly) {
                Write-Host "[enforce-guardrails] ⚠ dangerouslySetInnerHTML usage requires manual review for security implications" -ForegroundColor Yellow
            }
        }
    }
    
    # 3. Accessibility checks
    if ($config.guardrails.enforce_aria_compliance -ne $false) {
        # Check for images without alt text
        $imageMatches = [regex]::Matches($content, '<img(?![^>]*alt\s*=\s*["'']*["''])[^>]*>')
        foreach ($match in $imageMatches) {
            $violation = @{
                file = $file.FullName
                line = ($content.Substring(0, $match.Index) -split "`n").Count
                column = $match.Index - ($content.Substring(0, $match.Index).LastIndexOf("`n"))
                message = "Image without alt text: $($match.Value)"
                severity = "warning"
            }
            $violations.a11y_violations += $violation
            $fileViolations++
            
            if ($Fix -and -not $ReportOnly) {
                # Add alt attribute
                $imgTag = $match.Value
                $newImgTag = $imgTag -replace '(<img[^>]*?)(\s*/?>)', '$1 alt="Image"$2'
                $content = $content -replace [regex]::Escape($imgTag), $newImgTag
                Write-Host "[enforce-guardrails] ✓ Added alt attribute to image" -ForegroundColor Green
            }
        }
        
        # Check for buttons without accessible text
        $buttonMatches = [regex]::Matches($content, '<button(?![^>]*(?:aria-label|aria-labelledby))[^>]*>\s*(?:<[^>]*>\s*)*</button>')
        foreach ($match in $buttonMatches) {
            $violation = @{
                file = $file.FullName
                line = ($content.Substring(0, $match.Index) -split "`n").Count
                column = $match.Index - ($content.Substring(0, $match.Index).LastIndexOf("`n"))
                message = "Button without accessible text: $($match.Value)"
                severity = "warning"
            }
            $violations.a11y_violations += $violation
            $fileViolations++
            
            if ($Fix -and -not $ReportOnly) {
                # Add aria-label
                $buttonTag = $match.Value
                $newButtonTag = $buttonTag -replace '(<button[^>]*?)(\s*/?>)', '$1 aria-label="Button"$2'
                $content = $content -replace [regex]::Escape($buttonTag), $newButtonTag
                Write-Host "[enforce-guardrails] ✓ Added aria-label to button" -ForegroundColor Green
            }
        }
        
        # Check for form inputs without labels
        $inputMatches = [regex]::Matches($content, '<input(?![^>]*(?:aria-label|aria-labelledby|id\s*=\s*["'']*["'']))[^>]*>')
        foreach ($match in $inputMatches) {
            $violation = @{
                file = $file.FullName
                line = ($content.Substring(0, $match.Index) -split "`n").Count
                column = $match.Index - ($content.Substring(0, $match.Index).LastIndexOf("`n"))
                message = "Input without label or aria-label: $($match.Value)"
                severity = "warning"
            }
            $violations.a11y_violations += $violation
            $fileViolations++
            
            if ($Fix -and -not $ReportOnly) {
                # Add aria-label
                $inputTag = $match.Value
                $newInputTag = $inputTag -replace '(<input[^>]*?)(\s*/?>)', '$1 aria-label="Input"$2'
                $content = $content -replace [regex]::Escape($inputTag), $newInputTag
                Write-Host "[enforce-guardrails] ✓ Added aria-label to input" -ForegroundColor Green
            }
        }
    }
    
    # 4. CSP-related checks
    if ($config.guardrails.enforce_csp_strict -ne $false) {
        # Check for inline event handlers
        $inlineEventMatches = [regex]::Matches($content, '\s(on\w+)\s*=\s*["'']*["'']')
        foreach ($match in $inlineEventMatches) {
            $violation = @{
                file = $file.FullName
                line = ($content.Substring(0, $match.Index) -split "`n").Count
                column = $match.Index - ($content.Substring(0, $match.Index).LastIndexOf("`n"))
                message = "Inline event handler detected: $($match.Groups[1].Value)"
                severity = "warning"
            }
            $violations.csp_violations += $violation
            $fileViolations++
        }
        
        # Check for inline scripts
        $inlineScriptMatches = [regex]::Matches($content, '<script(?![^>]*src\s*=\s*["'']*["''])[^>]*>')
        foreach ($match in $inlineScriptMatches) {
            $violation = @{
                file = $file.FullName
                line = ($content.Substring(0, $match.Index) -split "`n").Count
                column = $match.Index - ($content.Substring(0, $match.Index).LastIndexOf("`n"))
                message = "Inline script detected (should use external file)"
                severity = "warning"
            }
            $violations.csp_violations += $violation
            $fileViolations++
        }
    }
    
    # Save file if modifications were made
    if ($content -ne $originalContent -and $Fix -and -not $ReportOnly) {
        try {
            $content | Set-Content $file.FullName -Encoding UTF8
            Write-Host "[enforce-guardrails] ✓ File updated: $($file.Name)" -ForegroundColor Green
        } catch {
            Write-Host "[enforce-guardrails] ✗ Error updating file $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    $totalViolations += $fileViolations
    if ($fileViolations -gt 0) {
        Write-Host "[enforce-guardrails] ⚠ $fileViolations violations in $($file.Name)" -ForegroundColor Yellow
    }
}

# Generate report
Write-Host "[enforce-guardrails] ==========================================================" -ForegroundColor Cyan
Write-Host "[enforce-guardrails] GUARDRAIL ENFORCEMENT REPORT" -ForegroundColor Cyan
Write-Host "[enforce-guardrails] ==========================================================" -ForegroundColor Cyan

Write-Host "[enforce-guardrails] Files processed: $filesProcessed" -ForegroundColor White
Write-Host "[enforce-guardrails] Total violations: $totalViolations" -ForegroundColor $(if ($totalViolations -eq 0) { "Green" } else { "Yellow" })

# Detailed violation breakdown
if ($violations.inline_styles.Count -gt 0) {
    Write-Host "[enforce-guardrails] Inline Style Violations: $($violations.inline_styles.Count)" -ForegroundColor Red
    foreach ($violation in $violations.inline_styles) {
        Write-Host "[enforce-guardrails]   $($violation.file):$($violation.line) - $($violation.message)" -ForegroundColor Yellow
    }
}

if ($violations.csp_violations.Count -gt 0) {
    Write-Host "[enforce-guardrails] CSP Violations: $($violations.csp_violations.Count)" -ForegroundColor Red
    foreach ($violation in $violations.csp_violations) {
        Write-Host "[enforce-guardrails]   $($violation.file):$($violation.line) - $($violation.message)" -ForegroundColor Yellow
    }
}

if ($violations.a11y_violations.Count -gt 0) {
    Write-Host "[enforce-guardrails] Accessibility Violations: $($violations.a11y_violations.Count)" -ForegroundColor Red
    foreach ($violation in $violations.a11y_violations) {
        Write-Host "[enforce-guardrails]   $($violation.file):$($violation.line) - $($violation.message)" -ForegroundColor Yellow
    }
}

if ($violations.security_violations.Count -gt 0) {
    Write-Host "[enforce-guardrails] Security Violations: $($violations.security_violations.Count)" -ForegroundColor Red
    foreach ($violation in $violations.security_violations) {
        Write-Host "[enforce-guardrails]   $($violation.file):$($violation.line) - $($violation.message)" -ForegroundColor Yellow
    }
}

# Overall status
$overallStatus = if ($totalViolations -eq 0) { "PASS" } else { "FAIL" }
$statusColor = if ($overallStatus -eq "PASS") { "Green" } else { "Red" }

Write-Host "[enforce-guardrails] ==========================================================" -ForegroundColor Cyan
Write-Host "[enforce-guardrails] OVERALL STATUS: $overallStatus" -ForegroundColor $statusColor
Write-Host "[enforce-guardrails] ==========================================================" -ForegroundColor Cyan

# Update agent status
try {
    pwsh -File scripts/agent/update-status.ps1 -section guardrails -ok ($overallStatus -eq "PASS") -detail "Guardrails: $overallStatus ($totalViolations violations)"
} catch {
    Write-Host "[enforce-guardrails] ⚠ Status update failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Log enforcement completion
$logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') – Guardrail enforcement completed: $overallStatus ($totalViolations violations)"
if (Test-Path "TASKS.md") {
    $logEntry | Add-Content "TASKS.md"
}

# Exit with appropriate code
if ($overallStatus -eq "FAIL") {
    exit 1
} else {
    exit 0
}
