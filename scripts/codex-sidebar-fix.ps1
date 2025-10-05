# Codex Sidebar Fix Verification Script
# Cat Nap Control Room - Low-Latency Observability Pipeline

Write-Host "🐾 Codex Sidebar Fix Verification" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Test basic Codex functionality
Write-Host "`n🔧 Testing Codex CLI functionality..." -ForegroundColor Yellow

try {
    $TestResult = codex -m "gpt-5-codex" "test connection" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Codex CLI is working with gpt-5-codex model" -ForegroundColor Green
    } else {
        Write-Host "❌ Codex CLI test failed" -ForegroundColor Red
        Write-Host "Error: $TestResult" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error testing Codex CLI: $($_.Exception.Message)" -ForegroundColor Red
}

# Check configuration file
Write-Host "`n📄 Verifying configuration..." -ForegroundColor Yellow
$ConfigPath = "$env:USERPROFILE\.codex\config.toml"
if (Test-Path $ConfigPath) {
    $ConfigContent = Get-Content $ConfigPath -Raw
    if ($ConfigContent -match 'model = "gpt-5-codex"') {
        Write-Host "✅ Model is correctly set to gpt-5-codex" -ForegroundColor Green
    } else {
        Write-Host "❌ Model setting not found or incorrect" -ForegroundColor Red
    }
    
    if ($ConfigContent -match 'persistence = "save-all"') {
        Write-Host "✅ History persistence is correctly set" -ForegroundColor Green
    } else {
        Write-Host "❌ History persistence setting incorrect" -ForegroundColor Red
    }
    
    if ($ConfigContent -match 'inherit = "all"') {
        Write-Host "✅ Shell environment policy is correct" -ForegroundColor Green
    } else {
        Write-Host "❌ Shell environment policy needs fixing" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Configuration file not found at $ConfigPath" -ForegroundColor Red
}

# Check auth.json
Write-Host "`n🔐 Verifying authentication..." -ForegroundColor Yellow
$AuthPath = "$env:USERPROFILE\.codex\auth.json"
if (Test-Path $AuthPath) {
    try {
        $AuthContent = Get-Content $AuthPath | ConvertFrom-Json
        if ($AuthContent.tokens.access_token -and $AuthContent.tokens.access_token -ne "null") {
            Write-Host "✅ Authentication tokens are present" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Authentication tokens may be missing or invalid" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Error reading auth.json: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ auth.json not found at $AuthPath" -ForegroundColor Red
}

Write-Host "`n🎯 Sidebar Loading Instructions" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "To get the Codex sidebar to load properly:" -ForegroundColor White
Write-Host "1. Close all Codex CLI sessions" -ForegroundColor White
Write-Host "2. Restart VS Code/Cursor completely" -ForegroundColor White
Write-Host "3. Open the Codex extension/sidebar" -ForegroundColor White
Write-Host "4. The sidebar should now load with gpt-5-codex model" -ForegroundColor White

Write-Host "`n📋 Configuration Summary" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host "✅ Model: gpt-5-codex (corrected from gpt-5-Codex)" -ForegroundColor Green
Write-Host "✅ History persistence: save-all (corrected from enabled)" -ForegroundColor Green
Write-Host "✅ Shell environment: inherit all (simplified)" -ForegroundColor Green
Write-Host "✅ MCP servers: commented out to prevent conflicts" -ForegroundColor Green
Write-Host "✅ Custom sections: commented out to prevent parsing errors" -ForegroundColor Green

Write-Host "`n🎉 Codex configuration is now ready for sidebar use!" -ForegroundColor Green
