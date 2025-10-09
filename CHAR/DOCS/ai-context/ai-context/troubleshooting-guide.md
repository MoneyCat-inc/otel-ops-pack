# OTel Troubleshooting Guide - AI Assistant Context

## 🚨 Common Issues & Solutions

### **1. Service Won't Start**

#### **Symptoms**
- Service status: Stopped
- Event logs show startup failures
- Configuration validation errors

#### **Diagnosis**
```powershell
# Check service status
Get-Service otelcol-contrib

# Check event logs
Get-WinEvent -LogName Application -Source "otelcol-contrib" -MaxEvents 10

# Validate configuration
C:\otel\config-schema.ps1 -ConfigPath C:\otel\config.yaml
```

#### **Common Causes & Solutions**
1. **YAML Syntax Error**
   ```yaml
   # ❌ Invalid YAML
   processors:
     resource/defaults:  # Invalid processor name
   
   # ✅ Valid YAML
   processors:
     resource/defaults:
   ```

2. **Missing Required Fields**
   ```yaml
   # ❌ Missing required fields
   exporters:
     kafka:
       brokers: []  # Empty brokers list
   
   # ✅ Valid configuration
   exporters:
     kafka:
       brokers: ["localhost:9092"]
       topic: otel-logs
   ```

3. **Invalid Port Bindings**
   ```yaml
   # ❌ Invalid port binding
   receivers:
     otlp:
       protocols:
         http:
           endpoint: "invalid:port"
   
   # ✅ Valid port binding
   receivers:
     otlp:
       protocols:
         http:
           endpoint: "127.0.0.1:5318"
   ```

### **2. No Data Flow**

#### **Symptoms**
- Service running but no data in backends
- Metrics show zero accepted records
- Canary test fails

#### **Diagnosis**
```powershell
# Check data flow
C:\otel\canary-check-min.ps1

# Check metrics
Invoke-WebRequest -Uri http://127.0.0.1:8889/metrics -UseBasicParsing | Select-String "accepted_log_records"

# Check pipeline configuration
C:\otel\config-schema.ps1 -ConfigPath C:\otel\config.yaml -CheckPipelines
```

#### **Common Causes & Solutions**
1. **Missing Pipeline Configuration**
   ```yaml
   # ❌ Missing pipeline
   service:
     extensions: [health_check]
     # No pipelines defined
   
   # ✅ Valid pipeline
   service:
     extensions: [health_check]
     pipelines:
       logs:
         receivers: [otlp]
         processors: [memory_limiter, batch]
         exporters: [otlp]
   ```

2. **Incorrect Receiver/Exporter Names**
   ```yaml
   # ❌ Mismatched names
   receivers:
     otlp: {...}
   service:
     pipelines:
       logs:
         receivers: [otlp_http]  # Wrong name
   
   # ✅ Matching names
   receivers:
     otlp: {...}
   service:
     pipelines:
       logs:
         receivers: [otlp]  # Correct name
   ```

3. **Exporter Connection Issues**
   ```powershell
   # Test Kafka connectivity
   C:\otel\kafka-smoke.ps1
   
   # Test SigNoz connectivity
   Invoke-WebRequest -Uri http://127.0.0.1:14318 -UseBasicParsing
   ```

### **3. Memory Issues**

#### **Symptoms**
- High memory usage
- Service crashes with OOM
- Performance degradation

#### **Diagnosis**
```powershell
# Check memory usage
Get-Process otelcol-contrib | Select-Object ProcessName, WorkingSet, PagedMemorySize

# Check memory limiter settings
C:\otel\config-schema.ps1 -ConfigPath C:\otel\config.yaml -CheckMemory
```

#### **Common Causes & Solutions**
1. **Insufficient Memory Limits**
   ```yaml
   # ❌ No memory limits
   processors: {}
   
   # ✅ Proper memory limits
   processors:
     memory_limiter:
       check_interval: 2s
       limit_mib: 512
       spike_limit_mib: 256
   ```

2. **Large Batch Sizes**
   ```yaml
   # ❌ Too large batches
   processors:
     batch:
       send_batch_size: 100000
   
   # ✅ Reasonable batch sizes
   processors:
     batch:
       send_batch_size: 2048
       send_batch_max_size: 4096
   ```

### **4. Performance Problems**

#### **Symptoms**
- Slow data processing
- High CPU usage
- Queue backlogs

