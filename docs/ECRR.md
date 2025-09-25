# ECRR - Resonai Project Mantra

**Examine -> Clean -> Report -> Role**
Every task, fix, or feature in Resonai follows this cycle. It keeps the system transparent, safe, and continuously improving.

---

## **1. Examine Your Environment**

Before starting work, take a snapshot of the system:

* **Runtime checks**: confirm `crossOriginIsolated === true`, mic constraints applied, IndexedDB present, flows load.
* **Local state**: ensure `.agent/` files exist, no `.agent/LOCK`, ports free.
* **CI/SSOT**: verify last run was green (`RUN_AND_VERIFY.md`, `.artifacts/SSOT.md`).
* **Deployment**: check the live site for regressions.

> Evidence belongs in your **ECRR report**.

---

## **2. Clean Up the Environment**

Resolve drift before building:

* Remove stale service workers, caches, IndexedDB data.
* Kill orphaned ports (`scripts/kill-port.ps1`).
* Regenerate missing SSOT artifacts.
* Quarantine flaky tests or update selectors.
* Reset env parity (pnpm scripts, devcontainer, node versions).

> Small safe cleanups may be automated by **codex-local** or **BossCat** agents.

---

## **3. Write a Report**

Every change must leave an artifact:

* Use the **ECRR report template** (`docs/ECRR_REPORT_TEMPLATE.md`).
* Include **Examine**, **Clean**, **Results**, and **Role** sections.
* Save under `docs/ECRR_REPORTS/<date>-<slug>.md`.
* Paste the summary into your PR body.

> If it isn't written down, it didn't happen.

---

## **4. Your Role**

Declare your role in the process:

* **ChatGPT Agent** — Research, specs, orchestration, documentation.
* **Cursor Agent** — Implements scoped UI/code tasks in Cursor IDE.
* **Codex Agent** — CI/CD, CSP/security guardrails, merges.
* **codex-local** — Keeps local workflows (pnpm/devcontainers/env) healthy.
* **BossCat** — Automates background maintenance (SSOT refresh, flake quarantine).
* **You (the human)** — Project lead, vision, scope approval, external auth.

> Role declarations keep accountability clear and prevent overlap.

---

## ECRR Gate (PR Checklist)

* [ ] **Examine**: Facts captured (isolation, mic, flow, SSOT, env state).
* [ ] **Clean**: Drift removed (SW/cache reset, ports cleared, flaky quarantined).
* [ ] **Report**: ECRR report attached (PR body or `docs/ECRR_REPORTS/`).
* [ ] **Role**: Declared (ChatGPT / Cursor / Codex / codex-local / BossCat / Human).

Only merge when all boxes are ticked.

---

## Rallying Cry

> **ECRR or it didn't happen.**
> Examine -> Clean -> Report -> Role, on every PR, every time.
