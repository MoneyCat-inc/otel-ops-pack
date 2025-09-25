# ECRR Task Generator - Automated Task Creation from ECRR Reports
# Analyzes ECRR reports and generates actionable tasks with duplicate detection

param(
    [Parameter(Mandatory = $false)]
    [string]$EcrrReportPath = "docs/ECRR_REPORTS/archive",
    
    [Parameter(Mandatory = $false)]
    [string]$JobsPath = "jobs",
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxTasks = 10
)

$ErrorActionPreference = 'Stop'

# Project context and scope analysis
$ProjectContext = @{
    Name = "OTel Observability Pipeline"
    Description = "Windows OpenTelemetry Collector + SigNoz observability pipeline"
    Components = @(
        "Windows Collector Service (otelcol-contrib)",
        "SigNoz Stack (Docker containers)",
        "GPU Sidecars (otel-gpu-*)",
        "Monitoring Scripts (PowerShell)",
        "ECRR Lifecycle Management",
        "Automation Framework"
    )
    CurrentStatus = @{
        DiskUsage = "69% (healthy)"
        CollectorStatus = "Running"
        SigNozStatus = "Operational"
        ECRRReports = "91/92 processed (98.9%)"
    }
}

# Task categorization and priority mapping
$TaskCategories = @{
    "observability" = @{
        Keywords = @("sigoz", "logs", "metrics", "traces", "clickhouse", "parser", "dataset")
        Priority = "high"
        Effort = "M"
        Assignee = "observability-engineer"
    }
    "infrastructure" = @{
        Keywords = @("collector", "service", "windows", "docker", "container", "port", "endpoint")
        Priority = "high"
        Effort = "M"
        Assignee = "system-admin"
    }
    "automation" = @{
        Keywords = @("script", "automation", "scheduled", "batch", "lifecycle", "ecrr")
        Priority = "medium"
        Effort = "S"
        Assignee = "devops-engineer"
    }
    "monitoring" = @{
        Keywords = @("alert", "health", "check", "monitor", "watch", "status")
        Priority = "medium"
        Effort = "S"
        Assignee = "observability-engineer"
    }
    "development" = @{
        Keywords = @("code", "implementation", "feature", "enhancement", "optimization")
        Priority = "medium"
        Effort = "L"
        Assignee = "team-lead"
    }
    "maintenance" = @{
        Keywords = @("cleanup", "clean", "disk", "space", "archive", "organize")
        Priority = "low"
        Effort = "XS"
        Assignee = "system-admin"
    }
}

function Write-TaskLog {
    param(
        [string]$Message,
        [ValidateSet('INFO','SUCCESS','WARN','ERROR')]
        [string]$Level = 'INFO'
    )
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'SUCCESS' { 'Green' }
        'WARN'    { 'Yellow' }
        'ERROR'   { 'Red' }
        default   { 'Cyan' }
    }
    Write-Host "[$stamp] [$Level] $Message" -ForegroundColor $color
}

function Get-TaskCategory {
    param([string]$Content)
    
    $contentLower = $Content.ToLower()
    $categoryScores = @{}
    
    foreach ($category in $TaskCategories.Keys) {
        $score = 0
        foreach ($keyword in $TaskCategories[$category].Keywords) {
            if ($contentLower -match $keyword) {
                $score += 1
            }
        }
        $categoryScores[$category] = $score
    }
    
    $topCategory = ($categoryScores | Sort-Object Value -Descending | Select-Object -First 1).Key
    return if ($categoryScores[$topCategory] -gt 0) { $topCategory } else { "maintenance" }
}

function Get-TaskPriority {
    param([string]$Content, [string]$Category)
    
    $contentLower = $Content.ToLower()
    
    # Critical priority indicators
    if ($contentLower -match "critical|urgent|emergency|failure|down|broken") {
        return "critical"
    }
    
    # High priority indicators
    if ($contentLower -match "error|issue|problem|fix|resolve|stability") {
        return "high"
    }
    
    # Use category default
    return $TaskCategories[$Category].Priority
}

function Get-TaskEffort {
    param([string]$Content, [string]$Category)
    
    $contentLower = $Content.ToLower()
    
    # Effort estimation based on content
    if ($contentLower -match "simple|quick|minor|small") {
        return "XS"
    }
    if ($contentLower -match "complex|major|comprehensive|extensive") {
        return "XL"
    }
    if ($contentLower -match "implementation|development|feature") {
        return "L"
    }
    
    # Use category default
    return $TaskCategories[$Category].Effort
}

