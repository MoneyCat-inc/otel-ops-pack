# OpenTelemetry Stack Audit — SSOT Snapshot

| Area | Status | Notes |
| --- | --- | --- |
| Config integrity | 🔴 Needs fixes | Windows collector config fails to load because of undefined processors/exporters; tail sampling unused. |
| Reliability & performance | 🟠 Gaps | No queue/backoff on core exporters; local harness lacks memory guardrails. |
| Security & privacy | 🟡 Mixed | Legacy config redacts secrets, but active Windows config ships without sanitizers. |
| Observability of observability | 🟢 Partial | Health checks in place, but no coverage for local test collector. |
| Test / CI posture | 🟠 Gaps | Only syntax lint for one config; no deterministic smoke in CI. |
| Runbooks & recovery | 🟢 Strong base | Detailed Windows break/fix steps exist; need condensed playbook for quick use. |

## Executive Summary

The current Windows → SigNoz observability stack contains **blocking configuration defects** (log pipeline references a non-existent processor/exporter) that will prevent the Windows collector from starting. Reliability controls on both the Windows and SigNoz collectors trail recommended baselines (no retry/queue envelope, missing memory limiter). Security posture regressed because the Windows config that is most prominently documented lacks the redaction/attribute controls present in the hardened baseline. CI only validates YAML syntax for a single file and has no automated smoke; operators rely on ad-hoc scripts. Introduce the attached findings, adopt the new smoke harness, and close the config gaps before promoting changes.

## Findings by Theme

### 1. Config integrity

* **Windows collector config regression.** `config/otelcol-windows.yaml` defines `processors.batch/logs` but the log pipeline references `batch` and adds a `debug` exporter that is never defined, which causes startup failure. Metrics and traces pipelines contain empty receiver lists and also reference the undefined `batch` processor.【F:config/otelcol-windows.yaml†L1-L52】【F:config/otelcol-windows.yaml†L53-L74】
* **Legacy config drift.** `config.yaml` wires sanitizers, filters, and tail sampling but only exposes a logs pipeline, so tail sampling never activates and there is no metrics/traces coverage. The file also omits exporter retry/queue configuration for the primary OTLP path.【F:config.yaml†L1-L72】【F:config.yaml†L73-L154】
* **Local harness gaps.** `collector/otel-local.yaml` lacks `memory_limiter`, retry/queue controls, and any health extension, so it is unsuitable for sustained smoke use.【F:collector/otel-local.yaml†L1-L33】
* **SigNoz collector exporter hardening outstanding.** `config/signoz-collector.yaml` enables batch processing but omits `memory_limiter` and leaves exporters without retry/backoff or queues, so transient failures can drop data.【F:config/signoz-collector.yaml†L1-L88】

### 2. Reliability & performance

* No queue/backoff envelopes on the primary OTLP exporters (`config/otelcol-windows.yaml`, `collector/otel-local.yaml`, `config/signoz-collector.yaml`), so bursts rely on best-effort delivery.【F:config/otelcol-windows.yaml†L34-L52】【F:collector/otel-local.yaml†L20-L33】【F:config/signoz-collector.yaml†L60-L88】
* Memory guardrails are inconsistent: the production Windows config caps at 256 MiB without spike handling, the local harness has no limiter, and SigNoz collector has none.【F:config/otelcol-windows.yaml†L25-L38】【F:collector/otel-local.yaml†L18-L31】【F:config/signoz-collector.yaml†L19-L88】
* SLO targets exist in `config/slo-config.json`, but there is no automation enforcing or reporting against them.【F:config/slo-config.json†L1-L17】

### 3. Security & privacy

* Hardened baseline (`config.yaml`) provides sanitization (`transform/sanitize`) and redaction processors, yet `config/otelcol-windows.yaml`—which is linked throughout the repo—omits them, so sensitive values can leak when teams follow the wrong config.【F:config.yaml†L27-L72】【F:config/otelcol-windows.yaml†L25-L52】
* `docker-compose.yml` stores the SigNoz JWT secret inline, which is fine for local dev but should be parameterized before shared environments.【F:docker-compose.yml†L1-L59】

