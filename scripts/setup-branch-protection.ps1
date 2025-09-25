# SSOT Gate Branch Protection Setup Guide
# This script provides instructions for setting up branch protection rules

Write-Host "🔒 SSOT Gate Branch Protection Setup" -ForegroundColor Cyan
Write-Host ""

Write-Host "Since this is a private repository, branch protection requires GitHub Pro or making the repo public." -ForegroundColor Yellow
Write-Host ""

Write-Host "📋 Manual Setup Instructions:" -ForegroundColor Green
Write-Host "1. Go to: https://github.com/fubumaki/otel-ops-pack/settings/branches" -ForegroundColor White
Write-Host "2. Click 'Add rule' for the 'main' branch" -ForegroundColor White
Write-Host "3. Configure the following settings:" -ForegroundColor White
Write-Host ""
Write-Host "   ✅ Require a pull request before merging" -ForegroundColor Green
Write-Host "   ✅ Require status checks to pass before merging" -ForegroundColor Green
Write-Host "   ✅ Require branches to be up to date before merging" -ForegroundColor Green
Write-Host ""
Write-Host "   📝 Required Status Checks:" -ForegroundColor Cyan
Write-Host "   - Add 'SSOT Gate' to the list of required status checks" -ForegroundColor White
Write-Host ""
Write-Host "   ✅ Restrict pushes that create files" -ForegroundColor Green
Write-Host "   ✅ Include administrators" -ForegroundColor Green
Write-Host ""
Write-Host "4. Click 'Create' to save the protection rule" -ForegroundColor White
Write-Host ""

Write-Host "🎯 Expected Behavior:" -ForegroundColor Cyan
Write-Host "- PRs cannot be merged until SSOT Gate job passes" -ForegroundColor White
Write-Host "- PRs must have '@cloud ready-for-gate' label" -ForegroundColor White
Write-Host "- Both Vitest and Playwright tests must pass" -ForegroundColor White
Write-Host ""

Write-Host "✅ Label Status:" -ForegroundColor Green
Write-Host "Label '@cloud ready-for-gate' has been created successfully!" -ForegroundColor White
Write-Host ""

Write-Host "🧪 Test the Gate:" -ForegroundColor Cyan
Write-Host "1. Create a test PR" -ForegroundColor White
Write-Host "2. Verify SSOT Gate runs automatically" -ForegroundColor White
Write-Host "3. Add '@cloud ready-for-gate' label when ready" -ForegroundColor White
Write-Host "4. Confirm merge is blocked until both conditions are met" -ForegroundColor White