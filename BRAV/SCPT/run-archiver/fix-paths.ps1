Param()
$ErrorActionPreference = 'Stop'

function Move-Safe($src, $dst){
  if (Test-Path -LiteralPath $src) {
    $dstDir = Split-Path -Parent $dst
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    Write-Host "Moving $src -> $dst"
    Move-Item -Force -LiteralPath $src -Destination $dst
  }
}

$root = Get-Location
Push-Location BRAV/SCPT/run-archiver
try {
  # Evidence
  Move-Safe 'CHAR/EVID' (Join-Path $root 'CHAR/EVID')
  # Reports
  if (Test-Path 'docs/BossCat') {
    Move-Safe 'docs/BossCat' (Join-Path $root 'docs/BossCat')
  }
} finally {
  Pop-Location
}

Write-Host 'Path normalization complete.'

