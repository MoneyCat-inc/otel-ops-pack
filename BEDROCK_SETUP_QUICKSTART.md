# 🐾 BossCat - AWS Bedrock AgentCore MCP Integration

## ✅ Setup Complete!

Your Cursor IDE is now configured to connect with **Amazon Bedrock** via the official **AgentCore MCP server**.

**Based on:** [AWS AgentCore MCP Documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/mcp-install-server.html)

### Files Created
1. **`.cursor/mcp.json`** - MCP server configuration (uses `uvx` + official AWS package)
2. **`scripts/test-bedrock-connection.ts`** - TypeScript connectivity test
3. **`scripts/test-bedrock-connection.ps1`** - PowerShell test wrapper
4. **`docs/BossCat/BEDROCK_INTEGRATION_GUIDE.md`** - Complete integration guide
5. **`@aws-sdk/client-bedrock-runtime`** - ✅ Installed (v3.901.0)

---

## 📋 Prerequisites

### Python + uvx (required for MCP server)

The official AWS MCP server runs via `uvx` (Python-based tool).

**Check if installed:**
```bash
uvx --version
```

**If not installed:**
```bash
# Windows (via pip)
pip install uv

# Or via pipx
pipx install uv
```

**Note:** `uvx` is part of the `uv` package manager. Learn more: [astral.sh/uv](https://docs.astral.sh/uv/)

---

## 🚀 3-Step Activation

### Step 1: Configure AWS Credentials (if not done)

```bash
aws configure
```

Provide:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `us-east-1` (or your preferred region)
- Output format: `json`

**Verify:**
```bash
aws sts get-caller-identity
```

### Step 2: Restart Cursor IDE

**IMPORTANT:** Cursor only loads MCP servers on startup!

1. Close Cursor completely (check Task Manager on Windows)
2. Reopen Cursor
3. Wait 10-15 seconds for initialization

**Verify MCP loaded:**
- Open command palette (Ctrl+Shift+P)
- Search for "MCP"
- You should see: `search_agentcore_docs` and `fetch_agentcore_doc`

### Step 3: Run Connectivity Test

```powershell
# PowerShell (recommended)
pwsh -File scripts\test-bedrock-connection.ps1

# Or directly with TypeScript
npx tsx scripts/test-bedrock-connection.ts
```

**Expected output:**
```
🐾 BossCat OEM - Bedrock Connectivity Test
============================================================
🔍 [Examine] Testing Bedrock connection...
✅ [Success] Bedrock responded in ~1200ms
📝 Response: BEDROCK_CONNECTED

✅ [Report] Bedrock connectivity test PASSED
🎯 [Role] Ready for production deployment
```

---

## 📊 Configuration Details

### MCP Server (`.cursor/mcp.json`)
```json
{
  "mcpServers": {
    "awslabs.amazon-bedrock-agentcore-mcp-server": {
      "command": "uvx",
      "args": ["awslabs.amazon-bedrock-agentcore-mcp-server@latest"],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR",
        "AWS_REGION": "us-east-1"
      },
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

**Configuration:**
- **Command:** `uvx` (Python-based MCP server from AWS)
- **Package:** `awslabs.amazon-bedrock-agentcore-mcp-server@latest`
- **To change region:** Edit `AWS_REGION` in `.cursor/mcp.json` and restart Cursor

### Default Model
- **Claude 3 Haiku:** `anthropic.claude-3-haiku-20240307-v1:0`
- Fastest response, lowest cost
- Good for rapid observability analysis
- **Alternative:** Claude 3 Sonnet (`anthropic.claude-3-sonnet-20240229-v1:0`) for deeper analysis

---

## 🔧 Troubleshooting

### ❌ MCP Tools Not Appearing
- Verify `.cursor/mcp.json` exists and uses `uvx` command
- Check `uvx --version` works (install via `pip install uv` if missing)
- **Completely** close Cursor (check Task Manager)
- Reopen and wait 15 seconds
- Check Cursor logs for MCP errors

### ❌ AWS Credentials Error
```bash
# Reconfigure
aws configure

# Verify
aws sts get-caller-identity
```

### ❌ Model Access Denied
1. Go to AWS Console → Bedrock
2. Navigate to "Model access"
3. Request access to "Anthropic Claude" models
4. Wait 2-5 minutes for approval

### ❌ Insufficient Permissions

Your IAM user/role needs:
```json
{
  "Effect": "Allow",
  "Action": [
    "bedrock:InvokeModel",
    "bedrock:InvokeModelWithResponseStream"
  ],
  "Resource": "*"
}
```

---

## 💡 Usage Examples

### Quick Log Analysis
```typescript
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';

const client = new BedrockRuntimeClient({ region: 'us-east-1' });

const payload = {
  anthropic_version: 'bedrock-2023-05-31',
  max_tokens: 300,
  messages: [{
    role: 'user',
    content: 'Analyze this error: TimeoutException in payment service'
  }]
};

const command = new InvokeModelCommand({
  modelId: 'anthropic.claude-3-haiku-20240307-v1:0',
  contentType: 'application/json',
  accept: 'application/json',
  body: Buffer.from(JSON.stringify(payload))
});

const response = await client.send(command);
const result = JSON.parse(new TextDecoder().decode(response.body));
console.log(result.content[0].text);
```

---

## 📚 Full Documentation

See **`docs/BossCat/BEDROCK_INTEGRATION_GUIDE.md`** for:
- Detailed IAM setup
- All available models
- Streaming examples
- Security best practices
- Integration with OTel pipeline

---

## 🎯 Next Steps

1. ✅ AWS credentials configured → Run connectivity test
2. ✅ Test passed → Integrate with observability pipeline
3. ✅ MCP server active → Use Bedrock tools in Cursor

**Test Command:**
```powershell
pwsh -File scripts\test-bedrock-connection.ps1
```

---

🐾 **BossCat OEM - Bedrock integration ready for deployment!**

*For full documentation, see: `docs/BossCat/BEDROCK_INTEGRATION_GUIDE.md`*

