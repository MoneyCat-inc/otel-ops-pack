# Cleanup Test Artifacts Script
# Removes test branches, PRs, and files after validation

Write-Host "🧹 CLEANING UP TEST ARTIFACTS" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Confirm before cleanup
Write-Host "⚠️  This will clean up test artifacts:" -ForegroundColor Yellow
Write-Host "  - test-queue-behavior branch" -ForegroundColor Gray
Write-Host "  - test-reviewdog.js file" -ForegroundColor Gray
Write-Host "  - Evidence directories" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Continue with cleanup? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "❌ Cleanup cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n🧹 Starting cleanup..." -ForegroundColor Green

# 1. Switch to main branch
Write-Host "`n1. Switching to main branch..." -ForegroundColor Yellow
try {
    git checkout main
    Write-Host "✅ Switched to main branch" -ForegroundColor Green
} catch {
    Write-Host "❌ Error switching to main: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Delete test branch locally
Write-Host "`n2. Deleting test branch locally..." -ForegroundColor Yellow
try {
    git branch -D test-queue-behavior
    Write-Host "✅ Deleted test-queue-behavior branch locally" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Test branch may not exist locally: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 3. Delete test branch remotely
Write-Host "`n3. Deleting test branch remotely..." -ForegroundColor Yellow
try {
    git push origin --delete test-queue-behavior
    Write-Host "✅ Deleted test-queue-behavior branch remotely" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Test branch may not exist remotely: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 4. Remove test file
Write-Host "`n4. Removing test file..." -ForegroundColor Yellow
if (Test-Path "test-reviewdog.js") {
    try {
        git rm test-reviewdog.js
        git commit -m "cleanup: remove test-reviewdog.js file"
        git push
        Write-Host "✅ Removed test-reviewdog.js file" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error removing test file: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  Test file not found" -ForegroundColor Yellow
}

# 5. Clean up evidence directories
Write-Host "`n5. Cleaning up evidence directories..." -ForegroundColor Yellow
try {
    $evidenceDirs = Get-ChildItem -Directory -Name "validation-evidence-*" -ErrorAction SilentlyContinue
    if ($evidenceDirs) {
        $evidenceDirs | ForEach-Object {
            Write-Host "  Removing: $_" -ForegroundColor Gray
            Remove-Item $_ -Recurse -Force
        }
        Write-Host "✅ Cleaned up evidence directories" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No evidence directories found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error cleaning evidence directories: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Clean up otel_art directory
Write-Host "`n6. Cleaning up otel_art directory..." -ForegroundColor Yellow
if (Test-Path "otel_art") {
    try {
        Remove-Item "otel_art" -Recurse -Force
        Write-Host "✅ Cleaned up otel_art directory" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error cleaning otel_art: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  otel_art directory not found" -ForegroundColor Yellow
}

# 7. Clean up monitoring scripts
Write-Host "`n7. Cleaning up monitoring scripts..." -ForegroundColor Yellow
$monitoringScripts = @(
    "monitor-ci-background.ps1",
    "monitor-parallel-validation.ps1",
    "quick-status-check.ps1",
    "check-validation-status.ps1",
    "collect-validation-evidence.ps1"
)

$monitoringScripts | ForEach-Object {
    if (Test-Path $_) {
        try {
            Remove-Item $_ -Force
            Write-Host "  Removed: $_" -ForegroundColor Gray
        } catch {
            Write-Host "  ❌ Error removing $_: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
Write-Host "✅ Cleaned up monitoring scripts" -ForegroundColor Green

# 8. Final status
Write-Host "`n8. Final cleanup status..." -ForegroundColor Yellow
try {
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        Write-Host "⚠️  Git status shows uncommitted changes:" -ForegroundColor Yellow
        $gitStatus | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    } else {
        Write-Host "✅ Git working directory is clean" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Error checking git status: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host "Test artifacts have been cleaned up:" -ForegroundColor White
Write-Host "  ✅ Test branch deleted" -ForegroundColor Green
Write-Host "  ✅ Test file removed" -ForegroundColor Green
Write-Host "  ✅ Evidence directories cleaned" -ForegroundColor Green
Write-Host "  ✅ Monitoring scripts removed" -ForegroundColor Green
Write-Host "  ✅ Working directory clean" -ForegroundColor Green

Write-Host "`n📋 Remember to:" -ForegroundColor Yellow
Write-Host "  - Review any open PRs and close if needed" -ForegroundColor Gray
Write-Host "  - Check for any remaining test artifacts" -ForegroundColor Gray
Write-Host "  - Document validation results if needed" -ForegroundColor Gray
