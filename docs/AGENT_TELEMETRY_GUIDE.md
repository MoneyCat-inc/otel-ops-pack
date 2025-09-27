# Agent Telemetry Guide

## Overview

The OpenTelemetry instrumentation for the Resonai agent system provides comprehensive observability for the watchdog/runner and flake-quarantine pipeline. This guide covers setup, configuration, and usage.

## Architecture

```
Agent Worker → OTel SDK → OTLP HTTP → Dev Collector → Jaeger/Zipkin/Prometheus
```

### Components

- **Agent Worker**: Background autopilot system with job queue management
- **Flake Quarantine**: Test flakiness detection and quarantine system
- **OTel SDK**: Node.js instrumentation with traces, metrics, and logs
- **Dev Collector**: Local OpenTelemetry collector for development
- **Exporters**: Jaeger, Zipkin, Prometheus for visualization

## Quick Start

### 1. Start the Development Collector

```powershell
# Start basic collector
pwsh -File otel/start-dev-collector.ps1

# Start with all services (Jaeger, Zipkin, Prometheus, Grafana)
pwsh -File otel/start-dev-collector.ps1 -All
```

### 2. Configure Environment

```powershell
# Copy environment template
cp scripts/agent/.env.example .env

# Edit configuration
notepad .env
```

Key environment variables:
- `OTEL_ENABLED=1` - Enable telemetry
- `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318` - Collector endpoint
- `OTEL_SERVICE_NAME=resonai-agent` - Service name

### 3. Start the Agent

```powershell
# Start agent with telemetry
$env:OTEL_ENABLED="1"
node scripts/agent/runner.ts start

# Or use npm script
npm run agent:start
```

## Telemetry Specifications

### Traces

#### Agent Queue Tick
- **Span**: `agent.queue.tick`
- **Attributes**:
  - `queue.depth`: Current job queue length
  - `agent.max_jobs`: Maximum concurrent jobs
  - `agent.lock_present`: Boolean lock file status
  - `agent.config.max_files`: File limit per job
  - `agent.config.max_lines`: Line limit per job

#### Job Execution
- **Span**: `agent.job.run`
- **Attributes**:
  - `job.id`: Unique job identifier
  - `job.type`: Job type (ssot-refresh, flake-quarantine, etc.)
  - `job.attempt`: Retry attempt number
  - `job.ttl_ms`: Time-to-live in milliseconds

### Metrics

#### Job Processing (Meter: `resonai.agent`)
- `jobs_processed_total{job_type}` - Counter
- `jobs_failed_total{job_type}` - Counter
- `job_retries_total{job_type}` - Counter
- `job_duration_ms{job_type}` - Histogram
- `queue_depth` - ObservableGauge

#### Flake Detection (Meter: `resonai.ci.flake`)
- `flake_detected_total{test_id,suite,browser,branch,reason}` - Counter
- `flake_quarantined_total{test_id,suite,browser,branch}` - Counter
- `flake_reoffended_total{test_id,suite,browser,branch}` - Counter
- `flake_rehabilitated_total{test_id,suite,browser,branch}` - Counter
- `ci.flaky_tests.count` - ObservableGauge
- `test.flake_status{test_id,suite,browser,branch}` - ObservableGauge
- `test.flake_age_days{test_id,suite,browser,branch}` - ObservableGauge

## Usage Examples

### Running Individual Components

```powershell
# Test flake quarantine with telemetry
node scripts/agent/flake-quarantine.ts

# Emit nightly flake gauges
node scripts/agent/emit-flake-gauges.ts

# Start watchdog with telemetry
node scripts/agent/watchdog.ts start
```

### Viewing Telemetry

#### Jaeger (Distributed Tracing)
1. Open http://localhost:16686
2. Select `resonai-agent` service
3. View traces for agent operations

#### Zipkin (Distributed Tracing)
1. Open http://localhost:9411
2. Search for `resonai-agent` traces

#### Prometheus (Metrics)
1. Open http://localhost:9090
2. Query metrics:
   - `jobs_processed_total`
   - `queue_depth`
   - `flake_detected_total`

#### Grafana (Dashboards)
1. Open http://localhost:3000 (admin/admin)
2. Import dashboards or create custom ones

## Configuration

### Collector Configuration

The development collector is configured in `otel/collector.dev.yaml`:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

exporters:
  logging: # Console output for debugging
  jaeger:  # Distributed tracing
  zipkin:  # Distributed tracing
  prometheus: # Metrics
```

### Agent Configuration

Agent settings in `.agent/config.json`:

```json
{
  "max_jobs_per_run": 3,
  "max_files_per_job": 15,
  "max_lines_per_job": 500,
  "flake_quarantine": {
    "threshold": 0.3,
    "min_runs": 5
  }
}
```

## Troubleshooting

### Common Issues

#### Telemetry Not Appearing
1. Check `OTEL_ENABLED=1` in environment
2. Verify collector is running: `docker ps`
3. Check collector logs: `docker logs otel-dev-collector`

#### Port Conflicts
1. Default ports: 4317 (gRPC), 4318 (HTTP), 16686 (Jaeger), 9411 (Zipkin)
2. Check for conflicts: `netstat -an | findstr :4318`
3. Modify ports in `otel/collector.dev.yaml` if needed

#### High Memory Usage
1. Adjust batch processor settings in collector config
2. Reduce metric export frequency
3. Enable memory limiter processor

### Debug Commands

```powershell
# Check collector health
curl http://localhost:13133/

# View collector metrics
curl http://localhost:8889/metrics

# Check agent status
node scripts/agent/runner.ts status

# View agent logs
Get-Content .agent/logs/watchdog-*.log -Tail 50
```

## Privacy and Security

### Data Filtering

The collector automatically filters sensitive data:
- HTTP authorization headers
- Cookies
- User email/name attributes

### Local-First Design

- No external cloud dependencies
- All telemetry stays local
- Optional export to external systems
- Graceful degradation when collector unavailable

## Integration with SSOT

The telemetry system integrates with the Single Source of Truth (SSOT) reporting:

- Agent metrics appear in SSOT summaries
- Flake statistics tracked over time
- Performance trends visible in reports
- Automated alerting on anomalies

## Development Workflow

### Adding New Telemetry

1. **Define Metrics**: Add to `scripts/agent/otel.ts`
2. **Instrument Code**: Add spans/metrics to relevant functions
3. **Test Locally**: Use dev collector to verify
4. **Document**: Update this guide with new metrics

### Testing Telemetry

```powershell
# Generate test data
node scripts/agent/flake-quarantine.ts

# Verify in Jaeger
# Check metrics in Prometheus
# Validate in Grafana
```

## Production Considerations

### Scaling

- Use batch processors for high-volume metrics
- Configure memory limits appropriately
- Monitor collector resource usage
- Set up alerting on collector health

### Reliability

- Implement retry logic for telemetry failures
- Use circuit breakers for external dependencies
- Maintain graceful degradation
- Monitor telemetry system itself

### Security

- Use TLS for external collectors
- Implement proper authentication
- Filter sensitive data at source
- Audit telemetry access

## References

- [OpenTelemetry Node.js SDK](https://opentelemetry.io/docs/instrumentation/js/)
- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [Prometheus Metrics](https://prometheus.io/docs/concepts/metric_types/)
