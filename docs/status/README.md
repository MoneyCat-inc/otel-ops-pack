# 📊 Status & Registry Files

**Location:** `docs/status/`  
**Purpose:** Canonical registries and operational metadata  
**Maintained:** Automatically generated, CI-enforced

**🛡️ Protected by Registry Guard:** All changes are validated by CI

---

## 📁 Files in This Directory

### Core Registries

**`REFERENCES_MAP.json`** / **`REFERENCES_MAP.md`**

- Canonical reference map with 7 buckets
- Single source of truth for all working parts
- **Update:** Manual (when adding canonical references)

**`scripts.json`**

- PowerShell scripts registry categorized by lane
- Includes file size, modification date, lane assignment
- **Regenerate:** After adding/modifying scripts in `scripts/`

**`workflows.json`** 🛡️ **CI-Guarded**

- GitHub Actions workflows registry
- Extracted triggers from `on:` block only (YAML-aware)
- Schema-validated (`workflows.schema.json`)
- **Regenerate:** After adding/modifying workflows in `.github/workflows/`
- **Guard:** `.github/workflows/registry-guard.yml` enforces freshness

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

## 🌙 Nightly Drift Check (Optional)

**Workflow:** `.github/workflows/registry-drift-check.yml`

Runs nightly at 03:00 UTC to detect registry drift. If workflows changed without updating the registry, it automatically:

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
  "total": 76,
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

**Command:**

```powershell
cd c:\otel

$files = Get-Content artifacts\index\files.json -Raw | ConvertFrom-Json
$scripts = $files | Where-Object {
    $_.FullName -like "*\scripts\*" -and $_.FullName -like "*.ps1"
} | ForEach-Object {
    $name = [IO.Path]::GetFileName($_.FullName)
    $lane = if ($name -match 'gate|verify') { 'GATE' }
            elseif ($name -match 'monitor|canary|test') { 'SSOT' }
            elseif ($name -match 'benchmark|process') { 'COMP' }
            elseif ($name -match 'hub|export') { 'DOCS' }
            else { 'UTIL' }
    
    [pscustomobject]@{
        name = $name
        path = $_.FullName.Replace('C:\otel\','').Replace('\','/')
        size = $_.Length
        modified = $_.LastWriteTime
        lane = $lane
    }
}

@{
    updated = (Get-Date -Format 'o')
    total = $scripts.Count
    scripts = $scripts
} | ConvertTo-Json -Depth 4 | Out-File docs\status\scripts.json -Encoding UTF8

Write-Host "✅ scripts.json regenerated ($($scripts.Count) scripts)" -ForegroundColor Green
```

---

## 🛡️ Quality Guardrails

### Workflows Registry

**CI-Enforced Rules:**

- ✅ Registry MUST be up to date (enforced by `registry-guard.yml`)
- ✅ Schema MUST validate (enforced by `registry-guard.yml`)
- ✅ PRs CANNOT merge if registry is stale
- ✅ Nightly check catches any drift

**YAML Parsing Rules:**

- ❌ DO NOT search entire file (matches `permissions: issues: write`)
- ✅ DO use YAML-aware block extraction
- ✅ DO stop at next top-level key (concurrency, permissions, env, jobs)
- ✅ Extract triggers from `on:` block only

**Schema Format:**

```json
{
  "source": "scripts/regenerate-workflows-registry.ps1",
  "total": 76,
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

**Daily (automated):**

- Nightly drift check at 03:00 UTC
- Auto-PR created if drift detected

**Monthly:**

- Review `artifacts/index/md_orphans.csv` for triage (regenerate first; it is gitignored)
- Update `REFERENCES_MAP.json` if canonical refs change
- Regenerate full inventory (`artifacts/index/`)
- Review auto-generated drift PRs

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

**Last Updated:** 2025-10-19  
**Maintained by:** Cursor{Implementer} under BossCat OEM  
**Methodology:** ECRR (Examine → Clean → Report → Role)  
**CI Guard:** `.github/workflows/registry-guard.yml`  
**Schema:** `docs/status/workflows.schema.json`

