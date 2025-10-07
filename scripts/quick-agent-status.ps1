#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Quick Agent Status Check
    
.DESCRIPTION
    Quickly check the status of background agents and their behavior patterns.
    Provides a real-time dashboard of agent health and performance.
#>

param(
    [string]$OutputDir = "artifacts/agents",
    [switch]$Watch,
    [int]$RefreshInterval = 10
)

# Set error action preference
$ErrorActionPreference = "Continue"

# Function to get agent status
function Get-AgentStatus {
    param([string]$AgentDir)
    
    $status = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        agents = @()
        reports = @()
        summary = @{
            totalAgents = 0
            healthyAgents = 0
            totalReports = 0
            criticalFindings = 0
            bossCatApprovals = 0
        }
    }
    
    # Check agent logs
    $logDir = Join-Path $AgentDir "logs"
    if (Test-Path $logDir) {
        $agentLogs = Get-ChildItem $logDir -Filter "*.log" -ErrorAction SilentlyContinue
        
        foreach ($log in $agentLogs) {
            $logContent = Get-Content $log.FullName -ErrorAction SilentlyContinue
            $lastLine = $logContent[-1] -replace "^\s*\[.*?\]\s*", ""  # Remove timestamp prefix
            $errorCount = ($logContent | Where-Object { $_ -match "ERROR|FAILED|Exception" }).Count
            $successCount = ($logContent | Where-Object { $_ -match "✅|SUCCESS|completed" }).Count
            
            $agentStatus = @{
                name = $log.BaseName
                lastActivity = $lastLine
                errorCount = $errorCount
                successCount = $successCount
                status = if ($errorCount -eq 0) { "healthy" } elseif ($successCount -gt $errorCount) { "warning" } else { "unhealthy" }
                logSize = (Get-Item $log.FullName).Length
                lastModified = $log.LastWriteTime
            }
            
            $status.agents += $agentStatus
            $status.summary.totalAgents++
            
            if ($agentStatus.status -eq "healthy") {
                $status.summary.healthyAgents++
            }
        }
    }
    
    # Check ECRR reports
    $ecrrDir = Join-Path $AgentDir "ecrr"
    if (Test-Path $ecrrDir) {
        $reports = Get-ChildItem $ecrrDir -Filter "*.json" -ErrorAction SilentlyContinue
        
        foreach ($report in $reports) {
            try {
                $reportData = Get-Content $report.FullName | ConvertFrom-Json
                
                $reportStatus = @{
                    reportId = $reportData.reportId
                    agentId = $reportData.responsibleAgent
                    timestamp = $reportData.timestamp
                    criticalFindings = $reportData.findings.critical.Count
                    majorFindings = $reportData.findings.major.Count
                    minorFindings = $reportData.findings.minor.Count
                    bossCatApproval = $reportData.bossCatApproval
                    compliance = $reportData.compliance
                }
                
                $status.reports += $reportStatus
                $status.summary.totalReports++
                $status.summary.criticalFindings += $reportData.findings.critical.Count
                
                if ($reportData.bossCatApproval) {
                    $status.summary.bossCatApprovals++
                }
                
            } catch {
                # Skip invalid reports
            }
        }
    }
    
    return $status
}

