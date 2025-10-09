# Verify Synthetic Ingestion - Simple API Check
# Checks if synthetic-windows-check service is visible in SigNoz

Write-Host "🔍 Verifying synthetic trace ingestion..." -ForegroundColor Cyan

# Wait a moment for traces to be processed
Start-Sleep -Seconds 3

try {
    # Try to get services via API
    $servicesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/services" -Method Get -TimeoutSec 10
    
    if ($servicesResponse -and $servicesResponse.data) {
        $services = $servicesResponse.data
        Write-Host "📋 Available services:" -ForegroundColor Yellow
        foreach ($service in $services) {
            Write-Host "   - $($service.serviceName)" -ForegroundColor White
            if ($service.serviceName -eq "synthetic-windows-check") {
                Write-Host "   ✅ Found synthetic-windows-check service!" -ForegroundColor Green
                return $true
            }
        }
        Write-Host "   ⚠️ synthetic-windows-check not found in services list" -ForegroundColor Yellow
    } else {
        Write-Host "   ⚠️ Could not retrieve services list" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ API call failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "💡 Manual verification steps:" -ForegroundColor Blue
Write-Host "   1. Open http://localhost:8080/services" -ForegroundColor White
Write-Host "   2. Search for 'synthetic-windows-check'" -ForegroundColor White
Write-Host "   3. Look for spans 'bc.synthetic.root' and 'bc.synthetic.child'" -ForegroundColor White
Write-Host ""

return $false
