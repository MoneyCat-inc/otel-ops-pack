#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Launch Background Agent Orchestrator and Monitor Agent Behavior
    
.DESCRIPTION
    This script launches the Background Agent Orchestrator system that spins off each task type
    to dedicated background agents and monitors their behavior following the ECRR methodology.
    
    Following BossCat OEM governance:
    - Examine: Capture agent behavior and task execution patterns
    - Clean: Remove failed agents and restart healthy ones  
    - Report: Generate comprehensive ECRR reports
    - Role: Assign responsibility for each agent's performance
    
.PARAMETER Duration
    How long to run the orchestrator (in minutes). Default: 30 minutes
    
.PARAMETER OutputDir
    Directory to store agent reports and logs. Default: artifacts/agents
    
.PARAMETER Verbose
    Enable verbose output for debugging
    
.EXAMPLE
    .\scripts\launch-background-agents.ps1 -Duration 60 -Verbose
    
.EXAMPLE
    .\scripts\launch-background-agents.ps1 -OutputDir "C:\otel\agent-reports"
#>

param(
    [int]$Duration = 30,
    [string]$OutputDir = "artifacts/agents",
    [switch]$Verbose
)

# Set error action preference
$ErrorActionPreference = "Continue"

# BossCat OEM Header
Write-Host "`n" -NoNewline
Write-Host "🐾 " -ForegroundColor Cyan -NoNewline
Write-Host "BossCat OEM - Background Agent Orchestrator" -ForegroundColor White
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "📋 Mission: Spin off tasks to background agents and monitor behavior" -ForegroundColor Yellow
Write-Host "⏱️  Duration: $Duration minutes" -ForegroundColor Yellow
Write-Host "📁 Output: $OutputDir" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Cyan

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "✅ Created output directory: $OutputDir" -ForegroundColor Green
}

# Function to log with timestamp
function Write-TimestampedLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO"  { "White" }
        default { "Gray" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-TimestampedLog "🔍 Checking prerequisites..." "INFO"
    
    $prereqs = @{
        "Node.js" = Get-Command node -ErrorAction SilentlyContinue
        "npm" = Get-Command npm -ErrorAction SilentlyContinue
        "tsx" = Get-Command npx -ErrorAction SilentlyContinue
    }
    
    $allGood = $true
    foreach ($prereq in $prereqs.Keys) {
        if ($prereqs[$prereq]) {
            Write-Host "  ✅ $prereq" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $prereq" -ForegroundColor Red
            $allGood = $false
        }
    }
    
    if (-not $allGood) {
        Write-TimestampedLog "❌ Missing prerequisites. Please install Node.js and npm." "ERROR"
        exit 1
    }
    
    Write-TimestampedLog "✅ All prerequisites satisfied" "SUCCESS"
}

