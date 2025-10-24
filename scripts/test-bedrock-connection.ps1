#!/usr/bin/env pwsh
# Gate #015 Job-1: Bedrock Connectivity Test
# ECRR: BossCat - Verify MCP + Bedrock operational
# Authority: BossCat OEM | Executor: Cursor{Implementer}

[CmdletBinding()]
param(
    [string]$Region = "us-east-1",
    [string]$ModelId = "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
    [string]$OutputFile = "artifacts/ecrr/gate015_job1_connectivity.json"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Host "🔌 Gate #015 - Bedrock Connectivity Test" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$evidence = @{
    gate = "015"
    job = "1"
    timestamp = (Get-Date -Format "o")
    objective = "Bedrock MCP connectivity verification"
    tests = @{}
    status = "UNKNOWN"
}

# Ensure output directory exists
New-Item -ItemType Directory -Path (Split-Path $OutputFile -Parent) -Force | Out-Null

# Test 1: AWS Credentials
Write-Host "▶ Test 1: AWS Credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    $evidence.tests.aws_credentials = @{
        status = "PASS"
        account = $identity.Account
        arn = $identity.Arn
    }
    Write-Host "✓ AWS Credentials valid" -ForegroundColor Green
    Write-Host "  Account: $($identity.Account)" -ForegroundColor Gray
} catch {
    $evidence.tests.aws_credentials = @{ status = "FAIL"; error = $_.ToString() }
    Write-Host "✗ AWS Credentials check failed: $_" -ForegroundColor Red
    $evidence.status = "RED"
    $evidence | ConvertTo-Json -Depth 10 | Set-Content $OutputFile
    exit 20
}

# Test 2: Bedrock IAM Permissions (attempt list models)
Write-Host "▶ Test 2: Bedrock IAM Permissions..." -ForegroundColor Yellow
try {
    $modelTest = aws bedrock list-foundation-models --region $Region --max-results 1 2>&1
    if ($LASTEXITCODE -eq 0) {
        $evidence.tests.bedrock_iam = @{ status = "PASS"; region = $Region }
        Write-Host "✓ Bedrock IAM permissions valid" -ForegroundColor Green
    } else {
        throw "Bedrock API access denied or unavailable"
  }
} catch {
    $evidence.tests.bedrock_iam = @{ status = "WARN"; error = $_.ToString(); note = "May work for InvokeModel even if list fails" }
    Write-Host "⚠ Bedrock list-models failed (may still work for invoke): $_" -ForegroundColor Yellow
}

# Test 3: Simple sync invocation (via AWS CLI as fallback)
Write-Host "▶ Test 3: Bedrock Sync Invocation..." -ForegroundColor Yellow
try {
    $prompt = "Say only 'BEDROCK_CONNECTED' and nothing else."
    $payload = @{
        anthropic_version = "bedrock-2023-05-31"
        max_tokens = 50
        messages = @(
            @{
                role = "user"
                content = $prompt
            }
        )
    } | ConvertTo-Json -Depth 10
    
    # Write payload to temp file for AWS CLI
    $tempPayload = "$env:TEMP\bedrock-test-payload.json"
    $payload | Set-Content $tempPayload -Encoding UTF8
    
    # Invoke via AWS CLI
    $response = aws bedrock-runtime invoke-model `
        --model-id $ModelId `
        --region $Region `
        --body "file://$tempPayload" `
        --output json `
        "$env:TEMP\bedrock-response.json" 2>&1
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path "$env:TEMP\bedrock-response.json")) {
        $responseContent = Get-Content "$env:TEMP\bedrock-response.json" -Raw | ConvertFrom-Json
        $bodyText = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($responseContent.body))
        $bodyJson = $bodyText | ConvertFrom-Json
        $responseText = $bodyJson.content[0].text
        
        $evidence.tests.bedrock_sync = @{
            status = "PASS"
            model = $ModelId
            response = $responseText
            tokens = $bodyJson.usage
        }
        
        Write-Host "✓ Bedrock sync invocation successful" -ForegroundColor Green
        Write-Host "  Response: $responseText" -ForegroundColor Cyan
        Write-Host "  Tokens: $($bodyJson.usage.input_tokens) in, $($bodyJson.usage.output_tokens) out" -ForegroundColor Gray
    } else {
        throw "Invoke model failed or no response file"
    }
    
    # Cleanup
    Remove-Item $tempPayload -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\bedrock-response.json" -ErrorAction SilentlyContinue
} catch {
    $evidence.tests.bedrock_sync = @{ status = "FAIL"; error = $_.ToString() }
    Write-Host "✗ Bedrock sync invocation failed: $_" -ForegroundColor Red
    $evidence.status = "RED"
    $evidence | ConvertTo-Json -Depth 10 | Set-Content $OutputFile
    exit 20
}

# Final Status
Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
$allPass = ($evidence.tests.aws_credentials.status -eq "PASS") -and 
           ($evidence.tests.bedrock_sync.status -eq "PASS")

if ($allPass) {
    $evidence.status = "GREEN"
    Write-Host "✅ Gate #015 Job-1: GREEN" -ForegroundColor Green
    Write-Host "   Bedrock connectivity operational" -ForegroundColor Green
} else {
    $evidence.status = "AMBER"
    Write-Host "⚠ Gate #015 Job-1: AMBER" -ForegroundColor Yellow
    Write-Host "   Some tests passed, review evidence" -ForegroundColor Yellow
}

# Save evidence
$evidence | ConvertTo-Json -Depth 10 | Set-Content $OutputFile
Write-Host ""
Write-Host "📋 Evidence: $OutputFile" -ForegroundColor Cyan
Write-Host "🐾 Job-1 complete" -ForegroundColor Cyan

if ($evidence.status -eq "GREEN") {
    exit 0
} else {
    exit 10
}
