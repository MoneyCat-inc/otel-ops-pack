#Requires -Version 7.0

<#
.SYNOPSIS
    Setup automation for conflict detection and resolution

.DESCRIPTION
    Configures pre-commit hooks, CI integration, and scheduled tasks for
    automated conflict detection and resolution.

.NOTES
    For long-running operations, this script uses the shared spinner toolkit:
    . (Join-Path $PSScriptRoot 'spinner-toolkit.ps1')
    Use Show-Spinner, Wait-WithSpinner, or Show-ProgressBar for consistent UX.

.PARAMETER InstallHooks
    Install pre-commit hooks for conflict detection

.PARAMETER SetupCI
    Generate CI configuration for automated scanning

.PARAMETER ScheduleTask
    Create Windows scheduled task for daily cleanup

.PARAMETER TaskName
    Name for the scheduled task (default: OTel-Conflict-Detector)
#>

param(
    [switch]$InstallHooks,
    [switch]$SetupCI,
    [switch]$ScheduleTask,
    [string]$TaskName = "OTel-Conflict-Detector"
)

$ErrorActionPreference = "Stop"

# Import shared spinner toolkit for consistent progress indicators
. (Join-Path $PSScriptRoot 'spinner-toolkit.ps1')

function Install-PreCommitHooks {
    Write-Host "Installing pre-commit hooks..." -ForegroundColor Yellow
    
    $hookDir = ".git/hooks"
    if (-not (Test-Path $hookDir)) {
        Write-Host "❌ Not in a git repository" -ForegroundColor Red
        return
    }
    
    $preCommitHook = @"
#!/bin/sh
# Pre-commit hook for conflict detection

echo "Running conflict detection..."

# Run conflict detector
pwsh -File scripts/automated-conflict-detector.ps1

if [ `$? -ne 0 ]; then
    echo "❌ Conflicts detected - commit blocked"
    exit 1
fi

echo "✅ No conflicts detected"
exit 0
"@

    Set-Content -Path "$hookDir/pre-commit" -Value $preCommitHook
    Write-Host "✓ Pre-commit hook installed" -ForegroundColor Green
}

function New-CIConfiguration {
    Write-Host "Generating CI configuration..." -ForegroundColor Yellow
    
    $ciConfig = @"
name: Conflict Detection

on:
  pull_request:
    branches: [ main, develop ]
  push:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM

jobs:
  conflict-detection:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup PowerShell
      uses: actions/setup-powershell@v1
      with:
        version: '7.4'
    
    - name: Install ripgrep
      run: |
        choco install ripgrep -y
    
    - name: Run conflict detection
      run: |
        pwsh -File scripts/automated-conflict-detector.ps1 -GenerateECRR
    
    - name: Upload ECRR reports
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: ecrr-reports
        path: docs/ECRR_REPORTS/
        retention-days: 30
    
    - name: Comment on PR
      uses: actions/github-script@v7
      if: github.event_name == 'pull_request'
      with:
        script: |
          const fs = require('fs');
          const path = require('path');
          
          const reportsDir = 'docs/ECRR_REPORTS';
          if (fs.existsSync(reportsDir)) {
            const reports = fs.readdirSync(reportsDir)
              .filter(f => f.endsWith('-ecrr.md'))
              .slice(-5); // Last 5 reports
            
            if (reports.length > 0) {
              const comment = `## 🔍 Conflict Detection Results
              
              Recent ECRR reports:
              ${reports.map(r => `- [${r}](${reportsDir}/${r})`).join('\n')}
              
              View all reports in the [ECRR_REPORTS](${reportsDir}) directory.`;
              
              github.rest.issues.createComment({
                issue_number: context.issue.number,
                owner: context.repo.owner,
                repo: context.repo.repo,
                body: comment
              });
            }
          }
"@

    Set-Content -Path ".github/workflows/conflict-detection.yml" -Value $ciConfig
    Write-Host "✓ CI configuration created: .github/workflows/conflict-detection.yml" -ForegroundColor Green
}

function New-ScheduledTask {
    Write-Host "Creating scheduled task..." -ForegroundColor Yellow
    
    $taskAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$(Get-Location)\scripts\automated-conflict-detector.ps1`" -Fix -GenerateECRR"
    $taskTrigger = New-ScheduledTaskTrigger -Daily -At "02:00"
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    try {
        Register-ScheduledTask -TaskName $TaskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Description "Daily conflict detection and resolution for OTel repository" -Force
        Write-Host "✓ Scheduled task created: $TaskName" -ForegroundColor Green
        Write-Host "  Runs daily at 2:00 AM" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Run as Administrator to create scheduled tasks" -ForegroundColor Yellow
    }
}

function Show-UsageInstructions {
    Write-Host "`n=== Usage Instructions ===" -ForegroundColor Green
    
    Write-Host "`nManual execution:" -ForegroundColor Cyan
    Write-Host "  pwsh -File scripts/automated-conflict-detector.ps1" -ForegroundColor White
    Write-Host "  pwsh -File scripts/automated-conflict-detector.ps1 -Fix -GenerateECRR" -ForegroundColor White
    
    Write-Host "`nPre-commit hooks:" -ForegroundColor Cyan
    Write-Host "  Automatically runs on git commit" -ForegroundColor White
    
    Write-Host "`nCI Integration:" -ForegroundColor Cyan
    Write-Host "  Runs on PRs and daily schedule" -ForegroundColor White
    Write-Host "  Uploads ECRR reports as artifacts" -ForegroundColor White
    
    Write-Host "`nScheduled Task:" -ForegroundColor Cyan
    Write-Host "  Runs daily at 2:00 AM" -ForegroundColor White
    Write-Host "  Check Task Scheduler for '$TaskName'" -ForegroundColor White
    
    Write-Host "`nConfiguration:" -ForegroundColor Cyan
    Write-Host "  Edit scripts/automated-conflict-detector.ps1 to customize:" -ForegroundColor White
    Write-Host "    - Exclude patterns" -ForegroundColor White
    Write-Host "    - Output directory" -ForegroundColor White
    Write-Host "    - Fix behavior" -ForegroundColor White
}

# Main execution
Write-Host "=== Automation Setup ===" -ForegroundColor Green

if ($InstallHooks) {
    Install-PreCommitHooks
}

if ($SetupCI) {
    New-CIConfiguration
}

if ($ScheduleTask) {
    New-ScheduledTask
}

if (-not ($InstallHooks -or $SetupCI -or $ScheduleTask)) {
    Write-Host "No options specified. Available options:" -ForegroundColor Yellow
    Write-Host "  -InstallHooks    Install pre-commit hooks" -ForegroundColor White
    Write-Host "  -SetupCI         Generate CI configuration" -ForegroundColor White
    Write-Host "  -ScheduleTask    Create scheduled task" -ForegroundColor White
    Write-Host "`nExample: pwsh -File scripts/setup-automation.ps1 -InstallHooks -SetupCI" -ForegroundColor Cyan
}

Show-UsageInstructions
