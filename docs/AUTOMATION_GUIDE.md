# Automation Guide — Conflict Detection & Resolution

## Overview

This guide covers automated conflict detection and resolution for the OTel observability repository. The automation system helps maintain repository hygiene by detecting and fixing common issues automatically.

## Components

### 1. Automated Conflict Detector (`scripts/automated-conflict-detector.ps1`)

**Purpose**: Scans repository for conflicts and inconsistencies

**Features**:
- Merge marker detection (`<<<<<<<`, `=======`, `>>>>>>>`)
- Incorrect OTLP endpoint detection (`http://localhost:4317` → `localhost:4317`)
- Path style inconsistencies (`C:\` vs `C:/`)
- Duplicate directory detection
- Corrupted file detection
- Safe automatic fixes
- ECRR report generation

**Usage**:
```powershell
# Scan only
pwsh -File scripts/automated-conflict-detector.ps1

# Scan and fix safe issues
pwsh -File scripts/automated-conflict-detector.ps1 -Fix

# Generate ECRR reports
pwsh -File scripts/automated-conflict-detector.ps1 -GenerateECRR

# Full automation
pwsh -File scripts/automated-conflict-detector.ps1 -Fix -GenerateECRR
```

### 2. Automation Setup (`scripts/setup-automation.ps1`)

**Purpose**: Configure automation infrastructure

**Features**:
- Pre-commit hook installation
- CI/CD pipeline configuration
- Windows scheduled task creation

**Usage**:
```powershell
# Install pre-commit hooks
pwsh -File scripts/setup-automation.ps1 -InstallHooks

# Generate CI configuration
pwsh -File scripts/setup-automation.ps1 -SetupCI

# Create scheduled task
pwsh -File scripts/setup-automation.ps1 -ScheduleTask

# Full setup
pwsh -File scripts/setup-automation.ps1 -InstallHooks -SetupCI -ScheduleTask
```

## Automation Levels

### Level 1: Pre-commit Hooks
- **Trigger**: Every git commit
- **Action**: Block commits with conflicts
- **Benefit**: Prevents conflicts from entering repository

### Level 2: CI/CD Pipeline
- **Trigger**: Pull requests, pushes, daily schedule
- **Action**: Scan and report issues
- **Benefit**: Continuous monitoring and reporting

### Level 3: Scheduled Tasks
- **Trigger**: Daily at 2:00 AM
- **Action**: Automatic fixes and ECRR generation
- **Benefit**: Proactive maintenance

## Configuration

### Customizing Detection Rules

Edit `scripts/automated-conflict-detector.ps1`:

```powershell
# Exclude patterns
$ExcludePatterns = "node_modules,*.log,*.tmp,archive,custom-dir"

# Output directory
$OutputDir = "docs/ECRR_REPORTS"

# Enable/disable specific tests
Test-MergeMarkers        # Always enabled
Test-IncorrectEndpoints  # Always enabled
Test-PathInconsistencies # Always enabled
Test-DuplicateDirectories # Always enabled
Test-CorruptedFiles      # Always enabled
```

### Adding New Detection Rules

1. Create new test function:
```powershell
function Test-CustomIssue {
    Write-Host "`nScanning for custom issues..." -ForegroundColor Yellow
    
    # Your detection logic here
    $issues = & rg "your-pattern" --files-with-matches
    
    foreach ($file in $issues) {
        Write-Issue -Type "CustomIssue" -Severity "WARNING" -File $file -Description "Custom issue found"
    }
}
```

2. Add to main execution:
```powershell
Test-CustomIssue
```

3. Add fix logic if applicable:
```powershell
function Invoke-SafeFixes {
    # ... existing code ...
    
    switch ($issue.Type) {
        "CustomIssue" {
            # Your fix logic here
        }
    }
}
```

## Integration Examples

### GitHub Actions
```yaml
name: Conflict Detection
on: [push, pull_request]

jobs:
  conflict-detection:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v4
    - name: Run conflict detection
      run: pwsh -File scripts/automated-conflict-detector.ps1 -GenerateECRR
```

### Azure DevOps
```yaml
trigger:
- main

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  displayName: 'Conflict Detection'
  inputs:
    filePath: 'scripts/automated-conflict-detector.ps1'
    arguments: '-GenerateECRR'
```

### Jenkins
```groovy
pipeline {
    agent any
    stages {
        stage('Conflict Detection') {
            steps {
                powershell 'pwsh -File scripts/automated-conflict-detector.ps1 -GenerateECRR'
            }
        }
    }
}
```

## Monitoring & Alerts

### ECRR Reports
- Generated in `docs/ECRR_REPORTS/`
- Timestamped with date and issue type
- Include examination, cleaning, reporting, and role sections

### CI Artifacts
- ECRR reports uploaded as build artifacts
- Retention: 30 days
- Accessible via CI/CD interface

### Scheduled Task Monitoring
- Check Windows Task Scheduler for `OTel-Conflict-Detector`
- Review task history for execution status
- Monitor PowerShell logs for errors

## Troubleshooting

### Common Issues

**PowerShell Execution Policy**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Missing ripgrep**:
```powershell
# Windows
choco install ripgrep

# Or download from: https://github.com/BurntSushi/ripgrep/releases
```

**Permission Issues**:
- Run PowerShell as Administrator for scheduled tasks
- Ensure git hooks directory is writable
- Check CI/CD service account permissions

### Debug Mode

Add debug output to scripts:
```powershell
$VerbosePreference = "Continue"
$DebugPreference = "Continue"
```

### Logging

Enable detailed logging:
```powershell
Start-Transcript -Path "conflict-detection.log"
pwsh -File scripts/automated-conflict-detector.ps1 -Fix -GenerateECRR
Stop-Transcript
```

## Best Practices

1. **Start Small**: Begin with pre-commit hooks, then expand
2. **Test Thoroughly**: Validate automation in development environment
3. **Monitor Results**: Review ECRR reports regularly
4. **Iterate**: Refine detection rules based on findings
5. **Document Changes**: Update this guide when adding new features

## Future Enhancements

- [ ] Integration with external conflict resolution tools
- [ ] Machine learning-based conflict prediction
- [ ] Real-time conflict notifications
- [ ] Integration with IDE plugins
- [ ] Advanced path normalization rules
- [ ] Custom conflict resolution strategies

## Support

For issues or questions:
1. Check ECRR reports for recent findings
2. Review PowerShell execution logs
3. Validate configuration parameters
4. Test individual detection functions
5. Create issue with detailed error information
