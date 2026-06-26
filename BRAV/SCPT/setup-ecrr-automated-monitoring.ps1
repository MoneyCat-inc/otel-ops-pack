# ECRR Automated Monitoring Setup
param(
    [switch]$SetupScheduledTask = $false,
    [switch]$SetupGitHooks = $false,
    [switch]$SetupCI = $false,
    [switch]$All = $false,
    [switch]$Force = $false
)

Write-Host "🔧 ECRR Automated Monitoring Setup" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Determine what to setup
if ($All) {
    $SetupScheduledTask = $true
    $SetupGitHooks = $true
    $SetupCI = $true
}

if (-not ($SetupScheduledTask -or $SetupGitHooks -or $SetupCI)) {
    Write-Host "❌ No setup options selected. Use -All or specify individual options:" -ForegroundColor Red
    Write-Host "   -SetupScheduledTask : Set up scheduled monitoring task" -ForegroundColor Gray
    Write-Host "   -SetupGitHooks      : Set up git pre-commit hooks" -ForegroundColor Gray
    Write-Host "   -SetupCI            : Set up CI/CD integration files" -ForegroundColor Gray
    Write-Host "   -All                : Set up everything" -ForegroundColor Gray
    exit 1
}

$workingDir = (Get-Location).Path
Write-Host "📁 Working Directory: $workingDir" -ForegroundColor Gray
Write-Host ""

