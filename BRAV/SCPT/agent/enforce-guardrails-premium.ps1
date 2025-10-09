param(
    [switch]$ReportOnly = $true,
    [switch]$Fix,
    [switch]$Quiet,
    [switch]$Json,
    [int]$MaxFiles = 10,
    [int]$MaxLines = 200
)

$ErrorActionPreference = "Stop"

# Import utilities
. "$PSScriptRoot\utils\terminal.ps1"
. "$PSScriptRoot\utils\progress.ps1"
. "$PSScriptRoot\utils\logging.ps1"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

# Initialize terminal cleanup
Initialize-TerminalCleanup

function Write-FinalResult {
    param([hashtable]$Results)
    
    if ($Json) {
        $Results | ConvertTo-Json -Depth 6
        return
    }
    
    if ($Quiet) {
        $status = if ($Results.violations -eq 0) { "PASS" } else { "FAIL" }
        Write-Host "$status - $($Results.violations) violations found"
        exit $Results.exitCode
    }
    
    Write-Colored -Message "Guardrails report written to .agent/guardrails_report.json" -Color "green"
    Write-Colored -Message "Violations found: $($Results.violations)" -Color $(if ($Results.violations -eq 0) { "green" } else { "yellow" })
}

# Initialize results
$results = @{
    violations = 0
    filesProcessed = 0
    filesModified = 0
    linesChanged = 0
    exitCode = 0
    items = @()
    needsFollowup = @()
}

