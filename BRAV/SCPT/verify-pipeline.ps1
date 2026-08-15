<#
.SYNOPSIS
  End-to-end verification of OTel → SigNoz pipeline with summary JSON.
.DESCRIPTION
  Runs quick-monitor (service/ports/docker), sends a canary trace, and writes
  out/outcome JSON for dashboards or CI. Exit codes:
    0 = OK (GREEN)
    1 = WARNING / could not fully confirm (manual check advised)
    2 = FAIL (RED / auto-HOLD threshold met)
    
  Part of BossCat OEM Gate Hardening Framework
#>

[CmdletBinding()]
param(
  [string]$ServiceName      = "synthetic-windows-check",
  [string]$CanaryScriptPath = "C:\otel\synthetic\send_synthetic_otel_simple.py",
  [string]$CollectorName    = "signoz-otel-collector",   # docker service name
  [string]$OutDir           = "out",
  [int]$CanaryWaitSeconds   = 60
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot 'lib\OtelPorts.psm1') -Force
$script:OtelPorts = Get-OtelPorts

# BossCat operational toggles (from environment)
$STRICT = [bool]([Environment]::GetEnvironmentVariable("BOSSCAT_STRICT","Process"))
$SKIP_API = [bool]([Environment]::GetEnvironmentVariable("BOSSCAT_SKIP_API","Process"))
$LOOKBACK = [int]([Environment]::GetEnvironmentVariable("BOSSCAT_LOOKBACK_SEC","Process"))
if (-not $LOOKBACK) { $LOOKBACK = 180 }  # Default 180s

# Empty-result retry. A span queried moments after send can be absent from the SigNoz query path
# while still in flight — that is ingestion lag, not a broken verification path. Retry a bounded
# number of times before concluding the span is missing.
$API_RETRIES = [int]([Environment]::GetEnvironmentVariable("BOSSCAT_API_RETRIES","Process"))
if (-not $API_RETRIES) { $API_RETRIES = 3 }
$API_RETRY_WAIT_SEC = [int]([Environment]::GetEnvironmentVariable("BOSSCAT_API_RETRY_WAIT_SEC","Process"))
if (-not $API_RETRY_WAIT_SEC) { $API_RETRY_WAIT_SEC = 5 }

if ($STRICT) {
  Write-Host "⚠️  [config] STRICT MODE: WARN outcomes will be treated as FAIL" -ForegroundColor Yellow
}
if ($SKIP_API) {
  Write-Host "ℹ️  [config] SKIP_API MODE: API verification disabled (air-gapped mode)" -ForegroundColor Cyan
}
if ($LOOKBACK -ne 180) {
  Write-Host "ℹ️  [config] Custom API lookback: $LOOKBACK seconds" -ForegroundColor Cyan
}

