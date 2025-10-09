# Phase B.1: Migrate scripts → BRAV/SCPT with backward-compatible junction
# BossCat OEM - Tetragram Migration Kit

$ErrorActionPreference = "Stop"

Write-Host "🐾 BossCat Phase B.1: Scripts Migration" -ForegroundColor Magenta
Write-Host "=======================================" -ForegroundColor Magenta
Write-Host ""

# Find repo root
try {
    $RepoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $RepoRoot) { $RepoRoot = Get-Location }
} catch {
    $RepoRoot = Get-Location
}

Set-Location $RepoRoot

# Safety checks
if (-not (Test-Path "scripts")) {
    Write-Host "✅ scripts/ directory not found - may already be migrated" -ForegroundColor Green
    exit 0
}

$scriptsItem = Get-Item "scripts" -ErrorAction SilentlyContinue
if ($scriptsItem.LinkType -eq "Junction" -or $scriptsItem.Attributes -match "ReparsePoint") {
    Write-Host "⚠️  scripts/ is already a junction/symlink - skipping migration" -ForegroundColor Yellow
    exit 0
}

# Create BRAV/SCPT if it doesn't exist
New-Item -ItemType Directory -Path "BRAV\SCPT" -Force | Out-Null

Write-Host "📦 Moving script files..." -ForegroundColor Cyan

# Move scripts
if (Test-Path "scripts") {
    $scriptFiles = Get-ChildItem "scripts" -File | Where-Object { $_.Extension -in @('.ps1', '.sh', '.py', '.js') }
    
    if ($scriptFiles) {
        Write-Host "  Moving $($scriptFiles.Count) script files..." -ForegroundColor Gray
        foreach ($file in $scriptFiles) {
            Write-Host "    $($file.Name)" -ForegroundColor DarkGray
            Move-Item $file.FullName "BRAV\SCPT\" -Force
        }
    }
    
    # Move subdirectories
    $subDirs = Get-ChildItem "scripts" -Directory -ErrorAction SilentlyContinue
    if ($subDirs) {
        Write-Host "  Moving subdirectories..." -ForegroundColor Gray
        foreach ($dir in $subDirs) {
            Write-Host "    $($dir.Name)\" -ForegroundColor DarkGray
            Move-Item $dir.FullName "BRAV\SCPT\" -Force
        }
    }
    
    # Remove empty scripts directory
    $remaining = Get-ChildItem "scripts" -ErrorAction SilentlyContinue
    if (-not $remaining) {
        Remove-Item "scripts" -Force
        Write-Host "  Removed empty scripts/ directory" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "🔗 Creating backward-compatible directory junction..." -ForegroundColor Cyan

# Create junction on Windows (more reliable than symlink for directories)
try {
    cmd /c mklink /J "scripts" "BRAV\SCPT" | Out-Null
    Write-Host "  Created: scripts → BRAV\SCPT" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Failed to create junction. You may need administrator privileges." -ForegroundColor Yellow
    Write-Host "  Run as administrator or manually create junction:" -ForegroundColor Yellow
    Write-Host "    cmd /c mklink /J scripts BRAV\SCPT" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Phase B.1 complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review changes: git status" -ForegroundColor White
Write-Host "  2. Test key scripts still work via old paths" -ForegroundColor White
Write-Host "  3. Commit: git add -A; git commit -m 'chore(repo): move scripts → BRAV/SCPT with junction'" -ForegroundColor White
Write-Host "  4. Update references in workflows and docs over next 2 cycles" -ForegroundColor White
Write-Host "  5. Remove junction after validation: .\BRAV\SCPT\cleanup_shims.ps1" -ForegroundColor White
Write-Host ""

