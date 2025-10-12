# BossCat Pinned TODOs

Purpose
- Track downstream actions BossCat wants to execute when convenient.
- All items follow ECRR and produce evidence on completion.

## Queue (Pending)

- **BOSS-CATX-COMP-CI01** – 🟡 TRACKED (2025-10-13) - CI Gate Verify 0s Failure
  - Status: Deferred with T+48h SLA (by 2025-10-15 00:25)
  - Issue: BossCat Gate Verify workflow reports immediate failure (0s duration)
  - Impact: 1/4 required checks failing (non-blocking, local gate confirms READY)
  - Root Cause: Matrix job filtering or artifact assertion failures
  - Tracking Doc: `docs/BossCat/CI_GATE_VERIFY_TRACKING.md`
  - Temporary Policy: PRs proceed with local gate artifact attached
  - Owner: BossCat OEM
  - Priority: P0 (deferred per Directive 008)

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
