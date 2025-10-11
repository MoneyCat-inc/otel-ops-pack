# ECRR – GPU_FIX v1.1 Hardening

Timestamp: ${DATE}
Branch: ${BRANCH}
Commit: ${COMMIT}

## Examine

- Gate×Site Matrix: active (IONA, GPU_FIX, PERF_SUMMARY × ci/local/prod)
- USE_MOCK policy: PR=true; push/nightly=false
- k6 thresholds: site-aware, CI-gated via exit code
- Ingestion evidence: health + emit + verify (prod/non-mock enforced)
- Preflight: budgets/kill-switch enforced in CI

## Clean

- Added k6 GPU_FIX runner with SLO gating
  - Files: `BRAV/SCPT/load/gpu_fix.js`, `scripts/summarize-perf.js`
  - Summary export: `DELT/ARTF/gpu_fix/k6-summary.json`
  - Roll-up: `DELT/ARTF/gpu_fix/gpu_fix_summary.json`
- Scoped artifact uploads per gate
- Moved tests out of ignored `tests/` to `BRAV/SCPT/load/`

## Report

- SLOs (effective):
  - prod + real: p95 < 200 ms; error-rate < 0.5%
  - ci/local or mock: p95 < 500 ms; error-rate < 1%
- Evidence locations:
  - GPU_FIX: `DELT/ARTF/gpu_fix/*.json`
  - IONA: `DELT/ARTF/gate-verification-results.json`, `PR_COMMENT_IONA_GATE_002_FINAL.md`
- Watchdog: OpenSSL waiver (SigNoz), review on/after 2025-11-07 (main only)

## Role

- Next actions:
  - Validate matrix run (ci/local/prod) — ensure GPU_FIX gates on breach
  - Tune site thresholds after 1 week of nightly data
  - Optional: add PERF_SUMMARY aggregator per-site

