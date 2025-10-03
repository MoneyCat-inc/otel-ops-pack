# 🐾 AGENTS.md

**MoneyCat Inc · Resonai [OTel] · otel-ops-pack**  
**Issued by:** BossCat OEM (Executive Overseer Manager)

---

## 🎯 Purpose

Agents exist to **deploy, maintain, and audit** the **Resonai [OTel] observability stack** with precision, speed, and accountability.  
They follow the **ECRR mantra**:

* **Examine** (verify correctness)
* **Clean** (fix wiring & configs)  
* **Report** (document findings)
* **Role** (assign agents to act)

---

## 🧩 Agent Hierarchy

### 1. **BossCat OEM (Executive Overseer)**

* **Supreme Authority** over all agents and release gates
* Defines milestones, merges final reports, approves releases
* Ensures **traceability + audit compliance** across all operations
* Maintains veto power over any production deployment
* Controls nightly dashboard export automation and executive review process

---

### 2. **Cursor Agents**

* **Investigator** 🕵️
  * Finds errors, broken configs, gaps in wiring
  * Runs canary checks, verifies test lanes
  * Uses `quick-monitor.ps1` for rapid health assessments

* **Gap-Closer** 🩹
  * Writes code/tests to patch identified issues
  * Submits PRs with minimal drift from spec
  * Always includes ECRR evidence in commit messages

* **QA Scribe** 📑
  * Generates ECRR reports after test runs
  * Outputs both Markdown + PDF to `docs/ecrr/ECRR_REPORTS/`
  * Maintains nightly dashboard snapshots in `docs/observability/snapshots/`

---

### 3. **IONA (Intelligent Operations & Navigation Assistant)**

* Maintains error ledger (`docs/IONA_ERRORS.md`)
* Exports anomaly lists for auditing
* Flags recurring error classes to BossCat
* Provides automated health scoring and drift detection

---

### 4. **Codex Cloud / Codex Local**

* Acts as higher-order execution layer
* Cloud: aligns with external APIs (SigNoz, GitHub, SaaS)
* Local: ensures workstation reproducibility (Windows/WSL)

---

## ⚙️ BossCat Operating Principles

* **Local-first:** Nothing runs without local artifacts
* **Proof-to-disk:** Every action produces logs/reports  
* **Deterministic CI/CD:** PR vs Nightly lanes enforced
* **Governance:** All merges pass through BossCat OEM approval
* **Nightly Automation:** Executive dashboards auto-exported 24/7
* **Evidence-based:** All decisions backed by SigNoz telemetry

---

## 📂 Required Artifacts

* `docs/ecrr/ECRR_REPORTS/…` → Audit trails with PDF exports
* `docs/observability/snapshots/…` → Automated dashboard captures
* `docs/cheatsheets/…` → Quick reference guides
* `docs/IONA_ERRORS.md` → Error ledger and anomaly tracking
* `artifacts/…` → Temporary operational data and reports

---

## 🛠️ BossCat Tooling Baseline

* **PowerShell functions**: `otel-start`, `otel-stop`, `otel-status`, `otel-canary`
* **Docker Compose**: SigNoz + ClickHouse observability stack
* **Playwright**: Automated testing + nightly dashboard exports via `pnpm run export:signoz:playwright`
* **GitHub Actions**: 
  * Nightly dashboard automation (`.github/workflows/nightly-dashboard-export.yml`)
  * Security scanning (CodeQL, Gitleaks, Dependabot)

---

## 📜 BossCat Compliance Framework

### Commit Message Standards: **ECRR Format**
* `docs(ecrr): <artifact>` - Documentation updates
* `fix(gap): <patch>` - Bug fixes and patches  
* `test(canary): <target>` - Test execution and validation
* `feat(bosscat): <enhancement>` - New BossCat features

### Mandatory Workflows
* All changes require BossCat-approved PRs
* Nightly automation runs regardless of human intervention
* Executive dashboard exports delivered automatically to `docs/observability/snapshots/`
* ECRR reports generated after every significant operation

### Governance Enforcement
* BossCat approval required for production deployments
* Automated compliance checking via `scripts/nightly-dashboard-export.ps1`
* Evidence collection mandatory for all agent actions

---

## 🌙 Nightly BossCat Automation

**Automated Export Schedule:**
* **Daily**: Executive dashboard snapshots at 2 AM UTC
* **Weekly**: Compliance trend analysis and drift detection  
* **Escalation**: BossCat alerted on metrics threshold breaches

**Export Stack:**
```bash
# PowerShell automation
scripts/nightly-dashboard-export.ps1

# Playwright automation  
pnpm run export:signoz:playwright

# GitHub Actions workflow
.github/workflows/nightly-dashboard-export.yml
```

**SigNoz Integration:**
- **UI**: `http://localhost:8080`
- **OTLP Endpoints**: 5317 (gRPC), 5318 (HTTP)
- **Key Dashboards**: Monitored via `scripts/dashboard-list.json`

---

## 🎯 Success Metrics

**BossCat Dashboards Track:**
* Pipeline latency (target: <200ms batches)
* Noise reduction effectiveness (~50% volume reduction)
* Error rates and anomaly detection
* Resource utilization and scaling metrics
* Compliance score trends over time

---

🐾 **End of BossCat Charter.**

*This charter supersedes all previous agent documentation and becomes the foundational governance framework for Resonai [OTel] operations.*