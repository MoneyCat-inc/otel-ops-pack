# Codex-Cloud Quick Reference

## Daily Checklist
- ☐ Sync local repository and review `.agent/state/queue.jsonl` for pending tasks.
- ☐ Confirm Windows collector health (`Get-Service otelcol-contrib`).
- ☐ Review SigNoz dashboards for ingestion latency or error spikes.
- ☐ Verify latest documentation changes in `README.md` and wallet cards remain accurate.

## Common Operations
| Task | Command | Notes |
| --- | --- | --- |
| Validate collector config | `safe-apply-config.ps1 -Path C:\otel\config.yaml -ValidateOnly` | Run before any rollout. |
| Apply and verify config | `safe-apply-config.ps1 -Path C:\otel\config.yaml -Restart` | Automatically restarts service on success. |
| Quick telemetry smoke test | `canary-check-min.ps1` | Confirms OTLP ingest and SigNoz pipeline. |
| Full regression sweep | `quick-all-green.ps1` | Aggregates regression, canary, and restart checks. |
| Kafka integration smoke | `kafka-smoke.ps1` | Ensures Kafka exporter and topics healthy. |
| Weekly audit prep | `setup-weekly-audit.ps1` | Generates compliance evidence package. |

## GitHub Action Triggers
- **Labels:** `needs-conflict-help`, `needs-codex-cloud`
- **Commands:** Comment containing `@codex` or `@codex-cloud` queues a task.
- **Manual Dispatch:** Use the `Codex-Cloud Trigger` workflow with inputs:
  - `task_type` – one of `documentation-update`, `configuration-change`, `conflict-resolution`, `observability-audit`, `incident-response`
  - `description` – short description of requested work
  - `target_number` – issue or PR number to report status to
  - `priority` – `standard` (default) or `urgent`

## Style & Documentation Rules
- Follow `.agent/policies.md` for formatting and commit expectations.
- Keep YAML keys sorted and indentation consistent with existing files.
- Record operational changes in the relevant runbook (`ON_CALL_RUNBOOK.md`, `OPS_WALLET_CARD.md`).
- When updating scripts, include PowerShell comment-based help with examples.

## Conflict Resolution Flow
1. Collect canonical versions of conflicting files using `git show` for each side.
2. Draft a structured brief for Cursor-Local with:
   - File order, authoritative source, and sections to preserve
   - Summary of semantic differences
   - Tests or commands required after merge
3. Post summary comment on the PR referencing the brief location.
4. Update `.agent/state/queue.jsonl` with resolution status once conflicts are cleared.

## Emergency Procedures
- **Telemetry outage:**
  1. Restore `config.yaml` from `config.yaml.backup`.
  2. Run `auto-restart-verify.ps1` to ensure the service recovers cleanly.
  3. Disable background automation until SigNoz ingestion stabilizes.
  4. Notify `#observability-alerts` with incident summary.
- **Misconfiguration detected:**
  1. Roll back using `safe-apply-config.ps1 -Rollback`.
  2. Capture logs from `C:\otel\logs` and attach to incident record.
  3. File follow-up task in queue for root cause analysis.

## Useful SigNoz Queries
- **Errors by service (last 15m):**
  ```sql
  SELECT serviceName, count(*)
  FROM traces
  WHERE timestamp >= now() - INTERVAL 15 MINUTE
  GROUP BY serviceName
  ORDER BY count(*) DESC;
  ```
- **Collector CPU vs. throughput:** Dashboard `Collector / Performance` panel `CPU % vs Exported Spans`.
- **ClickHouse health:** `SELECT * FROM system.clusters;`

## Reporting Template
```
Task: <summary>
Source: <workflow/label/comment>
Changes: <files touched>
Validation: <commands + results>
Follow-ups: <risks, TODOs>
```
Attach artifacts (logs, screenshots) when available and link to queue entry for cross-referencing.
