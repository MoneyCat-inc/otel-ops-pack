# ECRR Compliance Report - BossCat OEM Action Items
Date: 2025-10-05
Actor: Codex Agent (OTel Steward)

---

## Executive Summary
- Resolved the log export stall between the Windows OpenTelemetry Collector and the SigNoz collector by aligning OTLP listener ports (localhost:14317) and enabling the SigNoz logs pipeline.
- Restarted collectors and verified telemetry health with `scripts/test-end-to-end-pipeline.ps1` (latest run: 100% success, queue utilisation 0%).
- Installed Trivy 0.67.0, scanned all running observability images, and documented remaining 4 critical / 29 high vulnerabilities.
- Updated compliance artefacts (`docs/status/tests.json`, `docs/SECURITY_VULNERABILITY_REMEDIATION_PLAN.md`, security scan evidence under `artifacts/security-scans/`).

---

## ECRR Breakdown
### Examine
- Reviewed `docs/status/tests.json` (Docker security scan failure, success rate 93.3%).
- Inspected `signoz-collector-config.yaml` and discovered logs pipeline disabled and Prometheus target pointing to port 8889.
- Confirmed Windows collector metrics endpoint (`http://localhost:8888/metrics`) showed exporter queue saturation and zero logs sent.

### Clean
- Updated `signoz-collector-config.yaml` to:
  - scrape metrics from `localhost:8888` and `host.docker.internal:8888`;
  - enable OTLP logs pipeline with redaction plus batching;
  - configure ClickHouse log exporter queueing.
- Patched `config.yaml` (Windows collector) to send OTLP traffic to `localhost:14317`.
- Restarted `signoz-otel-collector` container and the `otelcol-contrib` Windows service to apply changes.
- Installed Trivy via Chocolatey and ran high/critical scans against Signoz collector, Signoz core, ClickHouse, and Zookeeper images.

### Report
- Pipeline evidence: `artifacts/end-to-end-pipeline-test-20251005-090259.md` (HEALTHY outcome) and prior degraded runs retained for traceability.
- Security evidence: individual Trivy reports and `artifacts/security-scans/trivy-summary-20251005.json`.
- Compliance documentation refreshed:
  - `docs/status/tests.json` now records the successful pipeline test and updated security findings.
  - `docs/SECURITY_VULNERABILITY_REMEDIATION_PLAN.md` captures outstanding CVEs and mitigation steps.

### Role
- Acting Role: OTel Steward (Gap-Closer).
- Hand-off Items:
  - Follow up with SigNoz maintainers for patched collector and zookeeper images.
  - Schedule weekly Trivy rescans (integrate into nightly automation script).
  - Monitor `docs/status/tests.json` security entry until vulnerabilities are cleared.

---

## Key Test Outcomes
| Test | Status | Evidence |
| --- | --- | --- |
| End-to-end pipeline test | Passed | `artifacts/end-to-end-pipeline-test-20251005-090259.md` |
| Windows collector status | Passed | `artifacts/windows-collector-status-20251005-084954.txt` |
| Docker security scan | Failed | `artifacts/security-scans/*.json` (4 critical / 29 high outstanding) |

---

## Security Posture (Trivy 0.67.0)
- signoz/signoz-otel-collector:v0.129.6 - 1 critical (CVE-2025-4802), 11 high (glibc, gnutls, xz).
- signoz/zookeeper:3.9.3 - 3 critical (glibc, PAM) and 16 high (OpenLDAP, PAM modules).
- signoz/signoz:v0.96.1 - 2 high (busybox, openssl).
- clickhouse/clickhouse-server:25.5.6 - no high/critical vulnerabilities detected.
- Remediation plan recorded in `docs/SECURITY_VULNERABILITY_REMEDIATION_PLAN.md`; security test remains red until upstream images refresh.

---

## Next Actions
1. Raise SigNoz support ticket referencing CVE list and desired patch versions.
2. Add Trivy scan step to BossCat nightly automation (`scripts/nightly-dashboard-export.ps1`).
3. Re-run end-to-end pipeline test after image updates to confirm sustained success rate >= 90%.
4. Update `docs/status/tests.json` and security plan once patched images land or compensating controls deployed.
