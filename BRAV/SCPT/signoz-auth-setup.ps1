# SigNoz Authentication Setup
# Configure authentication for alert deployment and API access
# Cursor-Local: Observability Copilot

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$Email = "admin@signoz.io",
    [string]$Password = "admin"
)

Write-Host "🔐 SigNoz Authentication Setup" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Check SigNoz connectivity
Write-Host "🔍 Checking SigNoz connectivity..." -ForegroundColor Yellow
try {
    $HealthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method Get -TimeoutSec 10
    Write-Host "✅ SigNoz is healthy: $($HealthResponse.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ SigNoz not accessible: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check if authentication is required
Write-Host "`n🔍 Checking authentication requirements..." -ForegroundColor Yellow
try {
    $VersionResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/version" -Method Get -TimeoutSec 10
    Write-Host "✅ SigNoz version: $($VersionResponse.version)" -ForegroundColor Green
    Write-Host "   Setup completed: $($VersionResponse.setupCompleted)" -ForegroundColor Gray
    Write-Host "   Enterprise: $($VersionResponse.ee)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Version check failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Try to access protected endpoint without auth
Write-Host "`n🔍 Testing protected endpoint access..." -ForegroundColor Yellow
try {
    $ProtectedResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/dashboards" -Method Get -TimeoutSec 10
    Write-Host "✅ No authentication required - SigNoz is in open mode" -ForegroundColor Green
    $AuthRequired = $false
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "🔐 Authentication required - SigNoz is in protected mode" -ForegroundColor Yellow
        $AuthRequired = $true
    } else {
        Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

if ($AuthRequired) {
    Write-Host "`n🔐 Attempting authentication..." -ForegroundColor Yellow
    
    try {
        # Try login
        $LoginBody = @{
            email = $Email
            password = $Password
        } | ConvertTo-Json
        
        $LoginResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/auth/login" -Method Post -Body $LoginBody -ContentType "application/json" -TimeoutSec 10
        
        if ($LoginResponse.accessJwt) {
            Write-Host "✅ Authentication successful!" -ForegroundColor Green
            Write-Host "   Access token: $($LoginResponse.accessJwt.Substring(0, 20))..." -ForegroundColor Gray
            
            # Save token for future use
            $TokenFile = "artifacts/signoz-token.json"
            $TokenData = @{
                timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                access_jwt = $LoginResponse.accessJwt
                refresh_jwt = $LoginResponse.refreshJwt
                expires_at = (Get-Date).AddHours(24).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
            
            $TokenData | ConvertTo-Json -Depth 3 | Set-Content -Path $TokenFile
            Write-Host "   Token saved to: $TokenFile" -ForegroundColor Gray
            
            # Test authenticated access
            $Headers = @{
                "Authorization" = "Bearer $($LoginResponse.accessJwt)"
            }
            
            $TestResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/dashboards" -Method Get -Headers $Headers -TimeoutSec 10
            Write-Host "✅ Authenticated access verified" -ForegroundColor Green
            
        } else {
            Write-Host "❌ Authentication failed - no access token received" -ForegroundColor Red
            exit 1
        }
        
    } catch {
        Write-Host "❌ Authentication failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Try alternative authentication methods
        Write-Host "`n🔍 Trying alternative authentication..." -ForegroundColor Yellow
        
        # Check if there's a setup endpoint
        try {
            $SetupResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/setup" -Method Get -TimeoutSec 10
            Write-Host "📋 Setup endpoint available" -ForegroundColor Yellow
            Write-Host "   Setup data: $($SetupResponse | ConvertTo-Json -Compress)" -ForegroundColor Gray
        } catch {
            Write-Host "⚠️ Setup endpoint not available" -ForegroundColor Yellow
        }
        
        exit 1
    }
} else {
    Write-Host "`n✅ SigNoz is in open mode - no authentication required" -ForegroundColor Green
    Write-Host "   You can access all endpoints without authentication" -ForegroundColor Gray
}

# Create authentication helper script
Write-Host "`n📝 Creating authentication helper script..." -ForegroundColor Yellow

$AuthHelperScript = @"
# SigNoz Authentication Helper
# Use this script to get authenticated headers for API calls

param(
    [string]`$SigNozUrl = "http://localhost:8080"
)

function Get-SigNozAuthHeaders {
    `$TokenFile = "artifacts/signoz-token.json"
    
    if (Test-Path `$TokenFile) {
        `$TokenData = Get-Content `$TokenFile | ConvertFrom-Json
        
        # Check if token is still valid
        `$ExpiresAt = [DateTime]::Parse(`$TokenData.expires_at)
        if ((Get-Date) -lt `$ExpiresAt) {
            return @{
                "Authorization" = "Bearer `$(`$TokenData.access_jwt)"
            }
        } else {
            Write-Host "⚠️ Token expired, re-authentication required" -ForegroundColor Yellow
        }
    }
    
    # Return empty headers if no valid token
    return @{}
}

# Export function for use in other scripts
Export-ModuleMember -Function Get-SigNozAuthHeaders
"@

$AuthHelperScript | Set-Content -Path "scripts/signoz-auth-helper.ps1"
Write-Host "   Helper script created: scripts/signoz-auth-helper.ps1" -ForegroundColor Gray

# Test alert deployment with authentication
Write-Host "`n🧪 Testing alert deployment with authentication..." -ForegroundColor Yellow

if ($AuthRequired -and $LoginResponse.accessJwt) {
    try {
        $Headers = @{
            "Authorization" = "Bearer $($LoginResponse.accessJwt)"
            "Content-Type" = "application/json"
        }
        
        # Test alert rule creation
        $TestAlert = @{
            alert = "Test Alert - Authentication"
            expr = "up == 0"
            for = "1m"
            labels = @{
                severity = "warning"
                test = "true"
            }
            annotations = @{
                summary = "Test alert for authentication verification"
                description = "This is a test alert to verify SigNoz authentication is working"
            }
        }
        
        $AlertResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/rules" -Method Post -Body ($TestAlert | ConvertTo-Json -Depth 5) -Headers $Headers -TimeoutSec 30
        
        Write-Host "✅ Alert deployment test successful!" -ForegroundColor Green
        Write-Host "   Test alert created: $($AlertResponse.rule_id)" -ForegroundColor Gray
        
        # Clean up test alert
        try {
            Invoke-RestMethod -Uri "$SigNozUrl/api/v1/rules/$($AlertResponse.rule_id)" -Method Delete -Headers $Headers -TimeoutSec 10
            Write-Host "   Test alert cleaned up" -ForegroundColor Gray
        } catch {
            Write-Host "   ⚠️ Could not clean up test alert" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "❌ Alert deployment test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n📊 SigNoz Authentication Setup Summary:" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

if ($AuthRequired) {
    Write-Host "🔐 Authentication: Required" -ForegroundColor Yellow
    Write-Host "✅ Status: Configured" -ForegroundColor Green
    Write-Host "📁 Token file: artifacts/signoz-token.json" -ForegroundColor Gray
    Write-Host "🔧 Helper script: scripts/signoz-auth-helper.ps1" -ForegroundColor Gray
} else {
    Write-Host "🔓 Authentication: Not required (open mode)" -ForegroundColor Green
    Write-Host "✅ Status: Ready for API access" -ForegroundColor Green
}

Write-Host "`n🎉 SigNoz Authentication Setup Complete!" -ForegroundColor Green
Write-Host "🚀 You can now deploy alerts and access protected endpoints" -ForegroundColor Blue
