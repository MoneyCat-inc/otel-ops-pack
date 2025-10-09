# Add Windows Day-2 Ops Kit (codex-local) Reference Implementation

## 🚀 Overview

This PR adds a **Windows Day-2 Ops Kit** as a reference implementation in the OpenTelemetry Collector examples directory. The kit demonstrates how to build **autonomous observability systems** with policy-driven governance and fleet management capabilities.

## 🛡️ What This Provides

### **Fleet Orchestration**
- Multi-repository health aggregation with composite JSON schemas
- Cross-platform support (Windows PowerShell + Linux Bash)
- Fleet-wide status monitoring and reporting

### **Policy as Code**
- OPA/Rego policy bundles with cosign signing
- CI/CD enforcement of guardrails (CSP, accessibility, security)
- Versioned policy management with verification

### **Supply Chain Integrity**
- CycloneDX SBOM generation and attestation
- Cosign-based signing and verification
- Release provenance and verification procedures

### **Cross-Platform Deployment**
- Windows service mode via NSSM integration
- Linux container deployment with Helm charts
- Hybrid architecture for enterprise environments

### **Autonomous Operations**
- Self-governing via policy enforcement
- Self-patching via automated PR creation
- Self-telemetry via OpenTelemetry instrumentation
- Self-recovering via service management

## 🎯 Why This Matters

OpenTelemetry provides excellent cross-platform instrumentation and pipeline support. What's missing is **day-2 operational guardrails**, especially on Windows. This kit demonstrates how to:

- Harden OTel Collector deployments with automated guardrails
- Embed policy-driven governance into development workflows
- Close the operational loop with self-telemetry and fleet-wide dashboards

## 📦 Components Added

### **Core Scripts**
- `scripts/status-fleet.ps1` - Windows PowerShell fleet aggregation
- `scripts/status-fleet.sh` - Linux Bash fleet aggregation
- `scripts/policy/` - Policy bundle management scripts
- `scripts/supplychain/` - SBOM generation and signing

### **Policy Framework**
- `policies/codex.rego` - OPA/Rego policy definitions
- Policy bundle building, signing, and verification
- CI/CD integration for policy enforcement

### **Deployment Artifacts**
- `docker/Dockerfile.watchdog` - Linux container image
- `helm/codex-local/` - Complete Helm chart
- Windows service integration examples

### **Documentation**
- Comprehensive README with quick start guide
- Configuration examples and best practices
- Grafana dashboard integration
- Community contribution guidelines

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

## 📊 Monitoring Integration

### Grafana Dashboard
The kit includes a Grafana dashboard (`docs/grafana/codex-local-dashboard.json`) that visualizes:
- Fleet health metrics across repositories
- Policy compliance status
- Guardrail violations and trends
- System performance metrics

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

## 🤝 Community Impact

This reference implementation:
- Establishes Windows as a first-class citizen in the OpenTelemetry ecosystem
- Provides operational governance layer for production deployments
- Demonstrates autonomous observability patterns at fleet scale
- Enables policy-driven development workflows

## 📄 License

Apache 2.0 - Consistent with OpenTelemetry project licensing

## 🔗 References

- **Source Repository**: https://github.com/resonai/codex-local
- **Documentation**: https://github.com/resonai/codex-local/blob/main/docs/
- **Grafana Dashboard**: https://github.com/resonai/codex-local/blob/main/docs/grafana/
- **Policy Bundles**: https://github.com/resonai/codex-local/blob/main/policies/

---

**This PR establishes a gold standard for Windows Day-2 Operations in the OpenTelemetry ecosystem, providing the operational governance layer that production deployments require.**
