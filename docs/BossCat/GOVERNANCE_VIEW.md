# BossCat Governance View (Tetragram + Gates)

**Tetragram ID (canonical):** `BOSS-CATX-GOVN-VIEW`

Register: Neutral Instructor (calm, documentary cadence)

---

## 0. Purpose

This document is the human-readable explainer for the governance JSON and reference map. It defines:
- Naming: the 4‑4‑4‑4 Tetragram scheme, NATO call‑outs, and compat paths.
- Budgets and gates: WARN vs STRICT, sticky thresholds, runtime lane budgets.
- Evidence loop: ECRR (Evidence → Contain → Rollback → Report).
- Performance and observability checks required to promote.
- Agent roles, lanes, and responsibilities.

---

## 1. Naming — Tetragram (4‑4‑4‑4) + NATO

Form: `AAAA-BBBB-CCCC-DDDD` (A–Z only; pad with X; reversible).
Semantics: Program → Domain → View → Artifact.

Examples:

| Human label | Tetragram |
|---|---|
| BossCat System Architecture View | `BOSS-CATX-RESE-SYAR` |
| Governance View (this doc) | `BOSS-CATX-GOVN-VIEW` |

All files keep human-readable titles; the path and 4‑4‑4‑4 prefix anchor determinism.

---

## 2. Budgets and Gates

### 2.1 Governance budgets (PR / Release)
- jobs_max: 10
- files_max: 10
- loc_max: 2,000 (governance LOC)
- sticky_threshold: 1,600 (80%)

Sticky WARN engages at ≥80% and remains until the next passing window; STRICT blocks prod promote when required checks fail.

### 2.2 Runtime lane budgets (Auto‑Bots)
- Max 10 files and 200 LOC per bot run to keep changes surgical and auditable. The lane runtime budgets are independent of the PR governance budget. (Bots never merge to trunk.)

Approved lanes: SSOT, FLAK, SELE, COMP, DOCS. Each lane has allow‑patterns and produces ECRR evidence plus a one‑line BossCat log entry.

### 2.3 Gate modes
- ci/local = WARN: Non‑blocking; sticky WARN posted at ≥80%.
- prod = STRICT: Blocking; all required checks must be green.

---

## 3. Evidence loop — ECRR

ECRR = Evidence → Contain → Rollback → Report.

Prime rules include: paired agents (A writes, B verifies), single‑writer lock, bounded retry with exponential backoff, changed‑paths smoke, kill‑switch `.agent/LOCK`, and no merges by bots.

Roles aligned to ECRR:
- SCOUT — Examine (risk/diff synthesis); emits ecrr.examine
- WARDEN — Contain/Rollback (budgets, tests, canary); emits ecrr.contain, ecrr.rollback
- SCRIBE — Report (status snippet, approvals, audit links); emits ecrr.report

Artifacts: `artifacts/ecrr/<lane>/<timestamp>.json|.md` + `docs/BossCat/BOSSCAT_LOG.md`.

---

## 4. Performance & Observability Gates

### 4.1 Threshold‑gated load tests
- Use k6/Locust/JMeter as appropriate.
- CI must fail if thresholds breach (e.g., p(95) < 500ms, error_rate < 1%).
- Quick baseline on every PR; heavier runs pre‑release.
- Archive test JSON/HTML and attach to ECRR evidence.

### 4.2 Synthetic tracing & telemetry smoke
- Emit a synthetic OTLP trace after deploy‑to‑stage and verify it is ingested.
- Auto‑instrument .NET services via OpenTelemetry zero‑code agent when applicable to ensure traces/metrics/logs correlate.

### 4.3 Supply‑chain evidence
- Generate Syft SBOM and signature registry on prod gate.
- Upload artifacts with ≥90‑day retention and surface “SBOM (latest)” on the status page.

---

## 5. Checks (by mode)

ci/local (WARN)
- ICF_COMPLIANCE — ICF doctrine visible; RSI indicators present
- SITE_HTML_CSP — CSP & WCAG AA where applicable
- SITE_REFMAP_PREVIEW — Reference map renders
- PERF_SMOKE — Baseline thresholds (short)
- PERF_SUMMARY — Attach metrics summary
- Sticky warning at ≥80% of LOC/file/job budget

prod (STRICT)
- All WARN checks, plus:
- ATTEST_VERIFIED — Attestation matches build
- SBOM_SIGNED — SBOM present and signed
- Canary steady, rollback plan linked; override requires explicit evidence set

---

## 6. Agents, lanes, and evidence

- Agent A (Writer): acquires `.agent/JOB.lock`, edits within lane budgets, generates ECRR.
- Agent B (Monitor): never writes; verifies evidence, diffs, heartbeats; triggers ECRR on anomaly.
- IONA Controller: orchestrates paired operation and kill‑switch.

Outputs:
- `artifacts/ecrr/<lane>/<timestamp>.json`
- `docs/BossCat/BOSSCAT_LOG.md` (one‑line lesson)
- Gate signal in PR: `@cat ready-for-gate`

---

## 7. Governance flow (Mermaid)

```mermaid
flowchart TD
  subgraph PLAN[Plan & Prepare]
    TETR[Tetragram map]
    BUDG[Budgets set]
    GATE[Gate modes]
  end
  subgraph BUILD[Build & Verify]
    PERF[Perf tests (threshold-gated)]
    TRACE[Synthetic trace check]
    SBOM[SBOM + signatures]
  end
  subgraph DECIDE[Decide & Promote]
    WARN[WARN lane (ci/local)]
    STRICT[STRICT lane (prod)]
    CANA[Canary steady]
    ROLL[Rollback ready]
  end
  TETR-->BUDG-->GATE-->PERF-->TRACE-->SBOM-->WARN-->STRICT-->CANA-->ROLL
```

---

## 8. Status page snippet (audit hooks)

Expose attestation, SBOM link, canary state, and next audit window in a CSP‑safe block. Keep copy neutral and documentary.

---

## 9. Canonical references

- ECRR rules, paired‑agent doctrine, budgets & kill‑switch
- Auto‑Bots lanes, lane budgets, artifacts & BOSSCAT_LOG
- Data Room harness for drills and canary exercises
- Status page hooks and docs hub integration
- ICF/RSI doctrine (dual‑agent improvement), safety guardrails
- Threshold‑gated perf in CI; synthetic telemetry via OpenTelemetry
