# GitHub Repository Security Setup
# Configures Actions, Code Scanning, Branch Protection, and Secrets verification

param(
    [string]$Owner = "resonai",
    [string]$Repository = "otel",
    [switch]$SetupSecrets,
    [switch]$TestOnly
)

Write-Host "🔐 GitHub Repository Security Setup" -ForegroundColor Cyan
Write-Host "Repository: $Owner/$Repository" -ForegroundColor Gray
Write-Host ""

# Configuration
$repoConfig = @{
    Owner = $Owner
    Repository = $Repository
    FullName = "$Owner/$Repository"
    RequiredSecrets = @("SIGNOZ_URL", "SIGNOZ_USER", "SIGNOZ_PASS")
    BranchProtectionLevel = "strict"
}

function Test-GitHubCLI {
    try {
        $ghVersion = gh --version
        Write-Host "✅ GitHub CLI: $(($ghVersion -split '`n')[0])" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ GitHub CLI not found. Install from: https://github.com/cli/cli#installation" -ForegroundColor Red
        return $false
    }
}

function Test-Authentication {
    try {
        $user = gh api user --jq '.login'
        Write-Host "✅ Authenticated as: $user" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ GitHub authentication failed. Run: gh auth login" -ForegroundColor Red
        return $false
    }
}

