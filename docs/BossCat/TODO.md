# BossCat Gate Verification TODO

## CI/CD Pipeline
- [x] Move `scripts/github-workflows/bosscat-gate-verify.yml` into `.github/workflows/` and align triggers with BossCat governance (PR, main, nightly)
- [x] Fix artifact handling in the workflow (download to a shared `artifacts/` directory, ensure results are available for later stages)
- [x] Remove ad-hoc `git push` from the workflow and replace with artifact publishing plus evidence upload
- [x] Add conditional logic so `workflow_dispatch` input `test_type` controls which k6 stages run (baseline/load/stress/soak/all)
- [x] Ensure `kubectl` context setup (or KinD cluster) is documented or mocked when running in CI to avoid failed namespace creation
- [x] Add lint/test hooks to the workflow (flake8, black, pytest, eslint)
- [x] Integrate mock SigNoz API for CI runs

## Performance Test Assets
- [x] Update all k6 scripts to emit an `overall_status` flag in their JSON summaries based on thresholds
- [x] Add reusable helper (JS module) to prevent duplicated threshold logic across k6 scripts
- [x] Validate k6 scripts produce deterministic outputs when environment variables are missing (fallbacks stay in SLA)
- [x] Parse Locust CSV outputs into a consolidated JSON artifact with computed success/error rates for gating
- [x] Provide a one-command runner (PowerShell + npm script) that executes k6 and Locust suites locally with configurable targets

## Synthetic Trace Tooling
- [x] Reconcile duplicate `send_synthetic_otel_simple.py` implementations (keep one canonical version under `scripts/` and update callers)
- [x] Add CLI flags for OTLP protocol selection (gRPC vs HTTP) and insecure/secure toggles
- [ ] Add unit-style smoke test to verify synthetic trace generation without contacting SigNoz (use OTLP exporter mock)
- [x] Replace emoji placeholders in PowerShell scripts with ASCII status markers (e.g., `[OK]`, `[WARN]`, `[ERROR]`)

## Verification and Reporting
- [x] Fix `verify-gate-readiness.py` so the default JSON report is written to `artifacts/gate-verification-results.json`
- [x] Teach gate verifier to emit `overall_status` for each test segment and propagate pass/fail reasons
- [x] Update `generate-ecrr-report.py` and `generate-boss-v2-report.py` to compute metrics from raw artifacts instead of hard-coded placeholders; strip control characters
- [x] Ensure both report generators support Markdown and optional PDF export into `docs/ecrr/ECRR_REPORTS/` and `docs/observability/snapshots/`
- [x] Wire the workflow to publish generated reports as build artifacts and copy them into the repo only in manual/local runs

## Documentation & Guides
- [x] Create `docs/BossCat/guides/PERFORMANCE_PIPELINE.md` describing local, CI, and Kubernetes execution paths
- [x] Update existing BossCat guides to reference the new scripts and workflows (local testing, CI integration, final gate readiness)
- [x] Add quick-start sections for each agent role (Investigator, Gap-Closer, QA Scribe) outlining how to trigger relevant scripts
- [x] Document expectations for evidence directories (`docs/ecrr/ECRR_REPORTS`, `docs/observability/snapshots`, `artifacts/`)

## Automation & Evidence
- [x] Add Playwright script or Node helper that moves latest screenshots into date-stamped folders under `docs/observability/snapshots/`
- [x] Ensure nightly automation script (`scripts/nightly-dashboard-export.ps1`) chains into the new performance pipeline or documents sequencing
- [x] Provide checksum/logging helper so every run appends an entry to `docs/BossCat/reports/BOSSCAT_LOG.md`
- [x] Add health check CLI that confirms SigNoz endpoints, OTLP ports, and Kubernetes namespace readiness before tests run

## Validation
- [x] Add lint/test hooks (e.g., `pnpm lint`, `pytest`, `pwsh` PSScriptAnalyzer) to the workflow to guard custom logic
- [x] Execute a dry-run locally (documented in artifacts) covering synthetic trace, k6 baseline, Locust user journey, and report generation
- [x] Capture follow-up issues or open questions in `docs/IONA_ERRORS.md` after the first full pipeline execution
