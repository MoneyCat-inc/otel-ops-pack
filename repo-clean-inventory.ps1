# Repository Clean Inventory Script
# Monthly dry-run to confirm no drift and rotate old files

Write-Host "Repository Clean Inventory - Monthly Check" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Check for files that shouldn't be in repo
Write-Host "`nChecking for unwanted files..." -ForegroundColor Yellow
$unwanted = Get-ChildItem -Recurse -File | Where-Object {
    $_.Name -match '\.(bak|tmp|log|zip|sha256)$' -or
    $_.Name -match '\.last\.' -or
    $_.Name -match 'config\.candidate\.yaml'
}

if ($unwanted) {
    Write-Host "  ⚠️  Found unwanted files:" -ForegroundColor Red
    $unwanted | ForEach-Object { Write-Host "    $($_.FullName)" -ForegroundColor Red }
} else {
    Write-Host "  ✅ No unwanted files found" -ForegroundColor Green
}

# Check operational directories
Write-Host "`nChecking operational directories..." -ForegroundColor Yellow
$opDirs = @('logs', 'audit', 'backup', 'state', 'queue')
foreach ($dir in $opDirs) {
    if (Test-Path $dir) {
        $fileCount = (Get-ChildItem $dir -File -Recurse | Measure-Object).Count
        Write-Host "  📁 $dir`: $fileCount files" -ForegroundColor Cyan
    } else {
        Write-Host "  📁 $dir`: Not found" -ForegroundColor Yellow
    }
}

# Check for old files (>30 days)
Write-Host "`nChecking for old files (>30 days)..." -ForegroundColor Yellow
$oldFiles = Get-ChildItem -Recurse -File | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddDays(-30)
} | Where-Object {
    $_.Directory.Name -in @('logs', 'audit', 'backup')
}

if ($oldFiles) {
    Write-Host "  📅 Old files found (candidates for rotation):" -ForegroundColor Yellow
    $oldFiles | ForEach-Object { 
        Write-Host "    $($_.FullName) ($($_.LastWriteTime.ToString('yyyy-MM-dd')))" -ForegroundColor Yellow 
    }
} else {
    Write-Host "  ✅ No old files found" -ForegroundColor Green
}

# Check core scripts integrity
Write-Host "`nChecking core scripts..." -ForegroundColor Yellow
$coreScripts = @(
    'config.yaml',
    'config-hardened-plus.yaml', 
    'canary-check-min.ps1',
    'green-sheet.ps1',
    'quick-all-green.ps1',
    'auto-restart-verify.ps1',
    'safe-apply-config.ps1',
    'chaos-drill.ps1',
    'make-audit-pack.ps1'
)

foreach ($script in $coreScripts) {
    if (Test-Path $script) {
        Write-Host "  ✅ $script" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $script MISSING!" -ForegroundColor Red
    }
}

Write-Host "`nInventory complete. Review output above for any issues." -ForegroundColor Green