function Test-DuplicateTask {
    param(
        [string]$Title,
        [string]$JobsPath
    )
    
    $existingTasks = Get-ChildItem -Path $JobsPath -Recurse -Filter "*.md" |
        Where-Object { $_.Name -ne "task-template.md" }
    
    foreach ($task in $existingTasks) {
        $content = Get-Content -Path $task.FullName -Raw
        if ($content -match "Title.*$([regex]::Escape($Title))") {
            return $task.FullName
        }
    }
    
    return $null
}

function New-TaskFromEcrrReport {
    param(
        [string]$ReportPath,
        [string]$JobsPath,
        [hashtable]$ProjectContext,
        [hashtable]$TaskCategories
    )
    
    $reportContent = Get-Content -Path $ReportPath -Raw
    $reportName = [System.IO.Path]::GetFileNameWithoutExtension($ReportPath)
    
    # Extract key information from ECRR report
    $title = if ($reportContent -match "# (.+)") { $matches[1] } else { "Task from $reportName" }
    $category = Get-TaskCategory -Content $reportContent
    $priority = Get-TaskPriority -Content $reportContent -Category $category
    $effort = Get-TaskEffort -Content $reportContent -Category $category
    $assignee = $TaskCategories[$category].Assignee
    
    # Check for duplicates
    $duplicatePath = Test-DuplicateTask -Title $title -JobsPath $JobsPath
    if ($duplicatePath) {
        Write-TaskLog "Duplicate task detected: $title (exists in $duplicatePath)" 'WARN'
        return $null
    }
    
    # Generate task ID
    $taskId = "TASK-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$(Get-Random -Minimum 100 -Maximum 999)"
    
    # Extract actionable items from ECRR report
    $actionableItems = @()
    if ($reportContent -match "## 📋 Next Actions|## Next Steps|## Follow-up|## TODOs") {
        $nextActionsSection = $reportContent -split "## 📋 Next Actions|## Next Steps|## Follow-up|## TODOs" | Select-Object -Index 1
        if ($nextActionsSection) {
            $actionableItems = ($nextActionsSection -split "`n" | 
                Where-Object { $_ -match "^\s*[-*]\s*" -or $_ -match "^\s*\d+\.\s*" } |
                ForEach-Object { $_.Trim() -replace "^\s*[-*\d\.]\s*", "" }) | 
                Where-Object { $_.Length -gt 10 }
        }
    }
    
    # Generate task content
    $taskContent = @"
# Task: $title

**Task ID**: `$taskId`  
**Created**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') UTC  
**Priority**: `$priority`  
**Category**: `$category`  
**Estimated Effort**: `$effort`  
**Status**: `pending`  
**Assigned To**: `$assignee`  

## 📋 Task Description

**Title**: `[$category] $title`

**Objective**: 
Implement actionable items identified in ECRR report: $reportName

**Context**: 
Generated from ECRR report analysis. This task addresses specific issues or improvements identified during the ECRR (Examine → Clean → Report → Role) process.

## 🎯 Acceptance Criteria

- [ ] **Implementation Complete**: All actionable items from source ECRR report addressed
- [ ] **Verification Passed**: Task outcomes verified through appropriate testing
- [ ] **Documentation Updated**: Relevant documentation updated to reflect changes

## 📝 Implementation Details

**Scope**: 
Based on ECRR report: $reportName

**Dependencies**: 
Review source ECRR report for specific dependencies: `$ReportPath`

**Resources Required**:
- Source Report: `$ReportPath`
- Scripts: Check ECRR report for specific script references
- Configs: Review ECRR report for configuration changes needed

## 🔧 Technical Requirements

**Commands to Execute**:
```powershell
# Review source ECRR report for specific commands
# Source: $ReportPath
```

**Expected Output**:
Success indicators as defined in source ECRR report.

## 📊 Success Metrics

- **Primary**: ECRR report objectives met
- **Secondary**: System health maintained or improved
- **Monitoring**: Verify through existing monitoring systems

## 🔄 Follow-up Actions

**Next Steps**:
$($actionableItems | ForEach-Object { "1. $_" } | Join-String -Separator "`n")

**Related Tasks**:
- Review other ECRR reports for related tasks
- Check for dependencies in project documentation

## 📁 Artifacts

**Files Created/Modified**:
- Task file: `jobs/pending/$taskId.md`
- Source reference: `$ReportPath`

**Documentation Updated**:
- ECRR report: `$ReportPath`

---

**Generated by**: ECRR Task Generator  
**Source Report**: `$ReportPath`  
**ECRR Session**: `session-$(Get-Date -Format 'yyyyMMdd-HHmmss')`
"@

    return @{
        Id = $taskId
        Title = $title
        Category = $category
        Priority = $priority
        Effort = $effort
        Assignee = $assignee
        Content = $taskContent
        SourceReport = $ReportPath
    }
}

