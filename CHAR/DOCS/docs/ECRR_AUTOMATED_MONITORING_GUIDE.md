# ECRR Automated Monitoring Guide

## Overview

The ECRR Automated Monitoring System provides comprehensive, automated compliance checking for all ECRR reports in the repository. This system ensures that ECRR methodology standards are maintained and prevents regression in compliance quality.

## 🎯 Current Status

- **Compliance Rate**: 100% (151/151 files)
- **Average Score**: 100/100
- **Last Check**: 2025-10-02 00:31:34
- **Threshold**: 95%

## 📊 System Components

### 1. Core Monitoring Script
- **File**: `scripts/ecrr-compliance-monitor.ps1`
- **Purpose**: Comprehensive compliance checking with scoring system
- **Features**:
  - Production marker validation
  - Four-section structure verification
  - ECRR Gate validation
  - Actor declaration checking
  - Detailed scoring (0-100 points)
  - HTML dashboard generation
  - JSON report export

### 2. Scheduled Task Monitoring
- **File**: `scripts/setup-ecrr-scheduled-monitoring.ps1`
- **Purpose**: Automated monitoring every 6 hours
- **Features**:
  - Runs as Windows Scheduled Task
  - System-level execution
  - Automatic report generation
  - Error handling and logging

### 3. CI/CD Integration
- **File**: `scripts/ecrr-ci-integration.ps1`
- **Purpose**: Continuous integration compliance checking
- **Features**:
  - Baseline comparison
  - Regression detection
  - Build failure on non-compliance
  - Artifact generation

### 4. Pre-Commit Hooks
- **File**: `scripts/ecrr-pre-commit-hook.ps1`
- **Purpose**: Prevent non-compliant commits
- **Features**:
  - Git hook integration
  - Real-time validation
  - Commit blocking on failures
  - Detailed error reporting

### 5. Comprehensive Setup
- **File**: `scripts/setup-ecrr-automated-monitoring.ps1`
- **Purpose**: One-command setup of entire monitoring system
- **Features**:
  - Scheduled task creation
  - Git hooks installation
  - CI/CD pipeline generation
  - Complete automation

## 🚀 Quick Start

### Manual Compliance Check
```powershell
# Run compliance check
pwsh -File scripts/ecrr-compliance-monitor.ps1

# Run with verbose output
pwsh -File scripts/ecrr-compliance-monitor.ps1 -Verbose

# Run with custom threshold
pwsh -File scripts/ecrr-compliance-monitor.ps1 -Threshold 98
```

### Setup Automated Monitoring
```powershell
# Setup everything (requires admin privileges)
pwsh -File scripts/setup-ecrr-automated-monitoring.ps1 -All

# Setup specific components
pwsh -File scripts/setup-ecrr-automated-monitoring.ps1 -SetupScheduledTask
pwsh -File scripts/setup-ecrr-automated-monitoring.ps1 -SetupGitHooks
pwsh -File scripts/setup-ecrr-automated-monitoring.ps1 -SetupCI
```

### CI/CD Integration
```powershell
# Run CI compliance check
pwsh -File scripts/ecrr-ci-integration.ps1 -Threshold 95 -FailOnRegression

# Generate baseline
pwsh -File scripts/ecrr-ci-integration.ps1 -BaselineFile "artifacts/baseline.json"
```

## 📈 Compliance Criteria

### Scoring System (100 points total)

1. **Production Marker** (25 points)
   - ✅ **PRODUCTION READY** status declaration
   - Must be in report header section

2. **Four-Section Structure** (25 points)
   - ## 🔍 1. Examine (or equivalent)
   - ## 🧹 2. Clean (or equivalent)
   - ## 📝 3. Report (or equivalent)
   - ## 🎭 4. Role (or equivalent)

3. **ECRR Gate** (25 points)
   - ## ✅ ECRR Gate section
   - Contains Examine/Clean/Report/Role subsections
   - Validates ECRR methodology completion

