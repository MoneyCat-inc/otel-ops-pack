# Quick test for SigNoz canary view
Write-Host "Testing SigNoz canary view..." -ForegroundColor Cyan

# Check if we can see recent canaries
$Query = @{
    query = "message contains "SigNoz wiring canary""
    start = [DateTimeOffset]::UtcNow.AddHours(-1).ToUnixTimeSeconds()
    end = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
} | ConvertTo-Json

try {
    $Response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs" -Method POST -Body $Query -ContentType "application/json"
    $Count = $Response.data.Count
    Write-Host "Found $Count canary entries in the last hour" -ForegroundColor Green
} catch {
    Write-Host "Could not query SigNoz API: $($_.Exception.Message)" -ForegroundColor Red
}
