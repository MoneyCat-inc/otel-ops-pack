# 🔧 Gate Self-Signal Infrastructure Fix

**Date:** 2025-10-23 16:27  
**Issue:** ClickHouse HTTP port (8123) not accessible from Windows host  
**Resolution:** Query ClickHouse via `docker exec` instead of HTTP endpoint

---

## Problem Identified

**Monitoring Loop Output (Check #1):**

```text
[2025-10-23 16:25:12] ⚠️ ClickHouse query failed
[2025-10-23 16:25:12] Check: localhost:8123 availability
```

**Root Cause:**

- ClickHouse container ports (8123, 9000, 9009) are **exposed** but **not published** to host
- `docker ps` showed: `signoz-clickhouse  8123/tcp, 9000/tcp, 9009/tcp  Up 18 hours`
- HTTP requests from Windows host to `localhost:8123` were failing
- Monitoring loop was returning **exit code 2 (ERROR)**

---

## Solution Applied

**Changed:** `gate-self-signal-check.ps1`

### Before (Failed)

```powershell
# HTTP endpoint (port not mapped to host)
$url = "http://localhost:8123/?query=$([uri]::EscapeDataString($query))"
$response = Invoke-WebRequest -UseBasicParsing -Uri $url
```

### After (Working)

```powershell
# Docker exec (works from Windows host)
$result = docker exec signoz-clickhouse clickhouse-client --query $query 2>&1
$spanCount = [int]$result.Trim()
```

---

## Schema Corrections

Also fixed the ClickHouse query schema (previous query was invalid):

### Before (Failed)

```sql
SELECT count() FROM signoz_traces.distributed_signoz_spans
WHERE serviceName='canary-test'
```

→ Error: `Unknown expression or function identifier 'serviceName'`

### After (Working)

```sql
SELECT count() FROM signoz_traces.span_attributes
WHERE tagKey='service.name'
  AND stringTagValue='canary-test'
  AND timestamp >= now() - INTERVAL 10 MINUTE;
```

---

## Verification

**Test Run Result (2025-10-23 16:27:36):**

```yaml
🔔 GATE SELF-SIGNAL CHECK
✅ Step 1: Canary sent (HTTP 200)
⏳ Waiting 2 seconds
🔎 Querying ClickHouse via docker exec
Result: 0 spans found
Exit code: 1 (HOLD - platform gap persists)
```

**Status:** ✅ Self-signal check now operational (correctly returning exit code 1)

---

## Current State

| Item | Status | Details |
|------|--------|---------|
| **Canary sender** | ✅ Working | HTTP 200 sent successfully |
| **ClickHouse access** | ✅ Working | `docker exec` queries respond |
| **Schema** | ✅ Correct | span_attributes table confirmed |
| **Query logic** | ✅ Correct | Returns count for canary-test |
| **Exit codes** | ✅ Working | 0=GREEN, 1=HOLD, 2=ERROR |
| **Monitoring loop** | ✅ Ready | Will detect fix when exit 0 appears |
| **Traces present** | ❌ Not yet | count() = 0 (awaiting platform fix) |

---

## What's Next

**Monitoring Loop:**

- Continues polling every 30 minutes
- Uses corrected `gate-self-signal-check.ps1`
- Will detect traces the moment SigNoz platform fix lands
- Will break with **exit code 0** alert

**When Fix Lands (SigNoz team resolves exporter→ClickHouse gap):**

1. Next poll detects `count() > 0`
2. Monitoring loop breaks with alert
3. Execute gate advancement runbook (10 min)
4. Flip verdict: **🟠 WARN → 🟢 GREEN**

---

## Technical Details

**Why `docker exec` works:**

- PowerShell runs on Windows host
- Docker daemon is accessible locally
- `docker exec` command executes inside the container
- ClickHouse client (inside container) connects to localhost:9000 (internal Docker networking)
- Result streams back to host PowerShell

**ClickHouse Table Structure:**

- `signoz_traces.signoz_spans`: Main table (traceID, timestamp, model)
- `signoz_traces.span_attributes`: Attributes table (tagKey, stringTagValue, dataType, etc.)
- Query joins via timestamp and span linking
- `service.name` stored as a resource attribute in span_attributes

---

**🐾 Infrastructure fixed. Self-signal monitoring operational. Awaiting platform fix.**

When SigNoz team resolves exporter→ClickHouse gap, traces will appear → loop detects → gate advances → 🟢 GREEN
