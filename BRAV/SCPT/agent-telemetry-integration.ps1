#Requires -Version 7.0

<#
.SYNOPSIS
    Agent Telemetry Integration for Bosscat Parallel Agent Framework
    Integrates agent performance tracking with existing SigNoz monitoring

.DESCRIPTION
    This module provides comprehensive telemetry integration for parallel agents,
    sending performance metrics, logs, and traces to SigNoz for real-time monitoring
    and analysis.

.PARAMETER AgentId
    Unique identifier for the agent

.PARAMETER TelemetryEndpoint
    SigNoz OTLP endpoint URL

.PARAMETER TelemetryType
    Type of telemetry to send (metrics, logs, traces, all)

.PARAMETER SamplingRate
    Telemetry sampling rate (0.0 to 1.0)

.PARAMETER BatchSize
    Number of telemetry items to batch before sending

.EXAMPLE
    .\agent-telemetry-integration.ps1 -AgentId "agent-001" -TelemetryType "all"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$AgentId,
    
    [string]$TelemetryEndpoint,
    
    [ValidateSet('metrics', 'logs', 'traces', 'all')]
    [string]$TelemetryType = 'all',
    
    [ValidateRange(0.0, 1.0)]
    [double]$SamplingRate = 1.0,
    
    [int]$BatchSize = 100,
    
    [int]$BatchTimeoutSeconds = 30,
    
    [switch]$EnableCompression,
    
    [switch]$EnableRetry,
    
    [int]$MaxRetries = 3,
    
    [string]$ServiceName = 'bosscat-parallel-agents',
    
    [hashtable]$CustomTags = @{}
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'lib\OtelPorts.psm1') -Force
$script:OtelPorts = Get-OtelPorts
if (-not $TelemetryEndpoint) { $TelemetryEndpoint = "$(Get-OtelIngestHttpBase -HostName 'localhost' -Ports $script:OtelPorts)/v1/traces" }

# Telemetry Integration Classes
class AgentTelemetryCollector {
    [string]$AgentId
    [string]$ServiceName
    [hashtable]$Tags
    [System.Collections.ArrayList]$MetricsBuffer
    [System.Collections.ArrayList]$LogsBuffer
    [System.Collections.ArrayList]$TracesBuffer
    [datetime]$LastFlush
    [bool]$IsEnabled
    
    AgentTelemetryCollector([string]$agentId, [string]$serviceName, [hashtable]$tags) {
        $this.AgentId = $agentId
        $this.ServiceName = $serviceName
        $this.Tags = $tags
        $this.MetricsBuffer = [System.Collections.ArrayList]::new()
        $this.LogsBuffer = [System.Collections.ArrayList]::new()
        $this.TracesBuffer = [System.Collections.ArrayList]::new()
        $this.LastFlush = Get-Date
        $this.IsEnabled = $true
    }
    
    [void] RecordMetric([string]$name, [double]$value, [hashtable]$tags = @{}, [string]$unit = '') {
        if (-not $this.IsEnabled) { return }
        
        $metric = @{
            timestamp = (Get-Date).ToString('o')
            name = $name
            value = $value
            unit = $unit
            tags = $this.MergeTags($tags)
            agent_id = $this.AgentId
            service_name = $this.ServiceName
        }
        
        $this.MetricsBuffer.Add($metric)
    }
    
    [void] RecordLog([string]$message, [string]$level = 'INFO', [hashtable]$tags = @{}, [hashtable]$fields = @{}) {
        if (-not $this.IsEnabled) { return }
        
        $log = @{
            timestamp = (Get-Date).ToString('o')
            message = $message
            level = $level
            tags = $this.MergeTags($tags)
            fields = $fields
            agent_id = $this.AgentId
            service_name = $this.ServiceName
        }
        
        $this.LogsBuffer.Add($log)
    }
    
    [void] RecordTrace([string]$operationName, [string]$spanId = '', [string]$parentSpanId = '', [hashtable]$tags = @{}, [hashtable]$events = @{}) {
        if (-not $this.IsEnabled) { return }
        
        $trace = @{
            timestamp = (Get-Date).ToString('o')
            operation_name = $operationName
            span_id = if ($spanId) { $spanId } else { (New-Guid).ToString() }
            parent_span_id = $parentSpanId
            tags = $this.MergeTags($tags)
            events = $events
            agent_id = $this.AgentId
            service_name = $this.ServiceName
        }
        
        $this.TracesBuffer.Add($trace)
    }
    