4. **Actor Declaration** (25 points)
   - **Actor**: [Agent Name] in header
   - Clearly identifies responsible agent
   - Required for accountability

### Compliance Levels

- **100/100**: Perfect compliance
- **90-99/100**: Excellent compliance
- **80-89/100**: Good compliance
- **70-79/100**: Acceptable compliance
- **<70/100**: Non-compliant

## 📊 Reports and Dashboards

### JSON Reports
- **Location**: `artifacts/ecrr-compliance-report-YYYY-MM-DD_HH-mm-ss.json`
- **Content**: Detailed compliance data, scores, issues
- **Use**: CI/CD integration, baseline comparison

### HTML Dashboard
- **Location**: `artifacts/ecrr-compliance-dashboard.html`
- **Content**: Visual compliance dashboard
- **Features**: Metrics, file status, trends

### CI Summary
- **Location**: `artifacts/ecrr-ci-summary.json`
- **Content**: CI/CD integration summary
- **Use**: Build status, regression detection

## 🔧 Troubleshooting

### Common Issues

1. **Low Compliance Rate**
   - Check for missing production markers
   - Verify four-section structure
   - Ensure ECRR Gate is present
   - Confirm actor declarations

2. **Scheduled Task Not Running**
   - Verify administrator privileges
   - Check task scheduler
   - Review task logs

3. **Git Hooks Not Working**
   - Ensure `.git/hooks/pre-commit` exists
   - Check file permissions
   - Verify PowerShell path

4. **CI/CD Integration Failures**
   - Check baseline file exists
   - Verify threshold settings
   - Review regression detection

### Manual Fixes

```powershell
# Fix production markers in batch
pwsh -File scripts/batch-production-marker-fix.ps1

# Check specific file compliance
pwsh -File scripts/ecrr-compliance-monitor.ps1 -Verbose | Select-String "filename"

# Test pre-commit hook
pwsh -File scripts/ecrr-pre-commit-hook.ps1
```

## 📋 Maintenance

### Regular Tasks

1. **Daily**: Check scheduled task execution
2. **Weekly**: Review compliance trends
3. **Monthly**: Update baseline files
4. **Quarterly**: Review and update criteria

### Monitoring Commands

```powershell
# Check scheduled task status
Get-ScheduledTask -TaskName "ECRR Compliance Monitor"

# View latest compliance report
Get-Content artifacts/ecrr-compliance-report-*.json | ConvertFrom-Json

# Check git hook status
Test-Path .git/hooks/pre-commit
```

## 🎯 Best Practices

### For New ECRR Reports

1. **Use Templates**: Start with compliant templates
2. **Pre-Commit Check**: Let git hooks validate before commit
3. **Follow Structure**: Use standard four-section format
4. **Include All Elements**: Production marker, ECRR Gate, Actor

### For Maintainers

1. **Monitor Trends**: Watch for compliance drift
2. **Update Baselines**: Keep CI/CD baselines current
3. **Review Reports**: Check HTML dashboard regularly
4. **Fix Issues**: Address non-compliance promptly

## 📚 Related Documentation

- [ECRR Compliance Agent Prompt](ECRR_COMPLIANCE_AGENT_PROMPT.md)
- [ECRR Compliance Remediation Prompt](ECRR_COMPLIANCE_REMEDIATION_PROMPT.md)
- [ECRR Methodology Guide](ECRR_METHODOLOGY.md)

## 🎉 Success Metrics

- **Target Compliance**: ≥95%
- **Current Compliance**: 100%
- **Files Monitored**: 151
- **Automation Level**: Fully Automated
- **Monitoring Frequency**: Every 6 hours
- **CI/CD Integration**: Complete

---

**Last Updated**: 2025-10-02  
**System Status**: ✅ Fully Operational  
**Compliance Status**: ✅ 100% Compliant
