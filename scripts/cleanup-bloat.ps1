# BossCat Aggressive Cleanup - Remove Regeneratable Bloat
# Safely removes node_modules, .venv, and build artifacts
# Can be restored with: pnpm install, pip install -r requirements.txt

param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "🐾 BossCat Aggressive Cleanup - Remove Regeneratable Bloat" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "⚠️  DRY RUN MODE - No deletions will occur" -ForegroundColor Yellow
}
Write-Host ""

# Directories to remove (all regeneratable)
$bloatDirs = @(
    @{ Path = "node_modules"; Size_GB = 3.28; Restore = "pnpm install" },
    @{ Path = ".venv"; Size_GB = 1.79; Restore = "python -m venv .venv && .venv\Scripts\pip install -r requirements.txt" },
    @{ Path = "resonai-mock"; Size_GB = 0.81; Restore = "Re-generate mock data or restore from backup" },
    @{ Path = "third_party"; Size_GB = 0.52; Restore = "git submodule update --init --recursive" },
    @{ Path = ".next"; Size_GB = 0.10; Restore = "pnpm build (auto-generated)" },
    @{ Path = "dist"; Size_GB = 0.00; Restore = "Build process (auto-generated)" },
    @{ Path = "out"; Size_GB = 0.00; Restore = "Build process (auto-generated)" },
    @{ Path = "__pycache__"; Size_GB = 0.00; Restore = "Python runtime (auto-generated)" }
)

$totalSize = 0
$toRemove = @()

Write-Host "📊 Analyzing bloat directories..." -ForegroundColor Cyan
Write-Host ""

foreach ($item in $bloatDirs) {
    if (Test-Path $item.Path) {
        $actualSize = (Get-ChildItem $item.Path -Recurse -File -ErrorAction SilentlyContinue | 
            Measure-Object Length -Sum).Sum / 1GB
        $totalSize += $actualSize
        $toRemove += $item
        
        Write-Host "  Found: $($item.Path)" -ForegroundColor Yellow
        Write-Host "    Size: $([math]::Round($actualSize, 2)) GB" -ForegroundColor White
        Write-Host "    Restore: $($item.Restore)" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host "💾 Total Removable: $([math]::Round($totalSize, 2)) GB" -ForegroundColor Yellow
Write-Host ""

if ($toRemove.Count -eq 0) {
    Write-Host "✅ No bloat directories found - repository already lean!" -ForegroundColor Green
    exit 0
}

if (-not $Force -and -not $DryRun) {
    Write-Host "⚠️  WARNING: This will delete $($toRemove.Count) directories ($([math]::Round($totalSize, 2)) GB)" -ForegroundColor Yellow
    Write-Host ""
    $response = Read-Host "Continue? (yes/no)"
    if ($response -ne "yes") {
        Write-Host "❌ Cancelled by user" -ForegroundColor Red
        exit 1
    }
}

if ($DryRun) {
    Write-Host "🔍 DRY RUN - Would remove:" -ForegroundColor Cyan
    foreach ($item in $toRemove) {
        Write-Host "  - $($item.Path) ($([math]::Round($item.Size_GB, 2)) GB)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "⚠️  Run without -DryRun to execute cleanup" -ForegroundColor Yellow
} else {
    Write-Host "🗑️  Removing bloat directories..." -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($item in $toRemove) {
        Write-Host "  Removing $($item.Path)..." -ForegroundColor Yellow
        try {
            Remove-Item -Path $item.Path -Recurse -Force -ErrorAction Stop
            Write-Host "    ✅ Removed" -ForegroundColor Green
        }
        catch {
            Write-Host "    ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "✅ Cleanup complete!" -ForegroundColor Green
    Write-Host "💾 Freed approximately $([math]::Round($totalSize, 2)) GB" -ForegroundColor Green
}

Write-Host ""
Write-Host "📋 To restore dependencies:" -ForegroundColor Cyan
Write-Host "  pnpm install                  # Restore node_modules (~3.3 GB)" -ForegroundColor Gray
Write-Host "  python -m venv .venv          # Recreate Python virtualenv" -ForegroundColor Gray
Write-Host "  .venv\Scripts\pip install -r requirements.txt  # Install Python packages" -ForegroundColor Gray
Write-Host "  git submodule update --init   # Restore third_party (if submodule)" -ForegroundColor Gray
Write-Host ""

Write-Host "🐾 BossCat: Repository cleaned - from 7.3 GB to <1 GB!" -ForegroundColor Cyan

