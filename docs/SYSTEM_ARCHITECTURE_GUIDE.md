# System Architecture Guide - Complete System Overview

## 🏗️ **System Architecture Overview**

The system consists of **two integrated subsystems** working together to provide comprehensive task management and observability:

1. **ECRR Reports System** - Comprehensive lifecycle management with status tracking
2. **Agent Task System** - Automated task processing and execution
3. **Observability Pipeline** - Windows OpenTelemetry Collector + SigNoz monitoring

---

## 🔄 **ECRR Reports System**

### **Core Components**

#### **1. Lifecycle Management**
```
New Report → Review → Work → Resolve → Archive
```

**Directories**:
- `docs/ECRR_REPORTS/` - Root directory
- `docs/ECRR_REPORTS/reviewed/` - Reports under review
- `docs/ECRR_REPORTS/working/` - Active work reports
- `docs/ECRR_REPORTS/archive/` - Completed reports

#### **2. Ledger System**
**File**: `docs/ECRR_REPORTS/ledger.json`
```json
{
  "report": "archive/2025-09-23-example.md",
  "title": "ECRR Report: Example Task",
  "status": "Archived",
  "assigned": "system-architect",
  "priority": "high",
  "created": "2025-09-23 19:25:05",
  "started": "2025-09-23 19:37:53",
  "completed": "2025-09-23 21:39:26",
  "notes": "Task completed successfully",
  "resolution": "All acceptance criteria met",
  "session": "session-20250923-194926"
}
```

#### **3. Status Badge System**
**Location**: `docs/assets/badges/`
- **Open**: ![Open](../assets/badges/open.svg) - New reports
- **Reviewed**: ![Reviewed](../assets/badges/reviewed.svg) - Under review
- **Not Working**: ![Not Working](../assets/badges/not-working.svg) - Issues
- **Resolved**: ![Resolved](../assets/badges/resolved.svg) - Completed

#### **4. Index Management**
**File**: `docs/ECRR_REPORTS/INDEX.md`
- Status-sorted directory with badge counts
- Chronological index with timestamps
- Automatic regeneration via management scripts

### **ECRR Methodology**
Every report follows the **Examine → Clean → Report → Role** framework:

1. **🔍 Examine**: Capture environment state before changes
2. **🧹 Clean**: Remove drift and enforce guardrails
3. **📝 Report**: Generate artifacts and evidence
4. **🎭 Role**: Declare the actor responsible

---

## 🤖 **Agent Task System**

### **Core Components**

#### **1. Task Creation**
**Script**: `.agent/scripts/enqueue-task.ps1`
```powershell
pwsh -File .agent/scripts/enqueue-task.ps1 '{"id":"T-2025-09-23-001","title":"Task Title","goal":"Task Goal","acceptance":["criteria1","criteria2"],"scope":{"paths":["file1.txt"]},"priority":"H","deadline":"2025-09-23","tests":["test1","test2"]}'
```

#### **2. Task Processing**
**Script**: `.agent/scripts/run-codex.ps1`
- Reads from `.agent/state/queue.jsonl`
- Processes tasks through codex system
- Records results in `.agent/state/results.jsonl`

#### **3. Task Lifecycle**
```
Enqueue → Process → Validate → Complete → Cleanup
```

**Directories**:
- `.agent/task_queue/pending/` - New tasks waiting
- `.agent/task_queue/processing/` - Currently being worked on
- `.agent/task_queue/completed/` - Successfully completed
- `.agent/task_queue/failed/` - Failed processing

#### **4. Results Tracking**
**File**: `.agent/state/results.jsonl`
```json
{
  "id": "T-2025-09-23-001",
  "title": "ECRR Reports Processing Complete",
  "status": "completed",
  "timestamp": "2025-09-23T22:13:00Z",
  "outcome": "success",
  "tests_passed": 3,
  "tests_failed": 0,
  "evidence": {"test1": "success", "test2": "running"},
  "resolution": "All acceptance criteria met"
}
```

---

## 🔧 **Management Scripts**

### **ECRR Management**
**Script**: `scripts/ecrr-manage.ps1`

**Actions**:
```powershell
# Review a report
pwsh -File scripts/ecrr-manage.ps1 -Action Review -Report "report.md" -Assign "team-member" -Priority "high"

# Start working on a report
pwsh -File scripts/ecrr-manage.ps1 -Action Start -Report "report.md"

# Resolve a report
pwsh -File scripts/ecrr-manage.ps1 -Action Resolve -Report "report.md" -Resolution "completed"

# Regenerate index
pwsh -File scripts/ecrr-manage.ps1 -Action RegenerateIndex
```

### **Agent Management**
**Scripts**: `.agent/scripts/`

**Task Creation**:
```powershell
pwsh -File .agent/scripts/enqueue-task.ps1 '{"id":"T-2025-09-23-001",...}'
```

**Task Processing**:
```powershell
pwsh -File .agent/scripts/run-codex.ps1
```

