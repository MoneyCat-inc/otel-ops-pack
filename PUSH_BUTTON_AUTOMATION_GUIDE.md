# Push-Button Automation System Guide

## 🎯 Overview

This is a **push-button, self-healing observability system** that proves the full path:

**[THIS PC] → [Cursor Agents] → Docker (OTel + SigNoz) → [THIS PC] UI**

The system automates every hop that has bitten us before, providing:
- **One-click bootstrap** for the entire development environment
- **Self-healing** Docker containers with healthchecks and auto-restart
- **Browser-level preflight** checks for COOP/COEP and mic constraints
- **Pitch pipeline correctness** validation with CREPE-tiny and fallbacks
- **Flow engine validation** for drill JSON and success metrics
- **Background autopilot** agent with budgets and kill-switch
- **CI gates** with SSOT reporting and merge protection
- **Pilot rollout** with feature flags and analytics

## 🚀 Quick Start

### One-Click Bootstrap

```powershell
# Start everything with one command
pwsh -File scripts/dev-up.ps1

# Or with custom options
pwsh -File scripts/dev-up.ps1 -WithTests -WaitSecs 45 -Verbose
```

This will:
1. ✅ Ensure Docker Desktop is running
2. ✅ Create Docker network (idempotent)
3. ✅ Start SigNoz stack with self-healing healthchecks
4. ✅ Wait for services to be healthy
5. ✅ Verify all required ports are accessible
6. ✅ Configure Windows OTel collector
7. ✅ Emit synthetic telemetry ping
8. ✅ Run deterministic smoke tests
9. ✅ Open SigNoz UI at http://localhost:8080

### Verify Full Stack

```powershell
# Comprehensive verification of the entire pipeline
pwsh -File scripts/verify-full-stack.ps1 -GenerateReport

# Check specific components
pwsh -File scripts/ci-verify.ps1 -CronMode
```

## 🛠️ Core Components

### 1. Development Bootstrap (`scripts/dev-up.ps1`)

**Purpose**: One-click environment setup with progress animation and error handling.

**Features**:
- Docker Desktop auto-start
- Self-healing container orchestration
- Port verification and health checks
- Synthetic telemetry emission
- Smoke test execution
- Progress animation with Unicode spinners

**Usage**:
```powershell
# Basic bootstrap
pwsh -File scripts/dev-up.ps1

# Skip tests for faster startup
pwsh -File scripts/dev-up.ps1 -WithTests:$false

# Custom wait time
pwsh -File scripts/dev-up.ps1 -WaitSecs 60

# Verbose output
pwsh -File scripts/dev-up.ps1 -Verbose
```

### 2. Self-Healing Docker (`docker-compose.yml`)

**Purpose**: Enhanced Docker Compose with healthchecks, restart policies, and proper networking.

**Features**:
- Healthchecks for all services (10s intervals, 10 retries)
- Automatic restart policies (`unless-stopped`)
- Proper service dependencies
- External network configuration
- Port mapping for Windows collector integration

**Services**:
- `signoz-clickhouse`: Database with healthcheck via `clickhouse-client`
- `signoz`: UI with healthcheck via `/api/v1/health`
- `otel-collector`: Collector with healthcheck via `/healthz`

### 3. Synthetic Telemetry (`scripts/otel_synthetic_ping.py`)

**Purpose**: Python script that emits OTLP logs, metrics, and traces to verify the pipeline.

**Features**:
- OTLP HTTP JSON envelope format
- Logs, metrics, and traces emission
- Retry logic with exponential backoff
- Configurable endpoint and count
- Comprehensive error handling

**Usage**:
```bash
# Single ping
python scripts/otel_synthetic_ping.py

# Multiple pings with interval
python scripts/otel_synthetic_ping.py --count 5 --interval 2.0

# Custom endpoint
python scripts/otel_synthetic_ping.py --endpoint http://localhost:5318

# Verbose output
python scripts/otel_synthetic_ping.py --verbose
```

### 4. Browser Preflight Tests (`tests/preflight/`)

**Purpose**: Playwright tests ensuring browser isolation and mic constraints for reliable trainer operation.

#### Browser Guarantees (`browser-guarantees.spec.ts`)
- Cross-origin isolation headers (COOP/COEP)
- Service worker offline isolation
- Microphone constraints (EC/NS/AGC = false)
- AudioWorklet context isolation
- CSP compliance
- Performance API availability

#### Pitch Pipeline (`pitch-pipeline.spec.ts`)
- CREPE-tiny ONNX model loading
- YIN fallback algorithm
- Octave error smoothing
- Pitch tracking stability with glides
- Phrase detection accuracy

#### Flow Engine (`flow-engine.spec.ts`)
- Drill JSON encoding and validation
- Gating logic and success thresholds
- Time-in-target calculation
- Smoothness metric calculation
- Confidence metric calculation
- Drill flow progression logic

**Usage**:
```bash
# Run all preflight tests
npm run test:preflight

# Run specific test suites
npm run test:browser
npm run test:pitch
npm run test:flow

# Run with Playwright UI
npx playwright test tests/preflight/ --ui
```