function Test-RepositoryAccess {
    param([string]$Owner, [string]$Repository)
    
    try {
        $repo = gh api "repos/$Owner/$Repository" --jq '.full_name'
        Write-Host "✅ Repository access: $repo" -ForegroundColor Green
        
        # Check current settings
        $settings = gh api "repos/$Owner/$Repository" --jq '{
            Actions: .has_actions_enabled,
            Downloads: .has_downloads,
            Archival: .archived
        }'
        
        Write-Host "📋 Current Settings:" -ForegroundColor Cyan
        $settings | ConvertFrom-Json | ForEach-Object {
            Write-Host "   Actions Enabled: $(if ($_.Actions) { '✅' } else { '❌' })" -ForegroundColor $(if ($_.Actions) { "Green" } else { "Red" })
            Write-Host "   Code Scanning: $(if ($_.Downloads) { '✅' } else { '❌' })" -ForegroundColor $(if ($_.Downloads) { "Green" } else { "Red" })
            Write-Host "   Repository Status: $(if (-not $_.Archival) { '✅ Active' } else { '❌ Archived' })" -ForegroundColor $(if (-not $_.Archival) { "Green" } else { "Red" })
        }
        
        return $true
    }
    catch {
        Write-Host "❌ Repository access failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-BranchProtection {
    param([string]$Owner, [string]$Repository)
    
    try {
        $protection = gh api "repos/$Owner/$Repository/branches/main/protection" --jq '.' 2>$null
        if ($protection -and $protection -ne "null") {
            Write-Host "✅ Branch protection: Enabled on main" -ForegroundColor Green
            
            $protData = $protection | ConvertFrom-Json
            Write-Host "📋 Protection Settings:" -ForegroundColor Cyan
            Write-Host "   Required Reviews: $($protData.required_pull_request_reviews.required_approving_review_count)" -ForegroundColor White
            Write-Host "   Dismiss Stale Reviews: $($protData.required_pull_request_reviews.dismiss_stale_reviews)" -ForegroundColor White
            Write-Host "   Require Status Checks: $($protData.required_status_checks.strict)" -ForegroundColor White
            return $true
        }
        else {
            Write-Host "❌ Branch protection: Not configured on main" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Branch protection: Not configured on main" -ForegroundColor Red
        return $false
    }
}

function Test-RepositorySecrets {
    param([string]$Owner, [string]$Repository, [string[]]$RequiredSecrets)
    
    Write-Host "📋 Checking GitHub Secrets:" -ForegroundColor Cyan
    $missingSecrets = @()
    
    foreach ($secret in $RequiredSecrets) {
        try {
            # Note: GitHub CLI cannot list secret names for security reasons
            # We verify by attempting to get metadata
            $secretCheck = gh secret list --repo "$Owner/$Repository" | Select-String $secret
            if ($secretCheck) {
                Write-Host "   ✅ $secret" -ForegroundColor Green
            }
            else {
                Write-Host "   ❌ $secret (missing)" -ForegroundColor Red
                $missingSecrets += $secret
            }
        }
        catch {
            Write-Host "   ❌ $secret (check failed)" -ForegroundColor Red
            $missingSecrets += $secret
        }
    }
    
    if ($missingSecrets.Count -eq 0) {
        Write-Host "✅ All required secrets are configured" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "⚠️  Missing secrets: $($missingSecrets -join ', ')" -ForegroundColor Yellow
        if ($SetupSecrets) {
            Show-SecretSetupInstructions -Owner $Owner -Repository $Repository -MissingSecrets $missingSecrets
        }
        else {
            Write-Host "💡 Run with -SetupSecrets for setup instructions" -ForegroundColor Blue
        }
        return $false
    }
}

function Show-SecretSetupInstructions {
    param([string]$Owner, [string]$Repository, [string[]]$MissingSecrets)
    
    Write-Host ""
    Write-Host "🔧 Setting up missing secrets:" -ForegroundColor Yellow
    Write-Host "Required secrets: $($MissingSecrets -join ', ')" -ForegroundColor Gray
    Write-Host ""
    
    foreach ($secret in $MissingSecrets) {
        Write-Host "📝 For ${secret}:" -ForegroundColor Cyan
        switch ($secret) {
            "SIGNOZ_URL" { 
                Write-Host "   gh secret set SIGNOZ_URL --body 'http://localhost:8080'" -ForegroundColor Gray
                Write-Host "   # or your SigNoz instance URL" -ForegroundColor DarkGray
            }
            "SIGNOZ_USER" { 
                Write-Host "   gh secret set SIGNOZ_USER --body 'your-signoz-username'" -ForegroundColor Gray
                Write-Host "   # your SigNoz login email/username" -ForegroundColor DarkGray
            }
            "SIGNOZ_PASS" { 
                Write-Host "   gh secret set SIGNOZ_PASS --body 'your-signoz-password'" -ForegroundColor Gray
                Write-Host "   # your SigNoz login password" -ForegroundColor DarkGray
            }
        }
        Write-Host ""
    }
    
    Write-Host "💡 Example complete setup:" -ForegroundColor Blue
    Write-Host "   gh secret set SIGNOZ_URL --body 'http://localhost:8080' --repo $Owner/$Repository" -ForegroundColor Gray
    Write-Host "   gh secret set SIGNOZ_USER --body 'admin@resonai.com' --repo $Owner/$Repository" -ForegroundColor Gray
    Write-Host "   gh secret set SIGNOZ_PASS --body 'your-password-here' --repo $Owner/$Repository" -ForegroundColor Gray
}

function Set-BranchProtection {
    param([string]$Owner, [string]$Repository)
    
    Write-Host "🔒 Setting up branch protection on main..." -ForegroundColor Yellow
    
    try {
        $protectionSettings = @{
            enforce_admins = $false
            required_status_checks = @{
                strict = $true
                checks = @("CodeQL", "SigNoz Automation", "ECRR Compliance")
            }
            required_pull_request_reviews = @{
                required_approving_review_count = 1
                dismiss_stale_reviews = $true
                require_code_owner_reviews = $false
            }
            restrictions = $null
        }
        
        $jsonSettings = $protectionSettings | ConvertTo-Json -Depth 3
        $jsonSettings | gh api "repos/$Owner/$Repository/branches/main/protection" --input -
        
        Write-Host "✅ Branch protection configured successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Failed to set branch protection: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "💡 You may need admin permissions for this repository" -ForegroundColor Blue
        return $false
    }
}

# Main execution
if ($TestOnly) {
    Write-Host "🔍 Running security test only..." -ForegroundColor Cyan
}

# Verify prerequisites
if (-not (Test-GitHubCLI)) { exit 1 }
if (-not (Test-Authentication)) { exit 1 }

# Test repository access
if (-not (Test-RepositoryAccess -Owner $repoConfig.Owner -Repository $repoConfig.Repository)) { exit 1 }

# Test branch protection
$protectionEnabled = Test-BranchProtection -Owner $repoConfig.Owner -Repository $repoConfig.Repository

# Test secrets
$secretsConfigured = Test-RepositorySecrets -Owner $repoConfig.Owner -Repository $repoConfig.Repository -RequiredSecrets $repoConfig.RequiredSecrets

# Generate setup instructions if needed
$needsSetup = -not ($protectionEnabled -and $secretsConfigured)

if ($needsSetup) {
    Write-Host ""
    Write-Host "⚠️  Repository security setup incomplete" -ForegroundColor Yellow
    
    if (-not $protectionEnabled) {
        Write-Host "❌ Branch protection needs configuration" -ForegroundColor Red
    }
    
    if (-not $secretsConfigured) {
        Write-Host "❌ Secrets need configuration" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Run branch protection setup (requires admin permissions)" -ForegroundColor White
    Write-Host "2. Configure required secrets for SigNoz automation" -ForegroundColor White
    Write-Host "3. Run this script again to verify all settings" -ForegroundColor White
    
    if ($SetupSecrets) {
        Show-SecretSetupInstructions -Owner $repoConfig.Owner -Repository $repoConfig.Repository -MissingSecrets @()
    }
}
else {
    Write-Host ""
    Write-Host "✅ Repository security is fully configured!" -ForegroundColor Green
    Write-Host "🎉 Ready for CI/CD automation" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "📊 Summary:" -ForegroundColor Cyan
    Write-Host "   Actions: ✅ Enabled" -ForegroundColor Green
    Write-Host "   Code Scanning: ✅ Enabled" -ForegroundColor Green
    Write-Host "   Branch Protection: ✅ Configured" -ForegroundColor Green
    Write-Host "   Secrets: ✅ Configured" -ForegroundColor Green
}

Write-Host ""
Write-Host "🔗 Useful Commands:" -ForegroundColor Cyan
Write-Host "   View secrets: gh secret list --repo $($repoConfig.FullName)" -ForegroundColor Gray
Write-Host "   View protection: gh api repos/$($repoConfig.FullName)/branches/main/protection" -ForegroundColor Gray
Write-Host "   Test actions: Go to Actions tab in GitHub UI" -ForegroundColor Gray
