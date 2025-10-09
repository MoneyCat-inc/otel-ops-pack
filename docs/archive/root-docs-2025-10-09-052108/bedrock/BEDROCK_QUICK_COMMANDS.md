# 🐾 Bedrock Integration - Quick Command Reference

**Status:** Ready to resume (waiting on AWS credentials)  
**Resume Guide:** `BEDROCK_RESUME_WHEN_READY.md`

---

## 🚀 When You Have AWS Credentials

### Quick 5-Minute Setup

```powershell
# 1. Configure AWS CLI (you'll be prompted for inputs)
aws configure
# Enter: Access Key ID (AKIA...), Secret Key, us-east-1, json

# 2. Verify credentials work
aws sts get-caller-identity
# Should return your User ARN and Account ID

# 3. Restart Cursor IDE completely
# Close all windows → Check Task Manager → Reopen

# 4. Run Bedrock connectivity test
cd C:\otel
pnpm dlx tsx scripts/test-bedrock-connection.ts

# Or use PowerShell wrapper
pwsh -File scripts\test-bedrock-connection.ps1
```

---

## 📋 Prerequisites Check

```powershell
# Check all prerequisites
pwsh -File scripts\setup-bedrock-prerequisites.ps1

# Check only (no auto-install)
pwsh -File scripts\setup-bedrock-prerequisites.ps1 -CheckOnly
```

---

## 🔍 Verification Commands

```powershell
# AWS CLI installed?
aws --version
# Should show: aws-cli/2.31.9

# uvx installed?
uvx --version
# Should show: uvx 0.8.24

# Credentials configured?
aws sts get-caller-identity
# Should show JSON with your ARN

# Model access enabled?
aws bedrock list-foundation-models --region us-east-1 --query "modelSummaries[?contains(modelId, 'claude-3-haiku')]"
# Should return Claude 3 Haiku model info

# AWS SDK installed?
cat package.json | Select-String "bedrock-runtime"
# Should show: @aws-sdk/client-bedrock-runtime
```

---

## 🎯 Test with Different Models

```powershell
# Claude 3 Haiku (fast, cheap)
$env:BEDROCK_MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0"
pnpm dlx tsx scripts/test-bedrock-connection.ts

# Claude 3 Sonnet (balanced)
$env:BEDROCK_MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0"
pnpm dlx tsx scripts/test-bedrock-connection.ts

# Claude 3 Opus (powerful)
$env:BEDROCK_MODEL_ID = "anthropic.claude-3-opus-20240229-v1:0"
pnpm dlx tsx scripts/test-bedrock-connection.ts
```

---

## 🌍 Test with Different Regions

```powershell
# US East (N. Virginia) - default
$env:AWS_REGION = "us-east-1"
pnpm dlx tsx scripts/test-bedrock-connection.ts

# US West (Oregon)
$env:AWS_REGION = "us-west-2"
pnpm dlx tsx scripts/test-bedrock-connection.ts

# EU (Frankfurt)
$env:AWS_REGION = "eu-central-1"
pnpm dlx tsx scripts/test-bedrock-connection.ts
```

---

## 🔧 Troubleshooting Commands

```powershell
# Reconfigure credentials
aws configure

# Clear cached credentials
Remove-Item -Path "$env:USERPROFILE\.aws\credentials" -Force
aws configure

# Check AWS CLI config
cat "$env:USERPROFILE\.aws\config"

# Check AWS credentials file
cat "$env:USERPROFILE\.aws\credentials"

# Refresh PowerShell PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Verify MCP config
cat .cursor\mcp.json

# Test uvx can run MCP server
uvx awslabs.amazon-bedrock-agentcore-mcp-server@latest --help
```

---

## 📊 AWS Console Links

```
# Bedrock Console
https://console.aws.amazon.com/bedrock/

# Model Access Page
https://console.aws.amazon.com/bedrock/home?#/modelaccess

# IAM Console
https://console.aws.amazon.com/iam/

# IAM Users Page
https://console.aws.amazon.com/iam/home?#/users

# CloudWatch (for logs)
https://console.aws.amazon.com/cloudwatch/

# CloudTrail (for audit)
https://console.aws.amazon.com/cloudtrail/
```

---

## 🐾 BossCat Status Commands

```powershell
# View current status
cat BEDROCK_INTEGRATION_STATUS.md

# View resume guide
cat BEDROCK_RESUME_WHEN_READY.md

# View gate checklist
cat BEDROCK_GATE_CHECKLIST.md

# View session summary
cat BEDROCK_SESSION_SUMMARY.md

# View all Bedrock docs
Get-ChildItem -Filter "BEDROCK_*.md"
```

---

## 📝 Documentation Files

```
Quick Reference:
  BEDROCK_QUICK_COMMANDS.md          ← This file

Essential Guides:
  BEDROCK_SETUP_QUICKSTART.md        ← 3-step quick setup
  BEDROCK_RESUME_WHEN_READY.md       ← Resume guide (start here!)

Status & Tracking:
  BEDROCK_INTEGRATION_STATUS.md      ← Current status
  BEDROCK_SESSION_SUMMARY.md         ← What we built today
  BEDROCK_GATE_CHECKLIST.md          ← Gate verification

Complete References:
  BEDROCK_COPY_PASTE_KIT.md          ← Copy-paste reference
  docs/BossCat/BEDROCK_INTEGRATION_GUIDE.md  ← Full guide (4K+ words)
  docs/BossCat/BEDROCK_FILES_MANIFEST.md     ← File inventory
```

---

## ⚡ One-Liner Shortcuts

```powershell
# Full test (all prerequisites → test → report)
pwsh -File scripts\setup-bedrock-prerequisites.ps1; pwsh -File scripts\test-bedrock-connection.ps1

# Quick test (assumes everything configured)
pnpm dlx tsx scripts/test-bedrock-connection.ts

# Check prerequisites only
pwsh -File scripts\setup-bedrock-prerequisites.ps1 -CheckOnly

# View test script
cat scripts\test-bedrock-connection.ts

# View MCP config
cat .cursor\mcp.json
```

---

🚀 **Quick Start:** When you have credentials, run `aws configure` → `aws sts get-caller-identity` → `pnpm dlx tsx scripts/test-bedrock-connection.ts`

📖 **Full Guide:** See `BEDROCK_RESUME_WHEN_READY.md` for detailed step-by-step instructions

