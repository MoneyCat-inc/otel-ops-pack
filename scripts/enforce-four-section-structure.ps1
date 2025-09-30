# Enforce 4-Section Structure on ECRR Reports (with dry-run)
param(
    [switch]$DryRun = $true,
    [string]$EcrrDir = "docs/ECRR_REPORTS"
)

$ErrorActionPreference = "Stop"

Write-Host "Enforcing 4-section structure (DryRun=$DryRun)" -ForegroundColor Cyan

$files = Get-ChildItem -Path $EcrrDir -Filter "*.md" -File | Where-Object { $_.Name -notlike "ECRR_*" -and $_.Name -notlike "workshop-*" }

function Ensure-Section {
    param(
        [string]$Content,
        [string]$SectionHeader,
        [string]$Template
    )
    if ($Content -notmatch [regex]::Escape($SectionHeader)) {
        return $Content.TrimEnd() + "`r`n`r`n" + $Template + "`r`n"
    }
    return $Content
}

$updated = 0
foreach ($f in $files) {
    $path = $f.FullName
    $content = Get-Content -Path $path -Raw -Encoding UTF8

    $examineTemplate = @("## 🔍 **1. Examine**","- State: ","- Evidence: ") -join "`r`n"
    $cleanTemplate   = @("## 🧹 **2. Clean**","- Changes: ","- Guardrails: ") -join "`r`n"
    $reportTemplate  = @("## 📝 **3. Report**","- Actions: ","- Results: ") -join "`r`n"
    $roleTemplate    = @("## 🎭 **4. Role**","- Actor: ","- Scope: ") -join "`r`n"

    $newContent = $content
    $newContent = Ensure-Section -Content $newContent -SectionHeader "## 🔍 **1. Examine" -Template $examineTemplate
    $newContent = Ensure-Section -Content $newContent -SectionHeader "## 🧹 **2. Clean"   -Template $cleanTemplate
    $newContent = Ensure-Section -Content $newContent -SectionHeader "## 📝 **3. Report"  -Template $reportTemplate
    $newContent = Ensure-Section -Content $newContent -SectionHeader "## 🎭 **4. Role"    -Template $roleTemplate

    if ($newContent -ne $content) {
        if ($DryRun) {
            Write-Host "DRY-RUN: Would enforce 4-section structure in $($f.Name)" -ForegroundColor DarkCyan
        } else {
            $newContent | Set-Content -Path $path -Encoding UTF8
            $updated++
            Write-Host "Updated: $($f.Name)" -ForegroundColor Green
        }
    }
}

Write-Host "Completed. Files updated: $updated" -ForegroundColor Green
