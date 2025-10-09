# Data Room Test Harness — User Guide

**Version**: 1.0  
**Date**: 2025-10-07  
**BossCat OEM Certified**

---

## 🎯 Overview

The **Resonai Data Room** is a comprehensive test harness and chaos engineering platform for generating, observing, and manipulating telemetry signals in real-time. It serves as both a development tool and an operational safety mechanism.

**Two Versions Available:**
1. **data_room.html** - Original mockup (105 lines, basic functionality)
2. **data_room_enhanced.html** - Enhanced version (461 lines, production-ready)

**Recommended**: Use the enhanced version for all testing operations.

---

## 🚀 Quick Start

### **Opening the Data Room**

```bash
# Enhanced version (recommended)
start docs/BossCat/data_room_enhanced.html

# Or navigate to
file:///C:/otel/docs/BossCat/data_room_enhanced.html
```

### **Basic Workflow**

1. Open the data room in your browser
2. Click a primary control button (Laminar, Chaotic, Test, Canary)
3. Observe metrics update in real-time
4. Review logs in the event table
5. Run chaos scenarios to test resilience
6. Click "Stop Signals" to halt tests

---

## 🎛️ Primary Controls

### **1. 🌊 Laminar Flow**
- **Purpose**: Generate steady-state, predictable telemetry
- **Throughput**: 400-450 req/sec (stable)
- **Use Case**: Baseline testing, performance benchmarking
- **Log Level**: INFO
- **Expected Behavior**: Smooth, consistent metrics without spikes

### **2. 🌀 Chaotic Flow**
- **Purpose**: Generate volatile, unpredictable telemetry
- **Throughput**: 300-700 req/sec (highly variable)
- **Use Case**: Stress testing, resilience validation
- **Log Level**: WARN
- **Expected Behavior**: Erratic metrics with rapid fluctuations

### **3. 🧪 Test Signal**
- **Purpose**: Generate standard test telemetry
- **Throughput**: 200-300 req/sec (moderate)
- **Use Case**: Integration testing, debugging
- **Log Level**: DEBUG
- **Expected Behavior**: Moderate, controlled throughput

### **4. 🐤 Canary Test**
- **Purpose**: Generate canary validation signals
- **Throughput**: 100-130 req/sec (low)
- **Use Case**: Deployment validation, smoke testing
- **Log Level**: INFO
- **Expected Behavior**: Low-volume, high-reliability signals with unique IDs

### **5. 🛑 Stop Signals**
- **Purpose**: Issue emergency stop command
- **Throughput**: N/A (control signal)
- **Use Case**: Halt all ongoing tests immediately
- **Log Level**: INFO
- **Expected Behavior**: Status bar changes to "Stopped" for 3 seconds

### **6. 🗑️ Clear Logs**
- **Purpose**: Reset event log table
- **Throughput**: N/A (control signal)
- **Use Case**: Start fresh test run
- **Log Level**: INFO
- **Expected Behavior**: All logs cleared, counters reset to zero

---

## 💥 Chaos Engineering Scenarios

### **Network Failures**

#### **🔌 Network Delay**
- **Simulation**: 200-500ms latency injection
- **Impact**: Request timeouts, slow responses
- **Use Case**: Test timeout handling, retry logic
- **Expected Logs**: `Request timeout after 500ms`

#### **📦 Packet Loss**
- **Simulation**: 10% packet drop rate
- **Impact**: Retransmissions, degraded throughput
- **Use Case**: Test network resilience, error correction
- **Expected Logs**: `Packet loss: 12%`

---

### **Service Failures**

#### **❌ Service Down**
- **Simulation**: Service unavailability
- **Impact**: Connection refused errors
- **Use Case**: Test failover, circuit breakers
- **Expected Logs**: `Connection refused • Target: http://localhost:8080`

---

### **Resource Exhaustion**

#### **📈 Memory Spike**
- **Simulation**: High memory pressure (87% utilization)
- **Impact**: OOM risks, GC pressure
- **Use Case**: Test memory limits, leak detection
- **Expected Logs**: `Memory usage: 87% • Threshold exceeded`

#### **⚡ CPU Throttle**
- **Simulation**: High CPU load (94% utilization)
- **Impact**: Slow processing, throttling
- **Use Case**: Test CPU-bound operations, scaling
- **Expected Logs**: `CPU usage: 94% • Throttling detected`

