# 🔍 Observability Setup Guide

This document describes the OpenTelemetry + SigNoz observability stack integrated with Resonai.

## Architecture Overview

```
Resonai (Port 3003) → OTel Collector (14317/14318) → SigNoz (8080)
                    ↓
              Windows Event Logs
                    ↓
              File Logs (C:\logs\)
```

## Components

### 1. OpenTelemetry Collector (Windows Service)

**Status**: Running as Windows service `otelcol-contrib`  
**Config**: `collector/otel-local.yaml`  
**Ports**: 
- 14317 (gRPC OTLP)
- 14318 (HTTP OTLP)

**Receivers**:
- OTLP (HTTP/gRPC)
- Windows Event Logs (Application, System)
- File logs (`C:\logs\**\*.log`)

**Exporters**:
- OTLP to SigNoz (gRPC on 4317)

### 2. SigNoz (Docker/WSL2)

**Status**: Running in Docker containers  
**URL**: http://localhost:8080  
**Components**:
- SigNoz UI
- ClickHouse (storage)
- OTel Collector (ingestion)
- Zookeeper (coordination)

### 3. Resonai Integration

**URL**: http://localhost:3003  
**Environment**: `.env.local` (OTel configuration)  
**Telemetry**: Voice training metrics, user interactions, audio processing

## Configuration Files

### OTel Collector Config (`collector/otel-local.yaml`)

```yaml
receivers:
  otlp:
    protocols:
      http:  { endpoint: 0.0.0.0:14318 }
      grpc:  { endpoint: 0.0.0.0:14317 }
  windows_event_log:
    channels: [Application, System]
  filelog:
    include: ["C:\\logs\\**\\*.log"]

processors:
  batch: {}

exporters:
  otlp:
    endpoint: localhost:4317
    tls: { insecure: true }

service:
  pipelines:
    logs:    { receivers: [windows_event_log, filelog, otlp], processors: [batch], exporters: [otlp] }
    metrics: { receivers: [otlp],                            processors: [batch], exporters: [otlp] }
    traces:  { receivers: [otlp],                            processors: [batch], exporters: [otlp] }
```

### Resonai Environment (`third_party/resonai/.env.local`)

```bash
OTEL_EXPORTER_OTLP_PROTOCOL=http/json
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:14318
OTEL_SERVICE_NAME=resonai-local
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=dev
```

## Monitoring & Dashboards

### SigNoz Queries

**All Resonai logs**:
```
service.name = "resonai-local"
```

**Voice training sessions**:
```
message contains "voice" OR message contains "pitch" OR message contains "training"
```

**Error tracking**:
```
severity = "ERROR" AND service.name = "resonai-local"
```

**Performance metrics**:
```
service.name = "resonai-local" | rate(5m)
```

### Key Metrics to Track

1. **Time to Voice (TTV)**: How quickly users get audio feedback
2. **Mic Grant Rate**: Percentage of successful microphone access
3. **Activation Rate**: Percentage of completed training sessions
4. **Audio Processing Latency**: Real-time feedback responsiveness
5. **Error Rates**: Failed audio processing, permission denials

## Troubleshooting

### Common Issues

**Port conflicts**:
```powershell
netstat -ano | findstr "14317\|14318\|3003\|8080"
```

**Service not running**:
```powershell
Get-Service otelcol-contrib
Start-Service otelcol-contrib
```

**SigNoz not accessible**:
```powershell
wsl -e bash -lc "docker ps | grep signoz"
```

**Resonai not starting**:
```powershell
cd third_party\resonai
pnpm dev
```

### Health Checks

Run the comprehensive verifier:
```powershell
.\Test-ResonaiStack.ps1
```

## Development Workflow

1. **Start services**: OTel collector (service), SigNoz (Docker), Resonai (dev)
2. **Develop features**: Make changes to Resonai
3. **Monitor metrics**: Check SigNoz for real-time data
4. **Debug issues**: Use logs and traces to identify problems
5. **Test canaries**: Send test data to verify pipeline

## Security & Privacy

- **No PII**: All telemetry is anonymized
- **Local-first**: Data stays on device by default
- **Redacted logs**: Sensitive information is filtered
- **Secure transport**: OTLP over localhost only

## Next Steps

1. **Create dashboards**: Build SigNoz dashboards for key metrics
2. **Set up alerts**: Configure alerts for error rates and performance
3. **Add traces**: Implement distributed tracing for audio pipeline
4. **Optimize metrics**: Fine-tune what data is collected
5. **Scale testing**: Test with multiple concurrent users



