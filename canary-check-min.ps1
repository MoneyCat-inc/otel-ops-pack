# C:\otel\canary-check-min.ps1
# Purpose: Send one OTLP/HTTP log and verify ingestion by metrics-delta on /metrics.

[CmdletBinding()]
param(
  [string]$OtlpUrl    = "http://127.0.0.1:5318/v1/logs",
  [string]$Metrics889  = "http://127.0.0.1:8889/metrics",
  [string]$Metrics888  = "http://127.0.0.1:8888/metrics",
  [int]$TimeoutSec     = 5
)

$ErrorActionPreference = "Stop"
$null = New-Item -ItemType Directory -Force -Path "C:\otel\logs" | Out-Null
$TranscriptPath = "C:\otel\logs\canary-check-min.last.log"

# Stop any existing transcription and start fresh
try { 
  Stop-Transcript -ErrorAction SilentlyContinue | Out-Null 
  Start-Sleep -Milliseconds 100
} catch {}
try { 
  Start-Transcript -Path $TranscriptPath -Force | Out-Null 
} catch {
  Write-Host "Note: Could not start transcript, continuing with console output only"
}

function Get-NowNs {
  return ([int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) * 1000000)
}

function Get-AcceptedLogCount {
  param([string]$Url)
  try {
    $raw = (Invoke-WebRequest -UseBasicParsing -TimeoutSec $TimeoutSec -Uri $Url).Content
  } catch {
    Write-Host "Metrics fetch failed on $Url`: $($_.Exception.Message)"
    return [int64](-1)
  }

  # Label-agnostic: accept any line starting with the metric name and ending in a number
  $lines = $raw -split "`n" | Where-Object { $_ -like "otelcol_receiver_accepted_log_records*" }
  if (-not $lines) { return [int64](-1) }

  $sum = [int64]0
  foreach ($ln in $lines) {
    if ($ln -match "\s([0-9]+)\s*$") {
      $sum += [int64]$Matches[1]
    }
  }
  return $sum
}

function Get-MetricsCount {
  # Try 8889 then 8888
  $c = Get-AcceptedLogCount -Url $Metrics889
  if ($c -ge 0) { return @{ Count=$c; Url=$Metrics889 } }
  $c = Get-AcceptedLogCount -Url $Metrics888
  if ($c -ge 0) { return @{ Count=$c; Url=$Metrics888 } }
  return @{ Count=[int64](-1); Url="" }
}

function Send-Canary {
  param([string]$Url)
  $token = [guid]::NewGuid().ToString("N")
  $ns = Get-NowNs

  # Create JSON payload as string to avoid PowerShell serialization issues
  $jsonPayload = @"
{
  "resourceLogs": [
    {
      "resource": {
        "attributes": [
          {"key": "service.name", "value": {"stringValue": "canary"}},
          {"key": "service.namespace", "value": {"stringValue": "observability"}},
          {"key": "deployment.environment", "value": {"stringValue": "production"}},
          {"key": "host.name", "value": {"stringValue": "$($env:COMPUTERNAME)"}},
          {"key": "canary", "value": {"boolValue": true}},
          {"key": "canary.token", "value": {"stringValue": "$token"}}
        ]
      },
      "scopeLogs": [
        {
          "logRecords": [
            {
              "timeUnixNano": "$ns",
              "severityText": "INFO",
              "body": {"stringValue": "canary $token"},
              "attributes": [
                {"key": "source", "value": {"stringValue": "canary-check-min"}}
              ]
            }
          ]
        }
      ]
    }
  ]
}
"@

  $headers = @{ "Content-Type" = "application/json" }
  $resp = Invoke-WebRequest -UseBasicParsing -TimeoutSec $TimeoutSec -Uri $Url -Method Post -Headers $headers -Body $jsonPayload
  if ($resp.StatusCode -ne 200) { throw "OTLP HTTP returned $($resp.StatusCode)" }
  return $token
}

Write-Host "Reading baseline metrics..."
$baseline = Get-MetricsCount
if ($baseline.Count -lt 0) {
  Write-Error "Could not read collector metrics on 8889 or 8888."
  try { Stop-Transcript | Out-Null } catch {}
  exit 3
}
Write-Host "Baseline: count=$($baseline.Count) url=$($baseline.Url)"

Write-Host "Sending canary..."
$tok = Send-Canary -Url $OtlpUrl

# Poll briefly (up to 8 tries) for delta
$deltaOk = $false
for ($i=0; $i -lt 8; $i++) {
  Start-Sleep -Milliseconds 300
  $after = Get-MetricsCount
  if ($after.Count -gt $baseline.Count) {
    Write-Host "OK delta observed. before=$($baseline.Count) after=$($after.Count) token=$tok via=$($after.Url)"
    $deltaOk = $true
    break
  }
}

if (-not $deltaOk) {
  Write-Error "No ingestion delta observed. before=$($baseline.Count) after=$($after.Count) token=$tok via=$($after.Url)"
  try { Stop-Transcript | Out-Null } catch {}
  exit 2
}

try { Stop-Transcript | Out-Null } catch {}
exit 0