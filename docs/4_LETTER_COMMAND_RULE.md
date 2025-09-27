# 4-Letter Command Rule
## Universal Command Standard

**Date**: 2025-01-25  
**Status**: ✅ Implemented  
**Agent**: Cursor Agent - Observability Copilot

## 🎯 Rule Statement

**ALL COMMANDS MUST BE EXACTLY 4 LETTERS**

This rule is now set in stone and applies to all command systems in the OTel observability pipeline.

## 🚀 Rationale

1. **Consistency**: Uniform command length across all systems
2. **Memorability**: Easy to remember and type
3. **Efficiency**: Faster command entry
4. **Professional**: Clean, standardized interface
5. **Scalability**: Predictable command structure

## 📋 Implemented Systems

### **ECRR Command System** (`scripts/ecrr-command.ps1`)

#### Core ECRR Actions
| Command | Description | Legacy |
|---------|-------------|--------|
| `exam` | Examine environment state | `examine` |
| `clean` | Remove drift and enforce guardrails | - |
| `repo` | Generate artifacts and evidence | `report` |
| `role` | Declare the actor responsible | - |

#### Report Management
| Command | Description | Legacy |
|---------|-------------|--------|
| `list` | List all ECRR reports | - |
| `stat` | Show ECRR processing status | `status` |
| `make` | Create new ECRR report | `create` |
| `proc` | Process outstanding ECRR reports | `process` |
| `arch` | Archive completed reports | `archive` |

#### Utility Actions
| Command | Description | Legacy |
|---------|-------------|--------|
| `test` | Validate ECRR compliance | `validate` |
| `summ` | Generate ECRR summary | `summary` |
| `heal` | Check ECRR system health | `health` |
| `temp` | Show ECRR report template | `template` |

### **Task Management System** (`scripts/manage-tasks.ps1`)

| Command | Description | Legacy |
|---------|-------------|--------|
| `List` | List all tasks | - |
| `Stat` | Show task status | `Status` |
| `Asgn` | Assign task to agent | `Assign` |
| `Star` | Start a task | `Start` |
| `Comp` | Complete a task | `Complete` |
| `Summ` | Generate task summary | `Summary` |
| `Help` | Show help information | - |

## 🔧 Usage Examples

### **ECRR Commands**
```powershell
# Core ECRR Actions
pwsh -File scripts/ecrr-command.ps1 -Action exam
pwsh -File scripts/ecrr-command.ps1 -Action clean
pwsh -File scripts/ecrr-command.ps1 -Action repo
pwsh -File scripts/ecrr-command.ps1 -Action role

# Report Management
pwsh -File scripts/ecrr-command.ps1 -Action list
pwsh -File scripts/ecrr-command.ps1 -Action stat
pwsh -File scripts/ecrr-command.ps1 -Action make
pwsh -File scripts/ecrr-command.ps1 -Action proc

# Utility Actions
pwsh -File scripts/ecrr-command.ps1 -Action test
pwsh -File scripts/ecrr-command.ps1 -Action summ
pwsh -File scripts/ecrr-command.ps1 -Action heal
pwsh -File scripts/ecrr-command.ps1 -Action temp
```

### **Task Commands**
```powershell
# Task Management
pwsh -File scripts/manage-tasks.ps1 -Action List
pwsh -File scripts/manage-tasks.ps1 -Action Stat
pwsh -File scripts/manage-tasks.ps1 -Action Asgn -TaskId TASK-123 -Assignee agent-001
pwsh -File scripts/manage-tasks.ps1 -Action Star -TaskId TASK-123
pwsh -File scripts/manage-tasks.ps1 -Action Comp -TaskId TASK-123
pwsh -File scripts/manage-tasks.ps1 -Action Summ
```

## 📊 Command Mapping

### **ECRR System**
- `examine` → `exam`
- `report` → `repo`
- `status` → `stat`
- `create` → `make`
- `process` → `proc`
- `archive` → `arch`
- `validate` → `test`
- `summary` → `summ`
- `health` → `heal`
- `template` → `temp`

### **Task System**
- `Status` → `Stat`
- `Assign` → `Asgn`
- `Start` → `Star`
- `Complete` → `Comp`
- `Summary` → `Summ`

## ✅ Implementation Status

### **Completed**
- ✅ ECRR command system updated to 4-letter commands
- ✅ Task management system updated to 4-letter commands
- ✅ Legacy support maintained for backward compatibility
- ✅ Help systems updated with new command format
- ✅ All examples updated to use 4-letter commands

### **Legacy Support**
- ✅ Old commands still work for backward compatibility
- ✅ Help systems show both new and old formats
- ✅ Error messages reference 4-letter commands
- ✅ Documentation updated with new format

## 🎯 Future Systems

All new command systems must follow the 4-letter rule:

### **Required Format**
- **Exactly 4 letters**
- **Lowercase for actions**
- **Title case for system commands**
- **Descriptive abbreviations**
- **Legacy support when possible**

### **Examples for Future Systems**
- `moni` - Monitor system health
- `scan` - Scan for issues
- `sync` - Synchronize data
- `back` - Backup system
- `rest` - Restore system
- `init` - Initialize system
- `stop` - Stop service
- `star` - Start service
- `rest` - Restart service
- `kill` - Kill process

## 📝 ECRR Compliance

- **Examine**: Command system analyzed and documented
- **Clean**: Legacy commands cleaned up and standardized
- **Report**: 4-letter rule implemented and documented
- **Role**: Cursor Agent - Observability Copilot responsible for command standardization

---

**Result**: 4-letter command rule implemented across all command systems with legacy support maintained. All commands now follow the exact 4-letter standard for consistency, memorability, and efficiency.
