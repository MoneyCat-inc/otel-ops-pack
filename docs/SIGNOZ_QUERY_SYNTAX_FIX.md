# SigNoz Query Syntax Fix - Windows Canary Log Alert

**Issue**: Your query has syntax errors because SigNoz uses a different query language than SQL.

## ❌ Your Current Query (Incorrect)
```
log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary' | stats count() as log_count by bin(1m)
```

## ✅ Correct SigNoz Query Syntax

### Option 1: Simple Log Filter (Recommended)
```
log.file.path contains "windows-canary-test.log" AND body contains "windows-canary"
```

### Option 2: With Source Filter
```
log.source = "filelog" AND log.file.path contains "windows-canary-test.log" AND body contains "windows-canary"
```

### Option 3: Multiple Log Sources
```
(log.source = "windows_event_log" AND body contains "windows-canary") OR (log.file.path contains "windows-canary-test.log" AND body contains "windows-canary")
```

## 🔧 Step-by-Step Fix

### 1. In SigNoz UI Alert Creation:
1. **Query Type**: Select "Logs"
2. **Query**: Use one of the corrected queries above
3. **Group By**: Leave empty or use `pattern` if available
4. **Legend Format**: `{{log.source}} - {{log.file.path}} Canaries`

### 2. Alert Configuration:
```
Name: Windows Logs Canary Absence
Description: Windows canary logs missing from pipeline. Expected canary logs every 5 minutes from Windows Event Log and file log sources, but none received in last 10 minutes.
Severity: Critical
Threshold: 1
Operator: below
Evaluation Window: 10m
Alert Frequency: 2m
```

### 3. Labels (Optional):
```
service: windows-logs
component: canary-detection
severity: critical
environment: local
framework: ecrr
```

## 📊 Alternative Query Options

### For Hurst Exponent Monitoring:
```
message contains "hurst_estimate" AND log.file.path contains "canary-pattern-results.json"
```

### For Pattern Analysis:
```
message contains "windows-canary" AND attributes.pattern exists
```

### For Enhanced Validation:
```
message contains "enhanced_statistical_validation" AND log.file.path contains "enhanced-statistical-validation.json"
```

## 🚨 Common SigNoz Query Syntax Rules

1. **Use `contains` instead of `=`** for partial matches
2. **Use `AND` and `OR`** for logical operations
3. **Quote strings with double quotes** `"string"`
4. **No SQL-style aggregations** like `stats count() by bin()`
5. **Group By** is handled in the UI, not in the query
6. **Time ranges** are set in the UI, not in the query

## 🧪 Test Your Query

### Before Creating Alert:
1. Go to **Logs → Explore** in SigNoz
2. Paste your corrected query
3. Verify it returns the expected log entries
4. Check the time range shows recent data

### Expected Results:
- Should show `windows-canary-*` log entries
- Should filter by file path `windows-canary-test.log`
- Should display in the last 24 hours (or your selected range)

## 📝 Complete Alert Configuration

Use this complete configuration for your Windows canary alert:

```
Alert Name: Windows Logs Canary Absence
Description: Windows canary logs missing from pipeline. Expected canary logs every 5 minutes from Windows Event Log and file log sources, but none received in last 10 minutes.
Severity: Critical

Query Type: Logs
Query: (log.source = "windows_event_log" AND body contains "windows-canary") OR (log.file.path contains "windows-canary-test.log" AND body contains "windows-canary")
Group By: log.source
Legend Format: {{log.source}} Canaries

Threshold: 1
Operator: below
Evaluation Window: 10m
Alert Frequency: 2m
Notification on Missing Data: true
Minimum Data Points: 1

Labels:
- service: windows-logs
- component: canary-detection
- severity: critical
- environment: local
```

## 🔍 Troubleshooting

### If Query Still Doesn't Work:
1. **Check Log Format**: Verify your logs are being ingested correctly
2. **Test Simpler Query**: Try just `body contains "windows-canary"`
3. **Check Field Names**: Use SigNoz field explorer to see available fields
4. **Verify Data**: Ensure logs exist in the time range you're querying

### Field Explorer:
1. Go to **Logs → Explore**
2. Click on a log entry
3. Expand the fields to see available attribute names
4. Use the exact field names in your query

---
*Generated to fix SigNoz query syntax errors*
