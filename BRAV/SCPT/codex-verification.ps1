# Codex Configuration Verification Script
# Cat Nap Control Room - Low-Latency Observability Pipeline

param(
    [switch]$Detailed,
    [switch]$FixIssues
)

Write-Host "🐾 Codex Configuration Verification" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

$Issues = @()
$Warnings = @()

# Check if .codex directory exists
Write-Host "`n📁 Checking .codex directory..." -ForegroundColor Yellow
$CodexPath = "$env:USERPROFILE\.codex"
if (Test-Path $CodexPath) {
    Write-Host "✅ .codex directory exists: $CodexPath" -ForegroundColor Green
} else {
    $Issues += ".codex directory not found at $CodexPath"
    Write-Host "❌ .codex directory not found" -ForegroundColor Red
}

# Check directory permissions
Write-Host "`n🔐 Checking directory permissions..." -ForegroundColor Yellow
if (Test-Path $CodexPath) {
    $Acl = Get-Acl $CodexPath
    $UserAccess = $Acl.Access | Where-Object { $_.IdentityReference -like "*$env:USERNAME*" }
    if ($UserAccess -and $UserAccess.FileSystemRights -match "FullControl") {
        Write-Host "✅ User has full control permissions" -ForegroundColor Green
    } else {
        $Warnings += "User may not have optimal permissions on .codex directory"
        Write-Host "⚠️  Permission check inconclusive" -ForegroundColor Yellow
    }
}

# Check core configuration files
Write-Host "`n📄 Checking configuration files..." -ForegroundColor Yellow

$RequiredFiles = @(
    "config.toml",
    "auth.json", 
    "version.json",
    "internal_storage.json"
)

foreach ($File in $RequiredFiles) {
    $FilePath = Join-Path $CodexPath $File
    if (Test-Path $FilePath) {
        Write-Host "✅ $File exists" -ForegroundColor Green
    } else {
        $Issues += "Required file missing: $File"
        Write-Host "❌ $File missing" -ForegroundColor Red
    }
}

# Validate config.toml syntax
Write-Host "`n🔧 Validating config.toml syntax..." -ForegroundColor Yellow
$ConfigPath = Join-Path $CodexPath "config.toml"
if (Test-Path $ConfigPath) {
    try {
        # Basic TOML syntax check - look for common issues
        $ConfigContent = Get-Content $ConfigPath -Raw
        if ($ConfigContent -match '\[.*\]' -and $ConfigContent -match '=') {
            Write-Host "✅ config.toml appears to have valid TOML syntax" -ForegroundColor Green
        } else {
            $Issues += "config.toml may have syntax issues"
            Write-Host "❌ config.toml syntax validation failed" -ForegroundColor Red
        }
    } catch {
        $Issues += "Error reading config.toml: $($_.Exception.Message)"
        Write-Host "❌ Error reading config.toml" -ForegroundColor Red
    }
}

# Check auth.json security
Write-Host "`n🔒 Checking auth.json security..." -ForegroundColor Yellow
$AuthPath = Join-Path $CodexPath "auth.json"
if (Test-Path $AuthPath) {
    try {
        $AuthContent = Get-Content $AuthPath | ConvertFrom-Json
        if ($AuthContent.OPENAI_API_KEY -and $AuthContent.OPENAI_API_KEY -ne "null") {
            Write-Host "✅ auth.json contains API credentials" -ForegroundColor Green
        } else {
            $Warnings += "auth.json may not contain valid API credentials"
            Write-Host "⚠️  auth.json API key check inconclusive" -ForegroundColor Yellow
        }
    } catch {
        $Issues += "auth.json may be corrupted or invalid JSON"
        Write-Host "❌ Error reading auth.json" -ForegroundColor Red
    }
}

# Check MCP server dependencies
Write-Host "`n🔌 Checking MCP server dependencies..." -ForegroundColor Yellow
$NpmCheck = Get-Command npm -ErrorAction SilentlyContinue
if ($NpmCheck) {
    Write-Host "✅ npm available for MCP servers" -ForegroundColor Green
} else {
    $Warnings += "npm not found - MCP servers may not work"
    Write-Host "⚠️  npm not found" -ForegroundColor Yellow
}

$NodeCheck = Get-Command node -ErrorAction SilentlyContinue
if ($NodeCheck) {
    Write-Host "✅ node available for MCP servers" -ForegroundColor Green
} else {
    $Warnings += "node not found - MCP servers may not work"
    Write-Host "⚠️  node not found" -ForegroundColor Yellow
}

# Check project integration
Write-Host "`n🏗️  Checking OTel project integration..." -ForegroundColor Yellow
$OtelPath = "C:\otel"
if (Test-Path $OtelPath) {
    Write-Host "✅ OTel project directory exists" -ForegroundColor Green
    
    # Check for required OTel files
    $OtelFiles = @("config.yaml", "docker-compose.yml", "package.json")
    foreach ($File in $OtelFiles) {
        $FilePath = Join-Path $OtelPath $File
        if (Test-Path $FilePath) {
            Write-Host "✅ OTel $File exists" -ForegroundColor Green
        } else {
            $Warnings += "OTel project missing $File"
            Write-Host "⚠️  OTel $File missing" -ForegroundColor Yellow
        }
    }
} else {
    $Warnings += "OTel project directory not found at $OtelPath"
    Write-Host "⚠️  OTel project directory not found" -ForegroundColor Yellow
}

# Check SigNoz availability
Write-Host "`n📊 Checking SigNoz integration..." -ForegroundColor Yellow
try {
    $Response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5 -ErrorAction Stop
    if ($Response.StatusCode -eq 200) {
        Write-Host "✅ SigNoz is accessible" -ForegroundColor Green
    }
} catch {
    $Warnings += "SigNoz not accessible at localhost:8080"
    Write-Host "⚠️  SigNoz not accessible" -ForegroundColor Yellow
}

# Summary
Write-Host "`n📋 Verification Summary" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

if ($Issues.Count -eq 0) {
    Write-Host "✅ No critical issues found!" -ForegroundColor Green
} else {
    Write-Host "❌ Critical Issues Found:" -ForegroundColor Red
    foreach ($Issue in $Issues) {
        Write-Host "   • $Issue" -ForegroundColor Red
    }
}

if ($Warnings.Count -gt 0) {
    Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
    foreach ($Warning in $Warnings) {
        Write-Host "   • $Warning" -ForegroundColor Yellow
    }
}

# Restart instructions
Write-Host "`n🔄 Restart Instructions" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host "To apply configuration changes:" -ForegroundColor White
Write-Host "1. Close all Codex CLI sessions" -ForegroundColor White
Write-Host "2. Restart VS Code (if using Codex extension)" -ForegroundColor White
Write-Host "3. Run: codex config validate" -ForegroundColor White
Write-Host "4. Test with: codex --help" -ForegroundColor White

# ECRR Compliance
Write-Host "`n📝 ECRR Report Generated" -ForegroundColor Cyan
$ReportPath = "C:\otel\artifacts\codex-verification-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$Report = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    issues = $Issues
    warnings = $Warnings
    config_valid = ($Issues.Count -eq 0)
    mcp_ready = ($NpmCheck -and $NodeCheck)
    signoz_accessible = ($Response.StatusCode -eq 200)
}

$Report | ConvertTo-Json -Depth 3 | Out-File $ReportPath -Encoding UTF8
Write-Host "Report saved to: $ReportPath" -ForegroundColor Green

if ($Issues.Count -eq 0) {
    Write-Host "`n🎉 Codex configuration is ready for use!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ Please fix critical issues before using Codex" -ForegroundColor Red
    exit 1
}
