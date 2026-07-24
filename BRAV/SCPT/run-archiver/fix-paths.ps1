Param()
$ErrorActionPreference = 'Stop'

# Normalize misplaced outputs created when archiver CWD was BRAV/SCPT/run-archiver
# without REPO_ROOT. NEVER Move-Item a docs/BossCat directory into an existing
# docs/BossCat — that creates docs/BossCat/BossCat/ (the Pack 2 nested-tree bug).

function Get-RepoRoot {
  if ($env:REPO_ROOT) { return (Resolve-Path $env:REPO_ROOT).Path }
  if ($env:GITHUB_WORKSPACE) { return (Resolve-Path $env:GITHUB_WORKSPACE).Path }
  $top = git rev-parse --show-toplevel 2>$null
  if ($LASTEXITCODE -eq 0 -and $top) { return $top.Trim() }
  return (Get-Location).Path
}

function Assert-NotNestedBossCat([string]$Path) {
  if ($Path -match '[/\\]BossCat[/\\]BossCat([/\\]|$)') {
    throw "Refusing nested BossCat path: $Path"
  }
}

function Merge-DirectoryContents([string]$Src, [string]$Dst) {
  Assert-NotNestedBossCat $Dst
  New-Item -ItemType Directory -Force -Path $Dst | Out-Null
  Get-ChildItem -LiteralPath $Src -Force | ForEach-Object {
    $target = Join-Path $Dst $_.Name
    if ($_.PSIsContainer -and (Test-Path -LiteralPath $target)) {
      Merge-DirectoryContents $_.FullName $target
    } else {
      Move-Item -Force -LiteralPath $_.FullName -Destination $target
    }
  }
  Remove-Item -LiteralPath $Src -Recurse -Force -ErrorAction SilentlyContinue
}

$root = Get-RepoRoot
$misplaced = Join-Path $root 'BRAV/SCPT/run-archiver/docs/BossCat'
$canonical = Join-Path $root 'docs/BossCat'

if (Test-Path -LiteralPath $misplaced) {
  Write-Host "Merging misplaced $misplaced -> $canonical (no nest)"
  if (Test-Path -LiteralPath $canonical) {
    Merge-DirectoryContents $misplaced $canonical
  } else {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $canonical) | Out-Null
    Move-Item -Force -LiteralPath $misplaced -Destination $canonical
  }
}

# Fail loud if nest already present (5A guard — delete is Task 5B)
$nested = Join-Path $root 'docs/BossCat/BossCat'
if (Test-Path -LiteralPath $nested) {
  Write-Warning "Nested tree still present at $nested — run Task 5B after 5A lands."
}

Write-Host 'Path normalization complete.'
