# ECRR — Compliance Engine Retirement

**Date:** 2026-08-03
**Actor:** Claude (chat/review seat); decision by machine operator `@fubumaki`
**Verdict:** **GREEN** — engine core deleted, decision recorded; second wave inventoried, not executed

## 1. Examine

Decision memo `docs/BossCat/MEMO_ECRR_COMPLIANCE_ENGINE_20260803.md` recommended retiring the
ECRR compliance engine; the operator approved on 2026-08-03. The load-bearing findings:

- `validate-ecrr-compliance.ps1` defaulted `MinFourSectionPct`/`MinGatePct` to `0` and no
  caller overrode them, so `passed = (pct >= 0) -and (pct >= 0)` — **structurally incapable
  of returning false**. All 13,682 archived verdicts read `passed: true` by arithmetic.
- The one real threshold (80% four-section, in the CI entrypoint) measured a metric held at
  **100%**, while fully-compliant — **23.2%** of 393 reports — was gated by nothing.
- Both consumers exited `1` daily against inputs no script in the repo writes.
- `scripts/remediate-ecrr-compliance.ps1`, invoked by the auto-remediation step of both
  compliance workflows, does not exist.

Reference inventory before deleting found the engine sits inside a ~20-file cluster in
`BRAV/SCPT`. Nearly every reference in that cluster points at `scripts/<name>.ps1` while the
files actually live in `BRAV/SCPT/` — a path drift dating to the tetragram reorganisation, so
most of the cluster was already broken independently of the thresholds. One script
(`setup-signoz-integration.ps1`) *generates* another (`export-ecrr-metrics-to-signoz.ps1`) at
a path that no longer holds it.

## 2. Clean

Deleted — the engine core and everything that cannot function without it:

| Path | Why |
|---|---|
| `BRAV/SCPT/validate-ecrr-compliance.ps1` | the engine; unconditional `passed` |
| `scripts/ecrr-compliance-check.ps1` | CI entrypoint; only callers were the two workflows below |
| `BRAV/SCPT/ecrr-compliance-monitoring.ps1` | dot-sources the engine; cannot run without it |
| `.github/workflows/ecrr-compliance.yml` | dispatch-only since #428; called the engine and a missing remediation script |
| `.github/workflows/ecrr-compliance-scheduled.yml` | same, on a weekday cron |

**Not deleted, deliberately.** The wider cluster (`ci-ecrr-compliance`, `monitor-ecrr-compliance`,
`monitor-ecrr-compliance-trends`, `ecrr-compliance-dashboard`, `-enhancement`, `-trend-analyzer`,
`-validation`, `unified-ecrr-compliance`, `lint-ecrr-compliance`, `setup-ecrr-compliance-*`,
`post-workshop-validation`, `visualize-ecrr-trends`, `export-ecrr-metrics-to-signoz`, and the
byte-identical pair `ecrr-compliance-monitor` / `continuous-ecrr-compliance-monitor`) is
unreachable — no workflow and no scheduled task invokes it — but removing ~20 interlinked files
is its own reviewable change, not a footnote to this one. Second wave, operator-gated.

`benchmark-process-all-ecrr-reports.yml` is also **kept**: it is a processing-speed benchmark,
not the compliance engine, and it currently exits 0. It is consumer-less now that
`nightly-dashboard-export` is retired, which is a separate disposition question.

## 3. Report

| Metric | Before | After |
|---|---|---|
| Workflows invoking the engine | 2 (dispatch-only) | 0 |
| Scripts able to emit a compliance verdict | 3 | 0 |
| Verdicts capable of returning false | 0 of 13,682 | n/a — engine gone |
| Scheduled tasks failing daily on engine outputs | 2 | 2 — **pending** operator unregister (elevated) |
| Unreachable ECRR cluster scripts remaining | ~20 | ~20 — inventoried, second wave |

Prior outputs remain immutable in `otel-ops-evidence` @ `00a31b0` (five monthly zips, 13,682
files). Deleted scripts remain in git history; nothing was rewritten.

**The ECRR practice is unchanged.** The lean four-section report per change — quantified
before/after, honest verdict — is lane discipline enforced by review. This report is one. What
was retired is the machinery that scored the reports, not the reports.

## 4. Role

Chat/review seat inventoried, deleted, and documented. Machine operator `@fubumaki` approved the
decision. **Open operator action (elevated):** unregister `ECRR-Compliance-Trends` and
`ECRR-SigNoz-Export`, which will keep failing daily until they are removed —

```powershell
Unregister-ScheduledTask -TaskName 'ECRR-Compliance-Trends' -Confirm:$false
Unregister-ScheduledTask -TaskName 'ECRR-SigNoz-Export' -Confirm:$false
```

With those two gone, the final Phase 0 item of Roadmap 2026 H2 is closed and Phase 1 — the
Windows collector keep-or-retire decision — is the next gate.

**Status:** COMPLETE

## ECRR Gate

- Gate: PASS
- Scope: Structural normalization only.
- Evidence Reference: artifacts/ecrr-compliance-metrics.json.
- Guardrail: Append-only; original report body unchanged.
