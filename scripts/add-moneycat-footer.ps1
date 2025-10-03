# Add MoneyCat-inc Footer to Documentation
# Usage: .\scripts\add-moneycat-footer.ps1 -FilePath "docs/report.md"

param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    
    [switch]$RemoveExistingFooter
)

$ErrorActionPreference = 'Stop'

# Get the footer template
$footerTemplate = Get-Content "docs/templates/MONEYCAT_FOOTER.md" -Raw

# Replace timestamp placeholder
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
$footer = $footerTemplate -replace '\{timestamp\}', $timestamp

# Read the current file
$content = Get-Content $FilePath -Raw

# Remove existing footer if requested
if ($RemoveExistingFooter) {
    # Remove footer between the last "---" and end of file
    $content = $content -replace '\n---\n\*Generated:.*$', ''
}

# Check if footer already exists
$footerPattern = '\n---\n\*Generated:.*MoneyCat-inc/otel-ops-pack\*$'
if ($content -match $footerPattern) {
    Write-Host "Footer already exists in $FilePath" -ForegroundColor Yellow
    return
}

# Append footer
$newContent = $content.TrimEnd() + "`n`n" + $footer

# Write back to file
Set-Content -Path $FilePath -Value $newContent -Encoding UTF8

Write-Host "✅ Added MoneyCat-inc footer to $FilePath" -ForegroundColor Green