    [void] Flush([string]$endpoint, [int]$batchSize, [int]$timeoutSeconds, [bool]$enableCompression, [bool]$enableRetry, [int]$maxRetries) {
        if (-not $this.IsEnabled) { return }
        
        $flusher = [TelemetryFlusher]::new($endpoint, $batchSize, $timeoutSeconds, $enableCompression, $enableRetry, $maxRetries)
        
        # Flush metrics
        if ($this.MetricsBuffer.Count -gt 0) {
            $flusher.FlushMetrics($this.MetricsBuffer)
            $this.MetricsBuffer.Clear()
        }
        
        # Flush logs
        if ($this.LogsBuffer.Count -gt 0) {
            $flusher.FlushLogs($this.LogsBuffer)
            $this.LogsBuffer.Clear()
        }
        
        # Flush traces
        if ($this.TracesBuffer.Count -gt 0) {
            $flusher.FlushTraces($this.TracesBuffer)
            $this.TracesBuffer.Clear()
        }
        
        $this.LastFlush = Get-Date
    }
    
    [hashtable] MergeTags([hashtable]$inputTags) {
        $merged = $this.Tags.Clone()
        foreach ($key in $inputTags.Keys) {
            $merged[$key] = $inputTags[$key]
        }
        return $merged
    }
    
    [void] Disable() {
        $this.IsEnabled = $false
    }
    
    [void] Enable() {
        $this.IsEnabled = $true
    }
}

class TelemetryFlusher {
    [string]$Endpoint
    [int]$BatchSize
    [int]$TimeoutSeconds
    [bool]$EnableCompression
    [bool]$EnableRetry
    [int]$MaxRetries
    
    TelemetryFlusher([string]$endpoint, [int]$batchSize, [int]$timeoutSeconds, [bool]$enableCompression, [bool]$enableRetry, [int]$maxRetries) {
        $this.Endpoint = $endpoint
        $this.BatchSize = $batchSize
        $this.TimeoutSeconds = $timeoutSeconds
        $this.EnableCompression = $enableCompression
        $this.EnableRetry = $enableRetry
        $this.MaxRetries = $maxRetries
    }
    
    [void] FlushMetrics([System.Collections.ArrayList]$metrics) {
        $this.FlushTelemetry('metrics', $metrics)
    }
    
    [void] FlushLogs([System.Collections.ArrayList]$logs) {
        $this.FlushTelemetry('logs', $logs)
    }
    
    [void] FlushTraces([System.Collections.ArrayList]$traces) {
        $this.FlushTelemetry('traces', $traces)
    }
    
    [void] FlushTelemetry([string]$type, [System.Collections.ArrayList]$data) {
        if ($data.Count -eq 0) { return }
        
        # Process in batches
        for ($i = 0; $i -lt $data.Count; $i += $this.BatchSize) {
            $batch = $data | Select-Object -Skip $i -First $this.BatchSize
            $this.SendBatch($type, $batch)
        }
    }
    
    [void] SendBatch([string]$type, [object[]]$batch) {
        $payload = @{
            type = $type
            timestamp = (Get-Date).ToString('o')
            batch_size = $batch.Count
            data = $batch
        }
        
        $attempt = 0
        $success = $false
        
        while (-not $success -and $attempt -lt $this.MaxRetries) {
            try {
                $this.SendToSigNoz($payload)
                $success = $true
                Write-Host "[TELEMETRY] Successfully sent $($batch.Count) $type items" -ForegroundColor Green
            } catch {
                $attempt++
                if ($attempt -lt $this.MaxRetries) {
                    $delay = [Math]::Min(1000 * [Math]::Pow(2, $attempt), 10000)  # Exponential backoff
                    Write-Warning "[TELEMETRY] Failed to send $type batch (attempt $attempt/$($this.MaxRetries)): $($_.Exception.Message). Retrying in $delay ms..."
                    Start-Sleep -Milliseconds $delay
                } else {
                    Write-Error "[TELEMETRY] Failed to send $type batch after $attempt attempts: $($_.Exception.Message)"
                }
            }
        }
    }
    
    [void] SendToSigNoz([hashtable]$payload) {
        $jsonPayload = $payload | ConvertTo-Json -Depth 10 -Compress
        
        $headers = @{
            'Content-Type' = 'application/json'
            'User-Agent' = 'Bosscat-Agent-Telemetry/1.0'
        }
        
        if ($this.EnableCompression) {
            $headers['Content-Encoding'] = 'gzip'
            # In a real implementation, you would compress the JSON payload
        }
        
        $uri = switch ($payload.type) {
            'metrics' { $this.Endpoint -replace '/traces', '/metrics' }
            'logs' { $this.Endpoint -replace '/traces', '/logs' }
            'traces' { $this.Endpoint }
        }
        
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $jsonPayload -Headers $headers -TimeoutSec $this.TimeoutSeconds
        
        if ($response -and $response.error) {
            throw "SigNoz API error: $($response.error)"
        }
    }
}

