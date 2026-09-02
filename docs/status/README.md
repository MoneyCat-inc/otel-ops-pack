# 📊 Status & Registry Files

**Location:** `docs/status/`  
**Purpose:** Canonical registries and operational metadata  
**Maintained:** `workflows.json` is generated and CI-guarded; `scripts.json` is generated on demand;
everything else is a hand-kept record or a dated snapshot (see the inventory below)

**🛡️ Protected by Registry Guard:** `workflows.json` only (`registry-guard.yml`)

---

## 📁 Files in This Directory

### Core Registries

**`REFERENCES_MAP.json`** / **`REFERENCES_MAP.md`**

- Canonical reference map: 5 buckets, 10 canonical references, 8 organized domains
- The JSON mirrors the markdown (same version number); keep them in step
- Single source of truth for all working parts
- **Update:** Manual (when adding canonical references)

**`scripts.json`**

- Tracked `scripts/**/*.ps1` (171 as of 2026-09-02), categorized by lane
- `size` = committed blob size, `modified` = last commit date, `updated` = newest `modified`
  (deterministic on every platform)
- **Regenerate:** `pwsh scripts/regenerate-scripts-registry.ps1` after adding, moving or deleting
  scripts (`-Check` exits 1 on drift)

**`workflows.json`** 🛡️ **CI-Guarded**

- GitHub Actions workflows registry
- Extracted triggers from `on:` block only (YAML-aware)
- Schema-validated (`workflows.schema.json`)
- **Regenerate:** After adding/modifying workflows in `.github/workflows/`
- **Guard:** `.github/workflows/registry-guard.yml` enforces freshness

### Snapshots and Records (not registries)

