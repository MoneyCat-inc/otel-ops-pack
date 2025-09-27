# Cursor Agent Task Lookup Script
# Interactive command that prompts agents to either summarize their current task or examine the first task in queue

param(
    [string]$TaskId = "",
    [string]$TaskNumber = "1",
    [switch]$ListTasks = $false,
    [switch]$ShowPrompt = $true,
    [switch]$ShowDetails = $true,
    [switch]$Verbose = $false,
    [switch]$Interactive = $true,
    [switch]$Summarize = $false,
    [switch]$ExamineFirst = $false
)

Write-Host "🔍 Cursor Agent Task Lookup" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Gray

# Function to read task file
function Read-TaskFile {
    param([string]$TaskId)
    
    $taskFile = "jobs/pending/$TaskId.md"
    if (Test-Path $taskFile) {
        return Get-Content $taskFile -Raw
    }
    
    $taskFile = "jobs/in-progress/$TaskId.md"
    if (Test-Path $taskFile) {
        return Get-Content $taskFile -Raw
    }
    
    $taskFile = "jobs/completed/$TaskId.md"
    if (Test-Path $taskFile) {
        return Get-Content $taskFile -Raw
    }
    
    return $null
}

# Interactive prompt for agents
if ($Interactive -and -not $ListTasks -and -not $TaskId -and $TaskNumber -eq "1" -and -not $Summarize -and -not $ExamineFirst) {
    Write-Host ""
    Write-Host "🤖 Agent Task Assistant" -ForegroundColor Cyan
    Write-Host "What would you like to do?" -ForegroundColor White
    Write-Host ""
    Write-Host "1. 📋 Summarize my current task (if assigned)" -ForegroundColor Yellow
    Write-Host "2. 🔍 Examine the first task in the queue" -ForegroundColor Yellow
    Write-Host "3. 📝 List all available tasks" -ForegroundColor Yellow
    Write-Host "4. ❌ Exit" -ForegroundColor Yellow
    Write-Host ""
    
    do {
        $choice = Read-Host "Enter your choice (1-4)"
    } while ($choice -notmatch "^[1-4]$")
    
    switch ($choice) {
        "1" {
            $Summarize = $true
            Write-Host "📋 Summarizing current task..." -ForegroundColor Cyan
        }
        "2" {
            $ExamineFirst = $true
            Write-Host "🔍 Examining first task in queue..." -ForegroundColor Cyan
        }
        "3" {
            $ListTasks = $true
            Write-Host "📝 Listing all available tasks..." -ForegroundColor Cyan
        }
        "4" {
            Write-Host "👋 Goodbye!" -ForegroundColor Green
            exit 0
        }
    }
    Write-Host ""
}

# Handle direct command options
if ($Summarize) {
    Write-Host "📋 Current Task Summary" -ForegroundColor Cyan
    Write-Host "=" * 30 -ForegroundColor Gray
    
    # Try to find current agent's task
    $currentAgent = $env:AGENT_ID
    if (-not $currentAgent) {
        $currentAgent = "unknown-agent"
    }
    
    # Look for tasks assigned to current agent
    $allTasks = pwsh -File scripts/manage-tasks.ps1 -Action List 2>&1
    $assignedTasks = @()
    
    # Parse tasks to find those assigned to current agent
    $taskLines = $allTasks | Where-Object { $_ -match "ID: TASK-" }
    foreach ($taskLine in $taskLines) {
        $taskId = ($taskLine -split "ID: ")[1].Trim()
        $taskFile = Read-TaskFile -TaskId $taskId
        if ($taskFile) {
            $lines = $taskFile -split "`n"
            $assignedTo = "Unassigned"
            foreach ($line in $lines) {
                $line = $line.Trim()
                if ($line -match "^\*\*Assigned To\*\*: (.+)$") {
                    $assignedTo = $matches[1].Trim()
                }
            }
            if ($assignedTo -eq $currentAgent -or $assignedTo -like "*$currentAgent*") {
                $assignedTasks += $taskId
            }
        }
    }
    
    if ($assignedTasks.Count -eq 0) {
        Write-Host "❌ No tasks currently assigned to agent: $currentAgent" -ForegroundColor Red
        Write-Host "💡 Use 'Examine First Task' to see available work" -ForegroundColor Yellow
        Write-Host ""
        $ExamineFirst = $true
    } else {
        Write-Host "✅ Found $($assignedTasks.Count) task(s) assigned to agent: $currentAgent" -ForegroundColor Green
        Write-Host ""
        
        foreach ($taskId in $assignedTasks) {
            Write-Host "📋 Task: $taskId" -ForegroundColor White
            $taskFile = Read-TaskFile -TaskId $taskId
            if ($taskFile) {
                $lines = $taskFile -split "`n"
                $title = "Unknown Task"
                $priority = "Unknown"
                $status = "Unknown"
                
                foreach ($line in $lines) {
                    $line = $line.Trim()
                    if ($line -match "^# Task: (.+)$") {
                        $title = $matches[1].Trim()
                    }
                    elseif ($line -match "^\*\*Priority\*\*: (.+)$") {
                        $priority = $matches[1].Trim()
                    }
                    elseif ($line -match "^\*\*Status\*\*: (.+)$") {
                        $status = $matches[1].Trim()
                    }
                }
                
                Write-Host "   Title: $title" -ForegroundColor Gray
                Write-Host "   Priority: $priority" -ForegroundColor Gray
                Write-Host "   Status: $status" -ForegroundColor Gray
                Write-Host ""
                
                # Show task description in plain English
                Write-Host "📝 Task Description (Plain English):" -ForegroundColor Cyan
                $inDescription = $false
                foreach ($line in $lines) {
                    $line = $line.Trim()
                    if ($line -match "## Task Description" -or $line -match "## Prompt" -or $line -match "## Instructions") {
                        $inDescription = $true
                        continue
                    }
                    if ($inDescription) {
                        if ($line -match "^## " -and $line -notmatch "## Task Description" -and $line -notmatch "## Prompt" -and $line -notmatch "## Instructions") {
                            break
                        }
                        if ($line -and -not $line.StartsWith("#") -and -not $line.StartsWith("-") -and -not $line.StartsWith("*")) {
                            Write-Host "   $line" -ForegroundColor White
                        }
                    }
                }
                Write-Host ""
            }
        }
    }
}

