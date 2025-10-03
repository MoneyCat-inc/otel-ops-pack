# SigNoz Automation Fresh Setup Guide

## Overview

This guide covers the **fresh SigNoz automation** system that addresses all the issues we've encountered and learned from. The new system includes:

- **Pre-flight validation** for secrets and environment
- **Robust error handling** with detailed troubleshooting
- **Docker Compose compatibility** checks
- **Enhanced logging** and debugging capabilities
- **Graceful fallbacks** when components are unavailable

## Files Created

### 1. Fresh Workflow
- **`.github/workflows/signoz-automation-fresh.yml`** - Complete rewrite with all improvements

### 2. Enhanced Script
- **`scripts/automate-signoz-setup-fresh.ps1`** - Improved PowerShell automation script

### 3. Updated Package Scripts
- **`package.json`** - Added `automate:signoz:fresh` command

## Key Improvements

### ✅ **Secret Validation**
- Pre-flight check for `SIGNOZ_USER` and `SIGNOZ_PASS`
- Clear error messages when secrets are missing
- Graceful fallback job with setup instructions

### ✅ **Docker Compose Compatibility**
- Detects both `docker-compose` and `docker compose` commands
- Verifies Docker availability before attempting to start services
- Clear error messages if Docker is not available

### ✅ **Enhanced Health Checks**
- Multi-stage health verification (ClickHouse → Schema Migrator → SigNoz API)
- Detailed logging with timestamps
- Proper timeout handling for each stage

### ✅ **Better Error Handling**
- Comprehensive container log collection on failure
- Detailed troubleshooting steps in error messages
- Always cleanup infrastructure, even on failure

### ✅ **Improved Logging**
- Verbose mode support (`-Verbose` flag)
- Progress indicators with emojis
- Clear success/failure messaging

## Usage

### Local Development

```powershell
# Set credentials (required)
$env:SIGNOZ_USER = "your-email@example.com"
$env:SIGNOZ_PASS = "your-password"

# Run fresh automation
pnpm run automate:signoz:fresh

# With verbose logging
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/automate-signoz-setup-fresh.ps1 -Verbose
```

### CI/CD

The fresh workflow will automatically:
1. **Validate secrets** before starting any jobs
2. **Check Docker availability** in the runner
3. **Start SigNoz infrastructure** with proper health checks
4. **Run Playwright tests** with comprehensive error handling
5. **Upload artifacts** (reports, screenshots, videos)
6. **Cleanup infrastructure** regardless of test results

## Troubleshooting

### Missing Secrets
```
❌ Missing required secrets: SIGNOZ_USER or SIGNOZ_PASS
```
**Solution**: Add secrets in GitHub → Settings → Secrets and variables → Actions

### Docker Not Available
```
❌ Docker not available in this runner
```
**Solution**: Use `ubuntu-latest` runner or enable Docker in self-hosted runners

### SigNoz Not Reachable
```
❌ SigNoz not reachable at http://localhost:8080
```
**Solution**: 
1. Start SigNoz: `docker compose -f docker-compose-signoz.yml up -d`
2. Wait for startup: `timeout 300 bash -c "until curl -sf http://localhost:8080/api/v1/health; do sleep 5; done"`

### Tests Failing
```
❌ Some tests failed
```
**Solution**:
1. Check Playwright report: `npx playwright show-report`
2. Verify credentials: `$env:SIGNOZ_USER` and `$env:SIGNOZ_PASS`
3. Check SigNoz health: `curl -sf http://localhost:8080/api/v1/health`

## Migration from Old System

### Replace Old Workflow
1. **Disable old workflow**: Rename `.github/workflows/signoz-automation.yml` to `.github/workflows/signoz-automation-old.yml`
2. **Enable fresh workflow**: The new workflow is already active as `signoz-automation-fresh.yml`

### Update Scripts
```powershell
# Old command
pnpm run automate:signoz

# New command (recommended)
pnpm run automate:signoz:fresh
```

### Update CI Triggers
The fresh workflow triggers on the same paths, so existing CI will automatically use the new system.

## Benefits of Fresh System

1. **Reliability**: Pre-flight checks prevent common failure modes
2. **Debugging**: Comprehensive logging and error messages
3. **Compatibility**: Works with different Docker Compose versions
4. **Maintainability**: Clear separation of concerns and modular design
5. **User Experience**: Helpful error messages and troubleshooting guidance

## Next Steps

1. **Test locally**: Run `pnpm run automate:signoz:fresh` to verify everything works
2. **Add secrets**: Ensure `SIGNOZ_USER` and `SIGNOZ_PASS` are set in repository settings
3. **Trigger workflow**: Run the "SigNoz Automation (Fresh)" workflow in GitHub Actions
4. **Monitor results**: Check workflow runs and artifacts for any remaining issues

The fresh system is designed to be robust, maintainable, and provide clear feedback when issues occur. It incorporates all the lessons learned from our previous automation attempts.

