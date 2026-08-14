# Current Architecture - Direct-to-SigNoz

**Status**: ✅ **ACTIVE**  
**Last Updated**: 2025-11-02  
**Authority**: BossCat OEM

---

## Overview

This document outlines the architecture of the **direct-to-SigNoz integration** as the
canonical approach for the OpenTelemetry observability pipeline.

### Current Architecture (Active)

```text
Windows Event Logs + File Logs
    ↓
Docker OTel Collectors (direct ingestion)
    ↓
SigNoz Backend
    ↓
SigNoz UI (http://localhost:8080)
```

---

## Key Components

### 1. Data Sources

- **Windows Event Logs** (Security, Application, System)
- **File Logs** (application logs, custom logs)
- **Metrics** (system performance, OTel collector metrics)
- **Traces** (distributed tracing via OTLP)

### 2. OpenTelemetry Collectors (Docker)

- **Primary Collector**: `signoz-otel-collector`
- **Metrics Collector**: `signoz-otel-collector-metrics`
- **Configuration**: `config.yaml`
- **Batch Processing**: 200ms timeout (optimized for low latency)
- **Noise Filtering**: ~50% volume reduction via event ID filters

### 3. SigNoz Backend

- **OTLP Endpoints**:
  - gRPC: `localhost:5320`
  - HTTP: `localhost:5321`
- **Query Service**: Real-time log/trace/metrics queries
- **Alerting**: Threshold-based alerts
- **Retention**: Configurable per signal type

### 4. SigNoz UI

- **URL**: <http://localhost:8080>
- **Features**: Logs explorer, traces explorer, metrics dashboards, alerts

---

## Performance Characteristics

- **Batch Latency**: ≤200ms (target achieved)
- **Noise Reduction**: ~50% (via selective event filtering)
- **Throughput**: 512 events per batch, max 1024
- **Send Timeout**: 200ms

---

## Configuration Files

### Active

- ✅ `config.yaml` - Primary OTel collector config (Docker)
- ✅ `docker-compose-signoz.yml` - SigNoz stack
- ✅ `BRAV/SCPT/verify-pipeline.ps1` - End-to-end gate validation (exit codes 0/1/2)
- ✅ `operator-pipeline-check.ps1` - Operator linear check after collector restart
- ✅ `scripts/canary-test.ps1` - Test data generation

### Deprecated

- ❌ `windows/otelcol/otelcol-contrib-config.yaml` - See [WINDOWS_COLLECTOR_DEPRECATION.md](WINDOWS_COLLECTOR_DEPRECATION.md)

---

## Monitoring & Validation

### Health Checks

```powershell
# Quick health check
pwsh -File scripts\quick-monitor.ps1

# Detailed monitoring  
pwsh -File scripts\monitor-optimized-pipeline.ps1 -DurationMinutes 10

# End-to-end validation
pwsh -File BRAV\SCPT\verify-pipeline.ps1
```

### SigNoz Queries

```text
# Logs
message contains "canary test"

# Metrics
otelcol_*

# Traces
service.name = "resonai_analytics"
```

---

## Architecture Decisions

### Why Direct-to-SigNoz?

1. **Eliminated Redundant Hop**: Previous dual-hop (Windows service → Docker) added 2-5s latency
2. **Simplified Configuration**: Single config file vs. dual configs
3. **Better Performance**: Achieved sub-200ms batch processing
4. **Reduced Drift**: No config synchronization issues

### Trade-offs

| Aspect | Direct-to-SigNoz | Previous (Windows Collector) |
|--------|------------------|------------------------------|
| **Latency** | ≤200ms | 2-5s |
| **Config Files** | 1 (Docker only) | 2 (Windows + Docker) |
| **Maintenance** | Low | Medium |
| **Complexity** | Simple | Moderate |

---

## Telemetry Flow

### Logs

```text
Windows Event Logs → OTel Receiver → Processors → Batch → SigNoz
                                    ↓
                            Noise Filter (50% reduction)
                            Format Transform
                            Resource Detection
```

### Traces

```text
Application (OTLP) → OTel Collector → Batch → SigNoz
```

### Metrics

```text
System Metrics → OTel Collector → Batch → SigNoz
OTel Collector Internal Metrics → SigNoz
```

---

## Related Documentation

- **Deprecation Notice**: [WINDOWS_COLLECTOR_DEPRECATION.md](WINDOWS_COLLECTOR_DEPRECATION.md)
- **Repository Structure**: [REPOSITORY_STRUCTURE.md](../REPOSITORY_STRUCTURE.md)
- **ECRR Framework**: [../comfort-cat/ECRR_FRAMEWORK.md](../comfort-cat/ECRR_FRAMEWORK.md)
- **Runbooks**: [../runbooks/unified-telemetry-proofs.md](../runbooks/unified-telemetry-proofs.md)

---

**Version**: 1.0  
**Last Updated**: 2025-11-02  
**Status**: Active - Canonical Architecture  
**Maintained by**: MoneyCat-inc

