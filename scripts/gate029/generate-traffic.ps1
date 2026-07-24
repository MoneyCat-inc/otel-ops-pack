# HISTORICAL (Gate-era): ports 5317/5318 predate the 5320/5321 move. Do not use as reference. See windows/otelcol/README.md.
# Gate #029: Traffic Generator for Service Verification
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Generate HTTP traffic to deployed services for telemetry verification

param(
    [string[]]$ServiceUrls = @("http://localhost:5556/", "http://localhost:5557/"),
    [int]$RequestsPerService = 25,
    [int]$DelayMs = 400,
    [switch]$Verbose
)

Write-Host "=== Gate #029: Traffic Generator ===" -ForegroundColor Cyan
Write-Host ""

$totalRequests = $ServiceUrls.Count * $RequestsPerService
$requestCount = 0
$successCount = 0
$failCount = 0

Write-Host "Generating traffic to $($ServiceUrls.Count) services..." -ForegroundColor Yellow
Write-Host "Requests per service: $RequestsPerService" -ForegroundColor Yellow
Write-Host "Total requests: $totalRequests" -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 2

for ($i = 1; $i -le $RequestsPerService; $i++) {
    foreach ($url in $ServiceUrls) {
        $requestCount++
        $service = $url -replace "http://localhost:(\d+)/", "Service on port `$1"
        
        try {
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            $successCount++
            
            if ($Verbose) {
                Write-Host "✅ Request $requestCount/$totalRequests`: $service → HTTP $($response.StatusCode)" -ForegroundColor Green
            } elseif ($i % 5 -eq 0) {
                Write-Host "   Progress: $requestCount/$totalRequests ($successCount success, $failCount failed)" -ForegroundColor Gray
            }
        } catch {
            $failCount++
            Write-Host "❌ Request $requestCount/$totalRequests`: $service → Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Start-Sleep -Milliseconds $DelayMs
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Traffic generation complete" -ForegroundColor Green
Write-Host ""
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "   Total requests: $totalRequests" -ForegroundColor White
Write-Host "   Successful: $successCount ($('{0:P0}' -f ($successCount / $totalRequests)))" -ForegroundColor $(if ($successCount -eq $totalRequests) { 'Green' } else { 'Yellow' })
Write-Host "   Failed: $failCount ($('{0:P0}' -f ($failCount / $totalRequests)))" -ForegroundColor $(if ($failCount -eq 0) { 'Green' } else { 'Red' })
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "   1. Wait 30 seconds for telemetry to propagate" -ForegroundColor White
Write-Host "   2. Run collector verification: pwsh -File scripts\gate029\verify-collector-5317.ps1" -ForegroundColor White
Write-Host "   3. Check SigNoz UI: http://localhost:8080" -ForegroundColor White

if ($failCount -gt 0) {
    Write-Host ""
    Write-Host "⚠️  Some requests failed. Verify services are running and healthy." -ForegroundColor Yellow
    exit 10  # AMBER
}

exit 0  # GREEN

