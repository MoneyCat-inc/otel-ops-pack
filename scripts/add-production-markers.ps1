# Add Production Readiness Markers to ECRR Reports (with dry-run)
param(
    [switch]$DryRun = $true,
    [string]$EcrrDir = "docs/ECRR_REPORTS"
)

$ErrorActionPreference = "Stop"

Write-Host "Adding Production Readiness markers (DryRun=$DryRun)" -ForegroundColor Cyan

$files = Get-ChildItem -Path $EcrrDir -Filter "*.md" -File | Where-Object { $_.Name -notlike "ECRR_*" -and $_.Name -notlike "workshop-*" }

$updated = 0
foreach ($f in $files) {
    $path = $f.FullName
    $content = Get-Content -Path $path -Raw -Encoding UTF8

    if ($content -match "Production\s*Ready" -or $content -match "Production\s*Readiness") { continue }

    $marker = @()
    $marker += ""
    $marker += "## 🏁 Production Readiness"
    $marker += "- Status: Pending (add ✅ Ready / ❌ Not Ready)"
    $marker += "- Risks: (list known risks)"
    $marker += "- Verification: (link to checks/evidence)"

    $newContent = $content.TrimEnd() + "`r`n" + ($marker -join "`r`n") + "`r`n"

    if ($DryRun) {
        Write-Host "DRY-RUN: Would add Production Readiness section to $($f.Name)" -ForegroundColor DarkCyan
    } else {
        $newContent | Set-Content -Path $path -Encoding UTF8
        $updated++
        Write-Host "Updated: $($f.Name)" -ForegroundColor Green
    }
}

Write-Host "Completed. Files updated: $updated" -ForegroundColor Green