#### **💾 Disk Full**
- **Simulation**: Storage exhaustion (98% full)
- **Impact**: Write failures, log rotation issues
- **Use Case**: Test disk management, cleanup policies
- **Expected Logs**: `Disk space: 98% full • Write operations blocked`

---

## 📊 Real-Time Metrics

### **Throughput**
- **Display**: req/sec
- **Range**: 0-700 (depends on control selected)
- **Color Coding**:
  - Green (✅): Normal operation
  - Yellow (⚠️): Warning threshold
  - Red (❌): Error threshold

### **Total Events**
- **Display**: Cumulative count
- **Increments**: Each button click or chaos scenario
- **Reset**: Click "Clear Logs"

### **Error Rate**
- **Display**: Percentage
- **Calculation**: `(Error logs / Total events) × 100`
- **Target**: <5% for production systems

### **Active Tests**
- **Display**: Running test count
- **Duration**: Auto-decrements after 2 seconds
- **Max**: Multiple simultaneous tests supported

---

## 📋 Event Log Structure

| Column | Description | Example |
|--------|-------------|---------|
| **Timestamp** | ISO 8601 format | `2025-10-07 20:35:42` |
| **Level** | INFO/WARN/ERROR/DEBUG | `INFO` |
| **Source** | Component origin | `Laminar`, `Chaos`, `Control` |
| **Message** | Event description | `Laminar flow operational` |
| **Details** | Additional context | `Steady-state throughput 400-450 req/sec` |

### **Log Levels**

- **INFO** (🟢 Teal): Normal operations, canary tests, control signals
- **WARN** (🟡 Yellow): Chaotic flows, chaos scenarios, threshold warnings
- **ERROR** (🔴 Red): Service failures, resource exhaustion, test errors
- **DEBUG** (🔵 Blue): Test signals, diagnostic information

### **Log Retention**
- Maximum: 100 logs (FIFO eviction)
- Display: Real-time insertion at top
- Clear: Manual via "Clear Logs" button

---

## 🧪 Testing Scenarios

### **Scenario 1: Baseline Validation**

**Objective**: Establish performance baseline

1. Click **"🌊 Laminar Flow"** 5 times
2. Observe throughput stabilizes at 400-450 req/sec
3. Verify error rate remains at 0%
4. Export metrics for baseline reference

**Expected**: Smooth line chart, consistent throughput, zero errors

---

### **Scenario 2: Stress Testing**

**Objective**: Test system under load

1. Click **"🌀 Chaotic Flow"** 10 times rapidly
2. Observe throughput spikes between 300-700 req/sec
3. Monitor error rate (should remain <10%)
4. Verify system recovers after chaos subsides

**Expected**: Volatile chart, fluctuating throughput, some warnings

---

### **Scenario 3: Canary Deployment**

**Objective**: Validate deployment safety

1. Click **"🐤 Canary Test"** 3 times
2. Verify each canary has unique ID (`canary-<timestamp>`)
3. Check all canaries appear in logs
4. Confirm low throughput (100-130 req/sec)

**Expected**: Low-volume signals, unique IDs, INFO level logs

---

### **Scenario 4: Chaos Drill**

**Objective**: Test resilience and recovery

1. Click **"🌊 Laminar Flow"** to establish baseline
2. Run **"❌ Service Down"** chaos scenario
3. Observe error logs and metric degradation
4. Click **"🛑 Stop Signals"** to halt
5. Click **"🌊 Laminar Flow"** to resume
6. Verify system recovers to baseline

**Expected**: Error spike, recovery to normal, logs document incident

---

### **Scenario 5: Multi-Failure Simulation**

**Objective**: Test compound failure handling

1. Run **"🔌 Network Delay"** scenario
2. Immediately run **"📈 Memory Spike"** scenario
3. Follow with **"⚡ CPU Throttle"** scenario
4. Monitor metrics and logs
5. Verify system remains operational despite multiple stressors

**Expected**: Multiple warnings, but no complete failure

---

## 🔗 Integration Points

### **With Live Dashboard**

```javascript
// Future enhancement: Export metrics to live dashboard
function exportToLiveDashboard() {
  const metrics = {
    throughput: document.getElementById('throughput').textContent,
    errorRate: document.getElementById('errorRate').textContent,
    timestamp: new Date().toISOString()
  };
  
  // Send to live dashboard via postMessage or API
  window.parent.postMessage({ type: 'metrics', data: metrics }, '*');
}
```

### **With SigNoz**

