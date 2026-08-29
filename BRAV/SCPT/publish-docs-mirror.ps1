#Requires -Version 7.0
<#
.SYNOPSIS
  Publish step for the CHAR/DOCS documentation mirror (v3, tree-level).

.DESCRIPTION
  Makes CHAR/DOCS/docs/ an exact copy of the last COMMITTED state of docs/ by
  grafting the docs tree object into the index at the mirror prefix. No file
  paths ever cross a string-decode boundary, which retires the entire failure
  family found on 2026-08-29:
    v1: raw worktree-byte comparison -> hundreds of stale-smudge phantoms;
        `git add -A` silently skipped gitignored-but-mirrored *.docx/*.pdf.
    v2: per-file `git hash-object` fixed the smudge phantoms, but comparing
        git-decoded path strings against .NET filesystem path strings still
        mis-paired 9 non-ASCII filenames on Windows (U+2019, en-dash).
    v3: `git read-tree --prefix` + tree-OID comparison. Content is compared
        by hash inside git; equality of the two tree OIDs IS the proof.

  Publishes committed content only: uncommitted edits under docs/ are not
  mirrored until they land in a commit (the script warns when it sees any).
  Scope guard unchanged: only CHAR/DOCS/docs/ is ever written or deleted;
  the first-class content at CHAR/DOCS/ top level (ADR/, policies/, ...) is
  untouched. Manual by design (docs/PURPOSE.md: no new recurring writers).

.PARAMETER DryRun
  Report the tree-level differences without touching index or worktree.

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

$srcTree = (git rev-parse 'HEAD:docs').Trim()
if (-not $srcTree) { throw 'HEAD:docs did not resolve - refusing to continue.' }

git rev-parse -q --verify 'HEAD:CHAR/DOCS/docs' *> $null
$dstTree = if ($LASTEXITCODE -eq 0) { (git rev-parse 'HEAD:CHAR/DOCS/docs').Trim() } else { $null }

# Uncommitted docs/ edits are not published; say so up front.
$dirty = git status --porcelain -- docs/
if ($dirty) {
    Write-Host "NOTE: docs/ has uncommitted changes; this publishes the last COMMITTED docs tree."
}

if ($dstTree -eq $srcTree) {
    Write-Host "Mirror in sync: HEAD:docs and HEAD:CHAR/DOCS/docs are the same tree ($srcTree)."
    exit 0
}

# Show what differs, straight from git (byte-exact, platform-independent).
Write-Host "Tree diff (mirror -> source):"
if ($dstTree) {
    git diff-tree -r --name-status $dstTree $srcTree
} else {
    Write-Host "  (mirror tree absent - full publish)"
}

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY RUN - nothing written. source tree $srcTree vs mirror tree $(if ($dstTree) { $dstTree } else { '<none>' })"
    exit 0
}

# 1. Drop the mirror subtree from the index (tolerate an empty mirror).
git rm -r -q --cached --ignore-unmatch -- 'CHAR/DOCS/docs' | Out-Null

# 2. Graft the committed docs tree at the mirror prefix (index-level, exact).
git read-tree --prefix='CHAR/DOCS/docs/' $srcTree

# 3. Materialize the worktree from the index (scoped to the mirror so no
#    unrelated uncommitted edit is ever touched), then drop strays - files
#    no longer tracked under the mirror, whatever their names or ignore
#    status.
git checkout -q -- 'CHAR/DOCS/docs'
git clean -qfdx -- 'CHAR/DOCS/docs'

# 4. Prove the staged result before anyone commits it.
$staged = (git write-tree).Trim()
$stagedMirror = (git rev-parse "${staged}:CHAR/DOCS/docs").Trim()
if ($stagedMirror -eq $srcTree) {
    Write-Host ""
    Write-Host "Published and staged. PROOF: staged mirror tree == source tree ($srcTree)."
    Write-Host "Commit with:  git commit -m 'docs: publish CHAR/DOCS mirror'"
} else {
    throw "Staged mirror tree $stagedMirror does not match source tree $srcTree - do not commit; investigate."
}
