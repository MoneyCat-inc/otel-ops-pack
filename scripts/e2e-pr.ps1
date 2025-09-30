# E2E PR Lane Script
# Run stable E2E tests for PR validation

Write-Host "Running E2E tests for PR lane..." -ForegroundColor Cyan

# Check if we're in CI environment
$isCI = $env:CI -eq "true"

if ($isCI) {
    Write-Host "CI environment detected - running no-flake subset" -ForegroundColor Yellow
    # Run only stable tests in CI
    pnpm e2e:grep:noflake
} else {
    Write-Host "Local environment - running full PR test suite" -ForegroundColor Green
    # Run full PR test suite locally
    pnpm e2e:pr
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ E2E tests passed" -ForegroundColor Green
} else {
    Write-Host "`n❌ E2E tests failed" -ForegroundColor Red
    Write-Host "Check test output above for details" -ForegroundColor Yellow
}
