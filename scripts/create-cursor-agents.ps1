# Create Cursor Agents for All Unassigned Tasks
# This script creates specialized Cursor agents for each unassigned task

param(
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

# Define the 7 unassigned tasks and their specialized agent types
$UnassignedTasks = @(
    @{
        TaskId = "TASK-20250925-041323-674"
        AgentId = "cursor-conflict-analysis-agent"
        AgentName = "Cursor Conflict Analysis Agent"
        Specialization = "conflict-analysis"
        Capabilities = @("conflict_detection", "merge_resolution", "git_analysis", "documentation")
    },
    @{
        TaskId = "TASK-20250925-041324-500"
        AgentId = "cursor-otlp-wiring-agent"
        AgentName = "Cursor OTLP Wiring Agent"
        Specialization = "otlp-wiring"
        Capabilities = @("otlp_integration", "wiring_verification", "endpoint_testing", "signoz_connectivity")
    },
    @{
        TaskId = "TASK-20250925-041324-642"
        AgentName = "Cursor Docker Mount Fix Agent"
        AgentId = "cursor-docker-mount-agent"
        Specialization = "docker-mount-fix"
        Capabilities = @("docker_management", "mount_configuration", "container_optimization", "troubleshooting")
    },
    @{
        TaskId = "TASK-20250925-041324-703"
        AgentId = "cursor-wiring-verification-agent"
        AgentName = "Cursor Wiring Verification Agent"
        Specialization = "wiring-verification"
        Capabilities = @("wiring_validation", "connectivity_testing", "endpoint_verification", "signoz_integration")
    },
    @{
        TaskId = "TASK-20250925-041324-781"
        AgentId = "cursor-e2-ratio-analysis-agent"
        AgentName = "Cursor E2 Ratio Analysis Agent"
        Specialization = "e2-ratio-analysis"
        Capabilities = @("performance_analysis", "ratio_calculation", "data_processing", "optimization")
    },
    @{
        TaskId = "TASK-20250925-041326-492"
        AgentId = "cursor-ecrr-processing-agent"
        AgentName = "Cursor ECRR Processing Agent"
        Specialization = "ecrr-processing"
        Capabilities = @("ecrr_processing", "report_analysis", "task_generation", "documentation")
    },
    @{
        TaskId = "TASK-20250925-041326-697"
        AgentId = "cursor-index-management-agent"
        AgentName = "Cursor Index Management Agent"
        Specialization = "index-management"
        Capabilities = @("index_management", "data_organization", "search_optimization", "cataloging")
    }
)

Write-Host "🚀 Creating Cursor Agents for All Unassigned Tasks" -ForegroundColor Green
Write-Host "📊 Total Tasks to Process: $($UnassignedTasks.Count)" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No agents will be created" -ForegroundColor Yellow
    Write-Host ""
}

$CreatedAgents = @()
$AssignedTasks = @()

