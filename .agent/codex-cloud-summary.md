# Codex-Cloud Enablement Summary

Codex-Cloud is an automation-focused agent responsible for maintaining the OpenTelemetry operations toolkit in this repository. The following artifacts define its mission, configuration, and operating procedures.

## Key Artifacts
- **Mission Prompt:** `.agent/codex-cloud-setup-prompt.md` — establishes Codex-Cloud's identity, scope, safety rules, and operating workflow.
- **Configuration Parameters:** `.agent/codex-cloud-config.json` — machine-readable limits, infrastructure metadata, safety guardrails, and integration hooks.
- **Quick Reference:** `.agent/codex-cloud-quick-reference.md` — day-to-day checklist, common commands, style guidance, and emergency playbooks.
- **GitHub Actions Workflow:** `.github/workflows/codex-cloud-trigger.yml` — automates task intake via labels, PR comments, and manual dispatch.
- **State Queue:** `.agent/state/queue.jsonl` (created on demand) — newline-delimited tasks consumed by Codex-Cloud workers.

## Operational Flow
1. **Trigger Detection:** GitHub Actions listens for workflow dispatches, PR labels (`needs-conflict-help`, `needs-codex-cloud`), and PR comments containing `@codex` or `@codex-cloud`.
2. **Task Queuing:** The workflow generates a structured queue entry and uploads it as an artifact. The entry includes task type, priority, requester, and related URLs.
3. **Execution:** Codex-Cloud reads the mission prompt and quick reference to plan, execute, and validate requested work while respecting safety limits (≤10 files, ≤200 changed LOC).
4. **Validation:** Required scripts such as `safe-apply-config.ps1`, `quick-all-green.ps1`, and `canary-check-min.ps1` ensure telemetry changes are safe before completion.
5. **Reporting:** Status comments summarize queued work, while operators reference the summary template from the quick reference for final reports.

## Safety & Escalation
- Rollbacks must restore `C:\otel\config.yaml` from the backup and restart `otelcol-contrib`.
- Escalate incidents through the Observability On-Call (`#observability-alerts`) or Platform SRE (`#platform-sre`).
- Never commit secrets, modify SigNoz credentials, or force-push protected branches.

## Next Steps for Operators
1. Review the mission prompt to familiarize yourself with Codex-Cloud's responsibilities.
2. Populate `.agent/state/queue.jsonl` with an initial task via the GitHub Actions workflow to verify end-to-end flow.
3. Keep the quick reference accessible during incident drills and weekly audits.

Codex-Cloud is now fully provisioned to collaborate with existing agents, handle conflict resolution, and maintain the Windows collector + SigNoz observability stack with documented guardrails.
