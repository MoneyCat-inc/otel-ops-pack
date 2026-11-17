if (-not $env:SIGNOZ_API_KEY) { throw 'SigNoz API key required: set $env:SIGNOZ_API_KEY (no key is stored in this script).' }
$response = Invoke-RestMethod -Method GET -Uri 'http://localhost:8080/api/v1/rules' -Headers @{'SIGNOZ-API-KEY'=$env:SIGNOZ_API_KEY}
$alerts = $response.data.rules
Write-Host "Sample alert fields:"
$alerts[0] | Get-Member -MemberType NoteProperty | ForEach-Object { Write-Host "  $($_.Name): $($alerts[0].$($_.Name))" }
