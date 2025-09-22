# SigNoz Authentication Setup Guide

## Overview

This guide covers setting up authentication for SigNoz API queries, particularly for `/api/v5/*` endpoints that require authentication.

## Current Status

- **Public Endpoints** (no auth required):
  - `/api/v1/health` ✅ Working
  - `/api/v1/version` ✅ Working
  - UI pages (http://localhost:8080/logs) ✅ Working

- **Authenticated Endpoints** (auth required):
  - `/api/v5/query_range` ❌ Returns 401 Unauthorized
  - `/api/v5/query` ❌ Returns 401 Unauthorized

## Authentication Methods

### Method 1: JWT Token (Attempted)
**Status**: ❌ Not working with current setup
```bash
# Tested token from docker-compose.yml
curl -H 'Authorization: Bearer YourSuperSecretJWTToken123!@#WithAtLeast32CharactersLong' \
     http://localhost:8080/api/v5/query_range
# Result: 401 Unauthorized
```

### Method 2: Session-based Authentication
**Status**: ⚠️ Requires manual setup
1. Visit http://localhost:8080 in browser
2. Login if prompted (check if authentication is enabled)
3. Extract session cookie from browser dev tools
4. Use cookie in subsequent requests

### Method 3: API Key Authentication
**Status**: ⚠️ May need to be enabled
1. Check SigNoz UI settings for API key configuration
2. Generate API key if available
3. Use header: `X-API-Key: <api-key>`

### Method 4: Disable Authentication (Local Development)
**Status**: ⚠️ May require configuration changes
For local development, authentication might be disabled or configured differently.

## Current Workaround

The monitoring scripts have been updated to use public endpoints only:
- Health checks via `/api/v1/health`
- Version info via `/api/v1/version`
- UI accessibility checks
- OTLP endpoint connectivity tests

## Helper Functions

Created `scripts/signoz-auth-helpers.ps1` with functions for authenticated requests:
```powershell
# Load helpers
. scripts\signoz-auth-helpers.ps1

# Use functions
Get-SigNozLogs -Filter "message contains 'canary test'" -Limit 10
Invoke-SigNozQuery -Query $queryJson -AuthToken $token
```

## Next Steps

1. **Investigate SigNoz Configuration**:
   - Check if authentication is enabled in local setup
   - Review SigNoz documentation for local development auth
   - Verify JWT configuration in docker-compose.yml

2. **Alternative Approaches**:
   - Use UI-based queries for manual verification
   - Implement log file parsing as backup
   - Consider ClickHouse direct queries for metrics

3. **Production Considerations**:
   - Set up proper authentication for production
   - Use API keys or service accounts
   - Implement token rotation

## Files Created

- `scripts/setup-signoz-auth.ps1` - Authentication setup helper
- `scripts/signoz-auth-helpers.ps1` - Helper functions for authenticated requests
- `docs/SIGNOZ_AUTH_SETUP.md` - This documentation

## Testing Commands

```powershell
# Test authentication setup
pwsh -File scripts\setup-signoz-auth.ps1 -TestAuth -AuthToken "YourSuperSecretJWTToken123!@#WithAtLeast32CharactersLong"

# Test helper functions
. scripts\signoz-auth-helpers.ps1
Get-SigNozLogs -Filter "canary test" -Limit 5

# Manual UI verification
Start-Process "http://localhost:8080/logs"
```

## Troubleshooting

### 401 Unauthorized Errors
- Check if authentication is required for the endpoint
- Verify token format and validity
- Try session-based authentication
- Check SigNoz logs for authentication errors

### No Data in Queries
- Verify logs are actually being ingested
- Check OTLP endpoint connectivity
- Review collector configuration
- Use UI to verify data exists

### Token Issues
- Ensure token is from correct environment
- Check token expiration
- Verify token has required permissions
- Try regenerating token
