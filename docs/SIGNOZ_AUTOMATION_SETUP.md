# SigNoz Automation Setup

## Overview

This guide explains how to set up automated testing for the SigNoz observability platform integration. The automation uses Playwright to perform end-to-end testing of SigNoz authentication, navigation, and functionality.

## Prerequisites

- Node.js 18+
- pnpm package manager
- Docker and Docker Compose
- SigNoz instance running (local or remote)

## Repository Secrets

The automation requires two repository secrets to be configured in GitHub:

| Secret Name   | Purpose                |
|---------------|------------------------|
| `SIGNOZ_USER` | SigNoz login email     |
| `SIGNOZ_PASS` | SigNoz login password  |

### Setting Repository Secrets

1. Navigate to your GitHub repository
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add both `SIGNOZ_USER` and `SIGNOZ_PASS` with your SigNoz credentials

## Local Development Setup

### Environment Variables

Set these environment variables for local testing:

```powershell
$env:SIGNOZ_URL  = "http://localhost:8080"
$env:SIGNOZ_USER = "<sigNoz-email>"
$env:SIGNOZ_PASS = "<sigNoz-password>"
```

Or for bash/zsh:

```bash
export SIGNOZ_URL="http://localhost:8080"
export SIGNOZ_USER="<sigNoz-email>"
export SIGNOZ_PASS="<sigNoz-password>"
```

### Installation

```bash
# Install dependencies with pinned versions
pnpm run install:pinned

# Install Playwright browsers
pnpm exec playwright install --with-deps
```

### Running Tests

```bash
# Run SigNoz automation tests
pnpm run test:signoz

# Run complete automation suite
pnpm run automate:signoz
```

## CI/CD Integration

### Workflow Triggers

The automation runs on:

- **Schedule**: Nightly at 2 AM UTC
- **Manual**: Via GitHub Actions workflow dispatch
- **Push**: On changes to SigNoz-related files

### Workflow Steps

1. **Setup**: Install dependencies and Playwright browsers
2. **Start SigNoz**: Launch SigNoz stack via Docker Compose
3. **Health Check**: Wait for SigNoz to be ready
4. **Run Tests**: Execute Playwright test suite
5. **Upload Artifacts**: Collect test reports and failure artifacts
6. **Cleanup**: Stop SigNoz stack and clean up resources

### Artifacts

The workflow automatically uploads:

- **Playwright Report**: HTML test report
- **Test Results**: Screenshots, videos, traces on failures
- **Logs**: SigNoz startup and error logs

## File Structure

```
tests/signoz.final.spec.ts          # Main test suite
playwright.signoz.config.ts         # Playwright configuration
scripts/automate-signoz-setup.ps1   # PowerShell automation script
.github/workflows/signoz-automation.yml  # CI workflow
docs/SIGNOZ_AUTOMATION_SETUP.md     # This documentation
```

## Test Coverage

The automation tests cover:

- **Health Check**: SigNoz API availability
- **Authentication**: Login flow and session management
- **Navigation**: Dashboard, logs, and alerts page access
- **Search Functionality**: Logs search and filtering

## Troubleshooting

### Common Issues

#### Missing Credentials
```
Error: SIGNOZ_USER is required for SigNoz automation
```
**Solution**: Set the required environment variables or repository secrets.

#### SigNoz Not Reachable
```
Error: SigNoz not reachable at http://localhost:8080
```
**Solution**: Ensure SigNoz is running and accessible at the specified URL.

#### Authentication Failures
```
Error: Authentication tests failing
```
**Solution**: Verify credentials are correct and SigNoz is properly configured.

### Debug Commands

```bash
# Check SigNoz health
curl -f http://localhost:8080/api/v1/health

# View SigNoz logs
docker logs signoz --tail 50

# Run tests in debug mode
pnpm run test:signoz:debug

# View Playwright traces
pnpm exec playwright show-trace test-results/*/trace.zip
```

## Security Considerations

- **Never commit credentials** to version control
- **Use repository secrets** for CI/CD environments
- **Rotate credentials regularly** for security
- **Monitor access logs** for unauthorized usage

## Maintenance

### Regular Tasks

- **Credential Rotation**: Update repository secrets quarterly
- **Version Updates**: Keep SigNoz and dependencies current
- **Test Monitoring**: Review automation results and failures
- **Documentation Updates**: Keep setup guides current

### Monitoring

The automation provides:

- **Success Notifications**: Confirmation of passing tests
- **Failure Alerts**: Detailed error information and artifacts
- **Health Reports**: Regular status updates
- **Performance Metrics**: Test execution times and success rates

## Support

For issues with the automation:

1. **Check Logs**: Review workflow execution logs
2. **Verify Setup**: Ensure all prerequisites are met
3. **Test Locally**: Run tests in your local environment
4. **Review Artifacts**: Examine uploaded test reports and traces

## Contributing

When modifying the automation:

1. **Test Locally**: Verify changes work in your environment
2. **Update Documentation**: Keep setup guides current
3. **Follow Patterns**: Maintain consistent code style
4. **Add Tests**: Include appropriate test coverage for new features