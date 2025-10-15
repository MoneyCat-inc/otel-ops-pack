param(
  [int]$ChunkOffset = 0,
  [int]$ChunkSize = 1000,
  [switch]$DryRun,
  [switch]$MarkRead,
  [double]$GetQps = 2.0,
  [double]$MutateQps = 2.0,
  [string]$OutRoot = 'docs/BossCat/notifications',
  [string]$EvidenceRoot = 'CHAR/EVID/notifications',
  [string]$Token = $env:GITHUB_TOKEN
)

$ErrorActionPreference = 'Stop'
function Ensure-Dir([string]$p){ if(-not(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Path $p -Force | Out-Null } }
function Append-Jsonl([string]$path, $obj){ $line = ($obj | ConvertTo-Json -Depth 10 -Compress); $line | Add-Content -Path $path -Encoding utf8 }
function New-YearMonth([datetime]$dt){ ($dt.ToString('yyyy'), $dt.ToString('MM')) }
function Sleep-ForQps([double]$qps){ if($qps -le 0){ return }; $ms = [math]::Ceiling(1000.0 / $qps); Start-Sleep -Milliseconds $ms }
function Has-Gh(){ try { $null = & gh --version 2>$null; return $LASTEXITCODE -eq 0 } catch { return $false } }

Ensure-Dir $OutRoot; Ensure-Dir (Join-Path $OutRoot 'threads'); Ensure-Dir $EvidenceRoot

Write-Host "[BossCat] Notifications conveyor starting (DryRun=$DryRun, MarkRead=$MarkRead)" -ForegroundColor Cyan

# Fetch threads (robust: prefer gh; fallback to REST; handle 404/permission)
$threadsRaw = $null
if(Has-Gh){
  try {
    $threadsRaw = & gh api -H 'Accept: application/vnd.github+json' '/notifications' -f per_page=100 -f all=true --paginate
    if($LASTEXITCODE -ne 0){ throw "gh api /notifications failed (exit $LASTEXITCODE)" }
  } catch {
    Write-Host "WARN: gh /notifications failed: $_" -ForegroundColor Yellow
  }
}
if(-not $threadsRaw){
  if(-not $Token){
    Write-Host "WARN: No gh auth or GITHUB_TOKEN; notifications will be empty. For mark-read, use a PAT classic with notifications scope." -ForegroundColor Yellow
    $threadsRaw = '[]'
  } else {
    try {
      $headers = @{ 'Authorization' = "token $Token"; 'User-Agent'='BossCat-Notifications'; 'Accept'='application/vnd.github+json'; 'X-GitHub-Api-Version'='2022-11-28' }
      $threadsRaw = Invoke-RestMethod -Method GET -Headers $headers -Uri 'https://api.github.com/notifications?per_page=100&all=true' | ConvertTo-Json -Depth 100
    } catch {
      Write-Host "WARN: REST /notifications failed: $_" -ForegroundColor Yellow
      $threadsRaw = '[]'
    }
  }
}

$threads = $threadsRaw | ConvertFrom-Json
$total = if($threads){ $threads.Count } else { 0 }
Append-Jsonl (Join-Path $EvidenceRoot 'METRICS.jsonl') @{ ts=(Get-Date).ToString('o'); metric='notifications_fetch'; meta=@{ count=$total } }

$start = $ChunkOffset; $end = [Math]::Min($start + $ChunkSize, $total) - 1
for($i=$start; $i -le $end -and $i -lt $total; $i++){
  $t = $threads[$i]
  $upd = try{ [datetime]$t.updated_at }catch{ Get-Date }
  $y,$m = New-YearMonth $upd
  $dir = Join-Path $OutRoot "threads/$y/$m"; Ensure-Dir $dir
  $id = $t.id

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
      Sleep-ForQps $MutateQps
    } catch { Write-Host "WARN: mark-read failed for ${id}: $_" -ForegroundColor Yellow }
  }

  Sleep-ForQps $GetQps
}

Write-Host "[BossCat] Notifications conveyor complete." -ForegroundColor Green