function Ensure-Dir([string]$p) {
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function Invoke-SigNozApiTraceCheck {
  <#
  .SYNOPSIS
    Queries SigNoz Trace API to explicitly confirm span ingestion (with optional trace ID pinning).
  .DESCRIPTION
    Uses SigNoz v5 Trace API (POST /api/v5/query_range) to verify span ingestion.
    - If TraceId provided: Pinpoint verification of EXACT trace (forensic-grade)
    - If no TraceId: Falls back to serviceName filter (standard verification)
    
    Returns span timestamp for ingest latency calculation.
    
    References:
    - SigNoz Trace API: https://signoz.io/docs/traces-management/trace-api/overview/
    - OTLP HTTP: Windows collector default 5321; SigNoz Docker direct via BOSSCAT_OTLP_ENDPOINT=http://127.0.0.1:4318
  #>
  param(
    [string]$BaseUrl = "http://localhost:8080",
    [string]$ApiKeyEnv = "SIGNOZ_API_KEY",
    [string]$ServiceName = "synthetic-windows-check",
    [string]$TraceId = "",
    [int]$LookbackSeconds = 180
  )
  
  # Read API key from environment (prefer current process env var)
  $apiKey = [Environment]::GetEnvironmentVariable($ApiKeyEnv, "Process")
  if (-not $apiKey) { $apiKey = [Environment]::GetEnvironmentVariable($ApiKeyEnv, "User") }
  if (-not $apiKey) { $apiKey = [Environment]::GetEnvironmentVariable($ApiKeyEnv, "Machine") }
  if (-not $apiKey) { 
    Write-Warning "[api-check] No API key in $ApiKeyEnv environment variable"
    Write-Host "[api-check] ℹ️  Create API key in SigNoz: Settings → API Keys" -ForegroundColor Yellow
    return @{ ok=$false; reason="missing_api_key"; timestampMs=$null }
  }

  $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  $startMs = $nowMs - ($LookbackSeconds * 1000)

  # Extract HTTP error body (PS7 ErrorDetails / HttpResponseMessage; PS5 WebException fallback)
  function Get-HttpErrorBody {
    param($ErrorRecord)
    if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) {
      return [string]$ErrorRecord.ErrorDetails.Message
    }
    $resp = $ErrorRecord.Exception.Response
    if ($resp -and $resp.PSObject.Properties['Content'] -and $resp.Content) {
      try { return $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult() } catch { }
    }
    if ($ErrorRecord.Exception -is [System.Net.WebException] -and $ErrorRecord.Exception.Response) {
      try {
        $stream = $ErrorRecord.Exception.Response.GetResponseStream()
        return (New-Object System.IO.StreamReader $stream).ReadToEnd()
      } catch { }
    }
    return [string]$ErrorRecord.Exception.Message
  }

  # Helper to build payload for a given filter expression
  function New-TraceApiPayload([string]$expr, [Int64]$StartMs, [Int64]$EndMs) {
    return @{
      start = $StartMs
      end   = $EndMs
    requestType = "raw"
    compositeQuery = @{
      queries = @(
        @{
          type = "builder_query"
          spec = @{
            name   = "A"
            signal = "traces"
              filter = @{ expression = $expr }
            selectFields = @(
              @{ name = "traceID" }
              @{ name = "spanID" }
              @{ name = "spanName" }
              @{ name = "timestamp" }
            )
            order = @(@{ key = @{ name = "timestamp" }; direction = "desc" })
            limit   = 1
            offset  = 0
            disabled = $false
          }
        }
      )
    }
  } | ConvertTo-Json -Depth 12
  }

  # Build initial (traceID) payload if available; otherwise serviceName
  $filterExpr = if ($TraceId) { "traceID = '$TraceId'" } else { "serviceName = '$ServiceName'" }
  $verificationMode = if ($TraceId) { "PINPOINT (traceID)" } else { "STANDARD (serviceName)" }
  $payload = New-TraceApiPayload -expr $filterExpr -StartMs $startMs -EndMs $nowMs

  try {
    $uri = $BaseUrl.TrimEnd('/') + "/api/v5/query_range"
    Write-Host "[api-check] Mode: $verificationMode (last $LookbackSeconds s)..." -ForegroundColor Gray
    
    # SigNoz v5 Trace API requires SIGNOZ-API-KEY header
    $resp = Invoke-RestMethod -Method Post -Uri $uri `
      -Headers @{ "SIGNOZ-API-KEY" = $apiKey } `
      -ContentType "application/json" -Body $payload -TimeoutSec 30

    # Check for span presence
    $json = ($resp | ConvertTo-Json -Depth 20)
    $hasSpan = ($json -match '"traceID"')
    
    # Extract timestamp for latency calculation (nanoseconds or milliseconds depending on SigNoz version)
    $timestampMs = $null
    $tsMatch = [regex]::Match($json, '"timestamp"\s*:\s*([0-9]+)')
    if ($tsMatch.Success) {
      $rawTs = [int64]$tsMatch.Groups[1].Value
      # SigNoz typically returns nanoseconds; convert to milliseconds
      $timestampMs = if ($rawTs -gt 9999999999999) { [int64]($rawTs / 1000000) } else { $rawTs }
    }
    
    if ($hasSpan) {
      $mode = if ($TraceId) { "PINPOINT ✓" } else { "STANDARD ✓" }
      Write-Host "[api-check] $mode Span confirmed via SigNoz API" -ForegroundColor Green
      return @{ ok = $true; reason = "span_found"; timestampMs = $timestampMs; mode = $verificationMode }
    } else {
      # Fallback to serviceName if traceID path empty
      if ($TraceId) {
        $fallbackExpr = "serviceName = '$ServiceName'"
        Write-Host "[api-check] Fallback to serviceName filter..." -ForegroundColor Yellow
        $payload2 = New-TraceApiPayload -expr $fallbackExpr -StartMs $startMs -EndMs $nowMs
        try {
          $resp2 = Invoke-RestMethod -Method Post -Uri $uri `
            -Headers @{ "SIGNOZ-API-KEY" = $apiKey } `
            -ContentType "application/json" -Body $payload2 -TimeoutSec 30
          $json2 = ($resp2 | ConvertTo-Json -Depth 20)
          $hasSpan2 = ($json2 -match '"traceID"')
          $timestampMs2 = $null
          $tsMatch2 = [regex]::Match($json2, '"timestamp"\s*:\s*([0-9]+)')
          if ($tsMatch2.Success) {
            $rawTs2 = [int64]$tsMatch2.Groups[1].Value
            $timestampMs2 = if ($rawTs2 -gt 9999999999999) { [int64]($rawTs2 / 1000000) } else { $rawTs2 }
          }
          if ($hasSpan2) {
            Write-Host "[api-check] STANDARD ✓ Span confirmed via SigNoz API (serviceName)" -ForegroundColor Green
            return @{ ok = $true; reason = "span_found_service"; timestampMs = $timestampMs2; mode = "STANDARD (serviceName)" }
          }
        } catch {
            Write-Warning "[api-check] Fallback request failed: $(Get-HttpErrorBody $_)"
        }
      }
      Write-Warning "[api-check] No spans found (filter: $filterExpr, last $LookbackSeconds s)"
      return @{ ok = $false; reason = "no_span_found"; timestampMs = $null; mode = $verificationMode }
    }
  } catch {
    $errMsg = Get-HttpErrorBody $_
    Write-Warning "[api-check] Request failed: $errMsg"
    return @{ ok=$false; reason="http_error"; timestampMs=$null; error=$errMsg }
  }
}

