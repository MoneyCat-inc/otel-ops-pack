# IONA Supervisor OTLP Metrics & Traces Helper
# Provides Send-IonaMetric, Send-IonaSpan, and Test-IonaMetricsEndpoint functions
# with retry/backoff and async fire-and-forget support

param(
    [string]$MetricsEndpoint = "http://localhost:5318/v1/metrics",
    [string]$TracesEndpoint  = "http://localhost:5318/v1/traces",
    [int]$MaxRetries = 2,
    [int]$InitialBackoffMs = 250
)

# Animation characters for progress indication
$spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')

function Write-ProgressSpinner {
    param(
        [string]$Message,
        [int]$Index = 0
    )
    Write-Host "`r$($spinner[$Index % $spinner.Count]) $Message" -NoNewline -ForegroundColor Cyan
}

function Invoke-RetryWithBackoff {
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 2,
        [int]$InitialBackoffMs = 250
    )
    
    $attempt = 0
    $backoffMs = $InitialBackoffMs
    
    while ($attempt -le $MaxRetries) {
        try {
            return & $ScriptBlock
        }
        catch {
            $attempt++
            if ($attempt -gt $MaxRetries) {
                throw $_
            }
            
            Write-Host "`n⚠️  Attempt $attempt failed, retrying in $backoffMs ms..." -ForegroundColor Yellow
            Start-Sleep -Milliseconds $backoffMs
            $backoffMs = [math]::Min($backoffMs * 2, 2000) # Cap at 2 seconds
        }
    }
}

