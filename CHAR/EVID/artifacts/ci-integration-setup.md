# ECRR CI Integration Setup Instructions

## Overview
This document provides instructions for integrating ECRR compliance checking into your CI/CD pipeline.

## Prerequisites
- PowerShell 7.4 or later
- ECRR compliance scripts in scripts/ directory
- Artifacts directory for reports

## Integration Options

### 1. GitHub Actions
Copy the workflow from $OutputDir/github-actions-workflow.yml to .github/workflows/ecrr-compliance.yml

### 2. Azure DevOps
Copy the pipeline from $OutputDir/azure-devops-pipeline.yml to your Azure DevOps project

### 3. Jenkins
Copy the pipeline from $OutputDir/jenkins-pipeline.yml to your Jenkins job configuration

### 4. Local CI Script
Use scripts/ci-ecrr-compliance.ps1 directly in your build scripts:

`powershell
# Run compliance check and fail on threshold violations
pwsh -File scripts/ci-ecrr-compliance.ps1 -FailOnThreshold

# Check exit code
if ( -ne 0) {
    Write-Error "ECRR compliance check failed"
    exit 1
}
`

## Thresholds
- **Four-section Structure**: Minimum 95% (configurable via -MinFourSectionPct)
- **ECRR Gates**: Minimum 90% (configurable via -MinGatePct)

## Artifacts Generated
- rtifacts/ecrr-ci-validation.json - Machine-readable compliance metrics
- rtifacts/ecrr-ci-report.md - Human-readable compliance report

## Monitoring
- Set up alerts for compliance drops below thresholds
- Review compliance trends using scripts/visualize-ecrr-trends.ps1
- Schedule regular compliance monitoring (daily recommended)

## Troubleshooting
- Ensure PowerShell 7.4+ is available in CI environment
- Check that ECRR reports exist in CHAR/ECRR/ECRR_REPORTS/
- Verify artifacts directory is writable

