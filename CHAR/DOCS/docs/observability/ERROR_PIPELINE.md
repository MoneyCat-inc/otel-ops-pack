# 🚨 Error Pipeline - Detection, Deduplication & Monetization

**Purpose**: Comprehensive error detection system that maximizes coverage while minimizing noise through intelligent fingerprinting and quiet channel management.

## 🎯 System Overview

The Error Pipeline implements a "Error Radar + Quiet Channel" strategy:

1. **Detect More**: Capture errors from Node.js, browsers, PowerShell, and HTTP layers
2. **Fingerprint & Dedupe**: Normalize and hash errors to identify duplicates
3. **Quiet Channel**: Suppress repeat notifications while maintaining visibility
4. **Monetize**: Focus on new errors (billable) vs known errors (tracking)

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Error Sources │───▶│  Error Radar     │───▶│   SigNoz        │
│                 │    │                  │    │                 │
│ • Node.js       │    │ • Fingerprinting │    │ • Logs          │
│ • Browser       │    │ • Deduplication  │    │ • Metrics       │
│ • PowerShell    │    │ • Noise Reduction│    │ • Alerts        │
│ • HTTP          │    │ • Registry       │    │ • Dashboards    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │  Error Ledger    │
                       │                  │
                       │ • Money Trail    │
                       │ • Resolution     │
                       │ • ROI Tracking   │
                       └──────────────────┘
```

## 🔧 Components

### 1. Error Detection (Input Sources)

#### Node.js Runtime
```typescript
import { bootstrapErrorRadar } from './scripts/agent/error-watcher/error-radar';

// Bootstrap in your app startup
bootstrapErrorRadar({
    serviceName: 'my-service',
    enableProcessWarnings: true,
    enableUnhandledRejections: true,
    enableUncaughtExceptions: true
});
```

#### Browser (Playwright + Runtime)
```typescript
// In Playwright tests
import { test } from './tests/e2e/setup/hardening';

test('should capture browser errors', async ({ page }) => {
    // Errors automatically captured via page error handlers
    await page.goto('http://localhost:3000');
    // Any page errors will be captured and fingerprinted
});
```

#### PowerShell Scripts
```powershell
$ErrorActionPreference = "Stop"
trap { 
    & node scripts/agent/error-watcher/publish.ps1-adapter.js `
        --message $_.Exception.Message `
        --stack $_.InvocationInfo.PositionMessage `
        --file $_.InvocationInfo.ScriptName `
        --line $_.InvocationInfo.ScriptLineNumber
    break
}
```

#### HTTP Middleware
```typescript
import { createErrorMiddleware } from './scripts/agent/error-watcher/error-radar';

app.use(createErrorMiddleware({
    serviceName: 'api-service',
    capture4xx: false,
    capture5xx: true
}));
```

### 2. Fingerprinting System

#### Core Algorithm
```typescript
import { fingerprint } from './scripts/agent/error-watcher/fingerprint';

// Normalizes error data to create stable hashes
const fp = fingerprint(error, { origin: 'uncaughtException', service: 'my-service' });
```

#### Normalization Rules
- Remove hex IDs and timestamps: `0x123abc` → `0x*`
- Remove absolute paths: `/full/path/file.js` → `/$CWD/file.js`
- Remove UUIDs and email addresses
- Normalize whitespace and preserve relative structure
- Focus on first 6 stack frames for stability

### 3. Deduplication & Noise Reduction

#### Registry Management
```json
{
  "fp1234abcd": {
    "firstSeen": 1690000000,
    "lastSeen": 1690001111,
    "count": 57,
    "mutedUntil": 1690004711,
    "lastMessage": "Database connection failed",
    "lastStack": "Error: Database connection failed\n    at..."
  }
}
```

#### Quiet Channel Logic
- **New Error**: First occurrence → Loud notification
- **Known Error**: Within 6h window → Quiet aggregation
- **Re-notification**: After 6h → Loud again (in case of changes)

### 4. SigNoz Integration

#### OTel Collector Configuration
```yaml
processors:
  attributes/error-enrichment:
    actions:
      - key: error.fingerprint
        action: insert
        from_attribute: error.fp
      - key: error.severity_class
        action: insert
        value: "unknown"
  
  filter/error-noise-reduction:
    logs:
      log_record:
        - 'attributes["error.fp"] != nil'
        - 'attributes["error.known"] == true and attributes["error.count"] < 10'
```

#### Structured Error Events
```json
{
  "fingerprint": "abc123def456",
  "known": false,
  "severity": "fatal",
  "origin": "uncaughtException",
  "service": "my-service",
  "message": "Database connection failed",
  "frames": [
    {"file": "database.ts", "line": 45, "fn": "connect"},
    {"file": "service.ts", "line": 123, "fn": "createUser"}
  ],
  "count": 1,
  "suppressed": 0
}
```

## 📊 SigNoz Queries & Dashboards

### New Errors (Billable)
```sql
SELECT 
  attributes['error.fp'] as fingerprint,
  attributes['error.origin'] as origin,
  attributes['service.name'] as service,
  body as message,
  timestamp
FROM signoz_logs 
WHERE attributes['error.known'] = 'false'
  AND timestamp > now() - INTERVAL 24 HOUR
ORDER BY timestamp DESC
```

### Error Trends Dashboard
```sql
SELECT 
  attributes['error.fp'] as fingerprint,
  attributes['service.name'] as service,
  count() as occurrences,
  max(timestamp) as last_seen
FROM signoz_logs 
WHERE attributes['error.known'] = 'true'
  AND timestamp > now() - INTERVAL 7 DAY