**Task Cleanup**:
```powershell
pwsh -File .agent/scripts/cleanup-tasks.ps1 -Type "completed" -DaysOld 30
```

---

## 📊 **Observability Pipeline**

### **Components**

#### **1. Windows OpenTelemetry Collector**
**Service**: `otelcol-contrib`
**Ports**: 
- 5317 (gRPC OTLP)
- 5318 (HTTP OTLP)
- 13134 (Health Check)

**Configuration**: `config.yaml`
```yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:5318
      grpc:
        endpoint: 0.0.0.0:5317

exporters:
  otlp/sigz:
    endpoint: "localhost:14317"
    tls:
      insecure: true
```

#### **2. SigNoz Stack**
**UI**: `http://localhost:8080`
**OTLP Endpoints**: 
- 14317 (gRPC)
- 14318 (HTTP)

**Services**:
- SigNoz UI
- SigNoz Collector
- ClickHouse Database
- All running in Docker containers

#### **3. Monitoring Scripts**
- `canary-check.ps1` - Generate test logs and traces
- `quick-monitor.ps1` - Fast health check
- `verify-pipeline.ps1` - End-to-end validation

---

## 🔄 **System Integration**

### **ECRR + Agent Integration**
1. **Task Creation**: Agent system can create ECRR reports
2. **Processing**: ECRR reports can generate agent tasks
3. **Tracking**: Both systems maintain separate but complementary ledgers
4. **Cleanup**: Coordinated cleanup processes

### **Observability Integration**
1. **Monitoring**: All system components monitored via SigNoz
2. **Logging**: ECRR and agent activities logged to observability pipeline
3. **Health Checks**: Regular health monitoring of all components
4. **Alerting**: SigNoz alerts for system issues

---

## 🚀 **System Workflow**

### **Typical ECRR Workflow**
1. **Create Report**: New ECRR report created
2. **Review**: Report moved to reviewed directory
3. **Work**: Report moved to working directory
4. **Process**: Work completed following ECRR methodology
5. **Resolve**: Report resolved and moved to archive
6. **Index**: Index regenerated with updated status

### **Typical Agent Workflow**
1. **Enqueue**: Task created and added to queue
2. **Process**: Task picked up by codex system
3. **Execute**: Task executed with validation
4. **Record**: Results recorded in results file
5. **Cleanup**: Task moved to completed/failed directory

### **Integrated Workflow**
1. **ECRR Report**: Created for system issue
2. **Agent Task**: Generated from ECRR report
3. **Processing**: Agent executes task
4. **ECRR Update**: ECRR report updated with results
5. **Archive**: Both systems archive completed work

---

## 🛠️ **System Health Monitoring**

### **Health Checks**
```powershell
# Windows Collector
sc query otelcol-contrib

# SigNoz Health
Test-NetConnection -ComputerName localhost -Port 8080

# ECRR System
pwsh -File scripts/ecrr-manage.ps1 -Action RegenerateIndex

# Agent System
pwsh -File .agent/scripts/cleanup-tasks.ps1 -DryRun
```

### **Status Indicators**
- **ECRR Reports**: 96 total, 0 open, 96 resolved (100% completion)
- **Agent Tasks**: 1 completed, 5 pending
- **Observability**: Windows collector running, SigNoz operational
- **System Health**: All components green

---

## 📋 **System Capabilities**

### **ECRR System**
- ✅ Comprehensive lifecycle management
- ✅ Status badges and visual indicators
- ✅ Automated index generation
- ✅ Detailed audit trails
- ✅ Role-based assignment
- ✅ Session tracking

### **Agent System**
- ✅ Automated task processing
- ✅ Structured task creation
- ✅ Validation and testing
- ✅ Results tracking
- ✅ Cleanup automation
- ✅ Integration with ECRR

### **Observability Pipeline**
- ✅ Real-time monitoring
- ✅ Log aggregation
- ✅ Metrics collection
- ✅ Health monitoring
- ✅ Alerting system
- ✅ Dashboard visualization

---

## 🎯 **System Benefits**

### **Unified Management**
- Single system for all task management
- Consistent methodology across all work
- Comprehensive audit trails
- Automated processing and cleanup

### **Observability**
- Complete system visibility
- Real-time health monitoring
- Automated alerting
- Historical data retention

### **Automation**
- Automated task processing
- Automated cleanup and maintenance
- Automated health checks
- Automated reporting

### **Scalability**
- Modular architecture
- Configurable retention policies
- Extensible task types
- Flexible integration points

---

## 🔧 **Maintenance Procedures**

### **Daily**
- Check system health status
- Review pending tasks
- Monitor observability pipeline

### **Weekly**
- Run task cleanup scripts
- Regenerate ECRR index
- Review system performance

### **Monthly**
- Archive old completed tasks
- Review and update retention policies
- Analyze system usage patterns

---

*System Architecture Guide v1.0*  
*Last updated: 2025-09-23*
