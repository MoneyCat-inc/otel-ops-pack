# Codex Cloud Reviewer B Integration

## Overview

This playbook describes how to operate codex-cloud as the read-only **Reviewer B** inside the BossCat dual-agent, ECRR-gated workflow. The goal is to turn codex-cloud into a fast, auditable reviewer that enforces safety rails without modifying the repository.

> **B Doctrine Reminder**
> *Reviewer B never writes, commits, rebases, force pushes, or merges. Any write attempt is a policy breach and triggers ECRR.*

---

## 1. Operate Within BossCat Safety Rails

* **Role:** codex-cloud always runs as the monitoring agent (**B** role). It remains read-only at all times: no local commits, no rebases, no merges, no lock manipulation.
* **Dual-agent discipline:** Agent A acquires the mutex lock, edits only within an authorized lane, and respects hard budgets (≤ 2 jobs, ≤ 10 files, ≤ 200 LOC). Reviewer B confirms the budget snapshot (`files_changed`, `loc_delta`, `jobs_used`) before rendering a verdict.
* **Kill-switch:** codex-cloud halts review and reports immediately if `.agent/LOCK` exists.
* **Heartbeat:** Confirm `.agent/JOB.lock` shows an unbroken lock lifecycle for the active job; missing beats are an ECRR escalation.
* **Trigger:** Reviewer B commands **ECRR** (Evidence → Contain → Rollback → Report) whenever a breach is detected, aligning with Rule #1 “Two make the strike” and Rule #8 “Review without writing.”

---

## 2. Supply Evidence Bundles

Agent A publishes a compact, machine-readable evidence bundle alongside each PR. Reviewer B refuses to proceed (ECRR → **RED**) if any required artifact is missing.

* **Static context:**
  * Lane scope (SSOT / DOCS / COMP / FLAK / SELE) and `.agent/PLAN.md` (≤ 150 words covering intent, scope, tests).
  * `git diff`, files changed, LOC counts, and Stability Pack budget snapshot (≤ 10 files, ≤ 200 LOC, ≤ 2 jobs).
  * `.agent/JOB.lock` heartbeat log for the active job.
* **Quality signals:**
  * Changed-path tests and short smoke runs only. For DOCS lane this means Markdown lint plus link/anchor validation at a minimum.
  * Performance-gate results (e.g., k6 thresholds for p95 latency, error rate).
  * One synthetic OpenTelemetry trace sent before the main load test; failure to capture marks the review **RED**.
* **Telemetry proof:**
  * Representative trace/metrics sample showing inbound server spans, outbound client spans, database spans (if any), and correlated logs.
* **Optional chaos drill:**
  * Data Room scenario (Laminar → Chaotic → Stop) with recovery metrics.
* **Audit trail:**
  * `.agent/EVIDENCE.log` (JSONL) covering `preflight → lock → edit → test → exit`, the ECRR report JSON, BOSSCAT_LOG one-liner, and any exit code emitted (see BossCat exit code table).

---

## 3. Emit a Single Gate Verdict

codex-cloud produces one structured comment per PR using BossCat’s NATO-color signals and gate command, for example:

```text
IONA/BALANCER STATUS — Reviewer B (codex-cloud)
Lane: DOCS  TTL: n/a  Budget: 4 files / 122 LOC  Jobs: 1/2
State: GREEN
Last event: 2025-10-09T10:22Z report "docs checks passed; evidence complete"
Action: continue → `@cat ready-for-gate`

Static: ✅ scope & budgets | ✅ diff matches lane
Tests: ✅ changed-paths (lint+links) | ✅ perf thresholds met
Telemetry: ✅ spans present | ✅ synthetic trace captured
Chaos drill (optional): ⚠️ mild error spike (3.8%) recovered in 12s
Evidence: ECRR#2025-10-09-1022
```

* Reviewer B never merges or writes to the repo; the external BossCat gate issues the final decision.
* Background agents archive verdicts, raise alerts, and update dashboards automatically.

---

## 4. Checklist for Reviewer B

1. **Scope & Budgets** – Confirm lane rules, file count ≤ 10, LOC ≤ 200, jobs ≤ 2 using the Stability Pack snapshot or CI budgets report.
2. **Plan & Tests** – `.agent/PLAN.md` present, `.agent/JOB.lock` heartbeat valid, changed-path tests executed (DOCS: lint + link/anchor). Reject long suites.
3. **Performance Gates** – Thresholds defined; job fails on breach (non-zero exit). Capture the k6/Perf gate JSON.
4. **Telemetry Completeness** – Server + client + DB spans, core metrics, log correlation, synthetic trace captured.
5. **ECRR Trail** – `.agent/EVIDENCE.log`, ECRR report JSON, BOSSCAT_LOG, exit color (GREEN/AMBER/RED/BLACK) and exit code recorded.
6. **Gate Signal Discipline** – Only post `@cat ready-for-gate` when the state is **GREEN**; otherwise document required actions (HOLD, ECRR).

---

## 5. Continuous Improvement via ICF

Adopt the **Iterative Convergence Framework (ICF)** once the loop is stable:

* Treat each audit cycle as Examine → Clean → Implement → Report for the review system itself.
* Use a dedicated ICF lane for meta-config updates under the same budgets and approvals.
* Track recurring failures to guide Agent A toward preemptive fixes without relaxing guardrails.

---

## 6. Integration Flow

