# SigNoz ECRR Compliance Integration Test
# Tests the integration between compliance monitoring and SigNoz

param(
    [string]$SigNozBaseURL = "http://localhost:8080",
    [switch]$TestLogIngestion,
    [switch]$TestQueries,
    [switch]$GenerateTestData
)

Write-Host "🧪 SigNoz ECRR Compliance Integration Test" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Function to generate test compliance data
function New-TestComplianceData {
    Write-Host "📊 Generating test compliance data..." -ForegroundColor Yellow
    
    $testData = @{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        dataset = "ecrr_compliance"
        event = "compliance_trend_calculated"
        overall_score = 8.5
        total_reports = 12
        passed_reports = 10
        failed_reports = 2
        compliance_rate = 70.83
        trend = "Improving"
        trend_direction = "Upward"
        trend_percentage = 5.2
        recommendation = "Continue current practices - compliance trending upward"
        threshold = 80
    }
    
    $logDirectory = "C:/logs/ecrr"
    $logFile = Join-Path $logDirectory "compliance-trends.log"
    
    if (-not (Test-Path $logDirectory)) {
        New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
    }
    
    $json = $testData | ConvertTo-Json -Compress
    [System.IO.File]::AppendAllText($logFile, $json + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
    
    Write-Host "✅ Test data written to: $logFile" -ForegroundColor Green
    Write-Host "   Compliance Rate: $($testData.compliance_rate)%" -ForegroundColor White
    Write-Host "   Trend: $($testData.trend) ($($testData.trend_percentage)%)" -ForegroundColor White
    
    return $testData
}

# Function to test SigNoz log ingestion
function Test-SigNozLogIngestion {
    Write-Host "🔍 Testing SigNoz log ingestion..." -ForegroundColor Yellow
    
    $queries = @(
        @{
            name = "ECRR Compliance Logs"
            query = 'log.file.path contains "C:/logs/ecrr/compliance-trends.log"'
        },
        @{
            name = "ECRR Compliance Dataset"
            query = 'attributes.dataset = "ecrr_compliance"'
        },
        @{
            name = "Compliance Trend Events"
            query = 'body contains "compliance_trend_calculated"'
        }
    )
    
    foreach ($query in $queries) {
        Write-Host ""
        Write-Host "📋 Testing: $($query.name)" -ForegroundColor Cyan
        Write-Host "   Query: $($query.query)" -ForegroundColor White
        
        try {
            $headers = @{
                "Content-Type" = "application/json"
            }
            
            $body = @{
                query = $query.query
                start = [DateTimeOffset]::UtcNow.AddHours(-1).ToUnixTimeSeconds()
                end = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$SigNozBaseURL/api/v1/query_range" -Method Post -Headers $headers -Body $body -ErrorAction Stop
            
            if ($response.status -eq "success") {
                Write-Host "   ✅ Query successful" -ForegroundColor Green
                if ($response.data.result.Count -gt 0) {
                    Write-Host "   📊 Found $($response.data.result.Count) log entries" -ForegroundColor White
                } else {
                    Write-Host "   ⚠️  No logs found (may need time for ingestion)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "   ❌ Query failed: $($response.error)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "   ❌ API Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Function to test SigNoz queries
function Test-SigNozQueries {
    Write-Host "🔍 Testing SigNoz compliance queries..." -ForegroundColor Yellow
    
    $queries = @(
        @{
            name = "Current Compliance Rate"
            query = '{dataset="ecrr_compliance"} | json | unwrap compliance_rate'
            description = "Extract compliance rate from JSON logs"
        },
        @{
            name = "Trend Analysis"
            query = '{dataset="ecrr_compliance"} | json | unwrap trend_percentage'
            description = "Get trend percentage change"
        },
        @{
            name = "Threshold Breaches"
            query = '{dataset="ecrr_compliance"} | json | compliance_rate < 80'
            description = "Find compliance below threshold"
        },
        @{
            name = "Recent Events"
            query = '{dataset="ecrr_compliance"} | json | event="compliance_trend_calculated"'
            description = "Get recent compliance calculations"
        }
    )
    
    foreach ($query in $queries) {
        Write-Host ""
        Write-Host "📋 $($query.name):" -ForegroundColor Cyan
        Write-Host "   Query: $($query.query)" -ForegroundColor White
        Write-Host "   Description: $($query.description)" -ForegroundColor White
        
        try {
            $headers = @{
                "Content-Type" = "application/json"
            }
            
            $body = @{
                query = $query.query
                start = [DateTimeOffset]::UtcNow.AddHours(-1).ToUnixTimeSeconds()
                end = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$SigNozBaseURL/api/v1/query_range" -Method Post -Headers $headers -Body $body -ErrorAction Stop
            
            if ($response.status -eq "success") {
                Write-Host "   ✅ Query successful" -ForegroundColor Green
                if ($response.data.result.Count -gt 0) {
                    Write-Host "   📊 Results: $($response.data.result.Count) data points" -ForegroundColor White
                } else {
                    Write-Host "   ⚠️  No data returned" -ForegroundColor Yellow
                }
            } else {
                Write-Host "   ❌ Query failed: $($response.error)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "   ❌ API Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Function to check SigNoz health
function Test-SigNozHealth {
    Write-Host "🏥 Checking SigNoz health..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "$SigNozBaseURL/api/v1/health" -Method Get -ErrorAction Stop
        Write-Host "✅ SigNoz is healthy" -ForegroundColor Green
        Write-Host "   Status: $($response.status)" -ForegroundColor White
        return $true
    }
    catch {
        Write-Host "❌ SigNoz health check failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Make sure SigNoz is running at $SigNozBaseURL" -ForegroundColor Yellow
        return $false
    }
}

# Main execution
try {
    Write-Host "🚀 Starting SigNoz integration test..." -ForegroundColor Green
    
    # Check SigNoz health
    $sigNozHealthy = Test-SigNozHealth
    if (-not $sigNozHealthy) {
        Write-Host ""
        Write-Host "⚠️  SigNoz is not accessible. Please ensure:" -ForegroundColor Yellow
        Write-Host "   1. SigNoz is running (docker-compose up)" -ForegroundColor White
        Write-Host "   2. SigNoz UI is accessible at $SigNozBaseURL" -ForegroundColor White
        Write-Host "   3. OTel collector is configured to send logs to SigNoz" -ForegroundColor White
        exit 1
    }
    
    # Generate test data if requested
    if ($GenerateTestData) {
        New-TestComplianceData
        Write-Host ""
        Write-Host "⏳ Waiting 30 seconds for log ingestion..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
    }
    
    # Test log ingestion
    if ($TestLogIngestion) {
        Test-SigNozLogIngestion
    }
    
    # Test queries
    if ($TestQueries) {
        Test-SigNozQueries
    }
    
    Write-Host ""
    Write-Host "🎯 Integration Test Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Import dashboard: artifacts/signoz-ecrr-compliance-dashboard.json" -ForegroundColor White
    Write-Host "   2. Run compliance monitoring: pwsh -File scripts/monitor-ecrr-compliance-trends.ps1 -GenerateReport" -ForegroundColor White
    Write-Host "   3. View dashboard in SigNoz UI: $SigNozBaseURL" -ForegroundColor White
    Write-Host "   4. Check logs: SigNoz Logs → filter by log.file.path contains 'C:/logs/ecrr/compliance-trends.log'" -ForegroundColor White
    
    exit 0
    
} catch {
    Write-Error "Integration test failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
