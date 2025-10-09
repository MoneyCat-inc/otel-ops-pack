$alerts = Invoke-RestMethod -Method GET -Uri 'http://localhost:8080/api/v1/rules' -Headers @{'SIGNOZ-API-KEY'='gt2fvKZbscYFcxlO2+toX7xbhyQZ7oOhoVB7L6L/AgU='}
Write-Host "Total alerts found: $($alerts.Count)"
foreach ($alert in $alerts) {
    $name = $alert.alert ?? $alert.name ?? 'Unknown'
    $severity = $alert.severity ?? 'Unknown'
    $disabled = $alert.disabled ?? 'Unknown'
    Write-Host "• $name - Severity: $severity - Disabled: $disabled"
}