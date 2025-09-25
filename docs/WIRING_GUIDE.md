# OTel Pipeline Wiring Guide

This guide documents the complete end-to-end wiring of the OTel observability pipeline.

## Quick Reference

- **Host Apps -> SigNoz**: See [OTLP_HOST_WIRING.md](OTLP_HOST_WIRING.md) for direct OTLP wiring
- **Windows Collector -> SigNoz**: Standard pipeline configuration below
- **Verification**: Use `scripts/test-otlp-wiring.ps1` for smoke testing

## Quick Start

```bash
# Initialize the complete wiring system
pnpm wire:init

# Verify all components are properly configured
pnpm wire:verify

# Check pipeline health
pnpm wire:health

# Start background agent (optional)
pnpm agent:start

# Check agent health
pnpm agent:doctor
```

## Architecture

### Agent Infrastructure

- **Max Jobs**: 2 concurrent jobs
- **Max Files**: 10 files per job
- **Max Lines**: 200 lines per job
- **Kill Switch**: Create `.agent/LOCK` to pause operations

### ECRR Integration

- Ingests reports from `ecrr/reports/`
- Extracts gaps and recommendations
- Generates actionable tasks
- Maintains index and backlog

### Health Monitoring

- Docker services (SigNoz containers)
- Windows OTel Collector service
- SigNoz health endpoints
- Agent infrastructure

## Components

### OTLP Host App Wiring

For direct host application -> SigNoz wiring (bypassing Windows collector):

**Quick Test:**
```powershell
# Run automated smoke test
pwsh -File scripts/test-otlp-wiring.ps1 -ServiceName "my-app"

# Manual setup
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4318"
$env:OTEL_SERVICE_NAME = "my-service"
```

**Endpoints:**
- HTTP: `http://127.0.0.1:4318/v1/traces`
- gRPC: `127.0.0.1:4317`

**Verification:**
1. SigNoz UI -> Traces -> Search -> Filter: `resource.service.name = 'my-service'`
2. Look for spans with your application's service name

See [OTLP_HOST_WIRING.md](OTLP_HOST_WIRING.md) for complete documentation.

### IONA Supervisor Integration

The IONA Supervisor instrumentation sends job lifecycle metrics and optional traces into SigNoz through the Windows collector.

**Endpoints**
- Metrics: `http://localhost:5318/v1/metrics`
- Traces: `http://localhost:5318/v1/traces`

**Key Metrics**
- `iona_jobs_completed_total{mode="*"}` — counter for completed jobs per mode
- `iona_jobs_failed_total{mode="*"}` — counter for failed jobs with error breakdowns
- `iona_jobs_running{mode="*"}` — gauge for currently executing jobs
- `iona_jobs_queued{mode="*"}` — gauge for pending work in the queue
- `iona_job_duration_ms` — histogram capturing job execution latency

**Scripts**
- `scripts/metrics.ps1` — helper functions (`Send-IonaMetric`, `Send-IonaSpan`, `Test-IonaMetricsEndpoint`)
- `scripts/iona-supervisor-runner.ps1` — demo runner that emits lifecycle metrics, histograms, and traces

**Quick Start**
```powershell
# Load helper functions
. .\scripts\metrics.ps1

# Smoke-test connectivity (writes probe metric)
Test-IonaMetricsEndpoint

# Run demo workload with tracing enabled
pwsh -File .\scripts\iona-supervisor-runner.ps1 -JobCount 5 -EnableTracing
```

**SigNoz Verification**
1. SigNoz UI -> Metrics -> Explorer
2. Query: `sum(rate(iona_jobs_completed_total{mode!=""}[5m])) by (mode)`
3. Add panels for success rate, duration p95, queue depth using the queries in `docs/QUERY_RECIPES.md`
4. SigNoz UI -> Traces -> Search -> Filter `service.name = "iona-supervisor"`

**Dashboard**
- Import `artifacts/iona-supervisor-dashboard.json` for ready-made panels covering throughput, success rate, latency p95, queue depth, and active jobs.

### Wiring Scripts

- `scripts/wire/init.mjs` - Initialize infrastructure
- `scripts/wire/verify.mjs` - Verify components
- `scripts/wire/health-check.mjs` - Health monitoring

### Agent System

- `scripts/agent/watchdog.js` - Background agent
- `scripts/agent/doctor.mjs` - Health diagnostics

### ECRR System

- `scripts/ecrr/wire.mjs` - Report processing

## Usage

### Daily Operations

```bash
pnpm wire:health
pnpm agent:doctor
pnpm ecrr:wire
```

### Agent Management

```bash
pnpm agent:start
echo > .agent/LOCK  # pause
rm .agent/LOCK      # resume
```

## Configuration

### Agent Config (`.agent/config.json`)

```json
{
  "maxJobs": 2,
  "maxFiles": 10,
  "maxLines": 200,
  "jobTtlMs": 43200000,
  "maxAttempts": 3,
  "backoffMs": 900000
}
```

## Troubleshooting

### Common Issues

1. **Agent not starting** - Check Node.js version (18+)
2. **Health checks failing** - Verify Docker/SigNoz services
3. **ECRR reports not processing** - Check report format
4. **Agent jobs failing** - Review job queue status

### Debug Commands

```bash
cat .agent/state.json
cat .agent/agent_queue.json
ls -la artifacts/
cat ecrr/index.json
```

## Best Practices

1. **Respect budgets** - Never exceed limits
2. **Use kill-switch** - Create `.agent/LOCK` when needed
3. **Monitor health** - Run `pnpm agent:doctor` regularly
4. **Review reports** - Check artifacts for insights

## Security

- Agent runs with local permissions only
- No external network access required
- Kill-switch provides immediate control
- All operations are logged and auditable