class AgentPerformanceMonitor {
    [AgentTelemetryCollector]$Collector
    [hashtable]$PerformanceCounters
    [datetime]$StartTime
    
    AgentPerformanceMonitor([AgentTelemetryCollector]$collector) {
        $this.Collector = $collector
        $this.PerformanceCounters = @{}
        $this.StartTime = Get-Date
    }
    
    [void] StartOperation([string]$operationName) {
        $this.PerformanceCounters[$operationName] = @{
            StartTime = Get-Date
            EndTime = $null
            Duration = $null
            Success = $false
            ErrorCount = 0
            RetryCount = 0
        }
        
        $this.Collector.RecordTrace($operationName, (New-Guid).ToString(), '', @{
            'operation.type' = 'start'
            'operation.name' = $operationName
        })
    }
    
    [void] EndOperation([string]$operationName, [bool]$success = $true, [string]$errorMessage = '') {
        if (-not $this.PerformanceCounters.ContainsKey($operationName)) {
            $this.PerformanceCounters[$operationName] = @{
                StartTime = Get-Date.AddMinutes(-1)
                EndTime = $null
                Duration = $null
                Success = $false
                ErrorCount = 0
                RetryCount = 0
            }
        }
        
        $counter = $this.PerformanceCounters[$operationName]
        $counter.EndTime = Get-Date
        $counter.Duration = ($counter.EndTime - $counter.StartTime).TotalMilliseconds
        $counter.Success = $success
        
        if (-not $success -and $errorMessage) {
            $counter.ErrorCount++
        }
        
        $this.Collector.RecordTrace($operationName, '', '', @{
            'operation.type' = 'end'
            'operation.name' = $operationName
            'operation.success' = $success.ToString().ToLower()
            'operation.duration_ms' = $counter.Duration
            'operation.error' = $errorMessage
        })
        
        # Record performance metrics
        $this.Collector.RecordMetric("operation_duration_ms", $counter.Duration, @{
            'operation_name' = $operationName
            'success' = $success.ToString().ToLower()
        })
        
        $this.Collector.RecordMetric("operation_count", 1, @{
            'operation_name' = $operationName
            'success' = $success.ToString().ToLower()
        })
    }
    
    [void] RecordError([string]$operationName, [string]$errorMessage, [hashtable]$context = @{}) {
        $this.Collector.RecordLog("Operation failed: $operationName - $errorMessage", 'ERROR', @{
            'operation_name' = $operationName
            'error_type' = 'operation_failure'
        }, $context)
        
        $this.Collector.RecordMetric("operation_errors", 1, @{
            'operation_name' = $operationName
            'error_type' = 'operation_failure'
        })
    }
    
    [void] RecordRetry([string]$operationName, [int]$attempt, [string]$reason = '') {
        $this.Collector.RecordLog("Operation retry: $operationName (attempt $attempt)", 'WARN', @{
            'operation_name' = $operationName
            'retry_attempt' = $attempt
            'retry_reason' = $reason
        })
        
        $this.Collector.RecordMetric("operation_retries", 1, @{
            'operation_name' = $operationName
            'retry_attempt' = $attempt
        })
    }
    
    [void] RecordResourceUsage([hashtable]$usage) {
        foreach ($key in $usage.Keys) {
            $this.Collector.RecordMetric("resource_$key", $usage[$key], @{
                'resource_type' = $key
            })
        }
    }
    
    [hashtable] GetPerformanceSummary() {
        $summary = @{
            TotalOperations = $this.PerformanceCounters.Count
            SuccessfulOperations = 0
            FailedOperations = 0
            TotalDuration = 0
            AverageDuration = 0
            Operations = @()
        }
        
        foreach ($operation in $this.PerformanceCounters.Keys) {
            $counter = $this.PerformanceCounters[$operation]
            $summary.TotalDuration += $counter.Duration
            
            if ($counter.Success) {
                $summary.SuccessfulOperations++
            } else {
                $summary.FailedOperations++
            }
            
            $summary.Operations += @{
                Name = $operation
                Duration = $counter.Duration
                Success = $counter.Success
                ErrorCount = $counter.ErrorCount
                RetryCount = $counter.RetryCount
            }
        }
        
        if ($summary.TotalOperations -gt 0) {
            $summary.AverageDuration = $summary.TotalDuration / $summary.TotalOperations
        }
        
        return $summary
    }
}