### 4. Observability of the observability

* Windows collector ships with a health extension, but the local smoke collector does not expose health or telemetry endpoints, limiting triage visibility.【F:config/otelcol-windows.yaml†L1-L24】【F:collector/otel-local.yaml†L1-L33】
* SigNoz collector exports its own metrics (`prometheus` receiver) and health/pprof endpoints, which is good; add dashboards to watch exporter queue depth once queues exist.【F:config/signoz-collector.yaml†L1-L59】【F:config/signoz-collector.yaml†L60-L88】

### 5. Test / CI posture

* The only automation that validates collector configuration is `validate-yaml.py`, which runs against `config.yaml` only; no validation covers the Windows/SigNoz configs or ensures processor wiring is correct.【F:validate-yaml.py†L1-L22】
* PowerShell scripts (`validate-pipeline.ps1`, `verify-pipeline.ps1`, `scripts/test-otel-integration.ps1`) exist but require manual invocation and are not wired into CI.【F:validate-pipeline.ps1†L1-L117】【F:verify-pipeline.ps1†L1-L46】【F:scripts/test-otel-integration.ps1†L1-L80】

### 6. Runbooks & recovery

* `ON_CALL_RUNBOOK.md` delivers deep recovery guidance, but responders still need a one-page quick reference and a deterministic smoke command; both are added in this audit.【F:ON_CALL_RUNBOOK.md†L1-L120】

## Risk → Mitigation

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Windows collector fails to start due to undefined processors/exporters. | Complete loss of Windows log ingest. | Align processor/exporter names in `config/otelcol-windows.yaml` and remove unused pipelines or supply valid receivers. |
| SigNoz collector drops data during ClickHouse hiccups. | Data loss under burst/backpressure. | Add `memory_limiter`, `retry_on_failure`, and `sending_queue` to all OTLP exporters in `config/signoz-collector.yaml`. |
| Sensitive data leaks from Windows logs when teams copy the wrong config. | Compliance breach. | Promote `config-hardened-plus.yaml` as default or port its sanitizers into `config/otelcol-windows.yaml`. |
| Smoke tests give false confidence because local collector has no guardrails. | Latent issues reach production. | Update `collector/otel-local.yaml` with memory limiter, queue controls, and health endpoint before using it in CI harness. |
| CI misses config regressions. | Broken pipelines merge undetected. | Wire `scripts/otel/smoke.ps1` / `.sh` into CI alongside schema validation so pull requests exercise the full path. |

## Evidence & Artifacts

* Configuration issues and current baselines: `config/otelcol-windows.yaml`, `config.yaml`, `collector/otel-local.yaml`, `config/signoz-collector.yaml`.
* Reliability targets: `config/slo-config.json`.
* Manual validation tooling: `validate-yaml.py`, `validate-pipeline.ps1`, `verify-pipeline.ps1`, `scripts/test-otel-integration.ps1`.
* Recovery documentation: `ON_CALL_RUNBOOK.md`.
* New artifacts from this audit:
  * `docs/otel/FINDINGS.json` — machine-readable findings list.
  * `docs/otel/PLAYBOOK.md` — one-page break-glass playbook.
  * `scripts/otel/smoke.ps1` and `scripts/otel/smoke.sh` — deterministic local smoke harness.

## Next Steps

1. Patch `config/otelcol-windows.yaml` to fix processor/exporter names, add sanitizers, and enable retry/queue envelopes.
2. Backport hardened controls (`memory_limiter`, retries) to `collector/otel-local.yaml` and `config/signoz-collector.yaml`.
3. Integrate the new smoke harness into CI (invoke PowerShell on Windows runners, Bash on Linux) so every PR exercises OTLP log/trace/metric round-trips.
4. Publish dashboards that visualize collector health endpoints and queue depth once retry buffers are added.
5. Redact or externalize secrets in `docker-compose.yml` before sharing images or running in staging/prod.
