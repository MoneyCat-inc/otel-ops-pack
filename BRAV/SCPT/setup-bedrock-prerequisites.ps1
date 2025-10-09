# BossCat OEM - Bedrock Prerequisites Setup
# Purpose: Install and verify all prerequisites for AWS Bedrock MCP integration
# Agent: Cursor Implementer (Gap-Closer)
# ECRR Phase: Clean
# Based on: https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/mcp-install-server.html

[CmdletBinding()]
param(
    [switch]$CheckOnly,
    [switch]$Force
)

$ErrorActionPreference = "Continue"

Write-Host "🐾 BossCat OEM - Bedrock Prerequisites Check" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Gray

$allGood = $true

# ============================================================================
# 1. Check Python
# ============================================================================
Write-Host "`n🔍 [Examine] Checking Python installation..." -ForegroundColor Yellow

try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python installed: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python not found" -ForegroundColor Red
    Write-Host "   Download from: https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "   Or use winget: winget install Python.Python.3.12" -ForegroundColor Yellow
    $allGood = $false
}

# ============================================================================
# 2. Check pip
# ============================================================================
Write-Host "`n🔍 [Examine] Checking pip..." -ForegroundColor Yellow

try {
    $pipVersion = pip --version 2>&1
    Write-Host "✅ pip installed: $pipVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ pip not found" -ForegroundColor Red
    Write-Host "   Install: python -m ensurepip --upgrade" -ForegroundColor Yellow
    $allGood = $false
}

# ============================================================================
# 3. Check uvx (critical for MCP server)
# ============================================================================
Write-Host "`n🔍 [Examine] Checking uvx (AWS MCP server requirement)..." -ForegroundColor Yellow

try {
    $uvxVersion = uvx --version 2>&1
    Write-Host "✅ uvx installed: $uvxVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ uvx not found (required for AWS AgentCore MCP server)" -ForegroundColor Red
    $allGood = $false
    
    if (-not $CheckOnly) {
        Write-Host "`n🧹 [Clean] Installing uv package (includes uvx)..." -ForegroundColor Yellow
        
        try {
            pip install uv
            Write-Host "✅ uv installed successfully" -ForegroundColor Green
            
            # Verify installation
            $uvxVersion = uvx --version 2>&1
            Write-Host "✅ uvx now available: $uvxVersion" -ForegroundColor Green
            $allGood = $true
        } catch {
            Write-Host "❌ Failed to install uv: $_" -ForegroundColor Red
            Write-Host "   Try manually: pip install uv" -ForegroundColor Yellow
            Write-Host "   Or via pipx: pipx install uv" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   Install: pip install uv" -ForegroundColor Yellow
        Write-Host "   Documentation: https://docs.astral.sh/uv/" -ForegroundColor Cyan
    }
}

# ============================================================================
# 4. Check AWS CLI
# ============================================================================
Write-Host "`n🔍 [Examine] Checking AWS CLI..." -ForegroundColor Yellow

try {
    $awsVersion = aws --version 2>&1
    Write-Host "✅ AWS CLI installed: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not found" -ForegroundColor Red
    Write-Host "   Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    Write-Host "   Or use winget: winget install Amazon.AWSCLI" -ForegroundColor Yellow
    $allGood = $false
}

# ============================================================================
# 5. Check AWS Credentials
# ============================================================================
Write-Host "`n🔍 [Examine] Checking AWS credentials..." -ForegroundColor Yellow

try {
    $identity = aws sts get-caller-identity --output json 2>&1 | ConvertFrom-Json
    Write-Host "✅ AWS credentials valid" -ForegroundColor Green
    Write-Host "   User/Role: $($identity.Arn)" -ForegroundColor Cyan
} catch {
    Write-Host "⚠️  AWS credentials not configured or invalid" -ForegroundColor Yellow
    Write-Host "   Run: aws configure" -ForegroundColor Yellow
    Write-Host "   Required for Bedrock API calls" -ForegroundColor Yellow
}

# ============================================================================
# 6. Check Node.js / pnpm
# ============================================================================
Write-Host "`n🔍 [Examine] Checking Node.js and pnpm..." -ForegroundColor Yellow

try {
    $nodeVersion = node --version 2>&1
    Write-Host "✅ Node.js installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found" -ForegroundColor Red
    $allGood = $false
}

try {
    $pnpmVersion = pnpm --version 2>&1
    Write-Host "✅ pnpm installed: v$pnpmVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️  pnpm not found (optional, but recommended)" -ForegroundColor Yellow
    Write-Host "   Install: npm install -g pnpm" -ForegroundColor Yellow
}

# ============================================================================
# 7. Check if .cursor/mcp.json exists
# ============================================================================
Write-Host "`n🔍 [Examine] Checking Cursor MCP configuration..." -ForegroundColor Yellow

if (Test-Path ".cursor/mcp.json") {
    Write-Host "✅ .cursor/mcp.json exists" -ForegroundColor Green
    
    # Verify it contains the AWS MCP server
    $mcpConfig = Get-Content ".cursor/mcp.json" | ConvertFrom-Json
    if ($mcpConfig.mcpServers.'awslabs.amazon-bedrock-agentcore-mcp-server') {
        Write-Host "✅ AWS AgentCore MCP server configured" -ForegroundColor Green
    } else {
        Write-Host "⚠️  AWS AgentCore MCP server not found in config" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  .cursor/mcp.json not found" -ForegroundColor Yellow
    Write-Host "   Should be created at repo root" -ForegroundColor Yellow
}

# ============================================================================
# 8. Check AWS SDK
# ============================================================================
Write-Host "`n🔍 [Examine] Checking AWS SDK for JavaScript..." -ForegroundColor Yellow

$packageJson = Get-Content "package.json" | ConvertFrom-Json
if ($packageJson.dependencies.'@aws-sdk/client-bedrock-runtime') {
    $version = $packageJson.dependencies.'@aws-sdk/client-bedrock-runtime'
    Write-Host "✅ @aws-sdk/client-bedrock-runtime installed: $version" -ForegroundColor Green
} else {
    Write-Host "⚠️  @aws-sdk/client-bedrock-runtime not found" -ForegroundColor Yellow
    Write-Host "   Install: pnpm add -w @aws-sdk/client-bedrock-runtime" -ForegroundColor Yellow
}

# ============================================================================
# Summary
# ============================================================================
Write-Host "`n" + ("=" * 60) -ForegroundColor Gray

if ($allGood) {
    Write-Host "✅ [Report] All critical prerequisites installed!" -ForegroundColor Green
    Write-Host "`n🎯 [Role] Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Restart Cursor IDE completely (to load MCP server)" -ForegroundColor White
    Write-Host "   2. Run: pwsh -File scripts\test-bedrock-connection.ps1" -ForegroundColor White
    Write-Host "   3. Verify MCP tools in Cursor: search_agentcore_docs" -ForegroundColor White
} else {
    Write-Host "❌ [Report] Some prerequisites missing" -ForegroundColor Red
    Write-Host "`n🔧 [Role] Gap-Closer action required:" -ForegroundColor Yellow
    Write-Host "   1. Install missing components (see errors above)" -ForegroundColor White
    Write-Host "   2. Re-run: pwsh -File scripts\setup-bedrock-prerequisites.ps1" -ForegroundColor White
}

Write-Host "`n📚 Documentation: docs\BossCat\BEDROCK_INTEGRATION_GUIDE.md" -ForegroundColor Cyan
Write-Host "🐾 BossCat OEM - Prerequisites check complete" -ForegroundColor Cyan

exit $(if ($allGood) { 0 } else { 1 })

