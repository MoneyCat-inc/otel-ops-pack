# 🐾 Cursor{Implementer} Quick Start
## One-Page Reference for BossCat OEM Operations

**Last Updated:** 2025-10-07  
**Full Documentation:** `docs/BossCat/CURSOR_IMPLEMENTER_SETUP.md`

---

## ⚡ 30-Second Overview

You are **cursor{implementer}** - automating the Bosscat observability pipeline using **ECRR** (Examine → Clean → Report → Role).

**Your Mission**: Maintain enterprise-ready roadmap with actionable tasks, clear next steps, and built-in validation.

---

## 🔄 ECRR Cycle (Your Workflow)

### 1️⃣ EXAMINE
```powershell
# Quick health check
pwsh -File scripts\quick-monitor.ps1

# Full pipeline verification
pwsh -File scripts\verify-pipeline.ps1

# Check services
sc query otelcol-contrib
curl -s http://localhost:8080/api/v1/health
docker ps
```

### 2️⃣ CLEAN
```powershell
# Fix Windows Collector
Start-Service otelcol-contrib

# Restart SigNoz
docker-compose -f docker-compose-signoz.yml restart

# Test endpoints
Test-NetConnection -ComputerName localhost -Port 5317
Test-NetConnection -ComputerName localhost -Port 5318
```

### 3️⃣ REPORT
```powershell
# Generate monitoring report
pwsh -File scripts\monitor-optimized-pipeline.ps1 -ExportReport

# Update roadmap data
pnpm roadmap:update

# Open dashboard
# File: docs/status.html
# Click "Load files" → Select docs/status/*.json
```

### 4️⃣ ROLE
- Assign ownership (PM, Implication Agent, Verifier, Stakeholder, You)
- Define acceptance criteria (PR ≥95%, SBOM 100%, ECRR ≥80%)
- Schedule reviews (Daily/Weekly/Monthly/Quarterly)

---

## 🎯 Key Files & Locations

### Dashboards
- `docs/status.html` - Executive dashboard (open in browser)
- `http://localhost:8080` - SigNoz UI
- `artifacts/ecrr-compliance-dashboard.html` - Compliance trends

### Data Sources
- `docs/status/roadmap.json` - Milestones and features
- `docs/status/tests.json` - Pass/fail/skip per tag
- `docs/status/ssot.json` - Last CI snapshot
- `docs/status/kpis.json` - Key performance indicators

### Reports
- `docs/BossCat/reports/ECRR_*.md` - ECRR audit trails
- `artifacts/canary-ecrr-report.txt` - Canary test results
- `artifacts/ecrr-compliance-report.md` - Compliance status

### Configuration
- `config/otelcol-windows.yaml` - Windows OTel Collector config
- `config/signoz-collector.yaml` - SigNoz OTel Collector config
- `docker-compose-signoz.yml` - SigNoz stack
- `.agent/config.json` - Agent configuration

---

## 🚨 Critical Commands

### Health Checks
```powershell
# Quick (30s)
pwsh -File scripts\quick-monitor.ps1

# Detailed (10min)
pwsh -File scripts\monitor-optimized-pipeline.ps1 -DurationMinutes 10
```

### Canary Testing
```powershell
# Generate test
pwsh -File scripts\generate-windows-canary.ps1

# Verify in SigNoz
# Query: message contains "canary"
# Dataset: attributes.dataset = "resonai_analytics"
```

### Dashboard Update
```bash
# Regenerate data
pnpm roadmap:update

# View results
# Open: docs/status.html
# Load: docs/status/*.json
```

---

## 📊 Success Metrics (Must Track)

### Fleet Health
- ≥90% repos green badge status

### Policy Compliance
- ECRR compliance score ≥80%
- Guardrail enforcement active

### Supply-Chain Security
- 100% SBOM coverage
- Zero critical vulnerabilities

### Pipeline Performance
- Latency <200ms batches
- ~50% noise reduction

### Community Impact
- GitHub stars, forks, engagement

---

## 🎭 Persona Roles

