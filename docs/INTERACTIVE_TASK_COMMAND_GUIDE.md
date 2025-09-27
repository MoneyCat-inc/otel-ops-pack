# Interactive Task Command Guide

## 🎯 **Overview**

The enhanced Cursor Agent Task Lookup command now provides an interactive interface that prompts agents to either summarize their current task or examine the first task in the queue. This makes it perfect for blank Cursor agents who need guidance on what to work on.

## 🤖 **Interactive Agent Assistant**

### **Default Behavior**
When you run the command without parameters, it presents an interactive menu:

```powershell
pwsh -File scripts/cursor-agent-task-lookup.ps1
```

**Output:**
```
🔍 Cursor Agent Task Lookup
🤖 Agent Task Assistant
What would you like to do?

1. 📋 Summarize my current task (if assigned)
2. 🔍 Examine the first task in the queue
3. 📝 List all available tasks
4. ❌ Exit

Enter your choice (1-4):
```

## 🎯 **Command Options**

### **1. Summarize Current Task**
**Choice**: `1` or `-Summarize`

**What it does:**
- Looks for tasks assigned to the current agent
- Displays task details in plain English
- Shows task status, priority, and description
- Falls back to examining first task if no assignments found

**Example Output:**
```
📋 Current Task Summary
✅ Found 1 task(s) assigned to agent: cursor-ecrr-agent-001

📋 Task: TASK-20250923-223956-864
   Title: ECRR Task: 2025-09-23-223709-task-generation-framework
   Priority: medium
   Status: pending

📝 Task Description (Plain English):
   Generated from ECRR report: 2025-09-23-223709-task-generation-framework.md
   This task involves implementing and validating an ECRR task generation framework
   that processes sample reports and creates structured tasks.
```

### **2. Examine First Task**
**Choice**: `2` or `-ExamineFirst`

**What it does:**
- Shows the first task in the queue (task #1)
- Displays complete task details including:
  - Task overview (ID, title, assignee, priority, category, status)
  - Task description/prompt
  - Acceptance criteria
  - Verification commands
  - Next actions

**Example Output:**
```
🔍 Examining First Task in Queue
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
```

### **3. List All Tasks**
**Choice**: `3` or `-ListTasks`

**What it does:**
- Shows all available tasks with numbers and titles
- Provides easy reference for task selection
- Shows task IDs and brief descriptions

**Example Output:**
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

### **4. Exit**
**Choice**: `4`

**What it does:**
- Exits the command gracefully
- Shows goodbye message

## 🔧 **Direct Command Usage**

### **Non-Interactive Mode**
```powershell
# Disable interactive mode
pwsh -File scripts/cursor-agent-task-lookup.ps1 -Interactive:$false -TaskNumber 1

# Direct commands
pwsh -File scripts/cursor-agent-task-lookup.ps1 -Summarize
pwsh -File scripts/cursor-agent-task-lookup.ps1 -ExamineFirst
pwsh -File scripts/cursor-agent-task-lookup.ps1 -ListTasks
```

### **Specific Task Lookup**
```powershell
# Look up specific task by number
pwsh -File scripts/cursor-agent-task-lookup.ps1 -TaskNumber 2

# Look up specific task by ID
pwsh -File scripts/cursor-agent-task-lookup.ps1 -TaskId TASK-20250923-223956-864
```

## 🎯 **Perfect for Blank Agents**

### **Agent Workflow**
1. **Start the command**: `pwsh -File scripts/cursor-agent-task-lookup.ps1`
2. **Choose option 1** to see if you have any assigned tasks
3. **If no assigned tasks**, choose option 2 to examine the first available task
4. **Review the task details** and understand what needs to be done
5. **Follow the verification commands** to test your work
6. **Use the helpful commands** to manage the task

### **Key Benefits for Blank Agents**
- **Guided Experience**: Interactive menu prevents confusion
- **Plain English Descriptions**: Easy to understand what needs to be done
- **Complete Context**: All task information in one place
- **Ready-to-Use Commands**: Copy-paste verification commands
- **Fallback Options**: Always shows available work if no assignments

## 📊 **Agent Detection**

### **Current Agent Identification**
The command tries to identify the current agent using:
1. `$env:AGENT_ID` environment variable
2. Falls back to "unknown-agent" if not set

### **Task Assignment Matching**
- Looks for tasks assigned to the current agent
- Supports partial matching (e.g., "cursor-agent" matches "cursor-ecrr-agent-001")
- Shows all assigned tasks if multiple found

## 🔧 **Technical Features**

### **Robust Parsing**
- Line-by-line parsing for reliable metadata extraction
- Handles multiple task file formats
- Error handling for missing or malformed files

### **Smart Fallbacks**
- If no tasks assigned → automatically shows first available task
- If task not found → provides helpful error messages
- If parsing fails → shows raw content with verbose mode

### **Comprehensive Display**
- Color-coded output for easy reading
- Structured sections for different information types
- Progress indicators and status messages

## 🚀 **Usage Examples**

### **For New Agents**
```powershell
# Start with interactive mode
pwsh -File scripts/cursor-agent-task-lookup.ps1
# Choose option 2 to examine first task
```

### **For Assigned Agents**
```powershell
# Check your current assignments
pwsh -File scripts/cursor-agent-task-lookup.ps1 -Summarize
```

### **For Task Management**
```powershell
# List all available tasks
pwsh -File scripts/cursor-agent-task-lookup.ps1 -ListTasks

# Examine specific task
pwsh -File scripts/cursor-agent-task-lookup.ps1 -TaskNumber 5
```

## 📚 **Integration with Agent System**

### **Agent Startup Integration**
```powershell
# In agent startup scripts
Write-Host "🤖 Starting agent task discovery..."
pwsh -File scripts/cursor-agent-task-lookup.ps1
```

### **Task Assignment Integration**
```powershell
# After assigning a task
pwsh -File scripts/manage-tasks.ps1 -Action Assign -TaskId $taskId -Assignee $agentId
pwsh -File scripts/cursor-agent-task-lookup.ps1 -Summarize
```

## 🎉 **Success Metrics**

- ✅ **Interactive Interface**: User-friendly menu system
- ✅ **Task Summarization**: Plain English task descriptions
- ✅ **First Task Examination**: Complete task details and requirements
- ✅ **Agent Detection**: Automatic current agent identification
- ✅ **Robust Parsing**: Reliable metadata extraction
- ✅ **Smart Fallbacks**: Graceful handling of edge cases
- ✅ **Comprehensive Help**: Built-in help and usage examples

## 🔧 **Command Reference**

| Command | Description | Example |
|---------|-------------|---------|
| `pwsh -File scripts/cursor-agent-task-lookup.ps1` | Interactive mode | Default behavior |
| `-Summarize` | Summarize current agent's tasks | `-Summarize` |
| `-ExamineFirst` | Examine first task in queue | `-ExamineFirst` |
| `-ListTasks` | List all available tasks | `-ListTasks` |
| `-TaskNumber N` | Look up task by number | `-TaskNumber 1` |
| `-TaskId ID` | Look up specific task by ID | `-TaskId TASK-123` |
| `-Interactive:$false` | Disable interactive mode | `-Interactive:$false` |
| `-Verbose` | Show full task content | `-Verbose` |

---

**Generated by**: Cursor Agent - Observability Copilot  
**Generated On**: 2025-09-25 04:45:00 UTC  
**Status**: ✅ COMPLETED