```javascript
// Future enhancement: Push logs to SigNoz
function pushToSigNoz(log) {
  fetch('http://localhost:8080/api/v1/logs', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      timestamp: log.timestamp,
      severity: log.level,
      body: log.message,
      attributes: {
        source: log.source,
        details: log.details
      }
    })
  });
}
```

### **With Canary Scripts**

```powershell
# PowerShell integration
# Run data room tests from command line

# Invoke browser automation
Start-Process "chrome.exe" "C:\otel\docs\BossCat\data_room_enhanced.html"

# Simulate button clicks via automation (e.g., Playwright)
npx playwright codegen docs/BossCat/data_room_enhanced.html
```

---

## 📈 Metrics Interpretation

### **Normal Operation Indicators**

✅ **Laminar Flow**: 400-450 req/sec, flat line chart  
✅ **Error Rate**: 0-2%  
✅ **Active Tests**: 0-2 concurrent  
✅ **Log Levels**: Primarily INFO with occasional DEBUG

### **Warning Indicators**

⚠️ **Chaotic Flow**: >500 req/sec spikes  
⚠️ **Error Rate**: 3-10%  
⚠️ **Active Tests**: 3-5 concurrent (may indicate resource contention)  
⚠️ **Log Levels**: Multiple WARN entries

### **Critical Indicators**

❌ **Throughput**: >700 req/sec (overload) or <100 req/sec (degradation)  
❌ **Error Rate**: >10%  
❌ **Active Tests**: >5 concurrent (resource exhaustion risk)  
❌ **Log Levels**: Multiple ERROR entries

---

## 🎓 Best Practices

### **Development**

1. **Start with Laminar**: Establish baseline before testing
2. **Isolate Variables**: Test one chaos scenario at a time
3. **Document Results**: Export logs after each test run
4. **Version Control**: Track test configurations and results

### **Operations**

1. **Pre-Deployment**: Run canary tests before releases
2. **Post-Deployment**: Verify with laminar flow validation
3. **Incident Response**: Use chaos scenarios to reproduce issues
4. **Capacity Planning**: Stress test with chaotic flow

### **Security**

1. **Localhost Only**: Data room should not be exposed publicly
2. **No Credentials**: Never input real credentials in test logs
3. **Sanitize Data**: Clear logs before sharing screenshots
4. **Audit Trail**: Keep test results for compliance

---

## 🐛 Troubleshooting

### **Chart Not Rendering**

**Symptom**: Blank chart area  
**Cause**: Chart.js CDN not loaded  
**Solution**: Check internet connection or use local Chart.js

### **Buttons Not Responding**

**Symptom**: Clicks don't generate events  
**Cause**: JavaScript error in console  
**Solution**: Open DevTools, check console for errors

### **Logs Not Updating**

**Symptom**: Table shows "No events logged"  
**Cause**: Event listener not attached  
**Solution**: Refresh page, ensure `window.onload` fired

### **Metrics Stuck at Zero**

**Symptom**: KPIs show 0 despite button clicks  
**Cause**: State management initialization failed  
**Solution**: Refresh page, check browser compatibility

---

## 🔄 Future Enhancements

### **Phase 1: Real Backend Integration**

- Connect to actual SigNoz API
- Push logs to OTel Collector
- Export metrics to Prometheus

### **Phase 2: Advanced Scenarios**

- DNS failures
- SSL/TLS errors
- Database connection pool exhaustion
- Distributed trace breakage

### **Phase 3: Automation**

- Playwright test suite
- CLI interface for headless operation
- Scheduled chaos drills
- Automated report generation

### **Phase 4: Collaboration**

- Multi-user coordination
- Shared test sessions
- Real-time collaboration features
- Team annotations on logs

---

## 📚 Related Documentation

- **Project Hub**: [../../index.html](../../index.html)
- **Live Dashboard**: [signoz_dashboard_live.html](signoz_dashboard_live.html)
- **System Architecture**: [SYSTEM_ARCHITECTURE_DIAGRAM.md](SYSTEM_ARCHITECTURE_DIAGRAM.md)
- **User Guide**: [PROJECT_HUB_USER_GUIDE.md](PROJECT_HUB_USER_GUIDE.md)
- **Full Deployment Summary**: [FULL_DEPLOYMENT_SUMMARY_20251007.md](FULL_DEPLOYMENT_SUMMARY_20251007.md)

---

**🐾 BossCat OEM Certified Test Harness**  
*Data Room User Guide • Version 1.0 • 2025-10-07*

