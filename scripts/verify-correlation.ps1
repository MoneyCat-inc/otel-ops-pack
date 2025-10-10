Param(
  [string]$LogPath = "logs/app.log",
  [string]$SigNozBase = $env:SIGNOZ_API_BASE
)

Write-Host "[verify-correlation] Checking log file: $LogPath"
if (-not (Test-Path $LogPath)) {
  Write-Error "Log file not found: $LogPath"
  exit 1
}

$firstLine = Get-Content -Path $LogPath -TotalCount 1 -ErrorAction Stop
if (-not $firstLine) {
  Write-Error "Log file is empty: $LogPath"
  exit 1
}

try {
  $obj = $firstLine | ConvertFrom-Json
} catch {
  Write-Error "First log line is not valid JSON"
  exit 1
}

$corr = $obj.correlation_id
$traceId = $obj.trace_id
$spanId = $obj.span_id

if (-not $corr) { Write-Error "Missing correlation_id in first log entry"; exit 1 }
if (-not $traceId) { Write-Error "Missing trace_id in first log entry"; exit 1 }
if (-not $spanId) { Write-Error "Missing span_id in first log entry"; exit 1 }

Write-Host "[verify-correlation] Found correlation_id: $corr"
Write-Host "[verify-correlation] Found trace_id     : $traceId"
Write-Host "[verify-correlation] Found span_id      : $spanId"

# Optional: Try to match last root span attributes via SigNoz API when up
if (-not [string]::IsNullOrEmpty($SigNozBase)) {
  try {
    $apiUrl = "$SigNozBase/api/traces?limit=1"
    Write-Host "[verify-correlation] Querying SigNoz: $apiUrl"
    $resp = Invoke-WebRequest -Uri $apiUrl -Method GET -TimeoutSec 5 -ErrorAction Stop
    $json = $resp.Content | ConvertFrom-Json
    $attrCorr = $null
    $attrTrace = $null
    if ($json.data) {
      # best-effort: infer fields if present
      $attrTrace = $json.data[0].traceId
      $attrs = $json.data[0].attributes
      if ($attrs) { $attrCorr = $attrs.correlation_id }
    }
    if ($attrCorr -and $attrCorr -ne $corr) {
      Write-Warning "SigNoz mismatch: correlation_id=$attrCorr != $corr"
    }
    if ($attrTrace -and $attrTrace -ne $traceId) {
      Write-Warning "SigNoz mismatch: traceId=$attrTrace != $traceId"
    }
    Write-Host "[verify-correlation] SigNoz check completed (best-effort)"
  } catch {
    Write-Warning "SigNoz API unavailable or schema unexpected - skipping trace match"
  }
} else {
  Write-Host "[verify-correlation] SigNoz base not set; skipping API check"
}

Write-Host "[verify-correlation] OK"
exit 0