### 5. Autopilot Agent (`scripts/agent/`)

**Purpose**: Background worker that keeps the project healthy between commits.

#### Watchdog (`watchdog.ts`)
- Job scheduling and execution
- Budget enforcement (maxJobs, maxFiles, maxLines)
- Kill-switch via `.agent/LOCK` file
- Structured logging with rotation
- Health monitoring and reporting

#### Runner (`runner.ts`)
- Daemon mode support
- Signal handling (SIGTERM, SIGINT, SIGHUP)
- PID file management
- Status reporting

#### Configuration (`config.json`)
```json
{
  "maxJobs": 2,
  "maxFiles": 10,
  "maxLines": 200,
  "backoffMinutes": 15,
  "ttlHours": 12,
  "logLevel": "info"
}
```

**Usage**:
```bash
# Start autopilot agent
npm run agent:start

# Check agent status
npm run agent:status

# Stop agent
npm run agent:stop

# Health gate check
npm run agent:doctor
```

**Kill-Switch**:
```bash
# Pause agent operations
echo "Maintenance in progress" > .agent/LOCK

# Resume agent operations
rm .agent/LOCK
```

### 6. Full Stack Verification (`scripts/verify-full-stack.ps1`)

**Purpose**: Comprehensive verification of the entire observability pipeline.

**Components Verified**:
1. Docker Infrastructure
2. SigNoz Stack (containers, ClickHouse, UI)
3. OTel Pipeline (Windows collector, health endpoints, OTLP ports)
4. Synthetic Telemetry (ping script, SigNoz logs)
5. Browser Preflight (Playwright tests, COOP/COEP)
6. Autopilot Agent (files, lock mechanism, status)
7. Integration Test (end-to-end verification)

**Output**:
- JSON report: `artifacts/full-stack-verification.json`
- Human-readable summary: `artifacts/full-stack-verification-summary.txt`
- Overall status: PASS/WARN/FAIL

### 7. CI Gates and SSOT (`scripts/ci/`, `scripts/generate-ssot.mjs`)

**Purpose**: CI/CD pipeline with SSOT reporting and merge protection.

#### CI Workflow (`push-button-automation.yml`)
- **PR Lane**: Trimmed deterministic smokes (15 min timeout)
- **Nightly Lane**: Full coverage and SSOT (45 min timeout)
- **Merge Gate**: Only merge when artifacts agree
- **Pilot Rollout**: Feature flagged with analytics
- **Security Scan**: CSP and accessibility compliance

#### SSOT Generator (`generate-ssot.mjs`)
- Test results aggregation
- System health monitoring
- Artifact collection
- Overall status calculation
- Human-readable summary generation

**Usage**:
```bash
# Generate SSOT report
npm run generate:ssot

# Run CI verification
npm run test:smoke:ci
```

## 📊 Monitoring and Observability

### Quick Health Checks

```powershell
# Quick system status
npm run monitor:quick

# Full monitoring with ECRR reporting
npm run monitor:full

# Generate canary test data
npm run canary:test

# Verify integration
npm run canary:verify
```

### SigNoz Queries

**Logs**:
```
# Synthetic telemetry
log.body contains "synthetic"

# Canary tests
log.body contains "canary"

# Dataset filtering
attributes.dataset = "synthetic"
attributes.dataset = "ecrr-canary"
```

**Metrics**:
```
# Pipeline metrics
otelcol_*

# Synthetic metrics
synthetic_ping_counter
```

**Traces**:
```
# Synthetic traces
synthetic_ping_operation
```

### Key Endpoints

- **SigNoz UI**: http://localhost:8080
- **ClickHouse HTTP**: http://localhost:8123
- **ClickHouse Native**: localhost:9000
- **OTel Collector gRPC**: localhost:14317
- **OTel Collector HTTP**: localhost:14318
- **Windows Collector Health**: http://localhost:13134

## 🔧 Troubleshooting

### Common Issues

#### Docker Not Starting
```powershell
# Check Docker Desktop status
docker info

# Start Docker Desktop manually
Start-Process "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe"

# Wait and retry
Start-Sleep -Seconds 30
docker info
```

#### Port Conflicts
```powershell
# Check port usage
Get-NetTCPConnection -LocalPort 8080,8123,9000,14317,14318 -State Listen

# Kill conflicting processes
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

#### SigNoz Not Accessible
```powershell
# Check container health
docker ps --format "{{.Names}}\t{{.Status}}"

# Check container logs
docker logs signoz
docker logs signoz-clickhouse
docker logs signoz-otel-collector

# Restart services
docker compose restart
```

#### OTel Collector Issues
```powershell
# Check Windows service
Get-Service otelcol-contrib

# Check collector health
Invoke-WebRequest -Uri "http://localhost:13134" -TimeoutSec 10

# Check config
& "C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe" --config "C:\otel\config.yaml" --dry-run
```

#### Playwright Tests Failing
```bash
# Install Playwright browsers
npx playwright install

# Run tests with debug info
npx playwright test --debug

