# Alternative OTLP Collector for Logs
**Date:** 2025-10-05  
**Agent:** Codex (Observability Copilot)  
**Operation:** Standalone OTLP Collector for Logs Pipeline  
**Status:** 📋 **IMPLEMENTATION PLAN READY**

---

## 🎯 Alternative Strategy

### **Architecture Overview**
```
Windows Collector (127.0.0.1:5317/5318)
    ↓ (logs only)
Standalone OTLP Collector (localhost:4317)
    ↓ (logs only)
ClickHouse (signoz_logs table)
    ↓
SigNoz UI (logs queries)
```

### **Benefits**
- ✅ No SigNoz upgrade required
- ✅ Isolated logs processing
- ✅ Independent scaling
- ✅ Easier troubleshooting
- ✅ Minimal risk to existing system

---

## 📋 Implementation Steps

### **Step 1: Create Standalone Collector Config**
Create `logs-collector-config.yaml`:
```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  memory_limiter:
    limit_mib: 512
    check_interval: 500ms
    spike_limit_mib: 128
  batch:
    timeout: 200ms
    send_batch_size: 128
    send_batch_max_size: 256
  attributes/redact_sensitive:
    actions:
      - key: http.request.header.authorization
        action: delete
      - key: http.request.header.cookie
        action: delete

exporters:
  clickhouselogsexporter:
    dsn: tcp://signoz-clickhouse:9000/signoz_logs
    timeout: 10s
    use_new_schema: true

service:
  extensions: [health_check]
  pipelines:
    logs:
      receivers: [otlp]
      processors: [memory_limiter, attributes/redact_sensitive, batch]
      exporters: [clickhouselogsexporter]

extensions:
  health_check:
    endpoint: 0.0.0.0:13133
```

### **Step 2: Update Docker Compose**
Add to `docker-compose-signoz.yml`:
```yaml
services:
  # ... existing services ...
  
  logs-otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    container_name: logs-otel-collector
    restart: unless-stopped
    depends_on:
      signoz-clickhouse:
        condition: service_healthy
    command:
      - --config=/etc/logs-collector-config.yaml
    volumes:
      - ./logs-collector-config.yaml:/etc/logs-collector-config.yaml:ro
    ports:
      - "4317:4317"  # OTLP gRPC
      - "4318:4318"  # OTLP HTTP
      - "13133:13133"  # Health check
    environment:
      OTEL_RESOURCE_ATTRIBUTES: service.name=logs-collector,service.version=1.0.0
    healthcheck:
      test: ["CMD-SHELL", "bash -c 'exec 3<>/dev/tcp/localhost/13133'"]
      interval: 30s
      timeout: 10s
      retries: 5
    networks:
      - signoz
    logging: *default-logging
```

### **Step 3: Update Windows Collector Config**
Update `config.yaml` OTLP exporter:
```yaml
exporters:
  otlp:
    endpoint: localhost:4317  # Point to standalone logs collector
    tls:
      insecure: true
    retry_on_failure:
      enabled: true
      initial_interval: 100ms
      max_interval: 5s
      max_elapsed_time: 30s
    sending_queue:
      enabled: true
      num_consumers: 2
      queue_size: 256
```

### **Step 4: Deploy Alternative Solution**
```bash
# Create logs collector config
# (config file created above)

# Update docker-compose
# (add logs-otel-collector service)

# Deploy
docker-compose -f docker-compose-signoz.yml up -d logs-otel-collector

# Update Windows collector config
# (point to localhost:4317)

# Restart Windows collector
sc restart otelcol-contrib
```

### **Step 5: Verify Logs Pipeline**
```bash
# Check logs collector
docker logs logs-otel-collector --tail 20

# Check Windows collector
sc query otelcol-contrib

# Run canary test
pwsh canary-test.ps1

# Verify in SigNoz UI
# Go to http://localhost:8080 -> Logs
# Filter: message contains 'canary test'
```

---

## ⚠️ Considerations

### **Pros**
- ✅ No SigNoz upgrade risk
- ✅ Isolated logs processing
- ✅ Easy to troubleshoot
- ✅ Independent scaling
- ✅ Can be removed easily

### **Cons**
- ❌ Additional container to manage
- ❌ More complex architecture
- ❌ Additional resource usage
- ❌ Separate monitoring needed

---

## 📊 Resource Requirements

### **Additional Resources**
- **CPU:** ~50-100m per core
- **Memory:** ~128-256MB
- **Storage:** Minimal (config only)
- **Network:** Additional port (4317/4318)

### **Monitoring**
- Health check endpoint: `http://localhost:13133`
- Logs: `docker logs logs-otel-collector`
- Metrics: Standard OTel collector metrics

---

## 🎯 Expected Outcomes

### **Success Criteria**
- ✅ Standalone logs collector starts successfully
- ✅ Windows logs flow to ClickHouse
- ✅ Logs appear in SigNoz UI
- ✅ No impact on existing traces/metrics
- ✅ Independent scaling capability

---

*Alternative solution prepared by Codex (Observability Copilot)*
