# ECRR Task Generation Framework — Definition of Done

## ✅ Acceptance Criteria
- Canonical ID format finalized (e.g. `TASK-YYYYMMDD-HHMMSS-###`) and documented
- Writers for ledger, index, and alignment outputs emit identical schema
- Framework execution is idempotent — reruns do **not** duplicate tasks
- Automated “audit lane” verifies assignee, labels, and priority mapping

## 🔍 Verification Steps
1. **Sandbox dry-run** — run generation against staging ledger/index stores
2. **Idempotency check** — execute twice; `diff` between runs must be empty
3. **Alignment audit** — produce alignment report; confirm zero orphaned tasks
4. **Schema validation** — validate outputs against JSON schema and archive proof

## 🔗 Downstream Integrations
- Feeds OPS-005 (Ledger automation) and OPS-007 (Index rotation)
- Provides metadata for OPS-006 alignment analysis

## 📎 References
- Operational cadence → [`operational-checklists.md`](operational-checklists.md)
- Backlog + dependencies → [TASKS.md](../TASKS.md)
