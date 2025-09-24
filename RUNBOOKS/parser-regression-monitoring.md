# Parser Regression Monitoring — Definition of Done

## ✅ Acceptance Criteria
- Canary alert triggers when `parse_error_rate > 0.5%` for a 5 minute window
- Burn panel shows events/sec (dropped vs ingested) with clear thresholds
- Schema drift detector compares latest release vs HEAD (top 10 field deltas)
- Primary alert links directly to the parser runbook section covering first-hour actions

## 🧪 Verification Steps
1. **Synthetic fault injection** — introduce controlled parse errors; confirm a single alert fires
2. **Silence control** — apply 30m silence and confirm suppression of duplicate alerts
3. **Runbook link check** — open alert in SigNoz UI and verify runbook anchor resolves
4. **Drift report** — execute schema comparison job; archive diff in `artifacts/`

## 🔁 Dependencies
- Blocked by OPS-001 SigNoz Parser Error Resolution (parser must be green first)

## 📎 References
- Escalation + daily routines → [`operational-checklists.md`](operational-checklists.md)
- Backlog + WIP context → [TASKS.md](../TASKS.md)
