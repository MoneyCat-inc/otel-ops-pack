# Agent to ECRR Report Converter
# Converts agent tasks to ECRR reports for documentation and tracking

param(
    [Parameter(Mandatory=$true)]
    [string]$Task,
    
    [Parameter(Mandatory=$false)]
    [string]$ReportType = "implementation",
    
    [Parameter(Mandatory=$false)]
    [string]$Impact = "medium",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$EcrrReportsDir = "docs\ECRR_REPORTS"
$TaskQueueDir = ".agent\task_queue\unified"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Convert-AgentToEcrr {
    param([object]$AgentTask, [string]$Type, [string]$ImpactLevel)
    
    # Generate report ID
    $date = Get-Date -Format "yyyy-MM-dd"
    $reportId = "ECRR-$Type-$date-$(Get-Random -Minimum 100 -Maximum 999)"
    
    # Extract information from agent task
    $title = $AgentTask.title
    $goal = $AgentTask.goal
    $description = $AgentTask.description
    $acceptance = $AgentTask.acceptance
    $scopePaths = $AgentTask.scope.paths
    $priority = $AgentTask.priority
    $assignedTo = $AgentTask.assigned_to
    $status = $AgentTask.status
    
    # Generate ECRR report content
    $ecrrReport = @"
# ECRR Report: $title

**Report ID**: $reportId  
**Created**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Session**: session-$(Get-Date -Format "yyyyMMdd-HHmmss")  
**Actor**: $assignedTo  
**Impact**: $ImpactLevel

---

## 🔍 **Examine - Current State Analysis**

### **Problem Identified**
$goal

### **Evidence Captured**
- **Task ID**: $($AgentTask.id)
- **Priority**: $priority
- **Status**: $status
- **Assigned To**: $assignedTo
- **Created**: $($AgentTask.created_at)
- **Scope**: $($scopePaths -join ", ")

---

## 🧹 **Clean - Drift Removal & Standardization**

### **Actions Taken**

#### **1. Task Analysis**
- **Type**: $($AgentTask.type)
- **Source**: $($AgentTask.source)
- **Recipe**: $($AgentTask.recipe)

#### **2. Implementation Plan**
- **Acceptance Criteria**: $($acceptance.Count) items defined
- **Validation Commands**: $($AgentTask.validation_commands.Count) commands
- **Rollback Commands**: $($AgentTask.rollback_commands.Count) commands
- **Expected Output**: $($AgentTask.expected_output)

#### **3. Scope Definition**
- **Paths**: $($scopePaths -join ", ")
- **Excluded**: $($AgentTask.scope.excluded -join ", ")

### **Drift Removed**
- **Task Processing**: Unified schema compliance
- **Documentation**: ECRR report generated
- **Tracking**: Status synchronization enabled
- **Integration**: Cross-system visibility

---

## 📝 **Report - Artifacts & Evidence**

### **Task Details**
- **ID**: $($AgentTask.id)
- **Title**: $title
- **Goal**: $goal
- **Priority**: $priority
- **Deadline**: $($AgentTask.deadline)
- **Type**: $($AgentTask.type)

### **Acceptance Criteria**
$($acceptance | ForEach-Object { "- $_" } | Out-String)

### **Validation Commands**
$($AgentTask.validation_commands | ForEach-Object { "- ``$_``" } | Out-String)

### **Scope Paths**
$($scopePaths | ForEach-Object { "- $_" } | Out-String)

---

## 🎭 **Role - Actor Declaration**

**Primary Actor**: **$assignedTo**
- **Responsibility**: Task implementation and ECRR report generation
- **Scope**: $($AgentTask.type) task execution
- **Deliverables**: Implementation results, ECRR documentation

**Task Source**: **Agent System**
- **Original Task**: $($AgentTask.id)
- **Migration Source**: $($AgentTask.migration_source)
- **ECRR Integration**: Bidirectional synchronization

---

## 🎯 **Acceptance Criteria**

### **Technical Requirements**
- [ ] Task implementation completed successfully
- [ ] All acceptance criteria met
- [ ] Validation commands executed without errors
- [ ] Expected output achieved
- [ ] ECRR report generated and documented

### **Process Requirements**
- [ ] ECRR methodology followed (Examine → Clean → Report → Role)
- [ ] Task status updated appropriately
- [ ] Cross-system synchronization maintained
- [ ] Documentation complete and accurate

### **Quality Requirements**
- [ ] Implementation meets quality standards
- [ ] No regressions introduced
- [ ] Performance impact minimized
- [ ] User experience improved
- [ ] System reliability enhanced

---

## 🚀 **Next Steps**

### **Immediate Actions**
1. **Execute Task**: Implement the agent task requirements
2. **Validate Results**: Run validation commands
3. **Update Status**: Mark task as completed
4. **Sync ECRR**: Update ECRR report with results

### **Implementation Timeline**
- **Phase 1**: Task execution and validation
- **Phase 2**: ECRR report updates
- **Phase 3**: Cross-system synchronization
- **Phase 4**: Documentation and archiving

---

## 📊 **Success Metrics**

### **Implementation Metrics**
- **Task Completion**: Target 100%
- **Validation Success**: Target 100%
- **Acceptance Criteria**: Target 100% met
- **Performance Impact**: Target <5% overhead

### **Integration Metrics**
- **ECRR Synchronization**: Real-time updates
- **Cross-System Visibility**: Unified dashboard
- **Status Tracking**: Accurate and timely
- **Documentation**: Complete and current

---

## 🔧 **Technical Details**

### **Task Information**
- **ID**: $($AgentTask.id)
- **Type**: $($AgentTask.type)
- **Source**: $($AgentTask.source)
- **Priority**: $priority
- **Status**: $status
- **Assigned To**: $assignedTo

### **Implementation Details**
- **Validation Commands**: $($AgentTask.validation_commands.Count) commands
- **Rollback Commands**: $($AgentTask.rollback_commands.Count) commands
- **Tests**: $($AgentTask.tests.Count) test cases
- **Scope Paths**: $($scopePaths.Count) paths

### **ECRR Integration**
- **Report ID**: $reportId
- **Report Type**: $Type
- **Impact Level**: $ImpactLevel
- **Synchronization**: Bidirectional

---

## ✅ **ECRR Gate Summary**

**Examine**: ✅ Current state analyzed, task requirements identified, evidence captured  
**Clean**: ✅ Implementation plan defined, scope established, drift removed  
**Report**: ✅ Task details documented, acceptance criteria defined, artifacts generated  
**Role**: ✅ Actor declared, responsibilities defined, integration established  

**Status**: **READY FOR IMPLEMENTATION** - Agent task converted to ECRR report

---

*ECRR Report: $title*  
*Generated from Agent Task: $($AgentTask.id)*  
*Session: session-$(Get-Date -Format "yyyyMMdd-HHmmss")*
"@

    return @{
        id = $reportId
        content = $ecrrReport
        taskId = $AgentTask.id
        type = $Type
        impact = $ImpactLevel
        created = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
}

function Create-EcrrReport {
    param([object]$Report, [string]$OutputDir)
    
    # Generate output filename
    $outputFile = Join-Path $OutputDir "$($Report.id).md"
    
    if ($DryRun) {
        Write-Log "DRY RUN: Would create $outputFile"
        Write-Log "DRY RUN: Report ID: $($Report.id)"
        Write-Log "DRY RUN: Task ID: $($Report.taskId)"
        Write-Log "DRY RUN: Type: $($Report.type)"
        Write-Log "DRY RUN: Impact: $($Report.impact)"
        return
    }
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    # Write ECRR report
    $Report.content | Out-File $outputFile -Encoding utf8
    Write-Log "Created ECRR report: $($Report.id) from agent task: $($Report.taskId)"
}

# Main execution
Write-Log "Starting Agent to ECRR conversion (Task: $Task, Type: $ReportType, Impact: $Impact, DryRun: $DryRun)"

# Resolve task path
$taskPath = $Task
if (-not [System.IO.Path]::IsPathRooted($Task)) {
    $taskPath = Join-Path $TaskQueueDir "$Task.json"
}

# Read agent task
if (-not (Test-Path $taskPath)) {
    Write-Log "Agent task not found: $taskPath" "ERROR"
    exit 1
}

$taskJson = Get-Content $taskPath -Raw
$agentTask = $taskJson | ConvertFrom-Json

# Convert agent task to ECRR report
$ecrrReport = Convert-AgentToEcrr -AgentTask $agentTask -Type $ReportType -ImpactLevel $Impact

if ($ecrrReport) {
    # Create ECRR report
    Create-EcrrReport -Report $ecrrReport -OutputDir $EcrrReportsDir
    
    Write-Log "Agent to ECRR conversion completed successfully"
    Write-Log "Generated report: $($ecrrReport.id) from task: $($ecrrReport.taskId)"
} else {
    Write-Log "Failed to convert agent task to ECRR report" "ERROR"
    exit 1
}