# SigNoz Integration Functions
function Initialize-SigNozConnection {
    param([string]$Endpoint)
    
    try {
        # Test connection to SigNoz
        $healthUri = $Endpoint -replace '/v1/traces', '/health'
        $response = Invoke-RestMethod -Uri $healthUri -Method Get -TimeoutSec 5
        
        if ($response -and $response.status -eq 'healthy') {
            Write-Host "[TELEMETRY] SigNoz connection established: $Endpoint" -ForegroundColor Green
            return $true
        } else {
            Write-Warning "[TELEMETRY] SigNoz health check failed: $($response | ConvertTo-Json)"
            return $false
        }
    } catch {
        Write-Warning "[TELEMETRY] Failed to connect to SigNoz: $($_.Exception.Message)"
        return $false
    }
}

function Send-AgentHeartbeat {
    param(
        [AgentTelemetryCollector]$Collector,
        [string]$Status = 'running'
    )
    
    $Collector.RecordMetric("agent_heartbeat", 1, @{
        'agent_status' = $Status
        'timestamp' = (Get-Date).ToString('o')
    })
    
    $Collector.RecordLog("Agent heartbeat", 'INFO', @{
        'agent_status' = $Status
    })
}

function Send-AgentLifecycleEvent {
    param(
        [AgentTelemetryCollector]$Collector,
        [string]$Event,
        [hashtable]$Context = @{}
    )
    
    $Collector.RecordTrace("agent_lifecycle", (New-Guid).ToString(), '', @{
        'lifecycle.event' = $Event
        'lifecycle.timestamp' = (Get-Date).ToString('o')
    }, $Context)
    
    $Collector.RecordLog("Agent lifecycle event: $Event", 'INFO', @{
        'lifecycle_event' = $Event
    }, $Context)
}

# Main execution
try {
    # Initialize SigNoz connection
    if (-not (Initialize-SigNozConnection -Endpoint $TelemetryEndpoint)) {
        Write-Warning "SigNoz connection failed. Telemetry will be logged locally only."
    }
    
    # Initialize telemetry collector
    $baseTags = @{
        'agent.id' = $AgentId
        'service.name' = $ServiceName
        'service.version' = '1.0.0'
        'deployment.environment' = 'development'
        'host.name' = $env:COMPUTERNAME
    }
    
    # Merge custom tags
    foreach ($key in $CustomTags.Keys) {
        $baseTags[$key] = $CustomTags[$key]
    }
    
    $collector = [AgentTelemetryCollector]::new($AgentId, $ServiceName, $baseTags)
    $monitor = [AgentPerformanceMonitor]::new($collector)
    
    # Send agent startup event
    Send-AgentLifecycleEvent -Collector $collector -Event 'startup' -Context @{
        'telemetry.endpoint' = $TelemetryEndpoint
        'telemetry.type' = $TelemetryType
        'telemetry.sampling_rate' = $SamplingRate
    }
    
    # Start heartbeat timer
    $heartbeatTimer = [System.Timers.Timer]::new(60000)  # 1 minute
    $heartbeatTimer.Add_Elapsed({
        Send-AgentHeartbeat -Collector $collector
    })
    $heartbeatTimer.Start()
    
    # Start telemetry flush timer
    $flushTimer = [System.Timers.Timer]::new($BatchTimeoutSeconds * 1000)
    $flushTimer.Add_Elapsed({
        $collector.Flush($TelemetryEndpoint, $BatchSize, $BatchTimeoutSeconds, $EnableCompression, $EnableRetry, $MaxRetries)
    })
    $flushTimer.Start()
    
    Write-Host "`n🎯 Agent Telemetry Integration Active" -ForegroundColor Green
    Write-Host "Agent ID: $AgentId" -ForegroundColor Cyan
    Write-Host "Service: $ServiceName" -ForegroundColor Cyan
    Write-Host "Endpoint: $TelemetryEndpoint" -ForegroundColor Cyan
    Write-Host "Telemetry Type: $TelemetryType" -ForegroundColor Cyan
    Write-Host "Sampling Rate: $SamplingRate" -ForegroundColor Cyan
    Write-Host "Batch Size: $BatchSize" -ForegroundColor Cyan
    
    # Return collector and monitor for use by calling scripts
    return @{
        Collector = $collector
        Monitor = $monitor
        HeartbeatTimer = $heartbeatTimer
        FlushTimer = $flushTimer
    }
    
} catch {
    Write-Error "Agent telemetry integration failed: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}
