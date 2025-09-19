# OTel Integration Checklist - AI Assistant Context

## 🎯 Pre-Integration Checklist

### **Configuration Validation**
- [ ] YAML syntax is valid
- [ ] All required fields are present
- [ ] Component names are correct
- [ ] Port bindings are loopback-only
- [ ] No secrets embedded in config
- [ ] Memory limits are appropriate
- [ ] Batch settings are optimized

### **Security Review**
- [ ] Receivers use loopback-only bindings
- [ ] Exporters use secure connections
- [ ] Sensitive data is redacted
- [ ] No hardcoded secrets
- [ ] TLS settings are appropriate
- [ ] CORS is not widened

### **Integration Prerequisites**
- [ ] External services are reachable
- [ ] Required credentials are available
- [ ] Network connectivity is verified
- [ ] Dependencies are installed
- [ ] Configuration templates are ready

## 🔧 Integration Implementation

### **Step 1: Create Candidate Config**
```powershell
# Create candidate configuration
Copy-Item C:\otel\config.yaml C:\otel\config.candidate.yaml -Force

# Edit candidate with new integration
# Use templates from ai-context/common-configurations.yaml
```

### **Step 2: Validate Configuration**
```powershell
# Validate syntax and structure
C:\otel\config-schema.ps1 -ConfigPath C:\otel\config.candidate.yaml

# Check for common issues
C:\otel\config-schema.ps1 -ConfigPath C:\otel\config.candidate.yaml -CheckSecurity
C:\otel\config-schema.ps1 -ConfigPath C:\otel\config.candidate.yaml -CheckPerformance
```

### **Step 3: Test Integration**
```powershell
# Test external service connectivity
C:\otel\kafka-smoke.ps1  # For Kafka
C:\otel\integration-tests.ps1 -Integrations @("kafka", "prometheus")

# Run canary test
C:\otel\canary-check-min.ps1
```

### **Step 4: Apply Configuration**
```powershell
# Apply via safe-apply workflow
C:\otel\safe-apply-config.ps1 -Candidate C:\otel\config.candidate.yaml

# Verify application
C:\otel\green-sheet.ps1
C:\otel\regression-check.ps1
```

### **Step 5: Generate Audit Pack**
```powershell
# Generate audit evidence
C:\otel\make-audit-pack.ps1

# Note SHA256 hash for compliance
```

## 📊 Post-Integration Verification

### **Service Health**
- [ ] Service is running
- [ ] Health endpoint returns 200
- [ ] Metrics endpoint returns 200
- [ ] No error logs in event viewer

### **Data Flow**
- [ ] Canary test passes (delta +1)
- [ ] Data appears in backends
- [ ] No export failures
- [ ] Queue sizes are healthy

### **Integration Specific**
- [ ] Kafka: Data appears in topic
- [ ] Prometheus: Metrics are scraped
- [ ] Jaeger: Traces are received
- [ ] Datadog: Data is sent

### **Performance**
- [ ] Memory usage is stable
- [ ] CPU usage is reasonable
- [ ] Queue sizes are healthy
- [ ] No performance degradation

## 🚨 Troubleshooting Checklist

### **Service Won't Start**
- [ ] Check YAML syntax
- [ ] Validate configuration
- [ ] Check port availability
- [ ] Review event logs
- [ ] Verify file permissions

### **No Data Flow**
- [ ] Check pipeline configuration
- [ ] Verify receiver/exporter names
- [ ] Test external connectivity
- [ ] Check queue status
- [ ] Review error logs

### **Performance Issues**
- [ ] Check memory limits
- [ ] Review batch settings
- [ ] Monitor queue sizes
- [ ] Check CPU usage
- [ ] Analyze metrics

### **Integration Failures**
- [ ] Test external service
- [ ] Check credentials
- [ ] Verify network connectivity
- [ ] Review configuration
- [ ] Check logs

## 🔄 Maintenance Checklist

### **Daily**
- [ ] Run regression check
- [ ] Check service health
- [ ] Monitor queue sizes
- [ ] Review error logs

### **Weekly**
- [ ] Run integration tests
- [ ] Check performance metrics
- [ ] Review configuration
- [ ] Update documentation

### **Monthly**
- [ ] Generate audit pack
- [ ] Review security settings
- [ ] Check for updates
- [ ] Test disaster recovery

### **Quarterly**
- [ ] Full security review
- [ ] Performance optimization
- [ ] Disaster recovery test
- [ ] Documentation update

## 📚 Documentation Checklist

### **Configuration Changes**
- [ ] Update configuration comments
- [ ] Document new integrations
- [ ] Update troubleshooting guide
- [ ] Add to integration patterns

### **Operational Procedures**
- [ ] Update daily ops procedures
- [ ] Add new monitoring checks
- [ ] Update emergency procedures
- [ ] Add integration-specific steps

### **Release Documentation**
- [ ] Update release notes
- [ ] Document breaking changes
- [ ] Add migration guide
- [ ] Update version numbers

## 🎯 Quality Gates

### **Pre-Deployment**
- [ ] All tests pass
- [ ] Security review complete
- [ ] Performance acceptable
- [ ] Documentation updated
- [ ] Rollback plan ready

### **Post-Deployment**
- [ ] Service healthy
- [ ] Data flowing
- [ ] No errors
- [ ] Performance stable
- [ ] Audit pack generated

### **Ongoing**
- [ ] Monitoring active
- [ ] Alerts configured
- [ ] Documentation current
- [ ] Procedures tested
- [ ] Team trained

## 🚀 Success Criteria

### **Technical Success**
- Service runs without errors
- Data flows to all destinations
- Performance meets requirements
- Security requirements met
- Monitoring is active

### **Operational Success**
- Procedures are documented
- Team is trained
- Monitoring is configured
- Alerts are working
- Rollback is tested

### **Business Success**
- Observability goals met
- Cost is within budget
- Compliance requirements met
- Stakeholders are satisfied
- ROI is demonstrated

---

**This is the way.** 🏁


