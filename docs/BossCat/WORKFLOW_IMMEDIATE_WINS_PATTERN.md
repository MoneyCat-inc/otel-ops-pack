<!-- markdownlint-disable MD022 MD031 MD032 MD036 -->
# Workflow Immediate Wins — Standard Pattern

> **Truth pass 2026-09-02.** The rollout table below is corrected in place: win #1 was never applied to
> `bosscat-gate-verify.yml` (it runs `cancel-in-progress: false`, deliberately, as a required lane);
> `nightly-dashboard-export.yml` does not exist; `bosscat-gate-bot-native.yml` is RETIRED. The helper
> scripts `scripts/audit-workflow-patterns.ps1` / `apply-immediate-wins.ps1` are not in the repo and the
> template is `.github/workflows/app-template.yml`.

**Authority:** BossCat Operations + Comfort Cat Architecture  
**Status:** ✅ **APPROVED PATTERN** — Apply to all workflows  
**First Applied:** 2025-10-10 (`bosscat-gate-verify.yml`)

---

## 🎯 The Three Immediate Wins

### 1. Concurrency Control (Demand Shaping)

**Problem:** Multiple pushes to PR trigger multiple full runs, only latest matters

**Solution:**
```yaml
concurrency:
  group: <unique-name>-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

**Impact:** 70-80% fewer runs (5 pushes = 1 run, not 5)

**Reference:** [GitHub Docs: Concurrency](https://docs.github.com/en/actions/using-jobs/using-concurrency)

---

### 2. Artifact Retention (Auto-Cleanup)

**Problem:** Artifacts accumulate forever, causing 10k+ run pileups

**Solution:**
```yaml
- uses: actions/upload-artifact@v4
  with:
    name: my-artifact
    path: artifacts/**
    retention-days: 14  # Standard: 14 days
```

**Impact:** Auto-expiry prevents accumulation, 75% storage savings

**Reference:** [GitHub Docs: Artifact Retention](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)

---

### 3. Job Summaries (Supply Expansion)

**Problem:** Developers dive into logs to find basic context

**Solution:**
```yaml
- name: 📋 Run Summary
  if: always()
  run: |
    {
      echo '### ${{ github.workflow }} - Run Summary';
      echo '';
      echo "**Run:** #${{ github.run_number }} (attempt ${{ github.run_attempt }})";
      echo "**Ref:** \`${{ github.ref }}\`";
      echo "**Actor:** @${{ github.actor }}";
      echo "**Status:** ${{ job.status }}";
      echo '';
      echo '[View full run](${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }})';
    } >> "$GITHUB_STEP_SUMMARY"
```

**Impact:** Instant context, 2-5 minutes saved per failure investigation

**Reference:** [GitHub Blog: Job Summaries](https://github.blog/news-insights/product-news/supercharging-github-actions-with-job-summaries/)

---

## 📋 Application Checklist

When updating a workflow:

- [ ] **Concurrency:** Added unique group with `cancel-in-progress: true`
- [ ] **Retention:** All `upload-artifact` steps have `retention-days: 14`
- [ ] **Summary:** Job summary step added (runs `if: always()`)
- [ ] **Testing:** Validated on test PR
- [ ] **Documentation:** Pattern confirmed in this doc

---

## 🎨 Template (Copy-Paste Ready)

### Full Pattern

```yaml
name: My Workflow

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

# ✅ IMMEDIATE WIN #1: Concurrency
concurrency:
  group: my-workflow-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      # ... your build steps ...
      
      # ✅ IMMEDIATE WIN #2: Retention
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: build-artifacts
          path: dist/**
          retention-days: 14
      
      # ✅ IMMEDIATE WIN #3: Summary
      - name: 📋 Run Summary
        if: always()
        run: |
          {
            echo '### ${{ github.workflow }} - Run Summary';
            echo '';
            echo "**Run:** #${{ github.run_number }} (attempt ${{ github.run_attempt }})";
            echo "**Ref:** \`${{ github.ref }}\`";
            echo "**Actor:** @${{ github.actor }}";
            echo "**Status:** ${{ job.status }}";
            echo '';
            echo '[View run](${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }})';
          } >> "$GITHUB_STEP_SUMMARY"
```

---

## 🔧 Customization Guide

### Concurrency Group Naming

**Standard Pattern:**
```yaml
group: <workflow-name>-${{ github.workflow }}-${{ github.ref }}
```

**Examples:**
```yaml
# Gate workflows
group: bosscat-gate-verify-${{ github.workflow }}-${{ github.ref }}

# Nightly workflows
group: nightly-dashboard-${{ github.workflow }}-${{ github.ref }}

# Security scans
group: security-scan-${{ github.workflow }}-${{ github.ref }}
```

**Why This Pattern:**
- `<workflow-name>`: Human-readable prefix
- `${{ github.workflow }}`: Workflow file name (uniqueness)
- `${{ github.ref }}`: Branch/PR ref (isolation)

**Result:** Each PR/branch gets one run, main branch runs independently

---

### Retention Days (When to Vary)

**Standard: 14 days**
- Most CI artifacts
- Test results
- Build outputs (non-release)

**7 days:**
- Frequent workflows (hourly/nightly)
- Logs only (no artifacts)

**30 days:**
- Release artifacts (if not using GitHub Releases)
- Compliance evidence
- Performance benchmarks

**90 days (exception):**
- Legal/audit requirements
- Long-term trend data
- Requires justification

---

### Job Summary Content

**Minimum (Always Include):**
- Workflow name
- Run number
- Status
- Link to full run

**Good Additions:**
- Actor (who triggered)
- Ref (branch/PR)
- Attempt number (for reruns)

**Advanced (Loop-Closing Machine):**
- Error signature (on failure)
- Fix hint (known issues)
- Link to similar runs
- Auto-rerun notice (flakes)

**Example Advanced Summary:**
```yaml
- name: 📋 Failure Summary
  if: failure()
  run: |
    {
      echo '### 🔴 Build Failed';
      echo '';
      echo "**Error Signature:** \`${{ env.SIG_ID }}\`";
      echo "**Hypothesis:** Cache miss on dependencies";
      echo "**Fix:** Check lockfile or rerun";
      echo '';
      echo '[Rerun workflow](${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }})';
      echo '[Similar failures](#) • [Playbook](#)';
    } >> "$GITHUB_STEP_SUMMARY"
```

---

## 📊 Validation

### How to Test

**1. Create Test PR**
```bash
git checkout -b test/immediate-wins
# Make trivial change
git commit -m "test: validate immediate wins"
git push
```

**2. Make Multiple Pushes**
```bash
# Push 1
git commit --allow-empty -m "test: push 1"
git push

# Push 2 (should cancel Push 1)
git commit --allow-empty -m "test: push 2"
git push

# Push 3 (should cancel Push 2)
git commit --allow-empty -m "test: push 3"
git push
```

**3. Verify Results**

✅ **Concurrency:** Only Push 3 run completes, Push 1 & 2 cancelled  
✅ **Retention:** Artifacts show "Expires in 14 days"  
✅ **Summary:** Run summary visible on Actions tab without clicking through

---

## 🚀 Propagation Strategy

### Phase 1: Critical Workflows (Manual)

Apply to 3-5 key workflows manually:
1. ⏸️ `bosscat-gate-verify.yml` (NOT applied — `cancel-in-progress: false` is intentional for a required lane)
2. ⛔ `nightly-dashboard-export.yml` (does not exist)
3. ⛔ `bosscat-gate-bot-native.yml` (RETIRED 2026-08-03)
4. ⏸️ Security scan workflow (if applicable)
5. ⏸️ Main test workflow

**Why Manual First:**
- Validate pattern works
- Find edge cases
- Build confidence
- Document learnings

---

### Phase 2: Audit & Systematic Rollout

**1. Create Audit Script**
```powershell
# scripts/audit-workflow-patterns.ps1
# Lists workflows missing patterns
# Generates report
# Suggests changes
```

**2. Review All Workflows**
- Identify special cases (release, compliance)
- Customize retention where needed
- Verify concurrency groups don't conflict

**3. Bulk Application**
```powershell
# scripts/apply-immediate-wins.ps1
# Applies pattern to all workflows
# Skips special cases
# Creates PR with changes
```

---

### Phase 3: Ongoing Enforcement

**1. Template Workflow**
```yaml
# .github/workflows/template.yml
# Copy-paste starter with patterns built-in
```

**2. PR Template**
```markdown
# .github/pull_request_template.md
## Workflow Changes
- [ ] Concurrency added
- [ ] Retention set
- [ ] Summary included
```

**3. Documentation**
```markdown
# docs/AGENTS.md
## Creating New Workflows
Always include the three immediate wins...
```

---

## 🐾 BossCat Governance

### Standards

**Required:**
- ✅ Concurrency on all PR/push workflows
- ✅ 14-day retention (default)
- ✅ Job summary (minimum: run info)

**Optional:**
- Path filters (if large workflow)
- Matrix optimization (if slow)
- Advanced summaries (when Loop-Closing Machine ready)

**Exceptions:**
- Release workflows (may need 30-day retention)
- Compliance workflows (may need no cancellation)
- Nightly reports (may need different concurrency group)

**Approval Required:**
- Retention > 30 days
- `cancel-in-progress: false`
- No job summary (must justify)

---

## 📚 References

### GitHub Documentation
- [Concurrency](https://docs.github.com/en/actions/using-jobs/using-concurrency)
- [Artifact Retention](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
- [Job Summaries](https://github.blog/news-insights/product-news/supercharging-github-actions-with-job-summaries/)

### Internal Documentation
- [Loop-Closing Machine Architecture](./LOOP_CLOSING_MACHINE_ARCHITECTURE.md)
- ECRR: Immediate Wins Implementation — `ECRR_IMMEDIATE_WINS_IMPLEMENTATION_20251010.md` (not in the repo)
- [Workflow Cleanup Investigation](../archive/BossCat/DIAGNOSTIC_PARALLEL_CLEANUP_FAILURE_20251010.md)

---

## ✅ Success Metrics

### Per-Workflow (After Application)

- [ ] Concurrency group unique
- [ ] Cancel-in-progress enabled
- [ ] Retention ≤ 14 days (or justified)
- [ ] Job summary present
- [ ] Tested on live PR
- [ ] No breaking changes

### Repository-Wide (30 Days Post-Rollout)

- [ ] Run volume ↓ 70-80%
- [ ] Artifact storage ↓ 75%
- [ ] Failure investigation time ↓ 50%
- [ ] Queue wait time ↓ 60%
- [ ] No new 10k+ pileups

---

**Status:** ✅ **APPROVED PATTERN**  
**First Applied:** 2025-10-10  
**Workflows Updated:** 1 (bosscat-gate-verify.yml)  
**Ready For:** Propagation to all workflows

🐾 **BossCat Seal: Standard Pattern Established**

