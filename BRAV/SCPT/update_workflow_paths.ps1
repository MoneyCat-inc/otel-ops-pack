# Update GitHub workflows to use BRAV/SCPT paths
# BossCat OEM - Phase B.1 cleanup

$ErrorActionPreference = "Stop"

Write-Host "🐾 BossCat: Updating workflow paths scripts/ → BRAV/SCPT/" -ForegroundColor Magenta
Write-Host ""

$updated = 0
$workflows = Get-ChildItem .github\workflows\*.yml -ErrorAction SilentlyContinue

if (-not $workflows) {
    Write-Host "✅ No workflows found to update" -ForegroundColor Green
    exit 0
}

foreach ($workflow in $workflows) {
    $content = Get-Content $workflow.FullName -Raw
    $original = $content
    
    # Replace scripts/ references (preserve spacing)
    $content = $content -replace '(\s|^)(scripts/)', '$1BRAV/SCPT/'
    
    if ($content -ne $original) {
        Set-Content $workflow.FullName $content -NoNewline
        Write-Host "  ✅ Updated: $($workflow.Name)" -ForegroundColor Green
        $updated++
    }
}

Write-Host ""
if ($updated -gt 0) {
    Write-Host "✅ Updated $updated workflow(s)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Review changes: git diff .github/workflows/" -ForegroundColor White
    Write-Host "  2. Commit: git add .github/workflows/" -ForegroundColor White
    Write-Host "  3. git commit -m 'ci(workflows): update paths scripts/ → BRAV/SCPT/'" -ForegroundColor White
} else {
    Write-Host "✅ No workflow updates needed" -ForegroundColor Green
}

