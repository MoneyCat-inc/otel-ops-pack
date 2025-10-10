#Requires -Version 7.0
Param(
  [Parameter(Mandatory=$true)][string]$RunDir
)

$ErrorActionPreference = 'Stop'

Write-Host "[ecrr] Processing run dir: $RunDir" -ForegroundColor Cyan
if (-not (Test-Path $RunDir)) { Write-Error "RunDir not found: $RunDir"; exit 1 }

function Assert-File($p){ if (-not (Test-Path $p)) { Write-Error "Missing file: $p"; exit 1 } }

Assert-File (Join-Path $RunDir 'meta.json')

try {
  if (-not (Get-Command tsx -ErrorAction SilentlyContinue)) {
    Write-Warning "tsx not found; ensure Node + tsx are installed to run TypeScript scripts"
    exit 2
  }

  $env:RUN_DIR = $RunDir
  Write-Host "[ecrr] Normalizing..." -ForegroundColor Yellow
  tsx scripts/normalize-events.ts --dir "$RunDir"

  Write-Host "[ecrr] Summarizing..." -ForegroundColor Yellow
  tsx scripts/summarize-run.ts --dir "$RunDir"

  $summary = Join-Path $RunDir 'summary.md'
  Assert-File $summary
  Write-Host "[ecrr] OK — Summary at: $summary" -ForegroundColor Green
  exit 0
}
catch {
  Write-Error $_
  exit 1
}

