#requires -Version 7
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
    Sets up branch protection rules and labels for the repository (admin only).

.DESCRIPTION
    This script configures GitHub branch protection rules and creates standard labels.
    Requires GitHub CLI (gh) to be installed and authenticated with admin permissions.

.PARAMETER Repo
    Repository in format 'owner/repo' (default: 'fubumaki/otel-ops-pack')

.EXAMPLE
    .\scripts\setup-branch-protection.ps1
    .\scripts\setup-branch-protection.ps1 -Repo "myorg/my-repo"
#>

param(
    [string]$Repo = "fubumaki/otel-ops-pack"
)

Write-Host "🔒 Setting up branch protection for $Repo..." -ForegroundColor Cyan

# Verify gh CLI is available and authenticated
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI (gh) is required but not installed. Install from: https://cli.github.com/"
}

# Test authentication
try {
    $null = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub CLI not authenticated. Run 'gh auth login' first."
    }
} catch {
    throw "GitHub CLI authentication failed: $_"
}

Write-Host "✅ GitHub CLI authenticated" -ForegroundColor Green

# Set branch protection rules
Write-Host "Setting up branch protection rules..." -ForegroundColor Yellow

$protectionConfig = @{
    required_pull_request_reviews = @{
        required_approvals = 1
        dismiss_stale_reviews = $true
        require_code_owner_reviews = $false
    }
    required_status_checks = @{
        strict = $true
        contexts = @("Hygiene", "CodeQL", "Gitleaks", "Pester")
    }
    enforce_admins = $true
    restrictions = $null
    required_linear_history = $true
    allow_force_pushes = $false
    allow_deletions = $false
    block_creations = $true
} | ConvertTo-Json -Depth 3

try {
    gh api -X PUT "/repos/$Repo/branches/main/protection" -f input="$protectionConfig"
    Write-Host "✅ Branch protection rules configured" -ForegroundColor Green
} catch {
    Write-Error "Failed to set branch protection: $_"
    exit 1
}

# Create standard labels
Write-Host "Creating repository labels..." -ForegroundColor Yellow

$labels = @(
    @{ name = "hygiene"; color = "0366d6"; description = "Repo hygiene & lint fixes" }
    @{ name = "otel"; color = "0e8a16"; description = "OpenTelemetry configs & pipelines" }
    @{ name = "yaml"; color = "c2e0c6"; description = "YAML schema/format issues" }
    @{ name = "powershell"; color = "d4c5f9"; description = "PowerShell scripts" }
    @{ name = "good first issue"; color = "7057ff"; description = "Low-risk starter task" }
    @{ name = "documentation"; color = "0075ca"; description = "Improvements or additions to documentation" }
    @{ name = "enhancement"; color = "a2eeef"; description = "New feature or request" }
    @{ name = "bug"; color = "d73a4a"; description = "Something isn't working" }
    @{ name = "help wanted"; color = "008672"; description = "Extra attention is needed" }
)

foreach ($label in $labels) {
    try {
        gh label create $label.name --color $label.color --description $label.description --force
        Write-Host "  ✅ Created label: $($label.name)" -ForegroundColor Green
    } catch {
        Write-Warning "  ⚠️  Label '$($label.name)' may already exist or creation failed: $_"
    }
}

Write-Host "🎉 Branch protection and labels setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Install Lefthook locally: lefthook install" -ForegroundColor White
Write-Host "2. Run hygiene check: npm run hygiene" -ForegroundColor White
Write-Host "3. Address any lint debt to make CI green" -ForegroundColor White
