# Generate MoneyCat-inc Branded Documentation
# Usage: .\scripts\generate-moneycat-doc.ps1 -Title "Report Title" -Content "Content here" -OutputPath "docs/report.md"

param(
    [Parameter(Mandatory=$true)]
    [string]$Title,
    
    [Parameter(Mandatory=$true)]
    [string]$Content,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputPath,
    
    [string]$BriefDescription = ""
)

$ErrorActionPreference = 'Stop'

# Get the template
$template = Get-Content "docs/templates/MONEYCAT_DOC_TEMPLATE.md" -Raw

# Replace placeholders
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
$document = $template -replace '\{TITLE\}', $Title
$document = $document -replace '\{BRIEF_DESCRIPTION\}', $BriefDescription
$document = $document -replace '\{MAIN_CONTENT\}', $Content
$document = $document -replace '\{timestamp\}', $timestamp

# Ensure output directory exists
$outputDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Write the document
Set-Content -Path $OutputPath -Value $document -Encoding UTF8

Write-Host "✅ Generated MoneyCat-inc branded document: $OutputPath" -ForegroundColor Green
Write-Host "   Title: $Title" -ForegroundColor Cyan
Write-Host "   Timestamp: $timestamp" -ForegroundColor Cyan
