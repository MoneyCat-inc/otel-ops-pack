param(
  [int]$DurationMinutes = 1,
  [int]$EventsPerMinute = 30,
  [string]$ServiceName = "frontend",  # used by queries/selectors
  [switch]$VerboseOutput
)

Write-Host "🐾 IONA Canary — BossCat Quick Signals" -ForegroundColor Cyan
Write-Host "Duration: $DurationMinutes min  •  Rate: $EventsPerMinute/min  •  Service: $ServiceName" -ForegroundColor DarkGray

# --- Setup paths
$root = Join-Path (Get-Location) "artifacts/iona"
if (-not (Test-Path $root)) { New-Item -ItemType Directory -Path $root | Out-Null }
$logFile = Join-Path $root "iona-canary.log"

# --- Ensure Windows Event Log source exists (Application)
$eventSource = "IONA-Canary"
try {
  if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
    New-EventLog -LogName Application -Source $eventSource | Out-Null
  }
} catch { }

# --- Emit logs for SigNoz (file + Windows Event Log)
function Write-CanaryLogs([datetime]$ts, [int]$i) {
  $msgInfo  = "[IONA] canary test • service=$ServiceName • seq=$i"
  $msgError = "[IONA] canary ERROR test • service=$ServiceName • seq=$i"
  Add-Content -Path $logFile -Value "$($ts.ToString('o')) $msgInfo"
  if (($i % 10) -eq 0) { Add-Content -Path $logFile -Value "$($ts.ToString('o')) $msgError" }
  try {
    Write-EventLog -LogName Application -Source $eventSource -EventId 1000 -EntryType Information -Message $msgInfo
    if (($i % 10) -eq 0) { Write-EventLog -LogName Application -Source $eventSource -EventId 1001 -EntryType Error -Message $msgError }
  } catch { }
}

# --- Optional: call existing local canary generator if present
$existingCanary = Join-Path (Get-Location) "scripts/generate-windows-canary.ps1"
if (Test-Path $existingCanary) {
  Write-Host "🔁 Detected existing canary generator — invoking in background" -ForegroundColor DarkGray
  try { pwsh -File $existingCanary -DurationMinutes $DurationMinutes | Out-Null } catch { }
}

# --- Emit quick burst for the chosen duration
$total = $DurationMinutes * $EventsPerMinute
if ($total -lt 1) { $total = 1 }
Write-Host "📝 Emitting $total log events to $logFile and Windows Event Log..." -ForegroundColor Yellow
for ($i = 1; $i -le $total; $i++) {
  Write-CanaryLogs ([datetime]::UtcNow) $i
  Start-Sleep -Milliseconds ([math]::Max([int](60000 / [math]::Max($EventsPerMinute,1)), 50))
}

# --- Metrics stub (guidance file)
$metricsStub = @()
$metricsStub += "BossCat SLO metric expectations (edit in scripts/bosscat-alerts-slo-burnrate.ps1):"
$metricsStub += "  • Request counter: http_server_request_duration_seconds_count"
$metricsStub += "  • Latency buckets: http_server_request_duration_seconds_bucket"
$metricsStub += "  • Service selector: service=`"$ServiceName`" (or set -ServiceSelector)"
$metricsStub += "If these metrics are not present, either align names to your app or emit matching series via your app/exporter."
Set-Content -Path (Join-Path $root "metrics-STUB.txt") -Value ($metricsStub -join "`n") -Encoding UTF8

Write-Host ""; Write-Host "✅ IONA canary completed." -ForegroundColor Green
Write-Host "   • File logs: $logFile" -ForegroundColor DarkGray
Write-Host "   • Windows Event Log: Application / Source=$eventSource" -ForegroundColor DarkGray
Write-Host ""; Write-Host "🔎 Verify in SigNoz (Logs): filter message contains 'canary test'" -ForegroundColor Cyan
Write-Host "   SLO metrics will populate once metric names are aligned or an exporter emits them." -ForegroundColor DarkGray


