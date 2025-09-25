<#
ECRR-Enhanced Canary Script
---------------------------
Implements Examine -> Clean -> Report -> Role cadence for canary testing.
Usage: pwsh -File scripts/canary-ecrr.ps1
Creates artifacts/canary-ecrr-report.txt with execution details.
#>

param(
    [switch]$DryRun,
    [switch]$Verbose
)

$issues = @()
$warnings = @()
$report = @()

function Add-ReportLine {
    param(
        [string]$Level,
        [string]$Message,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::Gray
    )

    $line = "[$Level] $Message"
    $script:report += $line
    Write-Host $line -ForegroundColor $Color
}

function Test-Port {
    param([int]$Port)
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $async = $client.BeginConnect('localhost', $Port, $null, $null)
        $completed = $async.AsyncWaitHandle.WaitOne(500)
        if (-not $completed) {
            $client.Close()
            return $false
        }
        $client.EndConnect($async)
        $client.Close()
        return $true
    } catch {
        return $false
    }
}

Add-ReportLine -Level 'INFO' -Message 'ECRR-Enhanced Canary Test - Examine -> Clean -> Report -> Role' -Color Cyan
Add-ReportLine -Level 'INFO' -Message ('Timestamp: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Color Cyan
Add-ReportLine -Level 'INFO' -Message ('Working directory: ' + (Get-Location))

# EXAMINE PHASE
Add-ReportLine -Level 'SECTION' -Message 'EXAMINE: Environment State' -Color Yellow

# Check SigNoz UI
try {
    $uiResponse = Invoke-WebRequest -Uri 'http://localhost:8080' -UseBasicParsing -TimeoutSec 3
    Add-ReportLine -Level 'OK' -Message 'SigNoz UI accessible at http://localhost:8080' -Color Green
} catch {
    $issues += 'SigNoz UI not accessible'
    Add-ReportLine -Level 'FAIL' -Message 'SigNoz UI not accessible at http://localhost:8080' -Color Red
}

# Check OTel Collector service
try {
    $service = Get-Service -Name 'otelcol-contrib' -ErrorAction Stop
    Add-ReportLine -Level 'OK' -Message ("OTel Collector service: " + $service.Status) -Color Green
    if ($service.Status -ne 'Running') {
        $issues += 'OTel Collector service not running'
    }
} catch {
    $issues += 'OTel Collector service not found'
    Add-ReportLine -Level 'FAIL' -Message 'OTel Collector service not found' -Color Red
}

# Check OTLP endpoints (Docker mapped ports)
$otlpPorts = @(14317, 14318)
foreach ($port in $otlpPorts) {
    if (Test-Port -Port $port) {
        Add-ReportLine -Level 'OK' -Message ("OTLP endpoint $port accessible") -Color Green
    } else {
        $warnings += "OTLP endpoint $port not reachable"
        Add-ReportLine -Level 'WARN' -Message ("OTLP endpoint $port not reachable") -Color Yellow
    }
}

# Check scheduled tasks
$canaryTasks = Get-ScheduledTask -TaskName "*OTel*" -ErrorAction SilentlyContinue
if ($canaryTasks) {
    Add-ReportLine -Level 'OK' -Message ("Found $($canaryTasks.Count) OTel scheduled tasks") -Color Green
    foreach ($task in $canaryTasks) {
        Add-ReportLine -Level 'INFO' -Message ("  - $($task.TaskName): $($task.State)") -Color Gray
    }
} else {
    $warnings += 'No OTel scheduled tasks found'
    Add-ReportLine -Level 'WARN' -Message 'No OTel scheduled tasks found' -Color Yellow
}

# CLEAN PHASE
Add-ReportLine -Level 'SECTION' -Message 'CLEAN: Address Drift' -Color Yellow

# Clean up old log files if they're getting too large
$logDir = 'C:\logs'
if (Test-Path $logDir) {
    $logFiles = Get-ChildItem -Path $logDir -Filter "*.log" | Where-Object { $_.Length -gt 10MB }
    if ($logFiles) {
        Add-ReportLine -Level 'WARN' -Message ("Found $($logFiles.Count) large log files (>10MB), consider rotation") -Color Yellow
    } else {
        Add-ReportLine -Level 'OK' -Message 'Log file sizes are reasonable' -Color Green
    }
} else {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Add-ReportLine -Level 'OK' -Message 'Created C:\logs directory' -Color Green
}

# REPORT PHASE - Execute Canary Test
Add-ReportLine -Level 'SECTION' -Message 'REPORT: Execute Canary Test' -Color Yellow

if (-not $DryRun) {
    # Run the actual canary test
    try {
        Add-ReportLine -Level 'INFO' -Message 'Executing canary test...'
        
        # Create canary log entry (single-line JSON)
        $canaryMessage = "ECRR-Canary-Test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        $logFile = Join-Path $logDir 'ecrr-canary-test.log'
        $logObj = [ordered]@{
            timestamp = (Get-Date).ToUniversalTime().ToString('o')
            message   = $canaryMessage
            category  = 'ecrr-canary'
            level     = 'INFO'
        }
        $logEntry = ($logObj | ConvertTo-Json -Compress)
        Add-Content -Path $logFile -Value $logEntry -Encoding utf8
        Add-ReportLine -Level 'OK' -Message "Created canary log entry: $canaryMessage" -Color Green
        
        # Ensure Windows Event Log source, then write entry
        if (-not [System.Diagnostics.EventLog]::SourceExists('SigNoz-Canary')) {
            try { New-EventLog -LogName Application -Source 'SigNoz-Canary' -ErrorAction Stop } catch {}
        }
        Write-EventLog -LogName Application -Source 'SigNoz-Canary' -EventId 1001 -Message $canaryMessage -EntryType Information
        Add-ReportLine -Level 'OK' -Message 'Created Windows Event Log entry' -Color Green
        
        # Send OTLP trace and log
        $otlpPayload = @{
            resourceLogs = @(
                @{
                    resource = @{
                        attributes = @(
                            @{ key = "service.name"; value = @{ stringValue = "ecrr-canary" } }
                        )
                    }
                    scopeLogs = @(
                        @{
                            logRecords = @(
                                @{
                                    body = @{ stringValue = $canaryMessage }
                                    severityText = "INFO"
                                    observedTimeUnixNano = [long]((Get-Date).ToUniversalTime() - [datetime]"1970-01-01").TotalMilliseconds * 1000000
                                    attributes = @(
                                        @{ key = "canary.type"; value = @{ stringValue = "ecrr-enhanced" } }
                                        @{ key = "test.framework"; value = @{ stringValue = "examine-clean-report-role" } }
                                    )
                                }
                            )
                        }
                    )
                }
            )
        }
        
        $jsonPayload = $otlpPayload | ConvertTo-Json -Depth 10
        $headers = @{ 'Content-Type' = 'application/json' }
        
        try {
            $response = Invoke-RestMethod -Uri 'http://localhost:14318/v1/logs' -Method Post -Body $jsonPayload -Headers $headers -TimeoutSec 5
            Add-ReportLine -Level 'OK' -Message 'Sent OTLP log to collector' -Color Green
        } catch {
            $warnings += 'Failed to send OTLP log'
            Add-ReportLine -Level 'WARN' -Message 'Failed to send OTLP log to collector' -Color Yellow
        }
        
    } catch {
        $issues += 'Canary test execution failed'
        Add-ReportLine -Level 'FAIL' -Message "Canary test execution failed: $($_.Exception.Message)" -Color Red
    }
} else {
    Add-ReportLine -Level 'INFO' -Message 'DRY RUN: Would execute canary test' -Color Cyan
}

# ROLE PHASE
Add-ReportLine -Level 'SECTION' -Message 'ROLE: Agent Responsibilities' -Color Yellow
Add-ReportLine -Level 'INFO' -Message 'Role: Observability Copilot - ECRR Canary Automation' -Color Cyan
Add-ReportLine -Level 'INFO' -Message 'Responsibilities: Examine environment, clean drift, report canary execution, document role' -Color Cyan
Add-ReportLine -Level 'INFO' -Message 'Artifacts: This report, canary logs, OTLP traces, Windows Event Log entries' -Color Cyan

# Summary
Add-ReportLine -Level 'SECTION' -Message 'Summary' -Color Yellow
if ($issues.Count -eq 0) {
    Add-ReportLine -Level 'OK' -Message 'ECRR Canary Test completed successfully' -Color Green
} else {
    foreach ($issue in $issues) {
        Add-ReportLine -Level 'FAIL' -Message $issue -Color Red
    }
}

if ($warnings.Count -gt 0) {
    foreach ($warning in $warnings) {
        Add-ReportLine -Level 'WARN' -Message $warning -Color Yellow
    }
}

# Persist artifact
$artifactDir = 'artifacts'
if (-not (Test-Path $artifactDir)) {
    New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
}
$artifactPath = Join-Path $artifactDir 'canary-ecrr-report.txt'
$report | Set-Content -Path $artifactPath
Add-ReportLine -Level 'INFO' -Message ('Report written to ' + (Resolve-Path $artifactPath)) -Color Cyan

# Verification instructions
Add-ReportLine -Level 'SECTION' -Message 'Verification Steps' -Color Yellow
Add-ReportLine -Level 'NOTE' -Message '1. Check SigNoz UI -> Logs -> filter: message contains "ECRR-Canary-Test"'
Add-ReportLine -Level 'NOTE' -Message '2. Verify canary log file: C:\logs\ecrr-canary-test.log'
Add-ReportLine -Level 'NOTE' -Message '3. Check Windows Event Viewer -> Application -> Source "SigNoz-Canary"'

if ($issues.Count -gt 0) {
    exit 1
} else {
    exit 0
}


