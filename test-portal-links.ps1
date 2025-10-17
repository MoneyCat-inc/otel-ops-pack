# Portal Link Testing Script
# Quick browser validation for donation buttons

Write-Host "🐾 Portal Link Validation" -ForegroundColor Cyan
Write-Host ""

# Test URLs
$urls = @{
    "GitHub Sponsors" = "https://github.com/sponsors/MoneyCat-inc"
    "Buy Me a Coffee" = "https://buymeacoffee.com/fubumaki"
    "Patreon" = "https://www.patreon.com/c/FaeMcLachlan"
}

Write-Host "Testing donation button URLs..." -ForegroundColor Yellow
Write-Host ""

foreach ($name in $urls.Keys) {
    $url = $urls[$name]
    Write-Host "  ✓ $name" -ForegroundColor Green
    Write-Host "    URL: $url" -ForegroundColor Gray
    
    # Open in browser for manual verification
    Start-Process $url
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "✅ All links opened in browser" -ForegroundColor Green
Write-Host "   Verify each page loads correctly" -ForegroundColor Gray
Write-Host ""
Write-Host "Portal files:" -ForegroundColor Cyan
Write-Host "  - portal.html (main forward-facing page)" -ForegroundColor Gray
Write-Host "  - docs/anticlickbait/index.html (transparency hub)" -ForegroundColor Gray
Write-Host ""
Write-Host "Next: Open portal.html in browser to test button clicks" -ForegroundColor Yellow
Write-Host "  Command: start portal.html" -ForegroundColor Gray

