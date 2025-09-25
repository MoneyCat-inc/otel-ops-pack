# Pester tests: latency measurements for OTLP HTTP, filelog, and Windows Event Log

param(
  [int]$MaxWaitMs = 8000,
  [int]$PollIntervalMs = 300,
  [string]$ArtifactsDir = (Join-Path (Resolve-Path "..").Path "artifacts")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ArtifactsDir)) { New-Item -ItemType Directory -Force -Path $ArtifactsDir | Out-Null }

function Invoke-SigNozLogsQuery {
  param(
    [string]$Expression,
    [int]$MinutesBack = 5
  )
  $now = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()); $start = $now - [long]($MinutesBack * 60000)
  $payload = @{ start=$start; end=$now; requestType="raw"; compositeQuery=@{ queries=@(@{ type="builder_query"; spec=@{ name="A"; signal="logs"; filter=@{ expression=$Expression }; order=@(@{ key=@{ name="timestamp" }; direction="desc" }); limit=10; offset=0 }}) } } | ConvertTo-Json -Depth 8
  Invoke-RestMethod -Method Post -Uri 'http://localhost:8080/api/v5/query_range' -ContentType 'application/json' -Body $payload -TimeoutSec 10
}

function Measure-OTLPHttpLatency {
  param([int]$PollMs = 300,[int]$MaxMs = 8000)
  $eid = [Guid]::NewGuid().ToString()
  $payload = @{ event="latency_test_otlp_http"; event_id=$eid; dataset="ecrr-canary"; canary="true"; timestamp=(Get-Date).ToString("o") } | ConvertTo-Json -Compress
  $t0 = Get-Date
  Invoke-RestMethod -Uri 'http://localhost:5318/v1/logs' -Method Post -Body $payload -ContentType 'application/json' -TimeoutSec 3 | Out-Null
  $seen = $false; $latMs = $null
  while (-not $seen -and ((Get-Date) - $t0).TotalMilliseconds -lt $MaxMs) {
    Start-Sleep -Milliseconds $PollMs
    try {
      $expr = "attributes.dataset = `"ecrr-canary`" OR attributes.dataset = `"ecrr_canary`" OR body contains `"$eid`""
      $resp = Invoke-SigNozLogsQuery -Expression $expr -MinutesBack 2
      $json = $resp | ConvertTo-Json -Depth 8
      if ($json -match $eid) { $seen = $true; $latMs = [int]((Get-Date) - $t0).TotalMilliseconds }
    } catch { }
  }
  return @{ source='otlp_http'; event_id=$eid; seen=$seen; latency_ms=$latMs }
}

function Measure-FilelogLatency {
  param([int]$PollMs = 300,[int]$MaxMs = 8000)
  $eid = [Guid]::NewGuid().ToString()
  $dir = 'C:\logs\latency-tests'
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $file = Join-Path $dir ("filelog-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
  $line = ("{0:o} filelog latency probe id={1}" -f (Get-Date), $eid)
  $t0 = Get-Date
  $line | Add-Content -Path $file -Encoding UTF8
  $seen = $false; $latMs = $null
  while (-not $seen -and ((Get-Date) - $t0).TotalMilliseconds -lt $MaxMs) {
    Start-Sleep -Milliseconds $PollMs
    try {
      $expr = "log.file.path contains `"C:/logs/latency-tests/`" AND (body contains `"$eid`")"
      $resp = Invoke-SigNozLogsQuery -Expression $expr -MinutesBack 2
      $json = $resp | ConvertTo-Json -Depth 8
      if ($json -match $eid) { $seen = $true; $latMs = [int]((Get-Date) - $t0).TotalMilliseconds }
    } catch { }
  }
  return @{ source='filelog'; event_id=$eid; seen=$seen; latency_ms=$latMs; file=$file }
}

function Measure-WinEventLatency {
  param([int]$PollMs = 300,[int]$MaxMs = 8000)
  $eid = [Guid]::NewGuid().ToString()
  $src = 'SigNozTest'
  if (-not [System.Diagnostics.EventLog]::SourceExists($src)) {
    New-EventLog -LogName Application -Source $src
  }
  $msg = "Latency probe event_id=$eid"
  $t0 = Get-Date
  Write-EventLog -LogName Application -Source $src -EventId 1001 -EntryType Information -Message $msg
  $seen = $false; $latMs = $null
  while (-not $seen -and ((Get-Date) - $t0).TotalMilliseconds -lt $MaxMs) {
    Start-Sleep -Milliseconds $PollMs
    try {
      $expr = "attributes.winlog.channel = `"Application`" AND (body contains `"$eid`")"
      $resp = Invoke-SigNozLogsQuery -Expression $expr -MinutesBack 2
      $json = $resp | ConvertTo-Json -Depth 8
      if ($json -match $eid) { $seen = $true; $latMs = [int]((Get-Date) - $t0).TotalMilliseconds }
    } catch { }
  }
  return @{ source='windows_event'; event_id=$eid; seen=$seen; latency_ms=$latMs }
}

Describe 'Latency measurements' {
  It 'Measures OTLP HTTP ingest latency' {
    $r = Measure-OTLPHttpLatency -PollMs $PollIntervalMs -MaxMs $MaxWaitMs
    ($r.seen) | Should Be $true
    $r.latency_ms | Should -BeLessThan $MaxWaitMs
    ($r | ConvertTo-Json) | Out-File -FilePath (Join-Path $ArtifactsDir "latency-otlp-http.json") -Encoding utf8
  }
  It 'Measures filelog ingest latency' {
    $r = Measure-FilelogLatency -PollMs $PollIntervalMs -MaxMs $MaxWaitMs
    ($r.seen) | Should Be $true
    $r.latency_ms | Should -BeLessThan $MaxWaitMs
    ($r | ConvertTo-Json) | Out-File -FilePath (Join-Path $ArtifactsDir "latency-filelog.json") -Encoding utf8
  }
  It 'Measures Windows Event Log ingest latency' {
    $r = Measure-WinEventLatency -PollMs $PollIntervalMs -MaxMs $MaxWaitMs
    ($r.seen) | Should Be $true
    $r.latency_ms | Should -BeLessThan $MaxWaitMs
    ($r | ConvertTo-Json) | Out-File -FilePath (Join-Path $ArtifactsDir "latency-winevent.json") -Encoding utf8
  }
}