foreach ($task in $UnassignedTasks) {
    Write-Host "🤖 Creating Agent: $($task.AgentName)" -ForegroundColor Cyan
    Write-Host "   Task ID: $($task.TaskId)" -ForegroundColor Gray
    Write-Host "   Specialization: $($task.Specialization)" -ForegroundColor Gray
    Write-Host "   Capabilities: $($task.Capabilities -join ', ')" -ForegroundColor Gray
    
    if (-not $DryRun) {
        # Create agent configuration
        $agentConfig = @{
            agent_id = $task.AgentId
            name = $task.AgentName
            version = "1.0.0"
            description = "Specialized Cursor agent for $($task.Specialization)"
            specialization = $task.Specialization
            capabilities = $task.Capabilities
            assigned_tasks = @($task.TaskId)
            current_focus = "Task: $($task.TaskId)"
            working_directory = "C:\otel"
            preferred_tools = @(
                "run_terminal_cmd",
                "read_file",
                "write",
                "search_replace",
                "codebase_search",
                "grep",
                "list_dir"
            )
            agent_goals = @(
                "Complete assigned task: $($task.TaskId)",
                "Maintain high code quality and documentation",
                "Follow ECRR methodology (Examine → Clean → Report → Role)",
                "Integrate with existing task management system",
                "Provide clear progress updates and artifacts"
            )
            success_criteria = @(
                "Task completed successfully",
                "All acceptance criteria met",
                "Documentation updated",
                "Verification commands executed",
                "Task status updated to completed"
            )
            status = "active"
            created = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            last_updated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
        
        # Save agent configuration
        $configPath = ".agent/$($task.AgentId)-config.json"
        $agentConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
        
        # Create agent startup script
        $startupScript = @"
# $($task.AgentName) Startup Script
# Specialized agent for $($task.Specialization)

param(
    [string]`$AgentId = "$($task.AgentId)",
    [string]`$TaskId = "$($task.TaskId)",
    [switch]`$DryRun = `$false,
    [switch]`$Verbose = `$false
)

# Agent Configuration
`$AgentConfig = @{
    Name = "$($task.AgentName)"
    Version = "1.0.0"
    Specialization = "$($task.Specialization)"
    Focus = "Task: `$TaskId"
    WorkingDir = "C:\otel"
    Status = "active"
}

Write-Host "🚀 Starting $($task.AgentName)" -ForegroundColor Green
Write-Host "📋 Specialization: $($task.Specialization)" -ForegroundColor Cyan
Write-Host "🎯 Assigned Task: `$TaskId" -ForegroundColor Yellow
Write-Host ""

# Task-specific implementation steps
`$ImplementationSteps = @(
    "Examine task requirements and acceptance criteria",
    "Analyze current system state and dependencies",
    "Implement required changes and improvements",
    "Execute verification commands and tests",
    "Update documentation and create artifacts",
    "Complete acceptance criteria validation",
    "Update task status to completed"
)

Write-Host "📊 Implementation Steps:" -ForegroundColor Cyan
for (`$i = 0; `$i -lt `$ImplementationSteps.Count; `$i++) {
    `$stepNum = `$i + 1
    Write-Host "  `$stepNum. `$(`$ImplementationSteps[`$i])" -ForegroundColor White
}

Write-Host ""
Write-Host "✅ Agent ready to work on task: `$TaskId" -ForegroundColor Green
Write-Host ""
Write-Host "🔧 Available Commands:" -ForegroundColor Cyan
Write-Host "  pwsh -File scripts/manage-tasks.ps1 -Action List" -ForegroundColor Gray
Write-Host "  pwsh -File scripts/manage-tasks.ps1 -Action Status" -ForegroundColor Gray
Write-Host "  pwsh -File scripts/manage-tasks.ps1 -Action Assign -TaskId `$TaskId -Assignee `$AgentId" -ForegroundColor Gray
Write-Host ""

# Update agent status
`$agentStatus = @{
    agent_id = `$AgentId
    status = "active"
    current_task = `$TaskId
    specialization = "$($task.Specialization)"
    last_updated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    completion_percentage = 0
}

`$agentStatus | ConvertTo-Json | Out-File -FilePath ".agent/`$AgentId-status.json" -Encoding UTF8

Write-Host "✅ Agent status updated in .agent/`$AgentId-status.json" -ForegroundColor Green
"@
        
        $startupPath = "scripts/$($task.AgentId)-startup.ps1"
        $startupScript | Out-File -FilePath $startupPath -Encoding UTF8
        
        # Assign task to agent
        try {
            $assignResult = pwsh -File scripts/manage-tasks.ps1 -Action Assign -TaskId $task.TaskId -Assignee $task.AgentId 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✅ Task assigned successfully" -ForegroundColor Green
                $AssignedTasks += $task.TaskId
            } else {
                Write-Host "   ❌ Task assignment failed: $assignResult" -ForegroundColor Red
            }
        } catch {
            Write-Host "   ❌ Task assignment error: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        $CreatedAgents += $task
        Write-Host "   ✅ Agent created successfully" -ForegroundColor Green
    } else {
        Write-Host "   ⏭️  Skipped (dry run mode)" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Create master agent management script
$masterAgentScript = @"
# Master Cursor Agent Management Script
# Manages all specialized Cursor agents

param(
    [string]`$Action = "Status",
    [string]`$AgentId = "",
    [switch]`$ListAll = `$false
)

`$Agents = @(
    @{ Id = "cursor-ecrr-agent-001"; Name = "Cursor ECRR Task Agent"; Status = "Active" },
    @{ Id = "cursor-conflict-analysis-agent"; Name = "Cursor Conflict Analysis Agent"; Status = "Active" },
    @{ Id = "cursor-otlp-wiring-agent"; Name = "Cursor OTLP Wiring Agent"; Status = "Active" },
    @{ Id = "cursor-docker-mount-agent"; Name = "Cursor Docker Mount Fix Agent"; Status = "Active" },
    @{ Id = "cursor-wiring-verification-agent"; Name = "Cursor Wiring Verification Agent"; Status = "Active" },
    @{ Id = "cursor-e2-ratio-analysis-agent"; Name = "Cursor E2 Ratio Analysis Agent"; Status = "Active" },
    @{ Id = "cursor-ecrr-processing-agent"; Name = "Cursor ECRR Processing Agent"; Status = "Active" },
    @{ Id = "cursor-index-management-agent"; Name = "Cursor Index Management Agent"; Status = "Active" }
)

switch (`$Action.ToLower()) {
    "status" {
        Write-Host "🤖 Cursor Agent Status Overview" -ForegroundColor Green
        Write-Host "=" * 50 -ForegroundColor Gray
        foreach (`$agent in `$Agents) {
            `$statusColor = if (`$agent.Status -eq "Active") { "Green" } else { "Red" }
            Write-Host "`$(`$agent.Id): `$(`$agent.Name)" -ForegroundColor `$statusColor
            Write-Host "  Status: `$(`$agent.Status)" -ForegroundColor Gray
        }
    }
    "list" {
        Write-Host "📋 Available Cursor Agents" -ForegroundColor Cyan
        Write-Host "=" * 50 -ForegroundColor Gray
        for (`$i = 0; `$i -lt `$Agents.Count; `$i++) {
            `$agentNum = `$i + 1
            Write-Host "`$agentNum. `$(`$Agents[`$i].Id)" -ForegroundColor White
            Write-Host "   Name: `$(`$Agents[`$i].Name)" -ForegroundColor Gray
        }
    }
    "start" {
        if (`$AgentId) {
            `$agent = `$Agents | Where-Object { `$_.Id -eq `$AgentId }
            if (`$agent) {
                Write-Host "🚀 Starting `$(`$agent.Name)..." -ForegroundColor Green
                pwsh -File "scripts/`$AgentId-startup.ps1"
            } else {
                Write-Host "❌ Agent not found: `$AgentId" -ForegroundColor Red
            }
        } else {
            Write-Host "❌ Please specify AgentId with -AgentId parameter" -ForegroundColor Red
        }
    }
    "help" {
        Write-Host "🔧 Cursor Agent Management Commands" -ForegroundColor Cyan
        Write-Host "=" * 50 -ForegroundColor Gray
        Write-Host "Status: Show all agent status" -ForegroundColor White
        Write-Host "List: List all available agents" -ForegroundColor White
        Write-Host "Start: Start specific agent (requires -AgentId)" -ForegroundColor White
        Write-Host "Help: Show this help message" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host "  pwsh -File scripts/master-agent-management.ps1 -Action Status" -ForegroundColor Gray
        Write-Host "  pwsh -File scripts/master-agent-management.ps1 -Action List" -ForegroundColor Gray
        Write-Host "  pwsh -File scripts/master-agent-management.ps1 -Action Start -AgentId cursor-ecrr-agent-001" -ForegroundColor Gray
    }
    default {
        Write-Host "❌ Unknown action: `$Action" -ForegroundColor Red
        Write-Host "Use -Action Help for available commands" -ForegroundColor Yellow
    }
}
"@

if (-not $DryRun) {
    $masterAgentScript | Out-File -FilePath "scripts/master-agent-management.ps1" -Encoding UTF8
}

# Summary
Write-Host "🎉 Agent Creation Summary" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Gray
Write-Host "Total Agents Created: $($CreatedAgents.Count)" -ForegroundColor Cyan
Write-Host "Total Tasks Assigned: $($AssignedTasks.Count)" -ForegroundColor Cyan
Write-Host ""

if (-not $DryRun) {
    Write-Host "📁 Files Created:" -ForegroundColor Yellow
    foreach ($agent in $CreatedAgents) {
        Write-Host "  .agent/$($agent.AgentId)-config.json" -ForegroundColor Gray
        Write-Host "  scripts/$($agent.AgentId)-startup.ps1" -ForegroundColor Gray
    }
    Write-Host "  scripts/master-agent-management.ps1" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "🔧 Management Commands:" -ForegroundColor Cyan
    Write-Host "  pwsh -File scripts/master-agent-management.ps1 -Action Status" -ForegroundColor Gray
    Write-Host "  pwsh -File scripts/master-agent-management.ps1 -Action List" -ForegroundColor Gray
    Write-Host "  pwsh -File scripts/master-agent-management.ps1 -Action Start -AgentId <agent-id>" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "✅ All Cursor agents are now ready for task execution!" -ForegroundColor Green
} else {
    Write-Host "⏭️  Dry run completed - no files were created" -ForegroundColor Yellow
}
