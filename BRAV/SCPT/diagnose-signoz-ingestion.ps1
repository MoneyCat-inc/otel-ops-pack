# Diagnose SigNoz Log Ingestion Issues
# Comprehensive diagnostic script for troubleshooting "no data" issues

# ECRR - Examine → Clean → Report → Role
Write-Host "🔍 Diagnose SigNoz Log Ingestion - ECRR Framework" -ForegroundColor Cyan
Write-Host "🎭 Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

Write-Host "`n📊 SigNoz Log Ingestion Diagnostic" -ForegroundColor Green

$DiagnosticResults = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    checks = @()
    recommendations = @()
}

# Check 1: Log Files Existence
Write-Host "`n1️⃣ Checking Log Files..." -ForegroundColor Yellow
$LogFiles = Get-ChildItem C:\logs\ | Where-Object { $_.Name -like "*canary*" }
if ($LogFiles) {
    Write-Host "  ✅ Found $($LogFiles.Count) canary log files" -ForegroundColor Green
    foreach ($File in $LogFiles) {
        Write-Host "    - $($File.Name) ($($File.Length) bytes, $($File.LastWriteTime))" -ForegroundColor White
    }
    $DiagnosticResults.checks += @{
        check = "log_files_exist"
        status = "pass"
        details = "Found $($LogFiles.Count) canary log files"
        files = $LogFiles | ForEach-Object { @{
            name = $_.Name
            size = $_.Length
            last_write = $_.LastWriteTime
        }}
    }
} else {
    Write-Host "  ❌ No canary log files found" -ForegroundColor Red
    $DiagnosticResults.checks += @{
        check = "log_files_exist"
        status = "fail"
        details = "No canary log files found in C:\logs\"
    }
    $DiagnosticResults.recommendations += "Generate canary logs using scripts/generate-windows-canary.ps1"
}

# Check 2: Log Content Format
Write-Host "`n2️⃣ Checking Log Content Format..." -ForegroundColor Yellow
$LatestCanaryLog = Get-ChildItem C:\logs\ | Where-Object { $_.Name -like "*canary*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($LatestCanaryLog) {
    $LogContent = Get-Content $LatestCanaryLog.FullName -TotalCount 1
    if ($LogContent -match '^{.*}$') {
        Write-Host "  ✅ Log format is valid JSON" -ForegroundColor Green
        Write-Host "  📄 Sample: $($LogContent.Substring(0, [Math]::Min(100, $LogContent.Length)))..." -ForegroundColor Gray
        
        try {
            $JsonContent = $LogContent | ConvertFrom-Json
            Write-Host "  📊 Available fields: $($JsonContent.PSObject.Properties.Name -join ', ')" -ForegroundColor Cyan
            $DiagnosticResults.checks += @{
                check = "log_format"
                status = "pass"
                details = "Valid JSON format with fields: $($JsonContent.PSObject.Properties.Name -join ', ')"
                sample_fields = $JsonContent.PSObject.Properties.Name
            }
        } catch {
            Write-Host "  ❌ Invalid JSON format" -ForegroundColor Red
            $DiagnosticResults.checks += @{
                check = "log_format"
                status = "fail"
                details = "Invalid JSON format"
            }
        }
    } else {
        Write-Host "  ❌ Log format is not JSON" -ForegroundColor Red
        $DiagnosticResults.checks += @{
            check = "log_format"
            status = "fail"
            details = "Log format is not JSON"
        }
    }
} else {
    Write-Host "  ❌ No canary log files to check" -ForegroundColor Red
    $DiagnosticResults.checks += @{
        check = "log_format"
        status = "fail"
        details = "No canary log files available"
    }
}

# Check 3: OTel Collector Status
Write-Host "`n3️⃣ Checking OTel Collector Status..." -ForegroundColor Yellow
try {
    $OtelService = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    if ($OtelService) {
        Write-Host "  📊 OTel Collector Service: $($OtelService.Status)" -ForegroundColor $(if ($OtelService.Status -eq "Running") { "Green" } else { "Yellow" })
        $DiagnosticResults.checks += @{
            check = "otel_collector"
            status = if ($OtelService.Status -eq "Running") { "pass" } else { "warning" }
            details = "Service status: $($OtelService.Status)"
            service_status = $OtelService.Status
        }
        
        if ($OtelService.Status -ne "Running") {
            $DiagnosticResults.recommendations += "Start OTel collector service: Start-Service otelcol-contrib"
        }
    } else {
        Write-Host "  ❌ OTel Collector service not found" -ForegroundColor Red
        $DiagnosticResults.checks += @{
            check = "otel_collector"
            status = "fail"
            details = "OTel collector service not found"
        }
        $DiagnosticResults.recommendations += "Install and configure OTel collector service"
    }
} catch {
    Write-Host "  ❌ Error checking OTel collector: $($_.Exception.Message)" -ForegroundColor Red
    $DiagnosticResults.checks += @{
        check = "otel_collector"
        status = "fail"
        details = "Error: $($_.Exception.Message)"
    }
}

