# Cursor Agent Task Lookup Guide

## 🎯 **Overview**

The Cursor Agent Task Lookup system provides a comprehensive way for blank Cursor agents to discover, understand, and work with tasks in the observability pipeline. This system allows any agent to quickly look up task details, read prompts, and understand requirements.

## 🔧 **Command Reference**

### **Basic Usage**
```powershell
# Look up the first task
pwsh -File scripts/cursor-agent-task-lookup.ps1 -TaskNumber 1

# Look up a specific task by ID
pwsh -File scripts/cursor-agent-task-lookup.ps1 -TaskId TASK-20250923-223956-864

# List all available tasks
pwsh -File scripts/cursor-agent-task-lookup.ps1 -ListTasks

# Show help
pwsh -File scripts/cursor-agent-task-lookup.ps1 -Help
```

### **Advanced Options**
```powershell
# Verbose output with full task content
pwsh -File scripts/cursor-agent-task-lookup.ps1 -TaskNumber 1 -Verbose

# Show only task details without prompt
pwsh -File scripts/cursor-agent-task-lookup.ps1 -TaskNumber 1 -ShowDetails:$false

# Show only prompt without details
pwsh -File scripts/cursor-agent-task-lookup.ps1 -TaskNumber 1 -ShowPrompt:$false
```

## 📋 **Command Parameters**

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `-TaskNumber` | String | Task number (1-based index) | `-TaskNumber 1` |
| `-TaskId` | String | Specific task ID | `-TaskId TASK-20250923-223956-864` |
| `-ListTasks` | Switch | List all available tasks | `-ListTasks` |
| `-ShowPrompt` | Switch | Show task description/prompt (default: true) | `-ShowPrompt:$false` |
| `-ShowDetails` | Switch | Show task details (default: true) | `-ShowDetails:$false` |
| `-Verbose` | Switch | Show full task content | `-Verbose` |

## 🎯 **Task Information Displayed**

### **Task Overview**
- **Task ID**: Unique identifier
- **Title**: Task name and description
- **Assigned To**: Current assignee (or "Unassigned")
- **Priority**: Task priority level
- **Category**: Task category (observability, infrastructure, etc.)
- **Status**: Current status (pending, in-progress, completed)

### **Task Content**
- **Task Description/Prompt**: Detailed task requirements
- **Acceptance Criteria**: Specific completion requirements
- **Verification Commands**: Commands to test completion
- **Next Actions**: Suggested workflow steps

### **Helpful Commands**
- Task management commands
- Assignment commands
- Status checking commands

## 🚀 **Usage Examples**

### **Example 1: Quick Task Lookup**
```powershell
# Look up the first task
pwsh -File scripts/cursor-agent-task-lookup.ps1 -TaskNumber 1
```

**Output:**
```
🔍 Cursor Agent Task Lookup
🎯 Looking up task: TASK-20250923-223956-864

📋 Task Overview
Task ID: TASK-20250923-223956-864
Title: ECRR Task: 2025-09-23-223709-task-generation-framework
Assigned To: observability-engineer
Priority: medium
Category: observability
Status: pending

📝 Task Description/Prompt
## Task Description
Generated from ECRR report: 2025-09-23-223709-task-generation-framework.md

✅ Acceptance Criteria
- [ ] Framework Validation: ECRR task generation framework successfully processes sample reports
- [ ] Task Management Integration: Generated tasks integrate seamlessly with existing task management CLI
- [ ] SigNoz Verification: Observability tasks include proper SigNoz queries for verification
- [ ] Documentation Complete: Usage patterns and best practices documented for team adoption
- [ ] Duplicate Prevention: Framework prevents creation of duplicate tasks from same ECRR reports
- [ ] Error Handling: Framework handles malformed ECRR reports gracefully with proper logging

🔧 Verification Commands
```powershell
# Test framework with dry run
pwsh -File scripts/ecrr-task-automation.ps1 -MaxTasks 3 -DryRun

# Generate actual tasks from recent ECRR reports
pwsh -File scripts/ecrr-task-automation.ps1 -MaxTasks 5 -AutoAssign

# Verify task management integration
pwsh -File scripts/manage-tasks.ps1 -Action Status
pwsh -File scripts/manage-tasks.ps1 -Action List
```

🚀 Next Actions
1. Review the task requirements above
2. Understand the acceptance criteria
3. Execute verification commands to test your work
4. Follow ECRR methodology (Examine → Clean → Report → Role)
5. Update task status when complete
```

### **Example 2: List All Tasks**
```powershell
# List all available tasks
pwsh -File scripts/cursor-agent-task-lookup.ps1 -ListTasks
```

