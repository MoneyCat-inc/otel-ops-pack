param(
  [int]$ChunkOffset = 0,
  [int]$ChunkSize = 1000,
  [switch]$DryRun,
  [switch]$MarkRead,
  [double]$GetQps = 2.0,
  [double]$MutateQps = 2.0,
  [string]$OutRoot = 'docs/BossCat/notifications',
  [string]$EvidenceRoot = 'CHAR/EVID/notifications',
  [string]$Token = $env:GITHUB_TOKEN,
  [switch]$NoProgress
)

$ErrorActionPreference = 'Stop'
function Ensure-Dir([string]$p){ if(-not(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Path $p -Force | Out-Null } }
function Append-Jsonl([string]$path, $obj){ $line = ($obj | ConvertTo-Json -Depth 10 -Compress); $line | Add-Content -Path $path -Encoding utf8 }
function New-YearMonth([datetime]$dt){ ($dt.ToString('yyyy'), $dt.ToString('MM')) }
function Sleep-ForQps([double]$qps){ if($qps -le 0){ return }; $ms = [math]::Ceiling(1000.0 / $qps); Start-Sleep -Milliseconds $ms }
function Has-Gh(){ try { $null = & gh --version 2>$null; return $LASTEXITCODE -eq 0 } catch { return $false } }

function Show-Progress($current, $total, $type, $id){
  if($NoProgress){ return }
  $pct = [math]::Round(($current / $total) * 100, 1)
  $bar = '█' * [math]::Floor($pct / 2)
  $space = '░' * (50 - [math]::Floor($pct / 2))
  Write-Host -NoNewline "`r[$bar$space] $pct% | $current/$total $type | Current: $id" -ForegroundColor Cyan
}

Ensure-Dir $OutRoot; Ensure-Dir (Join-Path $OutRoot 'threads'); Ensure-Dir $EvidenceRoot

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         🐾 BossCat Notifications Conveyor                     ║" -ForegroundColor Cyan
Write-Host "╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║  Chunk:     $ChunkSize (offset: $ChunkOffset)" -ForegroundColor Cyan
Write-Host "║  DryRun:    $DryRun" -ForegroundColor Cyan
Write-Host "║  MarkRead:  $MarkRead" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date
$threadsProcessed = 0
$threadsMarkedRead = 0

# Fetch threads (robust: prefer gh; fallback to REST; handle 404/permission)
Write-Host "📬 Fetching notifications..." -ForegroundColor Yellow
$threadsRaw = $null
if(Has-Gh){
  try {
    $threadsRaw = & gh api -H 'Accept: application/vnd.github+json' '/notifications' -f per_page=100 -f all=true --paginate
    if($LASTEXITCODE -ne 0){ throw "gh api /notifications failed (exit $LASTEXITCODE)" }
  } catch {
    Write-Host "   ⚠️  gh /notifications failed: $_" -ForegroundColor Yellow
  }
}
if(-not $threadsRaw){
  if(-not $Token){
    Write-Host "   ⚠️  No gh auth or GITHUB_TOKEN; notifications will be empty." -ForegroundColor Yellow
    Write-Host "   💡 For mark-read, use a PAT classic with notifications scope." -ForegroundColor Cyan
    $threadsRaw = '[]'
  } else {
    try {
      $headers = @{ 'Authorization' = "token $Token"; 'User-Agent'='BossCat-Notifications'; 'Accept'='application/vnd.github+json'; 'X-GitHub-Api-Version'='2022-11-28' }
      $threadsRaw = Invoke-RestMethod -Method GET -Headers $headers -Uri 'https://api.github.com/notifications?per_page=100&all=true' | ConvertTo-Json -Depth 100
    } catch {
      Write-Host "   ⚠️  REST /notifications failed: $_" -ForegroundColor Yellow
      $threadsRaw = '[]'
    }
  }
}

$threads = $threadsRaw | ConvertFrom-Json
$total = if($threads){ $threads.Count } else { 0 }
Append-Jsonl (Join-Path $EvidenceRoot 'METRICS.jsonl') @{ ts=(Get-Date).ToString('o'); metric='notifications_fetch'; meta=@{ count=$total } }
Write-Host "   Found $total notifications" -ForegroundColor Green
Write-Host ""

$start = $ChunkOffset; $end = [Math]::Min($start + $ChunkSize, $total) - 1
$chunkSize = $end - $start + 1

if($chunkSize -gt 0){
  Write-Host "🔄 Processing notifications: $chunkSize items ($start to $end)" -ForegroundColor Yellow
}

for($i=$start; $i -le $end -and $i -lt $total; $i++){
  $t = $threads[$i]
  $upd = try{ [datetime]$t.updated_at }catch{ Get-Date }
  $y,$m = New-YearMonth $upd
  $dir = Join-Path $OutRoot "threads/$y/$m"; Ensure-Dir $dir
  $id = $t.id
  $idx = $i - $start + 1
  
  if($chunkSize -gt 0){
    Show-Progress $idx $chunkSize "threads" "id:$id"
  }

  # Persist raw JSON and a friendly markdown snapshot
  ($t | ConvertTo-Json -Depth 50) | Set-Content -Path (Join-Path $dir ("thread-$id.json")) -Encoding utf8
  $md = @(
    "# Notification Thread $id",
    "",
    "- Repository: $($t.repository.full_name)",
    "- Reason: $($t.reason)",
    "- Updated: $($t.updated_at)",
    "- Unread: $($t.unread)",
    "- Subject: $($t.subject.type) - $($t.subject.title)",
    "- URL: $($t.url)",
    "- Subject URL: $($t.subject.url)",
    ""
  ) -join "`r`n"
  $md | Set-Content -Path (Join-Path $dir ("thread-$id.md")) -Encoding utf8

  $idx = @{ thread_id=$id; repo=$t.repository.full_name; reason=$t.reason; subject_type=$t.subject.type; updated_at=$t.updated_at; url=$t.url; done=(!$t.unread) }
  Append-Jsonl (Join-Path $OutRoot 'INDEX.jsonl') $idx

  if($MarkRead -and -not $DryRun){
    try{
      if(Has-Gh){ & gh api -X PATCH "/notifications/threads/$id" | Out-Null }
      else {
        $headers = @{ 'Authorization' = "token $Token"; 'User-Agent'='BossCat-Notifications'; 'Accept'='application/vnd.github+json' }
        Invoke-RestMethod -Method PATCH -Headers $headers -Uri "https://api.github.com/notifications/threads/$id" | Out-Null
      }
      Append-Jsonl (Join-Path $EvidenceRoot 'LEDGER.jsonl') @{ ts=(Get-Date).ToString('o'); action='THREAD_MARK_READ'; entity=$id; meta=@{} }
      $threadsMarkedRead++
      Sleep-ForQps $MutateQps
    } catch { 
      Write-Host ""
      Write-Host "   ⚠️  mark-read failed for ${id}: $_" -ForegroundColor Yellow 
    }
  }

  Sleep-ForQps $GetQps
}

if($chunkSize -gt 0){
  Write-Host ""
  Write-Host "   ✅ Threads processed: $threadsProcessed" -ForegroundColor Green
  if($MarkRead -and $threadsMarkedRead -gt 0){ 
    Write-Host "   ✅ Threads marked read: $threadsMarkedRead" -ForegroundColor Green 
  }
  Write-Host ""
}

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         ✅ BossCat Notifications Conveyor Complete            ║" -ForegroundColor Green
Write-Host "╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Threads:     $threadsProcessed processed" -ForegroundColor Green
if($MarkRead -and $threadsMarkedRead -gt 0){
Write-Host "║  Marked Read: $threadsMarkedRead" -ForegroundColor Green
}
Write-Host "║  Duration:    $($duration.TotalSeconds.ToString('F2'))s" -ForegroundColor Green
Write-Host "║  Evidence:    $EvidenceRoot" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
