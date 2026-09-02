#Requires -Version 7
<#
.SYNOPSIS
  H2 — lane-purity check (docs_gate GR-02 shift-left).
  Fails if staged set mixes docs-lane paths (docs/**, README.md) with non-docs
  (esp. CHAR/, artifacts/, code). No local lane:removal bypass.
#>
$ErrorActionPreference = 'Stop'
$staged = @(git diff --cached --name-only 2>$null)
if (-not $staged -or $staged.Count -eq 0) { exit 0 }

$docsLane = @()
$outOfLane = @()
foreach ($f in $staged) {
  $n = $f -replace '\\', '/'
  if ($n -eq 'README.md' -or $n.StartsWith('docs/')) {
    if ($n -notin @('docs/status/workflows.json', 'docs/status/scripts.json')) { $docsLane += $n }
  } else {
    $outOfLane += $n
  }
}

if ($docsLane.Count -gt 0 -and $outOfLane.Count -gt 0) {
  Write-Error @"
H2 lane-purity FAIL (mirrors docs_gate GR-02): staged set mixes docs-lane with non-docs.
  docs-lane ($($docsLane.Count)): $($docsLane -join ', ')
  out-of-lane ($($outOfLane.Count)): $($outOfLane -join ', ')
Split into separate PRs (docs vs code/evidence). No local lane:removal bypass.
"@
  exit 1
}
exit 0
