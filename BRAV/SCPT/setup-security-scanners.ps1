# Security Scanner Setup Script
# MoneyCat Inc · Resonai [OTel] · BossCat OEM

param(
    [switch]$DryRun,
    [switch]$CheckStatus,
    [string]$SnykToken,
    [string]$APISecUsername,
    [string]$APISecPassword,
    [string]$GitLeaksLicense
)

Write-Host "🔐 Security Scanner Setup Script" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

function Test-GitHubCLI {
    try {
        $version = gh --version
        Write-Host "✅ GitHub CLI found: $($version.Split("`n")[0])" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ GitHub CLI not found. Install from: https://cli.github.com/" -ForegroundColor Red
        return $false
    }
}

function Get-RequiredSecrets {
    Write-Host "`n🔍 Checking current secrets..." -ForegroundColor Yellow
    
    $secrets = @{
        "SNYK_TOKEN" = $false
        "APISEC_USERNAME" = $false
        "APISEC_PASSWORD" = $false
        "GITLEAKS_LICENSE" = $false
    }
    
    try {
        $currentSecrets = gh secret list --json name | ConvertFrom-Json
        foreach ($secret in $currentSecrets) {
            if ($secrets.ContainsKey($secret.name)) {
                $secrets[$secret.name] = $true
            }
        }
    } catch {
        Write-Host "⚠️  Could not retrieve secret list" -ForegroundColor Yellow
    }
    
    return $secrets
}

function Set-SecuritySecrets {
    param($Secrets)
    
    Write-Host "`n🚀 Setting up security scanner secrets..." -ForegroundColor Yellow
    
    if ($SnykToken -and -not $Secrets["SNYK_TOKEN"]) {
        if ($DryRun) {
            Write-Host "🔧 [DRY RUN] Would set SNYK_TOKEN" -ForegroundColor Blue
        } else {
            try {
                gh secret set SNYK_TOKEN --body $SnykToken
                Write-Host "✅ SNYK_TOKEN set successfully" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to set SNYK_TOKEN: $_" -ForegroundColor Red
            }
        }
    }
    
    if ($APISecUsername -and -not $Secrets["APISEC_USERNAME"]) {
        if ($DryRun) {
            Write-Host "🔧 [DRY RUN] Would set APISEC_USERNAME" -ForegroundColor Blue
        } else {
            try {
                gh secret set APISEC_USERNAME --body $APISecUsername
                Write-Host "✅ APISEC_USERNAME set successfully" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to set APISEC_USERNAME: $_" -ForegroundColor Red
            }
        }
    }
    
    if ($APISecPassword -and -not $Secrets["APISEC_PASSWORD"]) {
        if ($DryRun) {
            Write-Host "🔧 [DRY RUN] Would set APISEC_PASSWORD" -ForegroundColor Blue
        } else {
            try {
                gh secret set APISEC_PASSWORD --body $APISecPassword
                Write-Host "✅ APISEC_PASSWORD set successfully" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to set APISEC_PASSWORD: $_" -ForegroundColor Red
            }
        }
    }
    
    if ($GitLeaksLicense -and -not $Secrets["GITLEAKS_LICENSE"]) {
        if ($DryRun) {
            Write-Host "🔧 [DRY RUN] Would set GITLEAKS_LICENSE" -ForegroundColor Blue
        } else {
            try {
                gh secret set GITLEAKS_LICENSE --body $GitLeaksLicense
                Write-Host "✅ GITLEAKS_LICENSE set successfully" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to set GITLEAKS_LICENSE: $_" -ForegroundColor Red
            }
        }
    }
}

function Test-SecurityScanners {
    Write-Host "`n🧪 Testing security scanners..." -ForegroundColor Yellow
    
    try {
        Write-Host "🔄 Triggering test workflow..." -ForegroundColor Blue
        $runId = gh workflow run "Full CI & Gate Verification" --ref main | Out-String
        
        if ($runId -match "Created workflow_dispatch event") {
            Write-Host "✅ Test workflow triggered successfully" -ForegroundColor Green
            Write-Host "📊 Monitor progress at: https://github.com/$($env:GITHUB_REPOSITORY)/actions" -ForegroundColor Cyan
        } else {
            Write-Host "⚠️  Workflow trigger response: $runId" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Failed to trigger test workflow: $_" -ForegroundColor Red
    }
}

function Show-Status {
    $secrets = Get-RequiredSecrets
    
    Write-Host "`n📊 Security Scanner Status:" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    
    foreach ($secret in $secrets.GetEnumerator()) {
        $status = if ($secret.Value) { "✅" } else { "❌" }
        Write-Host "$status $($secret.Key): $(if ($secret.Value) { 'Configured' } else { 'Missing' })" -ForegroundColor $(if ($secret.Value) { 'Green' } else { 'Red' })
    }
    
    Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
    if ($secrets.Values -contains $false) {
        Write-Host "1. Obtain missing credentials from respective services" -ForegroundColor White
        Write-Host "2. Run this script with credentials to set them" -ForegroundColor White
        Write-Host "3. Test with workflow run" -ForegroundColor White
    } else {
        Write-Host "1. All secrets configured! Test with workflow run" -ForegroundColor Green
    }
}

# Main execution
if (-not (Test-GitHubCLI)) {
    exit 1
}

if ($CheckStatus) {
    Show-Status
} else {
    $secrets = Get-RequiredSecrets
    Set-SecuritySecrets -Secrets $secrets
    
    if (-not $DryRun) {
        Show-Status
        Test-SecurityScanners
    }
}

Write-Host "`n🐾 Security Scanner Setup Complete" -ForegroundColor Cyan
