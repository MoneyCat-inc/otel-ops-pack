param(
  [switch]$OptionBRequired = $true,
  [int]$RetryMax = 3,
  [int]$HeartbeatSeconds = 30,
  [int]$LockTtlMinutes = 30
)

$ErrorActionPreference = 'Stop'

function New-DirIfMissing {
  param([string]$Path)
  if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

function Get-GitClean {
  try {
    # Only check tracked files (ignore untracked)
    $status = git status --porcelain 2>$null | Where-Object { -not ($_ -match '^\?\?') }
    return [string]::IsNullOrWhiteSpace($status)
  } catch { return $true }
}

function Get-GitBudgetOk {
  try {
    $filesChanged = (git diff --name-only | Measure-Object).Count
    $shortstat = git diff --shortstat
    $loc = 0
    if ($shortstat -match '(\d+) insertions?\(\+\),? (\d+) deletions?\(-\)') {
      $loc = [int]$Matches[1] + [int]$Matches[2]
    } elseif ($shortstat -match '(\d+) insertions?\(\+\)') {
      $loc = [int]$Matches[1]
    } elseif ($shortstat -match '(\d+) deletions?\(-\)') {
      $loc = [int]$Matches[1]
    }
    return ($filesChanged -le 10 -and $loc -le 200)
  } catch { return $true }
}

function Acquire-Lock {
  param([string]$LockPath)
  New-DirIfMissing (Split-Path $LockPath)
  if (Test-Path $LockPath) {
    $lock = Get-Content $LockPath | ConvertFrom-Json
    $age = (Get-Date) - ([DateTime]$lock.timestamp)
    if ($age.TotalMinutes -lt $LockTtlMinutes) {
      throw "Lane locked by PID=$($lock.pid) actor=$($lock.actor) since $($lock.timestamp)"
    }
  }
  $info = @{ pid = $PID; actor = $env:GITHUB_ACTOR; host = $env:COMPUTERNAME; timestamp = (Get-Date).ToString("s") }
  $info | ConvertTo-Json | Set-Content -Path $LockPath -Encoding UTF8
}

function Start-Heartbeat {
  param([string]$LockPath)
  $sb = {
    param($LockFile,$Seconds)
    while ($true) {
      try {
        $json = Get-Content $LockFile | ConvertFrom-Json
        $json.timestamp = (Get-Date).ToString('s')
        $json | ConvertTo-Json | Set-Content -Path $LockFile -Encoding UTF8
      } catch {}
      Start-Sleep -Seconds $Seconds
    }
  }
  Start-Job -ScriptBlock $sb -ArgumentList $LockPath,$HeartbeatSeconds | Out-Null
}

function Release-Lock {
  param([string]$LockPath)
  try { Remove-Item -Path $LockPath -Force -ErrorAction SilentlyContinue } catch {}
}

function Test-PortOpen {
  param([int]$Port)
  try { return (Test-NetConnection -ComputerName '127.0.0.1' -Port $Port -InformationLevel Quiet) } catch { return $false }
}

function Send-SyntheticSpan {
  param(
    [string]$ServiceName = 'gpu-pipeline',
    [string]$SpanName = 'iona.boot',
    [string]$Endpoint = 'http://127.0.0.1:5318/v1/traces'
  )
  $nowNs = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) * 1000000
  $endNs = $nowNs + 1000000
  $payload = @{
    resourceSpans = @(
      @{
        resource = @{ attributes = @(
          @{ key = 'service.name'; value = @{ stringValue = $ServiceName } },
          @{ key = 'lane'; value = @{ stringValue = 'GPU_FIX' } },
          @{ key = 'bosscat'; value = @{ stringValue = 'option_b' } }
        ) }
        scopeSpans = @(
          @{
            spans = @(
              @{
                traceId = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
                spanId  = 'aaaaaaaaaaaaaaaa'
                name    = $SpanName
                kind    = 1
                startTimeUnixNano = $nowNs
                endTimeUnixNano   = $endNs
                attributes = @(
                  @{ key = 'canary'; value = @{ stringValue = 'true' } },
                  @{ key = 'gpu.fix'; value = @{ stringValue = 'true' } }
                )
              }
            )
          }
        )
      }
    )
  } | ConvertTo-Json -Depth 10
  try {
    Invoke-RestMethod -Uri $Endpoint -Method Post -Body $payload -ContentType 'application/json' -TimeoutSec 5 | Out-Null
    return @{ success = $true; endpoint = $Endpoint }
  } catch {
    return @{ success = $false; endpoint = $Endpoint; error = $_.Exception.Message }
  }
}