GROUP BY fingerprint, service
ORDER BY occurrences DESC
LIMIT 20
```

### Resolution Tracking
```sql
SELECT 
  attributes['error.fp'] as fingerprint,
  min(timestamp) as first_seen,
  max(timestamp) as last_seen,
  count() as total_occurrences,
  attributes['service.name'] as service
FROM signoz_logs 
WHERE attributes['error.fp'] != ''
  AND timestamp > now() - INTERVAL 30 DAY
GROUP BY fingerprint, service
HAVING last_seen < now() - INTERVAL 24 HOUR
ORDER BY first_seen DESC
```

## 🎯 Alerting Strategy

### Two-Tier Alert System

#### Tier 1: New Errors (Billable)
- **Trigger**: `error.known = false`
- **Action**: Immediate notification
- **Priority**: High
- **Value**: New issues requiring investigation

#### Tier 2: Persistent Errors
- **Trigger**: Known errors exceeding threshold (>50/hour)
- **Action**: Periodic summary
- **Priority**: Medium
- **Value**: Ongoing issues requiring attention

### Alert Configuration
```yaml
alerts:
  newErrorThreshold: 1
  persistentErrorThreshold: 50
  timeWindowHours: 1
  notificationChannels: ["sigNoz", "console"]
```

## 💰 Money Trail & ROI

### Error Ledger Management
```bash
# Add error to ledger
pnpm ledger:add abc123def456 --pr 123 --note "Fixed database connection timeout"

# Generate report
pnpm ledger:report 30d

# Check specific error
pnpm ledger:check abc123def456
```

### ROI Metrics
- **Error Detection Coverage**: >95% of runtime errors captured
- **Noise Reduction**: <1 notification per error per 6h window
- **Resolution Time**: <48h for critical errors
- **False Positive Rate**: <5% of alerts

### Cost Avoidance
- **Early Detection**: Errors caught before production impact
- **Reduced MTTR**: Faster resolution through better context
- **Preventive Maintenance**: Pattern recognition for proactive fixes

## 🧪 Testing & Validation

### Unit Tests
```typescript
// Fingerprint stability
expect(fingerprint(error1)).toBe(fingerprint(error2)); // Same errors
expect(fingerprint(error1)).not.toBe(fingerprint(error3)); // Different errors

// Token bucket suppression
const fp = captureError(error, context); // First - loud
const fp2 = captureError(error, context); // Second - quiet
```

### E2E Tests
```typescript
test('should capture and deduplicate browser errors', async ({ page }) => {
    // Induce same error twice
    await page.evaluate(() => { throw new Error('Test Error'); });
    await page.evaluate(() => { throw new Error('Test Error'); });
    
    // Verify first loud, second quiet
    // Check SigNoz logs for error.fp and error.known
});
```

### Integration Tests
```bash
# Test error capture end-to-end
node scripts/agent/error-watcher/capture.ts
node scripts/agent/error-watcher/fingerprint.ts
node scripts/agent/error-watcher/publisher.ts
```

## 🚀 Deployment & Configuration

### Environment Variables
```bash
# Error Radar Configuration
ERROR_RADAR_BROWSER=1
RENOTIFY_WINDOW_SEC=21600  # 6 hours
MAX_LOUD_PER_HOUR_PER_FP=1
ERROR_REGISTRY_TTL_DAYS=21

# Service Information
SERVICE_NAME=my-service
GIT_SHA=abc123def456
```

### Configuration File
```json
{
  "errorRadar": {
    "renotifyWindowHours": 6,
    "maxLoudPerHourPerFp": 1,
    "aggregateFlushIntervalSec": 60,
    "registryTtlDays": 21,
    "browserHook": true
  }
}
```

## 📋 PR Template Integration

```markdown
### Error Fix
- **Fingerprint**: `{{ fp }}`
- **First Seen**: {{ date }}
- **Root Cause**: {{ summary }}
- **Resolution**: {{ description }}

### Verification
- [ ] New error shows `error.known=false` in SigNoz
- [ ] After fix, no new occurrences for 24h
- [ ] Error ledger updated with resolution status
- [ ] Related tests added/updated
```

## 🎯 Success Criteria

- ✅ **Coverage**: All services have error radar enabled
- ✅ **Detection**: >95% of runtime errors captured
- ✅ **Noise Reduction**: <1 notification per error per 6h window
- ✅ **Resolution Time**: <48h for critical errors
- ✅ **False Positive Rate**: <5% of alerts
- ✅ **ROI**: Positive cost avoidance vs. implementation cost

## 🔍 Troubleshooting

### Common Issues

#### Errors Not Being Captured
- Check if error radar is bootstrapped in app startup
- Verify OTel SDK is properly configured
- Check collector configuration for error processors

#### Too Many Notifications
- Review `RENOTIFY_WINDOW_SEC` setting
- Check if fingerprinting is working correctly
- Verify quiet channel logic in registry

#### Missing Error Context
- Ensure service name is set correctly
- Check if stack traces are being preserved
- Verify OTel attribute promotion

### Debug Commands
```bash
# Check error registry
cat .agent/error_index.json | jq '.'

# Test fingerprinting
node scripts/agent/error-watcher/fingerprint.ts

# Check SigNoz logs
# Query: attributes['error.fp'] != ''

# Generate error report
pnpm ledger:report 7d
```

---

**Last Updated**: 2025-10-04T00:30:00Z  
**Next Review**: 2025-10-11T00:30:00Z  
**Maintainer**: Error Radar System
