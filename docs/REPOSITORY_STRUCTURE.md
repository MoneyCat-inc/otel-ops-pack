# Repository Structure Guide

**Last Updated:** 2025-11-01  
**Authority:** BossCat OEM  
**Purpose:** Guide to repository organization and archive locations

---

## 📁 Directory Structure

### Root Level (Active Development)

```text
otel/
├── .codex/                  # Codex Gateway configuration
├── codex/                   # Code analysis scripts
├── config/                  # Configuration organization
│   ├── backups/            # Config snapshots
│   └── templates/          # Sample configs (.env, etc.)
├── scripts/                # Automation scripts
├── artifacts/              # Current run outputs
│   ├── archive/           # Historical data
│   │   └── monitoring/    # Old monitoring snapshots
│   └── codex/             # Code analysis results
│       └── archive/       # Old analysis runs
├── docs/                   # Documentation
│   └── archive/           # Historical documentation
│       └── gates/         # Gate reports by month
│           └── 2025-11/   # Current month
└── windows/                # Windows-specific configs
    └── otelcol/           # OTel Collector configs
```

---

## 📚 Key Locations

### Active Development

**Configuration:**

- `config.yaml` - Main OTel collector config
- `windows/otelcol/otelcol-contrib-config.yaml` - Windows collector
- `docker-compose-signoz.yml` - SigNoz stack
- `.codex/config.json` - Codex Gateway settings

**Scripts:**

- `canary-test.ps1` - Canary test generation
- `verify-pipeline.ps1` - End-to-end verification
- `scripts/monitor-optimized-pipeline.ps1` - Real-time monitoring
- `scripts/demo/chaos-*.ps1` - Chaos injection demos

**Documentation:**

- `docs/comfort-cat/` - Creative & ECRR reference
- `docs/ecrr/` - ECRR reports and templates
- `docs/architecture/` - System architecture and deprecation notices
- `docs/personas/` - Automation personas (Quil, Lumi)
- `docs/runbooks/` - Operational guides
- `docs/cheatsheets/` - Quick reference

---

## 🗂️ Archive Locations

### Gate Reports

**Location:** `docs/archive/gates/{YYYY-MM}/`

**What's Archived:**

- GATE_0XX_*.md - Numbered gate reports
- GATE_*_EXECUTIVE_SUMMARY.md - Gate summaries
- GATE_*_EVIDENCE.md - Evidence bundles
- All gate-related documentation older than current sprint

**Retention:** Permanent (historical record)

**Example:**

- `docs/archive/gates/2025-11/GATE_026_COMPLETE.md`
- `docs/archive/gates/2025-10/GATE_020_*.md`

---

### Monitoring Snapshots

**Location:** `artifacts/archive/monitoring/`

**What's Archived:**

- monitor-optimized-*.json - Pipeline monitoring runs
- quick-monitor-*.json - Quick health check snapshots
- hub-smoke-*.json - Hub smoke test results
- k6-*.json - Performance test results
- collector-telemetry-*.txt - Collector metrics

**Retention:** 30 days, then archive  
**Cleanup:** Automated by `scripts/repo-cleanup.ps1`

---

### Codex Analysis Runs

**Location:** `artifacts/codex/archive/`

**What's Archived:**

- scenario*.json - Individual scenario workplans
- workplan-*.json - Older analysis runs
- manifest.json, request.json - Intermediate files (>7 days)
- review-*.json, review-*.md - Executive reviews beyond active window

**Retention:** 7 days active, then archive  
**Cleanup:** Automated by `scripts/repo-cleanup.ps1`

**Current Run:** Always in `artifacts/codex/` root:

- `master-workplan.json`
- `master-cursor-instructions.md`
- `EXECUTION_REPORT.md`
- `review.json` / `review-summary.md` (if latest run used ChatGPT 5 Pro)

---

### Configuration Backups

**Location:** `config/backups/`

**What's Archived:**

- config.backup-*.yaml - Collector config snapshots
- Pre-gate configuration backups
- Rollback versions

**Retention:** Keep 3 most recent per config file

---

## 🧹 Automated Cleanup

### Cleanup Script

**Location:** `scripts/repo-cleanup.ps1`

**Usage:**

```powershell
# Dry run (see what would be cleaned)
.\scripts\repo-cleanup.ps1 -DryRun

# Execute cleanup
.\scripts\repo-cleanup.ps1

# Verbose output
.\scripts\repo-cleanup.ps1 -Verbose
```

**What It Cleans:**

- tmp_*/, tmp/, out/, .next/ folders
- Test images (snap_*.jpg, test-*.jpg)
- Temp text files (tmp_*.txt)
- Old monitoring snapshots (>30 days)
- Old Codex runs (>7 days)
- Gate reports at root (moves to archive)

---

## 📋 .gitignore Patterns

**Automated Exclusions (Added 2025-11-01):**

```gitignore
tmp_*/
.next/
out/
artifacts/**/manifest.json
artifacts/**/request.json
snap_*.jpg
test-*.jpg
*.log.txt
```

**Purpose:** Prevent temporary files from cluttering working tree

---

## 🔄 Maintenance Cadence

### Weekly

- Run `scripts/repo-cleanup.ps1 -DryRun` to review cleanup candidates
- Execute cleanup if needed
- Check artifacts/archive/ size

### Monthly  

- Archive gate reports from current month to previous month directory
- Review config/backups/ - keep 3 most recent per file
- Audit scripts/ for new duplicates

### Quarterly

- Review docs/archive/ size and compress if >100MB
- Check for obsolete Dockerfiles or configs
- Run dependency audit (pnpm prune, dedupe)

---

## 📍 Finding Historical Data

**Looking for old gate reports?**
→ Check `docs/archive/gates/{YYYY-MM}/`

**Looking for old monitoring data?**
→ Check `artifacts/archive/monitoring/`

**Looking for previous Codex analysis?**
→ Check `artifacts/codex/archive/`

**Looking for config backups?**
→ Check `config/backups/`

---

## 🎯 Quick Reference

| Type | Active Location | Archive Location | Retention |
|------|----------------|------------------|-----------|
| Gate Reports | Root (current sprint) | docs/archive/gates/{YYYY-MM}/ | Permanent |
| Monitoring | artifacts/*.json | artifacts/archive/monitoring/ | 30 days |
| Codex Runs | artifacts/codex/ | artifacts/codex/archive/ | 7 days |
| Configs | config.yaml, etc. | config/backups/ | 3 recent |
| Templates | N/A | config/templates/ | Permanent |

---

## 🐾 Cat Nap Philosophy

**Repository structure reflects the Cat Nap Control Room aesthetic:**

- **Calm:** Clean root, no clutter
- **Organized:** Archives well-structured
- **Intentional:** Every file has a place
- **Cozy:** Easy to find what you need

**Automated cleanup ensures the repo stays tidy without manual intervention.**

---

## 📞 Questions?

**Where should X go?**

- Gate reports → `docs/archive/gates/{YYYY-MM}/`
- Monitoring data → `artifacts/archive/monitoring/`
- Code analysis → `artifacts/codex/archive/`
- Config backups → `config/backups/`

**How to run cleanup?**
→ `.\scripts\repo-cleanup.ps1`

**How to prevent re-clutter?**
→ `.gitignore` already updated with patterns

---

🐾 **Repository Structure Guide**  
*Keep it calm, organized, and cat-nap cozy*

