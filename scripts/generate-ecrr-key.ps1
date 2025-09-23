# ECRR Key Generator - PowerShell
# Generates unique ECRR keys in the format ECRR-YYYYMMDD-HHMMSS

param(
    [string]$Slug = "",
    [switch]$ShowUsage
)

if ($ShowUsage) {
    Write-Host "ECRR Key Generator" -ForegroundColor Green
    Write-Host "Usage: .\generate-ecrr-key.ps1 [-Slug 'SLUG-NAME'] [-ShowUsage]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\generate-ecrr-key.ps1                                    # Basic key"
    Write-Host "  .\generate-ecrr-key.ps1 -Slug 'FEATURE-IMPLEMENTATION'    # With slug"
    Write-Host "  .\generate-ecrr-key.ps1 -ShowUsage                        # Show this help"
    exit 0
}

# Generate timestamp in UTC
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$key = "ECRR-$timestamp"

if ($Slug) {
    # Clean slug (remove spaces, special chars, uppercase)
    $cleanSlug = $Slug -replace '[^A-Z0-9-]', '' -replace '^-+|-+$', '' -replace '-+', '-'
    if ($cleanSlug) {
        $key = "ECRR-$timestamp-$cleanSlug"
    }
}

Write-Host $key -ForegroundColor Green

# Also output for copy-paste
Write-Host ""
Write-Host "Copy-paste commands:" -ForegroundColor Yellow
Write-Host "  Filename: $key.md" -ForegroundColor Cyan
Write-Host "  Front-matter: ecrr_key: $key" -ForegroundColor Cyan
Write-Host "  Commit message: docs(ecrr): $key — [your description]" -ForegroundColor Cyan
