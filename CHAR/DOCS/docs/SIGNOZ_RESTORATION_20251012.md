<!-- markdownlint-disable MD013 MD022 MD031 MD032 MD034 MD040 -->
# SigNoz Stack Restoration — 2025-10-12

> **Dated record (2025-10-12) — 2026-09-02 truth pass.** Point-in-time stack restoration log; ports, versions and
> paths are as of that date (14317/14318 exporter scheme, SigNoz UI 3301, v0.96-era stack) and the
> `cursor{implementer}`/IONA roster is retired. Current truth: `docs/architecture/CURRENT_ARCHITECTURE.md`.

**Date:** 2025-10-12 01:15:00 +01:00  
**Operator:** Human (reported to cursor{implementer})  
**Status:** ✅ **UI Operational** (collector degraded)

---

## 🔍 **Changes Made**

### Docker Compose Configuration
**File:** `docker-compose-signoz-simple.yml`

**Changes:**
1. ✅ Recreated SigNoz with host port mapping 8080:8080
2. ✅ Set ClickHouse credentials: `CLICKHOUSE_PASSWORD: "signoz"`
3. ✅ Updated DSN with credentials for migrator and SigNoz
4. ✅ Added Zookeeper configuration for ClickHouse cluster

### ClickHouse Cluster Config
**File:** `clickhouse-cluster-config.xml`

**Changes:**
1. ✅ Updated remote host to `clickhouse`
2. ✅ Added `<zookeeper>` node for `signoz-zookeeper-simple:2181`

---

## ✅ **Verification Results**

### SigNoz UI (Primary Service)
```bash
$ curl http://127.0.0.1:8080/api/v1/health
{"status":"ok"}

$ curl http://127.0.0.1:8080/api/v1/version
{"version":"v0.96.1","ee":"Y","setupCompleted":true}
```

**Status:** ✅ **HEALTHY**

### Container Health
```
NAMES                          STATUS                           PORTS
signoz-simple                  Up 23 minutes (healthy)          0.0.0.0:8080->8080/tcp
signoz-clickhouse-simple       Up 27 minutes (healthy)          0.0.0.0:8123->8123/tcp, 9000/tcp
signoz-zookeeper-simple        Up 30 minutes (healthy)          0.0.0.0:2181->2181/tcp
signoz-otel-collector-simple   Restarting (1) <1 second ago     
```

**Critical Services:** ✅ **HEALTHY**  
**Collector:** ⚠️ **DEGRADED** (see Known Issues)

---

## ⚠️ **Known Issues**

### OTel Collector Restart Loop
**Container:** `signoz-otel-collector-simple`  
**Status:** Restarting continuously  
**Error:** `dial tcp: lookup signoz-clickhouse on 127.0.0.11:53: no such host`

**Root Cause:** Hostname mismatch in collector configuration
- Expected: `signoz-clickhouse-simple` (actual container name)
- Configured: `signoz-clickhouse` (incorrect)

**Impact:**
- ❌ Telemetry ingestion degraded (logs, traces, metrics)
- ✅ SigNoz UI operational (query engine, dashboards)
- ✅ Gate verification not blocked (UI health sufficient)

**Resolution Path:**
1. Update OTel collector config to use `signoz-clickhouse-simple`
2. OR update service name in docker-compose to `signoz-clickhouse`
3. Restart collector after config fix

**Priority:** P2 (non-blocking for gate, operational improvement)

---

## 📊 **Service Matrix**

| Service | Container Name | Status | Ports | Health |
|---------|----------------|--------|-------|--------|
| SigNoz UI | signoz-simple | ✅ Up 23m | 8080 | ✅ Healthy |
| ClickHouse | signoz-clickhouse-simple | ✅ Up 27m | 8123, 9000 | ✅ Healthy |
| Zookeeper | signoz-zookeeper-simple | ✅ Up 30m | 2181 | ✅ Healthy |
| OTel Collector | signoz-otel-collector-simple | ⚠️ Restarting | - | ❌ Degraded |

**Overall Status:** ✅ **OPERATIONAL** (3/4 healthy, collector non-critical for gate)

---

