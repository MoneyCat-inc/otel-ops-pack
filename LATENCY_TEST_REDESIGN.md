# Latency Test Redesign

## Overview

The latency test system has been redesigned to address gaps in the original DOE harness, focusing on real latency measurements, parallel execution, and fail-fast behavior.

## Key Improvements

### 1. Pre-flight "Latency Ready" Check

**Script**: `scripts/check-latency-readiness.ps1`

- Validates ClickHouse connectivity and collector health

- Includes 60-second smoke mode for quick validation

- Fails fast if prerequisites are not met
```powershell

# Basic readiness check

pwsh -File scripts/check-latency-readiness.ps1

# With smoke test

pwsh -File scripts/check-latency-readiness.ps1 -SmokeMode
```

### 2. Enhanced Latency Measurement Extraction

**Script**: `scripts/extract-latency-measurements.ps1`

- Fails immediately if no data found (no fallback values)

- Extracts from traces (preferred) or logs with duration attributes

- Includes baseline comparison with regression detection

- Supports both single runs and batch processing
```powershell

# Extract for specific run

pwsh -File scripts/extract-latency-measurements.ps1 -RunId test-run-001

# Extract for entire experiment

pwsh -File scripts/extract-latency-measurements.ps1 -ExperimentDir artifacts/doe/stage1-20250921-190945
```

### 3. Parallel DOE Execution

**Script**: `scripts/run-otel-doe-enhanced.ps1`

- Replaces sequential `foreach` with `ForEach-Object -Parallel`

- Configurable parallelism (default: 2 workers)

- Stage budgets to stop early when SLA is met

- Immediate latency assertions after each run
```powershell

# Run with 3 parallel workers and 90-second stage budgets

pwsh -File scripts/run-otel-doe-enhanced.ps1 -Parallelism 3 -StageBudget 90

# Smoke test (60 seconds)

pwsh -File scripts/run-otel-doe-enhanced.ps1 -SmokeMode
```

### 4. Baseline Management

**Script**: `scripts/manage-latency-baselines.ps1`

- Create, update, and compare latency baselines

- Automatic regression detection with configurable thresholds

- SLA compliance checking
```powershell

# Create baseline from control run

pwsh -File scripts/manage-latency-baselines.ps1 -Action create -SourceRunId control-r1-20250921-190945

# Compare run against baseline

pwsh -File scripts/manage-latency-baselines.ps1 -Action compare -SourceRunId test-run-001
```

### 5. Regression Monitoring

**Script**: `scripts/monitor-latency-regressions.ps1`

- Monitors experiment results for latency regressions

- Multiple output formats: JSON, text, Prometheus

- Configurable alert thresholds

- Severity levels: critical, high, medium

### 6. Integrated Orchestration

**Script**: `scripts/integrate-latency-testing.ps1`

- Single entrypoint for setup, smoke tests, full DOE runs, and monitoring

- Propagates non-zero exit codes for CI/CD so failures halt immediately

- Surfaces next-step commands after status checks for faster iteration
```powershell

# Monitor with text output

pwsh -File scripts/monitor-latency-regressions.ps1 -ExperimentDir artifacts/doe/latest

# JSON output for automation

pwsh -File scripts/monitor-latency-regressions.ps1 -ExperimentDir artifacts/doe/latest -OutputFormat json
```

## Usage Examples

### Quick Start
```powershell

# Check system status

pwsh -File scripts/integrate-latency-testing.ps1 -Action status

# Run complete example

pwsh -File scripts/run-latency-test-example.ps1
```

### Production Workflow

1. **System status check**:

   ```powershell

   pwsh -File scripts/integrate-latency-testing.ps1 -Action status

   ```

2. **Pre-flight check**:

   ```powershell

   pwsh -File scripts/check-latency-readiness.ps1 -SmokeMode

   ```

3. **Create baseline** (first time only):

   ```powershell

   pwsh -File scripts/manage-latency-baselines.ps1 -Action create -SourceRunId control-run-001

   ```

4. **Run experiment**:

   ```powershell

   pwsh -File scripts/run-otel-doe-enhanced.ps1 -Parallelism 3 -StageBudget 120 -LatencySLA 200

   ```

5. **Monitor regressions**:

   ```powershell

   pwsh -File scripts/monitor-latency-regressions.ps1 -ExperimentDir artifacts/doe/latest

   ```

### Integrated Workflow

For streamlined operation, use the integration script:

