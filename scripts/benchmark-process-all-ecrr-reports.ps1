Param(
  [string]$ReportsDir = 'docs/ecrr/ECRR_REPORTS',
  [string]$OutputJson = 'DELT/ARTF/ecrr-benchmark.json'
)
$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

function Get-GitMeta {
  try { $c = (git rev-parse --short HEAD 2>$null).Trim() } catch { $c = '' }
  try { $b = (git rev-parse --abbrev-ref HEAD 2>$null).Trim() } catch { $b = '' }
  [pscustomobject]@{ Commit = $c; Branch = $b }
}

Ensure-Dir (Split-Path -Parent $OutputJson)

if (-not (Test-Path -LiteralPath $ReportsDir)) {
  Write-Warning "Reports directory not found: $ReportsDir"
  $out = [ordered]@{
    timestamp = (Get-Date).ToString('o')
    commit    = (Get-GitMeta).Commit
    branch    = (Get-GitMeta).Branch
    total     = 0
    ready     = 0
    not_ready = 0
    warn      = 0
    latest_name = ''
    latest_verdict = ''
  }
  ($out | ConvertTo-Json -Depth 4) | Set-Content -Path $OutputJson -Encoding utf8
  return
}

$files = Get-ChildItem -LiteralPath $ReportsDir -File -Filter 'ECRR_GATE_RUN_*.md' | Sort-Object LastWriteTime
$total = 0; $ready = 0; $notReady = 0; $warn = 0
$latestVerdict = ''
$latestName = ''

foreach ($f in $files) {
  $total++
  $content = Get-Content -LiteralPath $f.FullName -Raw
  $line = ($content -split "`r?`n") | Where-Object { $_ -match '^Gate Verdict:' } | Select-Object -First 1
  if ($null -ne $line) {
    $v = ($line -replace '^Gate Verdict:\s*', '').Trim()
    switch -Regex ($v) {
      '^READY$' { $ready++; break }
      '^NOT_READY$' { $notReady++; break }
      '^READY_WITH_WARNINGS$' { $warn++; break }
    }
    if ($f -eq $files[-1]) { $latestVerdict = $v }
  }
  if ($f -eq $files[-1]) { $latestName = $f.Name }
}

$meta = Get-GitMeta
$out = [ordered]@{
  timestamp = (Get-Date).ToString('o')
  commit    = $meta.Commit
  branch    = $meta.Branch
  total     = $total
  ready     = $ready
  not_ready = $notReady
  warn      = $warn
  latest_name = $latestName
  latest_verdict = $latestVerdict
}

($out | ConvertTo-Json -Depth 4) | Set-Content -Path $OutputJson -Encoding utf8
Write-Host "Wrote benchmark summary to $OutputJson"