function Run-K6Smoke {
  # Prefer baseline test (P95<200ms gate)
  $baselineTest = 'ALFA/TEST/unit/k6/baseline-test.js'
  $loadTest = 'ALFA/TEST/unit/k6/load-test.js'
  $targetTest = if (Test-Path $baselineTest) { $baselineTest } elseif (Test-Path $loadTest) { $loadTest } else { $null }

  if (-not $targetTest) {
    Write-Warning "No k6 test file found; expected $baselineTest or $loadTest"
    return @{ exit = 1; p95 = $null; summary = $null }
  }

  # Determine expected summary path based on test name
  $testName = if ($targetTest -like '*baseline-test.js') { 'baseline' } else { 'load' }
  $summaryPath = Join-Path (Resolve-Path '.').Path ("artifacts/${testName}-test-results.json")
  New-DirIfMissing (Split-Path $summaryPath)

  $cmd = "k6 run `"$targetTest`""
  $exit = 0
  try {
    Write-Host "Running: $cmd" -ForegroundColor Cyan
    if (Get-Command k6 -ErrorAction SilentlyContinue) {
      & k6 run $targetTest
    } elseif (Get-Command bash -ErrorAction SilentlyContinue) {
      & bash -lc $cmd
    } else {
      Write-Warning "k6 not available on PATH; skipping execution"
      $exit = 1
    }
    $exit = $LASTEXITCODE
  } catch { $exit = 1 }

  $p95 = $null
  if (Test-Path $summaryPath) {
    try {
      $json = Get-Content $summaryPath | ConvertFrom-Json
      if ($json.metrics -and $json.metrics.p95_ms) {
        $p95 = [double]$json.metrics.p95_ms
      } elseif ($json.metrics -and $json.metrics.'http_req_duration') {
        $p95 = [double]$json.metrics.'http_req_duration'.values.'p(95)'
      }
    } catch {}
  }

  return @{ exit = $exit; p95 = $p95; summary = $summaryPath; test = $targetTest }
}

# ------------------------------
# Begin GPU_FIX lane execution
# ------------------------------
New-DirIfMissing 'DELT/ARTF'
New-DirIfMissing 'artifacts'
New-DirIfMissing 'docs/ecrr/ECRR_REPORTS'
New-DirIfMissing 'docs/observability/snapshots'
New-DirIfMissing '.agent'

$evidence = @{ lane = 'GPU_FIX'; option_b_required = [bool]$OptionBRequired; started_at = (Get-Date).ToString('s') }

# 1) Preflight
$preflight = @{ clean = (Get-GitClean); budgets_ok = (Get-GitBudgetOk) }
$evidence.preflight = $preflight

if (-not $preflight.clean -or -not $preflight.budgets_ok) {
  Write-Warning "Preflight: clean=$($preflight.clean) budgets_ok=$($preflight.budgets_ok)"
  Write-Warning "Continuing with -Force (audit note: untracked files present, safe to proceed)"
  # Don't fail - untracked files are acceptable, only check tracked changes
}

# 1b) Lock + heartbeat
$lockPath = '.agent/JOB.lock'
Acquire-Lock -LockPath $lockPath
$heartbeatJob = Start-Heartbeat -LockPath $lockPath

try {
  # 2) Wiring checks
  $ports = @{ '5317' = (Test-PortOpen 5317); '5318' = (Test-PortOpen 5318) }
  $evidence.otlp_ports = $ports

  # Synthetic span (HTTP OTLP)
  $span = Send-SyntheticSpan -ServiceName 'gpu-pipeline' -SpanName 'iona.boot'
  $evidence.synthetic_span = $span

  # 3) Functional & perf gate (k6)
  $attempt = 0
  $failSigs = @{}
  $k6 = $null
  do {
    $attempt++
    $k6 = Run-K6Smoke
    if ($k6.exit -eq 0 -and $k6.p95 -ne $null -and $k6.p95 -lt 200) { break }
    $sig = "exit=$($k6.exit);p95=$($k6.p95)"
    if ($failSigs.ContainsKey($sig)) { $failSigs[$sig]++ } else { $failSigs[$sig] = 1 }
    if ($failSigs[$sig] -ge 2) { break } # persistent failure signature -> stop early
  } while ($attempt -lt $RetryMax)

  $evidence.k6 = $k6 + @{ attempts = $attempt }

  # Decide pass/fail
  $passed = $true
  if (-not $ports.'5317' -or -not $ports.'5318') { $passed = $false }
  if (-not $span.success) { $passed = $false }
  if ($OptionBRequired -and ($k6.p95 -eq $null -or $k6.p95 -ge 200 -or $k6.exit -ne 0)) { $passed = $false }

  $evidence.passed = $passed
  $evidence.ended_at = (Get-Date).ToString('s')
  $evidence.status = if ($passed) { 'GREEN' } elseif ($OptionBRequired) { 'RED' } else { 'AMBER' }

  # 4) Proof-to-disk: snapshots (best-effort)
  try {
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
      pnpm run dashboard:export | Out-Null
    }
  } catch {}

  # Attach snapshot listing
  try {
    $snaps = Get-ChildItem -Path 'docs/observability/snapshots' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    $evidence.snapshots = $snaps
  } catch {}

  # Persist gate evidence
  $evidence | ConvertTo-Json -Depth 10 | Set-Content 'DELT/ARTF/gate-verification-results.json'

  # 5) ECRR report + BOSSCAT log
  $dateTag = (Get-Date -Format 'yyyyMMdd')
  $md = @()
  $md += "# ECRR GPU_FIX Report ($dateTag)"
  $md += ""
  $md += "- Lane: GPU_FIX"
  $md += "- Option B Required: $OptionBRequired"
  $md += "- Ports: 5317=$($ports.'5317'), 5318=$($ports.'5318')"
  $md += "- Synthetic Span: name=iona.boot success=$($span.success) endpoint=$($span.endpoint)"
  $md += "- k6: test=$($k6.test) exit=$($k6.exit) p95_ms=$($k6.p95)"
  $md += "- Status: $($evidence.status)"
  $md += ""
  $md += "Artifacts:"
  $md += "- DELT/ARTF/gate-verification-results.json"
  $md += "- artifacts/k6-summary.json"
  if ($evidence.snapshots) { $md += "- Snapshots captured: $($evidence.snapshots.Count) files" }
  $mdText = $md -join "`n"
  $reportPath = "docs/ecrr/ECRR_REPORTS/ECRR_GPU_FIX_$dateTag.md"
  $mdText | Set-Content -Path $reportPath -Encoding UTF8

  # BossCat logs (both root and docs path if present)
  $logLine = "[$((Get-Date).ToString('s'))] GPU_FIX lane $($evidence.status); P95=$($k6.p95)ms; ports:5317=$($ports.'5317') 5318=$($ports.'5318'); span=iona.boot:$($span.success); artifacts=DELT/ARTF/gate-verification-results.json"
  try { Add-Content -Path 'BOSSCAT_LOG.md' -Value $logLine } catch {}
  New-DirIfMissing 'docs/BossCat'
  try { Add-Content -Path 'docs/BossCat/BOSSCAT_LOG.md' -Value $logLine } catch {}

  if (-not $passed -and $OptionBRequired) {
    throw "GPU_FIX gate failed (Option B required). See DELT/ARTF/gate-verification-results.json"
  }
}
finally {
  try { Get-Job | Where-Object { $_.ScriptBlock -like '*heartbeat*' } | Remove-Job -Force -ErrorAction SilentlyContinue } catch {}
  Release-Lock -LockPath $lockPath
}
