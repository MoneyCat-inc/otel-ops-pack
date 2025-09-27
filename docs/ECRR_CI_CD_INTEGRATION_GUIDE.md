# ECRR CI/CD Integration Guide

## Overview

This guide explains how ECRR (Examine → Clean → Report → Role) compliance checking is integrated into the CI/CD pipeline to ensure all reports meet quality standards.

## CI/CD Integration

### GitHub Actions Workflow

The ECRR compliance check runs automatically on:
- **Push** to main or develop branches
- **Pull Requests** targeting main or develop branches
- **Manual trigger** via workflow dispatch

### Workflow Triggers

The workflow triggers when changes are made to:
- docs/ECRR_REPORTS/** - ECRR report files
- docs/ECRR_REPORT_TEMPLATE.md - ECRR template
- scripts/validate-ecrr-compliance.ps1 - Compliance validation script
- .github/workflows/ecrr-compliance-check.yml - Workflow file itself

### Compliance Validation

The workflow validates ECRR reports against:

#### Structure Requirements
- ✅ **ECRR Gate**: Mandatory validation section
- ✅ **4-Section Structure**: Examine → Clean → Report → Role
- ✅ **Status Declaration**: Clear success/failure status

#### Content Requirements
- ✅ **Actor Declaration**: Agent name and role clearly stated
- ✅ **Evidence Attachment**: Screenshots, logs, configs included
- ✅ **Guardrail Compliance**: Local-first, safety, idempotence principles
- ✅ **Artifact Documentation**: All files and changes documented

### Quality Gates

#### Compliance Thresholds
- **Minimum Compliance Rate**: 70%
- **Maximum Critical Issues**: 0
- **Maximum Warning Issues**: 5

#### Failure Conditions
- ❌ **Critical Issues**: Missing ECRR Gate, 4-section structure, or actor declaration
- ❌ **Low Compliance**: Compliance rate below 70%
- ❌ **Script Errors**: Compliance validation script fails

### PR Integration

#### Automatic PR Comments
The workflow automatically comments on pull requests with:
- Compliance metrics and status
- Detailed breakdown of report compliance
- Actionable next steps for fixes

#### Comment Examples
- ✅ **PASSED**: All reports compliant
- ⚠️ **WARNING**: Some non-compliant reports (non-blocking)
- ❌ **FAILED**: Critical issues found (blocking)

### Manual Execution

#### Workflow Dispatch
Run the compliance check manually with custom parameters:

`yaml
workflow_dispatch:
  inputs:
    report_path: 'docs/ECRR_REPORTS'  # Custom report path
    fail_on_warnings: false           # Fail on warnings
`

#### Local Execution
Run compliance check locally:

`powershell
# Basic compliance check
pwsh -File scripts/validate-ecrr-compliance.ps1

# Custom report path
pwsh -File scripts/validate-ecrr-compliance.ps1 -ReportPath "custom/path"

# Verbose output
pwsh -File scripts/validate-ecrr-compliance.ps1 -Verbose
`

### Artifacts

#### Generated Artifacts
- crr-compliance-report.json - Detailed compliance report
- crr-compliance-summary.md - Human-readable summary
- Workflow logs and outputs

#### Artifact Retention
- **Retention Period**: 30 days
- **Storage**: GitHub Actions artifacts
- **Access**: Available in workflow runs

### Configuration

#### Environment Variables
- COMPLIANCE_RATE_THRESHOLD=70
- CRITICAL_ISSUES_THRESHOLD=0
- WARNING_ISSUES_THRESHOLD=5

#### File Paths
- ECRR_REPORTS_PATH=docs/ECRR_REPORTS
- COMPLIANCE_SCRIPT_PATH=scripts/validate-ecrr-compliance.ps1
- WORKFLOW_FILE=.github/workflows/ecrr-compliance-check.yml

### Troubleshooting

#### Common Issues

##### Workflow Fails
- **Cause**: Compliance script errors
- **Solution**: Check script syntax and dependencies
- **Debug**: Enable verbose logging

##### False Positives
- **Cause**: Template changes not reflected
- **Solution**: Update compliance validation script
- **Debug**: Review compliance report details

##### PR Comments Missing
- **Cause**: GitHub token permissions
- **Solution**: Check repository permissions
- **Debug**: Review workflow logs

#### Debug Commands

`powershell
# Test compliance script locally
pwsh -File scripts/validate-ecrr-compliance.ps1 -Verbose

# Check specific report
pwsh -File scripts/validate-ecrr-compliance.ps1 -ReportPath "docs/ECRR_REPORTS/specific-report.md"

# Generate detailed report
pwsh -File scripts/validate-ecrr-compliance.ps1 -OutputPath "debug-compliance-report.json"
`

### Best Practices

#### Report Creation
1. **Use Template**: Always start with docs/ECRR_REPORT_TEMPLATE.md
2. **Follow Structure**: Ensure 4-section structure (Examine → Clean → Report → Role)
3. **Include ECRR Gate**: Add mandatory validation section
4. **Declare Actor**: Clearly state agent name and role

#### CI/CD Integration
1. **Test Locally**: Run compliance check before pushing
2. **Review PR Comments**: Address compliance issues promptly
3. **Monitor Thresholds**: Keep compliance rate above 70%
4. **Update Scripts**: Keep validation script current with template changes

#### Maintenance
1. **Regular Updates**: Update compliance script with template changes
2. **Threshold Tuning**: Adjust compliance thresholds as needed
3. **Documentation**: Keep this guide updated with changes
4. **Monitoring**: Monitor workflow success rates and issues

### Support

#### Resources
- **ECRR Framework**: docs/ECRR_FRAMEWORK_README.md
- **Template**: docs/ECRR_REPORT_TEMPLATE.md
- **Validation Script**: scripts/validate-ecrr-compliance.ps1
- **Configuration**: config/ecrr-cicd.conf

#### Contact
- **Issues**: Create GitHub issue for problems
- **Questions**: Use repository discussions
- **Contributions**: Submit pull requests for improvements

---

*Generated by ECRR CI/CD Integration Script*
