# Guard: Block Inflated Metrics (77×, 7×, 196.7)
# Fails CI if inflated performance claims are detected in production files
# Enhanced with Unicode, HTML entities, and worded variants

Write-Host "🛡️ Guarding against inflated metrics..." -ForegroundColor Cyan

# Define banned patterns (hardened with BossCat OEM guidance)
$bannedPatterns = @(
    # Core patterns
    '77\s*[x×✕]',
    '7\s*7\s*[x×✕]',
    
    # HTML entities
    '77\s*&times;',
    '77\s*&#215;',
    '77&nbsp;[x×✕]',
    '77&nbsp;&times;',
    
    # Worded forms
    'seventy[-\s]?seven\s*(times|x|×|✕)',
    
    # Derived value
    '196[.,]7(?!\d)'
)

# Define production file patterns (exclude archives)
$productionPatterns = @(
    "docs/*.md",
    "docs/ecrr/ECRR_REPORTS/*.md",
    "DELT/ARTF/*.json",
    "*.html",
    "README*.md",
    "portal.html",
    "index.html"
)

# Exclude archived content and historical files
$excludePatterns = @(
    "!**/archive/**",
    "!**/history/**",
    "!**/deprecated/**",
    "!**/legacy/**",
    "!CHAR/PRSV/**",
    "!CHAR/DOCS/docs/archive/**",
    "!**/node_modules/**",
    "!.git/**"
)

# Search for inflated claims in production files
$inflatedMatches = @()

foreach ($pattern in $productionPatterns) {
    foreach ($bannedPattern in $bannedPatterns) {
        $matches = rg -n --hidden -g $pattern `
            -e $bannedPattern `
            @excludePatterns 2>$null
        
        if ($matches) {
            $inflatedMatches += $matches
        }
    }
}

if ($inflatedMatches.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ INFLATED METRICS DETECTED" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""
    Write-Host "Found $($inflatedMatches.Count) occurrences of inflated performance claims:" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($match in $inflatedMatches | Select-Object -First 20) {
        Write-Host "  $match" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "POLICY:" -ForegroundColor Red
    Write-Host "  • 77× claim is BANNED (unverified)" -ForegroundColor Red
    Write-Host "  • 196.7 logs/sec is BANNED (derived from 77×)" -ForegroundColor Red
    Write-Host ""
    Write-Host "ALLOWED:" -ForegroundColor Green
    Write-Host "  • 'Performance thresholds met (see test evidence)'" -ForegroundColor Green
    Write-Host "  • Link to reproducible benchmark results" -ForegroundColor Green
    Write-Host "  • Measured values with test report links" -ForegroundColor Green
    Write-Host ""
    Write-Host "FIX:" -ForegroundColor Cyan
    Write-Host "  1. Remove inflated claims from production files" -ForegroundColor Cyan
    Write-Host "  2. Replace with verifiable statements" -ForegroundColor Cyan
    Write-Host "  3. Link to repeatable test evidence" -ForegroundColor Cyan
    Write-Host ""
    
    exit 1
}

Write-Host "✅ No inflated metrics detected in production files" -ForegroundColor Green
Write-Host ""

exit 0

