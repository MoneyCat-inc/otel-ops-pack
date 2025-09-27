# ECRR Report - Project OTEL sandbox scaffolding

- date: 2025-09-24
- actor: Cursor Agent
- severity: info
- scope: scripts/init-project-env.ps1, docs/PROJECT_ENV_SEPARATION.md, projects/sample
- related: []
- time_spent: ~45m
- outcome: resolved

---

## Examine (facts)
- build/sha: ac53cf63451d5388bd8a8cc1ce922406ececea63
- urls: http://localhost:8080 (SigNoz), OTLP http://localhost:5318/v1/logs
- crossOriginIsolated: not evaluated (headless CLI session)
- mic settings: unavailable (CLI-only; no media context)
- flow integrity: warm-up ? glide ? phrase ? reflection = not exercised (no UI session)
- local footprint: new C:/otel/projects/sample scaffold (artifacts|config|docs|logs|scripts)

---

## Clean (actions)
- SW/caches cleared: no (not applicable in CLI workflow)
- IndexedDB/localStorage reset: not applicable
- services/ports restarted: none required; SigNoz left running in WSL
- agent state: assumed running; LOCK=absent (confirmed)
- guardrails enforced: local-first, privacy, idempotence respected throughout

---

## Verify (proof)
- How to verify in SigNoz (UI):
  - UI ? Logs ? filter service.name = sample after emitting a log under projects/sample/logs
- Commands:
  - pwsh -File scripts/init-project-env.ps1 -Name sample -Force
  - Get-ChildItem projects/sample -Recurse
  - Get-Content projects/sample/scripts/enter.ps1
- Artifacts:
  - projects/sample scaffold (canary workspace)
  - docs/PROJECT_ENV_SEPARATION.md guidance

---

## Results
- before ? after: no repeatable scaffolding ? reusable init script for project sandboxes
- before ? after: missing operator guide ? documented PROJECT_ENV_SEPARATION checklist
- before ? after: single shared workspace ? isolated projects/sample proving segregation
- regressions: none observed
- follow-ups: run a SigNoz canary from a project shell; prune projects/sample when a real project replaces it

---

## Root cause and prevention
- cause: No documented process existed to keep third-party project environments isolated while reusing the OTEL stack
- contributing: fragmented docs, ad-hoc log routing
- prevention: standard scaffold script for every project; central guide kept current

---

## Role
- who: Cursor Agent ? Observability Copilot
- responsibilities: enforce OTEL guardrails, document telemetry workflows
- artifacts produced: scripts/init-project-env.ps1, docs/PROJECT_ENV_SEPARATION.md, projects/sample scaffold
- handoff notes: Human lead to onboard first external project via scaffold and confirm SigNoz canary ingestion

---

## ? ECRR Gate (required)
- Examine: [x] facts captured; [x] env documented; [x] evidence listed
- Clean: [x] guardrails enforced; [x] actions recorded
- Report: [x] results; [x] regressions; [x] follow-ups
- Role: [x] actor declared; [x] responsibilities; [x] handoff