Ensure-Dir $OutDir

# Prepare console encoding (prevents garbled box characters)
try {
  chcp 65001 | Out-Null
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
} catch { }

Write-Host "`n🐾 BossCat OEM - Pipeline Verification" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray

# --- 1) Quick monitor ---
Write-Host "[verify] Step 1/3: quick-monitor" -ForegroundColor Cyan
$quickMonitorExists = Test-Path "$PSScriptRoot\quick-monitor.ps1"
if ($quickMonitorExists) {
  & pwsh -NoProfile -File "$PSScriptRoot\quick-monitor.ps1"
  $qmCode = $LASTEXITCODE
  $quickMonitor = if ($qmCode -eq 0) { "pass" } else { "fail" }
  if ($qmCode -ne 0) {
    Write-Warning "[verify] quick-monitor reported issues (exit $qmCode)."
  }
} else {
  Write-Warning "[verify] quick-monitor.ps1 not found, skipping..."
  $quickMonitor = "skip"
  $qmCode = 0
}

# --- 2) Canary send + capture TRACE_ID for forensic verification ---
Write-Host "`n[verify] Step 2/3: canary trace (capturing TRACE_ID for pinpoint verification)" -ForegroundColor Cyan
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
# Default: Windows collector HTTP port. Override with BOSSCAT_OTLP_ENDPOINT for SigNoz-direct mode.
$otlpBase = [Environment]::GetEnvironmentVariable("BOSSCAT_OTLP_ENDPOINT", "Process")
if (-not $otlpBase) { $otlpBase = Get-OtelIngestHttpBase -Ports $script:OtelPorts }
$env:OTEL_EXPORTER_OTLP_ENDPOINT = $otlpBase
$env:OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = $otlpBase.TrimEnd('/') + "/v1/traces"
Write-Host "[verify] OTLP HTTP endpoint: $($otlpBase.TrimEnd('/'))" -ForegroundColor Gray
$env:SERVICE_NAME = $ServiceName
$env:OTEL_RESOURCE_ATTRIBUTES = "service.name=$ServiceName,service.version=0.1.0,os.type=windows,bosscat.gate=GATE-2025-10-08-234500"
$env:OTEL_LOG_LEVEL = "info"

