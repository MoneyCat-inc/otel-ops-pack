# BossCat Pinned TODOs

Purpose
- Track downstream actions BossCat wants to execute when convenient.
- All items follow ECRR and produce evidence on completion.

## Queue (Pending)

- PR #118 – ✅ MERGED (2025-10-10) - POST-MERGE REMEDIATION REQUIRED
  - Status: Merged with check failures (admin override)
  - Action Required: Address failures now in main branch
  - Critical failures: Build (guard, config, signature-registry.json), Gate (GATE-BETA Monitor), Compliance (Guardrails, Repo Structure)
  - Strategy: Prioritize critical build/gate failures, document security scan findings
  - Produce ECRR post-merge remediation report
  - Owner: BossCat OEM
  - Priority: P0 (failures in production)

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
