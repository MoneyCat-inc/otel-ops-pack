# See C:\otel\docs\comfort cat
# AutoBot: Service Guardian
# Monitors Windows Collector service and auto-recovers if stopped/disabled
# Tracks service state changes and generates ECRR audit logs

param(
    [int]$CheckIntervalSeconds = 60,
    [switch]$DryRun = $false,
    [switch]$Daemon = $false,
    [string]$LogPath = "artifacts\autobot-guardian-$(Get-Date -Format 'yyyyMMdd').log"
)

$ErrorActionPreference = "Continue"

# Ensure artifacts directory exists
$null = New-Item -ItemType Directory -Force -Path "artifacts"

function Write-GuardianLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $entry = "[$timestamp] [$Level] $Message"
    Write-Host $entry
    Add-Content -Path $LogPath -Value $entry
}

function Get-ServiceState {
    try {
        $service = Get-Service -Name "otelcol-contrib" -ErrorAction Stop
        $config = sc.exe qc otelcol-contrib | Out-String
        
        $startType = if ($config -match "START_TYPE\s+:\s+\d+\s+(\w+)") { $matches[1] } else { "UNKNOWN" }
        
        return @{
            Status = $service.Status
            StartType = $startType
            Name = $service.Name
            DisplayName = $service.DisplayName
            Success = $true
        }
    }
    catch {
        Write-GuardianLog "Failed to query service: $($_.Exception.Message)" "ERROR"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Get-ServiceChanges {
    # Check Windows Event Log for recent service changes
    try {
        $events = Get-EventLog -LogName System -Source "Service Control Manager" -Newest 50 -ErrorAction SilentlyContinue |
            Where-Object { $_.Message -match "otelcol|OpenTelemetry" } |
            Select-Object -First 5
        
        return $events
    }
    catch {
        return @()
    }
}

function Invoke-ServiceRecovery {
    param($CurrentState, $Issue)
    
    Write-GuardianLog "🚨 RECOVERY INITIATED: $Issue" "WARN"
    
    if ($DryRun) {
        Write-GuardianLog "DRY RUN: Would fix - $Issue" "INFO"
        return @{ Action = "DRY_RUN"; Success = $true }
    }
    
    $actions = @()
    
    # Fix 1: Ensure AUTO startup
    if ($CurrentState.StartType -ne "AUTO_START") {
        Write-GuardianLog "Setting service to AUTO start..." "INFO"
        $result = sc.exe config otelcol-contrib start= auto 2>&1
        if ($LASTEXITCODE -eq 0) {
            $actions += "SET_AUTO_START"
            Write-GuardianLog "✅ Service configured for AUTO start" "INFO"
        }
        else {
            Write-GuardianLog "❌ Failed to set AUTO start: $result" "ERROR"
            return @{ Action = "SET_AUTO_START_FAILED"; Success = $false; Error = $result }
        }
    }
    
    # Fix 2: Start service if stopped
    if ($CurrentState.Status -ne "Running") {
        Write-GuardianLog "Starting service..." "INFO"
        $result = sc.exe start otelcol-contrib 2>&1
        if ($LASTEXITCODE -eq 0) {
            Start-Sleep -Seconds 2
            $newState = Get-ServiceState
            if ($newState.Status -eq "Running") {
                $actions += "SERVICE_STARTED"
                Write-GuardianLog "✅ Service started successfully" "INFO"
            }
            else {
                Write-GuardianLog "❌ Service started but not running: $($newState.Status)" "ERROR"
                return @{ Action = "START_VERIFY_FAILED"; Success = $false }
            }
        }
        else {
            Write-GuardianLog "❌ Failed to start service: $result" "ERROR"
            return @{ Action = "START_FAILED"; Success = $false; Error = $result }
        }
    }
    
    return @{ Action = ($actions -join ","); Success = $true; ActionsCount = $actions.Count }
}

function New-ECRRIncidentReport {
    param($Incident, $RecoveryResult)
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportPath = "CHAR\ECRR\ECRR_REPORTS\AUTOBOT_GUARDIAN_RECOVERY_$timestamp.md"
    
    $report = @"
# ECRR Report: AutoBot Guardian Service Recovery
**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") UTC
**Incident ID:** AUTOBOT-GUARDIAN-$timestamp
**Severity:** Medium (Auto-Recovered)
**AutoBot:** Service Guardian

---

## E — Examine

**Detection Method:** Automated health check ($CheckIntervalSeconds`s interval)

**Service State at Detection:**
- Status: $($Incident.Status)
- StartType: $($Incident.StartType)
- Issue: $($Incident.Issue)

**Recent Service Events:**
``````
$($Incident.RecentEvents | ForEach-Object { "$($_.TimeGenerated): $($_.Message.Substring(0, [Math]::Min(100, $_.Message.Length)))" } | Out-String)
``````

---

## C — Clean

**Recovery Actions Taken:**
$($RecoveryResult.Action)

**Actions Count:** $($RecoveryResult.ActionsCount)

**Post-Recovery State:**
- Status: $($Incident.PostRecoveryState.Status)
- StartType: $($Incident.PostRecoveryState.StartType)

---

## R — Report

**Root Cause:** Service state changed to STOPPED or DISABLED

**Impact:** Telemetry ingestion interrupted (duration: $($Incident.DowntimeSeconds)s)

**Recovery Time:** $($Incident.RecoveryTimeSeconds)s

**Success:** $($RecoveryResult.Success)

---

## R — Role

**AutoBot:** Service Guardian (Automated Recovery Agent)

**Recommendation:** Investigate why service is being stopped/disabled repeatedly.

**Audit Trail:** See $(${LogPath}) for detailed logs.

---

🤖 **AutoBot Guardian** - Automated ECRR Report
"@
    
    try {
        $null = New-Item -ItemType File -Path $reportPath -Value $report -Force
        Write-GuardianLog "📋 ECRR report generated: $reportPath" "INFO"
        return $reportPath
    }
    catch {
        Write-GuardianLog "Failed to create ECRR report: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Invoke-GuardianCheck {
    Write-GuardianLog "🔍 Guardian check started..." "INFO"
    
    $state = Get-ServiceState
    
    if (-not $state.Success) {
        Write-GuardianLog "❌ Cannot check service state" "ERROR"
        return
    }
    
    $issue = $null
    
    # Check 1: Is service running?
    if ($state.Status -ne "Running") {
        $issue = "Service is $($state.Status) (expected: Running)"
    }
    
    # Check 2: Is service set to AUTO?
    if ($state.StartType -ne "AUTO_START") {
        if ($issue) {
            $issue += " AND StartType is $($state.StartType) (expected: AUTO_START)"
        }
        else {
            $issue = "StartType is $($state.StartType) (expected: AUTO_START)"
        }
    }
    
    if ($issue) {
        Write-GuardianLog "⚠️ ISSUE DETECTED: $issue" "WARN"
        
        $startTime = Get-Date
        $recentEvents = Get-ServiceChanges
        
        # Attempt recovery
        $recovery = Invoke-ServiceRecovery -CurrentState $state -Issue $issue
        
        $endTime = Get-Date
        $recoveryTime = ($endTime - $startTime).TotalSeconds
        
        # Get post-recovery state
        $postState = Get-ServiceState
        
        # Generate ECRR report
        $incident = @{
            Status = $state.Status
            StartType = $state.StartType
            Issue = $issue
            RecentEvents = $recentEvents
            DowntimeSeconds = "UNKNOWN"
            RecoveryTimeSeconds = [math]::Round($recoveryTime, 2)
            PostRecoveryState = $postState
        }
        
        $reportPath = New-ECRRIncidentReport -Incident $incident -RecoveryResult $recovery
        
        if ($recovery.Success) {
            Write-GuardianLog "✅ Recovery successful in $($recoveryTime)s" "INFO"
        }
        else {
            Write-GuardianLog "❌ Recovery failed: $($recovery.Error)" "ERROR"
        }
        
        return @{ Issue = $true; Recovery = $recovery; Report = $reportPath }
    }
    else {
        Write-GuardianLog "✅ Service healthy: Running, AUTO_START" "INFO"
        return @{ Issue = $false }
    }
}

# Main execution
Write-Host @"
🤖 AutoBot: Service Guardian
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Service:  otelcol-contrib
Interval: ${CheckIntervalSeconds}s
Mode:     $(if ($DryRun) { "DRY RUN" } else { "ACTIVE RECOVERY" })
Daemon:   $(if ($Daemon) { "YES" } else { "SINGLE CHECK" })
Log:      $LogPath
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"@ -ForegroundColor Cyan

Write-GuardianLog "AutoBot Guardian started" "INFO"
Write-GuardianLog "Mode: $(if ($DryRun) { "DRY RUN" } else { "ACTIVE RECOVERY" })" "INFO"

if ($Daemon) {
    Write-Host "`n🔄 Running in daemon mode (Ctrl+C to stop)...`n" -ForegroundColor Yellow
    
    $checkCount = 0
    while ($true) {
        $checkCount++
        Write-GuardianLog "━━━ Check #$checkCount ━━━" "INFO"
        
        $result = Invoke-GuardianCheck
        
        if ($result.Issue) {
            Write-Host "⚠️  Issue detected and handled. Check logs for details." -ForegroundColor Yellow
        }
        
        Write-GuardianLog "Sleeping for ${CheckIntervalSeconds}s..." "INFO"
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
}
else {
    # Single check mode
    $result = Invoke-GuardianCheck
    
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    if ($result.Issue) {
        Write-Host "⚠️  Issues found and recovery attempted" -ForegroundColor Yellow
        Write-Host "📋 Report: $($result.Report)" -ForegroundColor Cyan
    }
    else {
        Write-Host "✅ Service is healthy - no action needed" -ForegroundColor Green
    }
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
}

Write-GuardianLog "AutoBot Guardian session ended" "INFO"


