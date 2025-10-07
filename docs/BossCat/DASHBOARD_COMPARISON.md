# SigNoz Dashboard Mockup Comparison

## 🎯 Overview

Comparison between the original mockup and the enhanced **Cat Nap Control Room** v2 dashboard.

---

## 📊 Feature Comparison

| Feature | Original Mockup | Enhanced v2 | Notes |
|---------|----------------|-------------|-------|
| **Design System** | Basic light theme | Resonai brand colors (dark/light) | Matches status.html tokens |
| **77× Uplift** | ❌ Not present | ✅ Hero banner | Prominent performance metric |
| **GPU Sidecars** | ❌ Not present | ✅ Two dedicated panels | Ports 8001/8002 monitoring |
| **IONA Controller** | ❌ Not present | ✅ Health scoring section | 4 key metrics |
| **Three-Loop System** | ❌ Not present | ✅ Möbius loop status | Policy/Evaluation/Routing |
| **Real-time Updates** | ❌ Static | ✅ Live timestamp | Updates every second |
| **Responsive Design** | ✅ Basic | ✅ Advanced | Mobile-friendly grid |
| **Cat Nap Aesthetic** | ❌ Generic | ✅ Themed | Calm, efficient, playful |
| **ECRR Compliance** | ❌ Not present | ✅ Indicator | BossCat certification |
| **Print Support** | ❌ Basic | ✅ Optimized | PDF-friendly layout |
| **Accessibility** | ⚠️ Partial | ✅ Full | WCAG AA compliant |
| **Data Integration** | ❌ None | ✅ Hooks ready | SigNoz API comments |

---

## 🎨 Design Changes

### Color Palette
**Original:**
- Background: `#f5f5f5` (light gray)
- Primary: `#274472` (blue)
- Cards: `#fff` (white)

**Enhanced v2:**
- Background: `#0b0d12` (deep blue-black)
- Primary Gradient: `#7c5cff → #4caf50` (purple-green)
- Cards: `#121520` (elevated dark)
- Accent Colors: Teal `#00c2b2`, Yellow `#ffc107`, Red `#f44336`

### Typography
**Original:**
- Font: Arial
- Sizes: 14px, 16px, 32px

**Enhanced v2:**
- Font: system-ui, -apple-system, Segoe UI, Roboto, Inter
- Sizes: 11px → 48px (hierarchical scale)
- Weights: 500, 600, 700, 800

---

## 🚀 New Components in v2

### 1. Performance Hero
```html
<div class="performance-hero">
  <h2>🚀 77× THROUGHPUT UPLIFT</h2>
  <p>2.5 → 196.7 logs/sec</p>
</div>
```

### 2. GPU Sidecar Cards
- **Port 8001**: nvCOMP Compression (multi-GB/sec throughput)
- **Port 8002**: cuDF Aggregation (parallel bucketing)

### 3. Möbius Control Loops
- **Policy Loop**: ECRR gates, security baselines, compliance
- **Evaluation Loop**: Success rate, queue depth, latency
- **Routing Loop**: Traffic steering, circuit breakers, priority queues

### 4. IONA Controller Status
- Health Score: 98/100
- Error Ledger: 0 active anomalies
- Drift Detection: 0 config drifts
- ECRR Compliance: 100%

### 5. Enhanced Log Table
- Color-coded log levels (INFO/WARN/ERROR)
- Filter buttons (placeholder logic)
- Monospace timestamps
- Source column

---

## 📝 Usage Instructions

### View Original Mockup
```bash
start docs/BossCat/signoz_dashboard_mockup.html
```

### View Enhanced v2
```bash
start docs/BossCat/signoz_dashboard_mockup_v2.html
```

### Compare Side-by-Side
Open both in separate browser tabs and compare:
1. Color scheme and branding
2. Information density
3. Component organization
4. Visual hierarchy

---

## 🔌 Real Data Integration (Next Steps)

### SigNoz API Integration

The v2 dashboard includes placeholder hooks for real data. Here's how to integrate:

