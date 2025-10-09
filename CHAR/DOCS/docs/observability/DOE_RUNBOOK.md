# DOE (Design of Experiments) Runbook for OTel Collector Optimization

## Overview

This runbook provides step-by-step instructions for conducting systematic experiments to optimize Windows OTel Collector performance using Design of Experiments methodology.

## Prerequisites

- Windows 11 with PowerShell 7.0+
- OTel Collector (`otelcol-contrib`) installed as Windows service
- SigNoz running on localhost:8080 with OTLP receiver on 14317/14318
- Experiment artifacts directory structure

## Quick Start

```powershell
# Generate and test batch plan
pwsh -File scripts/run-otel-doe.ps1 -DryRun

# Score sample data for testing
pwsh -File scripts/score-otel-doe.ps1 -SampleData

# Execute Stage-1 experiments
pwsh -File scripts/run-otel-doe.ps1 -Stage stage1 -Replicates 3 -Duration 300
```

## DOE Framework Components

### 1. Experiment Matrix (`experiments/doe/stage1-matrix.csv`)

The matrix defines factor combinations for systematic testing:

| Factor | Levels | Purpose |
|--------|--------|---------|
| `traces_timeout_ms` | 100, 200, 500 | Batch timeout for traces |
| `metrics_timeout_ms` | 500, 1000, 2000 | Batch timeout for metrics |
| `logs_timeout_ms` | 1000, 2000, 5000 | Batch timeout for logs |
| `send_batch_max_size` | 5000, 10000, 20000 | Maximum batch size |
| `queue_size` | 3000, 6000, 15000 | Export queue size |
| `num_consumers` | 1, 2, 4 | Export consumer threads |
| `memory_limit_mib` | 512, 1024, 2048 | Memory limit |
| `compression` | gzip, none | Export compression |
| `retry_max_elapsed_minutes` | 5, 10, 15 | Retry timeout |

### 2. Collector Template (`templates/collector-doe-template.yaml`)

Parameterized collector configuration with placeholders:
- `{{RUN_ID}}` - Unique experiment identifier
- `{{RUN_STAGE}}` - Experiment stage (stage1, stage2)
- `{{RUN_LABEL}}` - Matrix row label
- `{{EXPERIMENT_TIMESTAMP}}` - Experiment timestamp
- Factor placeholders for dynamic configuration

### 3. Run Harness (`scripts/run-otel-doe.ps1`)

Batch experiment executor with capabilities:
- Matrix parsing and config generation
- Randomized port assignment (5000-6000 range)
- Load generation integration
- Metrics collection
- Artifact organization

### 4. Scoring Tool (`scripts/score-otel-doe.ps1`)

SLO-based evaluation with weighted scoring:
- **Latency (30%)**: p95/p99 thresholds
- **Throughput (25%)**: events/second targets
- **Resource Usage (25%)**: CPU/memory limits
- **Reliability (20%)**: error rate/availability

## Stage-1: Initial Factor Screening

### Objective
Identify the most influential factors affecting collector performance.

### Execution Steps

1. **Prepare Environment**
   ```powershell
   # Ensure SigNoz is running
   docker ps | findstr signoz
   
   # Verify collector service is stopped
   sc query otelcol-contrib
   ```

2. **Generate Batch Plan**
   ```powershell
   pwsh -File scripts/run-otel-doe.ps1 -DryRun -Stage stage1
   ```

3. **Review Generated Plan**
   ```powershell
   # Check batch plan
   Get-Content artifacts/doe/stage1-YYYYMMDD-HHMMSS/batch-plan.json | ConvertFrom-Json | ConvertTo-Json -Depth 5
   
   # Verify config generation
   Get-ChildItem artifacts/doe/stage1-YYYYMMDD-HHMMSS/configs/ | Measure-Object
   ```

4. **Execute Experiments**
   ```powershell
   # Run Stage-1 with 3 replicates, 5-minute duration
   pwsh -File scripts/run-otel-doe.ps1 -Stage stage1 -Replicates 3 -Duration 300
   ```

5. **Monitor Progress**
   ```powershell
   # Check experiment status
   Get-Content artifacts/doe/stage1-YYYYMMDD-HHMMSS/batch-plan.json | ConvertFrom-Json | Select-Object -ExpandProperty runs | Group-Object status
   ```

### Expected Outputs

- **Configurations**: 72 configs (24 matrix rows × 3 replicates)
- **Duration**: ~6-8 hours for full Stage-1 execution
- **Artifacts**: Batch plan, metrics, logs, results

## Stage-2: Fine-Tuning Optimization

### Objective
Optimize the most influential factors identified in Stage-1 with focused experiments.

### Process