function Send-IonaMetric {
    param(
        [string]$Name,
        [string]$Type = "counter", # counter, gauge, histogram
        [double]$Value = 1,
        [hashtable]$Labels = @{},
        [string]$Description = "",
        [switch]$Async = $false
    )
    
    $metricPayload = @{
        resourceMetrics = @(
            @{
                resource = @{
                    attributes = @(
                        @{ key = "service.name"; value = @{ stringValue = "iona-supervisor" } },
                        @{ key = "service.namespace"; value = @{ stringValue = "iona" } },
                        @{ key = "deployment.environment"; value = @{ stringValue = "local" } }
                    )
                }
                scopeMetrics = @(
                    @{
                        scope = @{ name = "iona-supervisor" }
                        metrics = @(
                            @{
                                name = $Name
                                description = $Description
                                unit = if ($Type -eq "histogram") { "ms" } else { "" }
                                $Type = @{
                                    dataPoints = @(
                                        @{
                                            timeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                                            attributes = @(
                                                foreach ($label in $Labels.GetEnumerator()) {
                                                    @{ key = $label.Key; value = @{ stringValue = $label.Value.ToString() } }
                                                }
                                            )
                                            $($Type + "Value") = if ($Type -eq "histogram") { 
                                                @{ 
                                                    count = 1
                                                    sum = $Value
                                                    bucketCounts = @(0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
                                                    explicitBounds = @(1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000)
                                                }
                                            } else { $Value }
                                        }
                                    )
                                }
                            }
                        )
                    }
                )
            }
        )
    }
    
    $jsonPayload = $metricPayload | ConvertTo-Json -Depth 10
    
    $sendAction = {
        try {
            $response = Invoke-RestMethod -Uri $MetricsEndpoint -Method Post -Body $jsonPayload -ContentType "application/json" -TimeoutSec 5
            return $true
        }
        catch {
            Write-Warning "Failed to send metric '$Name': $($_.Exception.Message)"
            throw $_
        }
    }
    
    if ($Async) {
        # Fire-and-forget async execution
        Start-Job -ScriptBlock $sendAction | Out-Null
        return $true
    }
    else {
        return Invoke-RetryWithBackoff -ScriptBlock $sendAction -MaxRetries $MaxRetries -InitialBackoffMs $InitialBackoffMs
    }
}

function Send-IonaSpan {
    param(
        [string]$Name,
        [string]$Status = "ok", # ok, error
        [int]$DurationMs = 0,
        [hashtable]$Attributes = @{},
        [string]$TraceId = "",
        [string]$SpanId = "",
        [string]$ParentSpanId = "",
        [switch]$Async = $false
    )
    
    # Generate IDs if not provided
    if (-not $TraceId) { $TraceId = [System.Guid]::NewGuid().ToString("N").Substring(0, 32) }
    if (-not $SpanId) { $SpanId = [System.Guid]::NewGuid().ToString("N").Substring(0, 16) }
    
    $startTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
    $endTime = $startTime + ($DurationMs * 1000000)
    
    $tracePayload = @{
        resourceSpans = @(
            @{
                resource = @{
                    attributes = @(
                        @{ key = "service.name"; value = @{ stringValue = "iona-supervisor" } },
                        @{ key = "service.namespace"; value = @{ stringValue = "iona" } },
                        @{ key = "deployment.environment"; value = @{ stringValue = "local" } }
                    )
                }
                scopeSpans = @(
                    @{
                        scope = @{ name = "iona-supervisor" }
                        spans = @(
                            @{
                                traceId = $TraceId
                                spanId = $SpanId
                                parentSpanId = if ($ParentSpanId) { $ParentSpanId } else { $null }
                                name = $Name
                                kind = 1 # SPAN_KIND_INTERNAL
                                startTimeUnixNano = $startTime
                                endTimeUnixNano = $endTime
                                status = @{
                                    code = if ($Status -eq "error") { 2 } else { 1 } # ERROR = 2, OK = 1
                                    message = if ($Status -eq "error") { "Job failed" } else { "" }
                                }
                                attributes = @(
                                    @{ key = "job.name"; value = @{ stringValue = $Name } },
                                    @{ key = "job.status"; value = @{ stringValue = $Status } },
                                    @{ key = "job.duration_ms"; value = @{ intValue = $DurationMs } }
                                ) + @(
                                    foreach ($attr in $Attributes.GetEnumerator()) {
                                        @{ key = $attr.Key; value = @{ stringValue = $attr.Value.ToString() } }
                                    }
                                )
                            }
                        )
                    }
                )
            }
        )
    }
    
    $jsonPayload = $tracePayload | ConvertTo-Json -Depth 10
    
    $sendAction = {
        try {
            $response = Invoke-RestMethod -Uri $TracesEndpoint -Method Post -Body $jsonPayload -ContentType "application/json" -TimeoutSec 5
            return $true
        }
        catch {
            Write-Warning "Failed to send span '$Name': $($_.Exception.Message)"
            throw $_
        }
    }
    
    if ($Async) {
        # Fire-and-forget async execution
        Start-Job -ScriptBlock $sendAction | Out-Null
        return $true
    }
    else {
        return Invoke-RetryWithBackoff -ScriptBlock $sendAction -MaxRetries $MaxRetries -InitialBackoffMs $InitialBackoffMs
    }
}

function Test-IonaMetricsEndpoint {
    param(
        [string]$Endpoint = $MetricsEndpoint
    )
    
    Write-Host "🔍 Testing IONA metrics endpoint: $Endpoint" -ForegroundColor Cyan
    
    try {
        # Send a probe metric to test connectivity
        $probeResult = Send-IonaMetric -Name "iona_probe_test" -Type "counter" -Value 1 -Labels @{ test = "connectivity" } -Description "Probe metric to test endpoint connectivity"
        
        if ($probeResult) {
            Write-Host "✅ IONA metrics endpoint is reachable" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "❌ IONA metrics endpoint test failed" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ IONA metrics endpoint test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-IonaTracesEndpoint {
    param(
        [string]$Endpoint = $TracesEndpoint
    )
    
    Write-Host "🔍 Testing IONA traces endpoint: $Endpoint" -ForegroundColor Cyan
    
    try {
        # Send a probe span to test connectivity
        $probeResult = Send-IonaSpan -Name "iona_probe_test" -Status "ok" -DurationMs 1 -Attributes @{ test = "connectivity" }
        
        if ($probeResult) {
            Write-Host "✅ IONA traces endpoint is reachable" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "❌ IONA traces endpoint test failed" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ IONA traces endpoint test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Functions are available for use in other scripts when sourced with . .\scripts\metrics.ps1

Write-Host "📊 IONA OTLP helpers loaded successfully" -ForegroundColor Green
Write-Host "   Available functions: Send-IonaMetric, Send-IonaSpan, Test-IonaMetricsEndpoint, Test-IonaTracesEndpoint" -ForegroundColor Gray