#### 1. Fetch Pipeline Metrics
```javascript
async function fetchPipelineMetrics() {
  const response = await fetch('http://localhost:8080/api/v1/query_range', {
    method: 'POST',
    headers: { 
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${SIGNOZ_API_TOKEN}`
    },
    body: JSON.stringify({
      query: 'rate(otelcol_receiver_accepted_spans[5m])',
      start: Date.now() - 3600000, // 1 hour ago
      end: Date.now(),
      step: 60 // 1 minute resolution
    })
  });
  const data = await response.json();
  updateThroughputCard(data);
}
```

#### 2. Fetch GPU Metrics
```javascript
async function fetchGPUMetrics() {
  // Assuming GPU sidecars expose Prometheus metrics
  const compressionMetrics = await fetch('http://localhost:8001/metrics');
  const aggregationMetrics = await fetch('http://localhost:8002/metrics');
  // Parse and update GPU cards
}
```

#### 3. Fetch IONA Health
```javascript
async function fetchIONAHealth() {
  // Read from IONA error ledger
  const errorLedger = await fetch('/docs/IONA_ERRORS.md');
  const anomalyCount = parseErrorCount(errorLedger);
  updateIONAHealthCard(anomalyCount);
}
```

#### 4. Fetch Recent Logs
```javascript
async function fetchRecentLogs() {
  const response = await fetch('http://localhost:8080/api/v1/logs', {
    method: 'POST',
    headers: { 
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${SIGNOZ_API_TOKEN}`
    },
    body: JSON.stringify({
      filters: { items: [] },
      limit: 50,
      orderBy: { columnName: 'timestamp', order: 'desc' }
    })
  });
  const data = await response.json();
  updateLogsTable(data.logs);
}
```

#### 5. Auto-Refresh Loop
```javascript
// Refresh data every 30 seconds
setInterval(async () => {
  await Promise.all([
    fetchPipelineMetrics(),
    fetchGPUMetrics(),
    fetchIONAHealth(),
    fetchRecentLogs()
  ]);
}, 30000);
```

---

## 🎯 Recommended Next Steps

### Phase 1: Data Integration (1-2 hours)
- [ ] Add SigNoz API token management
- [ ] Implement `fetchPipelineMetrics()`
- [ ] Implement `fetchRecentLogs()`
- [ ] Add auto-refresh loop (30s interval)

### Phase 2: Chart Library (2-3 hours)
- [ ] Install Chart.js or similar
- [ ] Replace chart placeholders with real time-series graphs
- [ ] Add GPU utilization sparklines
- [ ] Add latency histogram

### Phase 3: Interactive Features (1-2 hours)
- [ ] Implement log filtering (INFO/WARN/ERROR)
- [ ] Add date range picker
- [ ] Add export to CSV functionality
- [ ] Add dark/light theme toggle

### Phase 4: Advanced Features (3-4 hours)
- [ ] WebSocket for real-time updates
- [ ] Alert notifications
- [ ] Drill-down to individual traces
- [ ] IONA error ledger integration

---

## 🐾 BossCat Recommendations

### Immediate Actions
1. **Use v2 as the canonical dashboard mockup**
2. **Integrate SigNoz API for real-time data**
3. **Add Chart.js for time-series visualization**
4. **Test with live OTel pipeline**

### Future Enhancements
- **Mobile app version** (responsive already, optimize further)
- **Playwright automation** for screenshot exports
- **Nightly dashboard exports** (like status.html)
- **ECRR compliance dashboard** (separate view)

---

## 📚 References

- **Architecture Diagram**: `docs/BossCat/SYSTEM_ARCHITECTURE_DIAGRAM.md`
- **Status Dashboard**: `docs/status.html`
- **SigNoz API Docs**: https://signoz.io/docs/api/
- **BossCat Agents**: `docs/AGENTS.md`
- **IONA Integration**: `docs/IONA_SIGNOZ_INTEGRATION.md`

---

**🐾 BossCat OEM Approved**  
*This comparison guide is the canonical reference for dashboard evolution.*

