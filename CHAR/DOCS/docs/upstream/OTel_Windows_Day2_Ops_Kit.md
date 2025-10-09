# Windows Day-2 Ops Kit (codex-local)

This reference shows how to run a hardened, autonomous OpenTelemetry ops layer on Windows:
- Windows Service mode for a watchdog that enforces guardrails (CSP/a11y), budgets, and policy-as-code.
- OTLP-first telemetry, SigNoz/Grafana dashboards, and alerts on guardrail violations and cycle SLOs.
- Policy bundles (OPA) + CI verification.
- SBOM generation + signing for supply chain integrity.

## What's included
- Service scripts (NSSM) for running the watchdog.
- Guardrail methodology and example policy.
- CI examples (CodeQL, gitleaks, guardrails).
- Fleet aggregation for multi-repo health.

## How it aligns with OpenTelemetry
- Uses OTLP-first pipelines.
- Respects OTel semantic conventions in self-telemetry.
- Complements Collector examples with Day-2 operational guidance.