| File | What it is | Writer | Reader |
| --- | --- | --- | --- |
| `kpis.json` | Hub KPI tiles, last generated 2026-08-12 | `BRAV/SCPT/generate_status_jsons.py` (that run) or `scripts/generate-hub-kpis.ps1`; manual — `update-kpis.yml` RETIRED 2026-08-03 | `DELT/ASST/hub/hub.js`, `BRAV/SCPT/diagnostic-shell-enhanced.ps1` |
| `ssot.json` | Health summary from the same 2026-08-12 run | `BRAV/SCPT/generate_status_jsons.py` | `docs/status.html` (optional), diagnostic shell |
| `tests.json` | Gate #008 reconciliation record (2025-10-24), schema `schema/status-tests.schema.json` | `BRAV/SCPT/update-status-dashboard.ps1` | `json-validation-gate.yml`, `verify-iona-gate.ps1`, `docs/status.html` |
| `metrics.json`, `rsi-metrics.json` | RSI convergence rate (7d), `null` when unmeasured; written 2026-08-29 | RSI extractor lane (`scripts/rsi-extract.mjs` publishes to `artifacts/rsi/`) | `docs/assets/icf-rsi-panel.js` (last-resort fallback) |
| `convergence.json` | HISTORICAL snapshot, Gates #007-#008 (2025-10-22); the proposed panel was never built | hand-written | none |
| `version.json` | Release record for tag `bosscat-registry-1.0` (2025-10-19, PR #171) | hand-written | none |
| `workflows.schema.json` | JSON Schema for `workflows.json` | hand-written | `registry-guard.yml` |

> **Removed 2026-09-02:** `redirect-map.json` (177 old→new pairs from the 2025-10 root
> consolidation). The root stubs it described were deleted long ago and 133 of its 177 targets
> no longer existed (lower-cased `docs/bosscat/`, extracted `docs/socm/`, records since archived).
> `scripts/extract-redirect-map.ps1` can rebuild it from stubs if a consolidation ever recurs.

> **Removed 2026-08-14:** `orphans.md` was deleted in the deep-clean pass. It was a
> 4.4 MB / 144k-line snapshot generated 2025-10-19, it reported 18,018 orphans against
> a repo of ~6,800 tracked files (so it was counting untracked/vendored trees), no
> generator for it exists in this repository, and its triage never happened. Use the
> locally-generated `artifacts/index/md_orphans.csv` instead.

---

## 🛡️ Registry Guard (CI Enforcement)

The **Registry Guard** workflow automatically enforces that `workflows.json` stays in sync:

**What it does:**

1. **Regenerates** the registry from scratch
2. **Compares** with committed version
3. **Validates** against JSON schema
4. **Fails PR** if registry is out of date or malformed

**Workflow:** `.github/workflows/registry-guard.yml`  
**Schema:** `docs/status/workflows.schema.json`  
**Runs on:** PRs that modify workflows or registry files

**How to fix a failed guard:**

```powershell
pwsh scripts/regenerate-workflows-registry.ps1
git add docs/status/workflows.json
git commit -m "chore(registry): regenerate workflows.json"
```

---

## 🌙 Nightly Drift Check — RETIRED 2026-08-03

**Workflow:** `.github/workflows/registry-drift-check.yml` (now `workflow_dispatch` only)

Retired in the Phase 0 workflow audit (`docs/BossCat/ROADMAP_2026H2.md`): `registry-guard.yml` enforces
freshness at PR time, so the nightly PR-opener was a redundant recurring writer. When it ran nightly it would:

1. Regenerates `workflows.json`
2. Creates a PR with changes
3. Labels it for review

This catches cases where workflows were merged without regenerating the registry.
It shouldn't happen with the guard in place, but it provides defense-in-depth.

---

## 🔄 Regeneration Commands

### Workflows Registry

**When to regenerate:**

- After adding new workflow files
- After modifying workflow triggers (`on:` block)
- After renaming/deleting workflows

**Quick command (can be run from any directory):**

```powershell
pwsh scripts/regenerate-workflows-registry.ps1
```

**Output Format (Schema-Compliant):**

```json
{
  "source": "scripts/regenerate-workflows-registry.ps1",
  "total": 61,
  "items": [
    {
      "name": "workflow-name",
      "modified": "2025-10-16T04:41:51+01:00",
      "path": ".github/workflows/workflow-name.yml",
      "size": 1234,
      "triggers": {
        "issues": false,
        "other": [],
        "pull_request": true,
        "push": false,
        "release": false,
        "schedule": false,
        "workflow_call": false,
        "workflow_dispatch": true,
        "workflow_run": false
      }
    }
  ]
}
```

**Key Features:**

- ✅ Workflows sorted alphabetically by name (deterministic)
- ✅ Triggers as object (not string) for schema validation
- ✅ No timestamp field (use git history instead)
- ✅ CI-friendly (semantic comparison, not text diff)

**Manual regeneration (advanced users only):**

The helper script is the canonical source. If you need to modify the regeneration logic, see:

- `scripts/regenerate-workflows-registry.ps1` — Full implementation
- Key features: YAML-aware extraction, alphabetical ordering, semantic validation

**Quick manual regeneration:**

```powershell
# Always use the helper script (handles all complexity)
pwsh scripts/regenerate-workflows-registry.ps1

# The script:
# 1. Anchors to repo root (works from any directory)
# 2. Parses all .github/workflows/*.y(a)ml files
# 3. Extracts triggers from on: block only (YAML-aware)
# 4. Outputs schema-compliant JSON (sorted, deterministic)
# 5. Validates against docs/status/workflows.schema.json
```

**Verification:**

```powershell
# Check total count
$json = Get-Content docs\status\workflows.json -Raw | ConvertFrom-Json
Write-Host "Total workflows: $($json.total)"

# Spot-check specific workflows with active triggers
$json.items | Where-Object { $_.name -in @('bosscat-gate-bot-native', 'apisec-scan') } | 
  Select-Object name, @{N='triggers';E={
    ($_.triggers.PSObject.Properties | Where-Object {$_.Value -eq $true} | 
      Select-Object -ExpandProperty Name) -join ', '
  }} | Format-Table
```

---

### Scripts Registry

**When to regenerate:**

- After adding new PowerShell scripts
- After moving scripts between directories
- After lane reassignments

**Command (any platform, any directory):**

```powershell
pwsh scripts/regenerate-scripts-registry.ps1          # rewrite docs/status/scripts.json
pwsh scripts/regenerate-scripts-registry.ps1 -Check   # exit 1 if the committed file is stale
```

The script enumerates tracked `scripts/**/*.ps1` with `git ls-files`, so it never picks up
local-only files, and it takes sizes and dates from git rather than the filesystem, so two
clones at the same commit produce byte-identical output. Lane assignment is by filename
(see "Lane categorization" below). The 2025 recipe that read `artifacts/index/files.json`
from `C:\otel` is retired: that inventory is gitignored and its mtimes were machine-local.

---

## 🛡️ Quality Guardrails

### Workflows Registry

**CI-Enforced Rules:**

- ✅ Registry MUST be up to date (enforced by `registry-guard.yml`)
- ✅ Schema MUST validate (enforced by `registry-guard.yml`)
- ✅ PRs CANNOT merge if registry is stale
- ✅ `registry-guard.yml` on every workflow PR is the sole enforcement (nightly check retired 2026-08-03)

**YAML Parsing Rules:**

- ❌ DO NOT search entire file (matches `permissions: issues: write`)
- ✅ DO use YAML-aware block extraction
- ✅ DO stop at next top-level key (concurrency, permissions, env, jobs)
- ✅ Extract triggers from `on:` block only

**Schema Format:**

```json
{
  "source": "scripts/regenerate-workflows-registry.ps1",
  "total": 61,
  "items": [
    {
      "name": "workflow-name",
      "modified": "2025-10-16T04:41:51+01:00",
      "path": ".github/workflows/workflow-name.yml",
      "size": 1234,
      "triggers": {
        "push": true,
        "pull_request": false,
        "workflow_dispatch": true,
        "schedule": false,
        "issues": false,
        "other": []
      }
    }
  ]
}
```

**Notes:**

- Triggers are boolean objects (not strings) for machine readability
- Workflows sorted alphabetically by name for determinism
- No generatedAt field (git history provides timestamps)
- CI guard uses semantic comparison (ignores JSON formatting)

**Validation checks (automated by CI):**

```powershell
# Manual check for false 'issues' triggers
$json = Get-Content docs\status\workflows.json -Raw | ConvertFrom-Json
$falseIssues = $json.items | Where-Object { $_.triggers.issues -eq $true }
if ($falseIssues.Count -gt 0) {
    Write-Host "⚠️ WARNING: Found workflows with 'issues' trigger" -ForegroundColor Yellow
    $falseIssues | Select-Object name, path
}
```

### Scripts Registry

**Lane categorization:**

- **GATE:** Verification, gate checks
- **SSOT:** Monitoring, testing, canary
- **COMP:** Benchmarking, processing, analysis
- **DOCS:** Documentation, exports
- **UTIL:** Utilities, helpers

---

## 📚 Related Documentation

- **References Map:** [`REFERENCES_MAP.md`](REFERENCES_MAP.md)
- **Inventory Files:** `../../artifacts/index/` — gitignored, present only after local generation
- **BossCat Governance:** [`../BossCat/IMMUTABLE_PERSONA_v1.1.md`](../BossCat/IMMUTABLE_PERSONA_v1.1.md)

---

## 🐾 Maintenance Schedule

**After every workflow change:**

- Regenerate `workflows.json` (enforced by CI guard)
- Verify no false positives (automated validation)
- Commit with descriptive message

**On demand (manual):**

- Drift check: re-run the regenerate script and `git diff docs/status/workflows.json`
- The nightly drift workflow and its auto-PRs were RETIRED 2026-08-03; `registry-guard.yml`
  still fails a PR whose workflow change is not reflected in the registry

**Monthly:**

- Review `artifacts/index/md_orphans.csv` for triage (regenerate first; it is gitignored)
- Update `REFERENCES_MAP.json` if canonical refs change
- Regenerate full inventory (`artifacts/index/`)
- Review `workflows.json` against `.github/workflows/` (61 files as of 2026-09-02)

**Quarterly:**

- Audit lane assignments in `scripts.json`
- Review registry structure for improvements
- Archive old snapshots per retention policy
- Update schema if workflow patterns evolve

---

## 📋 PR Checklist

When modifying workflows, use this checklist (included in PR template):

- [ ] Ran `pwsh scripts/regenerate-workflows-registry.ps1`
- [ ] Committed changes to `docs/status/workflows.json`
- [ ] Reviewed diff for accuracy
- [ ] No false "issues" triggers
- [ ] Schema validation passes (checked by CI)
- [ ] Explained trigger changes in PR description

---

**Last Updated:** 2025-10-19; counts and cadence refreshed 2026-09-02  
**Maintained by:** Cursor{Implementer} under BossCat OEM  
**Methodology:** ECRR (Examine → Clean → Report → Role)  
**CI Guard:** `.github/workflows/registry-guard.yml`  
**Schema:** `docs/status/workflows.schema.json`

