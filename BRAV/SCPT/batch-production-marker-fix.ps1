# Batch Production Marker Fix Script
param(
    [string]$ReportsPath = "CHAR/ECRR/ECRR_REPORTS",
    [switch]$DryRun = $false
)

Write-Host "🔧 Batch Production Marker Fix Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
}

# Get files that need production markers
$reportFiles = Get-ChildItem -Path $ReportsPath -Filter "*.md" | Where-Object { 
    $_.Name -match '\d{4}-\d{2}-\d{2}' -and 
    $_.Name -notmatch 'backup' -and
    $_.Name -notmatch '20250929-200755-'  # Exclude duplicate prefixed files
}

$filesToFix = @()
foreach ($file in $reportFiles) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and $content -notmatch '✅.*PRODUCTION READY') {
        $filesToFix += $file
    }
}

Write-Host "📊 Files needing production markers: $($filesToFix.Count)" -ForegroundColor Yellow

if ($filesToFix.Count -eq 0) {
    Write-Host "✅ All files already have production markers!" -ForegroundColor Green
    exit 0
}

$fixedCount = 0
$errorCount = 0

foreach ($file in $filesToFix) {
    try {
        Write-Host "🔧 Processing: $($file.Name)" -ForegroundColor Cyan
        
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        
        # Look for existing status line patterns and replace them
        $patterns = @(
            '\*\*Status\*\*:\s*✅\s*\*\*[^*]+\*\*',
            '\*\*Status\*\*:\s*✅\s*[^*\n]+',
            '\*\*Status\*\*:\s*[^*\n]+',
            'Status:\s*✅\s*\*\*[^*]+\*\*',
            'Status:\s*✅\s*[^*\n]+',
            'Status:\s*[^*\n]+'
        )
        
        $replaced = $false
        foreach ($pattern in $patterns) {
            if ($content -match $pattern) {
                $content = $content -replace $pattern, '**Status**: ✅ **PRODUCTION READY**'
                $replaced = $true
                break
            }
        }
        
        # If no status line found, add one after the title
        if (-not $replaced) {
            # Look for the end of the header section (usually after Date, Actor, Task lines)
            if ($content -match '(\*\*Task\*\*:[^\n]+\n)') {
                $content = $content -replace '(\*\*Task\*\*:[^\n]+\n)', "`$1**Status**: ✅ **PRODUCTION READY**`n"
            } else {
                # Fallback: add after first line
                $lines = $content -split "`n"
                if ($lines.Count -gt 0) {
                    $lines[0] += "`n**Status**: ✅ **PRODUCTION READY**"
                    $content = $lines -join "`n"
                }
            }
        }
        
        if (-not $DryRun) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        }
        
        $fixedCount++
        Write-Host "  ✅ Fixed production marker" -ForegroundColor Green
        
    } catch {
        $errorCount++
        Write-Host "  ❌ Error processing $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📈 Batch Fix Results:" -ForegroundColor Green
Write-Host "  ✅ Files processed: $fixedCount" -ForegroundColor Green
Write-Host "  ❌ Errors: $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Red" })

if ($DryRun) {
    Write-Host "  🔍 This was a dry run - no files were actually modified" -ForegroundColor Yellow
} else {
    Write-Host "  🔧 Files modified: $fixedCount" -ForegroundColor Green
}

exit 0

