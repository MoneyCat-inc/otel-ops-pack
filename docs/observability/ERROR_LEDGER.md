# 🚨 Error Ledger - Money Trail Tracking

**Purpose**: Track error fingerprints, their monetization potential, and resolution status for the "cat$$" error detection system.

## 📊 Current Error Inventory

| Fingerprint | First Seen | First PR | Status | Total Repeats | Last Seen | Resolution |
|-------------|------------|----------|--------|---------------|-----------|------------|
| *No errors tracked yet* | | | | | | |

## 🎯 Error Categories

### 🚨 NEW ERRORS (Billable)
- **Status**: `open` - New error requiring investigation
- **Action**: Immediate notification, high priority
- **Value**: High - represents new issues to fix

### 🔄 KNOWN ERRORS (Quiet Channel)
- **Status**: `tracking` - Known error being monitored
- **Action**: Aggregated reporting, periodic review
- **Value**: Medium - ongoing issues requiring attention

### ✅ RESOLVED ERRORS
- **Status**: `fixed` - Error resolved via PR
- **Action**: Verify no new occurrences for 24h
- **Value**: Completed - issue resolved

### ⏸️ IGNORED ERRORS
- **Status**: `ignored` - Deliberately not fixed
- **Action**: Continue quiet monitoring
- **Value**: Low - known acceptable issues

## 📈 Metrics & KPIs

### Error Detection Coverage
- **New Errors/Week**: Target < 5
- **Resolution Time**: Target < 48h
- **Error Recurrence**: Target < 10%
- **Noise Reduction**: Target > 80%

### Money Trail Metrics
- **Billable Errors**: New errors requiring immediate attention
- **Cost Avoidance**: Errors caught before production impact
- **ROI**: Time saved by early error detection vs. investigation time

## 🔧 CLI Commands

### Add Error to Ledger
```bash
pnpm ledger:add <fingerprint> --pr <pr-id> --note "description"
```

### Update Error Status
```bash
pnpm ledger:update <fingerprint> --status <open|fixed|ignored> --pr <pr-id>
```

### Generate Error Report
```bash
pnpm ledger:report --period <7d|30d> --format <markdown|json>
```

### Check Error Status
```bash
pnpm ledger:check <fingerprint>
```

## 🎯 SigNoz Queries

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

### Most Frequent Known Errors
```sql
SELECT 
  attributes['error.fp'] as fingerprint,
  attributes['error.origin'] as origin,
  attributes['service.name'] as service,
  count() as occurrences,
  max(timestamp) as last_seen
FROM signoz_logs 
WHERE attributes['error.known'] = 'true'
  AND timestamp > now() - INTERVAL 7 DAY
GROUP BY fingerprint, origin, service
ORDER BY occurrences DESC
LIMIT 20
```

### Error Resolution Timeline
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

### Impact
- **Errors Prevented**: {{ count }}
- **Services Affected**: {{ services }}
- **Business Impact**: {{ impact }}
```

## 🔍 Error Investigation Workflow

1. **Detection**: New error appears in SigNoz with `error.known=false`
2. **Alert**: Immediate notification to on-call engineer
3. **Investigation**: Analyze fingerprint, stack trace, and context
4. **Prioritization**: Assess business impact and urgency
5. **Resolution**: Create PR with fix and test coverage
6. **Verification**: Confirm no new occurrences for 24h
7. **Documentation**: Update error ledger with resolution details

## 📊 Dashboard Queries

### Error Radar Dashboard
- **New Errors Today**: `error.known=false AND timestamp > today()`
- **Top Error Sources**: Group by `error.origin`
- **Service Error Rates**: Group by `service.name`
- **Error Resolution Time**: Time from first seen to last seen

### Noise Reduction Metrics
- **Quiet Channel Effectiveness**: `error.known=true` vs `error.known=false`
- **Suppression Rate**: `error.suppressed` / `error.count`
- **Re-notification Frequency**: Errors that become loud again

## 🎯 Success Criteria

- **Error Detection**: > 95% of runtime errors captured
- **Noise Reduction**: < 1 notification per error per 6h window
- **Resolution Time**: < 48h for critical errors
- **False Positive Rate**: < 5% of alerts are false positives
- **Coverage**: All services have error radar enabled

---

**Last Updated**: 2025-10-04T00:30:00Z  
**Next Review**: 2025-10-11T00:30:00Z  
**Maintainer**: Error Radar System
