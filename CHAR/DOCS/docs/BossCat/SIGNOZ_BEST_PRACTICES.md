# SigNoz + OpenTelemetry Best Practices for Bot-Native Pipelines

**Authority:** BossCat OEM  
**Source:** SigNoz OpenTelemetry Resource Center  
**Updated:** 2025-10-10 (Phase 1.4)  
**Status:** ✅ Active — corrected 2026-09-02 (see notice)

> **Corrected 2026-09-02 — two P0 items.** (1) The Windows collector must **not** export to
> `localhost:5321`: that is its own HTTP receiver, and the original block wired a self-loop. The
> canonical exporter is `otlp` → `localhost:4317` (`config.yaml`); 5320/5321 are the collector's
> *ingest* ports for local apps and browsers. (2) Never cap `retry_on_failure.max_elapsed_time`: the
> former 30 s cap silently dropped ~7.4k log records while SigNoz was down for hours on 2026-08-18;
> `config.yaml` sets `max_elapsed_time: 0` with a `file_storage`-backed `sending_queue`. Both blocks
> are corrected in place below. `config/otelcol-windows.yaml` is a legacy path — the canonical file is
> the root `config.yaml`.

---

## 🎯 Core Principles

### 1. Use HTTP/Protobuf as Primary Protocol

**Problem:** gRPC (port 4317/5320) can cause parse errors, especially in bot/script environments.

**Solution:** Default to HTTP/protobuf for *application and script* exports — into the Windows
collector (`5321`) or straight to SigNoz (`4318`). The collector's own exporter stays `otlp` gRPC →
`localhost:4317` per `config.yaml`.

**Implementation:**

```yaml
# config.yaml (Windows collector) — canonical exporter; never point this at 5320/5321
exporters:
  otlp:
    endpoint: localhost:4317   # signoz-otel-collector (docker-compose.yml)
    tls:
      insecure: true
```

```typescript
// scripts/emit-synthetic-span.ts
const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? 'http://127.0.0.1:5321/v1/traces';
```

**Benefits:**

- ✅ Fewer connection errors
- ✅ Better script/bot compatibility
- ✅ Simpler debugging (HTTP headers visible)
- ✅ No protobuf parsing issues

---

### 2. Centralize Configuration with .env Files

**Problem:** Hard-coded endpoints make multi-environment deployments fragile.

**Solution:** Use `.env` files for all environment-specific configuration.

**Implementation:**

```bash
# .env (copy from .env.template)
OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:5321
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_SERVICE_NAME=gate-synthetic
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=production,bosscat.lane=gate
```

**Load in PowerShell:**

```powershell
Get-Content .env | ForEach-Object {
  if ($_ -match '^([^#][^=]+)=(.*)$') {
    [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
  }
}
```

**Load in Docker Compose:**

```yaml
services:
  signoz-collector:
    env_file:
      - .env
```

**Benefits:**