**Output:**
```
📋 Available Tasks:

  1. TASK-20250923-223956-864
     Title: ECRR Task: 2025-09-23-223709-task-generation-framework

  2. TASK-20250923-224005-235
     Title: ECRR Task: LEDGER

  3. TASK-20250923-224113-304
     Title: ECRR Task: INDEX

  ... (and more)
```

### **Example 3: Specific Task Lookup**
```powershell
# Look up a specific task by ID
pwsh -File scripts/cursor-agent-task-lookup.ps1 -TaskId TASK-20250925-041323-674
```

## 🔍 **Task Discovery Workflow**

### **For New Agents**
1. **List Available Tasks**: `pwsh -File scripts/cursor-agent-task-lookup.ps1 -ListTasks`
2. **Choose a Task**: Select a task number or ID
3. **Read Task Details**: `pwsh -File scripts/cursor-agent-task-lookup.ps1 -TaskNumber <number>`
4. **Understand Requirements**: Review task description, acceptance criteria, and verification commands
5. **Start Working**: Follow the ECRR methodology (Examine → Clean → Report → Role)

### **For Task Assignment**
1. **Check Current Assignments**: `pwsh -File scripts/manage-tasks.ps1 -Action Status`
2. **Find Unassigned Tasks**: Look for tasks with "Unassigned" status
3. **Assign Task**: `pwsh -File scripts/manage-tasks.ps1 -Action Assign -TaskId <task-id> -Assignee <agent-id>`
4. **Verify Assignment**: Check task status again

## 🎯 **Integration with Agent System**

### **Agent Startup Integration**
```powershell
# In agent startup scripts
$taskId = "TASK-20250923-223956-864"
pwsh -File scripts/cursor-agent-task-lookup.ps1 -TaskId $taskId
```

### **Task Management Integration**
```powershell
# Check task status
pwsh -File scripts/manage-tasks.ps1 -Action Status

# List all tasks
pwsh -File scripts/manage-tasks.ps1 -Action List

# Assign task to agent
pwsh -File scripts/manage-tasks.ps1 -Action Assign -TaskId <task-id> -Assignee <agent-id>
```

## 📊 **Task Categories**

The system supports various task categories:
- **Observability**: Monitoring, logging, tracing, metrics
- **Infrastructure**: System administration, deployment, configuration
- **Monitoring**: Health checks, alerts, dashboards
- **Performance**: Optimization, analysis, tuning
- **Security**: Access control, compliance, auditing

## 🔧 **Technical Details**

### **File Locations**
- **Task Files**: `jobs/pending/`, `jobs/in-progress/`, `jobs/completed/`
- **Script Location**: `scripts/cursor-agent-task-lookup.ps1`
- **Documentation**: `docs/CURSOR_AGENT_TASK_LOOKUP_GUIDE.md`

### **Parsing Logic**
- Line-by-line parsing for robust metadata extraction
- Regex pattern matching for task information
- Support for multiple task file formats
- Error handling for missing or malformed files

### **Output Formats**
- **Console Output**: Color-coded, structured display
- **Task Overview**: Key metadata in table format
- **Task Content**: Detailed requirements and instructions
- **Helpful Commands**: Ready-to-use PowerShell commands

## 🚀 **Best Practices**

### **For Agents**
1. **Always read the full task** before starting work
2. **Understand acceptance criteria** completely
3. **Test verification commands** to ensure understanding
4. **Follow ECRR methodology** (Examine → Clean → Report → Role)
5. **Update task status** when work is complete

### **For Task Management**
1. **Use descriptive task titles** for easy identification
2. **Include clear acceptance criteria** for each task
3. **Provide verification commands** for testing
4. **Keep task status updated** throughout the lifecycle
5. **Assign tasks to appropriate agents** based on specialization

## 🎉 **Success Metrics**

- **Task Discovery**: Agents can quickly find and understand tasks
- **Clear Requirements**: Task descriptions are comprehensive and actionable
- **Easy Integration**: Commands work seamlessly with existing systems
- **Robust Parsing**: Handles various task file formats correctly
- **User-Friendly**: Clear, color-coded output with helpful guidance

## 📚 **Related Documentation**

- [Cursor Agents Deployment Summary](CURSOR_AGENTS_DEPLOYMENT_SUMMARY_2025-09-25.md)
- [ECRR Methodology Guide](ECRR_METHODOLOGY_GUIDE.md)
- [Task Management System](TASK_MANAGEMENT_SYSTEM.md)
- [Agent Configuration Guide](AGENT_CONFIGURATION_GUIDE.md)

---

**Generated by**: Cursor Agent - Observability Copilot  
**Generated On**: 2025-09-25 04:30:00 UTC  
**Status**: ✅ COMPLETED
