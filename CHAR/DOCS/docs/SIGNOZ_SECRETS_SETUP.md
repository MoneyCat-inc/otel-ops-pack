# SigNoz Repository Secrets Setup

## Quick Setup Guide

### Required Secrets

The SigNoz automation requires these two repository secrets:

| Secret Name | Purpose | Example Value |
|-------------|---------|---------------|
| `SIGNOZ_USER` | SigNoz login email | `admin@example.com` |
| `SIGNOZ_PASS` | SigNoz login password | `your-secure-password` |

### Setting Secrets via GitHub Web Interface

1. **Navigate to Repository Settings**
   - Go to your GitHub repository
   - Click **Settings** tab

2. **Access Secrets Section**
   - In the left sidebar, click **Secrets and variables**
   - Click **Actions**

3. **Add Repository Secrets**
   - Click **New repository secret**
   - Enter secret name: `SIGNOZ_USER`
   - Enter secret value: Your SigNoz email/username
   - Click **Add secret**
   - Repeat for `SIGNOZ_PASS`

### Setting Secrets via GitHub CLI

```bash
# Set SIGNOZ_USER secret
gh secret set SIGNOZ_USER --body "your-signoz-email@example.com"

# Set SIGNOZ_PASS secret  
gh secret set SIGNOZ_PASS --body "your-secure-password"
```

### Verification

After setting secrets, test the automation:

```bash
# Test locally with environment variables
export SIGNOZ_USER="your-email@example.com"
export SIGNOZ_PASS="your-password"
pnpm run test:signoz

# Or trigger CI workflow manually
gh workflow run "SigNoz Automation"
```

### Security Notes

- **Never commit credentials** to version control
- **Use strong passwords** for SigNoz accounts
- **Rotate credentials regularly** (quarterly recommended)
- **Monitor access logs** in SigNoz for unauthorized usage

### Troubleshooting

#### Secret Not Found Error
```
Error: SIGNOZ_USER is required for SigNoz automation
```
**Solution**: Verify secrets are set in repository settings and workflow has access.

#### Authentication Failure
```
Error: Authentication tests failing
```
**Solution**: Verify credentials are correct and SigNoz account is active.

#### CI Workflow Fails
```
Error: Workflow failed to start
```
**Solution**: Check that secrets are properly configured and repository has Actions enabled.
