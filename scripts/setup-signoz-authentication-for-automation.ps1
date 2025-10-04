# SigNoz Authentication Setup for Automation
# Configures proper authentication for GitHub Actions and automated dashboard capture

param(
    [string]$SignozUrl = $env:SIGNOZ_URL,
    [string]$SignozUser = $env:SIGNOZ_USER,
    [string]$SignozPass = $env:SIGNOZ_PASS,
    [switch]$TestOnly = $false
)

if (-not $SignozUrl) { $SignozUrl = 'http://localhost:8080' }

Write-Host "🔐 SigNoz Authentication Setup for Automation" -ForegroundColor Cyan
Write-Host "SigNoz URL: $SignozUrl" -ForegroundColor Gray
Write-Host ""

# Test SigNoz connectivity and authentication
function Test-SigNozAuthentication {
    Write-Host "🔍 Testing SigNoz authentication..." -ForegroundColor Cyan
    
    try {
        # Test unauthenticated health endpoint
        $healthResponse = Invoke-RestMethod -Uri "$SignozUrl/api/v1/health" -TimeoutSec 5
        Write-Host "   ✅ SigNoz Health: $($healthResponse.status)" -ForegroundColor Green
        
        # Test authentication if credentials provided
        if ($SignozUser -and $SignozPass) {
            Write-Host "   🔑 Testing authentication..." -ForegroundColor Cyan
            
            # Create basic auth header
            $authBytes = [System.Text.Encoding]::ASCII.GetBytes("$SignozUser:$SignozPass")
            $authHeader = "Basic " + [System.Convert]::ToBase64String($authBytes)
            
            $headers = @{
                "Authorization" = $authHeader
                "Content-Type" = "application/json"
            }
            
            # Test user info endpoint
            try {
                $userResponse = Invoke-RestMethod -Uri "$SignozUrl/api/v1/userInfo" -Headers $headers -TimeoutSec 5
                Write-Host "   ✅ Authentication: Success - User $($userResponse.data.email)" -ForegroundColor Green
                return $true
            }
            catch {
                Write-Host "   ❌ Authentication failed: $($_.Exception.Message)" -ForegroundColor Red
                
                # Test dashboard API endpoint
                try {
                    $dashboardResponse = Invoke-RestMethod -Uri "$SignozUrl/api/v1/dashboards" -Headers $headers -TimeoutSec 5
                    Write-Host "   ✅ Dashboard API: Success - $($dashboardResponse.Count) dashboards" -ForegroundColor Green
                    return $true
                }
                catch {
                    Write-Host "   ❌ Dashboard API failed: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "   💡 Trying login flow..." -ForegroundColor Yellow
                    
                    # Try login endpoint
                    $loginPayload = @{
                        email = $SignozUser
                        password = $SignozPass
                    } | ConvertTo-Json
                    
                    try {
                        $loginResponse = Invoke-RestMethod -Uri "$SignozUrl/api/v1/login" -Method Post -Body $loginPayload -ContentType "application/json" -TimeoutSec 5
                        Write-Host "   ✅ Login: Success - Token received" -ForegroundColor Green
                        return $true
                    }
                    catch {
                        Write-Host "   ❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
                        return $false
                    }
                }
            }
        }
        else {
            Write-Host "   ⚠️  No credentials provided - testing anonymous access" -ForegroundColor Yellow
            
            # Test if SigNoz allows anonymous access
            try {
                $dashboardResponse = Invoke-RestMethod -Uri "$SignozUrl/api/v1/dashboards" -TimeoutSec 5
                Write-Host "   ✅ Anonymous Access: Enabled - $($dashboardResponse.Count) dashboards" -ForegroundColor Green
                return $true
            }
            catch {
                Write-Host "   ❌ Anonymous access denied: Authentication required" -ForegroundColor Red
                Write-Host "   💡 Configure SIGNOZ_USER and SIGNOZ_PASS for authenticated access" -ForegroundColor Yellow
                return $false
            }
        }
    }
    catch {
        Write-Host "   ❌ SigNoz connectivity failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Configure authentication tokens for GitHub Actions
function Set-UpGitOpsAuthentication {
    Write-Host "🔧 Setting up GitOps authentication for automation..." -ForegroundColor Cyan
    
    $authMethods = @{
        "Environment Variables" = @{
            SIGNOZ_URL = $SignozUrl
            SIGNOZ_USER = $SignozUser
            SIGNOZ_PASS = $SignozPass
        }
        "GitHub Secrets" = @{
            RequiredSecrets = @("SIGNOZ_URL", "SIGNOZ_USER", "SIGNOZ_PASS")
            ConfigurationGuide = "gh secret set SIGNOZ_URL --body '$SignozUrl'"
        }
        "PowerShell Session" = @{
            CurrentValues = @{
                SIGNOS_URL = $env:SIGNOZ_URL ?? "not set"
                SIGNOZ_USER = $env:SIGNOZ_USER ?? "not set"  
                SIGNOZ_PASS = if ($env:SIGNOZ_PASS) { "***configured***" } else { "not set" }
            }
        }
    }
    
    Write-Host "📋 Authentication Configuration Summary:" -ForegroundColor Cyan
    
    foreach ($method in $authMethods.GetEnumerator()) {
        Write-Host "   $($method.Key):" -ForegroundColor Yellow
        foreach ($config in $method.Value.GetEnumerator()) {
            if ($config.Key -eq "RequiredSecrets") {
                Write-Host "     Required: $($config.Value -join ', ')" -ForegroundColor Gray
            }
            else {
                Write-Host "     $($config.Key): $($config.Value)" -ForegroundColor Gray
           <｜tool▁calls▁begin｜><｜tool▁call▁begin｜>
run_terminal_cmd
