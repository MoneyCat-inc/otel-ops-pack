<!-- markdownlint-disable MD013 MD022 MD032 MD034 -->
# 🐾 Resonai [OTel] — OpenTelemetry Observability Pack

[![ECRR](https://img.shields.io/badge/ECRR-Examine→Clean→Report→Role-7c5cff?style=for-the-badge&logo=gitbook&logoColor=white)](docs/BossCat/CHARTER.md)
[![BossCat Gate](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-gate-verify.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-gate-verify.yml)
[![CodeQL](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/codeql.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/codeql.yml)
[![Maintained by MoneyCat-inc](https://img.shields.io/badge/Maintained%20by-MoneyCat--inc-00aa88?style=for-the-badge&logo=github&logoColor=white)](https://github.com/MoneyCat-inc)

**OpenTelemetry observability pipeline** feeding Windows Event Logs and file logs into **SigNoz** for real-time monitoring. Optimized for low latency (200ms batches) with noise filtering (~50% volume reduction).

---

## 🚀 Quick Start

### 📚 Start Here
👉 **[Documentation Hub](docs/index.html)** — main entry point  
👉 **[Canonical References Map](docs/status/REFERENCES_MAP.md)** — single source of truth for working parts  
👉 **[Repository Index (AGENTS.md)](AGENTS.md)** — governance and agent entry point

### 🎛️ Live Dashboards
- **[Status Dashboard](docs/status.html)** — real-time metrics and system health
- **[Executive Status](docs/status/misc/STATUS.md)** — gate, SBOM, and pipeline summary

### 📊 Key Resources
- **[Gate Archive (2025-10)](docs/gate/2025-10/)** — October 2025 gate verification evidence
- **[Security Master Guide](docs/BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md)** — security and maintenance procedures
- **[Windows Collector Runbook](docs/runbooks/windows-collector.md)** — OTLP ports and service config

---

## 🐾 What is Resonai [OTel]?

A **small, evidence-first** Windows observability pack:

✅ **OpenTelemetry** auto-instrumentation for .NET  
✅ **SigNoz** backend (self-hosted, no vendor lock-in)  
✅ **BossCat governance** (audit trails by default)  
✅ **ECRR methodology** (Examine → Clean → Report → Role)

### Out-of-the-Box Support
- ASP.NET / ASP.NET Core
- HttpClient, SqlClient, Npgsql, Redis, gRPC
- Log correlation via ILogger
- Most traces work zero-code; metrics/logs vary by library

---

## 🛠️ System Requirements

- **Windows** (native support)
- **PowerShell 7+** (monitoring scripts)
- **Docker** (SigNoz stack)
- **SigNoz UI:** http://localhost:8080
- **OTLP ingest (Windows collector):** 5320 (gRPC), 5321 (HTTP) — avoids PlariumPlay’s 5300–5319 bind range
- **OTLP export (collector → SigNoz):** localhost:4317

See [windows/otelcol/README.md](windows/otelcol/README.md) for canonical service configuration.

---

## 💚 Support This Project

![Patreon](https://img.shields.io/badge/Support-Patreon-FF424D?style=for-the-badge&logo=patreon&logoColor=white)<!-- lychee-ignore -->
[![Ko-fi](https://img.shields.io/badge/Ko--fi-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/fubumaki)
[![Bluesky](https://img.shields.io/badge/Bluesky-0285FF?style=for-the-badge&logo=bluesky&logoColor=white)](https://bsky.app/profile/resonai.bsky.social)

Help fund BossCat automation lanes, SigNoz playbooks, and the [anti-clickbait transparency hub](https://hub.resonai.uk/).

**Bluesky Starter Pack** (one-click follow list): [AntiClickbait — Trusted Sources](https://bsky.app/starter-pack/resonai.bsky.social/3m3rct677yo2t)

---

## 📖 Documentation

All documentation is centralized in the **[Documentation Hub](docs/index.html)** with the **[Canonical References Map](docs/status/REFERENCES_MAP.md)** as the navigation index.

### Key Documentation Sections
- **Gate & Readiness** — production verification procedures
- **Persona & Governance** — [Charter](docs/BossCat/CHARTER.md), [Persona v1.1](docs/BossCat/IMMUTABLE_PERSONA_v1.1.md)
- **Stakeholder Evidence** — executive packages and audit trails
- **Security & Maintenance** — security procedures and risk waivers
- **Runbooks** — [Windows collector](docs/runbooks/windows-collector.md), [Docker recovery](docs/runbooks/misc/docker-fix-steps.md)
- **ECRR Reports** — [complete audit trail](CHAR/ECRR/ECRR_REPORTS/)

---

## 🔐 Security

- **Security scanning:** CodeQL, Gitleaks, Dependabot
- **SBOM:** blocking on prod gate (see [FOLLOWUP_SBOM_BLOCKING.md](docs/BossCat/FOLLOWUP_SBOM_BLOCKING.md))
- **Master guide:** [Security & Maintenance](docs/BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md)
- **Error ledger:** [IONA_ERRORS.md](docs/IONA_ERRORS.md)

---

## 🤝 Contributing

We follow **BossCat governance** with immutable merge rules:

- **Budget enforcement:** ≤10 files, ≤200 LOC per merge
- **ECRR methodology:** Examine → Clean → Report → Role
- **Gate verification:** must pass before merge
- **Kill-switch:** active for drift control

See: [AGENTS.md](AGENTS.md) | [ECRR Manual](docs/BossCat/misc/ART_OF_ECRR.md) | [Charter](docs/BossCat/CHARTER.md)

---

## 📊 Project Status

**Last updated:** June 2026 — see [Executive Status](docs/status/misc/STATUS.md) for current gate, SBOM, and pipeline health.

- **Main branch gates:** green (BossCat Gate Verify, CodeQL, Gitleaks)
- **Local pipeline:** Docker + SigNoz + Windows collector (`quick-monitor` health check)
- **ECRR reports:** 386 under `CHAR/ECRR/ECRR_REPORTS/`

Live metrics: [Status Dashboard](docs/status.html)

---

## 🎯 Quick Commands

```powershell
# Fast health check
pwsh -File scripts\quick-monitor.ps1

# Detailed monitoring
pwsh -File scripts\monitor-optimized-pipeline.ps1 -DurationMinutes 10

# Generate and verify OTLP canary signals
pwsh -File scripts\windows\test-otlp-e2e.ps1

# Verify pipeline readiness
pwsh -File scripts\preflight-health-check.ps1
```

---

## 📚 Additional Resources

- **[Cheat Sheets](docs/cheatsheets/README.md)** — quick reference guides
- **[ECRR Reports](CHAR/ECRR/ECRR_REPORTS/)** — complete audit trail
- **[Observability Snapshots](docs/observability/snapshots/)** — dashboard exports

---

## 📞 Contact & Links

- **GitHub:** [MoneyCat-inc/otel-ops-pack](https://github.com/MoneyCat-inc/otel-ops-pack)
- **Bluesky:** [@resonai.bsky.social](https://bsky.app/profile/resonai.bsky.social) · [Starter Pack](https://bsky.app/starter-pack/resonai.bsky.social/3m3rct677yo2t)
- **Hub:** [https://hub.resonai.uk](https://hub.resonai.uk/)
- **Ko-fi:** [ko-fi.com/fubumaki](https://ko-fi.com/fubumaki)
- **Documentation Hub:** [docs/index.html](docs/index.html)
- **Status Dashboard:** [docs/status.html](docs/status.html)

---

## 🐾 Governance & Credits

**Maintained by:** MoneyCat-inc  
**Authority:** BossCat OEM (Executive Overseer Manager)  
**Methodology:** ECRR (Examine → Clean → Report → Role)

**Site hub:** unified navigation via [docs/index.html](docs/index.html) (rebuilt October 2025, refreshed June 2026).

---

**🎯 Start with the [Documentation Hub](docs/index.html) for complete navigation.**

