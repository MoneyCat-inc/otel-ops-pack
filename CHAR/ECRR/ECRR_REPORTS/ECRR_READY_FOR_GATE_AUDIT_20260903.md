# ECRR — Ready-For-Gate Audit (post text_log closure, post truth sweep)

**Date:** 2026-09-03 (16:00–16:35Z)
**Actor:** Claude (chat/review), acting as BossCat OEM auditor on operator request (`@cat Ready-For-Gate`)
**Scope:** Everything that changed since the 2026-08-29 audit (`ECRR_BOSSCAT_AUDIT_DRIFT_20260829.md`):
PRs #649–#750, the quarterly upgrade, the watchdog vitals, the docs truth sweep, the VHDX arc.
**Method:** Every claim in `BOSSCAT_LOG.md`, `CHARTER.md`, `PURPOSE.md` and the last twelve ECRRs
re-checked against the live host, the live containers, GitHub, and the tree at `b6bb8d25f`.
Nothing below is quoted from a record without a live read behind it.
**Verdict:** **AMBER (non-blocking).** Stack GREEN and matching its record. Two operator-keyboard
items (P1) found that no gate covers: the daily host runs one collector minor behind the single pin,
and the logon task still spawns the codex-local working-tree writer Phase 0 declared gone.

---

## 1. Examine

### 1a. Live stack vs record — all GREEN, all matching

