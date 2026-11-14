if (-not $env:SIGNOZ_API_KEY) { throw 'SigNoz API key required: set $env:SIGNOZ_API_KEY (no key is stored in this script).' }
$alerts = Invoke-RestMethod -Method GET -Uri 'http://localhost:8080/api/v1/rules' -Headers @{'SIGNOZ-API-KEY'=$env:SIGNOZ_API_KEY}
Write-Host "Total alerts found: $($alerts.Count)"
foreach ($alert in $alerts) {
    $name = $alert.alert ?? $alert.name ?? 'Unknown'
    $severity = $alert.severity ?? 'Unknown'
    $disabled = $alert.disabled ?? 'Unknown'
    Write-Host "• $name - Severity: $severity - Disabled: $disabled"
}