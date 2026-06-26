# 🗺️ Resonai [OTel] — Canonical References Map

**Version:** 1.2  
**Updated:** 2026-06-12  
**Purpose:** Single source of truth for all working parts

**What's New in v1.1:**
- Updated paths after root consolidation (177 files organized)
- Added organized domains (gate, socm, pr, releases, runbooks, evidence, status)
- Expanded governance references (added AGENTS.md)

> **Navigation:** This map is linked from [`docs/index.html`](../index.html) (the documentation hub)

---

## 📚 Canonical Buckets

### 1. Gate & Readiness
**Authoritative playbooks for gate verification and production readiness**

- **[Gate Archive (2025-10)](../gate/2025-10/)**  
  October 2025 gate verification evidence

---

### 2. Persona & Governance
**Immutable rules for merge discipline, budgets, and ECRR methodology**

- **[The Art of ECRR (Manual)](../BossCat/misc/ART_OF_ECRR.md)**  
  Paired-agent protocol, kill-switch, strict budgets

- **[BossCat Charter](../BossCat/CHARTER.md)**  
  Canonical governance and agent hierarchy

- **[Immutable Persona v1.1](../BossCat/IMMUTABLE_PERSONA_v1.1.md)**  
  Merge discipline and executive voice

- **[Repository Index (AGENTS.md)](../../AGENTS.md)**  
  Canonical agent entry point

---

### 3. Stakeholder Evidence
**Executive packages for sign-offs and audit trails**

- **[Stakeholder Evidence Package](../BossCat/STAKEHOLDER_EVIDENCE_PACKAGE.md)**  
  Top-down view for stakeholder review

---

### 4. Security & Maintenance
**Master security guide and tracked risk waivers**

- **[Security & Maintenance Master Guide](../BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md)**  
  Week-by-week operations and security procedures

---

### 5. Dashboards & Data Room
**Live 'see it working' observability interfaces**

- **[Status/KPI Dashboard](../status.html)**  
  Real-time metrics and system health dashboard

## 🔧 System Registries

### Inventory & Analysis
- **File Inventory:** [`artifacts/index/files.json`](../../artifacts/index/files.json)
- **Markdown Links Graph:** [`artifacts/index/md_links.json`](../../artifacts/index/md_links.json)
- **Orphaned Docs:** [`artifacts/index/md_orphans.csv`](../../artifacts/index/md_orphans.csv)
- **Branch Status:** [`artifacts/index/branches.txt`](../../artifacts/index/branches.txt)

### Operational Registries
- **Scripts Registry:** [`scripts.json`](scripts.json) *(pending)*
- **Workflows Registry:** [`workflows.json`](workflows.json) *(pending)*
- **Orphans Triage:** [`orphans.md`](orphans.md) *(pending)*

### Evidence Trails
- **ECRR Reports:** [`CHAR/ECRR/ECRR_REPORTS/`](../../CHAR/ECRR/ECRR_REPORTS/)
- **Latest Processing:** [`ECRR_PROCESSING_SUMMARY_LATEST.md`](../../CHAR/ECRR/ECRR_REPORTS/ECRR_PROCESSING_SUMMARY_LATEST.md)
- **Benchmark Data:** [`DELT/ARTF/ecrr-benchmark.json`](../../DELT/ARTF/ecrr-benchmark.json)

---

## 🗂️ Organized Domains

The root consolidation organized 177 files into domain-specific folders:

- **[docs/gate/](../gate/)** — Gate verification and readiness evidence (25 files)
- **[docs/socm/](../socm/)** — Social media and communications (39 files)
- **[docs/pr/](../pr/)** — Pull request reviews and comments (15 files)
- **[docs/releases/](../releases/)** — Release notes and roadmaps (3 files)
- **[docs/runbooks/](../runbooks/)** — Operational guides and deployment (6 files)
- **[docs/evidence/](../evidence/)** — Commit evidence and system status (3 files)
- **[docs/status/](../status/)** — Session reports and implementation status (12 files)
- **[docs/notes/](../notes/)** — Notes, tasks, and misc documentation (56 files)

**Date-based organization:** Files with dates organized into `YYYY-MM/` subfolders  
**Redirect stubs:** 177 stubs at original locations preserve inbound links

---

## 📊 Map Statistics

- **Version:** 1.1
- **Total Canonical References:** 6
- **Buckets:** 7
- **Organized Domains:** 8
- **Root Docs Consolidated:** 177
- **Inventory Files:** 4 (complete)
- **Registries:** 3 (operational)
- **Last Updated:** 2026-06-12T13:00:00+00:00

---

## 🐾 Governance

**Maintained under:** BossCat Immutable Persona v1.1  
**ECRR Methodology:** Examine → Clean → Report → Role  
**Kill-Switch:** Active (10-file, 200-LOC budgets enforced)  
**Evidence Trail:** All changes logged in ECRR reports

**Hub Navigation:** [`docs/index.html`](../index.html) → References Map (this page)

---

🎯 **Canonical picks rationale:**

- **Gate:** One authoritative playbook for "ready-for-gate" evidence
- **Persona/Governance:** v1.1 defines merge discipline; ECRR encodes paired-agents
- **Stakeholder:** Packaged top-down view for sign-offs
- **Security:** Master guide + SigNoz waiver with tracked risk
- **Dashboards:** Live "see it working" assets
- **Bots:** Tetragram registry + Stability Pack enforce A/B lanes
- **Rebuild:** Oct-07 professional rebuild that unified UX

---

*This map is the single source of truth. All other documentation either links here or is marked for triage/archive.*


