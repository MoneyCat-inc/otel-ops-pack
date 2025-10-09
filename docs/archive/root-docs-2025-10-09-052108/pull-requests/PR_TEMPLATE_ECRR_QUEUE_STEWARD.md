# 📊 ECRR Queue Steward Quality Dashboard Integration

## 🎯 Purpose

This PR integrates the **ECRR Queue Steward Quality Dashboard** into the documentation.
It provides a **single source of truth** for pipeline health verification and audit compliance.

---

## ✅ What's Included

### 📚 Documentation
- [x] New section in `docs/ECRR_QUALITY_DASHBOARD.md` for Queue Steward
- [x] Structured status block (pipeline health, last verified, schema mode)
- [x] Explicit role ownership (`Cursor Agent — Observability Copilot`)

### 🔍 Queries
- [x] 30-minute ingestion count query (ClickHouse)
- [x] Latest row query with attributes (`service.name`, `log.source`)

### 📷 Evidence
- [x] Checklist for SigNoz Logs UI and Queue Steward screenshots

### 🔄 Migration
- [x] Step-by-step process for flipping `use_new_schema: true` once migrator has run

### 🪶 ECRR
- [x] Explicit Examine → Clean → Report → Role mapping

---

## 🔎 Verification

- [x] Restarted Windows otelcol-contrib with new config
- [x] Canary emission confirmed ingestion into `signoz_logs.logs_v2`
- [x] SigNoz Logs UI filter (`dataset=agent_queue`, `log.source=win-filelog`, `service.name=queue-steward`) shows fresh entries
- [x] ClickHouse queries return >0 rows in last 30 minutes

---

## 📊 Evidence

- [ ] Screenshot: SigNoz Logs view (Last 1h, three filters applied)
- [ ] Screenshot: Queue Steward dashboard panel
- [ ] Query output: count + latest row (ClickHouse)

---

## 🚀 Next Steps

- [ ] Collect screenshots and commit them under `docs/ecrr/screens/`
- [ ] When ready, run `signoz-schema-migrator-sync` and flip schema mode back to `use_new_schema: true`
- [ ] Re-validate using `signoz_logs.distributed_logs_v2`

---

## ✅ ECRR Compliance

- **Examine**: Collector + SigNoz pipeline state captured
- **Clean**: Config reviewed, schema mode pinned to legacy
- **Report**: Queries + evidence checklists added
- **Role**: Cursor Agent — Observability Copilot declared

---

## 📝 Commit Message

```
docs(ecrr): add Queue Steward Quality Dashboard section

- Added `docs/ECRR_QUALITY_DASHBOARD.md` section:
  - Subsystem: Windows → OTLP HTTP → SigNoz → ClickHouse
  - Role owner: Cursor Agent — Observability Copilot
  - Dataset: `agent_queue`
- Embedded audit-grade verification queries:
  - 30-minute ingestion count
  - Latest row (service.name + log.source)
- Checklist for evidence screenshots (SigNoz Logs UI + Queue Steward panel)
- Explicit migration path for schema toggle (`use_new_schema: true`)
- Full ECRR alignment (Examine → Clean → Report → Role)
```

---

## 🔗 Related

- **Evidence Report**: `docs/ECRR_REPORTS/2025-09-29-queue-steward-verification.md`
- **Automation Scripts**: `scripts/queue-steward-canary-automation.ps1`, `scripts/setup-queue-steward-scheduled-task.ps1`
- **Config**: `config.yaml` with transform processor for queue attributes
