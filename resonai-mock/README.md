# Resonai - MEMX Memory Observation Layer

This is a demonstration implementation of the **MEMX (Memory Observation Layer)** feature for the Resonai voice practice application. MEMX provides real-time browser memory monitoring with optional SigNoz integration.

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Set environment variables
cp env-example.txt .env.local
# Edit .env.local to enable MEMX: NEXT_PUBLIC_FEATURE_MEMX=1

# Start development server
npm run dev
```

## 📋 Implementation Status

### ✅ PR-0: Feature Flags & Scaffolding (Complete)
- [x] Environment configuration with off-by-default toggles
- [x] Type definitions for frames and session aggregates
- [x] Basic store implementation with ring buffer
- [x] Instrumentation stubs for browser memory collection
- [x] OTLP exporter for SigNoz integration
- [x] Labs page with feature gate

### 🔄 PR-1: Schema & Storage (In Progress)
- [ ] Extend session schema with memory aggregates
- [ ] IndexedDB integration for session persistence
- [ ] Export functionality for memory data

### 🔄 PR-2: Browser Instrumentation (Planned)
- [ ] WASM heap monitoring (ONNX runtime)
- [ ] SharedArrayBuffer usage tracking
- [ ] AudioWorklet lag measurement
- [ ] Zero-overhead frame collection

### 🔄 PR-3: Labs UI & HUD (Planned)
- [ ] Live metrics display
- [ ] Sparklines for memory trends
- [ ] Export controls
- [ ] Mini HUD overlay

### 🔄 PR-4: SigNoz Streaming (Planned)
- [ ] OTLP/HTTP metrics export
- [ ] Log events for strain thresholds
- [ ] Configurable export intervals

### 🔄 PR-5: Host Taps (Optional)
- [ ] Node.js ETW/PerfCounter integration
- [ ] GPU utilization monitoring
- [ ] System memory context

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Browser App   │    │   MEMX Engine    │    │   SigNoz OTLP   │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │ Labs Page   │◄┼────┼►│ Store        │ │    │ │ Metrics     │ │
│ │ /labs/memx  │ │    │ │ Ring Buffer  │ │    │ │ Logs        │ │
│ └─────────────┘ │    │ └──────────────┘ │    │ └─────────────┘ │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │                 │
│ │ HUD Overlay │◄┼────┼►│ Instrument.  │ │    │                 │
│ │ (PR-3)      │ │    │ │ WASM/SAB     │ │    │                 │
│ └─────────────┘ │    │ └──────────────┘ │    │                 │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │                 │
│ │ AudioWorklet│◄┼────┼►│ OTLP Export  │◄┼────┼► http://localhost:5318 │
│ │ Stamp Time  │ │    │ │ Metrics/Logs │ │    │                 │
│ └─────────────┘ │    │ └──────────────┘ │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🔧 Configuration

### Environment Variables

```bash
# MEMX Feature Flags
NEXT_PUBLIC_FEATURE_MEMX=0              # Enable/disable MEMX (default: 0)
NEXT_PUBLIC_MEMX_OTLP_ENDPOINT=         # SigNoz OTLP endpoint (optional)
NEXT_PUBLIC_MEMX_STREAM_DEFAULT=0       # Default streaming state (default: 0)

# OTel Integration
NEXT_PUBLIC_OTEL_EXPORTER_OTLP_PROTOCOL=http/json
NEXT_PUBLIC_OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:5318
NEXT_PUBLIC_OTEL_SERVICE_NAME=resonai-local

# Performance Overlay (INV-04)
NEXT_PUBLIC_PERF_OVERLAY=1  # enable battery/perf HUD in dev
```

### Feature Gates

- **MEMX Disabled**: Shows informational page with setup instructions
- **MEMX Enabled**: Full diagnostics page with live metrics and controls
- **Streaming Off**: No network calls, all data stays local
- **Streaming On**: Exports metrics and log events to SigNoz

## 📊 Memory Metrics

### Frame-Level Data (Local Only)
- `wasmHeapBytes`: WebAssembly memory usage
- `sabUsedBytes` / `sabCapacityBytes`: SharedArrayBuffer utilization
- `workletLagMs`: AudioWorklet processing latency
- `gpuUtilPct`: GPU utilization (PR-5)
- `flags`: Strain indicators (backlog, growth, etc.)

### Session Aggregates (Stored)
- `peakWasmHeapBytes`: Maximum WASM heap observed
- `peakSabUsagePct`: Maximum SAB usage percentage
- `avgWorkletLagMs`: Average worklet lag
- `p95WorkletLagMs`: 95th percentile worklet lag
- `memoryStrainPct`: Overall memory strain score (0-100)

### Strain Events (Logged)
- `SAB_BACKLOG`: Audio ring buffer >80% full
- `WASM_GROW`: WebAssembly memory growth detected
- `WORKLET_LAG`: AudioWorklet lag >50ms
- `GPU_STRAIN`: GPU utilization >90% (PR-5)

## 🔒 Privacy & Security

- **Local-First**: All frame data stays in browser memory
- **No Audio**: Never captures or transmits audio data
- **Optional Streaming**: SigNoz export is opt-in and off by default
- **Rate Limited**: Export intervals prevent spam
- **Redacted**: No PII in telemetry payloads

## 🧪 Testing

```bash
# Run type checking
npm run typecheck