# 1. Setup Scheduled Task
if ($SetupScheduledTask) {
    Write-Host "🕐 Setting up Scheduled Task..." -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    
    $scheduledTaskScript = Join-Path $workingDir "scripts/setup-ecrr-scheduled-monitoring.ps1"
    
    if (-not (Test-Path $scheduledTaskScript)) {
        Write-Host "❌ Scheduled task setup script not found: $scheduledTaskScript" -ForegroundColor Red
    } else {
        try {
            & pwsh -File $scheduledTaskScript -Force:$Force
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Scheduled task setup completed!" -ForegroundColor Green
            } else {
                Write-Host "❌ Scheduled task setup failed!" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Error setting up scheduled task: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# 2. Setup Git Hooks
if ($SetupGitHooks) {
    Write-Host "🪝 Setting up Git Hooks..." -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    
    $gitHooksDir = Join-Path $workingDir ".git/hooks"
    $preCommitHook = Join-Path $gitHooksDir "pre-commit"
    $hookScript = Join-Path $workingDir "scripts/ecrr-pre-commit-hook.ps1"
    
    if (-not (Test-Path $gitHooksDir)) {
        Write-Host "❌ Git hooks directory not found. Make sure you're in a git repository." -ForegroundColor Red
    } elseif (-not (Test-Path $hookScript)) {
        Write-Host "❌ Pre-commit hook script not found: $hookScript" -ForegroundColor Red
    } else {
        # Create the pre-commit hook
        $hookContent = @"
#!/bin/sh
# ECRR Pre-Commit Hook
# This hook checks ECRR compliance for new report files

# Run the PowerShell pre-commit hook
pwsh -File "$hookScript" "`$@"

# Exit with the same code as the PowerShell script
exit `$?
"@
        
        if (Test-Path $preCommitHook) {
            if ($Force) {
                Write-Host "🗑️  Replacing existing pre-commit hook" -ForegroundColor Yellow
                Remove-Item $preCommitHook -Force
            } else {
                Write-Host "⚠️  Pre-commit hook already exists. Use -Force to replace it." -ForegroundColor Yellow
                continue
            }
        }
        
        try {
            Set-Content -Path $preCommitHook -Value $hookContent -Encoding UTF8
            Write-Host "✅ Pre-commit hook created: $preCommitHook" -ForegroundColor Green
            
            # Make it executable (on Unix-like systems)
            if ($IsLinux -or $IsMacOS) {
                chmod +x $preCommitHook
                Write-Host "✅ Pre-commit hook made executable" -ForegroundColor Green
            }
        } catch {
            Write-Host "❌ Error creating pre-commit hook: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# 3. Setup CI/CD Integration
if ($SetupCI) {
    Write-Host "🚀 Setting up CI/CD Integration..." -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Cyan
    
    # Create GitHub Actions workflow
    $githubWorkflowsDir = Join-Path $workingDir ".github/workflows"
    $workflowFile = Join-Path $githubWorkflowsDir "ecrr-compliance.yml"
    
    if (-not (Test-Path $githubWorkflowsDir)) {
        Write-Host "📁 Creating .github/workflows directory" -ForegroundColor Yellow
        New-Item -Path $githubWorkflowsDir -ItemType Directory -Force | Out-Null
    }
    
    $workflowContent = @"
name: ECRR Compliance Check

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'CHAR/ECRR/ECRR_REPORTS/**/*.md'
  pull_request:
    branches: [ main, develop ]
    paths:
      - 'CHAR/ECRR/ECRR_REPORTS/**/*.md'
  schedule:
    # Run daily at 2 AM UTC
    - cron: '0 2 * * *'

jobs:
  ecrr-compliance:
    runs-on: windows-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Set up PowerShell
      uses: actions/setup-powershell@v1
      
    - name: Run ECRR Compliance Check
      run: |
        pwsh -File scripts/ecrr-ci-integration.ps1 -Threshold 95 -FailOnRegression
        
    - name: Upload Compliance Report
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: ecrr-compliance-report
        path: artifacts/ecrr-compliance-report-*.json
        
    - name: Upload HTML Dashboard
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: ecrr-compliance-dashboard
        path: artifacts/ecrr-compliance-dashboard.html
"@
    
    if (Test-Path $workflowFile) {
        if ($Force) {
            Write-Host "🗑️  Replacing existing GitHub Actions workflow" -ForegroundColor Yellow
            Remove-Item $workflowFile -Force
        } else {
            Write-Host "⚠️  GitHub Actions workflow already exists. Use -Force to replace it." -ForegroundColor Yellow
        }
    }
    
    if (-not (Test-Path $workflowFile) -or $Force) {
        try {
            Set-Content -Path $workflowFile -Value $workflowContent -Encoding UTF8
            Write-Host "✅ GitHub Actions workflow created: $workflowFile" -ForegroundColor Green
        } catch {
            Write-Host "❌ Error creating GitHub Actions workflow: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Create Azure DevOps pipeline
    $azurePipelineFile = Join-Path $workingDir "azure-pipelines-ecrr.yml"
    
    $azurePipelineContent = @"
# ECRR Compliance Pipeline
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - CHAR/ECRR/ECRR_REPORTS/**/*.md

schedules:
- cron: "0 2 * * *"
  displayName: Daily ECRR Compliance Check
  branches:
    include:
      - main

pool:
  vmImage: 'windows-latest'

stages:
- stage: ECRRCompliance
  displayName: 'ECRR Compliance Check'
  jobs:
  - job: ComplianceCheck
    displayName: 'Run Compliance Check'
    steps:
    - checkout: self
    
    - task: PowerShell@2
      displayName: 'Run ECRR Compliance Check'
      inputs:
        filePath: 'scripts/ecrr-ci-integration.ps1'
        arguments: '-Threshold 95 -FailOnRegression'
        
    - task: PublishBuildArtifacts@1
      displayName: 'Publish Compliance Report'
      condition: always()
      inputs:
        pathToPublish: 'artifacts'
        artifactName: 'ecrr-compliance-report'
"@
    
    if (Test-Path $azurePipelineFile) {
        if ($Force) {
            Write-Host "🗑️  Replacing existing Azure DevOps pipeline" -ForegroundColor Yellow
            Remove-Item $azurePipelineFile -Force
        } else {
            Write-Host "⚠️  Azure DevOps pipeline already exists. Use -Force to replace it." -ForegroundColor Yellow
        }
    }
    
    if (-not (Test-Path $azurePipelineFile) -or $Force) {
        try {
            Set-Content -Path $azurePipelineFile -Value $azurePipelineContent -Encoding UTF8
            Write-Host "✅ Azure DevOps pipeline created: $azurePipelineFile" -ForegroundColor Green
        } catch {
            Write-Host "❌ Error creating Azure DevOps pipeline: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
}

# 4. Test the setup
Write-Host "🧪 Testing ECRR Compliance Monitor..." -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

$monitorScript = Join-Path $workingDir "scripts/ecrr-compliance-monitor.ps1"

if (Test-Path $monitorScript) {
    try {
        & pwsh -File $monitorScript -Verbose:$false
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ ECRR Compliance Monitor test passed!" -ForegroundColor Green
        } else {
            Write-Host "❌ ECRR Compliance Monitor test failed!" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Error testing ECRR Compliance Monitor: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ ECRR Compliance Monitor script not found: $monitorScript" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 Setup Summary:" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan

if ($SetupScheduledTask) {
    Write-Host "✅ Scheduled Task: ECRR Compliance Monitor (every 6 hours)" -ForegroundColor Green
}
if ($SetupGitHooks) {
    Write-Host "✅ Git Hooks: Pre-commit validation for ECRR files" -ForegroundColor Green
}
if ($SetupCI) {
    Write-Host "✅ CI/CD: GitHub Actions and Azure DevOps pipelines" -ForegroundColor Green
}

Write-Host ""
Write-Host "📊 Available Commands:" -ForegroundColor Cyan
Write-Host "  Manual Check: pwsh -File scripts/ecrr-compliance-monitor.ps1" -ForegroundColor Gray
Write-Host "  CI Integration: pwsh -File scripts/ecrr-ci-integration.ps1" -ForegroundColor Gray
Write-Host "  Pre-commit Test: pwsh -File scripts/ecrr-pre-commit-hook.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "📁 Output Files:" -ForegroundColor Cyan
Write-Host "  JSON Report: artifacts/ecrr-compliance-report-*.json" -ForegroundColor Gray
Write-Host "  HTML Dashboard: artifacts/ecrr-compliance-dashboard.html" -ForegroundColor Gray
Write-Host "  CI Summary: artifacts/ecrr-ci-summary.json" -ForegroundColor Gray

Write-Host ""
Write-Host "🎉 ECRR Automated Monitoring Setup Complete!" -ForegroundColor Green
Write-Host "🚀 Your repository now has automated ECRR compliance monitoring!" -ForegroundColor Green

