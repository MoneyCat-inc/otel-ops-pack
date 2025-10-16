$apiKey = $env:SIGNOZ_API_KEY
if (-not $apiKey) {
  Write-Error "SIGNOZ_API_KEY not set. Create one in SigNoz settings and set env var."
  exit 2
}
$response = Invoke-RestMethod -Method GET -Uri 'http://localhost:8080/api/v1/rules' -Headers @{ 'SIGNOZ-API-KEY' = $apiKey }
Write-Host "Raw response type: $($response.GetType().Name)"
Write-Host "Raw response:"
$response | ConvertTo-Json -Depth 10