# Run linting
npm run lint

# Run tests (when implemented)
npm run test

# Run E2E tests (when implemented)
npm run test:e2e

# Run full CI pipeline
npm run ci
```

## 🚀 Release QA

### **Complete QA Suite**
```bash
# Run full QA suite (all tests)
pnpm run qa:full
# Expected runtime: 8-12 minutes
```

### **Individual Test Suites**
```bash
# Run specific test suites
pnpm run qa:a11y        # Accessibility smoke tests
pnpm run qa:isolation   # Offline isolation tests
pnpm run qa:prosody     # Prosody scenario tests
pnpm run qa:strain      # Strain detection tests
pnpm run qa:progress    # Progress dashboard tests
pnpm run qa:data        # Data control tests
```

### **QA Summary & Reporting**
```bash
# Generate test report
pnpm test:e2e --reporter=json > playwright-report.json || true
pnpm run qa:summary

# Environment check
pnpm run qa:env-check

# Cleanup test artifacts
pnpm run qa:cleanup
```

### **QA Runbook**
For detailed QA procedures, troubleshooting, and release processes, see:
- **[QA Release Runbook](./docs/QA_RELEASE_RUNBOOK.md)** - Complete QA process documentation
- **[QA Checklist](./docs/qa-checklist.md)** - Feature-specific testing checklists

### **Test Coverage**
- **Unit Tests**: Aggregation, export schema, strain detection
- **E2E Tests**: Progress dashboard, data control, prosody scenarios, strain detection, offline isolation, accessibility
- **Cross-Browser**: Firefox, Chromium, WebKit
- **Accessibility**: WCAG AA compliance, screen reader support, reduced motion
- **Security**: COOP/COEP headers, CSP compliance, offline isolation

## 🚀 Development

### Project Structure

```
resonai-mock/
├── app/                    # Next.js App Router
│   ├── labs/memx/         # MEMX diagnostics page
│   ├── layout.tsx         # Root layout with navigation
│   └── page.tsx           # Home page
├── src/engine/memx/       # MEMX core engine
│   ├── types.ts           # Type definitions
│   ├── store.ts           # Ring buffer & aggregates
│   ├── instrumentation.ts # Browser memory collection
│   └── otelExporter.ts    # SigNoz OTLP export
├── env-example.txt        # Environment configuration
└── README.md             # This file
```

### Key Files

- **`src/engine/memx/types.ts`**: Core type definitions
- **`src/engine/memx/store.ts`**: Ring buffer and session aggregates
- **`src/engine/memx/instrumentation.ts`**: Browser memory collection
- **`src/engine/memx/otelExporter.ts`**: SigNoz OTLP integration
- **`app/labs/memx/page.tsx`**: Diagnostics UI

## 📈 SigNoz Integration

When streaming is enabled, MEMX exports:

### Metrics (Every 5s)
- `memx.wasm_heap.bytes` - WASM heap size
- `memx.sab.usage.pct` - SAB usage percentage
- `memx.worklet.lag.avg.ms` - Average worklet lag
- `memx.worklet.lag.p95.ms` - P95 worklet lag
- `memx.strain.pct` - Memory strain percentage

### Log Events (On Threshold Crossing)
- `SAB_BACKLOG` - Audio ring buffer backlog
- `WASM_GROW` - WebAssembly memory growth
- `WORKLET_LAG` - AudioWorklet latency spike
- `GPU_STRAIN` - GPU utilization spike

### SigNoz Queries

```sql
-- All MEMX metrics
attributes.dataset = "resonai_analytics" AND attributes.metric.name LIKE "memx.%"

-- Memory strain events
attributes.dataset = "resonai_analytics" AND attributes.event.type IN ("SAB_BACKLOG", "WASM_GROW", "WORKLET_LAG", "GPU_STRAIN")

-- High strain sessions
attributes.dataset = "resonai_analytics" AND attributes.metric.name = "memx.strain.pct" AND attributes.metric.value > 80
```

## 🎯 Next Steps

1. **Enable MEMX**: Set `NEXT_PUBLIC_FEATURE_MEMX=1` in `.env.local`
2. **Start Dev Server**: Run `npm run dev`
3. **Visit Labs**: Navigate to `http://localhost:3000/labs/memx`
4. **Enable Streaming**: Toggle streaming in the labs page
5. **Monitor SigNoz**: Check `http://localhost:8080` for MEMX data

## 📚 References

- [Original MEMX Specification](./docs/memx-specification.md)
- [SigNoz OTLP Documentation](https://signoz.io/docs/userguide/otel-collector/)
- [WebAssembly Memory API](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WebAssembly/Memory)
- [SharedArrayBuffer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer)
