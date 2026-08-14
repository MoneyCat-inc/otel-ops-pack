# BossCat Charter (Canonical)

Canonical charter for **MoneyCat Inc · Resonai [OTel] · otel-ops-pack**.
Index: `AGENTS.md` (repo root). Roadmap of record: `docs/BossCat/ROADMAP_2026H2.md`.

**Rewritten 2026-08-13** (Roadmap 2026 H2, Phase 2 — truth in steering documents). The previous
version described an agent hierarchy that no longer exists and cited files and ports that no longer
match the repo. See "What changed and why" at the end.

---

## Purpose

Deploy, maintain, and audit the Resonai [OTel] observability stack, with every change carrying
evidence a stranger could check.

Work follows the **ECRR** shape — **Examine, Clean, Report, Role** — written as a lean report per
change: quantified before and after, an honest verdict, no checkbox apparatus.

---

## The four seats

There are four seats. Only one has hands on the machine.

### 1. BossCat OEM — authority

Not a person or a tool: the oversight function. Sets milestones, approves gates, and holds veto over
production changes. In practice this authority is exercised by the machine operator.

### 2. Machine operator — `@fubumaki`

**The only seat with hands.** Everything requiring elevation, physical access, or a credential is
theirs and cannot be delegated:

- elevated PowerShell — service changes, scheduled-task registration and removal, MSI installs
- Hyper-V and the clean-host E2E gate clock
- secret minting and rotation; no other seat mints, pastes, or reads a credential
- merging pull requests

### 3. Cursor{Implementer} — permanent

Repository implementation seat. Writes code and docs, opens PRs, files ECRRs. Operates under lane
discipline and never merges its own work.

### 4. Kiro{Implementer} — permanent

Second implementation seat, a peer of Cursor{Implementer} rather than nested under it. Same rules:
lane discipline, `Actor: Kiro{Implementer}` logged per commit, scoped credentials only, and it never
merges its own work.

Converted from provisional on **2026-08-14** after the pilot passed all three criteria frozen before
its report was read — `docs/BossCat/KIRO_VERDICT_CRITERIA_20260813.md`, scored in
`CHAR/ECRR/ECRR_REPORTS/ECRR_KIRO_PILOT_20260814.md`.

### Chat/review seat

A reviewing and drafting seat — currently Claude. Drafts decision memos, audits, and analysis;
proposes, never decides. It has no keyboard: it cannot elevate, mint, or merge.

> **Retired roles.** IONA, QA Scribe, Investigator, Gap-Closer, and Codex Cloud/Local are gone. They
> described a 2025 multi-agent arrangement that no longer runs. Historical reports referencing them
> remain accurate for their own dates and are not edited.

---

## Lane discipline

Every change belongs to exactly one lane, and lanes are never mixed in one pull request:

| Lane | Contains | Gate |
|---|---|---|
| docs | `docs/**`, `README.md` | `docs_gate` — budgets 10 files / 200 LOC, markdownlint, lychee |
| code | source, scripts, config | PSScriptAnalyzer, CodeQL, gitleaks |
| CI/ops | `.github/workflows/**` | registry-guard |
| evidence | `CHAR/ECRR/**`, `artifacts/**` | no docs gate — it does not trigger outside `docs/` |

The docs gate admits only `^docs/` and `README.md`. A pull request touching `docs/` **and** anything
else fails **GR-02** on scope. This is the most common cause of a red gate; split by lane first.

Commit messages are conventional: `feat fix docs test chore refactor perf ci build revert`. Anything
else fails the governance check.

---

## Operating principles

- **Proof to disk.** Every action leaves an artifact a reader can open.
- **One deliberate change at a time.** Operator-gated milestones, not batched sweeps.
- **No recurring writer** against the working tree without an owner, a review date, and a kill switch.
- **A gate must be able to both pass and fail.** Phase 0–2 retired a compliance gate that could never
  fail, a drift guard that could never pass, a permanently red CI check, and an unsatisfiable exit
  criterion. Any check that cannot do both is broken, however green it looks.
- **Do not edit the record to fix a blemish.** Historical evidence stays as filed; corrections are
  addenda, not rewrites.

---

## Where things are

| What | Where |
|---|---|
| Live log, one line per change | `docs/BossCat/BOSSCAT_LOG.md` |
| Per-change evidence | `CHAR/ECRR/ECRR_REPORTS/` |
| Roadmap of record | `docs/BossCat/ROADMAP_2026H2.md` |
| Raw evidence archive | `MoneyCat-inc/otel-ops-evidence` |
| Windows collector runbook | `docs/runbooks/windows-collector.md` |

**Stack facts** (verified 2026-08-13): Windows collector `otelcol-contrib` **v0.158.0**, carrying
**logs only** — Windows Event Log, filelog, and local OTLP on **`127.0.0.1:5320`** (gRPC) and
**`5321`** (HTTP). SigNoz UI on `http://localhost:8080`. There is no `hostmetrics` receiver.

---

## Cadence

- **Per change:** lean ECRR.
- **Monthly:** evidence rollup to `otel-ops-evidence`.
- **Quarterly:** evidence prune; dependency and stack upgrade check.

---

## Provenance

The previous charter was accurate for late 2025 and had drifted: it described retired agent roles,
cited OTLP ports the config no longer uses, and referenced two files that no longer exist. The
itemised corrections are in the commit that replaced it.

The ECRR *practice* is unchanged. Only the machinery that scored it is gone.
