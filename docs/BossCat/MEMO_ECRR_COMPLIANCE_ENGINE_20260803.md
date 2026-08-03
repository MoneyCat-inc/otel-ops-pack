# Decision memo — ECRR compliance engine: retire or fix

**Date:** 2026-08-03
**Drafted by:** Claude (chat/review seat) for operator decision
**Scope:** Roadmap 2026 H2, Phase 0, final open item
**Recommendation:** **Retire.**
**Decision:** **Approved 2026-08-03 by machine operator @fubumaki** — retire the engine,
keep the four-section practice. Execution and closeout land in a separate CI/ops PR.

---

## What the engine is

A chain of three parts: `scripts/ecrr-compliance-check.ps1` (CI entrypoint) calls
`BRAV/SCPT/validate-ecrr-compliance.ps1` (scans `CHAR/ECRR/ECRR_REPORTS/*.md` for
four-section headings, an ECRR-gate heading, an actor declaration, and a production
marker), which writes a JSON verdict. Two daily scheduled tasks then read that verdict:
`ECRR-Compliance-Trends` (visualiser) and `ECRR-SigNoz-Export` (metrics exporter).

## Findings

**1. The `passed` verdict cannot be false.** `validate-ecrr-compliance.ps1` defaults
`MinFourSectionPct` and `MinGatePct` to `0`, and no caller overrides them. Line 128 then
computes `passed = (pct >= 0) -and (pct >= 0)`. A percentage is never negative, so every
one of the 13,682 archived verdicts reads `passed: true` by arithmetic, not by assessment.

**2. The one real threshold is inert.** The CI entrypoint does gate — it exits 1 below
80% four-section compliance. But four-section compliance currently sits at **100%** (393
reports), and the two most recent ECRR commits (`7ddcb22f1`, `21affb783`) were work done
to *keep* it there. The gate measures the metric we maintain rather than one that tells
us something we did not already know.

**3. The metric that does discriminate is gated by nothing.** Fully-compliant — all four
checks passing — is **23.2%**. Nothing reads it, nothing alerts on it, no threshold
references it.

**4. Both consumers have been failing silently, daily.** `ECRR-Compliance-Trends` and
`ECRR-SigNoz-Export` both exited `1` on their 2026-08-03 runs. Each reads an input file
that nothing in the repo writes: `artifacts/ecrr-compliance-history.jsonl` and
`artifacts/ecrr-ci-validation.json` respectively (the validator writes
`ecrr-compliance-report.json` and `ecrr-compliance-check-*.json` instead). The exporter's
own append-only log, `artifacts/ecrr-signoz-export-history.jsonl`, is absent, and the
exporter cannot reach the line that writes it while its input is missing. (The log is
prunable by the weekly artifacts cleanup, so its absence alone does not prove it never
ran — but no ECRR compliance metric is reaching SigNoz now, and none can until the input
file is produced by something.)

**5. Supporting machinery is missing or duplicated.** `scripts/remediate-ecrr-compliance.ps1`
— invoked by the auto-remediation step of both compliance workflows — does not exist.
`BRAV/SCPT` holds 62 ECRR-related scripts, including at least one byte-identical pair
(`ecrr-compliance-monitor.ps1` / `continuous-ecrr-compliance-monitor.ps1`).

**6. Most of it is already stopped.** The producer was unregistered before 2026-08-03; the
13,682 outputs are archived in `otel-ops-evidence` @ `00a31b0`; all three compliance
workflows were retired to dispatch-only in #428. What remains live is two daily tasks that
fail on startup.

## The two branches, costed honestly

**Fix** means: set real thresholds, repoint them from four-section to fully-compliant,
create the two missing input files, restore the missing remediation script, and — the part
that is not mechanical — name the decision the number informs and the person who acts on
it. A real threshold on the discriminating metric fails immediately at 23.2%, and clearing
it means editing 393 historical reports. That is a report-normalization campaign, which
the roadmap lists under **explicit non-goals for 2026 H2**. The fix branch cannot be
completed without breaking a stated commitment.

**Retire** means deleting the engine and its scripts, unregistering the two failing tasks,
and keeping the ECRR *practice* — the lean four-section report written per change, with a
quantified before/after and an honest verdict. That practice is lane discipline enforced by
review, and it survives untouched. What goes away is the machinery that scored it.

## Recommendation

Retire. The engine measures report formatting, not system health; its verdict is
arithmetically incapable of failing; its consumers fail daily on inputs nothing writes; and
making it meaningful requires the one campaign the roadmap rules out. Phase 4 asks what this
stack should observe — a compliance engine observing the shape of its own reports is the
clearest example of the self-referential machinery Phase 0 exists to subtract.

**Execution** (separate CI/ops PR): inventory before deleting — the 62 `*ecrr*` matches in
`BRAV/SCPT` include unrelated benchmark and extraction tooling. Unregistering
`ECRR-Compliance-Trends` and `ECRR-SigNoz-Export` is a machine-operator action, elevated.
One closeout ECRR ends it.
