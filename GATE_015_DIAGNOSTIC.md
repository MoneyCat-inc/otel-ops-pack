# Gate #015 - Bedrock MCP Diagnostic Report

**Date:** 2025-10-24 11:35:00  
**Status:** Troubleshooting MCP connection

---

## ✅ **What's Working**

1. **MCP Configuration:** `.cursor/mcp.json` is valid
   - Server: `awslabs.amazon-bedrock-agentcore-mcp-server`
   - Command: `uvx`
   - Region: us-east-1
   - Status: `disabled: false`

2. **uvx Runtime:** Installed and functional
   - Version: 0.9.4
   - Can execute MCP server package

3. **AWS Credentials:** Valid
   - Account: 551346182830
   - Identity verified via `aws sts get-caller-identity`

---

## ❌ **What's Not Working**

1. **MCP Resources Not Available**
   - `list_mcp_resources` returns: "No MCP resources found"
   - Expected tools: `search_agentcore_docs`, `fetch_agentcore_doc`
   - This suggests MCP server isn't connected in Cursor

2. **Bedrock API Access**
   - AWS CLI bedrock commands failing
   - May be IAM permission issue or service not enabled

---

## 🔍 **Troubleshooting Steps**

### Step 1: Check Cursor MCP Server Status
**In Cursor IDE:**
1. Open Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
2. Search for "MCP"
3. Look for **"MCP: Show Server Status"** or similar
4. Check if `awslabs.amazon-bedrock-agentcore-mcp-server` shows as:
   - ✅ Connected (green)
   - ⚠️ Starting (yellow)
   - ❌ Error (red)

### Step 2: Check Cursor MCP Logs
**In Cursor:**
1. View → Output
2. Select "MCP Servers" from dropdown
3. Look for connection errors or AWS credential issues

### Step 3: Verify AWS Credentials in Environment
**Check if AWS credentials are accessible to Cursor:**
```powershell
# These should all show values
$env:AWS_ACCESS_KEY_ID
$env:AWS_SECRET_ACCESS_KEY
$env:AWS_SESSION_TOKEN  # (if using temporary credentials)
```

**Alternative:** Ensure `~/.aws/credentials` exists with valid profile

### Step 4: Test Bedrock Access Directly
```powershell
# Check if Bedrock is available in your account
aws bedrock list-foundation-models --region us-east-1 --query 'modelSummaries[?modelId==`anthropic.claude-3-sonnet-20240229-v1:0`]'

# If access denied, you may need to:
# 1. Enable Bedrock service in AWS Console
# 2. Request model access (Anthropic Claude 3 Sonnet)
# 3. Add IAM policy for bedrock:InvokeModel
```

### Step 5: Simplified MCP Config (if issues persist)
Try simpler command approach in `.cursor/mcp.json`:
```json
{
  "mcpServers": {
    "bedrock": {
      "command": "uvx",
      "args": ["awslabs.amazon-bedrock-agentcore-mcp-server"],
      "env": {
        "AWS_REGION": "us-east-1"
      }
    }
  }
}
```

---

## 🎯 **What I Can Test Right Now**

**Option 1: Test MCP Server Manually**
If you can confirm the MCP server shows as "Connected" in Cursor's MCP status, I can try calling the MCP tools directly.

**Option 2: Alternative Test via Direct Bedrock API**
I can create a test using AWS SDK directly (bypassing MCP) to verify Bedrock is accessible:
```powershell
pnpm add @aws-sdk/client-bedrock-runtime
npx tsx scripts/test-bedrock-direct.ts
```

**Option 3: Check Cursor's MCP Output**
You can share any error messages from Cursor's MCP logs and I'll diagnose.

---

## 🚀 **Recommended Next Step**

**Please check in Cursor:**
1. Open **Output** panel (View → Output)
2. Select **"MCP Servers"** from dropdown
3. Look for the `awslabs.amazon-bedrock-agentcore-mcp-server` entry
4. Share any error messages you see

**Common issues:**
- ❌ Python/uvx not finding AWS credentials
- ❌ Bedrock service not enabled in AWS account
- ❌ Model access not requested in Bedrock console
- ❌ IAM policy missing `bedrock:InvokeModel` permission
- ❌ MCP server crashed on startup (check logs)

---

**🐾 Standing by - please confirm what you see in Cursor's MCP status/logs.**

