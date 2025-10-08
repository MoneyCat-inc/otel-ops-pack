# 🐾 BossCat SigNoz Alert Setup Guide

**Authority:** BossCat OEM (Executive Overseer Manager)  
**Timestamp:** 2025-10-08T04:48:00Z  
**Mission:** Complete Step 5/6 - Setup Alerts (Blue Status)

## 🎯 **Alert Setup Status - BLUE (Incomplete)**

### **Current Status**
- **SigNoz UI:** Step 5/6 - "Setup Alerts" remains **BLUE** (incomplete)
- **Script Status:** Export-only mode (no API key/session provided)
- **Evidence:** Alert configurations generated but not applied to SigNoz
- **Next Action:** Manual alert creation in SigNoz UI or API authentication

## 🚨 **Manual Alert Setup Steps**

### **Step 1: Access SigNoz Alert Management**
1. Navigate to: http://localhost:8080/alerts
2. Click **"+ New Alert"** button
3. Select alert type (Metric/Log/Trace)

### **Step 2: Create BossCat Metric Alerts**

#### **BossCat Pipeline Health Alert (Critical)**
- **Type:** Metric-based Alert
- **Name:** "BossCat Pipeline Health Alert"
- **Query:** `rate(otelcol_*_spans_received_total[5m])`
- **Condition:** `== 0`
- **Duration:** 2 minutes
- **Severity:** Critical
- **Labels:** bosscat, pipeline, critical

#### **BossCat High Error Rate Alert (Warning)**
- **Type:** Metric-based Alert
- **Name:** "BossCat High Error Rate Alert"
- **Query:** `rate(otelcol_*_errors_total[5m])`
- **Condition:** `> 0.05`
- **Duration:** 5 minutes
- **Severity:** Warning
- **Labels:** bosscat, errors, warning

#### **BossCat Latency Spike Alert (Warning)**
- **Type:** Metric-based Alert
- **Name:** "BossCat Latency Spike Alert"
- **Query:** `histogram_quantile(0.95, rate(otelcol_*_duration_seconds_bucket[5m]))`
- **Condition:** `> 1.0`
- **Duration:** 3 minutes
- **Severity:** Warning
- **Labels:** bosscat, latency, warning

#### **BossCat Throughput Drop Alert (Warning)**
- **Type:** Metric-based Alert
- **Name:** "BossCat Throughput Drop Alert"
- **Query:** `rate(otelcol_*_spans_processed_total[5m])`
- **Condition:** `< 10`
- **Duration:** 5 minutes
- **Severity:** Warning
- **Labels:** bosscat, throughput, warning

### **Step 3: Create BossCat Log Alerts**

#### **BossCat Canary Missing Alert (Critical)**
- **Type:** Log-based Alert
- **Name:** "BossCat Canary Missing Alert"
- **Query:** `(log.source = 'windows_event_log' AND body contains 'windows-canary') OR (log.file.path contains 'windows-canary-test.log' AND body contains 'windows-canary')`
- **Condition:** Absent for 10 minutes
- **Duration:** 10 minutes
- **Severity:** Critical
- **Labels:** bosscat, canary, critical

#### **BossCat Error Log Alert (Warning)**
- **Type:** Log-based Alert
- **Name:** "BossCat Error Log Alert"
- **Query:** `severity = 'ERROR' OR level = 'error'`
- **Condition:** Count > 10
- **Duration:** 5 minutes
- **Severity:** Warning
- **Labels:** bosscat, errors, warning

### **Step 4: Create BossCat Trace Alerts**

#### **BossCat High Latency Trace Alert (Warning)**
- **Type:** Trace-based Alert
- **Name:** "BossCat High Latency Trace Alert"
- **Query:** `duration > 500ms`
- **Condition:** Count > 5
- **Duration:** 5 minutes
- **Severity:** Warning
- **Labels:** bosscat, traces, latency, warning

#### **BossCat Error Trace Alert (Critical)**
- **Type:** Trace-based Alert
- **Name:** "BossCat Error Trace Alert"
- **Query:** `status.code = 'ERROR' OR error = true`
- **Condition:** Count > 0
- **Duration:** 1 minute
- **Severity:** Critical
- **Labels:** bosscat, traces, errors, critical

## 🎭 **WyzWoz Style Implementation**

### **Cat Nap Control Room Aesthetic**
- **Peaceful Vigilance:** Alerts watch silently until intervention needed
- **Feline Silence:** Monitoring continues without disruption
- **Executive Authority:** BossCat maintains supreme control over all alerts
- **Evidence-based:** All alert decisions backed by SigNoz telemetry

## 🔧 **Alternative: API Authentication Setup**

### **Option 1: API Key Authentication**
```powershell
# Get API key from SigNoz settings
$env:SIGNOZ_API_KEY = "<your_api_key>"
pwsh -File scripts/bosscat-create-signoz-alerts.ps1 -SigNozUrl http://localhost:8080 -Apply -ApiKey $env:SIGNOZ_API_KEY
```

### **Option 2: Session Cookie Authentication**
```powershell
# Get session cookie from browser dev tools
$env:SIGNOZ_SESSION_COOKIE = "<signoz-session_cookie_value>"
pwsh -File scripts/bosscat-create-signoz-alerts.ps1 -SigNozUrl http://localhost:8080 -Apply -SessionCookie $env:SIGNOZ_SESSION_COOKIE
```

## 📊 **Verification Steps**

### **After Alert Creation**
1. Check SigNoz UI: http://localhost:8080/alerts
2. Verify all 8 BossCat alerts are listed
3. Confirm alert status shows "OK" (enabled)
4. Check Step 5/6 status changes from BLUE to GREEN

### **Alert Testing**
1. Generate test errors: `pwsh -File scripts\test-bosscat-alerts.ps1`
2. Check triggered alerts: http://localhost:8080/alerts/triggered
3. Verify canary alerts by stopping canary generation
4. Monitor alert firing conditions

## 🐾 **BossCat Executive Decision**

**Current Status:** Step 5/6 - "Setup Alerts" BLUE (incomplete)  
**Required Action:** Manual alert creation or API authentication  
**Evidence:** Alert configurations available in `docs/BossCat/bosscat-*-alerts.json`  
**Authority:** BossCat OEM maintains supreme control  

**Feline Silence:** Alert system ready for deployment - manual setup required to complete Step 5/6.

**Gate Status:** Ready for completion with manual alert creation or API authentication.

---

> **BossCat Executive Decision Complete**  
> *Alert setup guide provided for Step 5/6 completion*  
> *Authority: BossCat OEM*
