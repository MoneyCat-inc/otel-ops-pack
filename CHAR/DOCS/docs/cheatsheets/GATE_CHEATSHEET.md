# Gate Cheatsheet

## One-liner (local)

```powershell
pwsh -File scripts/local-gate-runner.ps1
```

## Kill-switch

Create `.agent/LOCK` to halt; remove to resume. **Hard stop mid-run is mandatory.**
Evidence remains under `docs/observability/snapshots/`.

```powershell
New-Item .agent/LOCK -ItemType File
Remove-Item .agent/LOCK
```

## Gate Phrase

When all checks pass and `docs/status/tests.json` shows `READY`:

```text
@cat ready-for-gate
```

This signals the gatekeeper for hand-off (does NOT auto-merge).

## Evidence Locations

- `docs/status/tests.json` - Gate verdict ledger
- `docs/status/ecrr-summary.json` - ECRR report metrics
- `docs/observability/snapshots/` - Raw evidence blobs

## Budgets (Immutable)

- ≤2 jobs per pass
- ≤10 files changed
- ≤ 2,000 LOC non-move changes

## ECRR Framework

Every gate run follows:

1. **Examine** - Capture state before
2. **Clean** - Fix/validate
3. **Report** - Generate evidence
4. **Role** - Declare actor/responsibility

---

## Automated Evidence Management

### Weekly Guardrails Re-Certification

- **Schedule:** Monday 03:00 UTC
- **Action:** Verify guardrails config hash, run compliance check
- **Evidence:** `docs/observability/snapshots/guardrails-recert-*.json`
- **Alert:** GitHub Issue on drift detection
- **Workflow:** `.github/workflows/guardrails-recert.yml`

### Monthly Evidence Rollup

- **Schedule:** 1st day of month, 02:00 UTC
- **Action:** Archive snapshots and ECRR reports older than 30 days
- **Archive:** `CHAR/PRSV/evidence-archives/evidence-rollup-YYYY-MM.tar.gz`
- **Report:** `CHAR/ECRR/ECRR_REPORTS/ECRR_EVIDENCE_ROLLUP_YYYY-MM.md`
- **Retention:** 90-day artifact retention, indefinite archive
- **Workflow:** `.github/workflows/bosscat-monthly-evidence-rollup.yml`

**Manual Trigger:**

```text
GitHub Actions → "Monthly Evidence Rollup" → Run workflow
```


