# ECRR — Security Risk Waivers (OTEL-001 / OTEL-002)

**Date:** 2026-08-29  
**Actor:** Cursor{Implementer} + machine operator `@fubumaki`  
**Verdict:** **GREEN** — waivers documented, PR #645 merged to `main`

## 1. Examine

Full health check (2026-08-29) reported two non-blocking warnings:

- `WARNING: Insecure TLS detected - ensure it's only for local connections` (`health-check.ps1 -Mode full` via `config-schema.ps1`)
- `Kafka: SKIPPED (not configured)` (expected; no Kafka exporter in active config)

No formal risk acceptance existed in `docs/BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md`.

## 2. Clean

- Added **Accepted Risk Waivers** section with WAIVER-OTEL-001 (loopback OTLP TLS) and WAIVER-OTEL-002 (Kafka N/A)
- Bumped Security Master Guide revision to v1.1
- Repaired broken Quick Links target (`SECURITY_REMEDIATION.md` → `DEPENDABOT_SECURITY_GUIDE.md`)
- Fixed SigNoz docs URL (404 → `https://signoz.io/docs/instrumentation/`)
- Satisfied docs-lane markdownlint for the touched file

**PR:** https://github.com/MoneyCat-inc/otel-ops-pack/pull/645  
**Merge commit:** `b2f2a79cf` on `main`

## 3. Report

| Waiver | Scope | Re-evaluation trigger |
| --- | --- | --- |
| WAIVER-OTEL-001 | `tls.insecure: true` on `localhost:4317` OTLP export | Remote endpoint, non-loopback bind, production scope |
| WAIVER-OTEL-002 | Kafka exporter absent | Kafka block added to collector config |

Evidence: `docs/BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md` (Accepted Risk Waivers, v1.1)

## 4. Role

Cursor{Implementer} drafted waivers and opened PR; machine operator approved merge path. No credentials touched.

**Status:** COMPLETE
