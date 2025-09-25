# 24-Hour Dataset Coverage Validation
# Usage: pwsh -File scripts/validate-dataset-coverage-24h.ps1

Write-Host "📊 24-Hour Dataset Coverage Validation" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Gray
Write-Host ""

# Ensure artifacts directory exists
$artifactsDir = "artifacts"
if (!(Test-Path $artifactsDir)) {
    New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
}

$reportFile = "$artifactsDir/dataset-coverage-24h-report.txt"
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

Write-Host "🕐 Validation Time: $timestamp" -ForegroundColor Green
Write-Host "📄 Report File: $reportFile" -ForegroundColor Gray
Write-Host ""

# Initialize report
"=== Dataset Coverage Validation Report ===" | Out-File -FilePath $reportFile -Encoding UTF8
"Validation Time: $timestamp" | Out-File -FilePath $reportFile -Append -Encoding UTF8
"" | Out-File -FilePath $reportFile -Append -Encoding UTF8

try {
    Write-Host "🔍 Checking dataset coverage over last 24 hours..." -ForegroundColor Yellow
    
    # Check for logs missing dataset attributes
    $missingDatasetQuery = @"
SELECT count() as missing_count
FROM signoz_logs.logs_v2
WHERE timestamp >= toUnixTimestamp64Nano(now64(9) - toIntervalHour(24))
  AND NOT mapContains(attributes_string, 'dataset')
"@
    
    $missingCount = docker exec signoz-clickhouse clickhouse-client --query $missingDatasetQuery
    
    if ([int]$missingCount -eq 0) {
        Write-Host "✅ Dataset Coverage: COMPLETE (0 missing datasets)" -ForegroundColor Green
        "Dataset Coverage: COMPLETE (0 missing datasets)" | Out-File -FilePath $reportFile -Append -Encoding UTF8
    } else {
        Write-Host "⚠️  Dataset Coverage: INCOMPLETE ($missingCount missing datasets)" -ForegroundColor Yellow
        "Dataset Coverage: INCOMPLETE ($missingCount missing datasets)" | Out-File -FilePath $reportFile -Append -Encoding UTF8
        
        # Capture sample logs missing dataset
        Write-Host "📋 Capturing sample logs missing dataset..." -ForegroundColor Yellow
        $sampleQuery = @"
SELECT value AS service, body, timestamp
FROM signoz_logs.logs_v2
ARRAY JOIN mapKeys(resources_string) AS key, mapValues(resources_string) AS value
WHERE key = 'service.name'
  AND timestamp >= toUnixTimestamp64Nano(now64(9) - toIntervalHour(24))
  AND NOT mapContains(attributes_string, 'dataset')
ORDER BY timestamp DESC
LIMIT 10
"@
        
        $samples = docker exec signoz-clickhouse clickhouse-client --query $sampleQuery
        Write-Host "Sample logs missing dataset:" -ForegroundColor Red
        "Sample logs missing dataset:" | Out-File -FilePath $reportFile -Append -Encoding UTF8
        $samples | ForEach-Object {
            Write-Host "  $($_)" -ForegroundColor Red
            "  $($_)" | Out-File -FilePath $reportFile -Append -Encoding UTF8
        }
    }
    
    Write-Host ""
    
    # Check dataset distribution
    Write-Host "📊 Dataset distribution over last 24 hours..." -ForegroundColor Yellow
    $distributionQuery = @"
SELECT value AS dataset, count() as log_count
FROM signoz_logs.logs_v2
ARRAY JOIN mapKeys(attributes_string) AS key, mapValues(attributes_string) AS value
WHERE key = 'dataset'
  AND timestamp >= toUnixTimestamp64Nano(now64(9) - toIntervalHour(24))
GROUP BY dataset
ORDER BY log_count DESC
"@
    
    $distribution = docker exec signoz-clickhouse clickhouse-client --query $distributionQuery
    Write-Host "Dataset Distribution:" -ForegroundColor Cyan
    "Dataset Distribution:" | Out-File -FilePath $reportFile -Append -Encoding UTF8
    $distribution | ForEach-Object {
        Write-Host "  $($_)" -ForegroundColor Cyan
        "  $($_)" | Out-File -FilePath $reportFile -Append -Encoding UTF8
    }
    
    Write-Host ""
    
    # Check parser errors
    Write-Host "🔍 Checking parser errors over last 24 hours..." -ForegroundColor Yellow
    $parserErrorQuery = @"
SELECT count() as parser_errors
FROM signoz_logs.logs_v2
WHERE timestamp >= toUnixTimestamp64Nano(now64(9) - toIntervalHour(24))
  AND severity_text = 'ERROR'
  AND body LIKE '%json_parser%'
"@
    
    $parserErrors = docker exec signoz-clickhouse clickhouse-client --query $parserErrorQuery
    
    if ([int]$parserErrors -eq 0) {
        Write-Host "✅ Parser Errors: NONE (0 errors)" -ForegroundColor Green
        "Parser Errors: NONE (0 errors)" | Out-File -FilePath $reportFile -Append -Encoding UTF8
    } else {
        Write-Host "⚠️  Parser Errors: $parserErrors errors detected" -ForegroundColor Yellow
        "Parser Errors: $parserErrors errors detected" | Out-File -FilePath $reportFile -Append -Encoding UTF8
    }
    
    Write-Host ""
    
    # Summary
    Write-Host "📋 Summary:" -ForegroundColor Magenta
    "Summary:" | Out-File -FilePath $reportFile -Append -Encoding UTF8
    
    if ([int]$missingCount -eq 0 -and [int]$parserErrors -eq 0) {
        Write-Host "✅ All validations PASSED - Dataset coverage complete, no parser errors" -ForegroundColor Green
        "All validations PASSED - Dataset coverage complete, no parser errors" | Out-File -FilePath $reportFile -Append -Encoding UTF8
    } else {
        Write-Host "⚠️  Some validations FAILED - Review sample data above" -ForegroundColor Yellow
        "Some validations FAILED - Review sample data above" | Out-File -FilePath $reportFile -Append -Encoding UTF8
    }
    
} catch {
    Write-Host "❌ Validation failed: $($_.Exception.Message)" -ForegroundColor Red
    "Validation failed: $($_.Exception.Message)" | Out-File -FilePath $reportFile -Append -Encoding UTF8
}

Write-Host ""
Write-Host "📄 Full report saved to: $reportFile" -ForegroundColor Gray
Write-Host "🕐 Validation completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
