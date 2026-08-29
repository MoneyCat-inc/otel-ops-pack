#Requires -Version 7.0
<#
.SYNOPSIS
  Publish step for the CHAR/DOCS documentation mirror.

.DESCRIPTION
  Makes CHAR/DOCS/docs/ an exact copy of the GIT-TRACKED contents of docs/.
  This is the "publish step" that CHAR/DOCS/README.md has referenced since the
  mirror was created but which never existed (found in the 2026-08-29 audit
  close-out; ECRR_BOSSCAT_AUDIT_DRIFT_20260829.md). Run it manually after
  docs/ changes land; it is deliberately NOT a scheduled workflow — per
  docs/PURPOSE.md, recurring writers need an owner, review date and kill
  switch, and a manually run script needs none of that.

  Scope guard: this script only ever writes or deletes inside CHAR/DOCS/docs/.
  The rest of CHAR/DOCS/ (ADR/, policies/, runbooks/, IONA_ERRORS.md, ...) is
  first-class content, NOT mirror output, and is never touched.

  The source file list comes from `git ls-files docs` so local untracked or
  ignored files under docs/ are never published into the mirror.

.PARAMETER DryRun
  Report what would be copied/deleted without writing anything.

.EXAMPLE
  pwsh -File BRAV/SCPT/publish-docs-mirror.ps1 -DryRun
  pwsh -File BRAV/SCPT/publish-docs-mirror.ps1
#>
[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel).Trim()
if (-not $repoRoot) { throw 'Not inside a git repository.' }
Set-Location $repoRoot

$src = 'docs'
$dst = Join-Path 'CHAR' (Join-Path 'DOCS' 'docs')

# Source of truth: git-tracked files under docs/ only.
# core.quotepath=off keeps non-ASCII paths raw instead of C-quoted octal escapes.
$srcRel = git -c core.quotepath=off ls-files -- $src | ForEach-Object {
    $_.Substring($src.Length + 1)
}
if (-not $srcRel -or $srcRel.Count -eq 0) { throw "git ls-files returned nothing under $src/ - refusing to empty the mirror." }

$relSet = @{}
foreach ($r in $srcRel) { $relSet[$r] = $true }

$copied = 0; $deleted = 0; $unchanged = 0

# 1. Copy new/changed files source -> mirror.
foreach ($r in $srcRel) {
    $s = Join-Path $src $r
    $d = Join-Path $dst $r
    if ((Test-Path -LiteralPath $d) -and
        ((Get-FileHash -LiteralPath $s -Algorithm SHA256).Hash -eq
         (Get-FileHash -LiteralPath $d -Algorithm SHA256).Hash)) {
        $unchanged++
        continue
    }
    if ($DryRun) {
        Write-Host "would copy:   $r"
    } else {
        $dir = Split-Path -Parent $d
        if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        Copy-Item -LiteralPath $s -Destination $d -Force
    }
    $copied++
}

# 2. Delete mirror files that have no source counterpart.
if (Test-Path -LiteralPath $dst) {
    $dstPrefix = (Resolve-Path -LiteralPath $dst).Path
    Get-ChildItem -LiteralPath $dst -Recurse -File | ForEach-Object {
        $r = $_.FullName.Substring($dstPrefix.Length + 1) -replace '\\', '/'
        if (-not $relSet.ContainsKey($r)) {
            if ($DryRun) {
                Write-Host "would delete: $r"
            } else {
                Remove-Item -LiteralPath $_.FullName -Force
            }
            $script:deleted++
        }
    }
    # 3. Prune directories the deletions emptied.
    if (-not $DryRun) {
        Get-ChildItem -LiteralPath $dst -Recurse -Directory |
            Sort-Object { $_.FullName.Length } -Descending |
            Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force) } |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
    }
}

$mode = if ($DryRun) { 'DRY RUN - nothing written' } else { 'published' }
Write-Host ""
Write-Host "Mirror $mode : copied $copied, deleted $deleted, unchanged $unchanged (source: $($srcRel.Count) tracked files)"
if (-not $DryRun) {
    Write-Host "Verify with:  git diff --stat   and   diff -rq $src $dst"
}
