# Windows Day-2 Ops Kit (codex-local)

A production-hardened autonomous agent that complements OpenTelemetry Collector with policy-driven guardrails and fleet management capabilities.

## 🚀 Key Features

- **Fleet Orchestration**: Multi-repository health aggregation with composite JSON schemas
- **Policy as Code**: OPA/Rego bundles with cosign signing and CI/CD enforcement
- **Supply Chain Integrity**: CycloneDX SBOM generation and attestation
- **Cross-Platform**: Windows service mode + Linux container deployment
- **Autonomous Operations**: Self-governing, self-patching, self-telemetry systems

## 🛡️ Why This Matters

OpenTelemetry provides excellent cross-platform instrumentation and pipeline support. What's missing is **day-2 operational guardrails**, especially on Windows. This kit demonstrates how to:

- Harden OTel Collector deployments with automated guardrails
- Embed policy-driven governance into development workflows
- Close the operational loop with self-telemetry and fleet-wide dashboards

## 📦 Components

### Fleet Management
- `status-fleet.ps1` - Windows PowerShell fleet aggregation
- `status-fleet.sh` - Linux Bash fleet aggregation
- Composite JSON schema `codex-local.fleet.v1`

### Policy Governance
- `policies/codex.rego` - OPA/Rego policy definitions
- `scripts/policy/build-bundle.ps1` - Policy bundle creation
- `scripts/policy/sign-bundle.ps1` - Cosign signing
- `scripts/policy/verify-bundle.ps1` - Bundle verification

### Supply Chain Security
- `scripts/supplychain/generate-sbom.ps1` - CycloneDX SBOM generation
- `scripts/supplychain/sign-sbom.ps1` - SBOM attestation
- `docs/RELEASE.md` - Release verification procedures

### Cross-Platform Deployment
- `docker/Dockerfile.watchdog` - Linux container image
- `helm/codex-local/` - Complete Helm chart
- Windows service integration via NSSM

### Autonomous Operations
- `scripts/agent/auto-pr.ps1` - Automated PR creation
- Guardrail enforcement (CSP, accessibility, security)
- Self-telemetry via OpenTelemetry
- Service management and recovery

## 🚀 Quick Start

### Windows Service Mode
```powershell
# Install as Windows service
pwsh -File scripts/setup-windows-service.ps1

# Start monitoring
pwsh -File scripts/agent/start-watchdog.ps1
```

### Linux Container Mode
```bash
# Build container
docker build -f docker/Dockerfile.watchdog -t codex-local:latest .

# Deploy with Helm
helm install codex-local ./helm/codex-local
```

### Fleet Management
```powershell
# Windows
pnpm agent:status-fleet-ps

# Linux
pnpm agent:status-fleet-sh
```

## 📊 Monitoring

### Grafana Dashboard
Import the dashboard from `docs/grafana/codex-local-dashboard.json` to visualize:
- Fleet health metrics
- Policy compliance status
- Guardrail violations
- System performance

### Key Metrics
- `codex.jobs_processed` - Total jobs processed
- `codex.guardrail_violations` - Policy violations count
- `watchdog.cycle.duration` p95 - Performance metrics

## 🔧 Configuration

### Policy Management
```powershell
# Build policy bundle
pnpm policy:build

# Sign with cosign
pnpm policy:sign

# Verify bundle
pnpm policy:verify
```

### SBOM Generation
```powershell
# Generate SBOM
pnpm sbom:gen

# Sign SBOM
pnpm sbom:sign
```

## 🤝 Community

This is a reference implementation for autonomous observability at fleet scale. We welcome:
- Community feedback and contributions
- Integration with other OpenTelemetry projects
- Best practices and use case sharing

## 📄 License

Apache 2.0 - See LICENSE file for details.

## 🔗 Links

- **Repository**: https://github.com/resonai/codex-local
- **Documentation**: https://github.com/resonai/codex-local/blob/main/docs/
- **Grafana Dashboard**: https://github.com/resonai/codex-local/blob/main/docs/grafana/
- **Policy Bundles**: https://github.com/resonai/codex-local/blob/main/policies/

---

**This kit establishes Windows as a first-class citizen in the OpenTelemetry ecosystem, providing the operational governance layer that production deployments require.**
