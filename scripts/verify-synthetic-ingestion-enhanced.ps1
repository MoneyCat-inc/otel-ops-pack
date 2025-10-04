param(
  [string]$SigNozUrl = $env:SIGNOZ_URL ?? "http://localhost:8080",
  [string]$ServiceName = "synthetic-windows-check",
  [string]$ApiKey = $env:SIGNOZ_API_KEY,              # optional: from Settings → API Keys
  [string]$SessionCookieValue = $env:SIGNOZ_SESSION_COOKIE   # optional: browser's signoz-session cookie
)

Write-Host "🔍 BossCat Synthetic Service Verification" -ForegroundColor Cyan
Write-Host "SigNoz URL: $SigNozUrl" -ForegroundColor Gray
Write-Host "Service: $ServiceName" -ForegroundColor Gray
if ($ApiKey) { Write-Host "Auth: API Key" -ForegroundColor Gray }
elseif ($SessionCookieValue) { Write-Host "Auth: Session Cookie" -ForegroundColor Gray }
else { Write-Host "Auth: None (public access)" -ForegroundColor Yellow }
Write-Host ""

function Get-Page($path) {
  $uri = "$SigNozUrl$path"
  $headers = @{}
  if ($ApiKey) { $headers["x-api-key"] = $ApiKey }
  try {
    if ($SessionCookieValue) {
      $cookie = New-Object System.Net.Cookie("signoz-session", $SessionCookieValue, "/", ([uri]$SigNozUrl).Host)
      $handler = New-Object System.Net.Http.HttpClientHandler
      $cc = New-Object System.Net.CookieContainer
      $handler.CookieContainer = $cc
      $cc.Add(([Uri]$SigNozUrl), $cookie)
      $client = New-Object System.Net.Http.HttpClient($handler)
      $resp = $client.GetAsync($uri).Result
      return [string]$resp.Content.ReadAsStringAsync().Result
    } else {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $uri -Headers $headers -ErrorAction Stop
      return $resp.Content
    }
  } catch {
    Write-Host "[WARN] $($uri) fetch failed: $($_.Exception.Message)" -ForegroundColor Yellow
    return ""
  }
}

# Try services view first, then falls back to domain search
$page = Get-Page "/services"
if (-not $page) { $page = Get-Page "/" }

if ($page -and ($page -match [regex]::Escape($ServiceName))) {
  Write-Host "✅ Found service: $ServiceName in SigNoz UI HTML." -ForegroundColor Green
  exit 0
} else {
  Write-Host "❌ Service not found yet: $ServiceName. It may take a few seconds to appear." -ForegroundColor Red
  exit 2
}
