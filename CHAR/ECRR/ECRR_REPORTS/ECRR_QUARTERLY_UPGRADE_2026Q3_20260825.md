# ECRR — Quarterly stack upgrade, Q3 2026

**Date:** 2026-08-23 → 2026-08-25  
**Actor:** chat/review seat (Claude) + machine operator `@fubumaki`; external research memo (Cursor seat) verified before use  
**Verdict:** **GREEN — CLOSED**  
**PRs:** #591/#592 (collector pin + runbook), #593 (clean-host result), #594 (single pin + drift guard), #595/#596 (SigNoz + collector), #597 (step-2 result), #598/#599 (ClickHouse + compat pin), #600 (profile profiler), #601 (step-3 result), #602 (global profiler), #611 (pnpm note)  
**Incidental:** #612/#613/#614 (evidence rollup excavation), #615 (dual-token amber watch)

## 1. Examine

- Audit 2026-08-23 vs upstream: otelcol-contrib 0.158.0 (0.159.0 out), SigNoz v0.135.1 (v0.138.0 out), ClickHouse 25.8 (chart pins 25.12.5), `system.trace_log` regrown to 5.75 GiB in 5 days post-incident (~2 GiB/day).
- Research memo verified with `gh` before pinning; three version attributions corrected (hostmetrics cpu change was v0.157.0 not v0.159.0; chart pins collector v0.144.8 not v0.144.9; ClickHouse 25.12.5 pre-emptive, not a hard prereq).
- Upstream shift: SigNoz v0.138.0 deprecates bundled compose/install.sh for Foundry → Helm chart `values.yaml` is now the pin authority.

## 2. Clean

- **Step 1** — otelcol-contrib **0.159.0** (no windowseventlog changes). Clean-host E2E 2026-08-23: functional GREEN (verify exit 0; clock estimated ~5–7 min, not measured; canary-test skipped — hangs on first Event Log source registration). Exposed a two-pin regression; collapsed to `scripts/windows/collector-version.txt` + hygiene-fast drift guard proven to fail and pass.
- **Step 2** — SigNoz **v0.138.0** + collector **v0.144.8** (chart pair). Metastore backed up; migrator exit 0; verify-pipeline exit 0, canary PINPOINT. Saved-views discovery v2-first with JSON-shape check (pre-0.137 SigNoz returns index.html HTTP 200 on the v2 path); v1 POST upsert body deferred and annotated.
- **Step 3** — ClickHouse **25.12.5**. Writers stopped; volume snapshot 4.45 GB verified (tar exit 0, 57,953 entries). `escape_variant_subcolumn_filenames=0` pinned (25.11 #87300 renames Variant stream files in Wide parts; we hold 25.8-written Wide parts with JSON columns). Old-data reads at baseline (traces 74,661 exact; forced Wide-part scan clean). verify-pipeline exit 0.
- **Profiler knob family closed** (each found because the previous fix was made able to fail): `total_memory_tracker_sample_probability` (08-18) → `total_memory_profiler_step` (#598) → profile-level `memory_profiler_step` (#600, merges sample through it, ~40k rows/min) → `global_profiler_*_period_ns` (#602, **25.12 enables the server-wide thread profiler by default**, ~25M rows/day). Query-level 1 s profiler left ON deliberately (~90k rows/day, useful, TTL-bounded). Renamed `system.*_0` orphans (5.9 GiB) dropped by operator.

## 3. Report

| Check | Before | After |
| --- | --- | --- |
| otelcol-contrib | 0.158.0, pin in 2 places (1 untracked) | 0.159.0, one pin file + commit-time drift guard |
| SigNoz / collector | v0.135.1 / v0.144.6 | v0.138.0 / v0.144.8 (chart-tested pair) |
| ClickHouse | 25.8 | 25.12.5, compat-pinned, snapshot-backed |
| `system.trace_log` | ~2 GiB/day regrowth | **flat 24 h** (formal T+24h: Memory/Peak **0**, empty-qid **57.9/h** vs <500 bar, 2.42 GiB steady) |
| Rollback assets | — | `signoz.db.pre-0.138.0-*`, `clickhouse_data.pre-25.12.5-*.tgz` (4.45 GB, verified) |

24 h record: clock 2026-08-24T12:41:25Z → formal read 2026-08-25T12:41:26Z, criteria per adjusted bar (empty-qid rows attributed to the single `RuntimeData` housekeeping thread under the deliberate 1 s profiler).

**Deferred (accepted):** ClickHouse 26.x until the SigNoz chart pins it; productisation (PURPOSE trigger 2 unfired); v1 saved-views POST body rewrite; clean-host clock re-measurement; Node-20 workflow lanes.

**Incidental finding, fixed in flight:** the monthly evidence rollup had been green since creation while structurally unable to deliver — mtime selection (matches nothing on fresh CI checkouts) → protected-main direct push (GH006) → expired `BOSSCAT_TOKEN` (dead in place since ~2025-10). Each layer surfaced only because the previous one was made able to fail (#612 → #613 → #614 landed the 500-file backlog; #615 puts both FG PATs under amber watch). The standing rule held: **a check must be able to both pass and fail.**

## 4. Role

Chat/review seat drafted, verified upstream claims, drove the step-3 apply under explicit operator go, and re-verified every operator report live. Operator held gate authority throughout: merges, clean-host run, step-2 apply, orphan DROPs, token mint. No self-ratified gates.
