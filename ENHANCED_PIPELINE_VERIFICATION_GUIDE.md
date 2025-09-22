# 🔍 **Enhanced CI Pipeline Verification Guide**

## ✅ **Test PR Pushed Successfully**

**Commit**: `00d8e1f` - "test: verify enhanced CI pipeline with collector logs artifact"  
**Branch**: `main`  
**Status**: ✅ **PUSHED TO ORIGIN**

---

## 🎯 **What to Verify in GitHub Actions**

### **1. Concurrency Control**
**Location**: Check the Actions tab for any cancelled runs
**Expected**: If you push multiple commits quickly, previous runs should be cancelled
**Indicator**: "❌ Cancelled" status on superseded runs

### **2. Enhanced OTLP Smoke Test**
**Job**: `otel-config-smoke`  
**Expected Steps**:
1. ✅ Pull collector image `0.114.0`
2. ✅ Show collector version
3. ✅ Create minimal CI config with `verbosity: detailed`
4. ✅ Start collector with OTLP receiver
5. ✅ Send canary span to `/v1/traces`
6. ✅ **Collect collector logs** to `artifacts/collector.log`
7. ✅ **Upload artifact** as `otel-collector-logs` (7-day retention)
8. ✅ Tear down container

### **3. Collector Logs Artifact**
**Location**: Actions → Run → Artifacts tab
**Expected Artifact**: `otel-collector-logs`
**Contents**: `artifacts/collector.log` with detailed verbosity output

---

## 📊 **Success Criteria Checklist**

### **✅ All 7 Jobs Green**
- [ ] **python** - pip cache + lint + test
- [ ] **node** - npm cache + lint + typecheck + test
- [ ] **powershell** - yaml validation + PSScriptAnalyzer
- [ ] **yamls** - yamllint general + OTel configs
- [ ] **actionlint** - GitHub Actions validation
- [ ] **otel-config-smoke** - collector + OTLP canary + logs
- [ ] **reviewdog-eslint** - PR annotations

### **✅ Enhanced Features Working**
- [ ] **Concurrency control** - superseded runs cancelled
- [ ] **Collector logs artifact** - `otel-collector-logs` appears
- [ ] **Detailed verbosity** - rich log output in artifact
- [ ] **7-day retention** - artifact available for debugging
- [ ] **Queue management** - PR processing smooth

---

## 🔍 **Troubleshooting Guide**

### **If OTLP Canary Fails:**
1. **Check collector logs artifact** - Download `otel-collector-logs`
2. **Look for errors** - Search for "error", "failed", "panic"
3. **Verify OTLP endpoint** - Check if port 4318 is accessible
4. **Review span format** - Ensure JSON payload is valid

### **If Concurrency Control Issues:**
1. **Check workflow runs** - Look for multiple concurrent runs
2. **Verify group setting** - Should be `ci-${{ github.ref }}`
3. **Review cancellation** - Previous runs should show "❌ Cancelled"

### **If Queue Management Issues:**
1. **Check Mergify status** - Look for queue processing
2. **Verify conditions** - PR needs approval + green CI
3. **Review merge method** - Should be squash merge

---

## 📋 **Expected Log Content**

When you download the `otel-collector-logs` artifact, you should see:

```
2024-01-XX INFO    service/telemetry.go:XXX    Setting up own telemetry...
2024-01-XX INFO    service/telemetry.go:XXX    Serving Prometheus metrics...
2024-01-XX INFO    service/service.go:XXX    Starting otelcol...
2024-01-XX INFO    service/service.go:XXX    Everything is ready. Begin running and processing data.
2024-01-XX DEBUG   otlpreceiver/otlp.go:XXX    Starting HTTP server on endpoint 0.0.0.0:4318
2024-01-XX DEBUG   loggingexporter/logging_exporter.go:XXX    ResourceSpans #0
Resource SchemaURL: 
Resource attributes:
     -> service.name: STRING(ci-cat)
ScopeSpans #0
Scope name: 
Scope version: 
Span #0
    Trace ID       : 0123456789abcdef0123456789abcdef
    Span ID        : 0123456789abcdef
    Parent Span ID : 
    Name           : ci-smoke
    Kind           : SPAN_KIND_INTERNAL
    Start time     : 1970-01-01 00:00:00 +0000 UTC
    End time       : 1970-01-01 00:00:00 +0000 UTC
```

---

## 🎉 **Success Indicators**

**✅ Enhanced pipeline is working when:**
- All 7 jobs show ✅ green
- `otel-collector-logs` artifact appears in Actions
- Collector logs show detailed verbosity output
- Concurrency control cancels superseded runs
- Queue management processes PRs smoothly

---

## 🚀 **Next Steps After Verification**

1. **Review collector logs** - Download and examine the artifact
2. **Test queue behavior** - Create another PR to test queue processing
3. **Verify concurrency** - Push multiple commits quickly
4. **Monitor badge status** - Check README badge shows green

---

**The enhanced pipeline is now prowling with persistent logs and smooth queue management! 🐾**

**Status**: Ready to verify the `otel-collector-logs` artifact and enhanced troubleshooting capabilities.