```powershell

# Setup system

pwsh -File scripts/integrate-latency-testing.ps1 -Action setup

# Run smoke test

pwsh -File scripts/integrate-latency-testing.ps1 -Action test -TestType smoke

# Run full experiment

pwsh -File scripts/integrate-latency-testing.ps1 -Action test -TestType full -Parallelism 3

# Monitor for regressions

pwsh -File scripts/integrate-latency-testing.ps1 -Action monitor

```

## Configuration

### Environment Variables

- `CLICKHOUSE_ENDPOINT`: ClickHouse HTTP endpoint (default: http://localhost:8123)

- `SIGNOZ_ENDPOINT`: SigNoz API endpoint (default: http://localhost:8080)

- `COLLECTOR_HEALTH_ENDPOINT`: Collector health endpoint (default: http://localhost:13134)

### Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `-Parallelism` | 2 | Number of parallel workers |
| `-StageBudget` | 120 | Maximum duration per stage (seconds) |
| `-LatencySLA` | 200 | Latency SLA threshold (milliseconds) |
| `-AlertThreshold` | 10 | Regression alert threshold (percentage) |

## File Structure
```
scripts/
|-- check-latency-readiness.ps1      # Pre-flight checks
|-- extract-latency-measurements.ps1 # Enhanced latency extraction
|-- run-otel-doe-enhanced.ps1        # Parallel DOE execution
|-- manage-latency-baselines.ps1     # Baseline management
|-- monitor-latency-regressions.ps1  # Regression monitoring
|-- run-latency-test-example.ps1     # Complete example
|-- integrate-latency-testing.ps1    # Integrated orchestration

artifacts/doe/
|-- baselines/
|   `-- latency.json                 # Baseline latency data
|-- stage1-20250921-190945/          # Experiment results
|   |-- batch-plan.json
|   |-- experiment-summary.json
|   |-- configs/                     # Generated configs
|   |-- results/                     # Run results
|   `-- logs/                        # Run logs
`-- latency-alerts.json              # Regression alerts
```

## Monitoring Integration

### Prometheus Metrics

The monitoring script can output Prometheus metrics:
```powershell

pwsh -File scripts/monitor-latency-regressions.ps1 -OutputFormat prometheus
```

Metrics include:

- `doe_latency_p95_milliseconds`: Average p95 latency

- `doe_regressions_total`: Number of regressions

- `doe_sla_violations_total`: Number of SLA violations

### Alert Integration

Alerts are saved to `artifacts/doe/latency-alerts.json` with:

- Run details and regression percentages

- Severity levels (critical/high/medium)

- Factor information for debugging

## Troubleshooting

### Common Issues

1. **No latency data found**:

   - Ensure traces are being generated (not just logs)

   - Check ClickHouse connectivity

   - Verify run IDs are properly tagged

2. **Pre-flight checks fail**:

   - Ensure SigNoz is running

   - Check collector service status

   - Verify port accessibility

3. **Parallel execution issues**:

   - Reduce parallelism if system is overloaded

   - Check for port conflicts

   - Monitor system resources

### Debug Commands
```powershell

# Check system status

pwsh -File scripts/check-latency-readiness.ps1 -SmokeMode

# Test single run extraction

pwsh -File scripts/extract-latency-measurements.ps1 -RunId test-run-001

# List available baselines

pwsh -File scripts/manage-latency-baselines.ps1 -Action list
```

## Performance Improvements

### Before (Original System)

- Sequential execution: 5 minutes x N runs

- Fallback values when data missing

- No early termination

- No regression detection

### After (Enhanced System)

- Parallel execution: ~2-3 minutes for 3 runs

- Fail-fast on missing data

- Early termination when SLA met

- Real-time regression monitoring with integration script that halts on first failure

- 60-second smoke tests

## Next Steps

1. **Integrate with CI/CD**: Add regression monitoring to build pipelines

2. **Expand metrics**: Add more latency percentiles and error rates

3. **Automated baselines**: Auto-update baselines from control runs

4. **Dashboard integration**: Connect to SigNoz dashboards

5. **Alerting**: Integrate with notification systems

## Migration Guide

To migrate from the original system:

1. **Replace calls**:

   ```powershell

   # Old

   pwsh -File scripts/run-otel-doe.ps1

   

   # New

   pwsh -File scripts/run-otel-doe-enhanced.ps1

   ```

2. **Update extraction**:

   ```powershell

   # Old

   pwsh -File scripts/extract-doe-measurements.ps1

   

   # New

   pwsh -File scripts/extract-latency-measurements.ps1

   ```

3. **Add monitoring**:

   ```powershell

   # New

   pwsh -File scripts/monitor-latency-regressions.ps1

   ```

The enhanced system is backward compatible and can run alongside the original system during migration.