1. **Analyze Stage-1 Results**
   ```powershell
   # Extract real measurements from ClickHouse
   pwsh -File scripts/extract-doe-measurements.ps1 -ExperimentDir artifacts/doe/stage1-YYYYMMDD-HHMMSS
   
   # Score Stage-1 experiments with real data
   pwsh -File scripts/score-otel-doe-enhanced.ps1 -ExperimentDir artifacts/doe/stage1-YYYYMMDD-HHMMSS
   ```

2. **Generate Stage-2 Matrix**
   - Focus on top-performing factor ranges from Stage-1
   - Narrow factor levels to 2-3 most promising values
   - Increase replicates for statistical significance
   - Use `experiments/doe/stage2-focus.csv` as template

3. **Execute Stage-2**
   ```powershell
   # Run Stage-2 with focused matrix
   pwsh -File scripts/run-otel-doe.ps1 -Stage stage2 -Replicates 5 -Duration 600 -MatrixPath experiments/doe/stage2-focus.csv
   ```

4. **Stage-2 Analysis**
   ```powershell
   # Extract and score Stage-2 results
   pwsh -File scripts/extract-doe-measurements.ps1 -ExperimentDir artifacts/doe/stage2-YYYYMMDD-HHMMSS
   pwsh -File scripts/score-otel-doe-enhanced.ps1 -ExperimentDir artifacts/doe/stage2-YYYYMMDD-HHMMSS
   ```

## Measurement Schema

### SigNoz Queries for Data Extraction

#### Latency Metrics
```sql
-- p95 latency by run
SELECT 
    attributes['run.id'] as run_id,
    quantile(0.95)(attributes['duration_ms']) as p95_latency_ms
FROM traces 
WHERE timestamp >= now() - INTERVAL 5 MINUTE
  AND attributes['run.id'] IS NOT NULL
GROUP BY run_id
```

#### Throughput Metrics
```sql
-- Events per second by run
SELECT 
    attributes['run.id'] as run_id,
    count() / 300 as events_per_second
FROM logs 
WHERE timestamp >= now() - INTERVAL 5 MINUTE
  AND attributes['run.id'] IS NOT NULL
GROUP BY run_id
```

#### Error Rate
```sql
-- Error rate by run
SELECT 
    attributes['run.id'] as run_id,
    countIf(severity_text = 'ERROR') / count() * 100 as error_rate_percent
FROM logs 
WHERE timestamp >= now() - INTERVAL 5 MINUTE
  AND attributes['run.id'] IS NOT NULL
GROUP BY run_id
```

### System Metrics Collection

The harness automatically collects:
- CPU utilization via Performance Counters
- Memory usage via Performance Counters
- Collector heap metrics via pprof
- Process uptime and availability

## SLO Configuration

### Default SLOs (`config/slo-config.json`)

```json
{
  "latency": {
    "p95_ms": 100,
    "p99_ms": 500,
    "weight": 0.3
  },
  "throughput": {
    "events_per_second": 1000,
    "weight": 0.25
  },
  "resource_usage": {
    "cpu_percent": 80,
    "memory_mb": 1024,
    "weight": 0.25
  },
  "reliability": {
    "error_rate_percent": 1.0,
    "availability_percent": 99.5,
    "weight": 0.2
  }
}
```

### Customizing SLOs

Create `config/slo-config.json` to override defaults:
```json
{
  "latency": {
    "p95_ms": 50,
    "p99_ms": 200,
    "weight": 0.4
  },
  "throughput": {
    "events_per_second": 2000,
    "weight": 0.3
  }
}
```

## Load Generation

### Synthetic Load Script (`scripts/generate-synthetic-load.ps1`)

Expected parameters:
- `-Duration`: Experiment duration in seconds
- `-OTLPEndpoint`: OTLP HTTP endpoint URL
- `-RunId`: Unique run identifier
- `-Stage`: Experiment stage

### Load Patterns

1. **Baseline Load**: Steady 100 eps per signal type
2. **Spike Load**: Bursts of 1000 eps for 30 seconds
3. **Sustained Load**: Gradual ramp to 500 eps over 5 minutes

## Troubleshooting

### Common Issues

1. **Port Conflicts**
   ```
   Error: Address already in use
   Solution: Check for existing collectors, use different port range
   ```

2. **Config Generation Failures**
   ```
   Error: Template substitution failed
   Solution: Verify template syntax, check factor values in matrix
   ```

3. **Collector Startup Failures**
   ```
   Error: Health check failed
   Solution: Check config validity, verify SigNoz connectivity
   ```

4. **Metrics Collection Issues**
   ```
   Error: pprof endpoint unreachable
   Solution: Verify collector started with pprof extension enabled
   ```

### Debugging Commands

```powershell
# Check collector logs
Get-EventLog -LogName Application -Source otelcol-contrib -Newest 10

# Verify port availability
netstat -an | findstr :5317

# Test SigNoz connectivity
Invoke-RestMethod -Uri http://localhost:8080/api/v1/status

# Check experiment artifacts
Get-ChildItem artifacts/doe/ -Recurse | Sort-Object LastWriteTime -Descending
```

