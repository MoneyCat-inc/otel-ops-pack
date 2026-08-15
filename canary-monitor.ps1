param(
    [int]$CheckIntervalSeconds = 300,
    [string]$TaskQueuePath = ".agent\\task_queue\\pending",
    [switch]$RunOnce
)

Import-Module (Join-Path $PSScriptRoot 'BRAV\SCPT\lib\OtelPorts.psm1') -Force
$script:OtelPorts = Get-OtelPorts

Write-Host "== Starting Canary Monitoring ==" -ForegroundColor Cyan

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Invoke-OtlpRequest {
    param(
        [string]$Path,
        [string]$Body
    )

    $endpoints = @(
        "$(Get-OtelIngestHttpBase -HostName 'localhost' -Ports $script:OtelPorts)/$Path",
        "http://localhost:$($script:OtelPorts.SignozOtlpHttp)/$Path"
    )

    $lastError = $null
    foreach ($endpoint in $endpoints) {
        try {
            Invoke-RestMethod -Method Post -Uri $endpoint -ContentType "application/json" -Body $Body -TimeoutSec 5 | Out-Null
            return $endpoint
        } catch {
            $lastError = $_
        }
    }

    if ($lastError) {
        throw $lastError
    }
}

function New-TaskFile {
    param(
        [string]$Type,
        [string]$Priority,
        [string]$Title,
        [string]$Description,
        [hashtable]$Metrics,
        [string]$Recipe
    )

    Ensure-Directory $TaskQueuePath

    $taskId = "canary-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
    $taskFile = Join-Path $TaskQueuePath "$taskId.json"

    $task = @{
        id = $taskId
        type = $Type
        priority = $Priority
        created_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        source = "canary"
        title = $Title
        description = $Description
        metrics = $Metrics
        recipe = $Recipe
        status = "pending"
        assigned_to = "codex"
        validation_commands = @(
            "powershell -ExecutionPolicy Bypass -File operator-pipeline-check.ps1",
            "powershell -ExecutionPolicy Bypass -File scripts/verify-integration.ps1"
        )
        expected_output = "Collector healthy, canary test passes, signals flowing to SigNoz"
        rollback_commands = @(
            "copy config.backup.yaml config.yaml",
            "sc stop otelcol-contrib",
            "sc start otelcol-contrib"
        )
    } | ConvertTo-Json -Depth 10

    $task | Out-File -FilePath $taskFile -Encoding ascii
    Write-Host "[TASK] Created task: $taskFile" -ForegroundColor Yellow
    return $taskFile
}

function Test-CanaryHealth {
    $issues = @()

    # SigNoz UI health
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 10
        if ($response.status -ne "ok") {
            $issues += "SigNoz UI status: $($response.status)"
        }
    } catch {
        $issues += "SigNoz UI unreachable: $($_.Exception.Message)"
    }

    # Collector health
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -Method Get -TimeoutSec 10
        if (@("Serving", "Server available") -notcontains $response.status) {
            $issues += "Collector health: $($response.status)"
        }
    } catch {
        $issues += "Collector health endpoint unreachable: $($_.Exception.Message)"
    }

    # Canary log freshness
    $logFile = "C:\\logs\\canary-test.log"
    if (Test-Path $logFile) {
        $lastWrite = (Get-Item $logFile).LastWriteTime
        $ageMinutes = ((Get-Date) - $lastWrite).TotalMinutes
        if ($ageMinutes -gt 10) {
            $issues += "Canary log file stale: $([math]::Round($ageMinutes, 1)) minutes old"
        }
    } else {
        $issues += "Canary log file missing"
    }

    # Collector metrics coverage
    try {
        $metricsResponse = Invoke-WebRequest -Uri "http://localhost:8888/metrics" -TimeoutSec 10
        $otelLines = $metricsResponse.Content -split "`n" | Where-Object { $_ -match "otelcol_" }
        if ($otelLines.Count -lt 10) {
            $issues += "Collector metrics count low: $($otelLines.Count)"
        }
    } catch {
        $issues += "Collector metrics unreachable: $($_.Exception.Message)"
    }

    return $issues
}

function Test-CanaryDataFlow {
    $logDir = "C:\\logs"
    Ensure-Directory $logDir

    $logFile = Join-Path $logDir "canary-test.log"
    $logEntry = @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        level = "INFO"
        message = "Canary monitor heartbeat - $(Get-Date -Format o)"
        service = "canary-monitor"
        canary = "true"
        monitor_run = $true
    } | ConvertTo-Json -Compress

    try {
        Add-Content -Path $logFile -Value $logEntry
    } catch {
        return [PSCustomObject]@{ Success = $false; Endpoint = $null; Error = "Failed writing canary log: $($_.Exception.Message)" }
    }

    $payload = @{
        resourceLogs = @(
            @{
                resource = @{
                    attributes = @(
                        @{ key = "service.name"; value = @{ stringValue = "canary-monitor" } },
                        @{ key = "canary"; value = @{ stringValue = "true" } }
                    )
                }
                scopeLogs = @(
                    @{
                        logRecords = @(
                            @{
                                timeUnixNano = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
                                severityNumber = 9
                                severityText = "INFO"
                                body = @{ stringValue = "Canary monitor heartbeat" }
                                attributes = @(
                                    @{ key = "source"; value = @{ stringValue = "canary-monitor.ps1" } }
                                )
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    try {
        $endpoint = Invoke-OtlpRequest -Path "v1/logs" -Body $payload
        return [PSCustomObject]@{ Success = $true; Endpoint = $endpoint; Error = $null }
    } catch {
        return [PSCustomObject]@{ Success = $false; Endpoint = $null; Error = $_.Exception.Message }
    }
}

Do {
    Write-Host "-- Canary health check at $(Get-Date -Format o) --" -ForegroundColor Cyan

    $healthIssues = Test-CanaryHealth
    $dataFlow = Test-CanaryDataFlow

    if ($healthIssues.Count -gt 0) {
        Write-Host "[WARN] Health issues detected:" -ForegroundColor Red
        $healthIssues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }

        $metrics = @{
            health_issues = $healthIssues.Count
            data_flow_ok = $dataFlow.Success
            timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        }

        New-TaskFile -Type "alert" -Priority "high" -Title "Canary Health Issues" -Description "Observability canary detected health problems" -Metrics $metrics -Recipe "otlp_exporter_failure" | Out-Null
    }

    if (-not $dataFlow.Success) {
        Write-Host "[WARN] Canary data flow failed: $($dataFlow.Error)" -ForegroundColor Red

        $metrics = @{
            data_flow_ok = $false
            health_issues = $healthIssues.Count
            timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        }

        New-TaskFile -Type "alert" -Priority "critical" -Title "Canary Data Flow Failure" -Description "Canary data did not reach SigNoz" -Metrics $metrics -Recipe "otlp_exporter_failure" | Out-Null
    }

    if ($healthIssues.Count -eq 0 -and $dataFlow.Success) {
        Write-Host "[OK] Canary health check passed (OTLP endpoint: $($dataFlow.Endpoint))" -ForegroundColor Green
    }

    if (-not $RunOnce) {
        Write-Host "Sleeping $CheckIntervalSeconds seconds before next run..." -ForegroundColor Gray
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
} while (-not $RunOnce)





