# See C:\otel\docs\comfort cat
# AutoBot: Gate Auditor
# Tracks who/what is changing the Windows Collector service
# Generates forensic reports on service state changes

param(
    [int]$LookbackHours = 24,
    [string]$OutputPath = "artifacts\gate-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

$ErrorActionPreference = "Continue"

function Get-ServiceChangeEvents {
    param([int]$Hours)
    
    Write-Host "🔍 Analyzing service events (last $Hours hours)..." -ForegroundColor Cyan
    
    try {
        $events = Get-EventLog -LogName System -Newest 1000 -ErrorAction SilentlyContinue |
            Where-Object { 
                $_.TimeGenerated -gt (Get-Date).AddHours(-$Hours) -and
                $_.Message -match "otelcol|OpenTelemetry"
            }
        
        return $events
    }
    catch {
        Write-Host "⚠️  Could not read System event log: $($_.Exception.Message)" -ForegroundColor Yellow
        return @()
    }
}

function Get-ProcessInfo {
    param([int]$ProcessId)
    
    if ($ProcessId -eq 0) {
        return @{ Name = "System"; User = "SYSTEM" }
    }
    
    try {
        $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        if ($process) {
            $owner = (Get-WmiObject Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction SilentlyContinue).GetOwner()
            return @{
                Name = $process.Name
                User = if ($owner) { "$($owner.Domain)\$($owner.User)" } else { "UNKNOWN" }
                Path = $process.Path
            }
        }
    }
    catch { }
    
    return @{ Name = "UNKNOWN"; User = "UNKNOWN" }
}

function Get-ServiceHistory {
    Write-Host "📊 Retrieving service configuration history..." -ForegroundColor Cyan
    
    # Current state
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    $configRaw = sc.exe qc otelcol-contrib | Out-String
    
    $startType = if ($configRaw -match "START_TYPE\s+:\s+\d+\s+(\w+)") { $matches[1] } else { "UNKNOWN" }
    
    $currentState = @{
        Status = $service.Status.ToString()
        StartType = $startType
        DisplayName = $service.DisplayName
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    # Get service changes from event log
    $events = Get-ServiceChangeEvents -Hours $LookbackHours
    
    $changes = $events | ForEach-Object {
        @{
            Timestamp = $_.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")
            EventId = $_.EventID
            Source = $_.Source
            EntryType = $_.EntryType.ToString()
            Message = $_.Message.Substring(0, [Math]::Min(200, $_.Message.Length))
            UserName = $_.UserName
        }
    }
    
    return @{
        CurrentState = $currentState
        Changes = $changes
        ChangeCount = $changes.Count
    }
}

function Get-RecentServiceStarts {
    Write-Host "🚀 Analyzing service start/stop patterns..." -ForegroundColor Cyan
    
    try {
        $startStopEvents = Get-EventLog -LogName System -Source "Service Control Manager" -Newest 500 |
            Where-Object { 
                $_.TimeGenerated -gt (Get-Date).AddHours(-$LookbackHours) -and
                ($_.EventID -eq 7036 -or $_.EventID -eq 7040) -and
                $_.Message -match "OpenTelemetry"
            }
        
        $pattern = $startStopEvents | ForEach-Object {
            $action = if ($_.Message -match "stopped") { "STOPPED" }
                     elseif ($_.Message -match "running") { "STARTED" }
                     elseif ($_.Message -match "disabled") { "DISABLED" }
                     elseif ($_.Message -match "auto") { "SET_AUTO" }
                     else { "CHANGED" }
            
            @{
                Timestamp = $_.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss.fff")
                Action = $action
                EventID = $_.EventID
                Message = $_.Message.Substring(0, [Math]::Min(150, $_.Message.Length))
            }
        }
        
        return $pattern
    }
    catch {
        return @()
    }
}

function Get-SuspiciousPatterns {
    param($Pattern)
    
    Write-Host "🕵️  Detecting suspicious patterns..." -ForegroundColor Cyan
    
    $suspiciousPatterns = @()
    
    # Pattern 1: Rapid start/stop cycles
    $stopStartPairs = 0
    for ($i = 0; $i -lt $Pattern.Count - 1; $i++) {
        if ($Pattern[$i].Action -eq "STOPPED" -and $Pattern[$i+1].Action -eq "STARTED") {
            $time1 = [DateTime]::Parse($Pattern[$i].Timestamp)
            $time2 = [DateTime]::Parse($Pattern[$i+1].Timestamp)
            $gap = ($time2 - $time1).TotalMinutes
            
            if ($gap -lt 2) {
                $stopStartPairs++
                $suspiciousPatterns += @{
                    Type = "RAPID_RESTART"
                    Description = "Service restarted within $([math]::Round($gap, 1)) minutes"
                    Timestamp = $Pattern[$i].Timestamp
                    Severity = "HIGH"
                }
            }
        }
    }
    
    # Pattern 2: Multiple DISABLED events
    $disableCount = ($Pattern | Where-Object { $_.Action -eq "DISABLED" }).Count
    if ($disableCount -gt 1) {
        $suspiciousPatterns += @{
            Type = "MULTIPLE_DISABLE"
            Description = "Service disabled $disableCount times in ${LookbackHours}h"
            Severity = "HIGH"
        }
    }
    
    # Pattern 3: Frequent changes
    if ($Pattern.Count -gt 10) {
        $suspiciousPatterns += @{
            Type = "HIGH_CHANGE_FREQUENCY"
            Description = "$($Pattern.Count) service state changes in ${LookbackHours}h"
            Severity = "MEDIUM"
        }
    }
    
    return $suspiciousPatterns
}

# Main execution
Write-Host @"

🤖 AutoBot: Gate Auditor
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Service:   otelcol-contrib
Lookback:  $LookbackHours hours
Output:    $OutputPath
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"@ -ForegroundColor Cyan

$history = Get-ServiceHistory
$pattern = Get-RecentServiceStarts
$suspicious = Get-SuspiciousPatterns -Pattern $pattern

# Build audit report
$auditReport = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    LookbackHours = $LookbackHours
    CurrentState = $history.CurrentState
    ChangeHistory = $history.Changes
    StartStopPattern = $pattern
    SuspiciousPatterns = $suspicious
    Statistics = @{
        TotalChanges = $history.ChangeCount
        StartStopEvents = $pattern.Count
        SuspiciousPatternCount = $suspicious.Count
    }
}

# Save to JSON
$null = New-Item -ItemType Directory -Force -Path (Split-Path $OutputPath)
$auditReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# Display summary
Write-Host "📊 AUDIT SUMMARY" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

Write-Host "`nCurrent State:" -ForegroundColor Yellow
Write-Host "  Status:     $($history.CurrentState.Status)" -ForegroundColor $(if ($history.CurrentState.Status -eq "Running") { "Green" } else { "Red" })
Write-Host "  StartType:  $($history.CurrentState.StartType)" -ForegroundColor $(if ($history.CurrentState.StartType -eq "AUTO_START") { "Green" } else { "Yellow" })

Write-Host "`nActivity (last ${LookbackHours}h):" -ForegroundColor Yellow
Write-Host "  Total changes:        $($history.ChangeCount)"
Write-Host "  Start/Stop events:    $($pattern.Count)"
Write-Host "  Suspicious patterns:  $($suspicious.Count)" -ForegroundColor $(if ($suspicious.Count -gt 0) { "Red" } else { "Green" })

if ($suspicious.Count -gt 0) {
    Write-Host "`n⚠️  SUSPICIOUS PATTERNS DETECTED:" -ForegroundColor Red
    foreach ($s in $suspicious) {
        Write-Host "  [$($s.Severity)] $($s.Type): $($s.Description)" -ForegroundColor Yellow
    }
}

if ($pattern.Count -gt 0) {
    Write-Host "`nRecent Service Activity:" -ForegroundColor Yellow
    $pattern | Select-Object -First 10 | ForEach-Object {
        $color = switch ($_.Action) {
            "STARTED" { "Green" }
            "STOPPED" { "Red" }
            "DISABLED" { "Red" }
            "SET_AUTO" { "Green" }
            default { "Gray" }
        }
        Write-Host "  $($_.Timestamp) | $($_.Action)" -ForegroundColor $color
    }
    
    if ($pattern.Count -gt 10) {
        Write-Host "  ... and $($pattern.Count - 10) more events" -ForegroundColor Gray
    }
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ Audit complete: $OutputPath" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# Return summary for scripting
return $auditReport

