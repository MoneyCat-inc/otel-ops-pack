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

```
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
- ≤200 LOC non-move changes

## ECRR Framework

Every gate run follows:
1. **Examine** - Capture state before
2. **Clean** - Fix/validate
3. **Report** - Generate evidence
4. **Role** - Declare actor/responsibility

