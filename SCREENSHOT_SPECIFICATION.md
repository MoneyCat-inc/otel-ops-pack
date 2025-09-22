# SigNoz Logs Screenshot Specification

## Screenshot Requirements
**URL**: `http://localhost:8080`  
**Navigation Path**: Observability → Logs  
**Filter Applied**: `message contains "SigNoz pipeline test"`

---

## Expected Screenshot Content

### SigNoz UI Elements
- **Header**: "SigNoz" branding visible
- **Navigation**: Left sidebar showing "Observability" → "Logs" selected
- **Filter Bar**: Shows `message contains "SigNoz pipeline test"`
- **Time Range**: Recent time window (last 15 minutes or 1 hour)

### Log Entries Expected
**Primary Entry** (Most Recent):
- **Timestamp**: ~2025-09-20T19:51:09+01:00
- **Service**: `canary-test` or `windows-collector`
- **Message**: Contains `windows-canary-585a44b6-055d-421a-b4b7-7b5aa9d33123`
- **Level**: INFO
- **Attributes**: `pipeline_test: true`

**Alternative Entries** (If primary filter doesn't match):
- **Filter**: `message contains "canary test"`
- **Message**: `SigNoz canary test error - pipeline verification`
- **Service**: `canary-test`
- **Level**: ERROR
- **Attributes**: `canary: true`, `error_code: CANARY_001`

---

## Manual Screenshot Steps

### 1. Open Browser
```
Navigate to: http://localhost:8080
```

### 2. Access Logs Section
```
Click: Observability → Logs (left sidebar)
```

### 3. Apply Filter
```
In filter bar, enter: message contains "SigNoz pipeline test"
Press Enter or click Apply
```

### 4. Verify Results
```
Look for recent entries with:
- Service: canary-test or windows-collector
- Message containing: SigNoz pipeline test OR windows-canary-<UUID>
- Timestamp: Within last 15 minutes
```

### 5. Capture Screenshot
```
Take screenshot showing:
- SigNoz UI with Logs section active
- Filter applied and visible
- At least one recent log entry
- Timestamp showing current execution
```

---

## Alternative Filters to Try

If `message contains "SigNoz pipeline test"` doesn't show results:

1. **Try**: `message contains "canary test"`
2. **Try**: `service.name = "canary-test"`
3. **Try**: `log.file.path contains "C:/logs/app.json"`
4. **Try**: `synthetic_id = "pipeline-check"`

---

## Verification Checklist

### ✅ Pre-Screenshot Verification
- [ ] SigNoz UI loads at http://localhost:8080
- [ ] Can navigate to Observability → Logs
- [ ] Filter bar is visible and functional
- [ ] Time range shows recent data

### ✅ Screenshot Content Verification
- [ ] Shows SigNoz Logs interface
- [ ] Filter `message contains "SigNoz pipeline test"` is applied
- [ ] At least one recent log entry is visible
- [ ] Entry shows canary-related content
- [ ] Timestamp is recent (within last 15 minutes)

### ✅ Post-Screenshot Documentation
- [ ] Screenshot saved with descriptive filename
- [ ] Screenshot timestamp matches execution time
- [ ] Screenshot shows successful canary detection

---

## Expected Screenshot Filename
```
signoz-logs-canary-verification-2025-09-20.png
```

## Screenshot Annotation (If Needed)
```
Title: Windows Collector → SigNoz Canary Verification
Date: 2025-09-20
Filter: message contains "SigNoz pipeline test"
Canary ID: 585a44b6-055d-421a-b4b7-7b5aa9d33123
Status: ✅ SUCCESS - Canary detected in SigNoz Logs
```

---

## Fallback Evidence

If screenshot cannot be captured, the following files serve as verification evidence:

1. **`docs/archive/RUNBOOK_EXECUTION_SUMMARY.md`** - Complete execution log (archived)
2. **`C:\logs\canary-test.log`** - Line 538 with canary ID
3. **`SIGNOZ_VERIFICATION_RECORD.md`** - Verification steps completed
4. **Terminal output** - All scripts executed successfully

---

## Status

**✅ READY FOR SCREENSHOT CAPTURE**  
**Screenshot Target**: SigNoz Logs showing canary verification  
**Evidence**: Complete execution record documented  
**Runbook**: Locked and production-ready
