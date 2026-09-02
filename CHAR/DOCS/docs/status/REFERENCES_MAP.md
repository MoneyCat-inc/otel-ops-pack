# 🗺️ Resonai [OTel] — Canonical References Map

**Version:** 1.3  
**Updated:** 2026-09-02  
**Purpose:** Single source of truth for all working parts

**What's New in v1.3 (2026-09-02 truth pass):**

- Every link and count re-checked against disk; domain counts are live `.md` files
  (excluding `archive/`) as of 2026-09-02
- Registries are live, not pending: `scripts.json` (46 entries), `workflows.json` (61)
- `docs/evidence/` dropped (no such directory); `docs/socm/` extracted to the `socm`
  repo in Pack 3B (2026-07-24)
- Gate bucket gains the live runner; two rationale entries for buckets that no longer
  exist (Bots, Rebuild) removed — the map has five buckets

**What's New in v1.1:**

- Updated paths after root consolidation (177 files organized)
- Added organized domains (gate, socm, pr, releases, runbooks, evidence, status)
- Expanded governance references (added AGENTS.md)

> **Navigation:** This map is linked from [`docs/index.html`](../index.html) (the documentation hub)

---

## 📚 Canonical Buckets

### 1. Gate & Readiness

**Authoritative playbooks for gate verification and production readiness.**

- **[Gate Cheatsheet](../cheatsheets/GATE_CHEATSHEET.md)**  
  Live runner: `scripts/verify-iona-gate.ps1 -Strict`; budgets per GR-02

- **[Current Architecture](../architecture/CURRENT_ARCHITECTURE.md)**  
  What is actually deployed (Windows collector → SigNoz), from the canonical configs

- **[Gate Archive (2025-10)](../gate/2025-10/)**  
  October 2025 gate verification evidence (historical)

---

### 2. Persona & Governance

**Immutable rules for merge discipline, budgets, and ECRR methodology.**

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

**Executive packages for sign-offs and audit trails.**

- **[Stakeholder Evidence Package](../BossCat/STAKEHOLDER_EVIDENCE_PACKAGE.md)**  
  Top-down view for stakeholder review

---

### 4. Security & Maintenance

**Master security guide and tracked risk waivers.**

- **[Security & Maintenance Master Guide](../BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md)**  
  Week-by-week operations and security procedures

---

### 5. Dashboards & Data Room

**Live 'see it working' observability interfaces.**

- **[Status/KPI Dashboard](../status.html)**  
  Real-time metrics and system health dashboard

## 🔧 System Registries

### Inventory & Analysis

> ⚠️ **Not in the repository.** Everything under `artifacts/` is gitignored, so these
> files exist only on a machine that has generated them. A fresh clone will **not**
> have them, and the paths below will not resolve. They are listed here to document
> what the inventory tooling produces, not as browsable links.

| Output | Path (local only) |
|---|---|
| File inventory | `artifacts/index/files.json` |
| Markdown links graph | `artifacts/index/md_links.json` |
| Orphaned docs | `artifacts/index/md_orphans.csv` |
| Branch status | `artifacts/index/branches.txt` |

### Operational Registries

- **Scripts Registry:** [`scripts.json`](scripts.json) — 46 entries
- **Workflows Registry:** [`workflows.json`](workflows.json) — 61 workflows, guarded by
  `registry-guard.yml`; regenerate with `scripts/regenerate-workflows-registry.ps1`

### Evidence Trails

- **ECRR Reports:** [`CHAR/ECRR/ECRR_REPORTS/`](../../CHAR/ECRR/ECRR_REPORTS/) — 409 reports
  as of 2026-09-02 (`ls CHAR/ECRR/ECRR_REPORTS/*.md | wc -l`)
- **Operating log:** [`docs/BossCat/BOSSCAT_LOG.md`](../BossCat/BOSSCAT_LOG.md)
- **Latest Processing:** [`ECRR_PROCESSING_SUMMARY_LATEST.md`](../../CHAR/ECRR/ECRR_REPORTS/ECRR_PROCESSING_SUMMARY_LATEST.md)
- **Benchmark Data:** [`DELT/ARTF/ecrr-benchmark.json`](../../DELT/ARTF/ecrr-benchmark.json)

---

## 🗂️ Organized Domains

The root consolidation organized 177 files into domain-specific folders. Counts below are
live `.md` files as of 2026-09-02 (excluding `archive/` subfolders):

- **[docs/gate/](../gate/)** — Gate verification and readiness evidence (17 files)
- **[socm](https://github.com/MoneyCat-inc/socm)** — Bluesky / social ops (extracted Pack 3B; was `docs/socm/`)
- **[docs/pr/](../pr/)** — Pull request reviews and comments (11 files)
- **[docs/releases/](../releases/)** — Release notes and roadmaps (3 files)
- **[docs/runbooks/](../runbooks/)** — Operational guides and deployment (13 files)
- **[docs/status/](../status/)** — This map, the registries README and STATUS (3 docs + 12 JSON registries)
- **[docs/notes/](../notes/)** — Notes, tasks, and misc documentation (42 files)
- **[docs/BossCat/](../BossCat/)** — Governance guides and records (119 files; see its README)

**Date-based organization:** Files with dates organized into `YYYY-MM/` subfolders  
**Redirect stubs:** 177 stubs at original locations preserve inbound links

---

## 📊 Map Statistics

- **Version:** 1.3
- **Total Canonical References:** 11
- **Buckets:** 5
- **Organized Domains:** 8
- **Root Docs Consolidated:** 177
- **Inventory Files:** 4 (local only, gitignored)
- **Registries:** 2 operational (`scripts.json`, `workflows.json`) + `REFERENCES_MAP.json`
- **Last Updated:** 2026-09-02

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

---

*This map is the single source of truth. All other documentation either links here or is marked for triage/archive.*


