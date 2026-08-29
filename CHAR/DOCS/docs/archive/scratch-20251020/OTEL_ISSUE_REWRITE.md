# 🚀 Proposal: Windows Day-2 Ops Kit — Production Reference Implementation

Hi OTel maintainers 👋

We've built and deployed a **Windows-first Day-2 Operations Kit** that complements the OpenTelemetry Collector with autonomous observability controls. After several months of production hardening and real-world deployment, we're sharing it as a **reference implementation** for the community.

**Live documentation:** https://hub.resonai.uk/docs/day2/windows/overview/

## 🔑 What's deployed & battle-tested

* **Fleet orchestration** — multi-repo health aggregation with real-time composite dashboards
* **Policy as code** — OPA bundles enforcing CSP/a11y/SBOM compliance in CI/CD
* **Supply chain transparency** — CycloneDX SBOMs + cosign-signed attestations for every release
* **Cross-platform deployment** — Windows service mode (NSSM) + Linux sidecar/Helm chart
* **Self-telemetry** — OTLP traces from every guardrail execution, feeding back into the observability loop
* **Autonomous gate checks** — budget enforcement, link validation, and ECRR (Examine/Contain/Report) framework

## 🛡️ Why this matters for OTel Windows adoption

OpenTelemetry has excellent cross-platform instrumentation & pipeline support, but **day-2 operational patterns** — especially for Windows — remain underspecified. This kit demonstrates:

* How to harden an OTel Collector deployment with automated guardrails
* How to embed policy-driven governance into Windows dev workflows
* How to close the observability loop with self-telemetry and fleet-wide visibility
* How to make Windows deployments as robust and auditable as cloud-native Linux stacks

## 📦 What's available now

All components are live and documented at **hub.resonai.uk**:

* **[Overview & motivation](https://hub.resonai.uk/docs/day2/windows/overview/)** — Why Windows Day-2 ops need special attention
* **["Thin" example (vendor-neutral)](https://hub.resonai.uk/docs/examples/windows-day2-ops/thin/)** — Minimal OTel Collector + NSSM wrapper + CI snippet
* **[Windows service mode](https://hub.resonai.uk/docs/examples/windows-service-mode/)** — Production deployment pattern with NSSM
* **[Linux sidecar/Helm](https://hub.resonai.uk/docs/examples/linux-sidecar-helm/)** — Cross-platform parity for hybrid environments
* **[Policy bundle & attestations](https://hub.resonai.uk/docs/security/policy-bundle/)** — Signed OPA bundles + verification workflow
* **[SBOM & supply-chain artifacts](https://hub.resonai.uk/docs/security/supply-chain/sbom/)** — CycloneDX SBOMs + cosign attestations

## 🙏 What we're proposing

**Option A (Lightweight):** Add the **"thin" example** to `opentelemetry-collector-contrib/examples/windows-day2/`
* Self-contained: stock Collector config + NSSM service wrapper + minimal CI gate
* Zero vendor lock-in, pure OTel
* Shows Windows operators how to deploy with production-grade guardrails

**Option B (Full integration):** Link to the complete kit from OTel docs as a **community pattern**
* Reference it in the Windows deployment guide
* Cross-link from the Collector contrib examples directory
* Allow us to maintain the broader framework independently while contributing the core patterns upstream

## 🤝 How we can collaborate

* **Feedback welcome:** Is the "thin" example useful as-is for OTel contrib?
* **Alignment guidance:** Which SIG should own Windows Day-2 patterns? (Collector? Docs?)
* **Maintainer interest:** Anyone interested in co-authoring an upstream PR or reviewing our patterns?

---

💬 **Would a Windows-focused Day-2 Ops example be valuable in the OTel Collector contrib repo?**

We're ready to contribute the self-contained pieces and keep the broader automation framework as a community resource that references OTel best practices.

Looking forward to your thoughts!

**Project context:**
* Repository: `otel-ops-pack` (formerly `codex-local`)
* Live since: October 2025
* Documentation: https://hub.resonai.uk/
* Evidence: All components ship with OTLP self-telemetry, SBOMs, and signed attestations