- ✅ Bot-friendly (swap configs without code changes)
- ✅ Environment parity (dev/stage/prod)
- ✅ Secret management (don't commit .env)

---

### 3. Centralize Telemetry with OTel Collector

**When to Use:**

- ✅ Multi-service architectures (>3 services)
- ✅ Need centralized management/enrichment
- ✅ Protocol translation required
- ✅ High availability/scalability needs
- ✅ Security/compliance controls

**When to Skip:**

- Small setups (<3 services, local only)
- Quick prototypes

**Architecture:**

```text
┌─────────────┐     ┌──────────────────┐     ┌─────────┐
│ Application │────▶│ OTel Collector   │────▶│ SigNoz  │
│  (OTLP)     │     │ (Process/Filter) │     │ Backend │
└─────────────┘     └──────────────────┘     └─────────┘
```

**Benefits:**

- ✅ Decouple apps from backend
- ✅ Add processors (sampling, filtering)
- ✅ Buffer during backend outages
- ✅ Multiple export destinations

---

### 4. Reduce Cardinality with Metric Views

**Problem:** High-cardinality attributes (user IDs, request IDs) explode costs and slow queries.

**Solution:** Use OpenTelemetry View API to limit attributes.

**Example (Python):**

```python
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.view import View, SumAggregation

# Drop debug metrics entirely
view_drop = View(
    instrument_name="debug.*",
    aggregation=DropAggregation()
)

# Limit attributes to specific keys
view_limit = View(
    instrument_name="http.server.request.duration",
    attribute_keys=["bosscat.lane", "deployment.environment"]  # Drop request_id, user_id, etc.
)

# Change histogram to sum (lower cardinality)
view_sum = View(
    instrument_name="memory.usage",
    aggregation=SumAggregation()
)

meter_provider = MeterProvider(views=[view_drop, view_limit, view_sum])
```

**Bot-Native Pattern:**

- Keep: `bosscat.lane`, `bosscat.actor`, `deployment.environment`
- Drop: `request_id`, `user_id`, `transaction_id` (use in logs/traces, not metrics)

**Benefits:**

- ✅ ~30-50% cardinality reduction
- ✅ Faster queries
- ✅ Lower costs

---

### 5. Structured Logging with Trace Context

**Problem:** Logs and traces are disconnected, hard to correlate.

**Solution:** Inject `trace_id` and `span_id` into every log entry.

**Implementation (Node.js + Pino):**

```typescript
import pino from 'pino';
import { trace } from '@opentelemetry/api';

const logger = pino({
  mixin() {
    const span = trace.getActiveSpan();
    if (span) {
      const spanContext = span.spanContext();
      return {
        trace_id: spanContext.traceId,
        span_id: spanContext.spanId,
      };
    }
    return {};
  },
});

// Usage
logger.info({ bosscat_lane: 'gate', action: 'verify' }, 'Pipeline verified');
```

**SigNoz Logs Pipeline:**

1. Navigate to SigNoz UI → Logs → Pipelines
2. Add processor: Parse `trace_id` and `span_id` fields
3. Verify linkage: Click log entry → "View Trace" button appears

**Benefits:**

- ✅ Instant log-to-trace navigation
- ✅ Debug faster (see all logs for a trace)
- ✅ Unified observability

---

### 6. Create Meaningful Metrics

**OpenTelemetry Instrument Types:**

| Type | Use Case | Example |
|------|----------|---------|
| **Counter** | Cumulative counts (always increasing) | Tasks completed, requests handled |
| **UpDownCounter** | Values that increase/decrease | Active connections, queue depth |
| **Histogram** | Distributions (latency, sizes) | Request duration, payload size |
| **Gauge** | Instantaneous measurements | CPU temperature, memory usage |

**Bot-Native Example (TypeScript):**

```typescript
const meter = provider.getMeter('bosscat-gate');

// Counter: Gate operations completed
const gateOps = meter.createCounter('bosscat.gate.operations', {
  description: 'Total gate operations completed',
  unit: 'operations',
});

// UpDownCounter: Active bot jobs
const activeJobs = meter.createUpDownCounter('bosscat.gate.active_jobs', {
  description: 'Currently active bot jobs',
  unit: 'jobs',
});

// Histogram: Gate execution duration
const gateDuration = meter.createHistogram('bosscat.gate.duration', {
  description: 'Gate execution duration',
  unit: 'ms',
});

// Gauge: Budget utilization
const budgetUsage = meter.createGauge('bosscat.gate.budget_used', {
  description: 'Current budget utilization',
  unit: 'percent',
});
```

**Benefits:**

- ✅ Semantic clarity
- ✅ Correct aggregations
- ✅ SigNoz dashboards auto-visualize

---

### 7. Balance Auto and Manual Instrumentation

**Auto-Instrumentation:**

- ✅ Fast to implement (zero code changes)
- ✅ Captures framework-level operations (HTTP, DB, etc.)
- ✅ Great for baseline observability

**Manual Instrumentation:**

- ✅ Business-logic visibility (gate checks, budget enforcement)
- ✅ Custom attributes (bosscat.lane, bosscat.budget_used)
- ✅ Deeper insight into critical paths

**Strategy:**

1. **Start with auto:** Install `@opentelemetry/auto-instrumentations-node`
2. **Add manual spans** for bot-specific operations:
   - Gate verification (`gate.verify`)
   - Budget checks (`gate.budget_check`)
   - Evidence writes (`gate.evidence_write`)
3. **Enrich with attributes:** `bosscat.lane`, `bosscat.actor`, `bosscat.files_changed`

**Example:**

```typescript
import { trace } from '@opentelemetry/api';

const tracer = trace.getTracer('bosscat-gate');

async function verifyGate() {
  const span = tracer.startSpan('gate.verify', {
    attributes: {
      'bosscat.lane': 'gate',
      'bosscat.actor': 'GATE-ALFA',
    },
  });
  
  try {
    // Business logic here
    span.setAttribute('bosscat.checks_passed', 3);
    span.setStatus({ code: 1 }); // OK
  } catch (error) {
    span.recordException(error);
    span.setStatus({ code: 2, message: error.message }); // ERROR
    throw error;
  } finally {
    span.end();
  }
}
```

---

### 8. Explicit Timeouts and Retries

**Problem:** Network flakiness causes silent failures in bot operations.

**Solution:** Explicit timeouts and retry logic everywhere.

**Patterns:**

**TypeScript (OTLP Exporter):**

```typescript
const exporter = new OTLPTraceExporter({
  url: endpoint,
  timeoutMillis: 5000,  // 5-second timeout
});

// Retries handled internally by SDK (3 attempts, exponential backoff)
```

**PowerShell (HTTP Requests):**

```powershell
Invoke-WebRequest -Uri $url -TimeoutSec 5 -MaximumRetryCount 3 -RetryIntervalSec 2
```

**OTel Collector (YAML):**

```yaml
# config.yaml — retry until delivered; the disk-backed queue is the outage mitigation
exporters:
  otlp:
    retry_on_failure:
      enabled: true
      initial_interval: 100ms
      max_interval: 5s
      max_elapsed_time: 0        # 0 = never give up (a 30s cap lost ~7.4k records on 2026-08-18)
    sending_queue:
      enabled: true
      num_consumers: 8
      queue_size: 100000
      storage: file_storage      # C:\ProgramData\Otelcol\FileStorage
```

**Benefits:**

- ✅ Predictable failure modes
- ✅ No hanging operations
- ✅ Graceful degradation

---

### 9. Secure Ingestion Keys

**Problem:** Hard-coded keys in code/configs = security risk.

**Solution:**

1. ✅ Load from environment variables
2. ✅ Never commit to version control
3. ✅ Rotate periodically (quarterly)

**Pattern:**

```bash
# .env (not committed)
SIGNOZ_INGESTION_KEY=your-key-here

# Load in app
export SIGNOZ_INGESTION_KEY=$(cat .env | grep SIGNOZ_INGESTION_KEY | cut -d'=' -f2)
```

**Rotation Calendar:**

- Document in `docs/BossCat/CREDENTIAL_ROTATION_CALENDAR.md`
- Automate with secrets manager (AWS Secrets Manager, Vault)

---

### 10. Correlation Best Practices

**Goal:** Link logs, metrics, and traces across bot operations.

**Pattern:**

1. **Generate correlation ID** at operation start (UUID v4)
2. **Propagate** via:
   - OTLP resource attributes (`bosscat.correlation_id`)
   - Log fields (`correlation_id`)
   - HTTP headers (`X-Correlation-ID`)
   - Evidence logs (`.agent/EVIDENCE.log`)
3. **Query** in SigNoz: Filter by `bosscat.correlation_id`

**Benefits:**

- ✅ End-to-end tracing across bots
- ✅ Debug complex workflows
- ✅ Audit compliance (link evidence to telemetry)

---

## 🚀 Quick Wins for Bot-Native Pipelines

### Immediate (Phase 1)

- [x] ✅ Default to HTTP/protobuf (not gRPC)
- [x] ✅ Create .env.template for configuration
- [x] ✅ Add explicit timeouts to all scripts
- [x] ✅ Document retry patterns

### Next (Phase 2)

- [ ] 📅 Add structured logging with trace context
- [ ] 📅 Create metric views for cardinality reduction
- [ ] 📅 Implement correlation IDs
- [ ] 📅 Enrich synthetic telemetry with business events

### Future (Phase 3)

- [ ] 📅 Modular collectors (dev/stage/prod)
- [ ] 📅 High-availability setup
- [ ] 📅 Secrets manager integration
- [ ] 📅 SOC 2 compliance mapping

---

## 📚 References

**SigNoz Documentation:**

- [OpenTelemetry Resource Center](https://signoz.io/resource-center/opentelemetry/)
- [Collector Setup Guide](https://signoz.io/docs/install/)
- [Logs Management (incl. log pipelines)](https://signoz.io/docs/logs-management/)

**OpenTelemetry:**

- [View API Documentation](https://opentelemetry.io/docs/specs/otel/metrics/sdk/#view)
- [Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/)
- [Collector Documentation (incl. security and configuration best practices)](https://opentelemetry.io/docs/collector/)

**BossCat Internal:**

- `AGENTS.md` / `docs/BossCat/CHARTER.md` — four-seat governance
- `docs/archive/BossCat/ECRR_PIPELINE_REBUILD_20251010.md` — Pipeline rebuild ECRR (archived)
- `.agent/config.json` — Lane configuration

---

## 🐾 BossCat Seal

**Authority:** BossCat OEM, Executive Overseer Manager  
**Organization:** MoneyCat Inc · Resonai [OTel]  
**Status:** ✅ APPROVED - Apply these patterns in all bot operations  
**Date:** 2025-10-10

---

**END OF BEST PRACTICES GUIDE.**

