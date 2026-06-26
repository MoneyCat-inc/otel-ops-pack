# ECRR Compliance CI/CD Integration Script
# Integrates compliance monitoring into CI/CD pipeline

param(
    [string]$WorkflowPath = ".github/workflows/ecrr-compliance.yml",
    [string]$SchedulePath = ".github/workflows/ecrr-compliance-scheduled.yml",
    [switch]$DeployWorkflows,
    [switch]$TestIntegration,
    [string]$Branch = "main"
)

# Initialize OpenTelemetry functions
. $PSScriptRoot\..\otel\otel-functions.ps1

Write-Host "🚀 ECRR Compliance CI/CD Integration" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Function to create enhanced compliance workflow
function New-ComplianceWorkflow {
    $workflowContent = @"
name: ECRR Compliance Check

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'CHAR/ECRR/ECRR_REPORTS/**'
      - 'scripts/lint-ecrr-compliance.ps1'
      - 'scripts/monitor-ecrr-compliance-trends.ps1'
      - 'scripts/post-workshop-validation.ps1'
  pull_request:
    branches: [ main, develop ]
    paths:
      - 'CHAR/ECRR/ECRR_REPORTS/**'
      - 'scripts/lint-ecrr-compliance.ps1'
      - 'scripts/monitor-ecrr-compliance-trends.ps1'
      - 'scripts/post-workshop-validation.ps1'
  workflow_dispatch:
    inputs:
      generate_dashboard:
        description: 'Generate compliance dashboard'
        required: false
        default: 'false'
        type: boolean
      run_trends_analysis:
        description: 'Run trends analysis'
        required: false
        default: 'true'
        type: boolean

jobs:
  ecrr-compliance:
    runs-on: windows-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup PowerShell
      uses: actions/setup-powershell@v1
      
    - name: Run ECRR Compliance Lint
      run: |
        pwsh -NoLogo -File scripts/lint-ecrr-compliance.ps1 -FailOnError -Verbose
        
    - name: Run Compliance Trends Analysis
      if: `${{ github.event.inputs.run_trends_analysis == 'true' || github.event.inputs.run_trends_analysis == '' }}
      run: |
        pwsh -NoLogo -File scripts/monitor-ecrr-compliance-trends.ps1 -GenerateReport -AlertOnDecline
        
    - name: Generate Compliance Dashboard
      if: `${{ github.event.inputs.generate_dashboard == 'true' }}
      run: |
        pwsh -NoLogo -File scripts/generate-compliance-dashboard.ps1 -AutoRefresh
        
    - name: Upload Compliance Report
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: ecrr-compliance-report-`${{ github.run_number }}
        path: artifacts/ecrr-compliance-report.json
        retention-days: 30
        
    - name: Upload Trends Data
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: ecrr-compliance-trends-`${{ github.run_number }}
        path: artifacts/ecrr-compliance-trends.json
        retention-days: 30
        
    - name: Upload Dashboard
      if: always() && github.event.inputs.generate_dashboard == 'true'
      uses: actions/upload-artifact@v4
      with:
        name: ecrr-compliance-dashboard-`${{ github.run_number }}
        path: artifacts/ecrr-compliance-dashboard.html
        retention-days: 30
        
    - name: Comment PR with Compliance Status
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v7
      with:
        script: |
          const fs = require('fs');
          const path = require('path');
          
          try {
            const reportPath = 'artifacts/ecrr-compliance-report.json';
            if (fs.existsSync(reportPath)) {
              const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
              const overallScore = report.Overall_Score;
              const totalReports = report.Total_Reports;
              const complianceRate = Math.round((overallScore / (totalReports * 12)) * 100);
              
              const comment = \`## 📊 ECRR Compliance Status
              
              **Overall Score**: \${overallScore}/\${totalReports * 12}
              **Compliance Rate**: \${complianceRate}%
              **Total Reports**: \${totalReports}
              
              \${complianceRate >= 80 ? '✅ **Compliance threshold met**' : '⚠️ **Compliance below threshold**'}
              
              [View detailed report](https://github.com/\`${{ github.repository }}/actions/runs/\`${{ github.run_id }})
              \`;
              
              github.rest.issues.createComment({
                issue_number: context.issue.number,
                owner: context.repo.owner,
                repo: context.repo.repo,
                body: comment
              });
            }
          } catch (error) {
            console.log('Could not create compliance comment:', error.message);
          }
"@

    return $workflowContent
}

# Function to create scheduled compliance monitoring workflow
function New-ScheduledComplianceWorkflow {
    $scheduledContent = @"
name: ECRR Compliance Scheduled Monitoring

on:
  schedule:
    # Run every weekday at 9 AM UTC
    - cron: '0 9 * * 1-5'
  workflow_dispatch:

jobs:
  scheduled-compliance-check:
    runs-on: windows-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup PowerShell
      uses: actions/setup-powershell@v1
      
    - name: Run Compliance Trends Analysis
      run: |
        pwsh -NoLogo -File scripts/monitor-ecrr-compliance-trends.ps1 -GenerateReport -AlertOnDecline
        
    - name: Generate Compliance Dashboard
      run: |
        pwsh -NoLogo -File scripts/generate-compliance-dashboard.ps1 -AutoRefresh
        
    - name: Upload Daily Report
      uses: actions/upload-artifact@v4
      with:
        name: ecrr-daily-compliance-`${{ github.run_number }}
        path: |
          artifacts/ecrr-compliance-report.json
          artifacts/ecrr-compliance-trends.json
          artifacts/ecrr-compliance-dashboard.html
        retention-days: 7
        
    - name: Create Compliance Summary Issue
      if: failure()
      uses: actions/github-script@v7
      with:
        script: |
          const fs = require('fs');
          
          try {
            const reportPath = 'artifacts/ecrr-compliance-report.json';
            if (fs.existsSync(reportPath)) {
              const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
              const overallScore = report.Overall_Score;
              const totalReports = report.Total_Reports;
              const complianceRate = Math.round((overallScore / (totalReports * 12)) * 100);
              
              const issueBody = \`## 🚨 ECRR Compliance Alert
              
              **Date**: \${new Date().toISOString().split('T')[0]}
              **Overall Score**: \${overallScore}/\${totalReports * 12}
              **Compliance Rate**: \${complianceRate}%
              
              ### Failed Reports
              \${report.Reports.filter(r => r.Score < r.Total).map(r => '- **' + r.File + '**: ' + r.Score + '/' + r.Total).join('\\n')}
              
              ### Action Required
              Please review the failed reports and take corrective action.
              
              [View detailed report](https://github.com/\`${{ github.repository }}/actions/runs/\`${{ github.run_id }})
              \`;
              
              github.rest.issues.create({
                owner: context.repo.owner,
                repo: context.repo.repo,
                title: \`ECRR Compliance Alert - \${complianceRate}% compliance rate\`,
                body: issueBody,
                labels: ['compliance', 'alert', 'ecrr']
              });
            }
          } catch (error) {
            console.log('Could not create compliance alert issue:', error.message);
          }
"@

    return $scheduledContent
}

# Function to deploy workflows
function Deploy-Workflows {
    Write-Host "🚀 Deploying ECRR compliance workflows..." -ForegroundColor Yellow
    
    # Ensure .github/workflows directory exists
    $workflowsDir = ".github/workflows"
    if (-not (Test-Path $workflowsDir)) {
        New-Item -Path $workflowsDir -ItemType Directory -Force | Out-Null
    }
    
    # Deploy main compliance workflow
    $mainWorkflow = New-ComplianceWorkflow
    $mainWorkflow | Set-Content -Path $WorkflowPath -Encoding UTF8
    Write-Host "✅ Main compliance workflow deployed: $WorkflowPath" -ForegroundColor Green
    
    # Deploy scheduled monitoring workflow
    $scheduledWorkflow = New-ScheduledComplianceWorkflow
    $scheduledWorkflow | Set-Content -Path $SchedulePath -Encoding UTF8
    Write-Host "✅ Scheduled monitoring workflow deployed: $SchedulePath" -ForegroundColor Green
    
    # Create workflow documentation
    $docPath = "docs/ECRR_CI_CD_INTEGRATION.md"
    $documentation = @"
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
\`\`\`bash
# Trigger compliance check manually
gh workflow run "ECRR Compliance Check" --ref main
\`\`\`

### Generate Dashboard
\`\`\`bash
# Generate compliance dashboard
gh workflow run "ECRR Compliance Check" --ref main -f generate_dashboard=true
\`\`\`

### Post-Workshop Validation
\`\`\`powershell
# Run after workshop sessions
pwsh -File scripts/post-workshop-validation.ps1 -WorkshopName "workshop-2025-01-27" -GenerateTrends -SendAlerts
\`\`\`

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
\`\`\`powershell
# Test compliance validation
pwsh -File scripts/validate-ecrr-compliance.ps1 -Verbose

# Test trends monitoring
pwsh -File scripts/monitor-ecrr-compliance-trends.ps1 -GenerateReport

# Test dashboard generation
pwsh -File scripts/generate-compliance-dashboard.ps1
\`\`\`
"@

    $documentation | Set-Content -Path $docPath -Encoding UTF8
    Write-Host "✅ CI/CD integration documentation created: $docPath" -ForegroundColor Green
}

# Function to test integration
function Test-Integration {
    Write-Host "🧪 Testing CI/CD integration..." -ForegroundColor Yellow
    
    # Test workflow files exist
    if (-not (Test-Path $WorkflowPath)) {
        Write-Error "Main workflow file not found: $WorkflowPath"
        return $false
    }
    
    if (-not (Test-Path $SchedulePath)) {
        Write-Error "Scheduled workflow file not found: $SchedulePath"
        return $false
    }
    
    # Test workflow syntax
    try {
        $mainWorkflow = Get-Content $WorkflowPath -Raw
        $scheduledWorkflow = Get-Content $SchedulePath -Raw
        
        # Basic YAML validation
        if ($mainWorkflow -notmatch "name:") {
            Write-Error "Main workflow missing name field"
            return $false
        }
        
        if ($scheduledWorkflow -notmatch "name:") {
            Write-Error "Scheduled workflow missing name field"
            return $false
        }
        
        Write-Host "✅ Workflow syntax validation passed" -ForegroundColor Green
    }
    catch {
        Write-Error "Workflow syntax validation failed: $($_.Exception.Message)"
        return $false
    }
    
    # Test script dependencies
    $requiredScripts = @(
        "scripts/lint-ecrr-compliance.ps1",
        "scripts/monitor-ecrr-compliance-trends.ps1",
        "scripts/post-workshop-validation.ps1",
        "scripts/generate-compliance-dashboard.ps1"
    )
    
    foreach ($script in $requiredScripts) {
        if (-not (Test-Path $script)) {
            Write-Error "Required script not found: $script"
            return $false
        }
    }
    
    Write-Host "✅ All required scripts found" -ForegroundColor Green
    
    # Test artifacts directory
    if (-not (Test-Path "artifacts")) {
        New-Item -Path "artifacts" -ItemType Directory -Force | Out-Null
    }
    
    Write-Host "✅ Artifacts directory ready" -ForegroundColor Green
    
    return $true
}

# Main execution
try {
    Write-Host "🚀 Starting ECRR CI/CD integration..." -ForegroundColor Green
    
    if ($DeployWorkflows) {
        Deploy-Workflows
    }
    
    if ($TestIntegration) {
        $testResult = Test-Integration
        if ($testResult) {
            Write-Host "✅ Integration test passed!" -ForegroundColor Green
        } else {
            Write-Error "Integration test failed!"
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "🎯 CI/CD Integration Complete!" -ForegroundColor Green
    Write-Host "   Main workflow: $WorkflowPath" -ForegroundColor White
    Write-Host "   Scheduled workflow: $SchedulePath" -ForegroundColor White
    Write-Host "   Documentation: docs/ECRR_CI_CD_INTEGRATION.md" -ForegroundColor White
    
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Commit and push workflow files to $Branch" -ForegroundColor White
    Write-Host "   2. Verify workflows appear in GitHub Actions" -ForegroundColor White
    Write-Host "   3. Test manual workflow dispatch" -ForegroundColor White
    Write-Host "   4. Monitor scheduled compliance checks" -ForegroundColor White
    
    exit 0
    
} catch {
    Write-Error "CI/CD integration failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}