## 🚀 **Quick Start Commands**

### Start/Refresh Stack
```bash
docker compose -f docker-compose-signoz-simple.yml up -d
```

### Check Health
```bash
# SigNoz UI
curl http://127.0.0.1:8080/api/v1/health

# Container status
docker ps --filter "name=signoz"
```

### View Logs
```bash
# SigNoz UI
docker logs signoz-simple

# ClickHouse
docker logs signoz-clickhouse-simple

# OTel Collector (debug restart issue)
docker logs signoz-otel-collector-simple

# Zookeeper
docker logs signoz-zookeeper-simple
```

---

## 🔧 **Configuration Details**

### ClickHouse Credentials (Local Only)
```
Username: default
Password: signoz
```

**⚠️ Security Note:** These credentials are for local development only. Production deployments should use secure credentials and proper secret management.

### Port Mappings
```
SigNoz UI:     8080  → 8080  (HTTP)
ClickHouse:    8123  → 8123  (HTTP API)
ClickHouse:    9000  → 9000  (Native Protocol)
Zookeeper:     2181  → 2181  (Client)
```

### Network Mode
- Using Docker Compose default bridge network
- Service discovery via container names
- Hostname resolution: `signoz-{service}-simple`

---

## 📈 **Gate #007 Impact**

### Gate Readiness Assessment
**Impact:** ✅ **NO IMPACT ON GATE READINESS**

**Justification:**
1. ✅ SigNoz UI healthy and responding (primary requirement)
2. ✅ ClickHouse operational (data storage layer)
3. ✅ Health endpoint returns 200 OK
4. ⚠️ OTel collector degraded (telemetry ingestion, non-critical for gate)

**Gate Status:** ✅ **REMAINS READY** (unchanged from certification)

### GATE-CORE Verification
```
Component            Status   Evidence
─────────────────────────────────────────────────
SigNoz Health        ✅       HTTP 200 OK
SigNoz Version       ✅       v0.96.1 (EE)
ClickHouse           ✅       Container healthy
Zookeeper            ✅       Container healthy
OTel Collector       ⚠️       Restarting (non-critical)
```

**GATE-CORE Status:** ✅ **PASS** (core services operational)

---

## 🐾 **BossCat Assessment**

### Operational Status
**Verdict:** ✅ **SUFFICIENT FOR GATE #007**

**Critical Services:** 3/3 healthy ✅
- SigNoz UI (query, dashboards)
- ClickHouse (data storage)
- Zookeeper (coordination)

**Non-Critical Services:** 0/1 healthy ⚠️
- OTel Collector (telemetry ingestion)

### Recommendation
**Gate #007:** ✅ **PROCEED** (no change to readiness certification)  
**Collector Fix:** 📋 **P2** (operational improvement, post-gate)

### Post-Gate Actions
1. 📋 Fix OTel collector hostname configuration
2. 📋 Verify telemetry pipeline end-to-end
3. 📋 Run canary test with telemetry ingestion
4. 📋 Document collector configuration in ops guide

---

## 🎯 **Success Criteria**

### Achieved ✅
- [x] SigNoz UI accessible at http://localhost:8080
- [x] Health endpoint returns 200 OK
- [x] ClickHouse storage layer operational
- [x] Zookeeper coordination operational
- [x] Version endpoint confirms v0.96.1 (EE)
- [x] Setup completed (setupCompleted: true)

### Pending (Non-Blocking) ⚠️
- [ ] OTel collector stable and ingesting telemetry
- [ ] Full telemetry pipeline validated (logs, traces, metrics)
- [ ] Canary test with end-to-end verification

---

## 📞 **Handoff**

**Restored By:** Human operator  
**Verified By:** cursor{implementer} with BossCat authority  
**Gate Impact:** ✅ None (readiness unchanged)  
**Next Steps:** Collector hostname fix (P2, post-gate)

---

**Authority:** cursor{implementer}  
**Timestamp:** 2025-10-12 01:15:00 +01:00  
**Status:** ✅ **SigNoz UI Operational, Gate Ready**

🐾 _SigNoz restored. Core services healthy. Gate #007 readiness unchanged._

