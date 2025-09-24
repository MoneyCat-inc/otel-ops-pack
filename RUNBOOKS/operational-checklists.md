# Operational Checklists

## 🗓️ Daily (5–7 minutes)
- [ ] Parser `p95` ingest latency within threshold
- [ ] Error budget remaining > 99%
- [ ] No unapproved schema keys added by parser (or explicitly noted)
- [ ] Health dashboard shows no canary alert

## 📆 Weekly
- [ ] Archive closed tasks in ledger
- [ ] Rotate on-call (`observability-duty`)
- [ ] Review label cardinality growth

## 📅 Monthly
- [ ] Re-baseline thresholds using last 30 days of data
- [ ] Run DR drill (simulate parser failure + rollback)
- [ ] Close or re-triage stale items (>30 days without movement)

## 📈 KPI Quick Reference
See [TASKS.md](../TASKS.md#-kpi-snapshot-targets) for metric definitions and targets.
