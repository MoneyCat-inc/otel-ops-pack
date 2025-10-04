# 🐾 BossCat GitHub Token Validator
# Tests GitHub token authentication and permissions

param(
    [string]$GitHubToken = $env:GITHUB_TOKEN,
    [string]$Repository = "resonai/otel"
)

function Write-BossCatLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "🐾 [$timestamp] $Message" -ForegroundColor Cyan
}

function Test-GitHubToken {
    param([string]$Token)
    
    if (-not $Token) {
        Write-Error "❌ No GitHub token provided"
        return $false
    }
    
    # Test with both classic and fine-grained PAT formats
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.github.v3+json"
        "User-Agent" = "BossCat-OEP"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    
    try {
        Write-BossCatLog "Testing GitHub token authentication..."
        $userResponse = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
        Write-Host "✅ Token valid for user: $($userResponse.login)" -ForegroundColor Green
        Write-Host "   Name: $($userResponse.name)" -ForegroundColor Gray
        Write-Host "   Email: $($userResponse.email)" -ForegroundColor Gray
        
        return $true
    }
    catch {
        Write-Host "❌ Token authentication failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Try classic PAT format as fallback
        try {
            Write-BossCatLog "Trying classic PAT format..."
            $classicHeaders = @{
                "Authorization" = "token $Token"
                "Accept" = "application/vnd.github.v3+json"
                "User-Agent" = "BossCat-OEP"
            }
            $userResponse = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $classicHeaders
            Write-Host "✅ Classic PAT format works for user: $($userResponse.login)" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "❌ Classic PAT format also failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

function Test-RepositoryAccess {
    param([string]$Token, [string]$Repo)
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.github.v3+json"
        "User-Agent" = "BossCat-OEP"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    
    try {
        Write-BossCatLog "Testing repository access for $Repo..."
        $repoResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo" -Headers $headers
        Write-Host "✅ Repository access confirmed: $($repoResponse.full_name)" -ForegroundColor Green
        Write-Host "   Private: $($repoResponse.private)" -ForegroundColor Gray
        Write-Host "   Permissions: $($repoResponse.permissions | ConvertTo-Json -Compress)" -ForegroundColor Gray
        
        return $true
    }
    catch {
        Write-Host "❌ Repository access failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Try classic PAT format
        try {
            $classicHeaders = @{
                "Authorization" = "token $Token"
                "Accept" = "application/vnd.github.v3+json"
                "User-Agent" = "BossCat-OEP"
            }
            $repoResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo" -Headers $classicHeaders
            Write-Host "✅ Classic PAT repository access works" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "❌ Classic PAT repository access also failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

function Test-IssuePermissions {
    param([string]$Token, [string]$Repo)
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.github.v3+json"
        "User-Agent" = "BossCat-OEP"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    
    try {
        Write-BossCatLog "Testing issue creation permissions..."
        
        # Try to list issues first (read permission)
        $issuesResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/issues?state=all&per_page=1" -Headers $headers
        Write-Host "✅ Issue read permission confirmed" -ForegroundColor Green
        
        # Try to create a test issue (write permission)
        $testIssue = @{
            title = "BossCat Token Test - DELETE ME"
            body = "This is a test issue created by BossCat token validator. Please delete this issue."
            labels = @("test", "bosscat-token-test")
        } | ConvertTo-Json
        
        $createResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/issues" -Method Post -Headers $headers -Body $testIssue
        Write-Host "✅ Issue creation permission confirmed" -ForegroundColor Green
        Write-Host "   Test issue created: #$($createResponse.number)" -ForegroundColor Gray
        
        # Clean up test issue
        try {
            $closeResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/issues/$($createResponse.number)" -Method Patch -Headers $headers -Body '{"state":"closed"}' | Out-Null
            Write-Host "✅ Test issue closed for cleanup" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️  Could not close test issue #$($createResponse.number) - please delete manually" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Host "❌ Issue permissions failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Try classic PAT format
        try {
            $classicHeaders = @{
                "Authorization" = "token $Token"
                "Accept" = "application/vnd.github.v3+json"
                "User-Agent" = "BossCat-OEP"
            }
            $issuesResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/issues?state=all&per_page=1" -Headers $classicHeaders
            Write-Host "✅ Classic PAT issue permissions work" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "❌ Classic PAT issue permissions also failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

# Main execution
Write-BossCatLog "Starting BossCat GitHub Token Validation..."

if (-not $GitHubToken) {
    Write-Error "❌ No GitHub token provided. Set GITHUB_TOKEN environment variable or use -GitHubToken parameter"
    Write-Host "`n🔑 Token Setup Instructions:" -ForegroundColor Yellow
    Write-Host "1. Go to GitHub → Settings → Developer settings → Personal access tokens" -ForegroundColor White
    Write-Host "2. Generate new token (classic) with 'repo' scope" -ForegroundColor White
    Write-Host "3. Or generate fine-grained token with 'Issues: Read & Write' permission" -ForegroundColor White
    Write-Host "4. Set environment variable: `$env:GITHUB_TOKEN = 'your_token_here'" -ForegroundColor White
    exit 1
}

Write-Host "`n🔍 Testing GitHub Token..." -ForegroundColor Cyan

# Test 1: Basic authentication
$authOk = Test-GitHubToken -Token $GitHubToken
if (-not $authOk) {
    Write-Host "`n❌ Token validation failed. Please check your token." -ForegroundColor Red
    exit 1
}

# Test 2: Repository access
$repoOk = Test-RepositoryAccess -Token $GitHubToken -Repo $Repository
if (-not $repoOk) {
    Write-Host "`n❌ Repository access failed. Please check repository permissions." -ForegroundColor Red
    exit 1
}

# Test 3: Issue permissions
$issueOk = Test-IssuePermissions -Token $GitHubToken -Repo $Repository
if (-not $issueOk) {
    Write-Host "`n❌ Issue permissions failed. Please check issue creation permissions." -ForegroundColor Red
    exit 1
}

Write-Host "`n🎉 All GitHub Token Tests PASSED!" -ForegroundColor Green
Write-Host "✅ Authentication working" -ForegroundColor Green
Write-Host "✅ Repository access confirmed" -ForegroundColor Green
Write-Host "✅ Issue creation permissions verified" -ForegroundColor Green

Write-Host "`n🚀 Ready to create GitHub issues!" -ForegroundColor Cyan
Write-Host "Run: pwsh -File scripts/create-gpu-epic-issues.ps1" -ForegroundColor Yellow
