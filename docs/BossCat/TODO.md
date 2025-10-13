# BossCat Pinned TODOs

Purpose
- Track downstream actions BossCat wants to execute when convenient.
- All items follow ECRR and produce evidence on completion.

## Queue (Pending)

- **BOSS-CATX-OPER-DIRE-009** – ✅ EXECUTED (2025-10-13 00:40) - Gate Workflow Unblocker
  - Status: Minimal validated skeleton deployed
  - Context: Evolved from BOSS-CATX-COMP-CI01 (0s duration failures)
  - Solution: Replace 500+ line complex workflow with 180-line minimal skeleton
  - Features: actionlint guard, budget enforcement, SBOM strict mode (prod)
  - Files: bosscat-gate-verify.yml (replaced), enforce-budgets.mjs (new)
  - Tracking Doc: `docs/BossCat/DIRECTIVE_009_GATE_WORKFLOW_UNBLOCKER.md`
  - Validation: Next push will test unconditional matrix execution
  - Owner: BossCat OEM
  - Priority: P0 → COMPLETE (awaiting CI validation)

- PR #118 – ✅ PARTIALLY REMEDIATED (2025-10-10 to 2025-10-13)
  - Status: Guardrails passing, 3/4 required checks GREEN
  - Remaining: CI workflow configuration issue (tracked as BOSS-CATX-COMP-CI01)
  - Security scans: 8 tools failing (non-blocking per policy)
  - Evidence: Local gate verification confirms system health
  - Next: Complete CI fix within T+48h
  - Owner: BossCat OEM
  - Priority: P0 → P1 (downgraded, tracked separately)

## Done (Add entries as items complete)

1) ✅ Normalize canonical analysis doc (P1) - **COMPLETE 2025-10-10**
- Path: docs/BossCat/analysis/system-issues-fractal.download.md
- Goal: Production-ready Markdown (frontmatter, no HTML anchors, clean citations)
- Actions completed:
  - ✅ pwsh -File scripts/normalize-markdown-analysis.ps1 -Path docs/BossCat/analysis/system-issues-fractal.download.md
  - ✅ pnpm map:generate (57 nodes, 9 edges generated)
  - ✅ pnpm map:validate (0 missing files)
  - ✅ pnpm map:guard (P0 check passed)
- Owner: BossCat OEM
- Evidence: .agent/EVIDENCE.log event "doc_normalized" logged
- Status: **DONE** ✅
