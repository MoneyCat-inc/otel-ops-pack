<# 
  scripts\ecrr-export-checklist.ps1
  Export docs/ECRR_SCREENSHOT_CHECKLIST.md into a PDF for external sharing.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$Src = Join-Path $Root 'docs\ECRR_SCREENSHOT_CHECKLIST.md'
$OutDir = Join-Path $Root 'artifacts'
$OutFile = Join-Path $OutDir 'ECRR_SCREENSHOT_CHECKLIST.pdf'

if (-not (Test-Path $Src)) { throw "Missing source: $Src" }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

Write-Host "[ECRR] Exporting $Src → $OutFile" -ForegroundColor Cyan

# Convert markdown → PDF
try {
    # Using pandoc if available
    if (Get-Command pandoc -ErrorAction SilentlyContinue) {
        pandoc $Src -o $OutFile
        Write-Host "[ok] Exported via pandoc."
    }
    else {
        # Fallback: use pypandoc if Python + pip available
        if (Get-Command python -ErrorAction SilentlyContinue) {
            python -m pip install --quiet pypandoc
            $pyCode = @"
import pypandoc
src = r'''$Src'''
out = r'''$OutFile'''
pypandoc.convert_file(src, 'pdf', outputfile=out, extra_args=['--standalone'])
print('[ok] Exported via pypandoc.')
"@
            $pyCode | python -
        } else {
            throw "No pandoc or Python available — please install pandoc to enable PDF export."
        }
    }
} catch {
    Write-Warning "Failed to export PDF: $($_.Exception.Message)"
    exit 1
}

Write-Host "[ECRR] Checklist PDF ready at $OutFile" -ForegroundColor Green
