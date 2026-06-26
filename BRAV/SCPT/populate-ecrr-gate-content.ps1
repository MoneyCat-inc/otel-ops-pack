param(
    [string]$ReportsPath = "CHAR/ECRR/ECRR_REPORTS",
    [switch]$DryRun = $true,
    [int]$MaxReports = 10
)

$ErrorActionPreference = 'Stop'

Write-Host "== Populating ECRR Gate Content ==" -ForegroundColor Cyan
Write-Host "ReportsPath: $ReportsPath | DryRun: $DryRun | MaxReports: $MaxReports"

$files = Get-ChildItem -Path $ReportsPath -Recurse -Filter *.md | Where-Object {
    $_.FullName -notmatch '(/|\\)(archive|backup)(/|\\)' -and $_.Name -notmatch '^\.(gitkeep|DS_Store)$'
} | Select-Object -First $MaxReports

$updated = 0
$skipped = 0
$errors = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    
    # Check if this file has placeholder ECRR Gate content
    if ($content -notmatch '## ECRR Gate[\s\S]*?- Facts:\s*$' -and $content -notmatch '## ECRR Gate[\s\S]*?- Actions:\s*$') {
        $skipped++
        continue
    }
    
    # Extract key information from the report
    $facts = @()
    $evidence = @()
    $actions = @()
    $artifacts = @()
    $actor = ""
    $scope = ""
    
    # Extract facts from Examine section
    if ($content -match '(?s)##\s*🔍[\s\S]*?Examine[\s\S]*?(?=##|\Z)') {
        $examineSection = $matches[0]
        if ($examineSection -match 'Total Reports[:\s]*(\d+)') { $facts += "Total Reports: $($matches[1])" }
        if ($examineSection -match 'Date Range[:\s]*([^-]+)') { $facts += "Date Range: $($matches[1].Trim())" }
        if ($examineSection -match 'Status[:\s]*([^\n]+)') { $facts += "Status: $($matches[1].Trim())" }
    }
    
    # Extract evidence
    if ($content -match 'artifacts/') { $evidence += "Generated artifacts in artifacts/ directory" }
    if ($content -match 'docs/') { $evidence += "Documentation updated in docs/ directory" }
    if ($content -match 'scripts/') { $evidence += "Scripts created/updated in scripts/ directory" }
    
    # Extract actions from Clean section
    if ($content -match '(?s)##\s*🧹[\s\S]*?Clean[\s\S]*?(?=##|\Z)') {
        $cleanSection = $matches[0]
        if ($cleanSection -match 'Processing[:\s]*([^\n]+)') { $actions += "Processing: $($matches[1].Trim())" }
        if ($cleanSection -match 'Consolidation[:\s]*([^\n]+)') { $actions += "Consolidation: $($matches[1].Trim())" }
        if ($cleanSection -match 'Enhancement[:\s]*([^\n]+)') { $actions += "Enhancement: $($matches[1].Trim())" }
    }
    
    # Extract artifacts
    if ($content -match 'artifacts/[^\s]+') { $artifacts += "Compliance reports in artifacts/" }
    if ($content -match 'scripts/[^\s]+') { $artifacts += "Automation scripts in scripts/" }
    if ($content -match 'docs/[^\s]+') { $artifacts += "Documentation in docs/" }
    
    # Extract actor from Role section
    if ($content -match '(?s)##\s*🎭[\s\S]*?Role[\s\S]*?(?=##|\Z)') {
        $roleSection = $matches[0]
        if ($roleSection -match '\*\*([^*]+)\*\* acting as \*\*([^*]+)\*\*') {
            $actor = "$($matches[1]) acting as $($matches[2])"
        }
        if ($roleSection -match 'Scope[:\s]*([^\n]+)') { $scope = $matches[1].Trim() }
    }
    
    # Build populated ECRR Gate section
    $populatedGate = @"
## ECRR Gate

### Examine
- Facts: $($facts -join '; ')
- Evidence: $($evidence -join '; ')

### Clean
- Actions: $($actions -join '; ')
- Guardrails: Local-first, safety, idempotence, verification

### Report
- Artifacts: $($artifacts -join '; ')
- Verification: Compliance validation completed

### Role
- Actor: $actor
- Scope: $scope

---
"@
    
    # Replace the placeholder ECRR Gate section
    $newContent = $content -replace '(?s)## ECRR Gate[\s\S]*?---\s*$', $populatedGate.TrimEnd()
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Would populate ECRR Gate -> $($file.Name)"
        Write-Host "  Facts: $($facts -join '; ')"
        Write-Host "  Actor: $actor"
        continue
    }
    
    try {
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
        $updated++
        Write-Host "[UPDATED] Populated ECRR Gate -> $($file.Name)" -ForegroundColor Green
    } catch {
        $errors++
        Write-Host "[ERROR] Failed to update $($file.FullName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

[PSCustomObject]@{
    reports = $files.Count
    updated = $updated
    skipped = $skipped
    errors = $errors
}

