# IONA Supervisor Demo Runner
# Emits job lifecycle metrics, histograms, and traces with progress indicators
# Demonstrates the complete observability pipeline for IONA jobs

param(
    [string]$JobIdPrefix = "demo-job",
    [int]$JobCount = 3,
    [int]$MinDurationMs = 100,
    [int]$MaxDurationMs = 2000,
    [switch]$EnableTracing = $false,
    [string]$Mode = "random" # random, Companion, Practice, Assessment, Analysis
)

# Load the metrics helper functions
. "$PSScriptRoot\metrics.ps1"

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

function Get-RandomMode {
    $modes = @("Companion", "Practice", "Assessment", "Analysis")
    return $modes | Get-Random
}

function Get-RandomDuration {
    param(
        [int]$MinMs,
        [int]$MaxMs
    )
    return Get-Random -Minimum $MinMs -Maximum $MaxMs
}

function Update-QueueGauge {
    param(
        [int]$Count,
        [string]$Mode
    )
    try {
        Send-IonaMetric -Name "iona_jobs_queued" -Type "gauge" -Value $Count -Labels @{ mode = $Mode } -Description "Number of jobs currently queued" -Async | Out-Null
    }
    catch {
        # Silently continue - metrics are best-effort
    }
}

function Update-RunningGauge {
    param(
        [int]$Count,
        [string]$Mode
    )
    try {
        Send-IonaMetric -Name "iona_jobs_running" -Type "gauge" -Value $Count -Labels @{ mode = $Mode } -Description "Number of jobs currently running" -Async | Out-Null
    }
    catch {
        # Silently continue - metrics are best-effort
    }
}

function Invoke-IonaJob {
    param(
        [string]$JobId,
        [string]$Mode,
        [int]$DurationMs,
        [bool]$ShouldFail = $false
    )
    
    $startTime = Get-Date
    $traceId = ""
    $spanId = ""
    
    # Start job metrics
    Update-RunningGauge -Count 1 -Mode $Mode
    
    if ($EnableTracing) {
        try {
            $traceId = [System.Guid]::NewGuid().ToString("N").Substring(0, 32)
            $spanId = [System.Guid]::NewGuid().ToString("N").Substring(0, 16)
            
            Send-IonaSpan -Name "iona.job.start" -Status "ok" -DurationMs 0 -Attributes @{
                job_id = $JobId
                mode = $Mode
                status = "started"
            } -TraceId $traceId -SpanId $spanId -Async | Out-Null
        }
        catch {
            # Silently continue - tracing is best-effort
        }
    }
    
    # Simulate job execution with progress
    $progressSteps = 10
    $stepDuration = $DurationMs / $progressSteps
    
    for ($i = 0; $i -lt $progressSteps; $i++) {
        $progress = [math]::Round(($i / $progressSteps) * 100)
        Write-ProgressSpinner -Message "Executing $JobId ($Mode) - $progress%" -Index $i
        
        Start-Sleep -Milliseconds $stepDuration
        
        # Simulate occasional failures
        if ($ShouldFail -and $i -eq 5) {
            throw "Simulated job failure for testing"
        }
    }
    
    $endTime = Get-Date
    $actualDuration = ($endTime - $startTime).TotalMilliseconds
    
    # Complete job metrics
    Update-RunningGauge -Count 0 -Mode $Mode
    
    if ($ShouldFail) {
        # Job failed
        try {
            Send-IonaMetric -Name "iona_jobs_failed_total" -Type "counter" -Value 1 -Labels @{ 
                mode = $Mode
                error_type = "simulated_failure"
            } -Description "Total number of failed jobs" -Async | Out-Null
            
            if ($EnableTracing) {
                Send-IonaSpan -Name "iona.job.failed" -Status "error" -DurationMs $actualDuration -Attributes @{
                    job_id = $JobId
                    mode = $Mode
                    status = "failed"
                    error_type = "simulated_failure"
                } -TraceId $traceId -SpanId $spanId -Async | Out-Null
            }
        }
        catch {
            # Silently continue
        }
        
        Write-Host "`r$JobId ($Mode) FAILED after $([math]::Round($actualDuration))ms" -ForegroundColor Red
    }
    else {
        # Job completed successfully
        try {
            Send-IonaMetric -Name "iona_jobs_completed_total" -Type "counter" -Value 1 -Labels @{ mode = $Mode } -Description "Total number of completed jobs" -Async | Out-Null
            
            Send-IonaMetric -Name "iona_job_duration_ms" -Type "histogram" -Value $actualDuration -Labels @{ mode = $Mode } -Description "Job execution duration in milliseconds" -Async | Out-Null
            
            if ($EnableTracing) {
                Send-IonaSpan -Name "iona.job.completed" -Status "ok" -DurationMs $actualDuration -Attributes @{
                    job_id = $JobId
                    mode = $Mode
                    status = "completed"
                } -TraceId $traceId -SpanId $spanId -Async | Out-Null
            }
        }
        catch {
            # Silently continue
        }
        
        Write-Host "`r$JobId ($Mode) completed in $([math]::Round($actualDuration))ms" -ForegroundColor Green
    }
}

function Start-IonaSupervisorDemo {
    Write-Host "Starting IONA Supervisor Demo" -ForegroundColor Cyan
    Write-Host "   Jobs: $JobCount" -ForegroundColor Gray
    Write-Host "   Duration: ${MinDurationMs}-${MaxDurationMs}ms" -ForegroundColor Gray
    Write-Host "   Tracing: $EnableTracing" -ForegroundColor Gray
    Write-Host "   Mode: $Mode" -ForegroundColor Gray
    Write-Host ""
    
    # Initialize queue metrics
    $modes = if ($Mode -eq "random") { @("Companion", "Practice", "Assessment", "Analysis") } else { @($Mode) }
    foreach ($m in $modes) {
        Update-QueueGauge -Count $JobCount -Mode $m
        Update-RunningGauge -Count 0 -Mode $m
    }
    
    # Execute jobs
    for ($i = 1; $i -le $JobCount; $i++) {
        $jobId = "$JobIdPrefix-$i"
        $jobMode = if ($Mode -eq "random") { Get-RandomMode } else { $Mode }
        $duration = Get-RandomDuration -MinMs $MinDurationMs -MaxMs $MaxDurationMs
        $shouldFail = (Get-Random -Minimum 1 -Maximum 10) -eq 1 # 10% failure rate
        
        Write-Host "Queuing job ${i}/${JobCount}: ${jobId} (${jobMode})" -ForegroundColor Yellow
        
        # Update queue metrics
        Update-QueueGauge -Count ($JobCount - $i) -Mode $jobMode
        
        try {
            Invoke-IonaJob -JobId $jobId -Mode $jobMode -DurationMs $duration -ShouldFail $shouldFail
        }
        catch {
            Write-Host "`r❌ Job $jobId failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # Small delay between jobs
        Start-Sleep -Milliseconds 100
    }
    
    # Clear progress line
    Write-Host "`r" -NoNewline
    
    Write-Host "Demo completed! Sent metrics and traces to SigNoz" -ForegroundColor Green
    Write-Host "   Check SigNoz UI -> Metrics -> Explorer for: sum(rate(iona_jobs_completed_total{mode!=\"\"}[5m]))" -ForegroundColor Gray
    if ($EnableTracing) {
        Write-Host "   Check SigNoz UI -> Traces -> Search -> Filter: service.name = \"iona-supervisor\"" -ForegroundColor Gray
    }
}

# Main execution
try {
    Start-IonaSupervisorDemo
}
catch {
    Write-Host "Demo failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}