# SigNoz Log Parser Error Resolution — Definition of Done

## ✅ Acceptance Criteria
- Parser builds cleanly; unit tests pass
- Golden sample set (≥ 20 events) parses with **0 schema mismatches**
- Label cardinality guard: < 200 values per key across a 24h replay window
- Ingest latency within budget — `p50 < 5s`, `p99 < 60s` from source → SigNoz query
- Documented one-click rollback plan
- Dashboard panel **Parser Health** shows all thresholds green

## 🔍 Verification Steps
1. **Static checks** — run `make test` (or repo-native equivalent) and capture success output
2. **Replay harness** — push golden samples through staging; inspect parsed fields for drift
3. **Latency check** — measure ingest latency via SigNoz or telemetry query; confirm targets
4. **SigNoz UI** — open _Dashboards → Parser Health_ and screenshot green indicators
5. **Artifact** — export 24h health report and attach to OPS-001 ledger entry

## 🧯 Rollback Readiness
- Identify rollback script / command in `scripts/` and verify dry-run
- Ensure previous working parser version tagged and retrievable

## 📎 References
- KPI targets mirrored in [TASKS.md](../TASKS.md)
- Daily/weekly checklists in [`operational-checklists.md`](operational-checklists.md)
