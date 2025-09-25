# System Flow Diagram

## 🔄 **Complete System Architecture**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           OBSERVABILITY PIPELINE                                │
│                                                                                 │
│  Windows Event Logs  ──┐                                                       │
│  File Logs (.log)    ──┼──►  Windows OTel Collector  ──►  SigNoz Stack        │
│  Browser Logs        ──┘     (Ports: 5317/5318)         (Port: 8080/14317)    │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           TASK MANAGEMENT SYSTEMS                               │
│                                                                                 │
│  ┌─────────────────────┐              ┌─────────────────────┐                  │
│  │   ECRR REPORTS      │              │   AGENT TASKS       │                  │
│  │                     │              │                     │                  │
│  │  New Report ──┐     │              │  Enqueue Task ──┐   │                  │
│  │              │      │              │               │     │                  │
│  │  Review ─────┼──┐   │              │  Process ──────┼──┐  │                  │
│  │             │  │    │              │              │  │   │                  │
│  │  Work ──────┼──┼──┐ │              │  Validate ────┼──┼─┐│                  │
│  │            │  │  │  │              │             │  │ │ │                  │
│  │  Resolve ──┼──┼──┼─┼─► Archive    │  Complete ──┼──┼─┼─┼─► Results        │
│  │           │  │  │ │               │            │  │ │ │                  │
│  │  Index ◄──┼──┼──┼─┘               │  Cleanup ◄──┼──┼─┼─┘                  │
│  │          │  │  │                  │           │  │ │                     │
│  │  Ledger ◄┼──┼──┘                   │  Queue ◄───┼──┼─┘                     │
│  │         │  │                       │          │  │                        │
│  │  Badges ◄┼──┘                       │  State ◄──┼──┘                       │
│  │        │                           │         │                           │
│  │  Status◄┘                           │  Files ◄─┘                           │
│  └─────────────────────┘              └─────────────────────┘                  │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           INTEGRATION LAYER                                    │
│                                                                                 │
│  ECRR Reports ◄──► Agent Tasks ◄──► Observability Pipeline                     │
│                                                                                 │
│  • Task Creation    • Automated Processing    • Health Monitoring              │
│  • Status Tracking  • Validation & Testing   • Log Aggregation                │
│  • Lifecycle Mgmt   • Results Recording      • Metrics Collection             │
│  • Audit Trails     • Cleanup Automation     • Alerting System                │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 **ECRR Reports Lifecycle**

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   CREATE    │───►│   REVIEW    │───►│    WORK     │───►│   RESOLVE   │───►│   ARCHIVE   │
│             │    │             │    │             │    │             │    │             │
│ New Report  │    │ Assign &    │    │ Process     │    │ Complete    │    │ Store &     │
│ Created     │    │ Prioritize  │    │ Following   │    │ & Document  │    │ Index       │
│             │    │             │    │ ECRR Method │    │ Results     │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │                   │
       ▼                   ▼                   ▼                   ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   LEDGER    │    │   BADGES    │    │   SESSION   │    │ RESOLUTION  │    │   INDEX     │
│ Entry Added │    │ Reviewed    │    │ Tracking    │    │ Documented  │    │ Updated     │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

## 🤖 **Agent Task Lifecycle**

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   ENQUEUE   │───►│   PROCESS   │───►│  VALIDATE   │───►│  COMPLETE   │───►│   CLEANUP   │
│             │    │             │    │             │    │             │    │             │
│ Task Added  │    │ Codex       │    │ Run Tests   │    │ Record      │    │ Move to     │
│ to Queue    │    │ Execution   │    │ & Verify    │    │ Results     │    │ Archive     │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │                   │
       ▼                   ▼                   ▼                   ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   QUEUE     │    │  PROCESSING │    │   TESTS     │    │  RESULTS    │    │ ARCHIVED   │
│ JSONL File  │    │ Directory   │    │ Execution   │    │ JSONL File  │    │ Directory   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

