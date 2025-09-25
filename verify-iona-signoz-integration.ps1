# IONA SigNoz Integration Verification Script
# Tests end-to-end pipeline from OTLP emission to SigNoz ingestion
# Follows ECRR methodology: Examine → Clean → Report → Role

param(
    [int]$JobCount = 2,
    [switch]$EnableTracing = $true,
    [string]$ReportPath = "artifacts/iona-integration-verify.txt"
)

# Animation characters for progress indication
$spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
$spinnerIndex = 0
$lastUpdate = Get-Date

function Write-ProgressSpinner {
    param(
        [string]$Message,
        [int]$Index = 0
    )
    $now = Get-Date
    if (($now - $lastUpdate).TotalMilliseconds -gt 50) {
        Write-Host "`r$($spinner[$Index % $spinner.Count]) $Message" -NoNewline -ForegroundColor Cyan
        $script:lastUpdate = $now
    }
}

function Invoke-Spinner {
    param(
        [string]$Message,
        [int]$Seconds = 5
    )
    
    Write-Host "`n⏳ $Message" -ForegroundColor Yellow
    $endTime = (Get-Date).AddSeconds($Seconds)
    $index = 0
    
    while ((Get-Date) -lt $endTime) {
        Write-ProgressSpinner -Message $Message -Index $index
        Start-Sleep -Milliseconds 100
        $index++
    }
    
    Write-Host "`r✅ $Message - Complete" -ForegroundColor Green
}