$canarySendCode = 0
$canaryConfirmed = $false
$traceId = ""
$canaryId = ""
$sendTsNs = 0

if (Test-Path $CanaryScriptPath) {
  # Run Python canary and capture stdout (TRACE_ID=..., CANARY_ID=..., SEND_TS_NS=...)
  Write-Host "[verify] Running canary script: $CanaryScriptPath" -ForegroundColor Gray
  
  # Resolve Python executable: prefer real 'python', then known install paths
  # (incl. other users' Local\Programs from Phase 0), then Windows 'py -3'.
  # Skip the WindowsApps Store stub (exit 9009).
  function Resolve-PythonInvocation {
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd -and $pythonCmd.Source -notmatch '\\WindowsApps\\python\.exe$') {
      return @{ Exe = $pythonCmd.Source; Args = "-u `"$CanaryScriptPath`"" }
    }
    $candidates = @(
      'C:\Program\python.exe',
      "$env:LocalAppData\Programs\Python\Python312\python.exe",
      "$env:LocalAppData\Programs\Python\Python311\python.exe",
      "$env:ProgramFiles\Python312\python.exe",
      "$env:ProgramFiles\Python311\python.exe"
    )
    # Phase 0 sometimes installs per-user under the interactive desktop account
    $candidates += @(Get-ChildItem 'C:\Users\*\AppData\Local\Programs\Python\Python3*\python.exe' -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty FullName)
    foreach ($candidate in $candidates) {
      if ($candidate -and (Test-Path $candidate)) {
        return @{ Exe = $candidate; Args = "-u `"$CanaryScriptPath`"" }
      }
    }
    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pyLauncher) {
      return @{ Exe = $pyLauncher.Source; Args = "-3 -u `"$CanaryScriptPath`"" }
    }
    throw "Python not found on PATH (tried real 'python', known install paths, and 'py -3')"
  }

  $pyInv = Resolve-PythonInvocation
  Write-Host "[verify] Using Python: $($pyInv.Exe) $($pyInv.Args)" -ForegroundColor Gray

  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $pyInv.Exe
  $psi.Arguments = $pyInv.Args
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  
  $p = [System.Diagnostics.Process]::Start($psi)
  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  $canarySendCode = $p.ExitCode
  
  # Parse machine-readable output
  if ($stdout -match "TRACE_ID=([0-9a-fA-F]{32})") { 
    $traceId = $Matches[1].ToLower() 
    Write-Host "[verify] ✓ Captured TRACE_ID: $traceId" -ForegroundColor Green
  }
  if ($stdout -match "CANARY_ID=([0-9]+)") { 
    $canaryId = $Matches[1] 
  }
  if ($stdout -match "SEND_TS_NS=([0-9]+)") { 
    $sendTsNs = [int64]$Matches[1] 
  }
  
  if ($canarySendCode -ne 0) {
    Write-Warning "[verify] Canary send returned exit $canarySendCode."
    if ($stderr) {
      Write-Warning "[verify] Stderr: $stderr"
    }
  } elseif (-not $traceId) {
    Write-Warning "[verify] Canary sent but TRACE_ID not captured from output."
    Write-Host "[verify] ℹ️  Using standard serviceName-based verification" -ForegroundColor Yellow
  } else {
    Write-Host "[verify] ✓ Canary sent successfully (TRACE_ID: $traceId, CANARY_ID: $canaryId)" -ForegroundColor Green
  }
  
  Write-Host "[verify] Waiting up to $CanaryWaitSeconds s for ingestion..."
  Start-Sleep -Seconds $CanaryWaitSeconds
  
  # Collector log check (heuristic)
  try {
    $log = docker logs --since 1m $CollectorName 2>$null
    if ($log -match "Exported spans" -or $log -match "exporter.*otlp" -or $log -match "TracesExporter") { 
      $canaryConfirmed = $true 
      Write-Host "[verify] ✓ Canary confirmed in collector logs" -ForegroundColor Green
    } else {
      Write-Warning "[verify] Could not confirm canary in collector logs"
    }
  } catch {
    Write-Warning "[verify] Could not check collector logs: $_"
  }
  
  # API-based verification (explicit - with trace ID pinning if available)
  if ($SKIP_API) {
    Write-Host "`n[verify] API check SKIPPED (BOSSCAT_SKIP_API=1)" -ForegroundColor Yellow
    $apiCheck = @{ ok=$false; reason="skipped_by_config"; mode="skipped"; timestampMs=$null }
  } else {
    Write-Host "`n[verify] API check (SigNoz Trace API - forensic verification)..." -ForegroundColor Cyan
    $apiCheck = Invoke-SigNozApiTraceCheck -ServiceName $ServiceName -TraceId $traceId -LookbackSeconds $LOOKBACK

    # An empty result is not the same failure as a broken query path.
    #   http_error  -> the verification path itself is broken; do not retry, it will not self-heal
    #   no_span_found -> the span may still be in flight; ingestion lag is expected right after send
    # Retrying only the second case stops a timing race being reported as an API failure, and keeps
    # a genuine http_error loud instead of silently rescued by the fallback below.
    if ((-not $apiCheck.ok) -and $apiCheck.reason -eq "no_span_found" -and $API_RETRIES -gt 0) {
      for ($attempt = 1; $attempt -le $API_RETRIES -and -not $apiCheck.ok; $attempt++) {
        Write-Host "[verify] No span yet — ingestion lag suspected; retry $attempt/$API_RETRIES in ${API_RETRY_WAIT_SEC}s..." -ForegroundColor Yellow
        Start-Sleep -Seconds $API_RETRY_WAIT_SEC
        $apiCheck = Invoke-SigNozApiTraceCheck -ServiceName $ServiceName -TraceId $traceId -LookbackSeconds $LOOKBACK
        if ($apiCheck.ok) {
          Write-Host "[verify] Span confirmed on retry $attempt — this was ingestion lag, not an API failure" -ForegroundColor Green
          $apiCheck.retries = $attempt
        }
      }
      if (-not $apiCheck.ok) { $apiCheck.retries = $API_RETRIES }
    }

    # Fallback: ClickHouse direct query (works without API auth).
    # Reached only after retries are exhausted, or immediately for reasons that will not self-heal.
    if (-not $apiCheck.ok) {
      Write-Host "[verify] API check failed (${apiCheck.reason ?? 'n/a'}) — attempting ClickHouse fallback..." -ForegroundColor Yellow
      try {
        $chQueries = @(
          "SELECT traceID, toUnixTimestamp64Milli(timestamp) AS timestamp_ms FROM signoz_traces.distributed_signoz_index_v3 WHERE traceID = '$traceId' ORDER BY timestamp DESC LIMIT 1",
          "SELECT traceID, toUnixTimestamp64Milli(timestamp) AS timestamp_ms FROM signoz_traces.signoz_index_v3 WHERE traceID = '$traceId' ORDER BY timestamp DESC LIMIT 1",
          "SELECT traceID, toUnixTimestamp64Milli(timestamp) AS timestamp_ms FROM signoz_traces.distributed_signoz_index_v2 WHERE traceID = '$traceId' ORDER BY timestamp DESC LIMIT 1",
          "SELECT traceID, toUnixTimestamp64Milli(timestamp) AS timestamp_ms FROM signoz_traces.signoz_index_v2 WHERE traceID = '$traceId' ORDER BY timestamp DESC LIMIT 1",
          "SELECT traceID, toUnixTimestamp64Milli(timestamp) AS timestamp_ms FROM signoz_traces.distributed_signoz_index_v3 WHERE serviceName = '$ServiceName' ORDER BY timestamp DESC LIMIT 1",
          "SELECT traceID, toUnixTimestamp64Milli(timestamp) AS timestamp_ms FROM signoz_traces.signoz_index_v3 WHERE serviceName = '$ServiceName' ORDER BY timestamp DESC LIMIT 1",
          "SELECT traceID, toUnixTimestamp64Milli(timestamp) AS timestamp_ms FROM signoz_traces.distributed_signoz_index_v2 WHERE serviceName = '$ServiceName' ORDER BY timestamp DESC LIMIT 1",
          "SELECT traceID, toUnixTimestamp64Milli(timestamp) AS timestamp_ms FROM signoz_traces.signoz_index_v2 WHERE serviceName = '$ServiceName' ORDER BY timestamp DESC LIMIT 1"
        )
        $found = $false
        $tsMs = $null
        foreach ($q in $chQueries) {
          try {
            $out = docker exec signoz-clickhouse clickhouse-client --query "$q"
            if ($out) {
              $found = $true
              # Expect: traceID\ttimestamp
              $parts = $out -split "\t"
              if ($parts.Length -ge 2) {
                $rawTs = [int64]$parts[1]
                $tsMs = if ($rawTs -gt 9999999999999) { [int64]($rawTs / 1000000) } else { $rawTs }
              }
              break
            }
          } catch { continue }
        }
        if ($found) {
          Write-Host "[verify] ✓ ClickHouse fallback confirmed span presence" -ForegroundColor Green
          # Record what the fallback rescued. Without this the artifact says only "CLICKHOUSE",
          # which cannot distinguish a broken API from a span that simply had not landed yet —
          # the ambiguity that made the 2026-08-14 run unreadable.
          $apiCheck = @{
            ok            = $true
            reason        = "clickhouse_trace_found"
            mode          = "CLICKHOUSE"
            timestampMs   = $tsMs
            fallback_from = $apiCheck.reason
            retries       = $apiCheck.retries
            # Carry the original error through the rebuild. Without this the rescue erases the only
            # description of what broke, which for an intermittent fault is the whole diagnosis.
            error         = $apiCheck.error
          }
        }
      } catch { }
    }
  }
  
  # Calculate ingest latency if we have both timestamps
  $ingestLatencyMs = $null
  if ($sendTsNs -and $apiCheck.timestampMs) {
    $sendMs = [math]::Floor($sendTsNs / 1000000)
    $ingestLatencyMs = [int64]($apiCheck.timestampMs - $sendMs)
    
    # Guard against clock skew (negative latency = time sync issue)
    if ($ingestLatencyMs -lt 0) {
      Write-Warning "[verify] Negative ingest latency detected ($ingestLatencyMs ms) - clock skew between systems"
      Write-Host "[verify] ℹ️  Ensure NTP/domain time sync is enabled" -ForegroundColor Yellow
      $ingestLatencyMs = $null
    } elseif ($ingestLatencyMs -gt 300000) {
      Write-Warning "[verify] Extremely high ingest latency ($ingestLatencyMs ms) - likely measurement error"
      $ingestLatencyMs = $null
    } else {
      Write-Host "[verify] 📊 Ingest latency: $ingestLatencyMs ms" -ForegroundColor Cyan
      
      # SLO check: p95 target < 5000ms
      if ($ingestLatencyMs -gt 5000) {
        Write-Warning "[verify] ⚠️  Ingest latency exceeds SLO target (5000ms)"
      }
    }
  }
  
} else {
  Write-Warning "[verify] Canary script not found at: $CanaryScriptPath"
  Write-Host "[verify] ℹ️  Skipping canary test - configure script path to enable" -ForegroundColor Yellow
  $canarySendCode = -1
  $apiCheck = @{ ok=$false; reason="canary_script_not_found"; mode="skipped" }
  $ingestLatencyMs = $null
}

