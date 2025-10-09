# Cleanup junctions/shims after validation window (2+ green CI cycles)
# BossCat OEM - Tetragram Migration Kit

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "🐾 BossCat Shim Cleanup" -ForegroundColor Magenta
Write-Host "======================" -ForegroundColor Magenta
Write-Host ""
Write-Host "⚠️  WARNING: This will remove backward-compatibility junctions." -ForegroundColor Yellow
Write-Host "   Only proceed after 2+ successful CI/CD cycles with new paths." -ForegroundColor Yellow
Write-Host ""

# Find repo root
try {
    $RepoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $RepoRoot) { $RepoRoot = Get-Location }
} catch {
    $RepoRoot = Get-Location
}

Set-Location $RepoRoot

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - no changes will be made" -ForegroundColor Cyan
    Write-Host ""
}

# Function to remove junction/symlink
function Remove-Shim {
    param(
        [string]$Shim,
        [string]$Target
    )
    
    if (-not (Test-Path $Shim)) {
        return
    }
    
    $item = Get-Item $Shim -ErrorAction SilentlyContinue
    if (-not ($item.LinkType -eq "Junction" -or $item.Attributes -match "ReparsePoint")) {
        Write-Host "⚠️  $Shim exists but is not a junction/symlink - skipping" -ForegroundColor Yellow
        return
    }
    
    if ($DryRun) {
        Write-Host "🔍 Would remove: $Shim → $Target" -ForegroundColor Gray
    } else {
        Remove-Item $Shim -Force
        Write-Host "✅ Removed shim: $Shim" -ForegroundColor Green
    }
}

Write-Host "Checking for legacy shims..." -ForegroundColor Cyan
Write-Host ""

# Check and remove known shims/junctions
Remove-Shim "scripts" "BRAV\SCPT"
Remove-Shim "config" "DELT\CONF\config"
Remove-Shim "configs" "DELT\CONF\configs"
Remove-Shim "docker" "BRAV\DOCK\legacy"
Remove-Shim "helm" "BRAV\INFR\helm"
Remove-Shim "deployment-pipeline" "BRAV\INFR\deployment-pipeline"
Remove-Shim "artifacts" "CHAR\EVID\artifacts"
Remove-Shim "reports" "CHAR\EVID\reports"
Remove-Shim "playwright-report" "CHAR\EVID\playwright-report"
Remove-Shim "assets" "DELT\ASST\assets"
Remove-Shim "baseline" "DELT\FIXT\baseline"
Remove-Shim "test-payloads" "DELT\FIXT\test-payloads"
Remove-Shim "templates" "DELT\TMPL\templates"

Write-Host ""

if ($DryRun) {
    Write-Host "🔍 Dry run complete. Re-run without -DryRun to apply changes." -ForegroundColor Cyan
} else {
    Write-Host "✅ Shim cleanup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Verify CI/CD still passes: git push" -ForegroundColor White
    Write-Host "  2. Check for any remaining legacy path references" -ForegroundColor White
    Write-Host "  3. Commit: git add -A; git commit -m 'chore(repo): remove legacy junctions after validation'" -ForegroundColor White
}

Write-Host ""