| Claim (source) | Live read 2026-09-03 | Match |
| --- | --- | --- |
| text_log loop dead (#746/#748) | `system.text_log` 0 rows; `MEMORY_LIMIT_EXCEEDED` absent from `system.errors`; `MergesMutationsMemoryTracking` 0 B; `MemoryTracking` 307 MiB; both memory keys `changed=1` (2.5 GiB / 1 GiB); uptime 2,673 s | ✅ |
| VHDX compacted to ~50 GB | `docker_data.vhdx` 51.11 GB on disk; watchdog `vhdx_gb` 50.2 → 51.1 over 40 min, last four ticks +0.2 GB total | ✅ (24 h read still open) |
| Collector Running/Automatic on 5320/5321 (CHARTER) | `otelcol-contrib` Running, Automatic; 5320/5321/4317/4318/8080 all listening; SigNoz `/api/v1/health` `{"status":"ok"}` | ✅ |
| Compose pins (quarterly ECRR) | signoz v0.138.0 / signoz-otel-collector v0.144.8 / ClickHouse 25.12.5 / zookeeper 3.9.3 running healthy; GitLab 18.5.1 healthy alongside | ✅ |
| Watchdog ticking with vitals | `watchdog.log` 8,885 lines, newest tick 17:15+01:00, `ok` with `c_free_gb` / `vhdx_gb` / `start_type` | ✅ |
| Host scheduled tasks | `OTel-Canary-ECRR` rc 0 (5 min), `OTel-Docker-Weekly-Trim` rc 0, `OTel-Wiring-Verification-Weekly` rc 0, `OTel-Artifacts-Cleanup` rc 0; three `Resonai-*` rc 2 (legacy, disposition already tracked) | ✅ |
| C: free | 475 GB (50 % used) | ✅ |

### 1b. Governance surfaces — all current

| Surface | State |
| --- | --- |
| Security alerts (Dependabot / code scanning / secret scanning) | 0 / 0 / 0 open |
| Open PRs | 0 |
| CI on `main` @ `b6bb8d25f` | 8/8 workflows success |
| Scheduled workflows | 12 on disk = PURPOSE.md amendment count; last scheduled run of each: success |
| Registries | `scripts.json -Check` current (172); `workflows.json` 61/61 matches disk; guardrail (`check_guardrails.py`) GREEN in CI as a required check |
| Docs mirror | `HEAD:docs` tree OID `d8311dd7…` == `HEAD:CHAR/DOCS/docs` (byte-identical in git; the 170 working-tree diffs are CRLF checkout noise, see 1e) |
| Evidence repo | `otel-ops-evidence` pushed 2026-09-03T12:51Z (archiver); September rollup ran 09-01 on schedule |
| Lint burn-down (B1, canonical command from `B1_REMEASURE_20260815.md`) | **1,511** findings across live docs — down from the recorded standing 3,992 (truth sweep #704–#719 did it; nobody re-measured) |
| PURPOSE trigger 1 (re-evaluated) | Not fired: `moneycat-site` 1 distinct commit day since 08-04, `viz-engine` 1 (archive closeout), `scorebot` / `socm` 0. Steady-state stands |
| Kiro{Implementer} | 1 commit since the 08-14 verdict; seat idle, not wrong |

### 1c. Findings — P1 (operator keyboard, no gate covers them)

**P1-1 · Daily host runs collector 0.158.0; the single pin says 0.159.0.**
`scripts/windows/collector-version.txt` = `0.159.0` (moved 2026-08-23, #591), the `phase0-setup.ps1`
fallback = `0.159.0`, and the clean-host E2E of 08-23 ran on 0.159.0. The daily host binary reports
`otelcol-contrib version 0.158.0`. The CHARTER "stack facts" line and the runbook's 2026-08-13
paragraph are truthful about the host, but the quarterly ECRR's before/after table
("0.158.0 → 0.159.0, one pin file") reads as if the estate moved. The commit-time drift guard
compares the two files to each other, not to the machine, so it cannot see this. Either the host
takes the 0.159.0 MSI (operator; runbook upgrade section, ~10 min, watchdog covers the restart) or
the runbook states in one line that the daily host deliberately lags the pin. Recommend the upgrade:
the pin exists so a clean host and the daily host install the same thing.

**P1-2 · `\BossCat\IONABossCatBootHealth` still spawns the codex-local working-tree writer.**
The logon task (`D-MONOLITH\fubum`, InteractiveToken, WorkingDirectory `C:\otel\scripts`) runs
`scripts/boot-health-check.ps1 -Environment dev -SendTelemetry`, which wraps
`BRAV/SCPT/boot-health-check.ps1`, whose "Watchdog Auto-Start" block (lines 169–187) starts
`BRAV/SCPT/agent/watchdog.ps1` hidden. That script is the codex-local "Local Workflow Custodian":
a 300 s loop that appends to `TASKS.md` and rewrites a queue JSON in the working tree. Roadmap
Phase 0 named "the 30s watchdog spawned at startup" as a thing to unregister and closed on the exit
criterion "no recurring writer left running against the working tree". The criterion holds today by
accident: at logon the cwd is `C:\otel\scripts`, so the custodian cannot find `.agent/config.json`
and exits 1 within a second. Run from `C:\otel`, as this audit did once (see section 2), it starts
and loops. The task has been "exit 1, needs diagnosis" since the 08-13 second-wave ECRR; the
diagnosis is above (the 6/6 boot reports on disk are healthy; the exit code is the custodian's, not
the health check's). Recommend the operator unregisters the task (its six checks are covered by
`BossCat-OtelcolWatchdog` plus gate-nightly), or at minimum the auto-start block is deleted from
`boot-health-check.ps1` in a code-lane PR.

### 1d. Findings — P2 (process and hygiene)

**P2-1 · The docs gate went RED on two of today's merges and neither merge waited for it.**
`docs-lane-checks` is not in the required-check set on `main` (required: CodeQL, PSScriptAnalyzer,
gitleaks, Gate k6, Gate synthetic trace, Site links, Repository Structure Compliance). Today:

- #744's branch: GR-03 AMBER (`DOCKER_VHDX_MAINTENANCE.md` MD013 ×2), merged, then fixed after
  merge by #745.
- #749 (log line only): GR-02 RED at 15:48Z because the branch was stacked on #748's unmerged ECRR
  change (`OUT_OF_LANE_COUNT: 1` at run time, which was correct); #748 merged 15:50Z, #749 merged
  15:53Z without a re-run. On re-run it would have passed.

Neither log line records the override. `docs_gate` is advisory by a recorded decision (a
path-filtered workflow cannot be required without blocking every code PR), so the control is
procedural and already on record since #528: the merge waits for the gate run's conclusion and
refuses on anything but success. Today's two merges broke that rule. Recommend no new machinery:
rebase stacked docs branches on `main` once the parent lands and re-run, and when a red is
overridden on purpose, the log line says so and why.

**P2-2 · Worktree and branch hygiene.** 12 registered worktrees, 10 stale: seven Cursor worktrees at
`9f697d7f5` (2025-10-22, one with 3 dirty files), `C:/otel-kiro-pilot` (#472 merged 08-14, 230 MB),
`C:/otel/.claude/worktrees/agent-ad34…` (#694 merged 09-01), one prunable scratchpad entry.
`C:/otel-main-worktree` is on `ci/enable-otel-health-on-main-min`: 44 commits ahead of `main`, no
remote, last commit 2025-09-23. Inspect before removing. Remote branches: 174, of which 76 are
detectably merged (squash-merged ones do not show as merged, so the real stale count is higher);
`delete_branch_on_merge` is off. Recommend enabling auto-delete (repo settings, operator), a one-time
prune of merged remotes, and `git worktree remove` for the nine safe ones.

**P2-3 · Untracked leftovers in the working directory that the guardrail sees locally.** Deleted-in-git
directories still on disk and not ignored: `bosscat-svc2-api/`, `bosscat-svc3-worker/`, `scorebot/`,
`synthetic/`. Ignored but present at root: `.env.bak-pre-rotate-20260724-112048`, `.env.socm`,
`CLOUDFLARE-*-HANDOFF.md`, `test-api-proof.ps1`, `test-signoz-api.ps1`, `config/`, `configs/`,
`dotnet-autoinstrumentation/`, `moneycat-site/`, `NHA/`. Effect: `check_guardrails.py` reports 3+11+7
violations locally and 0 in CI, a local red that means nothing and trains people to ignore it. The two
`.env*` files are pre-rotation credential backups sitting in the directory every agent seat runs in;
whether or not the values are dead, they do not belong there. Operator: move the `.env*` files out,
delete the four unignored leftover directories. Also
`CHAR/PRSV/experiments/experiments/codex-local-logfilter/.pytest_cache/` is owned by another
principal and makes every `git status` print a permission warning: `takeown` then delete.

### 1e. Findings — P3 (stale text) and non-findings

- `ROADMAP_2026H2.md` standing cadence still says "SigNoz current as of v0.135.1, 2026-08-03";
  live is v0.138.0 (quarterly, 08-25). One line.
- `docs/status/workflows.json` carries `modified` and `size` per workflow; a regeneration on a
  current tree yields 104 changed lines of timestamps only. The registry guard compares
  names/triggers/total, so this is not a failure, but the volatile fields invite a needless churn
  commit. Consider dropping them the next time the generator is touched (scripts.json already went
  date-free in #731).
- **Not a finding:** `diff -rq docs CHAR/DOCS/docs` shows 170 differences on this checkout. They are
  CRLF (working tree) vs LF (mirror); `.gitattributes` `eol=lf` normalises on commit and the two git
  trees are the same OID. Parity is proven by `git rev-parse HEAD:docs HEAD:CHAR/DOCS/docs`, not by
  diffing checkouts.
- **Not a finding:** `Get-ScheduledTask` from an unelevated shell does not list
  `BossCat-OtelcolWatchdog` or `\otel_canary_10m` (SYSTEM tasks). Proof of life is `watchdog.log`
  (5-min cadence, unbroken) and the `OTel-Canary-ECRR` result, both read above.
- **Could not verify from this seat:** Hyper-V `clean-host-e2e` VM state (Get-VM denied unelevated).
  The record says Off since 09-01; the 09-28 freshness check needs `Start-VM` first.

## 2. Clean

Audit, not remediation. One side effect and one artifact:

- **Side effect, reversed.** Running `BRAV/SCPT/boot-health-check.ps1 -Environment dev` (to diagnose
  P1-2) started `agent/watchdog.ps1` (PID 59560, 17:26:51+01:00). Stopped at 17:28 after reading its
  source; it lived about 70 s and wrote nothing (`git status` clean, no `TASKS.md`, no queue file). It
  also wrote `artifacts/boot-reports/boot-health-20260903-172653.json` (ignored path, left in place).
- `regenerate-workflows-registry.ps1` was run to measure drift and the result reverted with
  `git checkout`; nothing committed.
- This report. A companion docs-lane PR adds the `BOSSCAT_LOG.md` line.

## 3. Report

| Metric | Before (record) | Live 2026-09-03 |
| --- | --- | --- |
| Security alerts open (3 tabs) | 0 / 0 / 0 (08-28) | 0 / 0 / 0 |
| Scheduled workflows | 12 | 12 |
| `text_log` rows / `MEMORY_LIMIT_EXCEEDED` | 0 / absent (15:47Z) | 0 / absent (16:20Z) |
| `docker_data.vhdx` | 49.92 GB (post-compact) | 51.11 GB (+0.2 GB over the last four ticks) |
| Collector version, daily host | "0.159.0" (quarterly table) | **0.158.0** (pin 0.159.0) |
| Recurring writers against the tree | 0 (Phase 0 exit) | **1 spawner live**, loop dies on cwd |
| B1 lint findings (canonical) | 3,992 | **1,511** |
| Stale worktrees | — | 10 of 12 |
| Remote branches (merged-detectable) | — | 174 (76) |
| Docs-gate reds merged over, today | — | 2 |
| ECRR reports (top-level) | 410+ | 425 (426 with this) |

**Open watch items, unchanged by this audit:** watchdog `vhdx_gb` flat-for-24 h read due
**2026-09-04T15:34Z**; clean-host freshness first amber **2026-09-28** (VM must be started first);
`EVIDENCE_REPO_TOKEN` amber **2026-10-12**; evidence prune next scheduled **2026-10-01**.

**Dispositions proposed, in order:** P1-1 host MSI to 0.159.0 → P1-2 unregister the logon task →
P2-3 move `.env*` out, delete leftovers → P2-2 branch/worktree prune → P3 one-liners; P2-1 is a
rule to keep, not a change. All but the P3 text are operator-keyboard or repo-settings actions; this
seat drafts the P3 lines and the `boot-health-check.ps1` code-lane PR on "go".

## 4. Role

Claude (chat/review) as OEM auditor: read-only against host, containers, GitHub, and tree; one
process it started, it stopped; proposes, does not decide. Machine operator `@fubumaki` owns every
disposition above that touches a service, a task, a repo setting, or a credential file.