# Function to display status
function Show-Status {
    param([hashtable]$Status)
    
    Clear-Host
    
    # Header
    Write-Host "`n" -NoNewline
    Write-Host "🐾 " -ForegroundColor Cyan -NoNewline
    Write-Host "BossCat OEM - Agent Status Dashboard" -ForegroundColor White
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "⏰ Last Updated: $($Status.timestamp)" -ForegroundColor Gray
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    # Summary
    Write-Host "📊 " -ForegroundColor Yellow -NoNewline
    Write-Host "SUMMARY" -ForegroundColor White
    Write-Host "  🤖 Total Agents: $($Status.summary.totalAgents)" -ForegroundColor Blue
    Write-Host "  ✅ Healthy Agents: $($Status.summary.healthyAgents)" -ForegroundColor Green
    Write-Host "  📋 Total Reports: $($Status.summary.totalReports)" -ForegroundColor Blue
    Write-Host "  🚨 Critical Findings: $($Status.summary.criticalFindings)" -ForegroundColor Red
    Write-Host "  🐾 BossCat Approvals: $($Status.summary.bossCatApprovals)" -ForegroundColor Green
    Write-Host ""
    
    # Agent Status
    if ($Status.agents.Count -gt 0) {
        Write-Host "🤖 " -ForegroundColor Yellow -NoNewline
        Write-Host "AGENT STATUS" -ForegroundColor White
        Write-Host "-" * 60 -ForegroundColor Gray
        
        foreach ($agent in $Status.agents) {
            $statusIcon = switch ($agent.status) {
                "healthy" { "✅" }
                "warning" { "⚠️" }
                "unhealthy" { "❌" }
                default { "❓" }
            }
            
            $statusColor = switch ($agent.status) {
                "healthy" { "Green" }
                "warning" { "Yellow" }
                "unhealthy" { "Red" }
                default { "Gray" }
            }
            
            Write-Host "  $statusIcon " -NoNewline
            Write-Host "$($agent.name.PadRight(20)) " -ForegroundColor White -NoNewline
            Write-Host "Errors: $($agent.errorCount.ToString().PadLeft(3)) " -ForegroundColor Red -NoNewline
            Write-Host "Success: $($agent.successCount.ToString().PadLeft(3)) " -ForegroundColor Green -NoNewline
            Write-Host "Status: " -NoNewline
            Write-Host "$($agent.status)" -ForegroundColor $statusColor
            
            if ($agent.lastActivity) {
                $activity = if ($agent.lastActivity.Length -gt 50) { 
                    $agent.lastActivity.Substring(0, 47) + "..." 
                } else { 
                    $agent.lastActivity 
                }
                Write-Host "      Last: $activity" -ForegroundColor Gray
            }
        }
        Write-Host ""
    }
    
    # Recent Reports
    if ($Status.reports.Count -gt 0) {
        Write-Host "📋 " -ForegroundColor Yellow -NoNewline
        Write-Host "RECENT ECRR REPORTS" -ForegroundColor White
        Write-Host "-" * 60 -ForegroundColor Gray
        
        $recentReports = $Status.reports | Sort-Object timestamp -Descending | Select-Object -First 5
        
        foreach ($report in $recentReports) {
            $approvalIcon = if ($report.bossCatApproval) { "✅" } else { "⚠️" }
            $criticalIcon = if ($report.criticalFindings -gt 0) { "🚨" } else { "✅" }
            
            Write-Host "  $approvalIcon $criticalIcon " -NoNewline
            Write-Host "$($report.agentId.PadRight(15)) " -ForegroundColor White -NoNewline
            Write-Host "Critical: $($report.criticalFindings) " -ForegroundColor Red -NoNewline
            Write-Host "Major: $($report.majorFindings) " -ForegroundColor Yellow -NoNewline
            Write-Host "Minor: $($report.minorFindings)" -ForegroundColor Blue
            
            $time = [DateTime]::Parse($report.timestamp)
            Write-Host "      Generated: $($time.ToString('HH:mm:ss'))" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    # BossCat Approval Status
    Write-Host "🐾 " -ForegroundColor Cyan -NoNewline
    Write-Host "BOSSCAT OEM APPROVAL STATUS" -ForegroundColor White
    Write-Host "-" * 60 -ForegroundColor Gray
    
    $overallApproval = $Status.summary.criticalFindings -eq 0 -and $Status.summary.totalAgents -gt 0
    
    if ($overallApproval) {
        Write-Host "  ✅ SYSTEM APPROVED - All agents operating within parameters" -ForegroundColor Green
        Write-Host "  🐾 BossCat OEM Signature: MISSION APPROVED" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ SYSTEM REQUIRES REVIEW - Issues detected" -ForegroundColor Yellow
        Write-Host "  🐾 BossCat OEM Signature: REQUIRES REVIEW" -ForegroundColor Yellow
    }
    
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    if ($Watch) {
        Write-Host "🔄 Refreshing in $RefreshInterval seconds... (Ctrl+C to exit)" -ForegroundColor Gray
    }
}

# Main execution
try {
    if ($Watch) {
        Write-Host "🔄 Starting continuous monitoring (Ctrl+C to exit)..." -ForegroundColor Yellow
        
        while ($true) {
            $status = Get-AgentStatus -AgentDir $OutputDir
            Show-Status -Status $status
            Start-Sleep -Seconds $RefreshInterval
        }
    } else {
        $status = Get-AgentStatus -AgentDir $OutputDir
        Show-Status -Status $status
    }
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