#### **Diagnosis**
```powershell
# Check performance metrics
Invoke-WebRequest -Uri http://127.0.0.1:8889/metrics -UseBasicParsing | Select-String "queue_size|batch_size"

# Check queue status
C:\otel\queue-watch.ps1
```

#### **Common Causes & Solutions**
1. **Inefficient Batching**
   ```yaml
   # ❌ No batching
   processors:
     batch:
       timeout: 0s
       send_batch_size: 1
   
   # ✅ Efficient batching
   processors:
     batch:
       timeout: 2s
       send_batch_size: 2048
       send_batch_max_size: 4096
   ```

2. **Insufficient Queue Capacity**
   ```yaml
   # ❌ Small queue
   exporters:
     otlp:
       sending_queue:
         queue_size: 100
   
   # ✅ Adequate queue
   exporters:
     otlp:
       sending_queue:
         queue_size: 8192
         num_consumers: 4
   ```

## 🔧 Diagnostic Commands

### **Quick Health Check**
```powershell
# One-liner health check
C:\otel\regression-check.ps1
```

### **Detailed Diagnostics**
```powershell
# Service status
C:\otel\green-sheet.ps1

# Configuration validation
C:\otel\config-schema.ps1 -ConfigPath C:\otel\config.yaml

# Integration testing
C:\otel\integration-tests.ps1 -Integrations @("kafka", "prometheus")

# Canary test
C:\otel\canary-check-min.ps1
```

### **Log Analysis**
```powershell
# Check recent logs
Get-Content C:\otel\logs\safe-apply.last.txt -Tail 50

# Check canary logs
Get-Content C:\otel\logs\canary-check-min.last.log -Tail 20

# Check service logs
Get-WinEvent -LogName Application -Source "otelcol-contrib" -MaxEvents 20
```

## 🚨 Emergency Procedures

### **Service Down**
```powershell
# 1. Check service status
Get-Service otelcol-contrib

# 2. Start service
Start-Service otelcol-contrib

# 3. Verify startup
Start-Sleep 10
C:\otel\green-sheet.ps1

# 4. If still down, check config
C:\otel\config-schema.ps1 -ConfigPath C:\otel\config.yaml
```

### **Configuration Issues**
```powershell
# 1. Restore backup
Copy-Item C:\otel\config.bak.*.yaml C:\otel\config.yaml -Force

# 2. Restart service
Restart-Service otelcol-contrib

# 3. Verify recovery
C:\otel\canary-check-min.ps1
```

### **Data Flow Issues**
```powershell
# 1. Check pipeline configuration
C:\otel\config-schema.ps1 -ConfigPath C:\otel\config.yaml -CheckPipelines

# 2. Test integrations
C:\otel\kafka-smoke.ps1
C:\otel\integration-tests.ps1 -Integrations @("kafka")

# 3. Run canary test
C:\otel\canary-check-min.ps1
```

## 📊 Monitoring & Alerting

### **Key Metrics to Monitor**
- `otelcol_receiver_accepted_log_records` - Data ingestion rate
- `otelcol_exporter_sent_log_records` - Data export rate
- `otelcol_exporter_send_failed_log_records` - Export failures
- `otelcol_processor_batch_batch_send_size` - Batch efficiency
- `otelcol_exporter_queue_size` - Queue health

### **Alert Thresholds**
- **High failure rate**: `send_failed_log_records > 100/hour`
- **Queue backlog**: `queue_size > 80% capacity`
- **Memory usage**: `memory_rss > 80% limit`
- **No data flow**: `accepted_log_records = 0 for 5 minutes`

### **Automated Checks**
```powershell
# Daily health check
C:\otel\regression-check.ps1

# Weekly integration test
C:\otel\integration-tests.ps1 -FullTest

# Monthly audit
C:\otel\make-audit-pack.ps1
```

## 🎯 Prevention Strategies

### **Configuration Management**
- Always use `safe-apply-config.ps1` for changes
- Validate configurations before applying
- Keep configuration backups
- Use candidate configs for testing

### **Monitoring Setup**
- Enable health check endpoint
- Set up metrics collection
- Configure canary testing
- Implement alerting

### **Regular Maintenance**
- Weekly configuration validation
- Monthly integration testing
- Quarterly security review
- Annual disaster recovery testing

---

**This is the way.** 🏁


