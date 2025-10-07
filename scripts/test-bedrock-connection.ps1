$ErrorActionPreference = "Stop"

function Ensure-Cmd($name, $check) {
  if (-not (Get-Command $check -ErrorAction SilentlyContinue)) {
    throw "Missing prerequisite: $name (`"$check`")"
  }
}

Ensure-Cmd "AWS CLI" "aws"
aws sts get-caller-identity | Out-Null

if (-not (Test-Path env:AWS_REGION)) { $env:AWS_REGION = "us-east-1" }
if (-not (Test-Path env:BEDROCK_MODEL_ID)) { $env:BEDROCK_MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0" }

Write-Host "🐾 BossCat - Bedrock Connectivity Test"
Write-Host "Region: $env:AWS_REGION | Model: $env:BEDROCK_MODEL_ID"
pnpm dlx tsx scripts/test-bedrock-connection.ts

