<div align="center">

# 🐾 Resonai [OTel] Observability Platform

**Production-Ready Windows → OTel Collector → SigNoz Pipeline**

[![ECRR Compliant](https://img.shields.io/badge/ECRR-Compliant-7c5cff?style=for-the-badge&logo=gitbook&logoColor=white)](./docs/AGENTS.md)
[![Production Ready](https://img.shields.io/badge/Status-Production-4caf50?style=for-the-badge)](./docs/status.html)
[![BossCat OEM](https://img.shields.io/badge/BossCat-OEM%20Certified-ffc107?style=for-the-badge)](./docs/BossCat/README.md)

[![SigNoz Automation](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/signoz-automation.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/signoz-automation.yml)
[![CodeQL](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/codeql.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/codeql.yml)
[![Gitleaks](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/gitleaks.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/gitleaks.yml)

**77× throughput uplift** • **<200ms latency** • **99.97% success rate** • **~50% noise reduction**

[📊 Live Dashboard](./docs/dashboards/live-metrics.html) • [🧪 Test Harness](./docs/dashboards/test-harness.html) • [📖 Documentation](./docs/index.html) • [🏠 Project Hub](./index.html)

</div>

---

## 🎯 Overview

Complete observability solution for Windows environments with OpenTelemetry and SigNoz. Features GPU-accelerated processing, comprehensive chaos engineering, and ECRR compliance framework.

### **Key Features**

- **🚀 77× Throughput Uplift** — From 2.5 to 196.7 logs/sec
- **⚡ Sub-200ms Latency** — Optimized batch processing
- **🎮 GPU Acceleration** — nvCOMP compression + cuDF aggregation
- **🔒 Enterprise Security** — CVE scanning, credential rotation, compliance
- **🧪 Chaos Engineering** — Built-in test harness and fault injection
- **📊 Real-Time Monitoring** — Executive dashboards and live metrics
- **🐱 BossCat Governance** — ECRR framework with automated compliance

---

## 📐 System Architecture

```
┌─────────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  User Workstation   │───▶│  OTel Collector  │───▶│     SigNoz      │
│  (Windows 11 + GPU) │    │   (Port 5318)    │    │  (WSL2 Docker)  │
└─────────────────────┘    └──────────────────┘    └─────────────────┘
         │                          │                        │
    ┌────┴────┐              ┌──────┴──────┐          ┌──────┴──────┐
    │ Event   │              │ GPU Sidecars│          │  ClickHouse │
    │ Logs    │              │  8001/8002  │          │   Database  │
    │ Files   │              │  (nvCOMP)   │          │     UI      │
    └─────────┘              └─────────────┘          └─────────────┘
```

**[📐 View Complete Architecture](./docs/BossCat/SYSTEM_ARCHITECTURE_DIAGRAM.md)** with 77× uplift details and three-loop control system.

---

## ⚡ Quick Start

### **Prerequisites**

- Windows 11 with PowerShell 7+
- Docker Desktop with WSL2 integration
- Administrator rights (for collector service)

### **Installation (3 Commands)**

```powershell
# 1. Start SigNoz stack
docker-compose up -d

# 2. Start Windows OTel Collector
sc start otelcol-contrib

# 3. Verify pipeline
pwsh -File scripts/verify-pipeline.ps1
```

**Expected**: Logs flowing to SigNoz within 30 seconds.

### **Verify Installation**

```powershell
# Open SigNoz UI
Start-Process "http://localhost:8080"

# Send test log
pwsh -File scripts/canary-test.ps1

# View in SigNoz Logs Explorer
# Filter: message contains "canary"
```

---

## 📊 Dashboards & Interfaces

| Dashboard | Purpose | Link |
|-----------|---------|------|
| **🏠 Project Hub** | Central navigation for all projects | [index.html](./index.html) |
| **📈 Executive Dashboard** | KPIs, roadmap heatmap, ECRR compliance | [docs/status.html](./docs/status.html) |
| **🎛️ Live Metrics** | Real-time pipeline monitoring | [docs/dashboards/live-metrics.html](./docs/dashboards/live-metrics.html) |
| **🧪 Test Harness** | Signal generation & chaos engineering | [docs/dashboards/test-harness.html](./docs/dashboards/test-harness.html) |
| **🔍 SigNoz UI** | Query logs, traces, metrics | [localhost:8080](http://localhost:8080) |
| **📚 Documentation Hub** | Searchable docs index | [docs/index.html](./docs/index.html) |

---

## 🏗️ Project Structure

```
C:\otel\
├── index.html                    # Project hub (central navigation)
├── README.md                     # This file
├── docker-compose.yml            # SigNoz stack
├── config.yaml                   # OTel Collector configuration
│
├── scripts/                      # PowerShell automation
│   ├── canary-test.ps1          # Generate test logs
│   ├── verify-pipeline.ps1      # Health validation
│   ├── monitor-optimized-pipeline.ps1
│   └── quick-monitor.ps1
│
├── docs/
│   ├── index.html               # Documentation hub (searchable)
│   ├── status.html              # Executive dashboard
│   ├── assets/
│   │   └── resonai-system.css  # Unified design system
│   ├── dashboards/
│   │   ├── live-metrics.html   # Real-time monitoring
│   │   └── test-harness.html   # Chaos engineering
│   ├── BossCat/                 # Operations & governance
│   ├── comfort-cat/             # Design guidelines
│   └── ...
│
├── artifacts/                    # Generated reports & exports
└── config/                       # Additional configurations
```

---

## 🚀 Common Commands

```powershell
# Health check (fast)
pwsh -File scripts/quick-monitor.ps1

# Detailed monitoring (10 minutes)
pwsh -File scripts/monitor-optimized-pipeline.ps1 -DurationMinutes 10

# Generate test data
pwsh -File scripts/canary-test.ps1

# End-to-end verification
pwsh -File scripts/verify-pipeline.ps1

# Start all services
docker-compose up -d
sc start otelcol-contrib

# Stop all services
docker-compose down
sc stop otelcol-contrib
```

---

## 📈 Performance Metrics

| Metric | Baseline | Optimized | Improvement |
|--------|----------|-----------|-------------|
| **Throughput** | 2.5 logs/sec | 196.7 logs/sec | **77× faster** |
| **Batch Latency** | 5000ms | 200ms | **25× faster** |
| **Noise Reduction** | 0% | ~50% | **2× efficiency** |
| **Queue Depth** | Variable | 0% | **∞ headroom** |
| **Success Rate** | 85% | 99.97% | **17% improvement** |
| **GPU Utilization** | 0% | 16-23% | **Optimal range** |

---

## 🧪 Testing & Validation

### **Test Harness**

```bash
# Open test harness
start docs/dashboards/test-harness.html

# Or use quick link
start index.html
# → Testing & QA → Test Harness
```

**Features:**
- 🌊 Laminar flow (steady-state testing)
- 🌀 Chaotic flow (stress testing)
- 🧪 Test signals (integration testing)
- 🐤 Canary tests (deployment validation)
- 🛑 Stop signals (emergency halt)

### **Chaos Engineering Scenarios**

- Network delay (200-500ms)
- Service unavailability
- Memory pressure (87% utilization)
- CPU throttling (94% load)
- Disk exhaustion (98% full)
- Packet loss (10% drop rate)

---

## 📚 Documentation

### **📖 Core Guides**

- **[Quick Start Card](./docs/BossCat/QUICK_START_CARD.md)** — Get running in under 5 minutes
- **[User Guide](./docs/BossCat/PROJECT_HUB_USER_GUIDE.md)** — Complete operational manual
- **[Troubleshooting](./docs/TROUBLESHOOTING.md)** — Common issues and fixes
- **[System Architecture](./docs/BossCat/SYSTEM_ARCHITECTURE_DIAGRAM.md)** — 77× uplift design

### **🔧 Operations**

- **[BossCat Operations](./docs/BossCat/README.md)** — Executive oversight framework
- **[ECRR Framework](./docs/AGENTS.md)** — Examine → Clean → Report → Role
- **[IONA Controller](./docs/IONA_SIGNOZ_INTEGRATION.md)** — Coordination layer
- **[Runbook Index](./docs/RUNBOOK_INDEX.md)** — All operational procedures

### **🧪 Testing**

- **[Data Room Guide](./docs/BossCat/DATA_ROOM_GUIDE.md)** — Complete test harness manual
- **[QA Checklist](./docs/qa-checklist.md)** — Quality assurance steps
- **[Tetragrammaton](./docs/TETRAGRAMMATON_USER_GUIDE.md)** — Cross-language testing

### **🔒 Security**

- **[Security Policy](./docs/SECURITY.md)** — Vulnerability reporting
- **[Maintenance Guide](./docs/BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md)** — Security operations
- **[Rotation Calendar](./docs/BossCat/CREDENTIAL_ROTATION_CALENDAR.md)** — Scheduled rotations

**[📚 Browse All Documentation](./docs/index.html)** — Searchable documentation hub

---

## 🐱 BossCat ECRR Framework

All changes follow the **ECRR** (Examine → Clean → Report → Role) methodology:

1. **Examine** — Capture environment state before changes
2. **Clean** — Remove drift and enforce guardrails
3. **Report** — Generate artifacts and evidence
4. **Role** — Declare the actor responsible

**[Learn More](./docs/AGENTS.md)** about the BossCat agent framework and governance model.

---

## 🔐 Security

### **Current Status**

- ✅ CodeQL scanning enabled
- ✅ Gitleaks secret detection
- ✅ Dependabot alerts active
- ⚠️ [5 vulnerabilities detected](https://github.com/MoneyCat-inc/otel-ops-pack/security/dependabot) (3 high, 2 moderate)

### **Reporting Vulnerabilities**

See [SECURITY.md](./docs/SECURITY.md) for responsible disclosure procedures.

---

## 🤝 Contributing

1. **Run hygiene checks:**
   ```bash
   npm run hygiene
   ```

2. **Follow ECRR methodology:**
   ```powershell
   pwsh -File scripts/ecrr-doctor.ps1  # Examine
   # Make changes                        # Clean
   # Generate artifacts                  # Report
   # Declare your role in commit        # Role
   ```

3. **Commit with ECRR format:**
   ```
   <type>(scope): <subject>
   
   ECRR: Examine - <what you found>
   ECRR: Clean - <what you fixed>
   ECRR: Report - <evidence/metrics>
   ECRR: Role - <your agent role>
   ```

**[📋 Contribution Guidelines](./docs/COMMIT_GUIDE.md)**

---

## 🆘 Troubleshooting

### **Services Not Running**

```powershell
# Check Docker
docker ps | findstr signoz

# Check OTel Collector
Get-Service otelcol-contrib

# Restart everything
docker-compose restart
sc stop otelcol-contrib && sc start otelcol-contrib
```

### **No Logs in SigNoz**

```powershell
# Send test log
pwsh -File scripts/canary-test.ps1

# Check in SigNoz UI
Start-Process "http://localhost:8080"
# Filter: message contains "canary"
```

### **JSON Parse Errors**

```bash
# Use send-only data room (bypasses API)
start docs/dashboards/test-harness.html

# Or run debug diagnostics
start docs/BossCat/data_room_iona_debug.html
```

**[🔧 Full Troubleshooting Guide](./docs/TROUBLESHOOTING.md)**

---

## 📊 Status & Health

| Component | Status | Port | Health |
|-----------|--------|------|--------|
| **Windows OTel Collector** | ✅ Running | 5317/5318 | Auto-start |
| **SigNoz Frontend** | ✅ Running | 8080 | 40h uptime |
| **SigNoz Query Service** | ✅ Running | - | Healthy |
| **ClickHouse** | ✅ Running | 8123/9000 | Healthy |
| **GPU Compression** | ✅ Running | 8001 | Optimal |
| **GPU Aggregation** | ✅ Running | 8002 | Optimal |

**[📈 View Live Status](./docs/status.html)** — Real-time KPIs and roadmap heatmap

---

## 🌟 Highlights

### **77× Throughput Uplift**

Optimized pipeline delivers **196.7 logs/sec** (up from 2.5 baseline) through:
- Batch processing tuning (200ms windows)
- Noise filtering (~50% reduction)
- GPU-accelerated compression (nvCOMP)
- Parallel aggregation (cuDF)

### **Three-Loop Control System**

- **Policy Loop** — ECRR gates, security baselines, compliance
- **Evaluation Loop** — Success rate, queue depth, latency tracking
- **Routing Loop** — Traffic steering, circuit breakers, fallbacks

### **IONA Controller**

- Health scoring (98/100 current)
- Error ledger with anomaly tracking
- Configuration drift detection
- Automated remediation

---

## 📦 What's Included

- ✅ Windows OTel Collector service
- ✅ SigNoz observability platform (Docker)
- ✅ GPU-accelerated sidecars (ports 8001/8002)
- ✅ Automated monitoring scripts
- ✅ Test harness & chaos engineering
- ✅ Executive dashboards (status, live metrics)
- ✅ Comprehensive documentation (searchable hub)
- ✅ ECRR compliance framework
- ✅ Security scanning & rotation
- ✅ Nightly automation

---

## 🎓 Learning Resources

### **New Users**

1. **[Quick Start Card](./docs/BossCat/QUICK_START_CARD.md)** — 5-minute setup
2. **[Project Hub](./index.html)** — Browse all projects
3. **[User Guide](./docs/BossCat/PROJECT_HUB_USER_GUIDE.md)** — Complete manual
4. **[Test Harness Guide](./docs/BossCat/DATA_ROOM_QUICKSTART.md)** — Testing basics

### **Advanced Users**

1. **[System Architecture](./docs/BossCat/SYSTEM_ARCHITECTURE_DIAGRAM.md)** — Technical design
2. **[ECRR Framework](./docs/AGENTS.md)** — Governance methodology
3. **[Security Maintenance](./docs/BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md)** — Security ops
4. **[Nightly Operations](./docs/BossCat/guides/NIGHTLY_DASHBOARD_INTEGRATION.md)** — Automation

---

## 🏢 Enterprise Features

### **🔒 Security & Compliance**

- CodeQL static analysis
- Gitleaks secret scanning
- Dependabot vulnerability alerts
- Automated credential rotation
- SBOM generation (CycloneDX)
- Cosign artifact signing

### **🤖 Automation**

- Nightly dashboard exports (GitHub Actions)
- Automated ECRR compliance checking
- Self-patching systems
- Fleet orchestration (multi-repo)
- Policy-driven governance (OPA/Rego)

### **📋 Governance**

- BossCat OEM approval gates
- Multi-agent coordination
- Evidence-based decision making
- Audit trail generation
- Stakeholder reporting

---

## 🐾 MoneyCat Inc.

This repository is owned and maintained by **[MoneyCat Inc.](https://github.com/MoneyCat-inc)**

The **Resonai** local-first voice training application is developed as part of this observability stack.

### **Related Projects**

- **[Resonai Voice Training](./resonai-mock/index.html)** — Beta cohort (C1-C8)
- **[BossCat Operations](./docs/BossCat/README.md)** — Executive framework
- **[IONA Controller](./docs/IONA_SIGNOZ_INTEGRATION.md)** — Coordination layer

---

## 📞 Support

- **[Troubleshooting Guide](./docs/TROUBLESHOOTING.md)** — Self-service fixes
- **[IONA Error Ledger](./docs/IONA_ERRORS.md)** — Known issues
- **[GitHub Issues](https://github.com/MoneyCat-inc/otel-ops-pack/issues)** — Report bugs
- **[Security](./docs/SECURITY.md)** — Responsible disclosure

---

## 📜 License

See [LICENSE](./LICENSE) for details.

---

<div align="center">

**Made with 🐾 by MoneyCat Inc.**

[![Maintained by MoneyCat-inc](https://img.shields.io/badge/Maintained%20by-MoneyCat--inc-00aa88?style=for-the-badge&logo=github&logoColor=white)](https://github.com/MoneyCat-inc)

</div>

