# Quick chart for A/B batch sweep summary
# Reads artifacts/ab-batch-summary-*.json and plots latency vs batch timeout

param(
  [string]$InputPath,
  [string]$OutPng = $(Join-Path (Resolve-Path "..").Path ("artifacts/ab-batch-chart-{0}.png" -f (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

$ErrorActionPreference = "Stop"

if (-not $InputPath) {
  $latest = Get-ChildItem -Path "artifacts" -Filter "ab-batch-summary-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $latest) { Write-Error "No summary JSON found in artifacts"; exit 1 }
  $InputPath = $latest.FullName
}

$json = Get-Content -Raw -LiteralPath $InputPath | ConvertFrom-Json
$rows = @()
foreach ($r in $json.results) {
  $rows += [pscustomobject]@{
    batch_timeout_ms = $r.batch_timeout_ms
    p50_ms = $r.stats.p50_ms
    p90_ms = $r.stats.p90_ms
    p95_ms = $r.stats.p95_ms
    mean_ms = $r.stats.mean_ms
  }
}

# Render a simple ASCII chart to console
Write-Host "Latency vs Batch Timeout (p50/p90/p95)" -ForegroundColor Cyan
foreach ($row in ($rows | Sort-Object batch_timeout_ms)) {
  $bars = @()
  foreach ($v in @($row.p50_ms,$row.p90_ms,$row.p95_ms)) {
    if ($null -eq $v) { $bars += "-"; continue }
    $n = [math]::Min([int]([math]::Round($v / 10)), 80)
    $bars += ("".PadLeft($n,'#'))
  }
  Write-Host ("{0,4}ms | p50 {1} | p90 {2} | p95 {3}" -f $row.batch_timeout_ms,$bars[0],$bars[1],$bars[2])
}

# Optional PNG via PowerShell drawing (minimal dependency)
try {
  Add-Type -AssemblyName System.Drawing
  $w=900; $h=400
  $bmp = New-Object System.Drawing.Bitmap($w,$h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::White)
  $font = New-Object System.Drawing.Font('Consolas',10)
  $black = [System.Drawing.Brushes]::Black
  $colors = @([System.Drawing.Color]::Blue,[System.Drawing.Color]::Orange,[System.Drawing.Color]::Red)
  $pens = $colors | ForEach-Object { New-Object System.Drawing.Pen($_,2) }
  $g.DrawString('Latency vs Batch Timeout (p50/p90/p95)', $font, $black, 10, 10)

  $xs = ($rows | Sort-Object batch_timeout_ms | ForEach-Object { $_.batch_timeout_ms })
  $ys = @('p50_ms','p90_ms','p95_ms')
  if ($xs.Count -gt 1) {
    $minX = [double]$xs[0]; $maxX = [double]$xs[-1]
    $vals = @()
    foreach ($k in $ys) { $vals += ($rows | ForEach-Object { $_.$k } | Where-Object { $_ -ne $null }) }
    if ($vals.Count -gt 0) {
      $minY = [double]($vals | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum)
      $maxY = [double]($vals | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
      if ($maxY -le $minY) { $maxY = $minY + 1 }
      function SX($x){ param($x,$minX,$maxX,$w) return 60 + (($x - $minX)/($maxX - $minX)) * ($w - 80) }
      function SY($y){ param($y,$minY,$maxY,$h) return ($h - 40) - (($y - $minY)/($maxY - $minY)) * ($h - 80) }
      # axes
      $g.DrawLine([System.Drawing.Pens]::Black, 60, $h-40, $w-20, $h-40)
      $g.DrawLine([System.Drawing.Pens]::Black, 60, 40, 60, $h-40)
      # lines
      for ($s=0; $s -lt $ys.Count; $s++) {
        $k = $ys[$s]
        $pen = $pens[$s]
        $prev = $null
        foreach ($row in ($rows | Sort-Object batch_timeout_ms)) {
          $x = [double]$row.batch_timeout_ms
          $y = $row.$k
          if ($y -eq $null) { continue }
          $px = [int](SX $x $minX $maxX $w)
          $py = [int](SY ([double]$y) $minY $maxY $h)
          if ($prev -ne $null) { $g.DrawLine($pen, $prev.X, $prev.Y, $px, $py) }
          $g.FillEllipse([System.Drawing.Brushes]::Gray, $px-2, $py-2, 4, 4)
          $prev = New-Object System.Drawing.Point($px,$py)
        }
      }
      # legend
      $g.DrawString('p50', $font, (New-Object System.Drawing.SolidBrush($colors[0])), $w-80, 40)
      $g.DrawString('p90', $font, (New-Object System.Drawing.SolidBrush($colors[1])), $w-80, 60)
      $g.DrawString('p95', $font, (New-Object System.Drawing.SolidBrush($colors[2])), $w-80, 80)
      $bmp.Save($OutPng, [System.Drawing.Imaging.ImageFormat]::Png)
      Write-Host ("PNG chart written: {0}" -f $OutPng) -ForegroundColor Green
    }
  }
} catch { Write-Host "PNG rendering skipped (System.Drawing unavailable)" -ForegroundColor Yellow }