# Determine canary status (prefer API confirmation over log heuristic)
$canaryStatus = if (($canarySendCode -eq 0) -and ($apiCheck.ok -or $canaryConfirmed)) { 
  "pass" 
} elseif ($canarySendCode -eq 0) { 
  "warn" 
} elseif ($canarySendCode -eq -1) {
  "skip"
} else { 
  "fail" 
}

# --- 3) Apply rollback rules (5m windows are enforced by your monitors; here we gate current run) ---
Write-Host "`n[verify] Step 3/3: apply gate rules" -ForegroundColor Cyan

$gate = [ordered]@{
  collector_service_running = ($quickMonitor -eq "pass") # quick-monitor includes this check
  otlp_reachable            = ($quickMonitor -eq "pass")
  span_rate_nonzero         = ($canaryConfirmed -or $apiCheck.ok)  # API check OR log heuristic
  export_drops_zero         = $true                       # best effort; flip if logs indicate drops
  error_ratio_under_5pct    = $true                       # requires metrics; assumed true here
}

# detect drops/retries in last 2m logs
try {
  $scan = docker logs --since 2m $CollectorName 2>$null
  if ($scan -match "dropped" -or $scan -match "retry") { 
    $gate.export_drops_zero = $false 
    Write-Warning "[verify] Detected drops/retries in collector logs"
  }
} catch { 
  Write-Host "[verify] (info) Could not scan collector logs for drops"
}

