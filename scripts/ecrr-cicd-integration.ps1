# ECRR CI/CD Integration Script
# Creates GitHub Actions workflow and CI/CD integration files

param(
    [string]$OutputPath = "artifacts/ecrr-cicd-integration-report.json",
    [switch]$DryRun,
    [switch]$Verbose
)

function Create-GitHubWorkflow {
    param([bool]$DryRun)
    
    $workflowContent = @"
name: ECRR Compliance Check

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'docs/ECRR_REPORTS/**'
      - 'docs/ECRR_REPORT_TEMPLATE.md'
      - 'scripts/validate-ecrr-compliance.ps1'
      - '.github/workflows/ecrr-compliance-check.yml'
  pull_request:
    branches: [ main, develop ]
    paths:
      - 'docs/ECRR_REPORTS/**'
      - 'docs/ECRR_REPORT_TEMPLATE.md'
      - 'scripts/validate-ecrr-compliance.ps1'
      - '.github/workflows/ecrr-compliance-check.yml'
  workflow_dispatch:
    inputs:
      report_path:
        description: 'Path to ECRR reports directory'
        required: false
        default: 'docs/ECRR_REPORTS'
        type: string
      fail_on_warnings:
        description: 'Fail on warnings (not just errors)'
        required: false
        default: false
        type: boolean

jobs:
  ecrr-compliance:
    name: ECRR Compliance Validation
    runs-on: windows-latest
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      with:
        fetch-depth: 0
    
    - name: Setup PowerShell
      uses: actions/setup-powershell@v1
      with:
        version: '7.4'
    
    - name: Create artifacts directory
      run: |
        if (!(Test-Path "artifacts")) {
          New-Item -ItemType Directory -Path "artifacts" -Force
        }
    
    - name: Run ECRR Compliance Check
      id: compliance-check
      run: |
        `$reportPath = "`${{ github.event.inputs.report_path || 'docs/ECRR_REPORTS' }}"
        `$failOnWarnings = "`${{ github.event.inputs.fail_on_warnings || 'false' }}"
        
        Write-Host "🔍 Running ECRR Compliance Check..." -ForegroundColor Cyan
        Write-Host "Report Path: `$reportPath" -ForegroundColor Gray
        Write-Host "Fail on Warnings: `$failOnWarnings" -ForegroundColor Gray
        
        # Run compliance validation
        `$exitCode = 0
        try {
          pwsh -File scripts/validate-ecrr-compliance.ps1 -ReportPath `$reportPath -OutputPath "artifacts/ecrr-compliance-ci-report.json"
          
          # Check if compliance report exists
          if (Test-Path "artifacts/ecrr-compliance-ci-report.json") {
            `$complianceReport = Get-Content "artifacts/ecrr-compliance-ci-report.json" | ConvertFrom-Json
            
            # Extract compliance metrics
            `$totalReports = `$complianceReport.Total_Reports
            `$compliantReports = `$complianceReport.Compliant_Reports
            `$nonCompliantReports = `$complianceReport.Non_Compliant_Reports
            `$complianceRate = if (`$totalReports -gt 0) { [math]::Round((`$compliantReports / `$totalReports) * 100, 1) } else { 0 }
            
            # Check for critical issues
            `$criticalIssues = `$complianceReport.Reports | Where-Object { 
              `$_.Compliance.Structure.ECRR_Gate -eq `$false -or 
              `$_.Compliance.Structure.Four_Section_Structure -eq `$false -or
              `$_.Compliance.Content.Actor_Declaration -eq `$false
            }
            
            `$criticalCount = `$criticalIssues.Count
            
            # Set outputs
            Write-Host "Total Reports: `$totalReports" -ForegroundColor White
            Write-Host "Compliant Reports: `$compliantReports" -ForegroundColor Green
            Write-Host "Non-Compliant Reports: `$nonCompliantReports" -ForegroundColor Yellow
            Write-Host "Compliance Rate: `$complianceRate%" -ForegroundColor `$(if (`$complianceRate -ge 90) { "Green" } elseif (`$complianceRate -ge 70) { "Yellow" } else { "Red" })
            Write-Host "Critical Issues: `$criticalCount" -ForegroundColor `$(if (`$criticalCount -eq 0) { "Green" } else { "Red" })
            
            # Set GitHub outputs
            echo "total_reports=`$totalReports" >> `$env:GITHUB_OUTPUT
            echo "compliant_reports=`$compliantReports" >> `$env:GITHUB_OUTPUT
            echo "non_compliant_reports=`$nonCompliantReports" >> `$env:GITHUB_OUTPUT
            echo "compliance_rate=`$complianceRate" >> `$env:GITHUB_OUTPUT
            echo "critical_issues=`$criticalCount" >> `$env:GITHUB_OUTPUT
            
            # Determine if we should fail
            if (`$criticalCount -gt 0) {
              Write-Host "❌ FAILING: `$criticalCount critical compliance issues found" -ForegroundColor Red
              `$exitCode = 1
            } elseif (`$complianceRate -lt 70) {
              Write-Host "❌ FAILING: Compliance rate `$complianceRate% is below 70% threshold" -ForegroundColor Red
              `$exitCode = 1
            } elseif (`$failOnWarnings -eq "true" -and `$nonCompliantReports -gt 0) {
              Write-Host "❌ FAILING: `$nonCompliantReports non-compliant reports found (fail on warnings enabled)" -ForegroundColor Red
              `$exitCode = 1
            } else {
              Write-Host "✅ PASSING: ECRR compliance check passed" -ForegroundColor Green
            }
          } else {
            Write-Host "❌ FAILING: Compliance report not generated" -ForegroundColor Red
            `$exitCode = 1
          }
        } catch {
          Write-Host "❌ FAILING: Compliance check failed with error: `$(`$_.Exception.Message)" -ForegroundColor Red
          `$exitCode = 1
        }
        
        exit `$exitCode
    
    - name: Upload compliance report
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: ecrr-compliance-report
        path: artifacts/ecrr-compliance-ci-report.json
        retention-days: 30
    
    - name: Comment on PR
      if: github.event_name == 'pull_request' && always()
      uses: actions/github-script@v7
      with:
        script: |
          const fs = require('fs');
          const path = require('path');
          
          try {
            // Read compliance report
            const reportPath = 'artifacts/ecrr-compliance-ci-report.json';
            if (fs.existsSync(reportPath)) {
              const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
              
              const totalReports = report.Total_Reports || 0;
              const compliantReports = report.Compliant_Reports || 0;
              const nonCompliantReports = report.Non_Compliant_Reports || 0;
              const complianceRate = totalReports > 0 ? Math.round((compliantReports / totalReports) * 100 * 10) / 10 : 0;
              const criticalIssues = report.Reports ? report.Reports.filter(r => 
                !r.Compliance.Structure.ECRR_Gate || 
                !r.Compliance.Structure.Four_Section_Structure ||
                !r.Compliance.Content.Actor_Declaration
              ).length : 0;
              
              // Determine status
              const status = criticalIssues > 0 ? '❌ FAILED' : 
                           complianceRate < 70 ? '❌ FAILED' : 
                           nonCompliantReports > 0 ? '⚠️ WARNING' : '✅ PASSED';
              
              // Create comment
              const comment = `## ECRR Compliance Check Results
              
              **Status**: `$`{status`}
              
              ### Compliance Metrics
              - **Total Reports**: `$`{totalReports`}
              - **Compliant Reports**: `$`{compliantReports`}
              - **Non-Compliant Reports**: `$`{nonCompliantReports`}
              - **Compliance Rate**: `$`{complianceRate`}%
              - **Critical Issues**: `$`{criticalIssues`}
              
              ### Next Steps
              `$`{criticalIssues > 0 ? 
                '🔧 **Action Required**: Fix critical compliance issues before merging' :
                nonCompliantReports > 0 ? 
                '⚠️ **Recommendation**: Consider fixing non-compliant reports for better quality' :
                '🎉 **All Good**: ECRR compliance check passed successfully!'
              `}
              
              ---
              *Generated by ECRR Compliance Check workflow*`;
              
              // Post comment
              await github.rest.issues.createComment({
                issue_number: context.issue.number,
                owner: context.repo.owner,
                repo: context.repo.repo,
                body: comment
              });
            } else {
              await github.rest.issues.createComment({
                issue_number: context.issue.number,
                owner: context.repo.owner,
                repo: context.repo.repo,
                body: '## ECRR Compliance Check Results\n\n❌ **FAILED**: Compliance report not generated\n\n---\n*Generated by ECRR Compliance Check workflow*'
              });
            }
          } catch (error) {
            console.error('Error creating PR comment:', error);
            await github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## ECRR Compliance Check Results\n\n❌ **ERROR**: Failed to process compliance report\n\nError: `$`{error.message`}\n\n---\n*Generated by ECRR Compliance Check workflow*`
            });
          }
    
    - name: Create compliance summary
      if: always()
      run: |
        `$summary = @"
        # ECRR Compliance Check Summary
        
        **Workflow**: ECRR Compliance Check
        **Trigger**: `${{ github.event_name }}
        **Branch**: `${{ github.ref_name }}
        **Commit**: `${{ github.sha }}
        **Date**: `$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        ## Results
        - **Total Reports**: `${{ steps.compliance-check.outputs.total_reports }}
        - **Compliant Reports**: `${{ steps.compliance-check.outputs.compliant_reports }}
        - **Non-Compliant Reports**: `${{ steps.compliance-check.outputs.non_compliant_reports }}
        - **Compliance Rate**: `${{ steps.compliance-check.outputs.compliance_rate }}%
        - **Critical Issues**: `${{ steps.compliance-check.outputs.critical_issues }}
        
        ## Status
        `${{ steps.compliance-check.outputs.critical_issues > 0 && '❌ FAILED - Critical issues found' || steps.compliance-check.outputs.compliance_rate < 70 && '❌ FAILED - Compliance rate below threshold' || '✅ PASSED - ECRR compliance check successful' }}
        
        ## Artifacts
        - Compliance Report: `artifacts/ecrr-compliance-ci-report.json`
        - Workflow Logs: Available in GitHub Actions
        
        ---
        *Generated by ECRR Compliance Check workflow*
        "@
        
        `$summary | Out-File -FilePath "artifacts/ecrr-compliance-summary.md" -Encoding UTF8
    
    - name: Upload compliance summary
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: ecrr-compliance-summary
        path: artifacts/ecrr-compliance-summary.md
        retention-days: 30
"@
    
    $workflowPath = ".github/workflows/ecrr-compliance-check.yml"
    
    if (-not $DryRun) {
        # Ensure .github/workflows directory exists
        $workflowDir = Split-Path $workflowPath -Parent
        if (!(Test-Path $workflowDir)) {
            New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
        }
        
        # Write workflow file
        $workflowContent | Out-File -FilePath $workflowPath -Encoding UTF8
        Write-Host "✅ Created GitHub workflow: $workflowPath" -ForegroundColor Green
    } else {
        Write-Host "🔍 Would create GitHub workflow: $workflowPath" -ForegroundColor Yellow
    }
    
    return @{
        "File" = $workflowPath
        "Status" = if ($DryRun) { "Would create" } else { "Created" }
        "Action" = if ($DryRun) { "Dry run" } else { "File created" }
    }
}

function Create-CICDConfiguration {
    param([bool]$DryRun)
    
    $configContent = @"
# ECRR CI/CD Configuration
# Configuration for ECRR compliance checking in CI/CD pipelines

## Compliance Thresholds
COMPLIANCE_RATE_THRESHOLD=70
CRITICAL_ISSUES_THRESHOLD=0
WARNING_ISSUES_THRESHOLD=5

## Report Paths
ECRR_REPORTS_PATH=docs/ECRR_REPORTS
ECRR_TEMPLATE_PATH=docs/ECRR_REPORT_TEMPLATE.md
COMPLIANCE_SCRIPT_PATH=scripts/validate-ecrr-compliance.ps1

## Output Paths
COMPLIANCE_REPORT_PATH=artifacts/ecrr-compliance-ci-report.json
COMPLIANCE_SUMMARY_PATH=artifacts/ecrr-compliance-summary.md

## GitHub Actions Configuration
WORKFLOW_FILE=.github/workflows/ecrr-compliance-check.yml
ARTIFACT_RETENTION_DAYS=30

## Compliance Requirements
REQUIRED_ECRR_GATE=true
REQUIRED_4_SECTION_STRUCTURE=true
REQUIRED_ACTOR_DECLARATION=true
REQUIRED_EVIDENCE_ATTACHMENT=true

## Quality Gates
MIN_COMPLIANCE_RATE=70
MAX_CRITICAL_ISSUES=0
MAX_WARNING_ISSUES=5

## Notification Settings
PR_COMMENTS_ENABLED=true
FAIL_ON_WARNINGS=false
VERBOSE_LOGGING=false
"@
    
    $configPath = "config/ecrr-cicd.conf"
    
    if (-not $DryRun) {
        # Ensure config directory exists
        $configDir = Split-Path $configPath -Parent
        if (!(Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        # Write config file
        $configContent | Out-File -FilePath $configPath -Encoding UTF8
        Write-Host "✅ Created CI/CD configuration: $configPath" -ForegroundColor Green
    } else {
        Write-Host "🔍 Would create CI/CD configuration: $configPath" -ForegroundColor Yellow
    }
    
    return @{
        "File" = $configPath
        "Status" = if ($DryRun) { "Would create" } else { "Created" }
        "Action" = if ($DryRun) { "Dry run" } else { "File created" }
    }
}

function Create-CICDDocumentation {
    param([bool]$DryRun)
    
    $docContent = @"
# ECRR CI/CD Integration Guide

## Overview

This guide explains how ECRR (Examine → Clean → Report → Role) compliance checking is integrated into the CI/CD pipeline to ensure all reports meet quality standards.

## CI/CD Integration

### GitHub Actions Workflow

The ECRR compliance check runs automatically on:
- **Push** to `main` or `develop` branches
- **Pull Requests** targeting `main` or `develop` branches
- **Manual trigger** via workflow dispatch

### Workflow Triggers

The workflow triggers when changes are made to:
- `docs/ECRR_REPORTS/**` - ECRR report files
- `docs/ECRR_REPORT_TEMPLATE.md` - ECRR template
- `scripts/validate-ecrr-compliance.ps1` - Compliance validation script
- `.github/workflows/ecrr-compliance-check.yml` - Workflow file itself

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

```yaml
workflow_dispatch:
  inputs:
    report_path: 'docs/ECRR_REPORTS'  # Custom report path
    fail_on_warnings: false           # Fail on warnings
```

#### Local Execution
Run compliance check locally:

```powershell
# Basic compliance check
pwsh -File scripts/validate-ecrr-compliance.ps1

# Custom report path
pwsh -File scripts/validate-ecrr-compliance.ps1 -ReportPath "custom/path"

# Verbose output
pwsh -File scripts/validate-ecrr-compliance.ps1 -Verbose
```

### Artifacts

#### Generated Artifacts
- `ecrr-compliance-report.json` - Detailed compliance report
- `ecrr-compliance-summary.md` - Human-readable summary
- Workflow logs and outputs

#### Artifact Retention
- **Retention Period**: 30 days
- **Storage**: GitHub Actions artifacts
- **Access**: Available in workflow runs

### Configuration

#### Environment Variables
- `COMPLIANCE_RATE_THRESHOLD=70`
- `CRITICAL_ISSUES_THRESHOLD=0`
- `WARNING_ISSUES_THRESHOLD=5`

#### File Paths
- `ECRR_REPORTS_PATH=docs/ECRR_REPORTS`
- `COMPLIANCE_SCRIPT_PATH=scripts/validate-ecrr-compliance.ps1`
- `WORKFLOW_FILE=.github/workflows/ecrr-compliance-check.yml`

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

```powershell
# Test compliance script locally
pwsh -File scripts/validate-ecrr-compliance.ps1 -Verbose

# Check specific report
pwsh -File scripts/validate-ecrr-compliance.ps1 -ReportPath "docs/ECRR_REPORTS/specific-report.md"

# Generate detailed report
pwsh -File scripts/validate-ecrr-compliance.ps1 -OutputPath "debug-compliance-report.json"
```

### Best Practices

#### Report Creation
1. **Use Template**: Always start with `docs/ECRR_REPORT_TEMPLATE.md`
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
- **ECRR Framework**: `docs/ECRR_FRAMEWORK_README.md`
- **Template**: `docs/ECRR_REPORT_TEMPLATE.md`
- **Validation Script**: `scripts/validate-ecrr-compliance.ps1`
- **Configuration**: `config/ecrr-cicd.conf`

#### Contact
- **Issues**: Create GitHub issue for problems
- **Questions**: Use repository discussions
- **Contributions**: Submit pull requests for improvements

---

*Generated by ECRR CI/CD Integration Script*
"@
    
    $docPath = "docs/ECRR_CI_CD_INTEGRATION_GUIDE.md"
    
    if (-not $DryRun) {
        # Ensure docs directory exists
        $docDir = Split-Path $docPath -Parent
        if (!(Test-Path $docDir)) {
            New-Item -ItemType Directory -Path $docDir -Force | Out-Null
        }
        
        # Write documentation
        $docContent | Out-File -FilePath $docPath -Encoding UTF8
        Write-Host "✅ Created CI/CD documentation: $docPath" -ForegroundColor Green
    } else {
        Write-Host "🔍 Would create CI/CD documentation: $docPath" -ForegroundColor Yellow
    }
    
    return @{
        "File" = $docPath
        "Status" = if ($DryRun) { "Would create" } else { "Created" }
        "Action" = if ($DryRun) { "Dry run" } else { "File created" }
    }
}

# Main execution
try {
    Write-Host "🔍 ECRR CI/CD Integration Starting..." -ForegroundColor Cyan
    
    if ($DryRun) {
        Write-Host "🔍 DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
    }
    
    $results = @()
    
    # Create GitHub workflow
    $workflowResult = Create-GitHubWorkflow -DryRun $DryRun
    $results += $workflowResult
    
    # Create CI/CD configuration
    $configResult = Create-CICDConfiguration -DryRun $DryRun
    $results += $configResult
    
    # Create CI/CD documentation
    $docResult = Create-CICDDocumentation -DryRun $DryRun
    $results += $docResult
    
    # Generate report
    $report = @{
        "Generated" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "Mode" = if ($DryRun) { "Dry Run" } else { "Live Integration" }
        "Files_Created" = $results.Count
        "Results" = $results
        "Summary" = @{
            "Created" = ($results | Where-Object { $_.Status -like "*Created*" }).Count
            "Would_Create" = ($results | Where-Object { $_.Status -like "*Would*" }).Count
            "Errors" = ($results | Where-Object { $_.Status -like "*Error*" }).Count
        }
    }
    
    # Ensure output directory exists
    $outputDir = Split-Path $OutputPath -Parent
    if (!(Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    
    # Show summary
    Write-Host "`n📊 ECRR CI/CD Integration Summary" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "Files Created: $($results.Count)" -ForegroundColor White
    Write-Host "Created: $($report.Summary.Created)" -ForegroundColor Green
    Write-Host "Would Create: $($report.Summary.Would_Create)" -ForegroundColor Yellow
    Write-Host "Errors: $($report.Summary.Errors)" -ForegroundColor Red
    
    Write-Host "`n📄 Detailed report saved to: $OutputPath" -ForegroundColor Green
    
    if ($DryRun) {
        Write-Host "`n🔍 This was a dry run. Use without -DryRun to apply changes." -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host "`n✅ ECRR CI/CD Integration completed!" -ForegroundColor Green
        exit 0
    }
    
} catch {
    Write-Error "ECRR CI/CD Integration failed: $($_.Exception.Message)"
    exit 3
}
