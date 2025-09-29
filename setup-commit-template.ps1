# Setup Commit Template for Archive Lifecycle
# Run this script to ensure proper Git commit template configuration

Write-Host "[SETUP] Setting up Git commit template for archive lifecycle..." -ForegroundColor Green

# Check if we're in a Git repository
if (-not (Test-Path ".git")) {
    Write-Host "[ERROR] Not in a Git repository" -ForegroundColor Red
    exit 1
}

# Check if .gitmessage exists
if (-not (Test-Path ".gitmessage")) {
    Write-Host "[ERROR] .gitmessage template file not found" -ForegroundColor Red
    exit 1
}

# Configure Git to use the commit template
git config commit.template .gitmessage

# Verify configuration
$template = git config --get commit.template
if ($template -eq ".gitmessage") {
    Write-Host "[OK] Git commit template configured successfully" -ForegroundColor Green
    Write-Host "📍 Template location: $template" -ForegroundColor Cyan
} else {
    Write-Host "[ERROR] Failed to configure commit template" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[GUIDELINES] Archive Lifecycle Guidelines:" -ForegroundColor Yellow
Write-Host "  - [CHRONICLE]: Update docs/RESONAI_CHRONICLE.md executive summary" -ForegroundColor White
Write-Host "  - [INDEX]: Update archive/ARCHIVE_INDEX.md counts/references" -ForegroundColor White  
Write-Host "  - [BACKUP]: Archive original files (preserve emoji artifacts)" -ForegroundColor White
Write-Host ""
Write-Host "[POLICY] Full Policy: docs/ECRR_REPORTS/backup/ARCHIVE_POLICY.md" -ForegroundColor Cyan
Write-Host "[TEMPLATE] Full Template: docs/COMMIT_TEMPLATE.md" -ForegroundColor Cyan
Write-Host ""

# Self-test verification
Write-Host "[TEST] Verifying configuration..." -ForegroundColor Yellow
$currentTemplate = git config --get commit.template
if ($currentTemplate -eq ".gitmessage") {
    Write-Host "[OK] Template verification passed: $currentTemplate" -ForegroundColor Green
} else {
    Write-Host "[WARN] Template verification failed: $currentTemplate" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[READY] Commit messages will now include archive lifecycle reminders." -ForegroundColor Green
