# Parser Error Status Verification
# Check current status of SigNoz parser errors and validation

param(
    [int]$TimeWindow = 1,
    [switch]$Verbose = $false
)

Write-Host "🔍 Parser Error Status Verification" -ForegroundColor Cyan
Write-Host "Time Window: Last $TimeWindow hour(s)" -ForegroundColor Gray
Write-Host ""

# Check parser errors in SigNoz
Write-Host "📊 SigNoz Parser Error Analysis:" -ForegroundColor Yellow
try {
    $parserQuery = "SELECT count() FROM signoz_logs.logs_v2 WHERE severity_text='ERROR' AND body LIKE '%parser%' AND fromUnixTimestamp64Nano(timestamp) > (now() - toIntervalHour($TimeWindow))"
    $parserResult = docker exec signoz-clickhouse clickhouse-client --query "$parserQuery"
    Write-Host "  Parser errors (last $TimeWindow hr): $parserResult" -ForegroundColor $(if ($parserResult -eq "0") { "Green" } else { "Red" })
} catch {
    Write-Host "  Parser error query failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check total errors
try {
    $totalQuery = "SELECT count() FROM signoz_logs.logs_v2 WHERE severity_text='ERROR' AND fromUnixTimestamp64Nano(timestamp) > (now() - toIntervalHour($TimeWindow))"
    $totalResult = docker exec signoz-clickhouse clickhouse-client --query "$totalQuery"
    Write-Host "  Total errors (last $TimeWindow hr): $totalResult" -ForegroundColor White
} catch {
    Write-Host "  Total error query failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Check JSON validation of test files
Write-Host "📄 JSON Test File Validation:" -ForegroundColor Yellow
$testFiles = @(
    "C:\logs\canary\parser-regression-test.jsonl",
    "C:\logs\parser-test.jsonl",
    "C:\logs\canary-test.log"
)

foreach ($file in $testFiles) {
    $filename = Split-Path $file -Leaf
    if (Test-Path $file) {
        try {
            $content = Get-Content $file -Raw
            if ($content.Trim()) {
                # Try to parse each line as JSON
                $lines = Get-Content $file
                $validLines = 0
                $totalLines = $lines.Count
                
                foreach ($line in $lines) {
                    if ($line.Trim()) {
                        try {
                            $line | ConvertFrom-Json | Out-Null
                            $validLines++
                        } catch {
                            if ($Verbose) {
                                Write-Host "    Invalid line: $line" -ForegroundColor DarkGray
                            }
                        }
                    }
                }
                
                if ($validLines -eq $totalLines) {
                    Write-Host "  $filename`: VALID ✅ ($validLines/$totalLines lines)" -ForegroundColor Green
                } else {
                    Write-Host "  $filename`: PARTIAL ⚠️ ($validLines/$totalLines lines valid)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  $filename`: EMPTY" -ForegroundColor Gray
            }
        } catch {
            Write-Host "  $filename`: INVALID ❌" -ForegroundColor Red
            if ($Verbose) {
                Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor DarkRed
            }
        }
    } else {
        Write-Host "  $filename`: NOT FOUND" -ForegroundColor Gray
    }
}

Write-Host ""

# Check service status
Write-Host "🔧 Service Status:" -ForegroundColor Yellow
try {
    $serviceStatus = sc.exe query otelcol-contrib
    if ($serviceStatus -match "RUNNING") {
        Write-Host "  Windows Collector: RUNNING ✅" -ForegroundColor Green
    } else {
        Write-Host "  Windows Collector: NOT RUNNING ❌" -ForegroundColor Red
    }
} catch {
    Write-Host "  Windows Collector: STATUS UNKNOWN" -ForegroundColor Yellow
}

# Check Docker containers
try {
    $sigNozStatus = docker ps --filter name=signoz-clickhouse --format "{{.Status}}"
    if ($sigNozStatus -match "Up") {
        Write-Host "  SigNoz ClickHouse: RUNNING ✅" -ForegroundColor Green
    } else {
        Write-Host "  SigNoz ClickHouse: NOT RUNNING ❌" -ForegroundColor Red
    }
} catch {
    Write-Host "  SigNoz ClickHouse: STATUS UNKNOWN" -ForegroundColor Yellow
}

Write-Host ""

# Summary and recommendations
Write-Host "📋 Parser Status Summary:" -ForegroundColor Cyan
try {
    if ($parserResult -eq "0") {
        Write-Host "  ✅ Parser errors: RESOLVED (0 errors)" -ForegroundColor Green
        Write-Host "  ✅ Status: T05 Parser Errors task appears COMPLETE" -ForegroundColor Green
    } elseif ($parserResult -lt 5) {
        Write-Host "  ⚠️ Parser errors: LOW ($parserResult errors)" -ForegroundColor Yellow
        Write-Host "  ⚠️ Status: Minor parser issues detected" -ForegroundColor Yellow
    } else {
        Write-Host "  ❌ Parser errors: HIGH ($parserResult errors)" -ForegroundColor Red
        Write-Host "  ❌ Status: Significant parser issues need attention" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❓ Parser errors: UNABLE TO DETERMINE" -ForegroundColor Yellow
    Write-Host "  ❓ Status: Manual verification needed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Next Actions:" -ForegroundColor Cyan
Write-Host "  1. If 0 parser errors: Mark T05 as COMPLETED" -ForegroundColor White
Write-Host "  2. If >0 errors: Investigate specific error sources" -ForegroundColor White
Write-Host "  3. Continue with T03 (Canary Monitoring) next" -ForegroundColor White

return @{
    parserErrors = $parserResult
    totalErrors = $totalResult
    status = if ($parserResult -eq "0") { "RESOLVED" } else { "NEEDS_ATTENTION" }
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}
