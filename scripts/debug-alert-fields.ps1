$response = Invoke-RestMethod -Method GET -Uri 'http://localhost:8080/api/v1/rules' -Headers @{'SIGNOZ-API-KEY'='gt2fvKZbscYFcxlO2+toX7xbhyQZ7oOhoVB7L6L/AgU='}
$alerts = $response.data.rules
Write-Host "Sample alert fields:"
$alerts[0] | Get-Member -MemberType NoteProperty | ForEach-Object { Write-Host "  $($_.Name): $($alerts[0].$($_.Name))" }
