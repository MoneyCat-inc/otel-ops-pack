# Build MILK Vendor Bundles
# Purpose: Create local IIFE bundles of butterchurn + butterchurnPresets
# Why: Avoids CDN dependencies and security scanner false positives on minified code
# Usage: pwsh -File scripts/visuals/build-milk-vendors.ps1

$ErrorActionPreference = "Stop"

Write-Host "🥛 Building MILK vendor bundles..." -ForegroundColor Cyan

# Ensure node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    pnpm install
}

# Create vendor directory
$vendorDir = "docs/BossCat/visuals/vendor"
if (-not (Test-Path $vendorDir)) {
    New-Item -ItemType Directory -Path $vendorDir -Force | Out-Null
}

# Find butterchurn library
$bcPath = node -p "require.resolve('butterchurn/lib/butterchurn.min.js')"
$bpPath = node -p "require.resolve('butterchurn-presets/lib/butterchurnPresets.min.js')"

Write-Host "🔍 Found butterchurn: $bcPath" -ForegroundColor Gray
Write-Host "🔍 Found presets: $bpPath" -ForegroundColor Gray

# Bundle butterchurn as IIFE global
Write-Host "🔨 Bundling butterchurn..." -ForegroundColor Yellow
npx esbuild "$bcPath" `
    --bundle `
    --format=iife `
    --global-name=butterchurn `
    --minify `
    --outfile="$vendorDir/butterchurn.vend.js"

# Bundle butterchurn-presets as IIFE global
Write-Host "🔨 Bundling butterchurn-presets..." -ForegroundColor Yellow
npx esbuild "$bpPath" `
    --bundle `
    --format=iife `
    --global-name=butterchurnPresets `
    --minify `
    --outfile="$vendorDir/butterchurnPresets.vend.js"

# Verify outputs
$bcSize = (Get-Item "$vendorDir/butterchurn.vend.js").Length / 1KB
$bpSize = (Get-Item "$vendorDir/butterchurnPresets.vend.js").Length / 1KB

Write-Host "✅ Bundles created:" -ForegroundColor Green
Write-Host "   butterchurn.vend.js: $([math]::Round($bcSize, 1)) KB" -ForegroundColor Gray
Write-Host "   butterchurnPresets.vend.js: $([math]::Round($bpSize, 1)) KB" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 These bundles are .gitignore'd to avoid security scanner false positives." -ForegroundColor Cyan
Write-Host "   Run this script after cloning or when updating butterchurn versions." -ForegroundColor Cyan

