# BossCat Agent Standards & Workflow Patterns

NOTE: This file defines workflow standards. Canonical index: AGENTS.md (repo root). Canonical charter: docs/BossCat/CHARTER.md.

**Authority:** BossCat OEM (Executive Overseer Manager)  
**Status:** ✅ **ACTIVE STANDARD** — All agents must comply  
**Last Updated:** 2025-10-10 (Phase 1 Immediate Wins)

---

## 🐾 Agent Hierarchy

See: `docs/BossCat/CHARTER.md` (charter) for full agent hierarchy and ECRR methodology.

---

## ⚡ Workflow Standards (Immediate Wins - Phase 1)

<!-- markdownlint-disable-next-line MD013 -->
All GitHub Actions workflows MUST include the three immediate wins patterns. These prevent run accumulation and improve developer experience.

### Pattern 1: Concurrency Control (ALFA Track)

**Required for:** All workflows with `pull_request` or `push` triggers

**Pattern:**

```yaml
concurrency:
  group: <workflow-name>-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # or false for scheduled/nightly workflows
```

**Why:** Prevents queue pileup by cancelling superseded runs. Only the latest run per PR/branch executes.

**Impact:** 70-80% reduction in workflow runs

**Reference:** [GitHub Docs: Concurrency](https://docs.github.com/en/actions/using-jobs/using-concurrency)

---

### Pattern 2: Artifact Retention (BRAV Track)

**Required for:** All `upload-artifact` steps

**Standard Pattern:**

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: my-artifact
    path: artifacts/**
    retention-days: 14  # Standard: 14 days
```

**Exceptions (Require Justification):**

- `30 days`: Compliance artifacts, executive dashboards, nightly reports
- `90 days`: Audit trail, legal requirements (rare)

**Why:** Auto-expiry prevents 10k+ run accumulation

**Impact:** 75% storage cost reduction, automatic cleanup

**Reference:** [GitHub Docs: Artifact Retention](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)

---

### Pattern 3: Job Summaries (CHAR Track)

**Required for:** All workflows

**Minimum Pattern:**

```yaml
- name: 📋 Run Summary
  if: always()
  run: |
    {
      echo '### ${{ github.workflow }} - Run Summary';
      echo '';
      echo "**Workflow:** ${{ github.workflow }}";
      echo "**Run:** #${{ github.run_number }} (attempt ${{ github.run_attempt }})";
      echo "**Ref:** \`${{ github.ref }}\`";
      echo "**Actor:** @${{ github.actor }}";
      echo "**Status:** ${{ job.status }}";
      echo '';
      echo '[View full run](${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }})';
    } >> "$GITHUB_STEP_SUMMARY"
```

**Why:** Instant context without log diving

**Impact:** 2-5 minutes saved per failure investigation

**Reference:** [GitHub Blog: Job Summaries](https://github.blog/news-insights/product-news/supercharging-github-actions-with-job-summaries/)

---

## 📋 Workflow Creation Checklist

When creating or updating workflows:

- [ ] Concurrency group added (unique per workflow)
- [ ] `cancel-in-progress` set appropriately (true for PR/push, false for scheduled)
- [ ] All `upload-artifact` steps have `retention-days` set
- [ ] Retention follows standard (14d) or exception is documented
- [ ] Job summary step included at end
- [ ] Summary includes minimum fields (workflow, run, ref, actor, status)
- [ ] Tested with test PR (for concurrency validation)

---

## 🎯 Templates & Examples

**Full Template:** See `.github/workflows/template.yml` (TBD - DELT-2)

**Working Examples:**

- `.github/workflows/bosscat-gate-verify.yml` (all 3 patterns)
- `.github/workflows/boss-gate-verify.yml` (all 3 patterns)
- `.github/workflows/iona-gate-verify.yml` (all 3 patterns)

**Pattern Library:** See `docs/BossCat/WORKFLOW_IMMEDIATE_WINS_PATTERN.md`

---

## 🔧 Retention Policy Reference

| Artifact Type | Retention | Justification |
|---------------|-----------|---------------|
| Test results | 14 days | Standard debugging window |
| Build artifacts (non-release) | 14 days | Typical PR lifetime |
| Security scan results | 14 days | Recent issues matter most |
| Executive dashboards | 30 days | Compliance + trend analysis |
| Nightly benchmark data | 30 days | Performance trending |
| Audit trail / compliance | 90 days | Legal/regulatory (rare, requires approval) |
| Release artifacts | Use GitHub Releases | Not workflow artifacts |

---

## 🐾 BossCat Compliance

**Authority:** BossCat OEM  
**Enforcement:** Automated policy checker (Phase 3)  
**Review:** Monthly compliance scorecard  
**Exceptions:** Require BossCat OEM approval + documentation

**Non-Compliance Actions:**

- Warning: Auto-generated PR with fixes
- Repeated: Workflow disabled until compliant
- Release Blockers: Gate fails if critical workflows non-compliant

---

## 📚 Related Documentation

- **Loop-Closing Machine:** `docs/BossCat/LOOP_CLOSING_MACHINE_ARCHITECTURE.md`
- **Pattern Library:** `docs/BossCat/WORKFLOW_IMMEDIATE_WINS_PATTERN.md`
- **ECRR Charter:** `docs/BossCat/CHARTER.md`
- **Phase 1 ECRR:** `CHAR/ECRR/ECRR_REPORTS/ECRR_PHASE1_IMMEDIATE_WINS_*.md`

---

**Last Updated:** 2025-10-10 (Phase 1 execution)  
**Status:** Active standard - all new workflows must comply  
**Seal:** 🐾 **BossCat Executive Standard**

