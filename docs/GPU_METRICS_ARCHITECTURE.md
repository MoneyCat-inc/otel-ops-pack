# GPU Metrics Architecture

## Overview

This document describes the GPU metrics collection architecture for the Resonai OTel observability pipeline. The system collects GPU utilization, memory usage, and temperature metrics from NVIDIA GPUs and forwards them to SigNoz via OpenTelemetry.

## Architecture

```
GPU Hardware → pynvml → Python OTel SDK → OTLP/HTTP → SigNoz Collector → ClickHouse → SigNoz UI
```

### Components

1. **GPU Metrics Emitter** (`gpu-metrics-emitter.py`)
   - Uses `pynvml` to query NVIDIA GPU metrics
   - Implements OpenTelemetry Python SDK with current API
   - Sends metrics via OTLP/HTTP to collector
   - Runs as a bounded-duration process (default 120s)

2. **SigNoz OTel Collector**
   - Receives OTLP metrics on port 4318 (HTTP) and 4317 (gRPC)
   - Batches and forwards to ClickHouse
   - Runs in Docker container on `otel_default` network

3. **ClickHouse Database**
   - Stores metrics in `signoz_metrics` database
   - Part of SigNoz stack running on `otel_default` network

4. **SigNoz UI**
   - Provides visualization and querying interface
   - Accessible at `http://localhost:8080`

## Key Design Decisions

### No Prometheus Scraping
- **Decision**: Direct OTLP/HTTP integration instead of Prometheus scraping
- **Rationale**: 
  - Eliminates Prometheus dependency
  - Reduces complexity and resource usage
  - Provides real-time metrics without polling overhead
  - Better integration with SigNoz native OTLP support

### Current OTel Python API
- **Decision**: Use `create_observable_gauge()` with callbacks at creation time
- **Rationale**:
  - Follows current OpenTelemetry Python SDK patterns
  - Avoids deprecated `.add_callback()` method
  - Returns `Observation` objects for proper metric values

### Bounded Execution
- **Decision**: Run emitter for fixed duration (120s default)
- **Rationale**:
  - Prevents long-running processes
  - Allows for testing and validation
  - Can be scheduled via cron or Windows Task Scheduler

## Metrics Collected

| Metric Name | Type | Unit | Description |
|-------------|------|------|-------------|
| `gpu.utilization.percent` | Observable Gauge | percent | GPU SM utilization |
| `gpu.memory.used.bytes` | Observable Gauge | By | Used VRAM |
| `gpu.memory.total.bytes` | Observable Gauge | By | Total VRAM |
| `gpu.temperature.celsius` | Observable Gauge | Cel | GPU temperature |

### Attributes
- `gpu.index`: GPU device index (0, 1, 2, ...)
- `gpu.name`: GPU device name (e.g., "NVIDIA GeForce RTX 4090")

## Usage

### Basic Usage
```bash
python gpu-metrics-emitter.py
```

### Advanced Usage
```bash
python gpu-metrics-emitter.py --endpoint http://localhost:4318/v1/metrics --duration 60 --interval 5
```

### Parameters
- `--endpoint`: OTLP HTTP endpoint (default: `http://localhost:4318/v1/metrics`)
- `--duration`: Duration in seconds (default: 120)
- `--interval`: Export interval in seconds (default: 10)

## SigNoz Queries

### View GPU Metrics
```sql
-- GPU Utilization
SELECT * FROM signoz_metrics WHERE metric_name = 'gpu.utilization.percent'

-- GPU Memory Usage
SELECT * FROM signoz_metrics WHERE metric_name = 'gpu.memory.used.bytes'

-- GPU Temperature
SELECT * FROM signoz_metrics WHERE metric_name = 'gpu.temperature.celsius'
```

### Filter by GPU
```sql
-- Specific GPU
SELECT * FROM signoz_metrics WHERE metric_name = 'gpu.utilization.percent' AND gpu.index = '0'
```

## Troubleshooting

### Common Issues

1. **"No GPU found"**
   - Ensure NVIDIA drivers are installed
   - Verify `pynvml` can access GPU: `python -c "import pynvml; pynvml.nvmlInit(); print(pynvml.nvmlDeviceGetCount())"`

2. **"Connection refused" on port 4318**
   - Check if SigNoz collector is running: `docker ps | grep signoz-otel-collector`
   - Verify port is open: `Test-NetConnection localhost 4318`

3. **Metrics not appearing in SigNoz**
   - Check collector logs: `docker logs signoz-otel-collector`
   - Verify ClickHouse connectivity: `docker logs signoz-clickhouse`
   - Check SigNoz UI: `http://localhost:8080`

### Verification Commands

```powershell
# Check collector status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | findstr signoz-otel-collector

# Test OTLP endpoint
Test-NetConnection -ComputerName localhost -Port 4318

# Check collector logs
docker logs --since 2m signoz-otel-collector

# Run GPU emitter test
python gpu-metrics-emitter.py --duration 30
```

## Dependencies

### Python Packages
- `opentelemetry-api`
- `opentelemetry-sdk`
- `opentelemetry-exporter-otlp-proto-http`
- `pynvml`

### System Requirements
- NVIDIA GPU with supported drivers
- Docker Desktop with SigNoz stack running
- PowerShell 7 (for Windows scheduled tasks)

## Future Enhancements

1. **Multi-GPU Support**: Already implemented with `gpu.index` attribute
2. **Custom Metrics**: Add GPU-specific metrics (power consumption, clock speeds)
3. **Alerting**: Set up SigNoz alerts for high GPU utilization/temperature
4. **Dashboard**: Create dedicated GPU monitoring dashboard in SigNoz
5. **Scheduling**: Integrate with Windows Task Scheduler for continuous monitoring