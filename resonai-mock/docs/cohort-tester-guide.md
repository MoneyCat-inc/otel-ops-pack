# Cohort Tester Guide

## Overview

This guide provides instructions for beta testers participating in the Resonai cohort program. The cohort logging system allows controlled testing of new features while maintaining complete privacy and data sovereignty.

## What is Cohort Logging?

Cohort logging is a **local-only** system that:
- Records your practice session summaries on your device
- Tracks which features are enabled during each session
- Provides export and deletion capabilities for complete data control
- Never transmits data to external servers

## Opt-In Instructions

### Step 1: Enable Cohort Features

Cohort logging is **disabled by default** for privacy. To enable:

1. **Environment Variables** (for developers):
   ```bash
   # Set these environment variables
   NEXT_PUBLIC_COHORT_ENABLED=1
   NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY=1
   NEXT_PUBLIC_COHORT_EVENT_SUMMARY=1
   ```

2. **Browser Console** (for testers):
   ```javascript
   // Enable cohort features (run in browser console)
   window.__env = {
     NEXT_PUBLIC_COHORT_ENABLED: '1',
     NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
     NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1'
   };
   // Refresh the page
   location.reload();
   ```

### Step 2: Verify Activation

After enabling, you should see:
- Cohort features in the progress dashboard
- Local event summaries after practice sessions
- Access to `/labs/cohort-log` page

### Step 3: Start Testing

1. Complete practice sessions as normal
2. Each session will be automatically logged locally
3. View logged sessions at `/labs/cohort-log`
4. Export data or clear logs as needed

## Feature Flags Explained

| Flag | Purpose | Default |
|------|---------|---------|
| `NEXT_PUBLIC_COHORT_ENABLED` | Master switch for all cohort features | `0` (OFF) |
| `NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY` | Show progress dashboard CTA | `0` (OFF) |
| `NEXT_PUBLIC_COHORT_EVENT_SUMMARY` | Show local session summaries | `0` (OFF) |

## What Gets Logged

### Session Data
- Session timestamp and duration
- Voice metrics (in-band percentage, prosody variation)
- Comfort and fatigue ratings
- Memory strain indicators (if MEMX enabled)
- Resonance bucket bias data

### Metadata
- Cohort ID (local UUID for session tracking)
- Build hash (for version tracking)
- Enabled feature flags
- Browser user agent
- Viewport dimensions
- Platform information

### What's NOT Logged
- Audio recordings or raw audio data
- Personal identifying information
- Location data
- Any data transmitted to external servers

## Privacy & Data Control

### Complete Local Storage
- All data stays on your device
- No network transmission
- No cloud storage
- No third-party analytics

### Data Export
- Export all logged data as JSON
- Download includes timestamps and metadata
- Use for personal analysis or sharing with developers

### Data Deletion
- Clear all logged data with one click
- Immediate and permanent deletion
- No recovery possible (by design)

## Error Reporting Guidelines

### When to Report Issues
- Cohort features not activating after enabling flags
- Session data not appearing in logs
- Export/download functionality failing
- UI accessibility issues
- Performance problems during logging

### How to Report
1. **Screenshot** the issue if possible
2. **Browser console logs** (F12 → Console tab)
3. **Steps to reproduce** the problem
4. **Expected vs actual behavior**
5. **Browser and OS information**

### Information to Include
```javascript
// Run this in browser console and include output
console.log('Cohort Debug Info:', {
  flags: window.__env,
  userAgent: navigator.userAgent,
  platform: navigator.platform,
  viewport: { width: window.innerWidth, height: window.innerHeight },
  localStorage: Object.keys(localStorage).filter(k => k.includes('cohort'))
});
```

## Troubleshooting

### Cohort Features Not Showing
1. Verify environment variables are set correctly
2. Check browser console for errors
3. Ensure page is refreshed after enabling flags
4. Try disabling and re-enabling flags

### Sessions Not Logging
1. Confirm cohort features are enabled
2. Check browser console for logging errors
3. Verify localStorage is available and not full
4. Try clearing browser cache and cookies

### Export Not Working
1. Check browser download permissions
2. Ensure popup blockers are disabled
3. Try different browser or incognito mode
4. Check available disk space

### Performance Issues
1. Clear old log data if many sessions logged
2. Disable other browser extensions temporarily
3. Check system memory usage
4. Try reducing browser tab count

## Data Schema

### Session Log Entry
```json
{
  "cohortId": "uuid-v4-string",
  "timestamp": 1640995200000,
  "buildHash": "build-abc123",
  "flagsEnabled": ["cohort", "dashboard-entry"],
  "sessionSummary": {
    "ts": 1640995200000,
    "inBandPct": 0.75,
    "comfort": 4,
    "fatigue": 2,
    "memx": {
      "memoryStrainPct": 0.15,
      "bucketBias": {
        "front": 0.3,
        "central": 0.5,
        "back": 0.2
      }
    }
  },
  "metadata": {
    "userAgent": "Mozilla/5.0...",
    "viewport": { "width": 1920, "height": 1080 },
    "platform": "Win32",
    "cohortVersion": "1.0.0"
  }
}
```

## Best Practices

### For Testers
- Enable cohort features only when actively testing
- Export data regularly for backup
- Clear logs periodically to manage storage
- Report issues promptly with detailed information

### For Developers
- Always default flags to OFF
- Provide clear opt-in mechanisms
- Include comprehensive error handling
- Maintain backward compatibility

## Support

### Getting Help
- Check this guide first for common issues
- Search existing issues in the project repository
- Create new issue with detailed reproduction steps
- Include debug information from browser console

### Contact Information
- **Issues**: Create GitHub issue with `cohort-logging` label
- **Questions**: Use GitHub Discussions
- **Security**: Report privately via security contact

## Changelog

### Version 1.0.0
- Initial cohort logging implementation
- Local-only storage with export/clear functionality
- Feature flag system for controlled rollout
- Comprehensive tester documentation

---

**Remember**: Cohort logging is designed for privacy-first testing. All data remains on your device, and you have complete control over what gets logged and when it gets deleted.
