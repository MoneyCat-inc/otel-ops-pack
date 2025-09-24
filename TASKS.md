# TASKS.md — Observability Operations Board

_Last updated: 2025-09-23 by **Observability Copilot**_

## 📊 Snapshot
- **12 tracked work items** → 8 pending / 1 in progress / 3 done
- **Roles & WIP**: limits enforced at 2 concurrent items per primary assignee
- **Current focus**: unblock the SigNoz parser and prep monitoring rollout gated on that fix
- **Artifacts**: Acceptance criteria + verification steps live in [`RUNBOOKS/`](RUNBOOKS/)

## 👥 Roles & WIP Guardrails
| Role / Owner | WIP Limit | Active Slots | Notes |
|--------------|-----------|--------------|-------|
| Observability Engineer (Alex) | 2 | OPS-001 (active), OPS-004 (queued) | Keeps parser + pipeline work in scope without overload |
| Observability Duty (rotation) | 2 | OPS-002, OPS-010 | Rotating on-call handles monitoring + alert hygiene |
| Automation Engineer (Mira) | 2 | OPS-003A, OPS-003B | Owns ECRR framework build/rollout |
| System Admin (Ravi) | 2 | OPS-007 | Took over infra-heavy INDEX management as recommended |
| Data Steward (Lina) | 1 | OPS-005 ✅ | Ledger automation complete; on standby for audits |
| Strategy Analyst (Noor) | 1 | OPS-006 | Alignment study follows pipeline delivery |
| QA Scribe (Eli) | 1 | OPS-009 | Refreshing runbook evidence |
| Codex Agent (Automation) | 1 | OPS-011 ✅ | Guardrail audit complete |

## 🔗 Dependency Graph
| From | → | To | Rationale |
|------|---|----|-----------|
| OPS-001 SigNoz Parser Error Resolution | → | OPS-002 Parser Regression Monitoring | Don’t ship monitoring until parser is healthy |
| OPS-001 SigNoz Parser Error Resolution | → | OPS-004 Observability Pipeline Implementation | Parser fix feeds pipeline validation |
| OPS-004 Observability Pipeline Implementation | → | OPS-006 ECRR Task Alignment Analysis | Alignment requires live pipeline data |
| OPS-003A Framework Scaffolding | → | OPS-003B Framework Guardrails Rollout | Guardrails follow the core framework |
| OPS-003A Framework Scaffolding | → | OPS-005 Ledger Management Automation | Ledger ingest relies on canonical task schema |
| OPS-003A Framework Scaffolding | → | OPS-007 INDEX Management Rotation | Index routines use framework IDs |

## 📋 Task Catalog
| ID | Title | Priority | Status | Owner | Dependencies | Notes & Artifacts |
|----|-------|----------|--------|-------|--------------|-------------------|
| OPS-001 | SigNoz Parser Error Resolution | High | 🚧 In Progress | Observability Engineer | – | See [`RUNBOOKS/sigNoz-parser-resolution.md`](RUNBOOKS/sigNoz-parser-resolution.md) |
| OPS-002 | Parser Regression Monitoring | High | ⏳ Pending | Observability Duty | OPS-001 | Acceptance in [`RUNBOOKS/parser-regression-monitoring.md`](RUNBOOKS/parser-regression-monitoring.md) |
| OPS-003A | ECRR Task Generation Framework — Core Scaffolding | High | ⏳ Pending | Automation Engineer | – | Schema + writers baseline; DoD in [`RUNBOOKS/ecrr-task-generation-framework.md`](RUNBOOKS/ecrr-task-generation-framework.md) |
| OPS-003B | ECRR Task Generation Framework — Rollout & Guardrails | Medium | ⏳ Pending | Automation Engineer | OPS-003A | Covers auto-labels, anti-spam, SLAs |
| OPS-004 | Observability Pipeline Implementation | High | ⏳ Pending | Observability Engineer | OPS-001 | Pipeline validation unblocked once parser is green |
| OPS-005 | LEDGER Management Automation | Medium | ✅ Done | Data Steward | OPS-003A | Ledger entries now produced via framework schema |
| OPS-006 | ECRR Task Alignment Analysis | Medium | ⏳ Pending | Strategy Analyst | OPS-004 | Confirms pipeline feeds align with roadmap |
| OPS-007 | INDEX Management Rotation | Medium | ⏳ Pending | System Admin | OPS-003A | Rotated off engineer queue per WIP guidance |
| OPS-008 | SigNoz Dashboard Hardening | Low | ✅ Done | Observability Duty | – | Panels live; thresholds mirrored in alerts |
| OPS-009 | Incident Runbook Refresh | Low | ⏳ Pending | QA Scribe | – | Ensure RUNBOOKS/ coverage & latest evidence |
| OPS-010 | Alert Channel Audit | Medium | ⏳ Pending | Observability Duty | – | Validate recipients, silences, runbook links |
| OPS-011 | Automation Guardrail Audit | Low | ✅ Done | Codex Agent | – | Watchdog + CI guardrail checks completed |

### Epic Spotlight: OPS-003 — ECRR Task Generation Framework
- **Goal**: Single source for task creation with consistent schema + automated hygiene
- **Subtasks**:
  - **OPS-003A** — build canonical IDs, writers, and schema validation harness
  - **OPS-003B** — enable rollout guardrails (auto-labels, spam protection, SLA enforcement)
- **Feeds**: OPS-005 Ledger Automation, OPS-007 Index Rotation, downstream reporting
- **Artifacts**: DoD + verification steps documented in [`RUNBOOKS/ecrr-task-generation-framework.md`](RUNBOOKS/ecrr-task-generation-framework.md)

## ✅ Recently Completed
- **OPS-005** — Ledger automation wired into new schema; audit trail exported to `artifacts/ledger-sync-20250922.json`
- **OPS-008** — Dashboard hardening shipped with drift panels + warning bands
- **OPS-011** — Automation guardrails verified; CI parity report archived in `docs/ECRR_REPORTS/`

## 🧾 Definition of Done by Priority Band
### High Priority
- ✅ Linked runbook with acceptance checklist
- ✅ Automated test / verification script executed with evidence attached
- ✅ Impact metrics (KPI set below) captured before & after change
- ✅ Rollback plan documented or referenced

### Medium Priority
- ✅ Acceptance criteria mapped to measurable checks (manual or automated)
- ✅ Stakeholder notified / documentation updated
- ✅ Change logged in ledger/index with framework ID

### Low Priority
- ✅ Change reviewed for regressions or doc drift
- ✅ Reference added to relevant runbook or knowledge base

## 📈 KPI Snapshot Targets
Track these in weekly status pings (see dashboards):
- **Parser Quality**: `parse_error_rate %`, `dropped_events/min`
- **Latency**: ingest `p50/p95/p99` (source → query)
- **Schema Stability**: `new_keys/week`, top drifted fields
- **Throughput**: events/sec (raw vs parsed), compression ratio
- **Ops Health**: mean-time-to-ack (MTTA), mean-time-to-repair (MTTR)

## 🗓️ Operational Checklists
- Daily / Weekly / Monthly routines captured in [`RUNBOOKS/operational-checklists.md`](RUNBOOKS/operational-checklists.md)
- Use the daily checklist before reporting KPIs; weekly for backlog hygiene; monthly for resilience drills

## 📝 Next Status Update Template
1. **Blockers** — top 2
2. **Delta** — what moved since last report
3. **KPI Snapshot** — the 5 metrics above (pass/fail)
4. **Decision Needed** — optional; frame with 2 options

_ECRR mantra honoured: Examine → Clean → Report → Role._