# Function to start the orchestrator
function Start-Orchestrator {
    Write-TimestampedLog "🚀 Starting Background Agent Orchestrator..." "INFO"
    
    try {
        # Start the orchestrator in background
        $orchestratorProcess = Start-Process -FilePath "npx" -ArgumentList @(
            "tsx", 
            "scripts/agent/background-agent-orchestrator.ts"
        ) -PassThru -NoNewWindow -RedirectStandardOutput "$OutputDir/orchestrator.log" -RedirectStandardError "$OutputDir/orchestrator-error.log"
        
        Write-TimestampedLog "✅ Orchestrator started (PID: $($orchestratorProcess.Id))" "SUCCESS"
        return $orchestratorProcess
        
    } catch {
        Write-TimestampedLog "❌ Failed to start orchestrator: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Function to monitor agent behavior
function Start-AgentMonitoring {
    param([System.Diagnostics.Process]$OrchestratorProcess)
    
    Write-TimestampedLog "📊 Starting agent behavior monitoring..." "INFO"
    
    $startTime = Get-Date
    $endTime = $startTime.AddMinutes($Duration)
    
    while ((Get-Date) -lt $endTime -and -not $OrchestratorProcess.HasExited) {
        try {
            # Check orchestrator status
            if ($OrchestratorProcess.HasExited) {
                Write-TimestampedLog "⚠️ Orchestrator process has exited" "WARN"
                break
            }
            
            # Monitor agent logs
            $agentLogs = Get-ChildItem "$OutputDir/logs" -Filter "*.log" -ErrorAction SilentlyContinue
            foreach ($log in $agentLogs) {
                $logContent = Get-Content $log.FullName -Tail 5 -ErrorAction SilentlyContinue
                if ($logContent) {
                    $lastLine = $logContent[-1]
                    if ($lastLine -match "ERROR|FAILED|Exception") {
                        Write-TimestampedLog "🚨 Agent $($log.BaseName) error detected: $lastLine" "WARN"
                    }
                }
            }
            
            # Check for new ECRR reports
            $newReports = Get-ChildItem "$OutputDir/ecrr" -Filter "*.json" -ErrorAction SilentlyContinue | 
                         Where-Object { $_.LastWriteTime -gt $startTime }
            
            if ($newReports) {
                Write-TimestampedLog "📋 Generated $($newReports.Count) new ECRR reports" "INFO"
                
                # Analyze reports for critical findings
                foreach ($report in $newReports) {
                    try {
                        $reportData = Get-Content $report.FullName | ConvertFrom-Json
                        $criticalFindings = $reportData.findings.critical
                        
                        if ($criticalFindings.Count -gt 0) {
                            Write-TimestampedLog "🚨 Critical findings in $($report.Name): $($criticalFindings -join ', ')" "ERROR"
                        }
                        
                        if (-not $reportData.bossCatApproval) {
                            Write-TimestampedLog "⚠️ BossCat approval pending for $($report.Name)" "WARN"
                        }
                        
                    } catch {
                        Write-TimestampedLog "⚠️ Failed to parse report $($report.Name)" "WARN"
                    }
                }
            }
            
            # Sleep before next check
            Start-Sleep -Seconds 30
            
        } catch {
            Write-TimestampedLog "⚠️ Error in monitoring loop: $($_.Exception.Message)" "WARN"
            Start-Sleep -Seconds 10
        }
    }
    
    Write-TimestampedLog "⏹️ Monitoring completed" "INFO"
}

# Function to generate summary report
function New-SummaryReport {
    param([string]$OutputPath)
    
    Write-TimestampedLog "📊 Generating summary report..." "INFO"
    
    $summary = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        duration = "$Duration minutes"
        outputDirectory = $OutputPath
        orchestrator = @{
            started = $true
            duration = $Duration
        }
        agents = @()
        reports = @()
        findings = @{
            critical = 0
            major = 0
            minor = 0
        }
        compliance = @{
            security = $true
            performance = $true
            reliability = $true
        }
    }
    
    # Analyze agent logs
    $agentLogs = Get-ChildItem "$OutputPath/logs" -Filter "*.log" -ErrorAction SilentlyContinue
    foreach ($log in $agentLogs) {
        $logContent = Get-Content $log.FullName -ErrorAction SilentlyContinue
        $errorCount = ($logContent | Where-Object { $_ -match "ERROR|FAILED|Exception" }).Count
        
        $summary.agents += @{
            name = $log.BaseName
            logFile = $log.Name
            errorCount = $errorCount
            status = if ($errorCount -eq 0) { "healthy" } else { "issues" }
        }
    }
    
    # Analyze ECRR reports
    $ecrrReports = Get-ChildItem "$OutputPath/ecrr" -Filter "*.json" -ErrorAction SilentlyContinue
    foreach ($report in $ecrrReports) {
        try {
            $reportData = Get-Content $report.FullName | ConvertFrom-Json
            
            $summary.reports += @{
                reportId = $reportData.reportId
                agentId = $reportData.responsibleAgent
                timestamp = $reportData.timestamp
                bossCatApproval = $reportData.bossCatApproval
                criticalFindings = $reportData.findings.critical.Count
                majorFindings = $reportData.findings.major.Count
                minorFindings = $reportData.findings.minor.Count
            }
            
            # Aggregate findings
            $summary.findings.critical += $reportData.findings.critical.Count
            $summary.findings.major += $reportData.findings.major.Count
            $summary.findings.minor += $reportData.findings.minor.Count
            
            # Check compliance
            if (-not $reportData.compliance.security) { $summary.compliance.security = $false }
            if (-not $reportData.compliance.performance) { $summary.compliance.performance = $false }
            if (-not $reportData.compliance.reliability) { $summary.compliance.reliability = $false }
            
        } catch {
            Write-TimestampedLog "⚠️ Failed to analyze report $($report.Name)" "WARN"
        }
    }
    
    # Save summary report
    $summaryPath = Join-Path $OutputPath "summary-report.json"
    $summary | ConvertTo-Json -Depth 10 | Out-File -FilePath $summaryPath -Encoding UTF8
    
    Write-TimestampedLog "✅ Summary report saved: $summaryPath" "SUCCESS"
    
    # Display summary
    Write-Host "`n" -NoNewline
    Write-Host "📊 " -ForegroundColor Cyan -NoNewline
    Write-Host "SUMMARY REPORT" -ForegroundColor White
    Write-Host "=" * 40 -ForegroundColor Cyan
    Write-Host "🤖 Agents: $($summary.agents.Count)" -ForegroundColor Yellow
    Write-Host "📋 ECRR Reports: $($summary.reports.Count)" -ForegroundColor Yellow
    Write-Host "🚨 Critical Findings: $($summary.findings.critical)" -ForegroundColor Red
    Write-Host "⚠️  Major Findings: $($summary.findings.major)" -ForegroundColor Yellow
    Write-Host "ℹ️  Minor Findings: $($summary.findings.minor)" -ForegroundColor Blue
    Write-Host "✅ Security Compliance: $($summary.compliance.security)" -ForegroundColor Green
    Write-Host "⚡ Performance Compliance: $($summary.compliance.performance)" -ForegroundColor Green
    Write-Host "🛡️  Reliability Compliance: $($summary.compliance.reliability)" -ForegroundColor Green
    Write-Host "=" * 40 -ForegroundColor Cyan
    
    return $summary
}

# Function to cleanup
function Stop-Orchestrator {
    param([System.Diagnostics.Process]$OrchestratorProcess)
    
    Write-TimestampedLog "🛑 Stopping orchestrator..." "INFO"
    
    if (-not $OrchestratorProcess.HasExited) {
        $OrchestratorProcess.Kill()
        $OrchestratorProcess.WaitForExit(10000)
    }
    
    Write-TimestampedLog "✅ Orchestrator stopped" "SUCCESS"
}

# Main execution
try {
    Write-TimestampedLog "🎯 BossCat OEM - Background Agent Orchestrator Mission" "INFO"
    Write-TimestampedLog "📋 Following ECRR methodology: Examine → Clean → Report → Role" "INFO"
    
    # Check prerequisites
    Test-Prerequisites
    
    # Start orchestrator
    $orchestratorProcess = Start-Orchestrator
    
    # Monitor behavior
    Start-AgentMonitoring -OrchestratorProcess $orchestratorProcess
    
    # Generate summary
    $summary = New-SummaryReport -OutputPath $OutputDir
    
    # BossCat OEM approval
    Write-Host "`n" -NoNewline
    Write-Host "🐾 " -ForegroundColor Cyan -NoNewline
    Write-Host "BossCat OEM Approval Required" -ForegroundColor White
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    $approval = if ($summary.findings.critical -eq 0 -and $summary.compliance.security -and $summary.compliance.performance) {
        Write-Host "✅ MISSION APPROVED - All agents performing within parameters" -ForegroundColor Green
        $true
    } else {
        Write-Host "❌ MISSION REQUIRES REVIEW - Critical findings or compliance issues detected" -ForegroundColor Red
        $false
    }
    
    Write-Host "📋 BossCat OEM Signature: " -NoNewline
    if ($approval) {
        Write-Host "✅ MISSION APPROVED" -ForegroundColor Green
    } else {
        Write-Host "⚠️ REQUIRES REVIEW" -ForegroundColor Yellow
    }
    Write-Host "=" * 50 -ForegroundColor Cyan
    
} catch {
    Write-TimestampedLog "❌ Mission failed: $($_.Exception.Message)" "ERROR"
    exit 1
} finally {
    # Cleanup
    if ($orchestratorProcess) {
        Stop-Orchestrator -OrchestratorProcess $orchestratorProcess
    }
    
    Write-TimestampedLog "🏁 Mission completed" "INFO"
}

# Export functions for testing
Export-ModuleMember -Function @(
    'Write-TimestampedLog',
    'Test-Prerequisites', 
    'Start-Orchestrator',
    'Start-AgentMonitoring',
    'New-SummaryReport',
    'Stop-Orchestrator'
)
