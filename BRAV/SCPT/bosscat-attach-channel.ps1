param(
  [string]$SigNozUrl    = "http://localhost:8080",
  [string]$ApiKey,
  [string]$ChannelId,                 # required: obtain from SigNoz UI
  [string]$NamePrefix = "BossCat "    # scope safety
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

if (-not $ChannelId) { throw "ChannelId is required (create channel in UI and copy its ID)" }

$H=@{ "SIGNOZ-API-KEY"=$ApiKey; "Content-Type"="application/json" }
$U= ($SigNozUrl.TrimEnd('/')) + "/api/v1/rules"

$raw = Invoke-RestMethod -Uri $U -Headers $H -Method GET
$rules = @($raw.data?.rules ?? $raw.rules ?? $raw)

foreach ($r in $rules) {
  $nm = ($r.alert ?? $r.name ?? $r.alertName)
  if (-not $nm -or ($nm -notlike "$NamePrefix*")) { continue }
  $id = ($r.id ?? $r._id ?? $r.ruleId); if (-not $id) { continue }

  # merge / set preferredChannels
  $pref = @()
  if ($r.preferredChannels) { $pref = @($r.preferredChannels) }
  if ($pref -notcontains $ChannelId) { $pref += $ChannelId }

  $r.preferredChannels = $pref
  Invoke-RestMethod -Uri "$U/$id" -Headers $H -Method PUT -Body ($r|ConvertTo-Json -Depth 20) | Out-Null
  Write-Host "🔗 Attached channel to: $nm"
}
Write-Host "✅ Channel binding complete." -Foreground Green

