param(
    [string]$ReportsPath = "CHAR/ECRR/ECRR_REPORTS",
    [switch]$DryRun = $true
)

$ErrorActionPreference = 'Stop'

Write-Host "== Backfilling ECRR Gate sections ==" -ForegroundColor Cyan
Write-Host "ReportsPath: $ReportsPath | DryRun: $DryRun"

$files = Get-ChildItem -Path $ReportsPath -Recurse -Filter *.md | Where-Object {
    $_.FullName -notmatch '(/|\\)(archive|backup)(/|\\)' -and $_.Name -notmatch '^\.(gitkeep|DS_Store)$'
}

$gateTemplate = @"
## ECRR Gate

### Examine
- Facts:
- Evidence:

### Clean
- Actions:
- Guardrails:

### Report
- Artifacts:
- Verification:

### Role
- Actor:
- Scope:

---
"@

$updated = 0
$skipped = 0
$errors = 0

$gatePattern = '(?im)^##\s+(\*\*ECRR Gate\*\*|ECRR Gate)(\s|$)'

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    if ($content -match $gatePattern) {
        $skipped++
        continue
    }

    $newContent = ($content.TrimEnd() + "`r`n`r`n" + $gateTemplate.TrimEnd() + "`r`n")
    if ($DryRun) {
        Write-Host "[DRY RUN] Would add ECRR Gate -> $($file.Name)"
        continue
    }

    try {
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
        $updated++
        Write-Host "[UPDATED] Added ECRR Gate -> $($file.Name)" -ForegroundColor Green
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