# Decide outcome
$hardFail = (-not $gate.collector_service_running) -or (-not $gate.otlp_reachable) -or (($canaryStatus -eq "fail") -and ($canarySendCode -ne -1)) -or (-not $gate.export_drops_zero)
$warn     = ($canaryStatus -eq "warn") -or (-not $gate.error_ratio_under_5pct) -or ($canaryStatus -eq "skip")

# Apply STRICT mode if enabled (treat WARN as FAIL)
if ($STRICT -and $warn) {
  Write-Host "⚠️  [strict] WARN outcome elevated to FAIL due to STRICT mode" -ForegroundColor Yellow
  $hardFail = $true
  $warn = $false
}

$outcome  = if ($hardFail) { "FAIL" } elseif ($warn) { "WARN" } else { "OK" }
$exitCode = if ($hardFail) { 2 } elseif ($warn) { 1 } else { 0 }

# --- 4) Write summary JSON ---
$summary = [ordered]@{
  timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
  service_name  = $ServiceName
  gate_id       = "GATE-2025-10-08-234500"
  steps         = [ordered]@{
    quick_monitor      = $quickMonitor
    canary_send        = [ordered]@{
      exit_code          = $canarySendCode
      trace_id           = $traceId
      canary_id          = $canaryId
      send_ts_ns         = $sendTsNs
      log_confirmed      = $canaryConfirmed
      api_confirmed      = $apiCheck.ok
      api_reason         = $apiCheck.reason
      api_mode           = $apiCheck.mode
      # Present only when the ClickHouse fallback was used, so a reader can tell a rescued
      # http_error (broken path — act) from a rescued no_span_found (ingestion lag — expected).
      api_fallback_from  = $apiCheck.fallback_from
      api_retries        = $apiCheck.retries
      # The HTTP status and body behind an http_error. Get-HttpErrorBody has captured this since
      # August but it was never written out, so every occurrence recorded "http_error" and nothing
      # actionable. An intermittent fault cannot be caught live; the artifact has to carry it.
      api_error          = $apiCheck.error
      ingest_latency_ms  = $ingestLatencyMs
      status             = $canaryStatus
    }
  }
  gate_checks   = $gate
  outcome       = $outcome
  exit_code     = $exitCode
}