# Check 4: SigNoz Health
Write-Host "`n4️⃣ Checking SigNoz Health..." -ForegroundColor Yellow
try {
    $SigNozHealth = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
    if ($SigNozHealth.status -eq "ok") {
        Write-Host "  ✅ SigNoz is healthy" -ForegroundColor Green
        $DiagnosticResults.checks += @{
            check = "signoz_health"
            status = "pass"
            details = "SigNoz is healthy and accessible"
        }
    } else {
        Write-Host "  ❌ SigNoz is not healthy: $($SigNozHealth.status)" -ForegroundColor Red
        $DiagnosticResults.checks += @{
            check = "signoz_health"
            status = "fail"
            details = "SigNoz status: $($SigNozHealth.status)"
        }
        $DiagnosticResults.recommendations += "Check SigNoz container status and logs"
    }
} catch {
    Write-Host "  ❌ Cannot connect to SigNoz: $($_.Exception.Message)" -ForegroundColor Red
    $DiagnosticResults.checks += @{
        check = "signoz_health"
        status = "fail"
        details = "Connection error: $($_.Exception.Message)"
    }
    $DiagnosticResults.recommendations += "Ensure SigNoz is running on http://localhost:8080"
}

# Check 5: Sample Queries
Write-Host "`n5️⃣ Testing Sample Queries..." -ForegroundColor Yellow
$SampleQueries = @(
    "body contains `"windows-canary`"",
    "log.file.path contains `"windows-canary-test.log`"",
    "service = `"canary-test`"",
    "test_id = `"canary-alert-test`"",
    "level = `"INFO`"",
    "canary = `"true`""
)

Write-Host "  📋 Recommended queries to test in SigNoz UI:" -ForegroundColor Cyan
foreach ($Query in $SampleQueries) {
    Write-Host "    - $Query" -ForegroundColor White
}

$DiagnosticResults.checks += @{
    check = "sample_queries"
    status = "info"
    details = "Generated $($SampleQueries.Count) sample queries for testing"
    queries = $SampleQueries
}

# Check 6: Time Range Analysis
Write-Host "`n6️⃣ Time Range Analysis..." -ForegroundColor Yellow
if ($LatestCanaryLog) {
    $LogAge = (Get-Date) - $LatestCanaryLog.LastWriteTime
    Write-Host "  📅 Latest canary log: $($LatestCanaryLog.LastWriteTime)" -ForegroundColor White
    Write-Host "  ⏰ Log age: $([math]::Round($LogAge.TotalMinutes, 1)) minutes" -ForegroundColor White
    
    if ($LogAge.TotalMinutes -lt 60) {
        Write-Host "  ✅ Logs are recent (within 1 hour)" -ForegroundColor Green
        $DiagnosticResults.checks += @{
            check = "time_range"
            status = "pass"
            details = "Logs are recent ($([math]::Round($LogAge.TotalMinutes, 1)) minutes old)"
        }
    } else {
        Write-Host "  ⚠️ Logs are older than 1 hour" -ForegroundColor Yellow
        $DiagnosticResults.checks += @{
            check = "time_range"
            status = "warning"
            details = "Logs are older than 1 hour ($([math]::Round($LogAge.TotalMinutes, 1)) minutes old)"
        }
        $DiagnosticResults.recommendations += "Generate fresh logs or expand SigNoz time range to include log generation time"
    }
} else {
    Write-Host "  ❌ No logs available for time analysis" -ForegroundColor Red
    $DiagnosticResults.checks += @{
        check = "time_range"
        status = "fail"
        details = "No logs available for time analysis"
    }
}

# Generate Summary
Write-Host "`n📊 Diagnostic Summary" -ForegroundColor Green
$PassedChecks = ($DiagnosticResults.checks | Where-Object { $_.status -eq "pass" }).Count
$FailedChecks = ($DiagnosticResults.checks | Where-Object { $_.status -eq "fail" }).Count
$WarningChecks = ($DiagnosticResults.checks | Where-Object { $_.status -eq "warning" }).Count

Write-Host "  ✅ Passed: $PassedChecks checks" -ForegroundColor Green
Write-Host "  ⚠️ Warnings: $WarningChecks checks" -ForegroundColor Yellow
Write-Host "  ❌ Failed: $FailedChecks checks" -ForegroundColor Red

if ($DiagnosticResults.recommendations.Count -gt 0) {
    Write-Host "`n💡 Recommendations:" -ForegroundColor Cyan
    foreach ($Recommendation in $DiagnosticResults.recommendations) {
        Write-Host "  - $Recommendation" -ForegroundColor White
    }
}

# Save diagnostic results
$DiagnosticFile = "artifacts\signoz-ingestion-diagnostic.json"
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}
$DiagnosticResults | ConvertTo-Json -Depth 4 | Set-Content -Path $DiagnosticFile -Encoding UTF8
Write-Host "`n💾 Diagnostic results saved to: $DiagnosticFile" -ForegroundColor Green

# Generate actionable steps
Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test these queries in SigNoz UI (Logs → Explore):" -ForegroundColor White
Write-Host "   - body contains `"windows-canary`"" -ForegroundColor Gray
Write-Host "   - service = `"canary-test`"" -ForegroundColor Gray
Write-Host "   - test_id = `"canary-alert-test`"" -ForegroundColor Gray
Write-Host "2. Set time range to 'Last 24 hours' in SigNoz UI" -ForegroundColor White
Write-Host "3. Use SigNoz field explorer to verify exact field names" -ForegroundColor White
Write-Host "4. If still no data, check OTel collector configuration" -ForegroundColor White

Write-Host "`n🎭 Role: Cursor-Local (Observability Copilot) - Ingestion Diagnostic Complete" -ForegroundColor Magenta
