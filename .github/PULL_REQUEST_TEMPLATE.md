[![ECRR](https://img.shields.io/badge/✅%20ECRR-Required-7c5cff?style=flat-square)](../AGENTS.md#-agents--ecrr-mantra)

> **Reminder:** Follow the ECRR mantra — Examine → Clean → Report → Role.

# 🚀 Pull Request: <title>

## Summary
<!-- What & why -->

## Screens / Artifacts
- [ ] Screens or GIFs attached (if UX/visual)

## Creative Compliance (Comfort Cat)
- [ ] Palette matches `docs/comfort-cat/palette.md`
- [ ] Type & hierarchy match `docs/comfort-cat/type.md`
- [ ] Motion follows `docs/comfort-cat/motion.md` (respect prefers-reduced-motion)
- [ ] Copy tone & CTA align with `docs/comfort-cat/copy.md`
- [ ] Proof points align with `docs/comfort-cat/proofpoints.md`
- [ ] Accessibility checks per `docs/comfort-cat/accessibility.md`
- [ ] Success checklist in `docs/comfort-cat/success-criteria.md` passes
- [ ] Header comment present in changed creative files: `See C:\otel\docs\comfort cat`

## ✅ Env Clean & Healthy (from RUN_AND_VERIFY.md)
- Tidy: ☐/✅
- Install: ☐/✅
- Build: ☐/✅
- Smoke (Playwright): ☐/✅/N/A
- Isolation (crossOriginIsolated): ☐/✅

Notes:

## Risk
- [ ] Low  - config/docs
- [ ] Med  - service/alerts
- [ ] High - pipelines/runtime

## Verification (paste outputs or screenshots)
- [ ] Ran `pwsh .\tools\fix-yaml.ps1` (or `pre-commit run --all-files`)
- [ ] Ran `pwsh .\tools\hygiene.ps1` (attach artifacts/hygiene.log)
- [ ] `otelcol --config config/otelcol-windows.yaml --dry-run` succeeded
- [ ] Canary verify passed (`scripts/verify-canary.ps1`)
- [ ] Rollback path validated (if applicable)
- [ ] Docker compose validation passed (`docker compose -f compose/signoz.yml config`)

## Hygiene Checklist
- [ ] Repo structure & docs match `docs/REPO_HYGIENE.md`
- [ ] No secrets committed; `.env.example` updated
- [ ] CI is green (lint, actionlint, yamllint, PSScriptAnalyzer)
- [ ] PowerShell scripts follow quality standards (Set-StrictMode, ErrorActionPreference)
- [ ] YAML files pass yamllint validation
- [ ] OTel collector configs validate with `otelcol --dry-run`
- [ ] Docker compose files are syntactically valid

## ECRR Gate
- [ ] Examine: SigNoz UI reachable, collector service running, canary test passes
- [ ] Clean: Collector restarted if needed, SigNoz stack healthy, noisy logs cleared, ports conflict-free
- [ ] Report: ECRR report pasted below with links to evidence
- [ ] Role: Declared (Observability Copilot | OTel Steward | Agent Coordinator | Local Worker) with artifacts listed

## Artifacts
- Tests and scripts executed (include command output summaries)
- Dashboards/configs/docs updated or linked
- Agent status updated if touched

## ECRR Report
<!-- Paste docs/ECRR_REPORT_TEMPLATE.md contents here -->

## Changes
<!-- What did you change? -->

## Risk and Rollback
<!-- Key risks plus how to revert quickly -->
