param(
  [string]$SourceRoot = 'docs/BossCat/security',
  [switch]$RebuildAlerts = $true,
  [switch]$RebuildAnalyses = $true
)

$ErrorActionPreference = 'Stop'
function Append-Jsonl([string]$path, $obj){ $line = ($obj | ConvertTo-Json -Depth 10 -Compress); $line | Add-Content -Path $path -Encoding utf8 }
function Safe-ReadJson([string]$p){ try { Get-Content -Raw -LiteralPath $p | ConvertFrom-Json } catch { $null } }

Write-Host "[BossCat] Rebuilding indexes from $SourceRoot" -ForegroundColor Cyan

if($RebuildAlerts){
  $idxPath = Join-Path $SourceRoot 'INDEX_ALERTS.jsonl'
  if(Test-Path -LiteralPath $idxPath){ Remove-Item -LiteralPath $idxPath -Force }
  $jsonFiles = Get-ChildItem -Recurse -File -Path (Join-Path $SourceRoot 'data/alerts') -Filter 'alert-*.json' -ErrorAction SilentlyContinue
  foreach($f in $jsonFiles){
    $a = Safe-ReadJson $f.FullName
    if(-not $a){ continue }
    $idx = @{ alert_number=$a.number; rule_id=$a.rule.id; severity=$a.rule.severity; state=$a.state; created_at=$a.created_at; updated_at=$a.updated_at; html_url=$a.html_url; file=$a.most_recent_instance.location.path; line=$a.most_recent_instance.location.start_line; commit_sha=$a.most_recent_instance.commit_sha }
    Append-Jsonl $idxPath $idx
  }
  Write-Host "[BossCat] Alerts index rebuilt: $idxPath" -ForegroundColor Green
}

if($RebuildAnalyses){
  $idx2 = Join-Path $SourceRoot 'INDEX_ANALYSES.jsonl'
  if(Test-Path -LiteralPath $idx2){ Remove-Item -LiteralPath $idx2 -Force }
  $metaFiles = Get-ChildItem -Recurse -File -Path (Join-Path $SourceRoot 'data/analyses') -Filter 'analysis-*.json' -ErrorAction SilentlyContinue
  foreach($mf in $metaFiles){
    $m = Safe-ReadJson $mf.FullName
    if(-not $m){ continue }
    $id = $m.id
    $dir = Split-Path -Parent $mf.FullName
    # Translate to SARIF location based on year/month directory in /analyses
    $y = (Split-Path -Leaf (Split-Path -Parent $dir))
    $mm = (Split-Path -Leaf $dir)
    $sarifPath = Join-Path $SourceRoot "analyses/$y/$mm/analysis-$id.sarif.json"
    $idx = @{ analysis_id=$id; tool=$m.tool.name; ref=$m.ref; commit_sha=$m.commit_sha; created_at=$m.created_at; sarif_path=$sarifPath; alerts_count=$m.results_count }
    Append-Jsonl $idx2 $idx
  }
  Write-Host "[BossCat] Analyses index rebuilt: $idx2" -ForegroundColor Green
}

Write-Host "[BossCat] Index rebuild complete." -ForegroundColor Green