function Invoke-TaskGeneration {
    param(
        [string]$EcrrReportPath,
        [string]$JobsPath,
        [int]$MaxTasks,
        [bool]$DryRun
    )
    
    Write-TaskLog "Starting ECRR Task Generation" 'INFO'
    Write-TaskLog "ECRR Reports Path: $EcrrReportPath" 'INFO'
    Write-TaskLog "Jobs Path: $JobsPath" 'INFO'
    Write-TaskLog "Max Tasks: $MaxTasks" 'INFO'
    Write-TaskLog "Dry Run: $DryRun" 'INFO'
    
    # Ensure jobs directory structure exists
    $jobDirs = @("pending", "in-progress", "completed", "templates")
    foreach ($dir in $jobDirs) {
        $fullPath = Join-Path $JobsPath $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-TaskLog "Created directory: $fullPath" 'SUCCESS'
        }
    }
    
    # Get ECRR reports
    $ecrrReports = Get-ChildItem -Path $EcrrReportPath -Filter "*.md" |
        Where-Object { $_.Name -notmatch "INDEX|README|LATEST|PROCESS|LEDGER" } |
        Sort-Object LastWriteTime -Descending
    
    Write-TaskLog "Found $($ecrrReports.Count) ECRR reports to analyze" 'INFO'
    
    $generatedTasks = @()
    $taskCount = 0
    
    foreach ($report in $ecrrReports) {
        if ($taskCount -ge $MaxTasks) {
            Write-TaskLog "Reached maximum task limit: $MaxTasks" 'WARN'
            break
        }
        
        Write-TaskLog "Analyzing report: $($report.Name)" 'INFO'
        
        try {
            $task = New-TaskFromEcrrReport -ReportPath $report.FullName -JobsPath $JobsPath -ProjectContext $ProjectContext -TaskCategories $TaskCategories
            
            if ($task) {
                $generatedTasks += $task
                $taskCount++
                
                if ($DryRun) {
                    Write-TaskLog "DRY RUN - Would create task: $($task.Title)" 'INFO'
                } else {
                    $taskPath = Join-Path $JobsPath "pending" "$($task.Id).md"
                    Set-Content -Path $taskPath -Value $task.Content -Encoding UTF8
                    Write-TaskLog "Created task: $($task.Title) -> $taskPath" 'SUCCESS'
                }
            }
        } catch {
            Write-TaskLog "Error processing report $($report.Name): $($_.Exception.Message)" 'ERROR'
        }
    }
    
    # Generate summary
    Write-TaskLog "Task Generation Complete" 'SUCCESS'
    Write-TaskLog "Generated Tasks: $($generatedTasks.Count)" 'INFO'
    
    if ($generatedTasks.Count -gt 0) {
        Write-TaskLog "Task Summary:" 'INFO'
        foreach ($task in $generatedTasks) {
            Write-TaskLog "  - [$($task.Category)] $($task.Title) (Priority: $($task.Priority), Effort: $($task.Effort))" 'INFO'
        }
    }
    
    return $generatedTasks
}

# Main execution
try {
    $generatedTasks = Invoke-TaskGeneration -EcrrReportPath $EcrrReportPath -JobsPath $JobsPath -MaxTasks $MaxTasks -DryRun $DryRun
    
    if (-not $DryRun -and $generatedTasks.Count -gt 0) {
        Write-TaskLog "Tasks created in: $JobsPath/pending" 'SUCCESS'
        Write-TaskLog "Review and prioritize tasks before execution" 'INFO'
    }
    
} catch {
    Write-TaskLog "Task generation failed: $($_.Exception.Message)" 'ERROR'
    throw
}
