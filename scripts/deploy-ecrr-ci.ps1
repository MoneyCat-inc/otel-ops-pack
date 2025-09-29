# ECRR CI/CD Deployment Script
# This script deploys the GitHub Actions workflow for ECRR compliance checking

param(
    [switch]$Deploy = $false,
    [switch]$Test = $false
)

$WorkflowContent = @"
name: ECRR Compliance Check

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'docs/ECRR_REPORTS/**'
      - 'scripts/lint-ecrr-compliance.ps1'
  pull_request:
    branches: [ main, develop ]
    paths:
      - 'docs/ECRR_REPORTS/**'
      - 'scripts/lint-ecrr-compliance.ps1'

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
        
    - name: Upload Compliance Report
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: ecrr-compliance-report
        path: artifacts/ecrr-compliance-report.json
        retention-days: 30
"@

function Deploy-GitHubActionsWorkflow {
    Write-Host "🚀 Deploying ECRR Compliance GitHub Actions Workflow" -ForegroundColor Cyan
    
    # Create .github/workflows directory if it doesn't exist
    $workflowsDir = ".github/workflows"
    if (-not (Test-Path $workflowsDir)) {
        New-Item -ItemType Directory -Path $workflowsDir -Force | Out-Null
        Write-Host "✅ Created .github/workflows directory" -ForegroundColor Green
    }
    
    # Write the workflow file
    $workflowPath = "$workflowsDir/ecrr-compliance.yml"
    $WorkflowContent | Out-File -FilePath $workflowPath -Encoding UTF8
    Write-Host "✅ Deployed workflow to $workflowPath" -ForegroundColor Green
    
    # Verify the deployment
    if (Test-Path $workflowPath) {
        Write-Host "✅ Workflow deployment verified" -ForegroundColor Green
        Write-Host "📋 Workflow will trigger on:" -ForegroundColor Cyan
        Write-Host "   - Push to main/develop branches" -ForegroundColor White
        Write-Host "   - Pull requests to main/develop branches" -ForegroundColor White
        Write-Host "   - Changes to docs/ECRR_REPORTS/** or scripts/lint-ecrr-compliance.ps1" -ForegroundColor White
        return $true
    } else {
        Write-Host "❌ Workflow deployment failed" -ForegroundColor Red
        return $false
    }
}

function Test-LintScript {
    Write-Host "🧪 Testing ECRR Compliance Lint Script" -ForegroundColor Cyan
    
    if (-not (Test-Path "scripts/lint-ecrr-compliance.ps1")) {
        Write-Host "❌ Lint script not found at scripts/lint-ecrr-compliance.ps1" -ForegroundColor Red
        return $false
    }
    
    try {
        Write-Host "Running lint script test..." -ForegroundColor White
        $result = pwsh -NoLogo -File scripts/lint-ecrr-compliance.ps1 -Verbose 2>&1
        Write-Host "✅ Lint script executed successfully" -ForegroundColor Green
        Write-Host "📊 Test Results:" -ForegroundColor Cyan
        Write-Host $result -ForegroundColor White
        return $true
    } catch {
        Write-Host "❌ Lint script test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Show-TemplateWorkflow {
    Write-Host "📋 ECRR Template Cloning Workflow" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    
    Write-Host "`n1️⃣ **Copy Template**:" -ForegroundColor Yellow
    Write-Host "   Copy-Item -Path 'docs/ECRR_REPORTS/2025-01-27-rollout-merge-ecrr-final-complete.md' -Destination 'docs/ECRR_REPORTS/your-new-report.md'" -ForegroundColor White
    
    Write-Host "`n2️⃣ **Update Content**:" -ForegroundColor Yellow
    Write-Host "   - Change Date, Actor, Task, Status at the top" -ForegroundColor White
    Write-Host "   - Fill in Examine, Clean, Report, Role sections" -ForegroundColor White
    Write-Host "   - Preserve required patterns:" -ForegroundColor White
    Write-Host "     • Local-First:, Safety:, Idempotence:, Verification:" -ForegroundColor Gray
    Write-Host "     • Screenshots:, Console logs:, Configuration files:, Test outputs:" -ForegroundColor Gray
    
    Write-Host "`n3️⃣ **Validate Compliance**:" -ForegroundColor Yellow
    Write-Host "   pwsh -NoLogo -File scripts/lint-ecrr-compliance.ps1" -ForegroundColor White
    Write-Host "   pwsh -NoLogo -File scripts/validate-ecrr-compliance.ps1" -ForegroundColor White
    
    Write-Host "`n4️⃣ **Check Score**:" -ForegroundColor Yellow
    Write-Host "   Inspect artifacts/ecrr-compliance-report.json" -ForegroundColor White
    Write-Host "   Confirm Score: 12/12 and Issues: []" -ForegroundColor White
    
    Write-Host "`n5️⃣ **Document Completion**:" -ForegroundColor Yellow
    Write-Host "   Add FINISHED entry to TASKS.md" -ForegroundColor White
}

# Main execution
if ($Deploy) {
    $deployed = Deploy-GitHubActionsWorkflow
    if ($deployed) {
        Write-Host "`n🎯 GitHub Actions workflow deployed successfully!" -ForegroundColor Green
        Write-Host "The workflow will now automatically check ECRR compliance on:" -ForegroundColor Cyan
        Write-Host "• Push to main/develop branches" -ForegroundColor White
        Write-Host "• Pull requests to main/develop branches" -ForegroundColor White
        Write-Host "• Changes to ECRR reports or lint script" -ForegroundColor White
    }
}

if ($Test) {
    $tested = Test-LintScript
    if ($tested) {
        Write-Host "`n🎯 Lint script tested successfully!" -ForegroundColor Green
    }
}

if (-not $Deploy -and -not $Test) {
    Show-TemplateWorkflow
    Write-Host "`n💡 Usage:" -ForegroundColor Yellow
    Write-Host "   .\scripts\deploy-ecrr-ci.ps1 -Deploy    # Deploy GitHub Actions workflow" -ForegroundColor White
    Write-Host "   .\scripts\deploy-ecrr-ci.ps1 -Test      # Test lint script functionality" -ForegroundColor White
    Write-Host "   .\scripts\deploy-ecrr-ci.ps1            # Show template workflow" -ForegroundColor White
}
