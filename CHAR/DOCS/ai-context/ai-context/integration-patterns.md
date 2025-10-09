# OTel Integration Patterns - AI Assistant Context

## 🎯 Core Integration Patterns

### **1. Multi-Destination Fan-out**
```yaml
# Pattern: Export to multiple backends simultaneously
exporters:
  signoz:
    endpoint: 127.0.0.1:14318
    tls: {insecure: true}
  kafka:
    brokers: ["localhost:9092"]
    topic: otel-logs
    encoding: otlp_json
  datadog:
    api_key: ${DD_API_KEY}
    site: datadoghq.com

service:
  pipelines:
    logs:
      exporters: [signoz, kafka, datadog]
```

### **2. Resource Standardization**
```yaml
# Pattern: Unified attributes across all telemetry
processors:
  resource/defaults:
    attributes:
      - key: project
        value: common
        action: upsert
      - key: service.namespace
        value: core
        action: upsert
      - key: environment
        value: production
        action: upsert
```

### **3. Intelligent Sampling**
```yaml
# Pattern: Keep important traces, reduce noise
processors:
  tail_sampling:
    decision_wait: 5s
    num_traces: 50000
    policies:
      - name: errors
        type: status_code
        status_code: ERROR
      - name: high_latency
        type: latency
        latency: 500ms
      - name: business_critical
        type: attribute
        attribute: {key: business.critical, value: true}
```

### **4. Security-First Configuration**
```yaml
# Pattern: Loopback-only, no secrets in config
receivers:
  otlp:
    protocols:
      http:
        endpoint: 127.0.0.1:5318  # Loopback only
      grpc:
        endpoint: 127.0.0.1:5317  # Loopback only

exporters:
  signoz:
    endpoint: 127.0.0.1:14318     # Loopback only
    tls: {insecure: true}         # Local only
```

## 🔧 Integration-Specific Patterns

### **Kafka Integration**
```yaml
# Pattern: Reliable Kafka fan-out
exporters:
  kafka:
    brokers: ["localhost:9092"]
    topic: otel-${type}  # Dynamic topic per type
    encoding: otlp_json
    protocol_version: 2.0.0
    retry_on_failure:
      enabled: true
      initial_interval: 1s
      max_interval: 30s
    sending_queue:
      enabled: true
      queue_size: 8192
      storage: file_storage
```

### **Prometheus Integration**
```yaml
# Pattern: Metrics scraping and export
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: 'otel-collector'
          static_configs:
            - targets: ['127.0.0.1:8889']
        - job_name: 'gpu-metrics'
          static_configs:
            - targets: ['127.0.0.1:9400']

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
    namespace: otelcol
    const_labels:
      service: otel-collector
```

### **Jaeger Integration**
```yaml
# Pattern: Distributed tracing
exporters:
  jaeger:
    endpoint: http://localhost:14268/api/traces
    tls:
      insecure: true
    retry_on_failure:
      enabled: true
      initial_interval: 1s
      max_interval: 30s
```

## 🚨 Anti-Patterns to Avoid

### **❌ Security Violations**
```yaml
# DON'T: Expose to external networks
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:5318  # ❌ Exposes to all interfaces

# DON'T: Embed secrets
exporters:
  datadog:
    api_key: "dd_api_key_12345"  # ❌ Secret in config
```

### **❌ Performance Issues**
```yaml
# DON'T: Disable batching
processors:
  batch:
    timeout: 0s  # ❌ No batching
    send_batch_size: 1  # ❌ Inefficient

# DON'T: No memory limits
processors:
  memory_limiter:
    limit_mib: 0  # ❌ No memory protection
```

### **❌ Configuration Errors**
```yaml
# DON'T: Missing required fields
exporters:
  kafka:
    brokers: []  # ❌ Empty brokers list

# DON'T: Invalid YAML
processors:
  resource/defaults:  # ❌ Invalid processor name
    attributes: "invalid"  # ❌ Wrong type
```

## 🎯 Best Practices

### **1. Always Use Safe-Apply**
```powershell
# Pattern: Safe configuration changes
Copy-Item C:\otel\config.yaml C:\otel\config.candidate.yaml -Force
# Edit candidate...
C:\otel\safe-apply-config.ps1 -Candidate C:\otel\config.candidate.yaml
C:\otel\make-audit-pack.ps1
```

### **2. Validate Before Apply**
```powershell
# Pattern: Pre-apply validation
C:\otel\config-schema.ps1 -ConfigPath C:\otel\config.candidate.yaml
C:\otel\safe-apply-config.ps1 -Candidate C:\otel\config.candidate.yaml
```

### **3. Test Integrations**
```powershell
# Pattern: Integration testing
C:\otel\integration-tests.ps1 -Integrations @("kafka", "prometheus")
C:\otel\regression-check.ps1
```

### **4. Monitor and Alert**
```powershell
# Pattern: Continuous monitoring
C:\otel\advanced-monitoring.ps1 -EnableAlerts
C:\otel\canary-check-min.ps1
```

## 🔍 Troubleshooting Patterns

### **Common Issues**
1. **Service won't start**: Check YAML syntax, validate config
2. **No data flow**: Verify pipeline configuration, check exporters
3. **Memory issues**: Adjust memory_limiter settings
4. **Performance problems**: Optimize batching, check queue sizes

### **Debug Commands**
```powershell
# Check service status
Get-Service otelcol-contrib
C:\otel\green-sheet.ps1

# Validate configuration
C:\otel\config-schema.ps1 -ConfigPath C:\otel\config.yaml

# Test integrations
C:\otel\kafka-smoke.ps1
C:\otel\integration-tests.ps1 -Integrations @("kafka")

# Check logs
Get-Content C:\otel\logs\safe-apply.last.txt -Tail 50
```

## 📚 Integration Checklist

### **Before Adding New Integration**
- [ ] Validate configuration syntax
- [ ] Check security (loopback-only, no secrets)
- [ ] Test connectivity to external service
- [ ] Verify data flow end-to-end
- [ ] Update documentation
- [ ] Generate audit pack

### **After Integration Changes**
- [ ] Run regression check
- [ ] Verify canary test passes
- [ ] Check health endpoints
- [ ] Monitor metrics for anomalies
- [ ] Update integration tests
- [ ] Document changes

---

**This is the way.** 🏁