1. **Preflight:** Agent A acquires lock, validates clean git state, records plan.
2. **Implementation:** Make scoped edits and run changed-path smoke tests (docs lane: lint + link/anchor job).
3. **Evidence Gathering:** Execute performance gates, capture synthetic trace, collect telemetry proof, export budgets snapshot.
4. **Reporting:** Publish ECRR JSON, BOSSCAT_LOG line, `.agent/EVIDENCE.log`, `.agent/JOB.lock`, and evidence bundle artifact.
5. **Review:** codex-cloud ingests bundle, confirms kill-switch absence, runs checklist, and posts gate verdict with NATO color + `@cat ready-for-gate` when GREEN.
6. **Archival:** Background automation stores verdicts, updates dashboards, and alerts on exceptions.

---

## 7. READY-FOR-GATE Definition

* Lane, scope, and budgets satisfied.
* Plan documented; changed-path tests pass (docs: lint + link/anchor checks).
* Performance thresholds all green.
* Telemetry spans/metrics/logs present; synthetic trace captured.
* ECRR + BOSSCAT_LOG evidence available; exit status GREEN.
* (If chaos drill executed) Error spike < target and recovery time within SLA.

---

## 8. Docs-Lane Gate Workflow (Implemented)

The repository now ships with `.github/workflows/docs-lane-checks.yml`, a focused workflow that enforces BossCat’s DOCS-lane doctrine and emits auditable guard telemetry.

* **Trigger & scope:** Runs on `pull_request` events that touch `docs/**` or `README.md`, matching the lane definition while ignoring other paths.
* **Immediate wins baked in:** Declares the ALFA concurrency group, honours the 15-minute TTL via `timeout-minutes: 15`, uploads artifacts with the BRAV 14-day retention window, and appends the CHAR job summary so reviewers see the guard result without log diving.
* **Lane guard + budgets:** Computes the diff against the PR base, captures `changed_files.txt` plus any out-of-lane paths, and flags NATO **RED/20** when the ≤ 10 files / ≤ 200 LOC / ≤ 2 jobs budgets or lane rules are breached.
* **Changed-path tests only:** Pins Node.js 20.11.1, `markdownlint-cli2@0.14.0`, and `lychee v0.20.1`, executing each tool strictly over the changed docs list. If no docs change, both checks short-circuit while still recording guard telemetry.
* **Guard telemetry:** Every run writes `guard.json` (schema `bosscat.docs-lane.guard/1.0`) with the GR code, numeric guard status (`GR-xx`), reason, budgets, tool pins, and workflow metadata alongside the lint/link logs. The guard code and reason also populate `guard.json`, the dedicated guard comment, and the job summary so Reviewer B can cite the failure cause without opening logs.
* **GREEN-only signal:** The workflow posts two comments: a guard telemetry summary on every run and the canonical `@cat ready-for-gate` signal only when `GR-00` (GREEN) is emitted. Reviewer B’s public signal therefore mirrors the evidence artifact while still surfacing the guard tuple on suppressed runs.

### Guard reason codes (docs lane)

| Code | When emitted | NATO impact |
| --- | --- | --- |
| `GR-00` | Docs-lane budgets passed; lint + link checks succeeded | GREEN (0) |
| `GR-01` | Kill switch `.agent/LOCK` present | BLACK (30) |
| `GR-02` | Budget exceeded or out-of-lane change detected | RED (20) |
| `GR-03` | Markdownlint failure | AMBER (10) |
| `GR-04` | Link/anchor check failure | AMBER (10) |

Each guard code is exported through `GUARD_CODE`, `GUARD_REASON`, `GUARD_STATE`, `GUARD_STATUS`, `GUARD_FILES`, and `GUARD_LOC` environment variables so the workflow can render deterministic evidence bundles (`guard.json`, `budget.json`) and telemetry comments for Reviewer B.

Every run persists `guard.json` in `artifacts/docs-lane/` and mirrors the guard code/ reason in the job summary so Reviewer B can explain any suppressed signal without inspecting console logs.

Excerpt (abridged):

```yaml
jobs:
  docs_gate:
    timeout-minutes: 15
    env:
      LANE: docs
      GUARD_SCHEMA: bosscat.docs-lane.guard/1.0
    steps:
      - name: Compute changed docs scope
        run: |
          git diff --name-only "$MERGE_BASE" "$HEAD_SHA" > all_changed.txt || true
          grep -E '^(docs/|README\.md$)' all_changed.txt > changed_docs.txt || true
          grep -Ev '^(docs/|README\.md$)' all_changed.txt > out_of_lane.txt || true
      - name: Enforce docs lane budgets
        run: |
          if [ "${OUT_OF_LANE_COUNT:-0}" != "0" ]; then
            echo "GUARD_CODE=GR-02" >> "$GITHUB_ENV"
            echo "GUARD_REASON=docs lane scope violation" >> "$GITHUB_ENV"
            echo "PIPELINE_SHOULD_FAIL=1" >> "$GITHUB_ENV"
          fi
```

## 9. Strategic Benefits

* Keeps action and inspection separated for provable safety.
* Maximizes codex-cloud strengths in rapid diff analysis and anomaly spotting.
* Builds repeatable, auditable evidence for every gate decision.
* Enables gradual self-improvement of the audit loop without relaxing guardrails.

---

**Status:** Draft adoption guide · **Owner:** BossCat OEM · **Last updated:** 2025-10-16T12:10:00Z