# Check browser isolation
npx playwright test tests/preflight/browser-guarantees.spec.ts --headed
```

### Debug Commands

```powershell
# Full system diagnostics
pwsh -File scripts/verify-full-stack.ps1 -Verbose

# Check autopilot agent
npm run agent:status

# View agent logs
Get-Content .agent/logs/watchdog-*.log -Tail 50

# Check lock file
Test-Path .agent/LOCK

# Manual synthetic ping
python scripts/otel_synthetic_ping.py --verbose --count 3
```

## 🎛️ Configuration

### Environment Variables

```powershell
# OTel Configuration
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:14318"
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"

# SigNoz API Token (for authenticated requests)
$env:SIGNOZ_API_TOKEN = "your-token-here"

# Pilot Rollout Configuration
$env:PILOT_ROLLOUT_PCT = "5"
$env:PILOT_COHORT = "early-adopters"
```

### Agent Configuration

Edit `.agent/config.json`:
```json
{
  "maxJobs": 2,
  "maxFiles": 10,
  "maxLines": 200,
  "backoffMinutes": 15,
  "ttlHours": 12,
  "logLevel": "info",
  "jobs": {
    "ssot-refresh": { "enabled": true, "priority": 1 },
    "flake-quarantine": { "enabled": true, "priority": 2 },
    "csp-lint": { "enabled": true, "priority": 3 },
    "a11y-check": { "enabled": true, "priority": 3 },
    "cleanup": { "enabled": true, "priority": 4 }
  }
}
```

## 🚀 Deployment

### Local Development

1. **Bootstrap**: `npm run dev-up`
2. **Verify**: `npm run verify-full-stack`
3. **Start Agent**: `npm run agent:start`
4. **Monitor**: `npm run monitor:quick`

### CI/CD Pipeline

1. **PR Checks**: Automatic on pull requests
2. **Nightly Builds**: Full coverage and SSOT
3. **Merge Gates**: Only when artifacts agree
4. **Pilot Rollout**: Feature flagged deployment

### Production Monitoring

1. **Health Checks**: Automated via autopilot agent
2. **Synthetic Monitoring**: Every 5 minutes
3. **Alert Thresholds**: Error rate >5%, TTV p95 >threshold
4. **Auto-Rollback**: On KPI degradation

## 📈 Metrics and KPIs

### Key Performance Indicators

- **TTV p50/p90**: Time to voice measurement
- **Mic-grant %**: Microphone access success rate
- **Activation %**: User activation rate
- **Error Rate**: Application error percentage
- **Pipeline Health**: OTel collector queue size, send failures

### Monitoring Dashboards

- **Error Rate**: 24h trend with threshold alerts
- **Top Patterns**: Log pattern analysis
- **Windows Event IDs**: Event log monitoring
- **Ingest Latency**: p95 pipeline latency
- **Log Volume**: By source and dataset

## 🔒 Security and Compliance

### Content Security Policy

- Strict CSP headers enforced
- No inline styles or scripts
- Worker-src and script-src properly configured
- Blob: and data: URLs allowed for audio processing

### Accessibility

- ARIA labels and live regions
- Keyboard navigation support
- Screen reader compatibility
- Color contrast compliance

### Privacy

- No audio data forwarded to external services
- PII redaction in logs and metrics
- Local-first architecture
- Graceful degradation when telemetry fails

## 📚 Additional Resources

### Documentation

- [ECRR Project Report](docs/ECRR_PROJECT_REPORT.md)
- [Comfort Cat Guidelines](docs/comfort-cat/)
- [Wiring Guide](docs/WIRING_GUIDE.md)
- [Query Recipes](docs/QUERY_RECIPES.md)

### Scripts Reference

- `scripts/dev-up.ps1` - One-click bootstrap
- `scripts/verify-full-stack.ps1` - Comprehensive verification
- `scripts/ci-verify.ps1` - CI verification
- `scripts/otel_synthetic_ping.py` - Synthetic telemetry
- `scripts/agent/watchdog.ts` - Autopilot agent
- `scripts/generate-ssot.mjs` - SSOT report generator

### Test Suites

- `tests/preflight/browser-guarantees.spec.ts` - Browser isolation
- `tests/preflight/pitch-pipeline.spec.ts` - Pitch detection
- `tests/preflight/flow-engine.spec.ts` - Flow engine

---

## 🎉 Success Criteria

The push-button automation system is successful when:

✅ **One command to up**: `npm run dev-up` starts everything  
✅ **Self-healing**: Containers restart automatically on failure  
✅ **Browser isolation**: COOP/COEP headers present, `crossOriginIsolated === true`  
✅ **Mic constraints**: EC/NS/AGC = false for deterministic audio  
✅ **Pitch correctness**: CREPE-tiny + YIN fallback + octave smoothing  
✅ **Flow validation**: Drill JSON + gating + success metrics  
✅ **CI gates**: PR smokes + nightly SSOT + merge protection  
✅ **Autopilot**: Background agent with budgets + kill-switch  
✅ **Observability**: Full pipeline verified with synthetic telemetry  

**The system proves the complete path: [THIS PC] → [Cursor Agents] → Docker (OTel + SigNoz) → [THIS PC] UI**




