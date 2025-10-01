# Windows Canary Alert Verification Script
# Run this after importing the alert to verify it's working

Write-Host "Testing Windows Canary Alert..." -ForegroundColor Green

# Generate test canary logs
pwsh -File scripts/generate-windows-canary.ps1 -DurationMinutes 2 -IntervalSeconds 10

Write-Host "
Wait 2 minutes, then check SigNoz UI for:" -ForegroundColor Yellow
Write-Host "1. Canary logs appearing in Logs section" -ForegroundColor White
Write-Host "2. Alert status in Alerts section" -ForegroundColor White
Write-Host "3. No alert firing (since canaries are being generated)" -ForegroundColor White

Write-Host "
To test the alert:" -ForegroundColor Yellow
Write-Host "1. Stop canary generation" -ForegroundColor White
Write-Host "2. Wait 10+ minutes" -ForegroundColor White
Write-Host "3. Alert should fire due to missing canaries" -ForegroundColor White