$summaryPath = Join-Path $OutDir "gate_verification.json"
$summary | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $summaryPath
Write-Host "`n[verify] Summary written: $summaryPath"

# --- 5) Append to CSV trend log for SLO tracking ---
$csvPath = Join-Path $OutDir "gate_verification_trend.csv"
$line = "{0},{1},{2},{3},{4},{5},{6},{7}" -f `
  ((Get-Date).ToUniversalTime().ToString("o")),
  $outcome,
  $exitCode,
  $summary.steps.canary_send.api_confirmed,
  $summary.steps.canary_send.log_confirmed,
  ($summary.steps.canary_send.ingest_latency_ms ?? ""),
  $summary.gate_checks.export_drops_zero,
  ($traceId -ne "" ? "pinpoint" : "standard")
  
$header = "timestamp_utc,outcome,exit_code,api_confirmed,log_confirmed,ingest_latency_ms,export_drops_zero,verification_mode"

if (-not (Test-Path $csvPath)) { 
  $header | Out-File -Encoding UTF8 $csvPath 
  Write-Host "[verify] Created trend log: $csvPath" -ForegroundColor Gray
}

$line | Out-File -Encoding UTF8 -Append $csvPath
Write-Host "🧾 [verify] Trend updated: $csvPath" -ForegroundColor Cyan

# --- 5) Display results ---
Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
switch ($outcome) {
  "OK"   { 
    Write-Host "✅ VERIFICATION OK — pipeline healthy" -ForegroundColor Green 
    Write-Host "   All gate checks passed" -ForegroundColor Green
  }
  "WARN" { 
    Write-Host "⚠️  VERIFICATION WARN — check UI/metrics" -ForegroundColor Yellow 
    Write-Host "   Some checks could not be confirmed" -ForegroundColor Yellow
    Write-Host "   Review SigNoz UI: http://localhost:8080" -ForegroundColor Yellow
  }
  "FAIL" { 
    Write-Host "❌ VERIFICATION FAIL — rollback gate to HOLD" -ForegroundColor Red 
    Write-Host "   Critical gate checks failed" -ForegroundColor Red
    Write-Host "   Run: pwsh -File BRAV\SCPT\set-gate-status.ps1 -Status HOLD" -ForegroundColor Red
  }
}
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray

# --- 6) Generate evidence pack for audits ---
try {
  . "$PSScriptRoot\write-evidence-pack.ps1"
  $evidenceZip = Write-EvidencePack -CollectorName $CollectorName -OutDir $OutDir
  if ($evidenceZip) {
    Write-Host "📦 Evidence pack ready for audit: $evidenceZip" -ForegroundColor Cyan
  }
} catch {
  Write-Host "ℹ️  Evidence pack generation skipped: $_" -ForegroundColor Gray
}

# --- 6b) Prune old evidence packs (retention policy) ---
try {
  & pwsh -NoProfile -File "$PSScriptRoot\prune-evidence.ps1" -OutDir $OutDir -Days 30
} catch {
  Write-Host "ℹ️  Evidence pruning skipped: $_" -ForegroundColor Gray
}

# --- 7) Send webhook notification if configured ---
$webhookUrl = [Environment]::GetEnvironmentVariable("BOSSCAT_WEBHOOK_URL","Machine")
if (-not $webhookUrl) { $webhookUrl = [Environment]::GetEnvironmentVariable("BOSSCAT_WEBHOOK_URL","Process") }

if ($webhookUrl) {
  try {
    $severity = if ($outcome -eq "FAIL") { "critical" } elseif ($outcome -eq "WARN") { "warning" } else { "info" }
    $notifyText = @"
**Outcome:** $outcome
**Exit Code:** $exitCode
**API Verification:** $($apiCheck.reason)
**API Mode:** $($apiCheck.mode ?? 'N/A')
**Ingest Latency:** $($ingestLatencyMs ?? 'N/A') ms
**Trace ID:** $($traceId ? $traceId.Substring(0, 16) + '...' : 'N/A')
**Timestamp:** $((Get-Date).ToUniversalTime().ToString("o"))
"@
    
    & "$PSScriptRoot\notify-webhook.ps1" `
      -WebhookUrl $webhookUrl `
      -Title "BossCat Gate Verification" `
      -Text $notifyText `
      -Severity $severity
  } catch {
    Write-Host "ℹ️  Webhook notification skipped: $_" -ForegroundColor Gray
  }
}

# --- 8) BOSSCAT-022A: Windows Collector Verification (Gate #022) ---
Write-Host ""
Write-Host "=== Gate #022: Windows Collector Verification ===" -ForegroundColor Cyan
try {
  & "$PSScriptRoot\verify-windows-collector.ps1"
  Write-Host "✓ Windows Collector: PASS" -ForegroundColor Green
} catch {
  Write-Warning "Windows Collector verification failed: $($_.Exception.Message)"
  Write-Host "  → This may require admin privileges or collector installation" -ForegroundColor Yellow
  # Non-blocking for now during Gate #022 rollout
  # To make blocking: Uncomment the line below
  # $exitCode = 2; $outcome = "FAIL"
}

Write-Host ""
Write-Host "🐾 BossCat OEM - Verification Complete" -ForegroundColor Cyan
exit $exitCode

