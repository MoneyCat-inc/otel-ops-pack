$response = Invoke-RestMethod -Method GET -Uri 'http://localhost:8080/api/v1/rules' -Headers @{'SIGNOZ-API-KEY'='gt2fvKZbscYFcxlO2+toX7xbhyQZ7oOhoVB7L6L/AgU='}
Write-Host "Raw response type: $($response.GetType().Name)"
Write-Host "Raw response:"
$response | ConvertTo-Json -Depth 10
