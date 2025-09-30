# ECRR Compliance CI/CD Integration

## Overview

This document describes the CI/CD integration for ECRR compliance monitoring and automated reporting.

## Workflows

### 1. ECRR Compliance Check (ecrr-compliance.yml)

**Triggers:**
- Push to main/develop branches (ECRR reports or compliance scripts)
- Pull requests to main/develop branches
- Manual workflow dispatch

**Actions:**
- Runs compliance linting
- Performs trends analysis
- Generates compliance dashboard (on demand)
- Uploads artifacts
- Comments on PRs with compliance status

### 2. Scheduled Compliance Monitoring (ecrr-compliance-scheduled.yml)

**Triggers:**
- Daily at 9 AM UTC (weekdays only)
- Manual workflow dispatch

**Actions:**
- Runs compliance trends analysis
- Generates compliance dashboard
- Uploads daily reports
- Creates GitHub issues for compliance alerts

## Usage

### Manual Compliance Check
\\\ash
# Trigger compliance check manually
gh workflow run "ECRR Compliance Check" --ref main
\\\

### Generate Dashboard
\\\ash
# Generate compliance dashboard
gh workflow run "ECRR Compliance Check" --ref main -f generate_dashboard=true
\\\

### Post-Workshop Validation
\\\powershell
# Run after workshop sessions
pwsh -File scripts/post-workshop-validation.ps1 -WorkshopName "workshop-2025-01-27" -GenerateTrends -SendAlerts
\\\

## Monitoring

### Compliance Thresholds
- **Green**: ≥80% compliance rate
- **Yellow**: 60-79% compliance rate  
- **Red**: <60% compliance rate

### Alert Conditions
- Compliance rate below threshold
- Declining trend (>2% decrease)
- Failed workshop reports

### Artifacts
- Compliance reports (30-day retention)
- Trends data (30-day retention)
- Compliance dashboard (30-day retention)
- Daily reports (7-day retention)

## Integration Points

### GitHub Actions
- Automated compliance checking
- PR status comments
- Scheduled monitoring
- Issue creation for alerts

### Local Scripts
- Post-workshop validation
- Trends monitoring
- Dashboard generation
- Compliance linting

## Troubleshooting

### Common Issues
1. **Workflow fails**: Check PowerShell script syntax
2. **Missing artifacts**: Verify file paths and permissions
3. **Trends not updating**: Check historical data format
4. **Dashboard not loading**: Verify HTML generation

### Debug Commands
\\\powershell
# Test compliance validation
pwsh -File scripts/validate-ecrr-compliance.ps1 -Verbose

# Test trends monitoring
pwsh -File scripts/monitor-ecrr-compliance-trends.ps1 -GenerateReport

# Test dashboard generation
pwsh -File scripts/generate-compliance-dashboard.ps1
\\\
