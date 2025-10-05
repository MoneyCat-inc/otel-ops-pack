# OTel-Ops-Pack / Resonai

🚀 **Note on Ownership & Structure**  
This repository is now owned and maintained by the **MoneyCat-inc** organization.  
The **Resonai** local-first voice training application is developed **inside this repo** as part of the `otel-ops-pack` stack.  

All documentation, agents, CI/CD guardrails, and artifacts (ECRR reports, SSOTs, handoff docs) live here under the MoneyCat umbrella.

---

# OTel Windows -> SigNoz Observability Kit

> Creative source of truth: **C:\otel\docs\comfort cat** — start with `README.md` in that folder.

[![Comfort Cat](https://img.shields.io/badge/comfort--cat-guidelines-blueviolet)](#)
[![Accessibility AA](https://img.shields.io/badge/accessibility-AA-00aa88)](#)

[![ECRR](https://img.shields.io/badge/ECRR-Examine→Clean→Report→Role-7c5cff?style=for-the-badge&logo=gitbook&logoColor=white)](./AGENTS.md#-agents--ecrr-mantra)
[![ECRR Project Report](https://img.shields.io/badge/ECRR%20Project%20Report-available-7c5cff?style=for-the-badge)](docs/ECRR_PROJECT_REPORT.md)
[![SigNoz Automation](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/signoz-automation.yml/badge.svg)](../../actions/workflows/signoz-automation.yml)
[![CodeQL](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/codeql.yml/badge.svg)](../../actions/workflows/codeql.yml)
[![Gitleaks](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/gitleaks.yml/badge.svg)](../../actions/workflows/gitleaks.yml)
[![Maintained by MoneyCat-inc](https://img.shields.io/badge/Maintained%20by-MoneyCat--inc-00aa88?style=for-the-badge&logo=github&logoColor=white)](https://github.com/MoneyCat-inc)

A complete Windows-to-SigNoz observability pipeline with automated monitoring, alerting, and agent workflows for repeatable operations.

## Documentation
See the [Runbook Index](docs/RUNBOOK_INDEX.md) for all operational and handoff docs.

📊 For a high-level project status, see the [ECRR Report](docs/reports/ECRR_REPORT.md) covering Executive summary, Contributions, Risks, and Readiness.
?? Resonai program summary: see the [ECRR Project Report](docs/ECRR_PROJECT_REPORT.md) for cross-team context.

[![ECRR Status](https://img.shields.io/badge/ECRR-Cohort--Ready-green?style=flat-square)](docs/reports/ECRR_REPORT.md)

SigNoz UI reference: see [docs/observability/SIGNOZ_UI_MAP.md](docs/observability/SIGNOZ_UI_MAP.md) for routes, page anatomy, and local API behavior.

## Operational Runbook
Start with [docs/observability/SIGNOZ_RUNBOOK_BUNDLE.md](docs/observability/SIGNOZ_RUNBOOK_BUNDLE.md) for timestamped end-to-end verification. The latest pass (2025-09-20T21:14+01:00) recorded canary `5806cb5d-00b5-4415-8373-87a3f94b9a6d` and includes repeatable health/verification steps.

## Tetragrammaton Cross-Language Benchmarks
Advanced cross-language capability validation with Tetragrammaton YHWH (Yod-He-Vav-He) architecture:

- **`-hehe` Integration**: Dual HE (Interface + Integration) elements for comprehensive testing
- **Cross-Language Validation**: NodeJS Tetragrammaton + Python logfilter benchmarks
- **BossCat Compliance**: ECRR framework with automated evidence collection
- **Nightly CI**: Automated execution with governance visibility

See [docs/TETRAGRAMMATON_HEHE_INTEGRATION_COMPLETE.md](docs/TETRAGRAMMATON_HEHE_INTEGRATION_COMPLETE.md) for full documentation.

## ECRR or it did not happen
Examine -> Clean -> Report -> Role on every change. Evidence belongs in the PR body, artifacts in `docs/ECRR_REPORTS`, and verification steps in the description.

**🚀 Phase-4 Complete**: Reference implementation for autonomous observability at fleet scale is now ready for community launch!

**📊 Automated ECRR Compliance**: Continuous monitoring with GitHub Actions, webhook notifications, and scheduled compliance checking.

Run `pwsh -File scripts/ecrr-doctor.ps1` before making changes to capture the current environment.

> **Cross-Project ECRR Framework**: See [ECRR_FRAMEWORK_README.md](ECRR_FRAMEWORK_README.md) for ECRR implementation across both observability and Resonai projects.

### How to use ECRR cadence
1. **Examine**: `pwsh -File scripts/ecrr-doctor.ps1` (captures environment state)
2. **Clean**: Address any warnings, restart services if needed
3. **Report**: Use template in `docs/ECRR_REPORT_TEMPLATE.md`, save to `docs/ECRR_REPORTS/`
4. **Role**: Declare your role (Observability Copilot/OTel Steward/etc.)

### Automated Compliance Monitoring
- **GitHub Actions**: Automated compliance checking on PRs and daily schedules
- **Webhook Notifications**: Slack/Teams/Discord integration for compliance alerts
- **Scheduled Monitoring**: Daily compliance validation with configurable thresholds
- **Team Training**: Comprehensive guide in `docs/ECRR_AUTOMATED_MONITORING_TRAINING_GUIDE.md`

> See sample reports: `docs/ECRR_REPORTS/2025-09-28-*.md` for latest Phase-4 and compliance monitoring reports

## Phase-4 Reference Implementation Features

### 🚀 **Fleet Orchestration**
- Multi-repository autonomous management with `scripts/agent/status-fleet.ps1/.sh`
- Composite JSON schema `codex-local.fleet.v1` with repository metrics
- Cross-platform support: Windows PowerShell + Linux Bash

### 🔒 **Policy-Driven Governance**
- OPA/Rego policy bundles with cosign signing
- Versioned policy management with `policies/pinned.json`
- Automated bundle building, signing, and verification

### 📋 **Supply Chain Integrity**
- CycloneDX SBOM generation and attestation
- Cosign-based signing and verification
- Release documentation with verification procedures

### 🐳 **Cross-Platform Excellence**
- Docker containerization with `docker/Dockerfile.watchdog`
- Complete Helm chart deployment
- Windows service + Linux container hybrid architecture

### 🤖 **Autonomous Operations**
- Auto-PR mode with GitHub CLI integration
- Self-patching and self-governing systems
- Automated branch management and PR creation

### 🌐 **Community Readiness**
- Upstream contribution package ready
- CNCF Slack engagement strategy
- GitHub Discussion templates and launch checklist

## Quick start

### Creative Guidelines (Comfort Cat)
All visual, copy, and interaction decisions follow the Comfort Cat guidelines:
```powershell
# Set up creative guidelines
npm run comfort:scaffold

# Verify guidelines are present
npm run comfort:check

# Sync guidelines to Windows path
npm run comfort:sync
```

### Agent system and conflict resolution
GitHub Actions and local agents automate routine work. Dispatch workflows or apply the `needs-conflict-help` label to trigger the Codex conflict resolution routine.

### Prerequisites
- Windows 11 with PowerShell 5.1 or newer
- Docker Desktop with WSL2 integration enabled
- Administrator rights for installing the collector service

### Setup
1. Start SigNoz:
   ```powershell
   docker compose -f .\docker-compose.yml up -d
   ```
2. Install the Windows OTel Collector (from an elevated prompt):
   ```powershell
   .\scripts\setup.ps1
   ```
3. Verify the pipeline (match the runbook's expected output):
   ```powershell
   .\scripts\verify-integration.ps1
   ```
   See the runbook reference above for the latest artifacts and troubleshooting notes.

## Monitoring

### Automated verification
- Scheduled task runs every 15 minutes.
- Canary logs remain visible in SigNoz.
- Alerts fire when canaries disappear.

### Manual verification
Refer to the runbook's verification record for the exact SigNoz filters and expected canary entry.
```powershell
# Check system status
.\scripts\verify-integration.ps1

# View canary logs in SigNoz Logs with filter: message contains "windows-canary"

# Inspect scheduled task
Get-ScheduledTask -TaskName "OTel-Verification-Canary"
```

## API token setup (optional)

1. Open http://localhost:8080.
2. Settings -> Personal Access Tokens -> Generate token.
3. Store the token as `SIGNOZ_API_TOKEN` locally or in CI.

Example local usage:
```powershell
$env:SIGNOZ_API_TOKEN = "your-token-here"
pwsh -File .\scripts\verify-integration.ps1
```

## Service management
```powershell
# Start everything
.\scripts\start-all.ps1

# Stop everything
.\scripts\stop-all.ps1

# Restart the Windows collector
.\scripts\restart-collector.ps1
```

## Fallback monitoring
If scheduled tasks fail, run the fallback loop:
```powershell
.\monitor-loop.bat
```

## Repository layout
```
C:\otel\
|-- config\
|   |-- otelcol-windows.yaml     # Windows collector config
|   \-- signoz-collector.yaml    # SigNoz collector config
|-- scripts\
|   |-- setup.ps1                # Main setup script
|   |-- verify-integration.ps1   # Health verification
|   |-- start-all.ps1            # Start services
|   |-- stop-all.ps1             # Stop services
|   \-- schedule-monitoring.ps1  # Create scheduled task
|-- docker-compose.yml           # SigNoz stack
|-- monitor-loop.bat             # Fallback monitoring
\-- README.md                    # This file
```

## Contributing

Before pushing, run the local hygiene gates:

```bash
npm run hygiene
```

Install the optional fast hook with [Lefthook](https://github.com/evilmartians/lefthook) to run `tools/hygiene-fast.ps1` before commits.

PRs must pass the checks listed in [`docs/REPO_HYGIENE.md`](docs/REPO_HYGIENE.md).

## Success criteria

- Windows collector running (ports 5317 and 5318).
- SigNoz compose healthy (ports 14317, 14318, 8080, 8123, 9000).
- Canary logs appear in SigNoz within 30 seconds.
- Scheduled verification executes every 15 minutes.
- Alerts configured for missing canaries.

## Troubleshooting

Common issues:
1. Port conflicts: confirm ports 4317/4318/14317/14318/8080 are free.
2. Collector service stopped: run `.\scripts\restart-collector.ps1`.
3. SigNoz UI unreachable: verify docker compose status.
4. Scheduled task missing: check Task Scheduler for `OTel-Verification-Canary`.

Manual checks:
```powershell
# Docker containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Windows service
Get-Service -Name "otelcol-contrib"

# SigNoz health endpoint
Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -UseBasicParsing
```

## 🟣 Beta Launch

### **C8: Beta Launch Checklist**
The Resonai beta cohort is ready for launch with comprehensive preflight validation, onboarding, and rollback procedures.

**Key Documents:**
- [Beta Launch Checklist](docs/BETA_LAUNCH_CHECKLIST.md) - Complete preflight validation and launch procedures
- [Tester Onboarding Guide](docs/cohort-onboarding.md) - Beta tester setup and privacy FAQ
- [Rollback Procedures](docs/rollback-procedures.md) - Emergency rollback playbook
- [C8 Beta Launch Release Notes](docs/release-notes/c8-beta-launch.md) - Release documentation

**Cohort Features (C1-C4):**
- **C1 Progress Dashboard**: Local-first trends with sparklines
- **C2 Export & Delete UX**: Complete data sovereignty
- **C3 QA Release Runbook**: Deterministic pre-release gate
- **C4 Cohort Analytics Toggles**: Controlled rollout, defaults OFF

**Operations Tooling (C5-C8):**
- **C5 Cohort Log & Tester Guide**: Local JSON logging with tester documentation
- **C6 Beta Success Metrics**: Retention tracking and health metrics
- **C7 Dashboard Polish & UX**: Orb v2 shimmer overlay with friendly summaries
- **C8 Beta Launch Checklist**: Preflight validation and rollback procedures

**Quality Gates:**
- ✅ **Privacy-First**: No uploads, local-only data processing
- ✅ **WCAG AA Accessible**: Screen readers, keyboard navigation, reduced motion
- ✅ **Deterministic Testing**: Fixtures, tagged tests, one-command QA
- ✅ **Security-Hardened**: COOP/COEP, CSP, offline isolation

**Status**: Ready for 20-50 user beta cohort with complete operational excellence.

## Next steps

1. Configure SigNoz alerts for missing canaries and high error rate.
2. Schedule monitoring via `.\scripts\schedule-monitoring.ps1` (run as admin).
3. Confirm canary logs continue to land in SigNoz at the expected cadence.
4. **Beta Launch**: Execute C8 Beta Launch Checklist for cohort rollout.

## Status

The OTel Windows -> SigNoz observability pipeline is production ready when ECRR reports stay green and the canary proves ingestion end to end.







 
 =�<�  C I   P i p e l i n e   T e s t   -   H a r d e n e d   a u t o m a t i o n   r e a d y   t o   p u r r ! 
 
 
 
 >���  E n h a n c e d   C I   T e s t   -   C o l l e c t o r   l o g s   a r t i f a c t   +   q u e u e   m a n a g e m e n t   r e a d y ! 
 
 # CI trigger 09/21/2025 06:48:23
# Trigger CI 09/21/2025 07:00:09
# Background CI monitoring 09/21/2025 07:02:22
# Concurrency test 09/21/2025 07:05:22
