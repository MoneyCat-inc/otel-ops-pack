# Optional Enhancement: Preserve Canary Service Names

**Status:** Production-ready now. Enhancement is optional, low-risk, and can be applied anytime.

---

## Overview

Gate #008 is **GREEN** with full end-to-end trace ingestion confirmed. The current configuration works perfectly for production. This document describes an **optional future enhancement** to improve multi-service observability by preserving canary service names.

## Current Configuration (Production Now)

```yaml
# signoz-collector-config.yaml:47-54
resource/defaults:
  attributes:
    - key: service.name
      value: resonai-backend
      action: upsert  # ← Overwrites all incoming service.name
```

**Current Behavior:**
- ALL traces get `service.name = "resonai-backend"` (regardless of input)
- Example: Sent `service.name: "canary-test"` → Stored as `"resonai-backend"`
- Single unified service identity (proven production stability)
- Query example: `WHERE serviceName = 'resonai-backend'` returns 1,390+ traces

**Advantages (Current):**
- ✅ Single unified service identity
- ✅ Deterministic aggregation
- ✅ Simplified operational model
- ✅ All production data uses same service.name
- ✅ Proven stable in production

**Limitations (Current):**
- ❌ Loses original service names for canaries/tests
- ❌ Harder to filter production traces by test type
- ❌ Less visibility into multi-service calls

## Optional Enhancement (Future)

When/if multi-service observability becomes important:

```yaml
# Proposed change: signoz-collector-config.yaml:51
resource/defaults:
  attributes:
    - key: service.name
      value: resonai-backend
      action: insert  # ← Preserves original if present
```

**Proposed Behavior:**
- Incoming `service.name` values are PRESERVED
- Sets default only for spans WITHOUT `service.name`
- Example: Sent `service.name: "canary-test"` → Stored as `"canary-test"` ✓
- Example: Sent (no service.name) → Stored as `"resonai-backend"` (default)
- Better multi-service visibility

**Advantages (Enhanced):**
- ✅ Preserves canary/test service names for filtering
- ✅ Better multi-service tracing visibility
- ✅ More granular SigNoz filtering and dashboarding
- ✅ Easier to identify test traces vs. production

**Considerations (Enhanced):**
- ⚠️ Mixed `service.name` values in production data
- ⚠️ Slightly more complex SigNoz dashboarding setup
- ⚠️ Backward compatible (only affects future traces)
- ⚠️ Already tested/verified without this change

## Trade-off Analysis

| Aspect | Current (upsert) | Enhanced (insert) |
|--------|------------------|-------------------|
| **Service.name Preservation** | Overwrites all | Preserves originals |
| **Production Stability** | ✅ Proven | ⚠️ Untested in prod |
| **Canary Filtering** | ❌ Hard (all are resonai-backend) | ✅ Easy (distinct names) |
| **Multi-service Visibility** | ❌ Limited | ✅ Better |
| **Default Service** | ✅ All traces | ✅ Only if missing |
| **Complexity** | ✅ Simple | ⚠️ Moderate |

## Implementation Steps (If Needed)

**To apply this enhancement in the future:**

```bash
# 1. Edit the collector configuration
nano signoz-collector-config.yaml

# 2. Change line 51 from:
#    action: upsert
# To:
#    action: insert

# 3. Restart the collector
docker restart signoz-otel-collector

# 4. Send test canary with custom service.name
python synthetic/send_trace_canary.py

# 5. Verify service.name is now preserved
docker exec signoz-clickhouse clickhouse-client --query \
  "SELECT DISTINCT serviceName FROM signoz_traces.distributed_signoz_index_v3 \
   WHERE timestamp > now() - INTERVAL 5 MINUTE"

# Expected result: Both "resonai-backend" and your custom service names
```

## Recommendation for Phase 1

**Keep current configuration (action: upsert):**

1. **Next 1–2 weeks:** Monitor trace growth and auto-update runs
2. **Verify stability:** Confirm JSON validation gate performance
3. **Performance baseline:** Establish SigNoz with 1,390+ traces
4. **Assess need:** Determine if multi-service visibility is critical

**Then evaluate for Phase 2:**
- **Option A:** Keep current (sufficient for single-service aggregation)
- **Option B:** Implement enhancement (if multi-service tracing needed)
- **Either way:** System is production-ready now

## Key Insight

The root cause analysis of Gate #008 revealed that the current `action: upsert` behavior is **by design**, providing:
- ✅ Deterministic service aggregation
- ✅ Simplified operational model
- ✅ Proven production stability (1,390 traces confirmed)

The optional change would **add flexibility** without compromising current stability.

---

## Current Production Status

✅ **Ready for Deployment:** YES (upsert configuration)
- All systems operational
- Full trace ingestion confirmed
- 1,390 traces successfully stored
- No action required
- JSON Validation Gate live and protecting pipeline

⏳ **Optional Enhancement:** Available for future evaluation
- Low-risk configuration change
- Non-destructive to existing data
- Can be applied anytime
- Improves future multi-service visibility if needed

**Recommendation:** Deploy now with current configuration. Evaluate enhancement after 2 weeks of production operation.
