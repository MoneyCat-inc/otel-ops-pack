# Wire Publisher to E2 Sweep Job
# Modifies the E2 ratio sweep script to automatically publish results

param(
    [string]$SweepScript = "scripts/e2-ratio-sweep.ps1",
    [string]$PublisherScript = "scripts/publish-e2-results.ps1"
)

Write-Host "=== Wiring Publisher to E2 Sweep Job ===" -ForegroundColor Green

# Check if scripts exist
if (-not (Test-Path $SweepScript)) {
    Write-Error "Sweep script not found: $SweepScript"
    exit 1
}

if (-not (Test-Path $PublisherScript)) {
    Write-Error "Publisher script not found: $PublisherScript"
    exit 1
}

# Backup original sweep script
$backupFile = "$SweepScript.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $SweepScript $backupFile
Write-Host "Backed up original script to: $backupFile" -ForegroundColor Cyan

try {
    # Read the sweep script
    $sweepContent = Get-Content $SweepScript -Raw
    
    # Add publisher call at the end of the try block (before the success message)
    $publisherCall = @"

    # Publish results to SigNoz
    Write-Host "`nPublishing results to SigNoz..." -ForegroundColor Yellow
    try {
        pwsh -File $PublisherScript
        Write-Host "✓ Results published to SigNoz successfully" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to publish results to SigNoz: $($_.Exception.Message)"
        Write-Host "You can manually publish later with: pwsh -File $PublisherScript" -ForegroundColor Cyan
    }
"@

    # Find the success message and add publisher call before it
    $successPattern = 'Write-Host "`nE2 Ratio Sweep completed successfully!" -ForegroundColor Green'
    $newContent = $sweepContent -replace $successPattern, ($publisherCall + "`n    " + $successPattern)
    
    # Write the modified script
    $newContent | Set-Content $SweepScript
    Write-Host "✓ Modified sweep script to include publisher call" -ForegroundColor Green
    
    # Show the changes
    Write-Host "`nChanges made:" -ForegroundColor Yellow
    Write-Host "- Added publisher call after sweep completion" -ForegroundColor White
    Write-Host "- Added error handling for publisher failures" -ForegroundColor White
    Write-Host "- Publisher runs automatically after each sweep" -ForegroundColor White
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Test the modified sweep script" -ForegroundColor White
    Write-Host "2. Run: pwsh -File $SweepScript -TestAllCombinations" -ForegroundColor White
    Write-Host "3. Verify results appear in SigNoz dashboard" -ForegroundColor White
    
} catch {
    Write-Error "Failed to modify sweep script: $($_.Exception.Message)"
    
    # Restore backup if modification failed
    if (Test-Path $backupFile) {
        Copy-Item $backupFile $SweepScript -Force
        Write-Host "Restored original script from backup" -ForegroundColor Yellow
    }
    
    exit 1
}

Write-Host "`nPublisher successfully wired to E2 sweep job!" -ForegroundColor Green
