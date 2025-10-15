param(
  [Parameter(Mandatory=$true)][string]$Owner,
  [Parameter(Mandatory=$true)][string]$Repo,
  [ValidateSet('alerts','analyses','alerts+analyses')][string]$Mode = 'alerts+analyses',
  [int]$ChunkOffset = 0,
  [int]$ChunkSize = 1000,
  [switch]$DryRun,
  [int]$DeleteAnalysesOlderThanDays = -1,
  [double]$GetQps = 2.0,
  [double]$MutateQps = 1.0,
  [string]$OutRoot = 'docs/BossCat/security',
  [string]$EvidenceRoot = 'CHAR/EVID/security',
  [string]$Token = $env:GITHUB_TOKEN,
  [switch]$IncludeDismissed = $true,
  [switch]$IncludeFixed
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$p){ if(-not(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Path $p -Force | Out-Null } }
function Append-Jsonl([string]$path, $obj){ $line = ($obj | ConvertTo-Json -Depth 10 -Compress); $line | Add-Content -Path $path -Encoding utf8 }
function New-YearMonth([datetime]$dt){ ($dt.ToString('yyyy'), $dt.ToString('MM')) }
function Sleep-ForQps([double]$qps){ if($qps -le 0){ return }; $ms = [math]::Ceiling(1000.0 / $qps); Start-Sleep -Milliseconds $ms }

function Has-Gh(){ try { $null = & gh --version 2>$null; return $LASTEXITCODE -eq 0 } catch { return $false } }

function Invoke-GhApi([string]$Path, [hashtable]$Params, [string]$Accept){
  if(Has-Gh){
    # Build query string manually
    if($Params.Count -gt 0){
      $qs = ($Params.Keys | ForEach-Object { "$_=$($Params[$_])" }) -join '&'
      $fullPath = "$Path`?$qs"
    } else {
      $fullPath = $Path
    }
    
    $args = @('api')
    if($Accept){ $args += @('-H', "Accept: $Accept") }
    $args += $fullPath
    $ErrorActionPreference = 'Continue'
    $out = & gh @args 2>&1
    if($LASTEXITCODE -ne 0){ throw "gh api failed: $fullPath (exit $LASTEXITCODE): $out" }
    return $out
  } else {
    if(-not $Token){ throw 'Missing GITHUB_TOKEN and gh CLI not available.' }
    $qs = ($Params.Keys | ForEach-Object { "$($_)=$([uri]::EscapeDataString($Params[$_]))" }) -join '&'
    $url = "https://api.github.com$Path" + (if($qs){"?$qs"}else{""})
    $headers = @{ 'Authorization' = "token $Token"; 'User-Agent'='BossCat-Archiver'; 'Accept' = ($Accept ?? 'application/vnd.github+json') }
    return (Invoke-RestMethod -Method GET -Uri $url -Headers $headers | ConvertTo-Json -Depth 100)
  }
}

function Invoke-GhApi-PaginateAlerts([string]$Owner,[string]$Repo,[string[]]$States){
  $all = @()
  foreach($st in $States){
    $page = 1
    while($true){
      $json = Invoke-GhApi "/repos/$Owner/$Repo/code-scanning/alerts" @{ per_page=100; page=$page; state=$st; sort='updated' } 'application/vnd.github+json'
      $arr = $json | ConvertFrom-Json
      if(-not $arr -or $arr.Count -eq 0){ break }
      $all += $arr
      if($arr.Count -lt 100){ break }
      $page++
      Sleep-ForQps $GetQps
    }
  }
  return $all
}

function Invoke-GhApi-PaginateAnalyses([string]$Owner,[string]$Repo){
  $all = @()
  $page = 1
  while($true){
    $json = Invoke-GhApi "/repos/$Owner/$Repo/code-scanning/analyses" @{ per_page=100; page=$page } 'application/vnd.github+json'
    $arr = $json | ConvertFrom-Json
    if(-not $arr -or $arr.Count -eq 0){ break }
    $all += $arr
    if($arr.Count -lt 100){ break }
    $page++
    Sleep-ForQps $GetQps
  }
  return $all
}

function Get-Sarif([int]$Id){
  $raw = Invoke-GhApi "/repos/$Owner/$Repo/code-scanning/analyses/$Id" @{} 'application/sarif+json'
  return $raw
}

function Write-AlertArtifacts($alert){
  $updated = try{ [datetime]$alert.updated_at }catch{ Get-Date }
  $y,$m = New-YearMonth $updated
  $dataDir = Join-Path $OutRoot "data/alerts/$y/$m"; Ensure-Dir $dataDir
  $mdDir   = Join-Path $OutRoot "alerts/$y/$m";   Ensure-Dir $mdDir
  $num = $alert.number
  $jsonPath = Join-Path $dataDir ("alert-$num.json")
  ($alert | ConvertTo-Json -Depth 50) | Set-Content -Path $jsonPath -Encoding utf8

  $state = $alert.state
  $sev = $alert.rule.severity
  $ruleId = $alert.rule.id
  $file = $alert.most_recent_instance.location.path
  $line = $alert.most_recent_instance.location.start_line
  $title = $alert.rule.description
  $html = $alert.html_url
  $created = $alert.created_at

  $badgeColor = if($state -eq 'open'){'red'} elseif($state -eq 'dismissed'){'yellow'} else {'green'}
  $md = @(
    "# Code Scanning Alert #$num"
    ""
    "- Rule: ``$ruleId``"
    "- Severity: ``$sev``"
    "- State: ``$state``"
    "- File: ``$file``:$line"
    "- Created: $created"
    "- Updated: $($alert.updated_at)"
    "- Link: $html"
    ""
    "> $title"
  ) -join "`r`n"
  $mdPath = Join-Path $mdDir ("alert-$num.md")
  $md | Set-Content -Path $mdPath -Encoding utf8

  $idx = @{ alert_number=$num; rule_id=$ruleId; severity=$sev; state=$state; created_at=$created; updated_at=$alert.updated_at; html_url=$html; file=$file; line=$line; commit_sha=$alert.most_recent_instance.commit_sha }
  Append-Jsonl (Join-Path $OutRoot 'INDEX_ALERTS.jsonl') $idx
}

function Write-AnalysisArtifacts($ana){
  $created = try{ [datetime]$ana.created_at }catch{ Get-Date }
  $y,$m = New-YearMonth $created
  $dir = Join-Path $OutRoot "analyses/$y/$m"; Ensure-Dir $dir
  $rawDir = Join-Path $OutRoot "data/analyses/$y/$m"; Ensure-Dir $rawDir
  $id = [int]$ana.id

  # Save metadata JSON
  ($ana | ConvertTo-Json -Depth 50) | Set-Content -Path (Join-Path $rawDir ("analysis-$id.json")) -Encoding utf8

  # Fetch SARIF (graceful on HTTP 422 or other API errors)
  try {
    $sarif = Get-Sarif -Id $id
    $sarifPath = Join-Path $dir ("analysis-$id.sarif.json")
    $sarif | Set-Content -Path $sarifPath -Encoding utf8

    $idx = @{ analysis_id=$id; tool=$ana.tool.name; ref=$ana.ref; commit_sha=$ana.commit_sha; created_at=$ana.created_at; sarif_path=$sarifPath; alerts_count=$ana.results_count }
    Append-Jsonl (Join-Path $OutRoot 'INDEX_ANALYSES.jsonl') $idx
  } catch {
    Write-Host "SKIP SARIF for analysis $id (unavailable): $_" -ForegroundColor Yellow
    Write-Ledger 'ANALYSIS_SARIF_UNAVAILABLE' $id @{ created_at=$ana.created_at; reason="$_" }
    Write-Metrics 'analyses_sarif_skip' @{ analysis_id=$id }
  }
}

function Write-Ledger($action,$entity,$meta){
  Ensure-Dir $EvidenceRoot
  $rec = @{ ts=(Get-Date).ToString('o'); action=$action; entity=$entity; meta=$meta }
  Append-Jsonl (Join-Path $EvidenceRoot 'LEDGER.jsonl') $rec
}

function Write-Metrics($name,$meta){
  Ensure-Dir $EvidenceRoot
  $rec = @{ ts=(Get-Date).ToString('o'); metric=$name; meta=$meta }
  Append-Jsonl (Join-Path $EvidenceRoot 'METRICS.jsonl') $rec
}

# Ensure base dirs
Ensure-Dir $OutRoot; Ensure-Dir (Join-Path $OutRoot 'alerts'); Ensure-Dir (Join-Path $OutRoot 'analyses'); Ensure-Dir (Join-Path $OutRoot 'data')
Ensure-Dir $EvidenceRoot

Write-Host "[BossCat] Security conveyor starting ($Mode) for $Owner/$Repo (DryRun=$DryRun)" -ForegroundColor Cyan

if($Mode -in @('alerts','alerts+analyses')){
  $states = @('open'); if($IncludeDismissed){ $states += 'dismissed' }; if($IncludeFixed){ $states += 'fixed' }
  $alerts = Invoke-GhApi-PaginateAlerts $Owner $Repo $states
  $total = $alerts.Count
  Write-Metrics 'alerts_fetch' @{ count=$total }
  $start = $ChunkOffset; $end = [Math]::Min($start + $ChunkSize, $total) - 1
  for($i=$start; $i -le $end -and $i -lt $total; $i++){
    $a = $alerts[$i]
    if(-not $DryRun){ Write-AlertArtifacts $a; Write-Ledger 'ARCHIVED_ALERT' $a.number @{ state=$a.state } } else { Write-Host "DRY: alert #$($a.number)" }
    Sleep-ForQps $GetQps
  }
}

if($Mode -in @('analyses','alerts+analyses')){
  $analyses = Invoke-GhApi-PaginateAnalyses $Owner $Repo
  $totalA = $analyses.Count
  Write-Metrics 'analyses_fetch' @{ count=$totalA }
  $startA = $ChunkOffset; $endA = [Math]::Min($startA + $ChunkSize, $totalA) - 1
  for($j=$startA; $j -le $endA -and $j -lt $totalA; $j++){
    $an = $analyses[$j]
    if(-not $DryRun){ Write-AnalysisArtifacts $an; Write-Ledger 'ARCHIVED_ANALYSIS' $an.id @{ deletable=$an.deletable } } else { Write-Host "DRY: analysis id $($an.id)" }
    Sleep-ForQps $GetQps
  }

  if(-not $DryRun -and $DeleteAnalysesOlderThanDays -ge 0){
    $cut = (Get-Date).AddDays(-$DeleteAnalysesOlderThanDays)
    $old = $analyses | Where-Object { ($_.created_at) -as [datetime] -lt $cut -and $_.deletable -eq $true }
    foreach($o in $old){
      # Hard gate: only proceed if archived SARIF exists
      $y,$m = New-YearMonth ([datetime]$o.created_at)
      $sarifPath = Join-Path $OutRoot "analyses/$y/$m/analysis-$($o.id).sarif.json"
      if(-not (Test-Path -LiteralPath $sarifPath)){ Write-Host "SKIP delete $($o.id): no archived SARIF" -ForegroundColor Yellow; continue }
      if($DryRun){ Write-Host "DRY: would delete analysis $($o.id)"; continue }
      # Mutate lane: DELETE analysis with confirm flag
      try {
        if(Has-Gh){ & gh api -X DELETE "/repos/$Owner/$Repo/code-scanning/analyses/$($o.id)" -f confirm_delete=true | Out-Null }
        else {
          if(-not $Token){ throw 'Missing GITHUB_TOKEN for deletes' }
          $headers = @{ 'Authorization' = "token $Token"; 'User-Agent'='BossCat-Archiver'; 'Accept'='application/vnd.github+json' }
          Invoke-RestMethod -Method DELETE -Headers $headers -Uri "https://api.github.com/repos/$Owner/$Repo/code-scanning/analyses/$($o.id)?confirm_delete=true" | Out-Null
        }
        Write-Ledger 'ANALYSIS_DELETED' $o.id @{ created_at=$o.created_at }
        Sleep-ForQps $MutateQps
      } catch {
        Write-Host "WARN: delete failed for analysis $($o.id): $_" -ForegroundColor Yellow
      }
    }
  }
}

Write-Host "[BossCat] Security conveyor complete." -ForegroundColor Green
