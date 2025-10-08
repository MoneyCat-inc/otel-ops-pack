param(
  [string]$SigNozUrl = "http://localhost:8080",
  [string]$ApiKey,
  [string]$ServiceSelector = "",            # e.g., 'service="frontend"' (optional)
  [double]$SLOErrorBudget = 0.01,           # 1% allowed error; change per SLO
  [double]$P95LatencySLOSeconds = 0.3,      # 300ms latency target; change per SLO
  [switch]$DryRun
)

# Auto-detect API key from environment or GitHub secret
if (-not $ApiKey) {
  if ($env:SIGNOZ_API_KEY) {
    $ApiKey = $env:SIGNOZ_API_KEY
    Write-Host "🔑 Using API key from `$env:SIGNOZ_API_KEY" -ForegroundColor DarkGray
  } elseif ($env:WYZWOZ_SIGNOZ) {
    $ApiKey = $env:WYZWOZ_SIGNOZ
    Write-Host "🔑 Using API key from `$env:WYZWOZ_SIGNOZ" -ForegroundColor DarkGray
  } else {
    throw "ApiKey is required. Set `$env:SIGNOZ_API_KEY or `$env:WYZWOZ_SIGNOZ or pass -ApiKey parameter"
  }
}
$H = @{ "SIGNOZ-API-KEY" = $ApiKey; "Content-Type"="application/json" }
$U = ($SigNozUrl.TrimEnd('/')) + "/api/v1/rules"

# ---- PromQL templates (edit metrics/labels to match your app) ----
# Request counters (per‑request)
$reqMetric    = "http_server_request_duration_seconds_count"
# Histogram buckets for latency
$bucketMetric = "http_server_request_duration_seconds_bucket"
# Errors defined by status code 5xx (override if your metric uses different labels)
$errSelector  = "status_code=~`"5..`""

$svc = $ServiceSelector -ne "" ? ("," + $ServiceSelector) : ""

# Error ratio: errors / total over a window
function New-ErrorRatioQuery([string]$win) {
  return "sum(rate($reqMetric{$errSelector$svc}[$win])) / sum(rate($reqMetric{$svc}[$win]))"
}

# Latency P95 over a window
function New-P95LatencyQuery([string]$win) {
  return "histogram_quantile(0.95, sum(rate($bucketMetric{$svc}[$win])) by (le))"
}

# Burn-rate thresholds (Google SRE‑style for 1% budget; adjust if SLOErrorBudget != 0.01)
# Fast (5m/1h) critical ~ 14.4x; Slow (30m/6h) warning ~ 6x
$brCrit = 14.4 * (0.01 / $SLOErrorBudget)
$brWarn =  6.0 * (0.01 / $SLOErrorBudget)

$defs = @(
  # Error SLO – Critical (fast window pair simplified to 5m window)
  @{
    alert       = "BossCat SLO • Error Burn (5m) – Critical"
    description = "Error budget burn-rate exceeds ${brCrit}x over 5m window."
    severity    = "critical"
    evalWindow  = "5m"; frequency = "1m"
    query       = "($(New-ErrorRatioQuery '5m')) / $SLOErrorBudget"
    target      = $brCrit; op = ">"; match = "greater_than"
  },
  # Error SLO – Warning (slow window simplified to 30m)
  @{
    alert       = "BossCat SLO • Error Burn (30m) – Warning"
    description = "Error budget burn-rate exceeds ${brWarn}x over 30m window."
    severity    = "warning"
    evalWindow  = "30m"; frequency = "1m"
    query       = "($(New-ErrorRatioQuery '30m')) / $SLOErrorBudget"
    target      = $brWarn; op = ">"; match = "greater_than"
  },
  # Latency SLO – Critical (fast)
  @{
    alert       = "BossCat SLO • P95 Latency (5m) – Critical"
    description = "P95 latency breaches ${P95LatencySLOSeconds}s over 5m."
    severity    = "critical"
    evalWindow  = "5m"; frequency = "1m"
    query       = "$(New-P95LatencyQuery '5m')"
    target      = [double]$P95LatencySLOSeconds; op = ">"; match = "greater_than"
  },
  # Latency SLO – Warning (slow)
  @{
    alert       = "BossCat SLO • P95 Latency (30m) – Warning"
    description = "P95 latency breaches ${P95LatencySLOSeconds}s over 30m."
    severity    = "warning"
    evalWindow  = "30m"; frequency = "1m"
    query       = "$(New-P95LatencyQuery '30m')"
    target      = [double]$P95LatencySLOSeconds; op = ">"; match = "greater_than"
  }
)

# ---- Fetch existing rules for idempotent upsert ----
try {
  $cur = Invoke-RestMethod -Method GET -Uri $U -Headers $H
} catch {
  throw "Failed to list rules from $U : $($_.Exception.Message)"
}
$existing = @{}
$norm = @($cur.data?.rules ?? $cur.rules ?? $cur)
foreach ($r in $norm) {
  $nm = ($r.alert ?? $r.name ?? $r.alertName)
  if ($nm) { $existing[$nm.ToLower()] = $r }
}

# ---- Upsert each rule ----
foreach ($d in $defs) {
  $payload = @{
    alert       = $d.alert
    description = $d.description
    alertType   = "METRIC_BASED_ALERT"
    ruleType    = "threshold_rule"
    severity    = $d.severity
    evalWindow  = $d.evalWindow
    frequency   = $d.frequency
    condition   = @{
      compositeQuery = @{
        promQueries = @{ A = @{ query = $d.query; disabled = $false } }
        queryType   = "promql"
      }
      target    = $d.target
      op        = $d.op
      matchType = $d.match
    }
    disabled = $false
  }

  $nameKey = $d.alert.ToLower()
  if ($existing.ContainsKey($nameKey)) {
    $id = ($existing[$nameKey].id ?? $existing[$nameKey]._id ?? $existing[$nameKey].ruleId)
    if ($id) {
      if ($DryRun) {
        Write-Host "[DRYRUN] PUT /rules/$id  $($d.alert)"
      } else {
        Invoke-RestMethod -Method PUT -Uri "$U/$id" -Headers $H -Body ($payload|ConvertTo-Json -Depth 20) | Out-Null
        Write-Host "🔁 Updated: $($d.alert)"
      }
    }
  } else {
    if ($DryRun) {
      Write-Host "[DRYRUN] POST /rules     $($d.alert)"
    } else {
      Invoke-RestMethod -Method POST -Uri $U -Headers $H -Body ($payload|ConvertTo-Json -Depth 20) | Out-Null
      Write-Host "➕ Created: $($d.alert)"
    }
  }
}

Write-Host "✅ SLO burn-rate pack applied." -ForegroundColor Green