if ($ExamineFirst) {
    Write-Host "🔍 Examining First Task in Queue" -ForegroundColor Cyan
    Write-Host "=" * 40 -ForegroundColor Gray
    $TaskNumber = "1"
}

# Function to get task by number
function Get-TaskByNumber {
    param([int]$Number)
    
    $allTasks = pwsh -File scripts/manage-tasks.ps1 -Action List 2>&1
    $taskLines = $allTasks | Where-Object { $_ -match "ID: TASK-" }
    
    if ($Number -gt 0 -and $Number -le $taskLines.Count) {
        $taskLine = $taskLines[$Number - 1]
        $taskId = ($taskLine -split "ID: ")[1]
        return $taskId.Trim()
    }
    return $null
}

# Function to extract prompt from task
function Extract-TaskPrompt {
    param([string]$TaskContent)
    
    $prompt = @()
    $inPromptSection = $false
    
    foreach ($line in $TaskContent -split "`n") {
        if ($line -match "## Task Description" -or $line -match "## Prompt" -or $line -match "## Instructions") {
            $inPromptSection = $true
            $prompt += $line
            continue
        }
        
        if ($inPromptSection) {
            if ($line -match "^## " -and $line -notmatch "## Task Description" -and $line -notmatch "## Prompt" -and $line -notmatch "## Instructions") {
                break
            }
            $prompt += $line
        }
    }
    
    return $prompt -join "`n"
}

# Function to extract acceptance criteria
function Extract-AcceptanceCriteria {
    param([string]$TaskContent)
    
    $criteria = @()
    $inCriteriaSection = $false
    
    foreach ($line in $TaskContent -split "`n") {
        if ($line -match "## Acceptance Criteria") {
            $inCriteriaSection = $true
            $criteria += $line
            continue
        }
        
        if ($inCriteriaSection) {
            if ($line -match "^## " -and $line -notmatch "## Acceptance Criteria") {
                break
            }
            $criteria += $line
        }
    }
    
    return $criteria -join "`n"
}

# Function to extract verification commands
function Extract-VerificationCommands {
    param([string]$TaskContent)
    
    $commands = @()
    $inCommandsSection = $false
    
    foreach ($line in $TaskContent -split "`n") {
        if ($line -match "## Verification Commands" -or $line -match "## Commands") {
            $inCommandsSection = $true
            $commands += $line
            continue
        }
        
        if ($inCommandsSection) {
            if ($line -match "^## " -and $line -notmatch "## Verification Commands" -and $line -notmatch "## Commands") {
                break
            }
            $commands += $line
        }
    }
    
    return $commands -join "`n"
}

