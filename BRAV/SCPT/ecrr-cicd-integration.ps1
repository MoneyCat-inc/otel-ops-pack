# ECRR CI/CD Integration Script
# Integrates ECRR compliance checking into CI/CD pipelines

param(
    [string]$ComplianceThreshold = "95",
    [switch]$GenerateWorkflow,
    [switch]$Test
)

# Configuration
$Config = @{
    ComplianceThreshold = $ComplianceThreshold
    MonitorScript = "scripts/continuous-ecrr-compliance-monitor.ps1"
    SetupScript = "scripts/setup-ecrr-compliance-tracking.ps1"
    ArtifactsPath = "artifacts"
}

function Write-ECRRLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Generate-GitHubWorkflow {
    Write-ECRRLog "Generating GitHub Actions workflow..." "INFO"
    
    $workflowContent = @"
name: ECRR Compliance Check

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'docs/ECRR_REPORTS/**'
  pull_request:
    branches: [ main, develop ]
    paths:
      - 'docs/ECRR_REPORTS/**'
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:
    inputs:
      compliance_threshold:
        description: 'Compliance threshold (default: 95)'
        required: false
        default: '95'
        type: string

env:
  COMPLIANCE_THRESHOLD: `${{ github.event.inputs.compliance_threshold || '$($Config.ComplianceThreshold)' }}

jobs:
  ecrr-compliance-check:
    name: ECRR Compliance Check
    runs-on: windows-latest
    
    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4
    
    - name: Setup PowerShell
      uses: actions/setup-powershell@v1
    
    - name: Create Artifacts Directory
      run: |
        if (-not (Test-Path "$($Config.ArtifactsPath)")) {
          New-Item -ItemType Directory -Path "$($Config.ArtifactsPath)" -Force
        }
    
    - name: Run ECRR Compliance Analysis
      id: compliance-check
      run: |
        Write-Host "🔍 Running ECRR Compliance Analysis..." -ForegroundColor Cyan
        `$complianceRate = pwsh -File "$($Config.MonitorScript)" -Verbose -GenerateReport
        if (`$LASTEXITCODE -eq 0) {
          Write-Host "✅ Compliance analysis completed successfully" -ForegroundColor Green
          echo "compliance-rate=`$complianceRate" >> `$env:GITHUB_OUTPUT
          echo "compliance-success=true" >> `$env:GITHUB_OUTPUT
        } else {
          Write-Host "❌ Compliance analysis failed" -ForegroundColor Red
          echo "compliance-rate=0" >> `$env:GITHUB_OUTPUT
          echo "compliance-success=false" >> `$env:GITHUB_OUTPUT
        }
    
    - name: Check Compliance Threshold
      id: threshold-check
      run: |
        `$complianceRate = `${{ steps.compliance-check.outputs.compliance-rate }}
        `$threshold = `${{ env.COMPLIANCE_THRESHOLD }}
        if ([int]`$complianceRate -ge [int]`$threshold) {
          Write-Host "✅ Compliance threshold met" -ForegroundColor Green
          echo "threshold-met=true" >> `$env:GITHUB_OUTPUT
        } else {
          Write-Host "❌ Compliance threshold not met" -ForegroundColor Red
          echo "threshold-met=false" >> `$env:GITHUB_OUTPUT
        }
    
    - name: Fail on Compliance Threshold
      if: steps.threshold-check.outputs.threshold-met == 'false'
      run: |
        Write-Host "❌ ECRR compliance threshold not met" -ForegroundColor Red
        exit 1
    
    - name: Success Message
      if: steps.threshold-check.outputs.threshold-met == 'true'
      run: |
        Write-Host "✅ ECRR compliance check passed!" -ForegroundColor Green
"@
    
    $workflowFile = ".github/workflows/ecrr-compliance-check.yml"
    if (-not (Test-Path ".github/workflows")) {
        New-Item -ItemType Directory -Path ".github/workflows" -Force | Out-Null
    }
    
    $workflowContent | Out-File -FilePath $workflowFile -Encoding UTF8
    Write-ECRRLog "GitHub Actions workflow generated: $workflowFile" "SUCCESS"
    return $workflowFile
}

function Test-CICDIntegration {
    Write-ECRRLog "Testing CI/CD integration..." "INFO"
    
    if (-not (Test-Path $Config.MonitorScript)) {
        Write-ECRRLog "Monitor script not found: $($Config.MonitorScript)" "ERROR"
        return $false
    }
    
    try {
        Write-ECRRLog "Testing compliance monitor script..." "INFO"
        $complianceRate = & $Config.MonitorScript -Verbose
        if ($LASTEXITCODE -eq 0) {
            Write-ECRRLog "Monitor script test successful. Compliance rate: $complianceRate%" "SUCCESS"
            return $true
        } else {
            Write-ECRRLog "Monitor script test failed" "ERROR"
            return $false
        }
    } catch {
        Write-ECRRLog "Monitor script test error: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
try {
    if ($GenerateWorkflow) {
        $workflowFile = Generate-GitHubWorkflow
        Write-ECRRLog "GitHub Actions workflow generated: $workflowFile" "SUCCESS"
    }
    
    if ($Test) {
        $success = Test-CICDIntegration
        if ($success) {
            Write-ECRRLog "CI/CD integration test passed" "SUCCESS"
        } else {
            Write-ECRRLog "CI/CD integration test failed" "ERROR"
            exit 1
        }
    }
    
    if (-not $GenerateWorkflow -and -not $Test) {
        Write-Host "ECRR CI/CD Integration" -ForegroundColor Cyan
        Write-Host "Usage: $($MyInvocation.MyCommand.Name) [-GenerateWorkflow] [-Test]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Options:" -ForegroundColor Cyan
        Write-Host "  -GenerateWorkflow    Generate GitHub Actions workflow" -ForegroundColor White
        Write-Host "  -Test                Test CI/CD integration components" -ForegroundColor White
    }
    
} catch {
    Write-ECRRLog "CI/CD integration failed: $($_.Exception.Message)" "ERROR"
    exit 1
}