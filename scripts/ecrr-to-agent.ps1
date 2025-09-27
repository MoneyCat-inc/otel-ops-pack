# ECRR to Agent Task Converter
# Converts ECRR reports to agent tasks in unified schema format

param(
    [Parameter(Mandatory=$true)]
    [string]$Report,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("remediation", "alert", "maintenance", "review")]
    [string]$Type = "remediation",
    
    [Parameter(Mandatory=$false)]
    [string]$Priority = "M",
    
    [Parameter(Mandatory=$false)]
    [string]$AssignedTo = "codex",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$TaskQueueDir = ".agent\task_queue\unified"
$EcrrReportsDir = "docs\ECRR_REPORTS"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Convert-EcrrToAgent {
    param([string]$ReportPath, [string]$TaskType, [string]$TaskPriority, [string]$Assignee)
    
    # Read ECRR report
    if (-not (Test-Path $ReportPath)) {
        Write-Log "ECRR report not found: $ReportPath" "ERROR"
        return $null
    }
    
    $reportContent = Get-Content $ReportPath -Raw
    
    # Extract key information from ECRR report
    $title = ""
    $goal = ""
    $description = ""
    $acceptance = @()
    $scopePaths = @()
    
    # Parse ECRR report structure
    if ($reportContent -match "## 🔍 \*\*Examine.*?\n(.*?)(?=## 🧹|$)") {
        $examineSection = $matches[1]
        if ($examineSection -match "### \*\*Problem Identified\*\*\n(.*?)(?=\n###|$)") {
            $problem = $matches[1].Trim()
            $goal = $problem
            $description = $problem
        }
    }
    
    if ($reportContent -match "## 🧹 \*\*Clean.*?\n(.*?)(?=## 📝|$)") {
        $cleanSection = $matches[1]
        if ($cleanSection -match "### \*\*Actions Taken\*\*\n(.*?)(?=\n###|$)") {
            $actions = $matches[1].Trim()
            $acceptance += "Actions from ECRR report implemented"
        }
    }
    
    # Generate title from report filename
    $reportName = [System.IO.Path]::GetFileNameWithoutExtension($ReportPath)
    $title = "ECRR: $reportName"
    
    # Set default goal if not extracted
    if (-not $goal) {
        $goal = "Implement recommendations from ECRR report: $reportName"
    }
    
    # Generate acceptance criteria
    if ($acceptance.Count -eq 0) {
        $acceptance = @(
            "ECRR report recommendations implemented",
            "All acceptance criteria from report met",
            "System state improved as documented",
            "ECRR report marked as resolved"
        )
    }
    
    # Generate scope paths based on report type
    switch ($TaskType) {
        "remediation" {
            $scopePaths = @("config.yaml", "scripts/", "docs/ECRR_REPORTS/")
        }
        "alert" {
            $scopePaths = @("scripts/monitor-*.ps1", "config.yaml", "alerts/")
        }
        "maintenance" {
            $scopePaths = @("scripts/", "config.yaml", "docs/")
        }
        "review" {
            $scopePaths = @("docs/ECRR_REPORTS/", "docs/")
        }
        default {
            $scopePaths = @("config.yaml", "scripts/", "docs/")
        }
    }
    
    # Generate new task ID
    $date = Get-Date -Format "yyyy-MM-dd"
    $random = Get-Random -Minimum 100 -Maximum 999
    $newId = "T-$date-$random"
    
    # Create unified task structure
    $agentTask = @{
        id = $newId
        title = $title
        goal = $goal
        description = $description
        acceptance = $acceptance
        scope = @{
            paths = $scopePaths
            excluded = @()
        }
        priority = $TaskPriority
        deadline = (Get-Date).AddDays(7).ToString("yyyy-MM-dd")
        tests = @()
        validation_commands = @(
            "pwsh -File scripts/verify-pipeline.ps1",
            "pwsh -File scripts/ecrr-manage.ps1 -Action RegenerateIndex"
        )
        rollback_commands = @("git checkout HEAD~1")
        expected_output = "ECRR report recommendations implemented successfully"
        type = $TaskType
        source = "ecrr"
        recipe = $null
        metrics = @{}
        assigned_to = $Assignee
        status = "pending"
        created_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        original_ecrr_report = $ReportPath
        ecrr_report_id = $reportName
    }
    
    # Generate tests from validation commands
    $agentTask.tests = $agentTask.validation_commands
    
    return $agentTask
}

function Create-AgentTask {
    param([object]$Task, [string]$OutputDir)
    
    # Generate output filename
    $outputFile = Join-Path $OutputDir "$($Task.id).json"
    
    if ($DryRun) {
        Write-Log "DRY RUN: Would create $outputFile"
        Write-Log "DRY RUN: Task ID: $($Task.id)"
        Write-Log "DRY RUN: Title: $($Task.title)"
        Write-Log "DRY RUN: Acceptance criteria: $($Task.acceptance.Count) items"
        Write-Log "DRY RUN: Scope paths: $($Task.scope.paths.Count) items"
        return
    }
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    # Write agent task
    $Task | ConvertTo-Json -Depth 10 | Out-File $outputFile -Encoding utf8
    Write-Log "Created agent task: $($Task.id) from ECRR report: $($Task.ecrr_report_id)"
}

# Main execution
Write-Log "Starting ECRR to Agent conversion (Report: $Report, Type: $Type, Priority: $Priority, DryRun: $DryRun)"

# Resolve report path
$reportPath = $Report
if (-not [System.IO.Path]::IsPathRooted($Report)) {
    $reportPath = Join-Path $EcrrReportsDir $Report
}

# Convert ECRR report to agent task
$agentTask = Convert-EcrrToAgent -ReportPath $reportPath -TaskType $Type -TaskPriority $Priority -Assignee $AssignedTo

if ($agentTask) {
    # Create agent task
    Create-AgentTask -Task $agentTask -OutputDir $TaskQueueDir
    
    Write-Log "ECRR to Agent conversion completed successfully"
    Write-Log "Generated task: $($agentTask.id) - $($agentTask.title)"
} else {
    Write-Log "Failed to convert ECRR report to agent task" "ERROR"
    exit 1
}
