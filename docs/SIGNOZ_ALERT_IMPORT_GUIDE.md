# SigNoz Alert Import Guide: Hurst Exponent Drift Alert

**Date**: 2025-10-01  
**Purpose**: Step-by-step guide to manually import the Hurst Exponent Drift Alert into SigNoz UI

---

## 🎯 Overview

This guide provides detailed instructions for importing the Hurst Exponent Drift Alert into SigNoz UI. The alert monitors fractal pattern analysis for significant drift in Hurst exponent values, detecting persistent behavior (H > 0.7) that may indicate system instability.

---

## 📋 Prerequisites

- SigNoz running and accessible at http://localhost:8080
- Admin access to SigNoz UI
- Pattern drill logs being generated (from daily automation)

---

## 🚀 Step-by-Step Import Process

### Step 1: Access SigNoz UI
1. Open your web browser
2. Navigate to: `http://localhost:8080`
3. Log in to SigNoz (if authentication is enabled)

### Step 2: Navigate to Alerts
1. In the SigNoz UI, locate the **Alerts** section in the navigation menu
2. Click on **Alerts** or **Create Alert** (depending on your SigNoz version)

### Step 3: Create New Alert
1. Click **"Create Alert"** or **"New Alert"** button
2. You'll see a form with multiple sections to configure

### Step 4: Basic Alert Configuration
Fill in the following fields:

```
Alert Name: Hurst Exponent Drift Alert

Description: Detects significant drift in Hurst exponent values from fractal pattern analysis. Indicates potential changes in system behavior patterns - persistence (H>0.7), anti-persistence (H<0.3), or deviation from expected random walk behavior (H≈0.5).

Severity: Warning
```

### Step 5: Query Configuration
Set up the query section:

```
Query Type: Logs

Query:
message contains "hurst_estimate" AND log.file.path contains "canary-pattern-results.json"

Group By: pattern

Legend Format: {{pattern}} Pattern Hurst Drift
```

### Step 6: Alert Conditions
Configure the alert conditions:

```
Threshold: 0.7

Operator: above

Evaluation Window: 15m

Alert Frequency: 5m

Notification on Missing Data: False

Minimum Data Points: 3
```

### Step 7: Labels Configuration
Add the following labels (if your SigNoz version supports labels):

```
service: fractal-analysis
component: hurst-exponent
severity: warning
environment: local
framework: ecrr
metric_type: fractal_drift
```

### Step 8: Notification Channels
Configure notification channels:

```
Primary: email-default
Secondary: slack-default
```

### Step 9: Save and Activate
1. Review all configuration settings
2. Click **"Save"** or **"Create Alert"**
3. Ensure the alert is **"Active"** or **"Enabled"**

---

## ✅ Verification Steps

### Step 1: Alert Status Check
1. Navigate back to the **Alerts** section
2. Locate your **"Hurst Exponent Drift Alert"**
3. Verify it shows as **"Active"** or **"Enabled"**

### Step 2: Test Alert Query
1. Go to **Logs** section in SigNoz
2. Use the query: `message contains "hurst_estimate"`
3. Verify you can see pattern drill results
4. Check that the query returns relevant log entries

### Step 3: Generate Test Data
Run a pattern drill to generate test data:

```powershell
# Run pattern drills to generate data
pwsh -File scripts/canary-pattern-drills.ps1 -Pattern All -Duration 300 -Analyze

# Check for results
pwsh -File scripts/monitor-fractal-drift.ps1
```

### Step 4: Monitor Alert Status
1. Wait 15-20 minutes for the evaluation window
2. Check the alert status in SigNoz UI
3. Verify no false positives with normal patterns

---

## 🔧 Troubleshooting

### Issue: No Logs Found
**Symptoms**: Alert query returns no results
**Solutions**:
1. Verify pattern drills are running: `pwsh -File scripts/manage-daily-pattern-drills.ps1 -Action status`
2. Check logs directory: `Get-ChildItem C:\logs\canary-*.log`
3. Run manual pattern drill: `pwsh -File scripts/canary-pattern-drills.ps1 -Pattern All -Duration 120`

### Issue: Alert Not Triggering
**Symptoms**: Alert remains in "OK" state despite high Hurst values
**Solutions**:
1. Verify query syntax matches exactly
2. Check minimum data points requirement
3. Ensure evaluation window has sufficient data

### Issue: False Positives
**Symptoms**: Alert triggers with normal patterns (H ≈ 0.5)
**Solutions**:
1. Review threshold setting (should be 0.7)
2. Check sample size in pattern drills
3. Verify statistical significance of results

---

## 📊 Expected Behavior

### Normal Operation
- **Steady Pattern**: H ≈ 0.5 (no alert)
- **Poisson Pattern**: H ≈ 0.5 (no alert)
- **Pareto Pattern**: H ≈ 0.5-0.6 (no alert)

### Alert Conditions
- **Persistent Behavior**: H > 0.7 (alert triggers)
- **Anti-persistent**: H < 0.3 (manual investigation needed)
- **Significant Drift**: Deviation > 0.2 from expected values

---

## 📈 Monitoring Dashboard

### Recommended Dashboard Panels
1. **Hurst Exponent Trends**: Time series of H values by pattern
2. **Alert Status**: Current status of drift alert
3. **Pattern Event Counts**: Volume of events per pattern type
4. **Drift Detection**: Historical drift incidents

### Dashboard Import
Use the dashboard configuration from:
`artifacts/fractal-drift-dashboard.json`

---

## 🔄 Maintenance

### Daily Checks
1. Verify alert status in SigNoz UI
2. Check for any drift alerts
3. Review pattern drill results

### Weekly Reviews
1. Analyze Hurst exponent trends
2. Review alert effectiveness
3. Adjust thresholds if needed

### Monthly Analysis
1. Statistical validation of patterns
2. Performance optimization
3. Alert tuning based on data

---

## 📞 Support

### Scripts for Verification
- `scripts/verify-hurst-drift-alert.ps1` - Alert verification
- `scripts/monitor-fractal-drift.ps1` - Ongoing monitoring
- `scripts/manage-daily-pattern-drills.ps1` - Pattern drill management

### Documentation
- `artifacts/poisson-anomaly-analysis-report.md` - Statistical analysis
- `docs/ECRR_REPORTS/2025-10-01-log-pattern-fractal-validation.md` - Pattern validation
- `docs/ECRR_REPORTS/2025-10-01-comprehensive-implementation-summary.md` - Complete overview

---

## 🎯 Success Criteria

✅ **Alert Imported**: Hurst drift alert visible in SigNoz UI  
✅ **Alert Active**: Status shows "Active" or "Enabled"  
✅ **Query Working**: Logs query returns pattern drill results  
✅ **No False Positives**: Alert doesn't trigger with normal patterns (H ≈ 0.5)  
✅ **Drift Detection**: Alert triggers appropriately with H > 0.7  

---

*Generated by Cursor-Local (Observability Copilot) for SigNoz Alert Import*