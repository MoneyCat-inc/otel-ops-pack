Param(
  [string]$BenchmarkJson = 'DELT/ARTF/ecrr-benchmark.json',
  [string]$OutputCsv = 'DELT/ARTF/ecrr-benchmark-trend.csv',
  [string]$MirrorCsv = 'artifacts/ecrr-benchmark-trend.csv',
  [switch]$Dedup,
  [int]$MaxDays = 365,
  [int]$MaxRows = 2000
)
$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

if (-not (Test-Path -LiteralPath $BenchmarkJson)) {
  Write-Warning "Benchmark JSON not found: $BenchmarkJson"
  return
}

Ensure-Dir (Split-Path -Parent $OutputCsv)
Ensure-Dir (Split-Path -Parent $MirrorCsv)

$data = Get-Content -Raw -LiteralPath $BenchmarkJson | ConvertFrom-Json
$timestamp = try {
  Get-Date $data.timestamp
} catch {
  [datetime]::ParseExact($data.timestamp.Substring(0,19), 'yyyy-MM-ddTHH:mm:ss', $null)
}
$key = ($timestamp.ToString('s') + '|' + $data.commit + '|' + $data.branch + '|' + $data.latest_name)

function Read-CsvRows([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return @() }
  return Import-Csv -LiteralPath $Path
}

$rows = New-Object System.Collections.ArrayList
foreach ($r in (Read-CsvRows $OutputCsv)) { [void]$rows.Add($r) }

$newRow = [ordered]@{
  timestamp = $timestamp.ToString('o')
  commit    = $data.commit
  branch    = $data.branch
  total     = $data.total
  ready     = $data.ready
  not_ready = $data.not_ready
  warn      = $data.warn
  latest_name = $data.latest_name
  latest_verdict = $data.latest_verdict
  key       = $key
}

if ($Dedup) {
  $rows = @($rows | Where-Object { $_.key -ne $key })
}

$rows = @($rows + (New-Object PSObject -Property $newRow))

# Trim by date window
$cutoff = (Get-Date).AddDays(-$MaxDays)
$rows = @($rows | Where-Object { 
  $ts = try { Get-Date $_.timestamp } catch { $null }
  $null -ne $ts -and $ts -ge $cutoff
})

# Trim by row count (keep newest)
$rows = @($rows | Sort-Object {
  try { Get-Date $_.timestamp } catch { [datetime]::MinValue }
} -Descending)
if ($rows.Count -gt $MaxRows) { $rows = $rows[0..($MaxRows-1)] }

# Write CSV
$rows | Export-Csv -LiteralPath $OutputCsv -NoTypeInformation
Copy-Item -Force -LiteralPath $OutputCsv -Destination $MirrorCsv

Write-Host "Appended benchmark trend -> $OutputCsv (mirror: $MirrorCsv)"