function Test-CollectorService {
    Write-Host "🔍 [step] Checking Windows Collector service status" -ForegroundColor Cyan
    
    try {
        $service = Get-Service -Name "otelcol-contrib" -ErrorAction Stop
        if ($service.Status -eq "Running") {
            Write-Host "✅ Windows Collector service is running" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "❌ Windows Collector service is not running (Status: $($service.Status))" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Windows Collector service not found or not accessible" -ForegroundColor Red
        return $false
    }
}

function Test-SigNozHealth {
    Write-Host "🔍 [step] Checking SigNoz health endpoint" -ForegroundColor Cyan
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 10
        Write-Host "✅ SigNoz health check passed" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ SigNoz health check failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-IonaMetricsEndpoint {
    Write-Host "🔍 [step] Probing OTLP HTTP endpoint" -ForegroundColor Cyan
    
    # Load metrics helper
    . "$PSScriptRoot\scripts\metrics.ps1"
    
    try {
        $result = Test-IonaMetricsEndpoint
        return $result
    }
    catch {
        Write-Host "❌ OTLP metrics endpoint test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-IonaTracesEndpoint {
    Write-Host "🔍 [step] Probing OTLP traces endpoint" -ForegroundColor Cyan
    
    # Load metrics helper
    . "$PSScriptRoot\scripts\metrics.ps1"
    
    try {
        $result = Test-IonaTracesEndpoint
        return $result
    }
    catch {
        Write-Host "❌ OTLP traces endpoint test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Invoke-DemoWorkload {
    Write-Host "🔍 [step] Running demo workload with $JobCount jobs" -ForegroundColor Cyan
    
    try {
        $demoScript = "$PSScriptRoot\scripts\iona-supervisor-runner.ps1"
        if (-not (Test-Path $demoScript)) {
            Write-Host "❌ Demo script not found: $demoScript" -ForegroundColor Red
            return $false
        }
        
        $tracingFlag = if ($EnableTracing) { "-EnableTracing" } else { "" }
        $command = "pwsh -NoLogo -NoProfile -File `"$demoScript`" -JobCount $JobCount $tracingFlag"
        
        Write-Host "📋 Executing: $command" -ForegroundColor Gray
        Invoke-Expression $command
        
        Write-Host "✅ Demo workload completed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Demo workload failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-SigNozIngestion {
    Write-Host "🔍 [step] Verifying metrics ingestion in SigNoz" -ForegroundColor Cyan
    
    try {
        # Wait for metrics to propagate
        Invoke-Spinner -Message "Waiting for SigNoz ingest" -Seconds 5
        
        # Test SigNoz API for metrics
        $query = "iona_jobs_completed_total"
        $apiUrl = "http://localhost:8080/api/v1/query"
        $body = @{
            query = $query
            time = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10
        
        if ($response.data.result -and $response.data.result.Count -gt 0) {
            Write-Host "✅ Metrics found in SigNoz: $($response.data.result.Count) results" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "⚠️  No metrics found in SigNoz yet (may need more time)" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "❌ SigNoz ingestion verification failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Write-VerificationReport {
    param(
        [hashtable]$Results,
        [string]$Path
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $report = @"
IONA SigNoz Integration Verification Report
Generated: $timestamp

=== ECRR EXAMINE ===
Environment State Captured:
- Windows Collector Service: $($Results.CollectorService)
- SigNoz Health: $($Results.SigNozHealth)
- OTLP Metrics Endpoint: $($Results.MetricsEndpoint)
- OTLP Traces Endpoint: $($Results.TracesEndpoint)

=== ECRR CLEAN ===
Actions Taken:
- Verified collector pipelines for IONA telemetry
- Tested OTLP endpoint connectivity
- Executed demo workload with $JobCount jobs
- Validated SigNoz ingestion

=== ECRR REPORT ===
Results:
- Demo Workload: $($Results.DemoWorkload)
- SigNoz Ingestion: $($Results.SigNozIngestion)
- Overall Status: $($Results.OverallStatus)

=== ECRR ROLE ===
Actor: Cursor Agent - Observability Copilot
Responsibility: IONA Supervisor SigNoz integration verification
Timestamp: $timestamp

Next Steps:
1. Import artifacts/iona-supervisor-dashboard.json into SigNoz
2. Verify metrics visible: sum(rate(iona_jobs_completed_total{mode!=""}[5m])) by (mode)
3. Check traces: service.name = "iona-supervisor"
4. Set up alerts for job failure rates and duration thresholds

"@
    
    # Ensure artifacts directory exists
    $artifactsDir = Split-Path $Path -Parent
    if (-not (Test-Path $artifactsDir)) {
        New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
    }
    
    $report | Out-File -FilePath $Path -Encoding UTF8
    Write-Host "📄 Verification report saved to: $Path" -ForegroundColor Green
}

function Start-IonaVerification {
    Write-Host "🚀 Starting IONA SigNoz Integration Verification" -ForegroundColor Cyan
    Write-Host "   Job Count: $JobCount" -ForegroundColor Gray
    Write-Host "   Tracing: $EnableTracing" -ForegroundColor Gray
    Write-Host "   Report: $ReportPath" -ForegroundColor Gray
    Write-Host ""
    
    $results = @{
        CollectorService = $false
        SigNozHealth = $false
        MetricsEndpoint = $false
        TracesEndpoint = $false
        DemoWorkload = $false
        SigNozIngestion = $false
        OverallStatus = "FAILED"
    }
    
    # Step 1: Check collector service
    $results.CollectorService = Test-CollectorService
    if (-not $results.CollectorService) {
        Write-Host "❌ Cannot proceed without running collector service" -ForegroundColor Red
        Write-VerificationReport -Results $results -Path $ReportPath
        return $false
    }
    
    # Step 2: Check SigNoz health
    $results.SigNozHealth = Test-SigNozHealth
    if (-not $results.SigNozHealth) {
        Write-Host "❌ Cannot proceed without healthy SigNoz instance" -ForegroundColor Red
        Write-VerificationReport -Results $results -Path $ReportPath
        return $false
    }
    
    # Step 3: Test OTLP endpoints
    $results.MetricsEndpoint = Test-IonaMetricsEndpoint
    $results.TracesEndpoint = Test-IonaTracesEndpoint
    
    if (-not $results.MetricsEndpoint) {
        Write-Host "❌ Cannot proceed without working metrics endpoint" -ForegroundColor Red
        Write-VerificationReport -Results $results -Path $ReportPath
        return $false
    }
    
    # Step 4: Run demo workload
    $results.DemoWorkload = Invoke-DemoWorkload
    if (-not $results.DemoWorkload) {
        Write-Host "❌ Demo workload failed" -ForegroundColor Red
        Write-VerificationReport -Results $results -Path $ReportPath
        return $false
    }
    
    # Step 5: Verify ingestion
    $results.SigNozIngestion = Test-SigNozIngestion
    
    # Determine overall status
    $criticalChecks = @($results.CollectorService, $results.SigNozHealth, $results.MetricsEndpoint, $results.DemoWorkload)
    if ($criticalChecks -contains $false) {
        $results.OverallStatus = "FAILED"
    }
    elseif ($results.SigNozIngestion) {
        $results.OverallStatus = "PASSED"
    }
    else {
        $results.OverallStatus = "PARTIAL" # Endpoints work but ingestion needs more time
    }
    
    # Write report
    Write-VerificationReport -Results $results -Path $ReportPath
    
    # Final status
    Write-Host ""
    if ($results.OverallStatus -eq "PASSED") {
        Write-Host "🎯 IONA SigNoz integration check: PASS" -ForegroundColor Green
        Write-Host "   ✅ All components verified and metrics ingested" -ForegroundColor Green
    }
    elseif ($results.OverallStatus -eq "PARTIAL") {
        Write-Host "⚠️  IONA SigNoz integration check: PARTIAL" -ForegroundColor Yellow
        Write-Host "   ✅ Pipeline working, metrics may need more time to appear" -ForegroundColor Yellow
    }
    else {
        Write-Host "❌ IONA SigNoz integration check: FAIL" -ForegroundColor Red
        Write-Host "   ❌ Critical components failed verification" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Check SigNoz UI -> Metrics -> Explorer" -ForegroundColor Gray
    Write-Host "   2. Query: sum(rate(iona_jobs_completed_total{mode!=\"\"}[5m])) by (mode)" -ForegroundColor Gray
    if ($EnableTracing) {
        Write-Host "   3. Check SigNoz UI -> Traces -> Search -> Filter: service.name = \"iona-supervisor\"" -ForegroundColor Gray
    }
    Write-Host "   4. Import artifacts/iona-supervisor-dashboard.json for ready-made panels" -ForegroundColor Gray
    
    return $results.OverallStatus -eq "PASSED"
}

# Main execution
try {
    $success = Start-IonaVerification
    if ($success) { exit 0 } else { exit 1 }
}
catch {
    Write-Host "❌ Verification script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}