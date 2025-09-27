# SigNoz API Authentication Setup Guide

## Overview
This guide walks you through setting up API authentication for SigNoz to enable log visibility and automated monitoring.

## Step 1: Access SigNoz UI
1. Open browser: http://localhost:8080
2. If you haven't set up SigNoz yet, you'll see the initial setup screen
3. Create an account or sign in

## Step 2: Generate API Token
1. Navigate to **Settings** (gear icon in top-right corner)
2. Click **API Keys** in the left sidebar
3. Click **Generate New API Key**
4. Fill in the details:
   - **Name**: `OTel Pipeline Monitoring`
   - **Description**: `API key for OpenTelemetry pipeline monitoring and automation`
   - **Permissions**: Select **Read** permissions (minimum required)
   - **Expiration**: Choose appropriate expiration (recommend 1 year for automation)
5. Click **Generate**
6. **Copy the API token** - you won't be able to see it again!

## Step 3: Set Environment Variable
In PowerShell (run as Administrator):
```powershell
# Set the API token
$env:SIGNOZ_API_TOKEN = 'your-actual-api-token-here'

# Make it permanent (optional)
[Environment]::SetEnvironmentVariable("SIGNOZ_API_TOKEN", "your-actual-api-token-here", "User")
```

## Step 4: Test Authentication
```powershell
# Test the authentication
pwsh -File scripts/test-signoz-auth.ps1
```

## Step 5: Verify API Access
The test script will check:
- ✅ Health endpoint (no auth required)
- ✅ Logs API with authentication
- ✅ Metrics API with authentication  
- ✅ Traces API with authentication

## Troubleshooting

### Common Issues
1. **401 Unauthorized**: Invalid or expired API token
2. **403 Forbidden**: Insufficient permissions (need Read access)
3. **HTML Response**: API token not set or invalid

### Verification Commands
```powershell
# Check if token is set
echo $env:SIGNOZ_API_TOKEN

# Test health endpoint
curl http://localhost:8080/api/v1/health

# Test with authentication
$Headers = @{ "Authorization" = "Bearer $env:SIGNOZ_API_TOKEN" }
curl -H "Authorization: Bearer $env:SIGNOZ_API_TOKEN" http://localhost:8080/api/v1/logs
```

## Next Steps
Once authentication is working:
1. Import the queue pressure dashboard
2. Configure webhook notifications
3. Test end-to-end pipeline
4. Set up automated monitoring

## Security Notes
- Keep your API token secure
- Use minimal required permissions (Read only)
- Set appropriate expiration dates
- Don't commit tokens to version control
- Use environment variables for automation
