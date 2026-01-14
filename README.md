# 🐾 Resonai [OTel] — OpenTelemetry Observability Pack

[![ECRR](https://img.shields.io/badge/ECRR-Examine→Clean→Report→Role-7c5cff?style=for-the-badge&logo=gitbook&logoColor=white)](docs/bosscat/misc/AGENTS.md#-agents--ecrr-mantra)
[![BossCat Gate](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-gate-verify.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-gate-verify.yml)
[![CodeQL](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/codeql.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/codeql.yml)
[![Maintained by MoneyCat-inc](https://img.shields.io/badge/Maintained%20by-MoneyCat--inc-00aa88?style=for-the-badge&logo=github&logoColor=white)](https://github.com/MoneyCat-inc)

**OpenTelemetry observability pipeline** feeding Windows Event Logs and file logs directly into **SigNoz** for real-time monitoring. Optimized for low latency (200ms batches) with noise filtering (~50% volume reduction).

---

## 🚀 Quick Start

**Professional site rebuild (2025-10-07)** unified all navigation and documentation.

### 📚 **Start Here**
👉 **[Documentation Hub](docs/index.html)** — Your main entry point  
👉 **[Canonical References Map](docs/status/REFERENCES_MAP.md)** — Single source of truth for all working parts

### 🎛️ **Live Dashboards**
- **[Status Dashboard](docs/status.html)** — Real-time metrics and system health

### 📊 **Key Resources**
- **[Gate Archive (2025-10)](docs/gate/2025-10/)** — October 2025 gate verification evidence
- **[Security Master Guide](docs/BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md)** — Security and maintenance procedures

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
- **OTLP Endpoints:** 5317 (gRPC), 5318 (HTTP)

---

## 💚 Support This Project

[![Patreon](https://img.shields.io/badge/Support-Patreon-FF424D?style=for-the-badge&logo=patreon&logoColor=white)](https://www.patreon.com/c/FaeMcLachlan)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/fubumaki)

Help fund development of BossCat automation lanes, deeper SigNoz playbooks, and the anti-clickbait transparency hub. Every contribution supports evidence-first observability infrastructure.

**Sponsorship Tiers:**
- **🐱 Comfort Cat** ($5/mo) — Early access to new features
- **🦁 BossCat Tier** ($15/mo) — Priority support + quarterly roadmap input
- **🐯 Executive Tier** ($50/mo) — All benefits + monthly 1:1 consultation

---

## 📖 Documentation

All documentation is centralized in the **[Documentation Hub](docs/index.html)** with the **[Canonical References Map](docs/status/REFERENCES_MAP.md)** serving as the single source of truth.

### Key Documentation Sections
- **Gate & Readiness** — Production verification procedures
- **Persona & Governance** — Merge discipline and ECRR methodology  
- **Stakeholder Evidence** — Executive packages and audit trails
- **Security & Maintenance** — Security procedures and risk waivers
- **Dashboards & Data Room** — Live observability interfaces
- **Bots & Lanes** — AUTO-BOTS registry and lane enforcement
- **Rebuild History** — Professional site rebuild documentation

---

## 🔐 Security

- **Security scanning:** CodeQL, Gitleaks, Dependabot
- **Master guide:** [Security & Maintenance](docs/BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md)
- **Error ledger:** [IONA_ERRORS.md](docs/IONA_ERRORS.md)

---

## 🤝 Contributing

We follow strict **BossCat governance** with immutable merge rules:

- **Budget enforcement:** ≤10 files, ≤200 LOC per merge
- **ECRR methodology:** All changes follow Examine → Clean → Report → Role
- **Gate verification:** Must pass before merge
- **Kill-switch:** Active for drift control

See: [ECRR Manual](docs/bosscat/misc/ART_OF_ECRR.md) | [Agents & Hierarchy](docs/bosscat/misc/AGENTS.md)

---

## 📊 Project Status

**System Health:** ✅ 96/100 (Excellent)  
**Gate Pass Rate:** 96% (78/81 ready)  
**ECRR Reports:** 195+ comprehensive reports  
**Active Development:** 11+ consecutive days

See [Status Dashboard](docs/status.html) for detailed metrics.

---

## 🎯 Quick Commands

```powershell
# Health check
pwsh BRAV\SCPT\quick-monitor.ps1

# Detailed monitoring
pwsh scripts/monitor-optimized-pipeline.ps1 -DurationMinutes 10

# Generate canary test
pwsh scripts/canary-test.ps1

# Verify pipeline
pwsh scripts/verify-pipeline.ps1
```

---

## 📚 Additional Resources

- **[Cheat Sheets](docs/cheatsheets/README.md)** — Quick reference guides
- **[ECRR Reports](docs/ecrr/ECRR_REPORTS/)** — Complete audit trail
- **[Observability Snapshots](docs/observability/snapshots/)** — Dashboard exports

---

## 📞 Contact & Links

- **GitHub:** [MoneyCat-inc/otel-ops-pack](https://github.com/MoneyCat-inc/otel-ops-pack)
- **Bluesky:** [@resonai.bsky.social](https://bsky.app/profile/resonai.bsky.social)
- **Documentation Hub:** [docs/index.html](docs/index.html)
- **Status Dashboard:** [docs/status.html](docs/status.html)

---

## 🐾 Governance & Credits

**Maintained by:** MoneyCat-inc  
**Authority:** BossCat OEM (Executive Overseer Manager)  
**Methodology:** ECRR (Examine → Clean → Report → Role)  
**Creative Guide:** See Documentation Hub for creative references

**Professional Site Rebuild:** October 7, 2025  
Unified navigation, docs hub, and observability interfaces.

---

**🎯 Start with the [Documentation Hub](docs/index.html) for complete navigation.**
