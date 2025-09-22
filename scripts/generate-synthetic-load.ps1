#Requires -Version 7.0

<#
.SYNOPSIS
    Synthetic load generator for OTel Collector DOE experiments

.DESCRIPTION
    Generates controlled load patterns (baseline, spike, sustained) to test
    collector performance under various conditions.

.PARAMETER Duration
    Total experiment duration in seconds. Default: 300

.PARAMETER OTLPEndpoint
    OTLP HTTP endpoint URL. Default: http://localhost:5318

.PARAMETER RunId
    Unique run identifier for experiment tracking

.PARAMETER Stage
    Experiment stage (stage1, stage2). Default: stage1

.PARAMETER LoadPattern
    Load pattern: baseline, spike, sustained, mixed. Default: mixed

.EXAMPLE
    .\generate-synthetic-load.ps1 -Duration 600 -RunId test-run-001 -Stage stage1
    Generate mixed load pattern for 10 minutes
#>

param(
    [int]$Duration = 300,
    [string]$OTLPEndpoint = "http://localhost:5318",
    [string]$RunId = "synthetic-load",
    [string]$Stage = "stage1",
    [string]$LoadPattern = "mixed"
)

# Initialize script
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "Synthetic Load Generator" -ForegroundColor Green
Write-Host "Run ID: $RunId" -ForegroundColor Cyan
Write-Host "Duration: $Duration seconds" -ForegroundColor Cyan
Write-Host "Endpoint: $OTLPEndpoint" -ForegroundColor Cyan
Write-Host "Pattern: $LoadPattern" -ForegroundColor Cyan

# OTLP Log Record Template
$logTemplate = @{
    resourceLogs = @(
        @{
            resource = @{
                attributes = @(
                    @{
                        key = "service.name"
                        value = @{
                            stringValue = "synthetic-load-generator"
                        }
                    },
                    @{
                        key = "run.id"
                        value = @{
                            stringValue = $RunId
                        }
                    },
                    @{
                        key = "run.stage"
                        value = @{
                            stringValue = $Stage
                        }
                    }
                )
            }
            scopeLogs = @(
                @{
                    scope = @{
                        name = "synthetic-load-generator"
                        version = "1.0.0"
                    }
                    logRecords = @(
                        @{
                            timeUnixNano = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
                            severityNumber = 9
                            severityText = "INFO"
                            body = @{
                                stringValue = "Synthetic log message for DOE experiment"
                            }
                            attributes = @(
                                @{
                                    key = "log.source"
                                    value = @{
                                        stringValue = "synthetic"
                                    }
                                },
                                @{
                                    key = "experiment.phase"
                                    value = @{
                                        stringValue = "baseline"
                                    }
                                }
                            )
                        }
                    )
                }
            )
        }
    )
}

# Convert to JSON
$logPayload = $logTemplate | ConvertTo-Json -Depth 10 -Compress

# Send OTLP logs via HTTP
function Send-OTLPLogs {
    param(
        [string]$Endpoint,
        [string]$Payload,
        [int]$Count,
        [string]$Phase = "baseline"
    )
    
    try {
        # Update phase in payload
        $payloadObj = $Payload | ConvertFrom-Json
        $payloadObj.resourceLogs[0].scopeLogs[0].logRecords[0].attributes[1].value.stringValue = $Phase
        $payloadObj.resourceLogs[0].scopeLogs[0].logRecords[0].timeUnixNano = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
        $updatedPayload = $payloadObj | ConvertTo-Json -Depth 10 -Compress
        
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        for ($i = 0; $i -lt $Count; $i++) {
            Invoke-RestMethod -Uri "$Endpoint/v1/logs" -Method Post -Body $updatedPayload -Headers $headers -TimeoutSec 10 -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 1
        }
        
        Write-Host "Sent $Count logs in $Phase phase" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to send logs: $($_.Exception.Message)"
    }
}

# Load patterns
$patterns = @{
    baseline = @{
        eps = 100
        duration = $Duration
        description = "Steady baseline load"
    }
    spike = @{
        eps = 1000
        duration = 30
        description = "High-intensity spike load"
    }
    sustained = @{
        eps = 500
        duration = 60
        description = "Sustained moderate load"
    }
    mixed = @{
        phases = @(
            @{ eps = 100; duration = 60; phase = "warmup" },
            @{ eps = 1000; duration = 30; phase = "spike" },
            @{ eps = 200; duration = 60; phase = "recovery" },
            @{ eps = 500; duration = 90; phase = "sustained" },
            @{ eps = 100; duration = 60; phase = "cooldown" }
        )
        description = "Mixed load pattern with spikes and recovery"
    }
}

Write-Host "Starting load generation..." -ForegroundColor Yellow

$startTime = Get-Date
$endTime = $startTime.AddSeconds($Duration)

if ($LoadPattern -eq "mixed") {
    $currentPhase = 0
    $phaseStartTime = $startTime
    
    while ((Get-Date) -lt $endTime -and $currentPhase -lt $patterns.mixed.phases.Count) {
        $phase = $patterns.mixed.phases[$currentPhase]
        $phaseEndTime = $phaseStartTime.AddSeconds($phase.duration)
        
        Write-Host "Phase $($currentPhase + 1): $($phase.phase) - $($phase.eps) eps for $($phase.duration)s" -ForegroundColor Cyan
        
        while ((Get-Date) -lt $phaseEndTime -and (Get-Date) -lt $endTime) {
            Send-OTLPLogs -Endpoint $OTLPEndpoint -Payload $logPayload -Count $phase.eps -Phase $phase.phase
            Start-Sleep -Seconds 1
        }
        
        $currentPhase++
        $phaseStartTime = $phaseEndTime
    }
} else {
    $pattern = $patterns[$LoadPattern]
    Write-Host "Pattern: $($pattern.description)" -ForegroundColor Cyan
    
    while ((Get-Date) -lt $endTime) {
        Send-OTLPLogs -Endpoint $OTLPEndpoint -Payload $logPayload -Count $pattern.eps -Phase $LoadPattern
        Start-Sleep -Seconds 1
    }
}

$elapsed = (Get-Date) - $startTime
Write-Host "Load generation completed in $($elapsed.TotalSeconds.ToString('F1')) seconds" -ForegroundColor Green

# Generate summary
$summary = @{
    runId = $RunId
    stage = $Stage
    pattern = $LoadPattern
    duration = $Duration
    actualDuration = $elapsed.TotalSeconds
    endpoint = $OTLPEndpoint
    completedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
}

$summary | ConvertTo-Json | Write-Host

Write-Host "Load generation summary saved to console output" -ForegroundColor Yellow
