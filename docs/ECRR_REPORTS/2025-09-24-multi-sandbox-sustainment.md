# ECRR Report - Multi-sandbox canary sustainment

- date: 2025-09-24
- actor: Cursor Agent
- severity: info
- scope: projects/myproj2, projects/payments-qa, projects/payments-dev, scripts/init-project-env.ps1, docs/PROJECT_ENV_SEPARATION.md
- related: []
- time_spent: ~30m
- outcome: resolved

---

## Examine (facts)
- build/sha: ac53cf63451d5388bd8a8cc1ce922406ececea63
- urls: http://localhost:8080 (SigNoz), OTLP http://localhost:5318/v1/logs
- crossOriginIsolated: not evaluated (headless session)
- mic settings: N/A (no browser session)
- flow integrity: warm-up ? glide ? phrase ? reflection = not exercised (no client run)
- local footprint: active sandboxes = myproj2, payments-dev, payments-qa, "payments qa"; C:/logs/projects/<name> holds per-project logs only

---

## Clean (actions)
- SW/caches cleared: not applicable
- IndexedDB/localStorage reset: not applicable
- services/ports restarted: none; SigNoz containers kept running
- agent state: running; LOCK absent
- guardrails enforced: local-first routing, privacy-safe attributes, idempotent scaffolds confirmed

---

## Verify (proof)
- SigNoz UI:
  - Logs ? filter service.name = payments-dev
  - Optional secondary filter log.file.path contains "/projects/payments-dev/logs"
- Commands:
  - Get-ChildItem projects | Select-Object Name,LastWriteTime
  - docker exec signoz-clickhouse clickhouse-client --query 'SELECT JSON_VALUE(CAST(resource AS String), ''$.service.name'') AS service_name, body, fromUnixTimestamp64Nano(timestamp) AS ts FROM signoz_logs.distributed_logs_v2 WHERE body LIKE ''%payments-dev%'' ORDER BY timestamp DESC LIMIT 1'
  - pwsh -File "projects/payments qa/scripts/enter.ps1" -EmitCanary (emits scoped log to shared collector)
- Artifacts:
  - Updated per-project OTEL env vars (projects/*/scripts/enter.ps1)
  - Log entries under C:/logs/projects/<name>/

---

## Results
- before ? after: single sandbox focus ? three sandboxes (myproj2, payments qa, payments-qa, payments-dev) maintained with verified canary pipeline
- before ? after: manual scope switching ? scripted nter.ps1 shells with team tags ready for customization
- before ? after: ad-hoc verification ? documented SigNoz UI + ClickHouse queries for each sandbox
- regressions: none observed
- follow-ups: align duplicate "payments qa" vs "payments-qa" namespaces; ensure each project adds 	eam= attribute in OTEL_RESOURCE_ATTRIBUTES

---

## Root cause and prevention
- cause: Need ongoing proof that multiple sandboxes stay isolated while sharing the collector
- contributing: rapid addition of project shells without consolidated status reporting
- prevention: Run scoped canary script after each scaffold; keep PROJECT_ENV_SEPARATION guide authoritative

---

## Role
- who: Cursor Agent ? Observability Copilot
- responsibilities: maintain OTEL wiring, document isolation strategy, verify collector health
- artifacts produced: docs/PROJECT_ENV_SEPARATION.md (prior), updated sandbox scripts, this ECRR report
- handoff notes: Human lead to standardize project naming and finalize team tag attributes per sandbox

---

## ? ECRR Gate (required)
- Examine: [x] facts captured; [x] env documented; [x] evidence listed
- Clean: [x] guardrails enforced; [x] actions recorded
- Report: [x] results; [x] regressions; [x] follow-ups
- Role: [x] actor declared; [x] responsibilities; [x] handoff
