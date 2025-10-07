# BossCat Performance Pipeline Guide

This guide explains how to run the BossCat performance and gate verification pipeline locally and in CI.

## Overview
- **k6** covers baseline, load, stress, and soak scenarios
- **Locust** simulates user journeys against the SigNoz API
- **Synthetic trace tooling** proves OTLP ingestion health
- **Gate verifier** aggregates artifacts and produces ECRR/BOSS reports
- **Mock SigNoz server** is available for dry-runs when a real stack is not reachable

## Local Workflow
1. Optional: start the mock SigNoz API for offline runs:
   ```bash
   python scripts/mock_signoz_api.py --port 8080
   ```
2. Run k6 suites (examples):
   ```bash
   mkdir -p artifacts
   BASE_URL=http://127.0.0.1:8080 k6 run tests/k6/baseline-test.js
   BASE_URL=http://127.0.0.1:8080 k6 run tests/k6/load-test.js
   ```
3. Run Locust headless tests:
   ```bash
   locust -f tests/locust/signoz_user_journey.py \
     --headless --users 15 --spawn-rate 3 --run-time 2m \
     --host http://127.0.0.1:8080 --csv artifacts/locust/locust-results
   python scripts/parse_locust_results.py --csv-prefix artifacts/locust/locust-results
   ```
4. Fire synthetic traces when using a real collector:
   ```bash
   python scripts/send_synthetic_otel_simple.py --endpoint http://localhost:4317 --trace-count 10
   ```
5. Aggregate the gate verdict and reports:
   ```bash
   python scripts/verify-gate-readiness.py --artifacts-dir artifacts --signoz-url http://127.0.0.1:8080
   python scripts/generate-ecrr-report.py --gate-results artifacts/gate-verification-results.json --output docs/ecrr/ECRR_REPORTS/local-gate.md
   python scripts/generate-boss-v2-report.py --gate-results artifacts/gate-verification-results.json --output docs/BossCat/reports/local-boss-v2.md
   ```

## GitHub Actions Summary
- Workflow: `.github/workflows/bosscat-gate-verify.yml`
- `workflow_dispatch` input `test_type` runs a single k6 stage or the full matrix
- Each job launches the mock SigNoz API so tests succeed in CI
- Reports and raw artifacts are uploaded via `actions/upload-artifact`
- Gate job fails the workflow if overall status is not `PASS`

## Evidence Directories
- `artifacts/` ? raw k6 summaries, Locust CSV and JSON, gate verifier results
- `docs/ecrr/ECRR_REPORTS/` ? long-lived human-reviewed ECRR outputs (commit manually)
- `docs/observability/snapshots/` ? Playwright captures and dashboards (created by nightly automation)
- `docs/BossCat/reports/` ? curated history of BossCat report bundles

## Quick Commands
- Full local dry-run with mock SigNoz:
  ```bash
  pnpm install --frozen-lockfile
  python scripts/mock_signoz_api.py --duration 900 &
  pnpm bosscat:perf:all   # add this script if desired
  ```
- Single k6 test:
  ```bash
  BASE_URL=http://127.0.0.1:8080 VUS=20 DURATION=1m k6 run tests/k6/stress-test.js
  ```
- Generate only reports from existing artifacts:
  ```bash
  python scripts/generate-ecrr-report.py --gate-results artifacts/gate-verification-results.json --output artifacts/reports/re-run-ecrr.md
  ```

## Agent Responsibilities
- **Investigator**: confirm mock or real SigNoz availability, execute k6 and Locust suites
- **Gap-Closer**: update thresholds, fix scripts, and re-run pipeline on failures
- **QA Scribe**: file ECRR/BOSS outputs into the documentation tree and notify BossCat OEM

## Troubleshooting
- Missing artifacts: rerun Locust parser (`scripts/parse_locust_results.py`) and ensure `artifacts/` exists before tests
- No traces found: verify OTLP endpoint address or use `scripts/mock_signoz_api.py` for offline testing
- Workflow failure: download the `bosscat-gate-reports` artifact for full JSON context
