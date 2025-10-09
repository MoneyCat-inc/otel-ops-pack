param(
  [string]$Root = "..",
  [switch]$Json,
  [switch]$Quiet
)

$ErrorActionPreference = "Stop"

function Read-Status($path) {
  try {
    (Get-Content $path -Raw -ErrorAction Stop | ConvertFrom-Json)
  } catch { $null }
}

$files = Get-ChildItem -Recurse -Path $Root -Filter "status.json" -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -match "\\.agent\\status\.json$" }

$stats = @()
foreach ($f in $files) {
  $s = Read-Status $f.FullName
  if ($s) { $stats += $s }
}

$running  = ($stats | Where-Object { $_.state -eq "running" }).Count
$locked   = ($stats | Where-Object { $_.state -eq "paused:lock" }).Count
$blocked  = ($stats | Where-Object { $_.state -eq "blocked:env" }).Count
$violSum  = ($stats | Measure-Object -Property guardrailViolations -Sum).Sum
if (-not $violSum) { $violSum = 0 }

$result = [pscustomobject]@{
  schema     = "codex-local.fleet.v1"
  repos      = $stats.Count
  running    = $running
  locked     = $locked
  blocked    = $blocked
  violations = $violSum
  generatedAt= (Get-Date).ToString("o")
}

if ($Json) {
  $result | ConvertTo-Json -Depth 6
} elseif ($Quiet) {
  "{0} repos | {1} running | {2} locked | {3} blocked | {4} violations" -f `
  $result.repos,$running,$locked,$blocked,$violSum
} else {
  $result | Format-List
}