# Main logic
if ($ListTasks) {
    Write-Host "📋 Available Tasks:" -ForegroundColor Cyan
    Write-Host ""
    
    $allTasks = pwsh -File scripts/manage-tasks.ps1 -Action List 2>&1
    $taskLines = $allTasks | Where-Object { $_ -match "ID: TASK-" }
    
    for ($i = 0; $i -lt $taskLines.Count; $i++) {
        $taskNum = $i + 1
        $taskLine = $taskLines[$i]
        $taskId = ($taskLine -split "ID: ")[1]
        $taskId = $taskId.Trim()
        
        # Get task title
        $taskFile = Read-TaskFile -TaskId $taskId
        $title = "Unknown Task"
        if ($taskFile) {
            $lines = $taskFile -split "`n"
            foreach ($line in $lines) {
                $line = $line.Trim()
                if ($line -match "^# Task: (.+)$") {
                    $title = $matches[1].Trim()
                    break
                }
            }
        }
        
        Write-Host "  $taskNum. $taskId" -ForegroundColor White
        Write-Host "     Title: $title" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "💡 Usage Examples:" -ForegroundColor Yellow
    Write-Host "   Interactive mode: pwsh -File scripts/cursor-agent-task-lookup.ps1" -ForegroundColor Gray
    Write-Host "   Summarize current: pwsh -File scripts/cursor-agent-task-lookup.ps1 -Summarize" -ForegroundColor Gray
    Write-Host "   Examine first: pwsh -File scripts/cursor-agent-task-lookup.ps1 -ExamineFirst" -ForegroundColor Gray
    Write-Host "   List all tasks: pwsh -File scripts/cursor-agent-task-lookup.ps1 -ListTasks" -ForegroundColor Gray
    Write-Host "   Specific task: pwsh -File scripts/cursor-agent-task-lookup.ps1 -TaskNumber 1" -ForegroundColor Gray
    exit 0
}

# Determine task ID
if (-not $TaskId) {
    if ($TaskNumber -match "^\d+$") {
        $taskNum = [int]$TaskNumber
        $TaskId = Get-TaskByNumber -Number $taskNum
        if (-not $TaskId) {
            Write-Host "❌ Task number $TaskNumber not found" -ForegroundColor Red
            Write-Host "💡 Use -ListTasks to see available tasks" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "❌ Please specify either -TaskId or -TaskNumber" -ForegroundColor Red
        Write-Host "💡 Use -ListTasks to see available tasks" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "🎯 Looking up task: $TaskId" -ForegroundColor Cyan
Write-Host ""

# Read task file
$taskContent = Read-TaskFile -TaskId $TaskId
if (-not $taskContent) {
    Write-Host "❌ Task file not found for: $TaskId" -ForegroundColor Red
    Write-Host "💡 Check if task exists in jobs/pending/, jobs/in-progress/, or jobs/completed/" -ForegroundColor Yellow
    exit 1
}

# Extract task information using line-by-line parsing
$title = "Unknown Task"
$assignedTo = "Unassigned"
$priority = "Unknown"
$category = "Unknown"
$status = "Unknown"

$lines = $taskContent -split "`n"
foreach ($line in $lines) {
    $line = $line.Trim()
    
    if ($line -match "^# Task: (.+)$") {
        $title = $matches[1].Trim()
    }
    elseif ($line -match "^\*\*Assigned To\*\*: (.+)$") {
        $assignedTo = $matches[1].Trim()
    }
    elseif ($line -match "^\*\*Priority\*\*: (.+)$") {
        $priority = $matches[1].Trim()
    }
    elseif ($line -match "^\*\*Category\*\*: (.+)$") {
        $category = $matches[1].Trim()
    }
    elseif ($line -match "^\*\*Status\*\*: (.+)$") {
        $status = $matches[1].Trim()
    }
}

# Display task overview
Write-Host "📋 Task Overview" -ForegroundColor Cyan
Write-Host "=" * 30 -ForegroundColor Gray
Write-Host "Task ID: $TaskId" -ForegroundColor White
Write-Host "Title: $title" -ForegroundColor White
Write-Host "Assigned To: $assignedTo" -ForegroundColor White
Write-Host "Priority: $priority" -ForegroundColor White
Write-Host "Category: $category" -ForegroundColor White
Write-Host "Status: $status" -ForegroundColor White
Write-Host ""

if ($ShowDetails) {
    # Extract and display task description/prompt
    $prompt = Extract-TaskPrompt -TaskContent $taskContent
    if ($prompt -and $ShowPrompt) {
        Write-Host "📝 Task Description/Prompt" -ForegroundColor Cyan
        Write-Host "=" * 40 -ForegroundColor Gray
        Write-Host $prompt -ForegroundColor White
        Write-Host ""
    }
    
    # Extract and display acceptance criteria
    $criteria = Extract-AcceptanceCriteria -TaskContent $taskContent
    if ($criteria) {
        Write-Host "✅ Acceptance Criteria" -ForegroundColor Cyan
        Write-Host "=" * 30 -ForegroundColor Gray
        Write-Host $criteria -ForegroundColor White
        Write-Host ""
    }
    
    # Extract and display verification commands
    $commands = Extract-VerificationCommands -TaskContent $taskContent
    if ($commands) {
        Write-Host "🔧 Verification Commands" -ForegroundColor Cyan
        Write-Host "=" * 35 -ForegroundColor Gray
        Write-Host $commands -ForegroundColor White
        Write-Host ""
    }
}

# Display next actions
Write-Host "🚀 Next Actions" -ForegroundColor Cyan
Write-Host "=" * 20 -ForegroundColor Gray
Write-Host "1. Review the task requirements above" -ForegroundColor White
Write-Host "2. Understand the acceptance criteria" -ForegroundColor White
Write-Host "3. Execute verification commands to test your work" -ForegroundColor White
Write-Host "4. Follow ECRR methodology (Examine → Clean → Report → Role)" -ForegroundColor White
Write-Host "5. Update task status when complete" -ForegroundColor White
Write-Host ""

# Display helpful commands
Write-Host "🔧 Helpful Commands" -ForegroundColor Cyan
Write-Host "=" * 25 -ForegroundColor Gray
Write-Host "Check task status: pwsh -File scripts/manage-tasks.ps1 -Action Status" -ForegroundColor Gray
Write-Host "List all tasks: pwsh -File scripts/manage-tasks.ps1 -Action List" -ForegroundColor Gray
Write-Host "Assign task: pwsh -File scripts/manage-tasks.ps1 -Action Assign -TaskId $TaskId -Assignee <agent-id>" -ForegroundColor Gray
Write-Host "List available tasks: pwsh -File scripts/cursor-agent-task-lookup.ps1 -ListTasks" -ForegroundColor Gray
Write-Host ""

if ($Verbose) {
    Write-Host "📄 Full Task Content" -ForegroundColor Cyan
    Write-Host "=" * 30 -ForegroundColor Gray
    Write-Host $taskContent -ForegroundColor White
}

Write-Host "✅ Task lookup completed!" -ForegroundColor Green

# Show help if requested
if ($args -contains "-Help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-Host ""
    Write-Host "🔧 Cursor Agent Task Lookup Help" -ForegroundColor Cyan
    Write-Host "=" * 40 -ForegroundColor Gray
    Write-Host ""
    Write-Host "📋 Interactive Mode (Default):" -ForegroundColor Yellow
    Write-Host "   pwsh -File scripts/cursor-agent-task-lookup.ps1" -ForegroundColor Gray
    Write-Host "   - Prompts agent to choose action" -ForegroundColor White
    Write-Host "   - Summarize current task or examine first task" -ForegroundColor White
    Write-Host ""
    Write-Host "🎯 Direct Commands:" -ForegroundColor Yellow
    Write-Host "   -Summarize     Summarize current agent's assigned tasks" -ForegroundColor Gray
    Write-Host "   -ExamineFirst  Examine the first task in the queue" -ForegroundColor Gray
    Write-Host "   -ListTasks     List all available tasks" -ForegroundColor Gray
    Write-Host "   -TaskNumber N  Look up task by number" -ForegroundColor Gray
    Write-Host "   -TaskId ID     Look up specific task by ID" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚙️  Display Options:" -ForegroundColor Yellow
    Write-Host "   -ShowPrompt    Show task description/prompt (default: true)" -ForegroundColor Gray
    Write-Host "   -ShowDetails   Show task details (default: true)" -ForegroundColor Gray
    Write-Host "   -Verbose       Show full task content" -ForegroundColor Gray
    Write-Host "   -Interactive   Enable interactive mode (default: true)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "💡 Examples:" -ForegroundColor Yellow
    Write-Host "   # Interactive mode" -ForegroundColor Gray
    Write-Host "   pwsh -File scripts/cursor-agent-task-lookup.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "   # Summarize current task" -ForegroundColor Gray
    Write-Host "   pwsh -File scripts/cursor-agent-task-lookup.ps1 -Summarize" -ForegroundColor White
    Write-Host ""
    Write-Host "   # Examine first task" -ForegroundColor Gray
    Write-Host "   pwsh -File scripts/cursor-agent-task-lookup.ps1 -ExamineFirst" -ForegroundColor White
    Write-Host ""
    Write-Host "   # List all tasks" -ForegroundColor Gray
    Write-Host "   pwsh -File scripts/cursor-agent-task-lookup.ps1 -ListTasks" -ForegroundColor White
    Write-Host ""
}