$files = Get-ChildItem -Recurse -File -Include *.html,*.htm,*.js,*.jsx,*.ts,*.tsx | `
         Where-Object { $_.FullName -notmatch "\\node_modules\\" }

$patterns = @(
    @{ id="inline-style-html"; desc="Inline style attributes"; rx='(?is)<[^>]+\sstyle\s*=\s*"[^"]*"' },
    @{ id="inline-style-jsx";  desc="JSX style prop";        rx='(?s)\bstyle\s*=\s*{{.*?}}' },
    @{ id="dangerouslySetInnerHTML"; desc="dangerouslySetInnerHTML usage"; rx='dangerouslySetInnerHTML\s*=' },
    @{ id="img-missing-alt"; desc="IMG missing alt"; rx='(?is)<img(?![^>]*\balt\s*=)[^>]*>' },
    @{ id="btn-no-name"; desc="BUTTON w/out accessible name/label"; rx='(?is)<button(?![^>]*(aria-label|aria-labelledby|title)=)[^>]*>\s*(?:</button>|<\s*/button\s*>)' },
    @{ id="input-unlabeled"; desc="INPUT missing label/aria"; rx='(?is)<input(?![^>]*(id=|name=|aria-label=|aria-labelledby=|title=|placeholder=))[^>]*>' }
)

if (-not $Quiet) {
    if (-not $Json) {
        Write-Colored -Message "[GUARDRAILS] Scanning $($files.Count) files for violations..." -Color "cyan"
    }
}

$scanStartTime = Get-Date
$processedFiles = 0

foreach ($f in $files) {
    $processedFiles++
    $results.filesProcessed++
    
    # Show progress
    if (-not $Quiet) {
        $percent = [Math]::Round(($processedFiles / $files.Count) * 100)
        if (-not $Json) {
            Show-EnhancedProgress -Activity "Guardrail Scan" -Status "Processing files" -Current $processedFiles -Total $files.Count -SubStatus $f.Name
        }
    }
    
    # Check budget limits
    if ($Fix -and -not $ReportOnly) {
        if (-not (Test-BudgetLimit -Current $results.filesModified -Limit $MaxFiles -Type "files")) {
            $results.needsFollowup += "File budget exceeded ($results.filesModified/$MaxFiles). Remaining files need manual review."
            break
        }
        
        if (-not (Test-BudgetLimit -Current $results.linesChanged -Limit $MaxLines -Type "lines")) {
            $results.needsFollowup += "Line budget exceeded ($results.linesChanged/$MaxLines). Remaining changes need manual review."
            break
        }
    }
    
    $text = Get-Content $f.FullName -Raw
    $originalText = $text
    $fileViolations = 0
    
    foreach ($p in $patterns) {
        $matches = [regex]::Matches($text, $p.rx)
        foreach ($m in $matches) {
            $lineNum = ($text.Substring(0, $m.Index) -split "`n").Count
            $violation = [pscustomobject]@{
                file = $f.FullName
                id   = $p.id
                desc = $p.desc
                line = $lineNum
                excerpt = $text.Substring($m.Index, [Math]::Min(120, $m.Length)).Replace("`r"," ").Replace("`n"," ")
            }
            $results.items += $violation
            $fileViolations++
            $results.violations++
        }
    }

    if ($Fix -and -not $ReportOnly) {
        $fixed = $false
        $linesAdded = 0
        
        # Safe autofixes only
        # 1) img missing alt -> add alt=""
        $text2 = $text -replace '(?is)<img(?![^>]*\balt\s*=)([^>]*)>', '<img alt=""$1>'
        if ($text2 -ne $text) { 
            $fixed = $true
            $text = $text2
            $linesAdded++
            Add-TaskLog -Message "Added alt=\"\" to <img> in $($f.Name)"
        }

        # 2) empty/unnamed buttons -> add aria-label="TODO"
        $text2 = $text -replace '(?is)<button((?:(?!>).)*)>(\s*)</button>', '<button aria-label="TODO"$1>$2</button>'
        if ($text2 -ne $text) { 
            $fixed = $true
            $text = $text2
            $linesAdded++
            Add-TaskLog -Message "Added aria-label to empty <button> in $($f.Name)"
        }

        # 3) inputs without label/aria -> add aria-label="TODO"
        $text2 = $text -replace '(?is)<input(?![^>]*(aria-label|aria-labelledby|title|placeholder|name|id)=)([^>]*)>', '<input aria-label="TODO"$2>'
        if ($text2 -ne $text) { 
            $fixed = $true
            $text = $text2
            $linesAdded++
            Add-TaskLog -Message "Added aria-label to <input> in $($f.Name)"
        }

        if ($fixed) {
            Set-Content -Path $f.FullName -Value $text -Encoding UTF8
            $results.filesModified++
            $results.linesChanged += $linesAdded
            
            # Show budget warning
            Show-BudgetWarning -Current $results.filesModified -Limit $MaxFiles -Type "files"
            Show-BudgetWarning -Current $results.linesChanged -Limit $MaxLines -Type "lines"
            
            if (-not $Quiet) {
                Write-Colored -Message "✓ Fixed $linesAdded violations in $($f.Name)" -Color "green"
            }
        }
    }
    
    if ($fileViolations -gt 0 -and -not $Quiet) {
        Write-Colored -Message "⚠️  $fileViolations violations in $($f.Name)" -Color "yellow"
    }
}

# Update EMA
$scanDuration = ((Get-Date) - $scanStartTime).TotalSeconds
Update-EmaOnCompletion -EmaKey "guardrailsSecs" -ObservedSeconds $scanDuration

# Write JSON report
$report = [pscustomobject]@{
    generatedAt = (Get-Date).ToString("o")
    summary = @{
        violations = $results.violations
        filesProcessed = $results.filesProcessed
        filesModified = $results.filesModified
        linesChanged = $results.linesChanged
        duration = $scanDuration
    }
    counts = ($results.items | Group-Object id | ForEach-Object { @{($_.Name) = $_.Count} } | `
             ForEach-Object { $_ }) -join "; "
    items = $results.items
    needsFollowup = $results.needsFollowup
}

$reportJson = $report | ConvertTo-Json -Depth 6
Write-RateLimitedJson -Path ".agent/guardrails_report.json" -Data $report

# Log results
if ($results.violations -gt 0) {
    Add-TaskLog -Message "Guardrail scan found $($results.violations) violations. See .agent/guardrails_report.json" -Level "WARN"
}

if ($results.needsFollowup.Count -gt 0) {
    foreach ($followup in $results.needsFollowup) {
        Add-TaskLog -Message "Follow-up needed: $followup" -Level "INFO"
    }
}

# Set exit code
if ($results.violations -gt 0) {
    $results.exitCode = 1
}

Write-FinalResult -Results $results