## 📊 **Status Badge System**

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│     OPEN    │───►│   REVIEWED  │───►│ NOT WORKING │───►│   RESOLVED   │
│             │    │             │    │             │    │             │
│ ![Open]     │    │ ![Reviewed] │    │ ![Not Work] │    │ ![Resolved] │
│ (Teal)      │    │ (Purple)    │    │ (Red)       │    │ (Green)     │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       ▼                   ▼                   ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   NEW       │    │ ASSIGNED    │    │   ISSUES    │    │ COMPLETED   │
│ REPORTS     │    │ FOR REVIEW  │    │ DETECTED    │    │ & ARCHIVED  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

## 🔧 **Management Scripts**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           MANAGEMENT SCRIPTS                                   │
│                                                                                 │
│  ECRR Management:                                                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │
│  │ ecrr-manage.ps1 │  │ RegenerateIndex │  │ Update Ledger   │                │
│  │                 │  │                 │  │                 │                │
│  │ • Review        │  │ • Update Counts │  │ • Add Entries   │                │
│  │ • Start         │  │ • Sort Reports  │  │ • Update Status │                │
│  │ • Resolve       │  │ • Generate HTML │  │ • Track Sessions│                │
│  │ • Archive       │  │ • Update Badges │  │ • Record Times  │                │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                │
│                                                                                 │
│  Agent Management:                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │
│  │ enqueue-task.ps1│  │ run-codex.ps1   │  │ cleanup-tasks.ps1│                │
│  │                 │  │                 │  │                 │                │
│  │ • Create Tasks  │  │ • Process Queue │  │ • Remove Old    │                │
│  │ • Validate JSON │  │ • Execute Codex │  │ • Clean Results │                │
│  │ • Add to Queue  │  │ • Record Results│  │ • Archive Tasks │                │
│  │ • Track Status  │  │ • Update State  │  │ • Maintain Size │                │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 📈 **System Health Monitoring**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           HEALTH MONITORING                                    │
│                                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │   ECRR      │    │   AGENT     │    │ OBSERVABILITY│   │   SYSTEM   │        │
│  │   HEALTH    │    │   HEALTH    │    │   HEALTH    │    │   HEALTH   │        │
│  │             │    │             │    │             │    │            │        │
│  │ • Index OK  │    │ • Queue OK  │    │ • Collector │    │ • All      │        │
│  │ • Ledger OK │    │ • Results OK│    │   Running   │    │   Systems  │        │
│  │ • Badges OK │    │ • Tasks OK  │    │ • SigNoz OK │    │   Green    │        │
│  │ • Archive OK│    │ • State OK  │    │ • Pipeline OK│    │ • Status   │        │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘        │
│         │                   │                   │                   │            │
│         └───────────────────┼───────────────────┼───────────────────┘            │
│                             │                   │                               │
│                             ▼                   ▼                               │
│                    ┌─────────────┐    ┌─────────────┐                          │
│                    │   ALERTS    │    │ DASHBOARDS  │                          │
│                    │             │    │             │                          │
│                    │ • Issues    │    │ • Real-time │                          │
│                    │ • Failures  │    │ • Historical│                          │
│                    │ • Warnings  │    │ • Trends    │                          │
│                    │ • Status    │    │ • Metrics   │                          │
│                    └─────────────┘    └─────────────┘                          │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🎯 **Current System Status**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           CURRENT STATUS                                       │
│                                                                                 │
│  ECRR Reports:           Agent Tasks:           Observability:                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐          │
│  │ Total: 96        │    │ Completed: 1    │    │ Collector: ✅   │          │
│  │ Open: 0          │    │ Pending: 5      │    │ SigNoz: ✅      │          │
│  │ Resolved: 96     │    │ Failed: 0       │    │ Pipeline: ✅    │          │
│  │ Completion: 100% │    │ Success: 100%   │    │ Health: ✅      │          │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘          │
│                                                                                 │
│  System Health: ✅ ALL SYSTEMS OPERATIONAL                                     │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

*System Flow Diagram v1.0*  
*Last updated: 2025-09-23*
