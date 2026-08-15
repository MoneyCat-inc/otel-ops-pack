# scripts/agent/synthetic-telemetry.ps1 - Feed guardrail violations into SigNoz/Grafana alerts

param(
    [string]$OtelEndpoint = "",
    [string]$ServiceName = "codex-local",
    [switch]$DryRun,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot '..\lib\OtelPorts.psm1') -Force
if (-not $OtelEndpoint) {
    $OtelEndpoint = "$(Get-OtelIngestHttpBase -HostName 'localhost')/v1/metrics"
}

function Write-TelemetryResult {
    param(
        [string]$Message,
        [bool]$Success = $true
    )
    
    $color = if ($Success) { "Green" } else { "Red" }
    $icon = if ($Success) { "✅" } else { "❌" }
    Write-Host "$icon $Message" -ForegroundColor $color
}

function Get-MetricsData {
    try {
        # Get current guardrail status
        $guardrailsOutput = pnpm agent:guardrails-premium -Json 2>$null
        # Find the JSON part - look for the first { and take everything from there
        $jsonStart = -1
        for ($i = 0; $i -lt $guardrailsOutput.Count; $i++) {
            if ($guardrailsOutput[$i] -match '^\s*\{') {
                $jsonStart = $i
                break
            }
        }
        
        if ($jsonStart -ge 0) {
            $guardrailsClean = ($guardrailsOutput | Select-Object -Skip $jsonStart) -join "`n"
        } else {
            $guardrailsClean = $guardrailsOutput -join "`n"
        }
        # Debug output
        if ($Verbose) {
            Write-Host "DEBUG: Guardrails output length: $($guardrailsOutput.Count)" -ForegroundColor Gray
            Write-Host "DEBUG: Guardrails clean length: $($guardrailsClean.Length)" -ForegroundColor Gray
        }
        $guardrails = $guardrailsClean | ConvertFrom-Json
        
        $statusOutput = pnpm agent:status-premium -Json 2>$null
        # Find the JSON part - look for the first { and take everything from there
        $jsonStart = -1
        for ($i = 0; $i -lt $statusOutput.Count; $i++) {
            if ($statusOutput[$i] -match '^\s*\{') {
                $jsonStart = $i
                break
            }
        }
        
        if ($jsonStart -ge 0) {
            $statusClean = ($statusOutput | Select-Object -Skip $jsonStart) -join "`n"
        } else {
            $statusClean = $statusOutput -join "`n"
        }
        
        # Debug output
        if ($Verbose) {
            Write-Host "DEBUG: Status output length: $($statusOutput.Count)" -ForegroundColor Gray
            Write-Host "DEBUG: Status clean length: $($statusClean.Length)" -ForegroundColor Gray
        }
        $status = $statusClean | ConvertFrom-Json
        
        return @{
            timestamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
            violations = $guardrails.violations
            filesProcessed = $guardrails.filesProcessed
            filesModified = $guardrails.filesModified
            linesChanged = $guardrails.linesChanged
            agentStatus = if ($status.lock) { 0 } elseif ($status.status -eq "active") { 1 } else { -1 }
            queueTotal = $status.queue.total
            queueQueued = $status.queue.queued
            queueCompleted = $status.queue.completed
            queueFailed = $status.queue.failed
            ema = $status.ema
            success = $true
        }
    } catch {
        return @{
            timestamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
            violations = -1
            filesProcessed = 0
            filesModified = 0
            linesChanged = 0
            agentStatus = -1
            queueTotal = 0
            queueQueued = 0
            queueCompleted = 0
            queueFailed = 0
            ema = @{}
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Create-OtelMetrics {
    param([hashtable]$MetricsData)
    
    $timestamp = $MetricsData.timestamp
    
    $metrics = @{
        resourceMetrics = @(
            @{
                resource = @{
                    attributes = @(
                        @{
                            key = "service.name"
                            value = @{
                                stringValue = $ServiceName
                            }
                        },
                        @{
                            key = "service.version"
                            value = @{
                                stringValue = "1.0.0"
                            }
                        }
                    )
                }
                scopeMetrics = @(
                    @{
                        scope = @{
                            name = "codex-local"
                            version = "1.0.0"
                        }
                        metrics = @(
                            # Guardrail violations counter
                            @{
                                name = "codex.guardrail.violations"
                                description = "Total number of guardrail violations found"
                                unit = "1"
                                sum = @{
                                    dataPoints = @(
                                        @{
                                            attributes = @(
                                                @{
                                                    key = "severity"
                                                    value = @{
                                                        stringValue = if ($MetricsData.violations -eq 0) { "none" } elseif ($MetricsData.violations -lt 5) { "low" } elseif ($MetricsData.violations -lt 10) { "medium" } else { "high" }
                                                    }
                                                }
                                            )
                                            startTimeUnixNano = $timestamp * 1000000
                                            timeUnixNano = $timestamp * 1000000
                                            asInt = $MetricsData.violations
                                        }
                                    )
                                    aggregationTemporality = 2  # CUMULATIVE
                                    isMonotonic = $true
                                }
                            },
                            # Agent status gauge
                            @{
                                name = "codex.agent.status"
                                description = "Agent status (1=active, 0=locked, -1=error)"
                                unit = "1"
                                gauge = @{
                                    dataPoints = @(
                                        @{
                                            timeUnixNano = $timestamp * 1000000
                                            asInt = $MetricsData.agentStatus
                                        }
                                    )
                                }
                            },
                            # Queue metrics
                            @{
                                name = "codex.queue.total"
                                description = "Total number of tasks in queue"
                                unit = "1"
                                gauge = @{
                                    dataPoints = @(
                                        @{
                                            timeUnixNano = $timestamp * 1000000
                                            asInt = $MetricsData.queueTotal
                                        }
                                    )
                                }
                            },
                            @{
                                name = "codex.queue.queued"
                                description = "Number of queued tasks"
                                unit = "1"
                                gauge = @{
                                    dataPoints = @(
                                        @{
                                            timeUnixNano = $timestamp * 1000000
                                            asInt = $MetricsData.queueQueued
                                        }
                                    )
                                }
                            },
                            @{
                                name = "codex.queue.failed"
                                description = "Number of failed tasks"
                                unit = "1"
                                gauge = @{
                                    dataPoints = @(
                                        @{
                                            timeUnixNano = $timestamp * 1000000
                                            asInt = $MetricsData.queueFailed
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
    
    # Add EMA metrics if available
    if ($MetricsData.ema.Count -gt 0) {
        foreach ($emaKey in $MetricsData.ema.Keys) {
            $emaValue = $MetricsData.ema[$emaKey]
            $metricName = "codex.ema.$emaKey"
            
            $emaMetric = @{
                name = $metricName
                description = "EMA value for $emaKey"
                unit = "s"
                gauge = @{
                    dataPoints = @(
                        @{
                            timeUnixNano = $timestamp * 1000000
                            asDouble = $emaValue
                        }
                    )
                }
            }
            
            $metrics.resourceMetrics[0].scopeMetrics[0].metrics += $emaMetric
        }
    }
    
    return $metrics
}

function Send-Metrics {
    param([hashtable]$MetricsData, [string]$Endpoint)
    
    try {
        $metrics = Create-OtelMetrics -MetricsData $MetricsData
        $jsonBody = $metrics | ConvertTo-Json -Depth 10
        
        if ($Verbose) {
            Write-Host "📡 Sending metrics to $Endpoint" -ForegroundColor Yellow
            Write-Host "📊 Metrics payload size: $($jsonBody.Length) bytes" -ForegroundColor Gray
        }
        
        $headers = @{
            "Content-Type" = "application/json"
            "User-Agent" = "codex-local/1.0.0"
        }
        
        $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Body $jsonBody -Headers $headers -TimeoutSec 30
        
        return @{
            success = $true
            response = $response
            payloadSize = $jsonBody.Length
        }
    } catch {
        return @{
            success = $false
            error = $_.Exception.Message
            payloadSize = 0
        }
    }
}

function Create-AlertRules {
    param([string]$OutputPath)
    
    $alertRules = @{
        groups = @(
            @{
                name = "codex-local"
                rules = @(
                    @{
                        alert = "CodexLocalHighViolations"
                        expr = "increase(codex_guardrail_violations_total[1h]) > 10"
                        for = "5m"
                        labels = @{
                            severity = "warning"
                            service = "codex-local"
                        }
                        annotations = @{
                            summary = "High number of guardrail violations detected"
                            description = "Codex-local has detected {{ $value }} violations in the last hour"
                        }
                    },
                    @{
                        alert = "CodexLocalAgentDown"
                        expr = "codex_agent_status != 1"
                        for = "2m"
                        labels = @{
                            severity = "critical"
                            service = "codex-local"
                        }
                        annotations = @{
                            summary = "Codex-local agent is down or locked"
                            description = "Agent status is {{ $value }} (1=active, 0=locked, -1=error)"
                        }
                    },
                    @{
                        alert = "CodexLocalQueueBacklog"
                        expr = "codex_queue_queued > 50"
                        for = "10m"
                        labels = @{
                            severity = "warning"
                            service = "codex-local"
                        }
                        annotations = @{
                            summary = "Codex-local task queue backlog"
                            description = "Queue has {{ $value }} tasks waiting to be processed"
                        }
                    },
                    @{
                        alert = "CodexLocalHighFailureRate"
                        expr = "codex_queue_failed / codex_queue_total > 0.1"
                        for = "5m"
                        labels = @{
                            severity = "warning"
                            service = "codex-local"
                        }
                        annotations = @{
                            summary = "High task failure rate in codex-local"
                            description = "{{ $value | humanizePercentage }} of tasks are failing"
                        }
                    }
                )
            }
        )
    }
    
    $alertRules | ConvertTo-Json -Depth 10 | Set-Content $OutputPath -Encoding UTF8
    Write-TelemetryResult -Message "Alert rules generated: $OutputPath" -Success $true
}

Write-Host "📡 codex-local Synthetic Telemetry" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Get metrics data
Write-Host "`n📊 Collecting metrics data..." -ForegroundColor Yellow
$metricsData = Get-MetricsData

if (-not $metricsData.success) {
    Write-TelemetryResult -Message "Failed to collect metrics: $($metricsData.error)" -Success $false
    exit 1
}

Write-Host "`n📈 Metrics Summary:" -ForegroundColor White
Write-Host "   Violations: $($metricsData.violations)" -ForegroundColor $(if ($metricsData.violations -eq 0) { "Green" } else { "Yellow" })
Write-Host "   Agent Status: $($metricsData.agentStatus)" -ForegroundColor $(if ($metricsData.agentStatus -eq 1) { "Green" } else { "Red" })
Write-Host "   Queue: $($metricsData.queueTotal) total, $($metricsData.queueQueued) queued" -ForegroundColor White
Write-Host "   EMA Metrics: $($metricsData.ema.Count) available" -ForegroundColor Gray

# Send metrics
if (-not $DryRun) {
    Write-Host "`n📡 Sending metrics to OTel endpoint..." -ForegroundColor Yellow
    $sendResult = Send-Metrics -MetricsData $metricsData -Endpoint $OtelEndpoint
    
    if ($sendResult.success) {
        Write-TelemetryResult -Message "Metrics sent successfully (${sendResult.payloadSize} bytes)" -Success $true
    } else {
        Write-TelemetryResult -Message "Failed to send metrics: $($sendResult.error)" -Success $false
    }
} else {
    Write-TelemetryResult -Message "Dry run - metrics not sent" -Success $true
}

# Generate alert rules
Write-Host "`n🚨 Generating alert rules..." -ForegroundColor Yellow
$alertRulesPath = ".agent/alert-rules.json"
Create-AlertRules -OutputPath $alertRulesPath

# Log telemetry event
$logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Synthetic telemetry: Violations=$($metricsData.violations), Status=$($metricsData.agentStatus), Queue=$($metricsData.queueTotal)"
Add-Content -Path "TASKS.md" -Value $logEntry

Write-Host "`n🎯 Telemetry Summary:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "Endpoint: $OtelEndpoint" -ForegroundColor Gray
Write-Host "Service: $ServiceName" -ForegroundColor Gray
Write-Host "Dry Run: $DryRun" -ForegroundColor Gray
Write-Host "Alert Rules: $alertRulesPath" -ForegroundColor Gray

Write-TelemetryResult -Message "Synthetic telemetry completed" -Success $true
