# BRAV/SCPT/run-archiver/generate-index.ps1
# Build lightweight INDEX.jsonl for archived run reports with progress output

param(
  [string]$ArchivedRoot = "docs/BossCat/run-reports/archived",
  [string]$OutFile = "docs/BossCat/run-reports/INDEX.jsonl"
)

$ErrorActionPreference = "Stop"

Write-Host "🐾 Generating INDEX.jsonl from archived reports..." -ForegroundColor Yellow

if (-not (Test-Path $ArchivedRoot)) {
  Write-Error "Archived root not found: $ArchivedRoot"
}

$outDir = Split-Path -Parent $OutFile
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

# Create/clear output
if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
New-Item -ItemType File -Path $OutFile -Force | Out-Null

function Parse-MetadataFromMd {
  param([string[]]$Lines)

  $obj = [ordered]@{
    id = $null
    workflow = $null
    conclusion = $null
    duration = $null
    date = $null
    actor = $null
  }

  foreach ($line in $Lines) {
    if (-not $obj.id -and $line -match '^\- \*\*ID:\*\*\s+(\d+)') { $obj.id = $matches[1] }
    if (-not $obj.workflow -and $line -match '^\- \*\*Workflow:\*\*\s+(.+)$') { $obj.workflow = $matches[1].Trim() }
    if (-not $obj.actor -and $line -match '^\- \*\*Actor:\*\*\s+@([A-Za-z0-9_.\-]+)') { $obj.actor = $matches[1] }
    if (-not $obj.conclusion -and $line -match '^\- \*\*Conclusion:\*\*\s+`([^`]+)`') { $obj.conclusion = $matches[1] }
    if (-not $obj.duration -and $line -match '^\- \*\*Duration:\*\*\s+([0-9]+)s') { $obj.duration = [int]$matches[1] }
    if (-not $obj.date -and $line -match '^\- \*\*Started:\*\*\s+([0-9T:\-]+)') {
      try {
        $dt = [datetime]::Parse($matches[1])
        $obj.date = $dt.ToString('yyyy-MM-dd')
      } catch {}
    }
  }

  return $obj
}

# Count total files first
Write-Host "📊 Scanning for archived reports..." -ForegroundColor Cyan
$allFiles = @(Get-ChildItem -Path $ArchivedRoot -Recurse -File -Filter "run-*.md")
$total = $allFiles.Count
Write-Host "   Found $total reports to index`n" -ForegroundColor DarkGray

$count = 0
$lastPercent = -1

foreach ($file in $allFiles) {
  $mdPath = $file.FullName
  $relRoot = (Resolve-Path .).Path
  $relPath = $mdPath.Substring($relRoot.Length).TrimStart(@('\','/')).Replace("\","/")

  # Expect path like docs/BossCat/run-reports/archived/YYYY/MM/run-<id>.md
  $relUnderArchived = $relPath -replace "^.*?archived/", ""

  $lines = Get-Content -LiteralPath $mdPath -ErrorAction Continue
  $meta = Parse-MetadataFromMd -Lines $lines

  # Fallbacks from filename if needed
  if (-not $meta.id -and $mdPath -match "run-(\d+)\.md$") { $meta.id = $matches[1] }
  if (-not $meta.duration) { $meta.duration = 0 }
  if (-not $meta.workflow) { $meta.workflow = 'unknown' }
  if (-not $meta.conclusion) { $meta.conclusion = 'unknown' }
  if (-not $meta.actor) { $meta.actor = 'unknown' }
  if (-not $meta.date) {
    # Derive from parent folder (YYYY/MM)
    if ($mdPath -match "archived\\(?<y>\d{4})\\(?<m>\d{2})\\") {
      $meta.date = "{0}-{1}-01" -f $matches['y'], $matches['m']
    } else { $meta.date = '1970-01-01' }
  }

  $obj = [ordered]@{
    id = "$($meta.id)"
    workflow = "$($meta.workflow)"
    conclusion = "$($meta.conclusion)"
    duration = [int]$meta.duration
    date = "$($meta.date)"
    actor = "$($meta.actor)"
    path = $relUnderArchived
  }

  ($obj | ConvertTo-Json -Compress) | Add-Content -Path $OutFile -Encoding UTF8
  $count++
  
  # Progress indicator every 5%
  $percent = [math]::Floor(($count / $total) * 100)
  if ($percent -ne $lastPercent -and $percent % 5 -eq 0) {
    $bar = "█" * ($percent / 5) + "░" * (20 - ($percent / 5))
    Write-Host "`r   $bar  $percent% ($count/$total)" -NoNewline -ForegroundColor Yellow
    $lastPercent = $percent
  }
}

Write-Host "`n`n✅ Index generated: $OutFile ($count entries)" -ForegroundColor Green

