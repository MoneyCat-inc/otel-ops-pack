# OTel Best Practices - AI Assistant Context

## 🎯 Configuration Best Practices

### **1. Security First**
```yaml
# ✅ Always use loopback-only bindings
receivers:
  otlp:
    protocols:
      http:
        endpoint: 127.0.0.1:5318  # Loopback only
      grpc:
        endpoint: 127.0.0.1:5317  # Loopback only

# ✅ Never embed secrets in config
exporters:
  datadog:
    api_key: ${DD_API_KEY}  # Use environment variables
    site: datadoghq.com

# ❌ Never expose to external networks
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:5318  # Exposes to all interfaces
```

### **2. Resource Management**
```yaml
# ✅ Always include memory limits
processors:
  memory_limiter:
    check_interval: 2s
    limit_mib: 512
    spike_limit_mib: 256

# ✅ Use efficient batching
processors:
  batch:
    timeout: 2s
    send_batch_size: 2048
    send_batch_max_size: 4096

# ✅ Configure retry and queue settings
exporters:
  otlp:
    retry_on_failure:
      enabled: true
      initial_interval: 1s
      max_interval: 30s
      max_elapsed_time: 300s
    sending_queue:
      enabled: true
      num_consumers: 4
      queue_size: 8192
      storage: file_storage
```

### **3. Pipeline Design**
```yaml
# ✅ Logical processor order
processors:
  resource/defaults:    # 1. Standardize attributes
  attributes/redact:    # 2. Remove sensitive data
  tail_sampling:        # 3. Sample traces
  memory_limiter:       # 4. Control memory
  batch:                # 5. Batch for efficiency

# ✅ Complete pipeline configuration
service:
  pipelines:
    logs:
      receivers: [otlp, filelog]
      processors: [resource/defaults, memory_limiter, batch]
      exporters: [otlp, kafka]
```

## 🔧 Integration Best Practices

### **1. Multi-Destination Fan-out**
```yaml
# ✅ Fan-out to multiple backends
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
# ✅ Standardize attributes across all telemetry
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
      - key: datacenter
        value: us-east-1
        action: upsert
```

### **3. Intelligent Sampling**
```yaml
# ✅ Keep important traces, reduce noise
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
        attribute:
          key: business.critical
          value: true
```

## 🚀 Operational Best Practices

### **1. Safe Change Management**
```powershell
# ✅ Always use safe-apply workflow
Copy-Item C:\otel\config.yaml C:\otel\config.candidate.yaml -Force
# Edit candidate...
C:\otel\safe-apply-config.ps1 -Candidate C:\otel\config.candidate.yaml
C:\otel\make-audit-pack.ps1
```

### **2. Configuration Validation**
```powershell
# ✅ Validate before applying
C:\otel\config-schema.ps1 -ConfigPath C:\otel\config.candidate.yaml
C:\otel\safe-apply-config.ps1 -Candidate C:\otel\config.candidate.yaml
```

### **3. Integration Testing**
```powershell
# ✅ Test integrations before deployment
C:\otel\integration-tests.ps1 -Integrations @("kafka", "prometheus")
C:\otel\regression-check.ps1
```

### **4. Continuous Monitoring**
```powershell
# ✅ Regular health checks
C:\otel\regression-check.ps1  # Daily
C:\otel\integration-tests.ps1 -FullTest  # Weekly
C:\otel\make-audit-pack.ps1  # Monthly
```

## 📊 Performance Best Practices

### **1. Memory Management**
```yaml
# ✅ Appropriate memory limits
processors:
  memory_limiter:
    check_interval: 2s
    limit_mib: 512        # Adjust based on available memory
    spike_limit_mib: 256  # 50% of limit
```

### **2. Batch Optimization**
```yaml
# ✅ Efficient batching
processors:
  batch:
    timeout: 2s           # Balance latency vs throughput
    send_batch_size: 2048 # Adjust based on data volume
    send_batch_max_size: 4096
```

### **3. Queue Configuration**
```yaml
# ✅ Adequate queue capacity
exporters:
  otlp:
    sending_queue:
      enabled: true
      num_consumers: 4    # Match CPU cores
      queue_size: 8192    # Adjust based on data volume
      storage: file_storage
```

## 🔒 Security Best Practices

### **1. Network Security**
```yaml
# ✅ Loopback-only bindings
receivers:
  otlp:
    protocols:
      http:
        endpoint: 127.0.0.1:5318
      grpc:
        endpoint: 127.0.0.1:5317

# ✅ Local-only exporters
exporters:
  signoz:
    endpoint: 127.0.0.1:14318
    tls: {insecure: true}  # OK for local connections
```

### **2. Secret Management**
```yaml
# ✅ Use environment variables
exporters:
  datadog:
    api_key: ${DD_API_KEY}
    site: datadoghq.com

# ❌ Never embed secrets
exporters:
  datadog:
    api_key: "dd_api_key_12345"  # Never do this
```

### **3. Data Redaction**
```yaml
# ✅ Remove sensitive data
processors:
  attributes/redact:
    actions:
      - key: password
        action: delete
      - key: token
        action: delete
      - key: secret
        action: delete
      - key: api_key
        action: delete
```

## 📚 Documentation Best Practices

### **1. Configuration Comments**
```yaml
# ✅ Document configuration sections
extensions:
  health_check:
    endpoint: 127.0.0.1:13134  # Health check endpoint

receivers:
  otlp:
    protocols:
      http:
        endpoint: 127.0.0.1:5318  # OTLP HTTP receiver
      grpc:
        endpoint: 127.0.0.1:5317  # OTLP gRPC receiver
```

### **2. Change Documentation**
```powershell
# ✅ Document changes
git commit -m "feat: add Kafka fan-out + resource defaults

- exporters.kafka added; pipelines fan-out to SigNoz + Kafka
- resource/defaults processor standardizes project and namespace
- tail_sampling keeps error and high-latency traces, reduces noise
- applied via safe-apply (validate + restart + canary PASS)
- audit pack generated with SHA256"
```

### **3. Operational Runbooks**
```markdown
# ✅ Document procedures
## Daily Operations
1. Run `C:\otel\regression-check.ps1`
2. Check health endpoints
3. Verify canary test passes
4. Monitor queue sizes

## Change Management
1. Create candidate config
2. Validate configuration
3. Apply via safe-apply
4. Generate audit pack
```

## 🎯 Quality Assurance

### **1. Pre-Deployment Checklist**
- [ ] Configuration validated
- [ ] Integration tests passed
- [ ] Security review completed
- [ ] Documentation updated
- [ ] Rollback plan prepared

### **2. Post-Deployment Verification**
- [ ] Service health check
- [ ] Canary test passes
- [ ] Metrics collection working
- [ ] Data flow verified
- [ ] Audit pack generated

### **3. Ongoing Monitoring**
- [ ] Daily regression checks
- [ ] Weekly integration tests
- [ ] Monthly security review
- [ ] Quarterly disaster recovery

## 🚨 Anti-Patterns to Avoid

### **❌ Security Violations**
- Exposing receivers to external networks
- Embedding secrets in configuration
- Disabling security features

### **❌ Performance Issues**
- Disabling batching
- Setting memory limits too high/low
- Inadequate queue capacity

### **❌ Operational Problems**
- Making changes without safe-apply
- Skipping validation steps
- Not maintaining audit trails

### **❌ Configuration Errors**
- Missing required fields
- Invalid YAML syntax
- Mismatched component names

---

**This is the way.** 🏁