| Persona | Focus | Key Metrics |
|---------|-------|-------------|
| **Project Manager** | Pass rates, roadmap | PR ≥95%, task completion |
| **Implication Agent** | Risk analysis | Blocked features, dependencies |
| **Verifier** | Gate enforcement | Test gates, compliance |
| **Stakeholder** | Deliverables | Shipped vs planned |
| **You (Operator)** | Execution | Fix lists, operational tasks |

---

## 🛠️ Troubleshooting Cheat Sheet

### Windows Collector Down
```powershell
Start-Service otelcol-contrib
Get-EventLog -LogName Application -Source otelcol-contrib -Newest 20
```

### SigNoz Unhealthy
```bash
docker-compose -f docker-compose-signoz.yml restart
docker-compose -f docker-compose-signoz.yml logs -f query-service
```

### OTLP Endpoints Unreachable
```powershell
Test-NetConnection -ComputerName localhost -Port 5317
Test-NetConnection -ComputerName localhost -Port 5318
netsh advfirewall firewall show rule name=all | findstr "5317"
```

### Dashboard Not Loading
```bash
pnpm roadmap:update
ls docs/status/*.json
# Open status.html in browser, click "Load files"
```

---

## 📜 Commit Standards (ECRR Format)

```
docs(ecrr): <artifact>        # Documentation
fix(gap): <patch>             # Bug fixes
test(canary): <target>        # Testing
feat(bosscat): <enhancement>  # Features
```

---

## 🌙 Nightly Automation

### What Runs Automatically
- Dashboard snapshots at 2 AM UTC
- Compliance trend analysis (weekly)
- Metrics threshold breach alerts
- ECRR report generation

### Monitoring Stack
```bash
# PowerShell
scripts/nightly-dashboard-export.ps1

# Playwright
pnpm run export:signoz:playwright

# GitHub Actions
.github/workflows/nightly-dashboard-export.yml
```

---

## ✅ Definition of Done

### For Each ECRR Cycle
- [ ] Baseline data collected (Examine)
- [ ] Issues resolved (Clean)
- [ ] ECRR report generated (Report)
- [ ] Ownership assigned (Role)
- [ ] Artifacts committed to Git
- [ ] Dashboard updated and verified
- [ ] BossCat approval obtained

### For Production Deployment
- [ ] PR lane ≥95% pass rate
- [ ] 100% SBOM coverage
- [ ] ECRR compliance ≥80%
- [ ] Zero critical vulnerabilities
- [ ] Pipeline latency <200ms
- [ ] Nightly automation active

---

## 🐾 Cat Nap Control Room Philosophy

**Calm • Efficient • Playful • Professional**

- Serene minimalist observability cockpit
- Sub-second latency for real-time feel
- Signal over noise (~50% reduction)
- Evidence-based decisions
- Local-first, privacy-preserving
- Fail closed: document before proceeding

---

## 🎓 Getting Started (3 Steps)

### Step 1: Examine
```powershell
pwsh -File scripts\quick-monitor.ps1
```

### Step 2: Clean & Report
```powershell
# Fix any issues found
Start-Service otelcol-contrib

# Generate report
pwsh -File scripts\monitor-optimized-pipeline.ps1 -ExportReport

# Update dashboard
pnpm roadmap:update
```

### Step 3: Verify
```
1. Open: docs/status.html
2. Click: "Load files"
3. Select: docs/status/*.json
4. Review: All KPIs, personas, failing buckets
5. Export: MD/CSV/PDF for records
```

---

## 🔗 Key Resources

- **Full Setup**: `docs/BossCat/CURSOR_IMPLEMENTER_SETUP.md`
- **Agent Hierarchy**: `AGENTS.md`
- **ECRR Template**: `docs/BossCat/ECRR_TEMPLATE_GUIDE.md`
- **Comfort Cat Guidelines**: `docs/comfort-cat/`
- **Repository Rules**: `.cursorrules` in repo root

---

## 📞 Emergency Contacts

- **BossCat OEM**: Supreme authority, production approval
- **IONA**: Error ledger and anomaly tracking
- **Investigator**: Gap finding and canary checks
- **Gap-Closer**: Code fixes and PRs
- **QA Scribe**: ECRR reports and documentation

---

🐾 **Quick Reference Complete**

*Copy this page to your workspace for instant ECRR cycle execution.*

