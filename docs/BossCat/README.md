# BossCat Operations Guide

Purpose: Governance and local-first operations for Resonai [OTel].

Key Artifacts:
- docs/ecrr/ECRR_REPORTS/ — ECRR audit trails
- docs/observability/snapshots/ — Dashboard exports
- docs/status/ — Status and test summaries
- docs/IONA_ERRORS.md — Error ledger

Runbooks:
- Gate verify: pwsh -NoProfile -File scripts/verify-iona-gate.ps1 -Strict
- ECRR benchmark: pwsh -NoProfile -File scripts/benchmark-process-all-ecrr-reports.ps1

