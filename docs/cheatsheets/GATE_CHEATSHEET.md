# Gate Cheatsheet

## One-liner (local)

```powershell
pwsh -NoProfile -File scripts/verify-iona-gate.ps1 -Strict   # alias: pnpm run agent:ready-for-gate
```

*(`scripts/local-gate-runner.ps1`, cited here until 2026-09-02, never existed in the tree.)*

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

This signals the gatekeeper for hand-off (does NOT auto-merge). *Note (2026-09-02): the workflow that consumed
the phrase, `boss-gate-signal-and-merge.yml`, is `workflow_dispatch`-only since 2026-08-03; merging is the machine
operator's call per `docs/BossCat/CHARTER.md`.*

## Evidence Locations

- `docs/status/tests.json` - Gate verdict ledger
- `CHAR/ECRR/ECRR_REPORTS/` - per-change ECRR evidence
- `docs/observability/snapshots/` - Raw evidence blobs

## Budgets (Immutable)

- ≤10 files changed
- ≤200 LOC per docs PR (GR-02; `lane:cleanup` waiver for sweep passes)
- One lane per PR — docs / code / CI-ops / evidence, never mixed (`docs/BossCat/CHARTER.md`)

## ECRR Framework

Every gate run follows:

1. **Examine** - Capture state before
2. **Clean** - Fix/validate
3. **Report** - Generate evidence
4. **Role** - Declare actor/responsibility

---

## Automated Evidence Management

*The "Weekly Guardrails Re-Certification" formerly listed here referenced `guardrails-recert.yml`, which does not
exist; structure compliance runs on every PR via `guardrails.yml` (a required check).*

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


