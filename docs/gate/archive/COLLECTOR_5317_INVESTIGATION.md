# Windows Collector 5317 Forwarding Investigation

**Date:** 2025-10-27  
**Authority:** BossCat OEM (Fubumaki)  
**Executor:** Cursor{Implementer}  
**Context:** Follow-up from Gate #026A / Gate #029 closure  
**Status:** 🔍 **INVESTIGATION IN PROGRESS**

---

## Executive Summary

**Problem:** Windows OTel Collector service running on port 5317 does not forward traces to SigNoz (port 14317), despite collector configuration showing a traces pipeline.

**Workaround:** Direct connection to SigNoz port 14317 works perfectly (proven in Gate #026A).

**Impact:** Limits usefulness of Windows Collector for .NET services; forces direct routing instead of centralized collection.

---

## Background

### Gate #026A Context

**Original Issue:**
- .NET auto-instrumentation sent zero telemetry when configured to use `http://127.0.0.1:5317` (Windows Collector)
- Collector service was RUNNING, port was listening
- Suspected profiler activation issue initially

**Resolution:**
- Changed `OTEL_EXPORTER_OTLP_ENDPOINT` from `http://127.0.0.1:5317` to `http://127.0.0.1:14317` (direct to SigNoz)
- **Result:** IMMEDIATE SUCCESS — All telemetry flowing

**Root Cause (Suspected):**
- Windows Collector NOT forwarding traces to SigNoz (despite config.yaml traces pipeline)
- Port 5317 listening but not processing/forwarding

### Gate #029 Context

**Collector Path Verification:**
- Gate #029 objective was to verify collector path (5317 → 14317 → SigNoz)
- Implementation document claims "collector path verified"
- However, services were actually using direct port 14317 (per Gate #026A pattern)

**Current State:**
- Port 5317: Windows Collector listening ✅
- Port 14317: SigNoz direct ingestion working ✅
- Port 5317 → 14317 forwarding: ❌ **NOT VERIFIED / NOT WORKING**

---

## Investigation Objectives

### Primary Questions

1. **Is the Windows Collector traces pipeline configured correctly?**
   - Check `config/otelcol-config.yaml` traces receivers/processors/exporters
   - Verify pipeline wiring: `receivers → processors → exporters`

2. **Is the collector receiving data on port 5317?**
   - Check collector metrics for received spans
   - Look for `otelcol_receiver_accepted_spans`
   - Check for receiver errors

3. **Is the collector attempting to forward to SigNoz?**
   - Check collector metrics for exported spans
   - Look for `otelcol_exporter_sent_spans`
   - Check for exporter errors

4. **Are there errors in the collector logs?**
   - Check Windows Event Viewer for otelcol-contrib service logs
   - Look for export failures, connection errors, auth issues

5. **Is the exporter endpoint configured correctly?**
   - Should be `localhost:14317` (SigNoz gRPC endpoint)
   - Check protocol (gRPC vs HTTP)
   - Check TLS settings (should be insecure for localhost)

---

## Investigation Plan

### Phase 1: Configuration Review (10-15 min)

**Actions:**
1. Read `config/otelcol-config.yaml`
2. Verify traces receiver on port 5317
3. Verify traces exporter to port 14317
4. Check pipeline service configuration
5. Look for obvious misconfigurations

**Success Criteria:**
- Configuration looks correct (receiver + exporter + service pipeline)
- No obvious errors

### Phase 2: Collector Metrics Check (10-15 min)

**Actions:**
1. Query collector metrics endpoint (port 8888)
2. Check receiver metrics: `otelcol_receiver_accepted_spans{receiver="otlp/traces"}`
3. Check exporter metrics: `otelcol_exporter_sent_spans{exporter="otlp/signoz"}`
4. Compare received vs sent (should be equal if forwarding works)

**Success Criteria:**
- Metrics endpoint accessible
- Receiver shows incoming spans (or 0 if no traffic)
- Exporter shows outgoing spans (or 0 if not forwarding)

### Phase 3: Live Traffic Test (15-20 min)

**Actions:**
1. Deploy a simple .NET service configured to send to port 5317
2. Generate traffic (HTTP requests to trigger spans)
3. Check collector metrics for received/sent spans
4. Check SigNoz for traces (should appear if forwarding works)
5. Compare: Send to 5317 vs send to 14317 (baseline)

**Success Criteria:**
- Service sends spans to 5317
- Collector metrics show received spans
- Collector metrics show sent spans  
- Traces appear in SigNoz

### Phase 4: Log Analysis (10-15 min)

**Actions:**
1. Check Windows Event Viewer: Application log, source "otelcol-contrib"
2. Look for export errors, connection failures
3. Check collector service restart logs
4. Review any error messages

**Success Criteria:**
- Logs reveal error messages or connection issues
- Root cause identified

---

## Hypothesis Tree

### Hypothesis 1: Exporter Endpoint Misconfigured ⭐ (MOST LIKELY)

**Evidence:**
- Direct to 14317 works
- Via 5317 doesn't work
- Config might point to wrong endpoint or protocol

**Test:**
- Review config file exporter section
- Look for `endpoint: localhost:14317` or similar

**Expected Finding:**
- Wrong endpoint (e.g., pointing to wrong port)
- Wrong protocol (HTTP instead of gRPC or vice versa)
- TLS misconfiguration

### Hypothesis 2: Traces Pipeline Not Wired

**Evidence:**
- Collector service running but not forwarding

**Test:**
- Check `service.pipelines.traces` section
- Verify receivers, processors, exporters all listed

**Expected Finding:**
- Pipeline missing or incomplete
- Exporter not included in service pipeline

### Hypothesis 3: Receiver Port Conflict or Binding Issue

**Evidence:**
- Port 5317 shows as listening

**Test:**
- Check if receiver actually accepting connections
- Send test span directly to 5317 and check metrics

**Expected Finding:**
- Receiver not actually bound to 5317
- Or bound but not accepting OTLP protocol

### Hypothesis 4: Resource/Permission Issue

**Evidence:**
- Collector service runs as LocalSystem or specific user

**Test:**
- Check service permissions
- Check if collector can reach SigNoz on 14317

**Expected Finding:**
- Permission issue preventing outbound connections
- Firewall blocking collector → SigNoz traffic

---

## Expected Findings

### Scenario A: Config Issue (60% probability)

**Finding:** Exporter endpoint wrong or pipeline not wired  
**Fix:** Update config.yaml, restart collector  
**Effort:** 15 minutes  
**Risk:** LOW

### Scenario B: Protocol Mismatch (25% probability)

**Finding:** Receiver expects gRPC but service sends HTTP, or vice versa  
**Fix:** Align protocols in config  
**Effort:** 20 minutes  
**Risk:** LOW

### Scenario C: Collector Bug (10% probability)

**Finding:** Windows-specific collector bug in forwarding traces  
**Fix:** Upgrade collector version or report upstream  
**Effort:** Hours (workaround: continue using direct 14317)  
**Risk:** MEDIUM

### Scenario D: Network/Firewall (5% probability)

**Finding:** Firewall or localhost routing issue  
**Fix:** Adjust firewall rules or collector network config  
**Effort:** 30 minutes  
**Risk:** LOW

---

## Success Criteria

**Investigation Complete When:**
- Root cause identified with evidence
- Fix applied (if config issue)
- Verification test shows 5317 → 14317 forwarding works
- OR documented as permanent limitation with workaround

**Deliverables:**
- Investigation report (this document updated)
- Fix applied (if applicable)
- Verification evidence
- Runbook update with findings

---

## Current Status

**Phase:** 0 (Planning)  
**Next Step:** Begin Phase 1 (Configuration Review)  
**Estimated Duration:** 45-60 minutes total

---

**Investigation Date:** 2025-10-27 16:15:00 UTC  
**Executor:** Cursor{Implementer}  
**Authority:** BossCat OEM (Fubumaki)

🐾 **Windows Collector 5317 Forwarding Investigation — Ready to Begin**