## Measurement Extraction

### Automated Measurement Collection

After experiment execution, extract real performance metrics from ClickHouse/SigNoz:

```powershell
# Extract measurements for completed experiments
pwsh -File scripts/extract-doe-measurements.ps1 -ExperimentDir artifacts/doe/stage1-YYYYMMDD-HHMMSS

# Score with real extracted data
pwsh -File scripts/score-otel-doe-enhanced.ps1 -ExperimentDir artifacts/doe/stage1-YYYYMMDD-HHMMSS
```

### ClickHouse Query Templates

The extraction script uses these queries to gather performance data:

#### Latency Metrics (p95/p99)
```sql
SELECT 
    attributes['run.id'] as run_id,
    quantile(0.95)(toFloat64(attributes['duration_ms'])) as p95_latency_ms
FROM traces 
WHERE timestamp >= now() - INTERVAL 10 MINUTE
  AND attributes['run.id'] IS NOT NULL
  AND attributes['duration_ms'] IS NOT NULL
GROUP BY run_id
```

#### Throughput Metrics
```sql
SELECT 
    attributes['run.id'] as run_id,
    count() / 10 as events_per_second
FROM logs 
WHERE timestamp >= now() - INTERVAL 10 MINUTE
  AND attributes['run.id'] IS NOT NULL
GROUP BY run_id
```

#### Error Rate
```sql
SELECT 
    attributes['run.id'] as run_id,
    countIf(severity_text = 'ERROR') / count() * 100 as error_rate_percent
FROM logs 
WHERE timestamp >= now() - INTERVAL 10 MINUTE
  AND attributes['run.id'] IS NOT NULL
GROUP BY run_id
```

### Measurement Files Structure

Extracted measurements are saved as `*-measurements.json`:

```json
{
  "runId": "row01-r1-20250921-190700",
  "runLabel": "row01",
  "replicate": 1,
  "timestamp": "2025-09-21T19:07:00.000Z",
  "latency": {
    "p95_ms": 85.2,
    "p99_ms": 420.1
  },
  "throughput": {
    "events_per_second": 1200.5
  },
  "reliability": {
    "error_rate_percent": 0.2,
    "availability_percent": 99.8
  },
  "resource_usage": {
    "cpu_percent": 65.3,
    "memory_mb": 480.7
  },
  "factors": { /* experiment factors */ }
}
```

## Results Analysis

### CSV Output Format

The enhanced scoring tool generates `doe-scores.csv` with columns:
- `rank`: Overall ranking (1 = best)
- `runId`, `runLabel`, `replicate`: Run identification
- `overall_score`: Weighted composite score
- `*_score`: Individual SLO component scores
- `slo_violations`: List of violated SLOs
- `*_ms`, `*_eps`, `*_percent`: Raw performance metrics
- Factor columns: All experimental factors

### Interpretation Guidelines

1. **High Overall Score**: Meets all SLOs with good performance
2. **SLO Violations**: Critical issues requiring attention
3. **Factor Analysis**: Identify patterns in top-performing configurations
4. **Statistical Significance**: Consider replicate variation

### Stage-2 Matrix Creation

Based on Stage-1 results, create focused experiments:

```powershell
# Analyze top performers to identify optimal factor ranges
$topRuns = Import-Csv doe-enhanced-scores.csv | Where-Object { $_.rank -le 5 }

# Create Stage-2 matrix with narrowed factor ranges
# Focus on: traces_timeout_ms (100-200), batch sizes (5000-10000), compression (gzip/none)
```

### Next Steps

1. **Extract Real Measurements**: Run measurement extraction after experiments
2. **Factor Importance**: Rank factors by performance impact
3. **Optimal Ranges**: Identify promising factor value ranges
4. **Stage-2 Planning**: Design focused experiments with narrowed ranges
5. **Production Deployment**: Apply winning configuration

## Automation Integration

### Scheduled Execution

```powershell
# Weekly DOE execution
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File C:\otel\scripts\run-otel-doe.ps1 -Stage stage1"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2AM
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "DOE-Stage1-Weekly"
```

### CI/CD Integration

```yaml
# .github/workflows/doe-validation.yml
- name: Run DOE Validation
  run: |
    pwsh -File scripts/run-otel-doe.ps1 -DryRun
    pwsh -File scripts/score-otel-doe.ps1 -SampleData
```

## References

- [OpenTelemetry Collector Configuration](https://opentelemetry.io/docs/collector/configuration/)
- [SigNoz Query Documentation](https://signoz.io/docs/userguide/query-builder/)
- [Design of Experiments Principles](https://en.wikipedia.org/wiki/Design_of_experiments)
- [Statistical Process Control](https://en.wikipedia.org/wiki/Statistical_process_control)