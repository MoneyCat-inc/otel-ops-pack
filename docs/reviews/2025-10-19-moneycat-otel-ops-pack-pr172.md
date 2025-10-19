# BossCat Codex-Cloud Review — MoneyCat otel-ops-pack PR #172

- **URL:** https://github.com/MoneyCat-inc/otel-ops-pack/pull/172
- **Author:** @fubumaki
- **Lane:** Governance / Registry Hardening
- **Verdict:** ⛔ **Block — required guardrails missing**

## Summary of proposed changes
- Require MoneyCat maintainers to review the workflow registry, schema, guard workflow, documentation hub, and BossCat governance docs via new CODEOWNERS entries.
- Extend `bosscat-gate-bot-native` to pre-warm Docker, add compose health polling, capture diagnostics on failure, and lengthen timeouts for SigNoz bring-up.
- Add two new GitHub Actions workflows:
  - `registry-drift-check`: nightly regeneration of `docs/status/workflows.json` that auto-opens a PR when drift is detected.
  - `registry-guard`: pull-request gate that regenerates the registry, compares it to committed state, and validates it against a JSON schema.
- Check in a PowerShell regeneration script plus JSON schema/registry artefacts for the workflows catalog, and add extensive hub deployment runbooks/status docs.

## Blocking findings
1. **Registry guard only checks counts and names.** The guard workflow performs a semantic comparison but limits the assertions to total workflow count and the sorted list of names. Trigger changes inside `docs/status/workflows.json` (e.g., adding/removing `workflow_dispatch`, adjusting schedules) would therefore pass undetected, defeating the goal of locking down registry drift. The guard must compare the full trigger matrix (and ideally timestamps/sizes) before we can certify it as an enforcement gate.
2. **Legacy CODEOWNERS coverage lost.** Replacing the existing CODEOWNERS block drops explicit protection for top-level configuration files such as `config.yaml`, `config-hardened-plus.yaml`, and the PowerShell scripts that previously required @fubumaki review. Unless those paths were intentionally retired in the same branch, this change re-opens critical infrastructure to unreviewed edits. We need confirmation that equivalent ownership remains (or the files are deleted) before approving.

## Recommendations before re-review
- Extend the registry guard comparison to iterate each workflow’s trigger flags (and optionally file metadata) so behavioural drift fails the job instead of silently passing.
- Either restore CODEOWNERS coverage for the removed config/scripts or document their deprecation in the PR with matching deletions.

BossCat gate stays closed until these regressions are addressed.
