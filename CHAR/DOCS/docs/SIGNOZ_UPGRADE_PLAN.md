# SigNoz Collector Upgrade Plan
**Date:** 2025-10-05  
**Agent:** Codex (Observability Copilot)  
**Operation:** SigNoz Collector Upgrade for Logs Pipeline Support  
**Status:** 📋 **UPGRADE PLAN READY**

---

## 🎯 Upgrade Strategy

### **Current State**
- **SigNoz UI:** v0.96.1 (supports logs pipeline)
- **SigNoz Collector:** v0.129.6 (does NOT support logs pipeline)
- **Issue:** Version mismatch between UI and collector

### **Target State**
- **SigNoz UI:** v0.96.1 (keep current)
- **SigNoz Collector:** Latest version with logs pipeline support
- **Result:** Full logs pipeline functionality

---

## 📋 Upgrade Steps

### **Step 1: Backup Current Configuration**
```bash
# Backup current collector config
cp signoz-collector-config.yaml signoz-collector-config.yaml.backup

# Backup current docker-compose
cp docker-compose-signoz.yml docker-compose-signoz.yml.backup
```

### **Step 2: Update Docker Compose**
Update `docker-compose-signoz.yml` collector service:
```yaml
signoz-otel-collector:
  image: signoz/signoz-otel-collector:latest  # or specific version
  # ... rest of configuration stays the same
```

### **Step 3: Enable Logs Pipeline**
Update `signoz-collector-config.yaml`:
```yaml
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, resourcedetection, resource/defaults, signozspanmetrics/delta, batch]
      exporters: [clickhousetraces]
    metrics:
      receivers: [otlp, hostmetrics, prometheus]
      processors: [memory_limiter, resourcedetection, batch]
      exporters: [signozclickhousemetrics]
    logs:  # Enable this section
      receivers: [otlp]
      processors: [memory_limiter, resourcedetection, attributes/redact_sensitive, batch]
      exporters: [clickhouselogsexporter]
```

### **Step 4: Deploy Upgrade**
```bash
# Stop current stack
docker-compose -f docker-compose-signoz.yml down

# Pull new collector image
docker pull signoz/signoz-otel-collector:latest

# Start upgraded stack
docker-compose -f docker-compose-signoz.yml up -d
```

### **Step 5: Verify Logs Pipeline**
```bash
# Check collector logs
docker logs signoz-otel-collector --tail 20

# Run canary test
pwsh canary-test.ps1

# Verify in SigNoz UI
# Go to http://localhost:8080 -> Logs
# Filter: message contains 'canary test'
```

---

## ⚠️ Risk Mitigation

### **Rollback Plan**
If upgrade fails:
```bash
# Restore backup configuration
cp signoz-collector-config.yaml.backup signoz-collector-config.yaml
cp docker-compose-signoz.yml.backup docker-compose-signoz.yml

# Restart with original configuration
docker-compose -f docker-compose-signoz.yml down
docker-compose -f docker-compose-signoz.yml up -d
```

### **Testing Strategy**
1. **Pre-upgrade:** Document current functionality
2. **Post-upgrade:** Verify traces and metrics still work
3. **Logs test:** Confirm logs pipeline functionality
4. **Rollback test:** Verify rollback procedure works

---

## 📊 Expected Outcomes

### **Success Criteria**
- ✅ SigNoz collector starts without errors
- ✅ Logs pipeline accepts OTLP logs
- ✅ Windows Event Logs appear in SigNoz UI
- ✅ Traces and metrics continue working
- ✅ No data loss during upgrade

### **Performance Impact**
- **Minimal:** Logs pipeline adds minimal overhead
- **Memory:** Slight increase due to logs processing
- **Storage:** Additional ClickHouse storage for logs

---

*Upgrade plan prepared by Codex (Observability Copilot)*
