# GitHub Integration for Cursor-Local Conflict Resolution
# Provides GitHub CLI helpers and webhook integration

param(
    [Parameter(Mandatory=$false)]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$PR,
    
    [Parameter(Mandatory=$false)]
    [string]$Repo,
    
    [Parameter(Mandatory=$false)]
    [switch]$Setup
)

# GitHub CLI authentication check
function Test-GitHubAuth {
    try {
        $user = gh api user --jq '.login'
        if ($user) {
            Write-Host "GitHub CLI authenticated as: $user" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "GitHub CLI not authenticated" -ForegroundColor Red
        return $false
    }
}

# Setup GitHub CLI and webhooks
function Install-GitHubIntegration {
    Write-Host "Setting up GitHub integration for conflict resolution..." -ForegroundColor Yellow
    
    # Check if gh CLI is installed
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Host "Installing GitHub CLI..." -ForegroundColor Yellow
        winget install --id GitHub.cli
    }
    
    # Check authentication
    if (-not (Test-GitHubAuth)) {
        Write-Host "Please authenticate with GitHub CLI:" -ForegroundColor Yellow
        gh auth login
    }
    
    # Create webhook configuration
    $webhookConfig = @{
        name = "web"
        config = @{
            url = "http://localhost:8080/webhooks/github"
            content_type = "json"
            secret = "cursor-local-conflict-webhook"
        }
        events = @("pull_request")
        active = $true
    }
    
    $webhookFile = ".agent\webhook-config.json"
    $webhookConfig | ConvertTo-Json -Depth 10 | Set-Content $webhookFile
    
    Write-Host "Webhook configuration saved to: $webhookFile" -ForegroundColor Green
    Write-Host "To enable webhooks, run: gh api repos/$Repo/hooks --input $webhookFile" -ForegroundColor Yellow
}

# Monitor PR for conflict resolution triggers
function Start-PRMonitor {
    param([string]$PR, [string]$Repo)
    
    if (-not $PR -or -not $Repo) {
        Write-Host "Usage: .\github-integration.ps1 -Action monitor -PR <number> -Repo <repo>" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Monitoring PR #$PR for conflict resolution triggers..." -ForegroundColor Green
    
    # Check for triggers
    $triggers = @(
        "needs-conflict-help",
        "@codex please analyze this conflict",
        "/analyze-conflicts"
    )
    
    while ($true) {
        try {
            # Check PR labels
            $labels = gh pr view $PR --json labels --jq '.labels[].name'
            if ($labels -contains "needs-conflict-help") {
                Write-Host "Trigger detected: label 'needs-conflict-help'" -ForegroundColor Yellow
                Start-Process powershell -ArgumentList "-File", ".\.agent\cursor-local-conflict-resolver.ps1", "-PR", $PR, "-Repo", $Repo, "-CreatePatch"
                break
            }
            
            # Check recent comments
            $comments = gh pr view $PR --json comments --jq '.comments[-5:] | .[].body'
            foreach ($comment in $comments) {
                foreach ($trigger in $triggers) {
                    if ($comment -like "*$trigger*") {
                        Write-Host "Trigger detected in comment: $trigger" -ForegroundColor Yellow
                        Start-Process powershell -ArgumentList "-File", ".\.agent\cursor-local-conflict-resolver.ps1", "-PR", $PR, "-Repo", $Repo, "-CreatePatch"
                        break
                    }
                }
            }
            
            Start-Sleep -Seconds 30
            
        } catch {
            Write-Host "Error monitoring PR: $($_.Exception.Message)" -ForegroundColor Red
            Start-Sleep -Seconds 60
        }
    }
}

# Create conflict resolution label
function New-ConflictResolutionLabel {
    param([string]$Repo)
    
    try {
        gh api repos/$Repo/labels --method POST --field name="needs-conflict-help" --field description="PR has merge conflicts that need resolution assistance" --field color="d73a49"
        Write-Host "Created 'needs-conflict-help' label" -ForegroundColor Green
    } catch {
        Write-Host "Label may already exist or failed to create: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Auto-label PRs with conflicts
function Set-ConflictLabels {
    param([string]$Repo)
    
    Write-Host "Checking for PRs with merge conflicts..." -ForegroundColor Yellow
    
    try {
        $prs = gh pr list --repo $Repo --state open --json number,title,mergeable
        $prs | ConvertFrom-Json | ForEach-Object {
            if ($_.mergeable -eq $false) {
                Write-Host "PR #$($_.number): $($_.title) has conflicts" -ForegroundColor Red
                gh pr edit $_.number --add-label "needs-conflict-help"
            }
        }
    } catch {
        Write-Host "Failed to check PR conflicts: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# GitHub Actions workflow for conflict resolution
function New-ConflictResolutionWorkflow {
    $workflow = @"
name: Conflict Resolution Assistant

on:
  pull_request:
    types: [opened, synchronize, labeled]
  repository_dispatch:
    types: [conflict-resolution-requested]

jobs:
  detect-conflicts:
    if: github.event.label.name == 'needs-conflict-help' || contains(github.event.pull_request.body, '@codex please analyze this conflict')
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Setup PowerShell
        uses: actions/setup-powershell@v1
      
      - name: Run conflict resolver
        run: |
          ./.agent/cursor-local-conflict-resolver.ps1 -PR `${{ github.event.pull_request.number }} -Repo `${{ github.repository }} -CreatePatch
        shell: pwsh
      
      - name: Comment on PR
        if: success()
        run: |
          echo "Conflict resolution analysis completed. Check the PR comments for detailed resolution instructions."
        shell: bash
"@

    $workflowDir = ".github\workflows"
    if (-not (Test-Path $workflowDir)) {
        New-Item -ItemType Directory -Path $workflowDir -Force
    }
    
    $workflowFile = "$workflowDir\conflict-resolution.yml"
    $workflow | Set-Content $workflowFile
    
    Write-Host "Created GitHub Actions workflow: $workflowFile" -ForegroundColor Green
}

# Main execution
function Main {
    switch ($Action.ToLower()) {
        "setup" {
            Install-GitHubIntegration
        }
        "monitor" {
            Start-PRMonitor $PR $Repo
        }
        "label" {
            New-ConflictResolutionLabel $Repo
        }
        "check-conflicts" {
            Set-ConflictLabels $Repo
        }
        "workflow" {
            New-ConflictResolutionWorkflow
        }
        default {
            Write-Host "GitHub Integration for Conflict Resolution" -ForegroundColor Green
            Write-Host ""
            Write-Host "Usage:" -ForegroundColor Yellow
            Write-Host "  .\github-integration.ps1 -Action setup                    # Setup GitHub CLI and webhooks"
            Write-Host "  .\github-integration.ps1 -Action monitor -PR 123 -Repo owner/repo  # Monitor PR for triggers"
            Write-Host "  .\github-integration.ps1 -Action label -Repo owner/repo  # Create conflict resolution label"
            Write-Host "  .\github-integration.ps1 -Action check-conflicts -Repo owner/repo  # Auto-label conflicted PRs"
            Write-Host "  .\github-integration.ps1 -Action workflow               # Create GitHub Actions workflow"
            Write-Host ""
            Write-Host "Examples:" -ForegroundColor Cyan
            Write-Host "  .\github-integration.ps1 -Action setup"
            Write-Host "  .\github-integration.ps1 -Action monitor -PR 10 -Repo fubumaki/otel-ops-pack"
            Write-Host "  .\github-integration.ps1 -Action check-conflicts -Repo fubumaki/otel-ops-pack"
        }
    }
}

# Execute main function
Main
