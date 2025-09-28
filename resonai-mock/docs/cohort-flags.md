# Cohort Feature Flags

## Overview

Cohort feature flags enable controlled rollout of analytics and dashboard features to a small pilot group of users. All flags default to **OFF** to maintain privacy and ensure no unintended exposure.

## Flag Configuration

### Environment Variables

| Flag | Environment Variable | Default | Description |
|------|---------------------|---------|-------------|
| **Master Switch** | `NEXT_PUBLIC_COHORT_ENABLED` | `0` | Enables cohort features |
| **Dashboard Entry** | `NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY` | `0` | Shows Progress CTA in navigation |
| **Event Summary** | `NEXT_PUBLIC_COHORT_EVENT_SUMMARY` | `0` | Shows local session summary |

### Flag Hierarchy

- **Master Flag Required**: `dashboardEntry` and `eventSummary` require `enabled: true`
- **Independent Operation**: Each sub-flag can be enabled/disabled independently
- **Default OFF**: All flags default to `false` for privacy

## Usage Examples

### Default Configuration (All OFF)
```bash
# .env.local
NEXT_PUBLIC_COHORT_ENABLED=0
NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY=0
NEXT_PUBLIC_COHORT_EVENT_SUMMARY=0
```
**Result**: No cohort features visible, standard UI unchanged.

### Enable All Cohort Features
```bash
# .env.local
NEXT_PUBLIC_COHORT_ENABLED=1
NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY=1
NEXT_PUBLIC_COHORT_EVENT_SUMMARY=1
```
**Result**: Progress CTA in navigation + local event summary on practice page.

### Enable Dashboard Entry Only
```bash
# .env.local
NEXT_PUBLIC_COHORT_ENABLED=1
NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY=1
NEXT_PUBLIC_COHORT_EVENT_SUMMARY=0
```
**Result**: Progress CTA visible, no event summary.

### Enable Event Summary Only
```bash
# .env.local
NEXT_PUBLIC_COHORT_ENABLED=1
NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY=0
NEXT_PUBLIC_COHORT_EVENT_SUMMARY=1
```
**Result**: Event summary on practice page, no navigation CTA.

## Safe Combinations

### ✅ Valid Combinations
- All OFF (default)
- All ON (full cohort experience)
- Master + Dashboard Entry only
- Master + Event Summary only

### ❌ Invalid Combinations
- Dashboard Entry without Master
- Event Summary without Master
- Sub-flags without Master flag

## Implementation Details

### Flag Resolver
```typescript
import { flags, shouldShowDashboardEntry, shouldShowEventSummary } from '@/config/flags';

// Check if cohort features are enabled
if (shouldShowDashboardEntry()) {
  // Show dashboard CTA
}

if (shouldShowEventSummary()) {
  // Show local event summary
}
```

### Client-Side Environment
The flag resolver works in both SSR and CSR contexts:
- **Server-side**: Reads from `process.env`
- **Client-side**: Reads from `window.__env` (if available) or falls back to `process.env`

### Validation
```typescript
import { validateFlags } from '@/config/flags';

if (!validateFlags()) {
  console.warn('Invalid cohort flag configuration');
}
```

## Privacy & Security

### Local-Only Data
- **No Network Calls**: All cohort features read from local IndexedDB
- **No Uploads**: Event summaries never leave the device
- **No Beacons**: No analytics tracking or telemetry

### Data Sources
- **Session Data**: Reads from existing IndexedDB sessions
- **Aggregation**: Client-side calculation of metrics
- **Display Only**: No data modification or export

## Accessibility

### Keyboard Navigation
- **Focusable Elements**: All cohort CTAs are keyboard accessible
- **Focus Rings**: Visible focus indicators for keyboard users
- **Tab Order**: Logical tab sequence through cohort features

### Screen Reader Support
- **ARIA Labels**: Descriptive labels for all interactive elements
- **Semantic HTML**: Proper heading structure and landmarks
- **Live Regions**: Status updates announced appropriately

### Reduced Motion
- **Respects Preferences**: Honors `prefers-reduced-motion` setting
- **Static Fallbacks**: Non-animated alternatives for all transitions
- **CSS Overrides**: Global CSS disables animations when reduced motion preferred

## Testing

### Unit Tests
```bash
# Test flag resolver
pnpm test:unit --filter flags
```

### E2E Tests
```bash
# Test cohort behavior
pnpm test:e2e --grep "@cohort-flags"
```

### Test Scenarios
- **Flags OFF**: UI unchanged, no cohort features visible
- **Flags ON**: CTA visible, summary renders, navigation works
- **Partial Flags**: Only enabled features visible
- **Invalid Values**: Graceful fallback to defaults
- **Cross-Browser**: Firefox + Chromium compatibility

## Troubleshooting

### Common Issues

#### Flags Not Working
1. **Check Environment**: Verify `.env.local` has correct values
2. **Restart Dev Server**: Environment changes require restart
3. **Clear Cache**: Run `pnpm run qa:clear-cache`

#### Invalid Flag Combinations
1. **Check Master Flag**: Ensure `NEXT_PUBLIC_COHORT_ENABLED=1`
2. **Validate Configuration**: Run `validateFlags()` in console
3. **Check Console**: Look for validation warnings

#### UI Not Updating
1. **Hard Refresh**: Clear browser cache
2. **Check Network**: Ensure no network calls being made
3. **Verify Flags**: Check `getDebugInfo()` output

### Debug Information
```typescript
import { getDebugInfo } from '@/config/flags';

console.log(getDebugInfo());
// Outputs: flags, enabledFeatures, isValid, environment
```

## Deployment

### Production Configuration
- **Default OFF**: All flags default to `false` in production
- **Environment Variables**: Set via deployment platform
- **No Code Changes**: Flag changes don't require code deployment

### Rollout Strategy
1. **Start Small**: Enable for internal team first
2. **Monitor**: Check for errors and performance impact
3. **Gradual Rollout**: Increase cohort size over time
4. **Quick Rollback**: Set flags to `0` to disable immediately

## Future Enhancements

### Planned Features
- **A/B Testing**: Split cohort into test groups
- **Gradual Rollout**: Percentage-based feature enablement
- **Feature Dependencies**: More complex flag relationships
- **Analytics**: Optional usage tracking (with consent)

### Considerations
- **Performance**: Monitor impact of additional UI elements
- **User Experience**: Ensure smooth transitions between states
- **Maintenance**: Keep flag logic simple and maintainable
