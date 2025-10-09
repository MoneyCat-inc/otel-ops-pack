# GPU Health Signals for SigNoz
**Cat Nap Control Room - Resonai [OTel] - GPU Pattern-Sifter**

## Signal Types

### 1. GPU Fallback Events
**Signal Type**: `gpu_fallback`  
**Level**: `warn`  
**Trigger**: When GPU provider fails and falls back to CPU

**Query**:
```sql
SELECT * FROM logs 
WHERE service = 'gpu-pattern-sifter' 
  AND signal_type = 'gpu_fallback'
  AND timestamp >= now() - interval '1 hour'
ORDER BY timestamp DESC;
```

**Alert Rule**:
```yaml
- alert: GPUFallbackHigh
  expr: rate(gpu_fallback_total[5m]) > 0.1
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "High GPU fallback rate detected"
```

### 2. Parity Failures
**Signal Type**: `parity_failure`  
**Level**: `error`  
**Trigger**: When GPU/CPU results don't match within threshold

**Query**:
```sql
SELECT * FROM logs 
WHERE service = 'gpu-pattern-sifter' 
  AND signal_type = 'parity_failure'
  AND timestamp >= now() - interval '1 hour'
ORDER BY timestamp DESC;
```

**Alert Rule**:
```yaml
- alert: GPUParityFailure
  expr: rate(parity_failure_total[5m]) > 0
  for: 0m
  labels:
    severity: critical
  annotations:
    summary: "GPU/CPU parity failure detected"
```

### 3. Performance Regressions
**Signal Type**: `performance_regression`  
**Level**: `warn`  
**Trigger**: When performance degrades beyond threshold

**Query**:
```sql
SELECT * FROM logs 
WHERE service = 'gpu-pattern-sifter' 
  AND signal_type = 'performance_regression'
  AND timestamp >= now() - interval '24 hours'
ORDER BY timestamp DESC;
```

**Alert Rule**:
```yaml
- alert: GPUPerformanceRegression
  expr: rate(performance_regression_total[10m]) > 0.05
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "GPU performance regression detected"
```

### 4. Acceleration Success
**Signal Type**: `acceleration_success`  
**Level**: `info`  
**Trigger**: When GPU provides significant speedup

**Query**:
```sql
SELECT * FROM logs 
WHERE service = 'gpu-pattern-sifter' 
  AND signal_type = 'acceleration_success'
  AND timestamp >= now() - interval '1 hour'
ORDER BY timestamp DESC;
```

### 5. Provider Availability
**Signal Type**: `provider_availability`  
**Level**: `info`/`warn`  
**Trigger**: On provider availability changes

**Query**:
```sql
SELECT * FROM logs 
WHERE service = 'gpu-pattern-sifter' 
  AND signal_type = 'provider_availability'
  AND timestamp >= now() - interval '1 hour'
ORDER BY timestamp DESC;
```

## Dashboard Queries

### GPU Health Overview
```sql
SELECT 
  signal_type,
  level,
  COUNT(*) as event_count,
  AVG(acceleration_ratio) as avg_acceleration,
  MAX(regression_percent) as max_regression
FROM logs 
WHERE service = 'gpu-pattern-sifter' 
  AND timestamp >= now() - interval '24 hours'
GROUP BY signal_type, level
ORDER BY event_count DESC;
```

### Performance Trends
```sql
SELECT 
  algorithm,
  AVG(cpu_ms) as avg_cpu_ms,
  AVG(gpu_ms) as avg_gpu_ms,
  AVG(acceleration_ratio) as avg_acceleration
FROM logs 
WHERE service = 'gpu-pattern-sifter' 
  AND signal_type IN ('acceleration_success', 'performance_regression')
  AND timestamp >= now() - interval '7 days'
GROUP BY algorithm
ORDER BY avg_acceleration DESC;
```

### Fallback Rate by Algorithm
```sql
SELECT 
  algorithm,
  COUNT(*) as fallback_count,
  COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as fallback_percentage
FROM logs 
WHERE service = 'gpu-pattern-sifter' 
  AND signal_type = 'gpu_fallback'
  AND timestamp >= now() - interval '24 hours'
GROUP BY algorithm
ORDER BY fallback_count DESC;
```

## Monitoring Setup

### 1. Log Ingestion
Ensure GPU health signals are ingested into SigNoz:

```yaml
# In your OTel collector config
receivers:
  filelog:
    include: [ "/var/log/gpu-signals/*.log" ]
    operators:
      - type: json_parser
        parse_from: message

exporters:
  otlp:
    endpoint: http://signoz:4317

service:
  pipelines:
    logs:
      receivers: [filelog]
      exporters: [otlp]
```

### 2. Alert Rules
Create alert rules in SigNoz for critical GPU events:

```yaml
groups:
- name: gpu-health
  rules:
  - alert: GPUFallbackRate
    expr: rate(gpu_fallback_total[5m]) > 0.1
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High GPU fallback rate: {{ $value }} events/sec"
      
  - alert: GPUParityFailure
    expr: rate(parity_failure_total[5m]) > 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: "GPU/CPU parity failure detected"
      
  - alert: GPUPerformanceRegression
    expr: rate(performance_regression_total[10m]) > 0.05
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "GPU performance regression: {{ $value }} events/sec"
```

### 3. Dashboard Configuration
Create a GPU Health dashboard in SigNoz with:

- **Time Series**: GPU fallback rate, acceleration ratio, performance metrics
- **Logs Panel**: Recent GPU health signals
- **Alerts Panel**: Active GPU-related alerts
- **Heatmap**: Performance trends by algorithm and time

## Signal Examples

### Fallback Signal
```json
{
  "timestamp": "2025-10-04T04:00:00Z",
  "level": "warn",
  "service": "gpu-pattern-sifter",
  "signal_type": "gpu_fallback",
  "message": "GPU provider CUDAExecutionProvider failed, fell back to CPUExecutionProvider",
  "gpu_fallback": true,
  "requested_provider": "CUDAExecutionProvider",
  "actual_provider": "CPUExecutionProvider",
  "fallback_reason": "CUDA not available",
  "algorithm": "rolling",
  "metadata": {
    "evidence_ts": "2025-10-04T04:00:00.123Z",
    "kill_switch": false
  }
}
```

### Acceleration Success Signal
```json
{
  "timestamp": "2025-10-04T04:00:00Z",
  "level": "info",
  "service": "gpu-pattern-sifter",
  "signal_type": "acceleration_success",
  "message": "GPU acceleration successful in rolling: 2.50x speedup",
  "acceleration_success": true,
  "algorithm": "rolling",
  "cpu_ms": 5.0,
  "gpu_ms": 2.0,
  "acceleration_ratio": 2.5,
  "metadata": {
    "evidence_ts": "2025-10-04T04:00:00.123Z",
    "provider": "CuPyExecutionProvider"
  }
}
```

## Troubleshooting

### No Signals Appearing
1. Check if signals module is imported correctly
2. Verify logging configuration
3. Ensure SigNoz is receiving logs
4. Check for import errors in the harness scripts

### High Fallback Rate
1. Check GPU driver status: `nvidia-smi`
2. Verify CUDA installation: `nvcc --version`
3. Install missing GPU libraries: `pip install cupy-cuda12x`
4. Check kill-switch status: `Test-Path ".agent/LOCK"`

### Parity Failures
1. Review algorithm implementations for differences
2. Check floating-point precision settings
3. Verify input data consistency
4. Consider adjusting parity thresholds

---

*For more information, see the [BossCat GPU Pattern-Sifter documentation](../gpu/windows-cheats.md)*
