# 🐾 Cursor ⇄ Bedrock Copy-Paste Kit

**Status:** ✅ Complete - Ready to use  
**Approach:** Official AWS AgentCore MCP + TypeScript  
**Style:** Minimal, tight, production-ready

---

## 📦 What's Included

All files follow the **tight, copy-paste kit** pattern - minimal code, maximum clarity.

### ✅ Core Files (Ready)

| File | Purpose | Lines | Status |
|------|---------|-------|--------|
| `.cursor/mcp.json` | MCP server config | 15 | ✅ Created |
| `scripts/test-bedrock-connection.ts` | Smoke test (TS) | 62 | ✅ Created |
| `scripts/test-bedrock-connection.ps1` | Test wrapper (PS) | 17 | ✅ Created |
| `BEDROCK_GATE_CHECKLIST.md` | Gate verification | - | ✅ Created |

**Total code:** ~100 lines (minimal, focused)

---

## 🚀 Quick Start (3 Steps)

### 1️⃣ Prerequisites (One-time setup)

```bash
# Install uv (provides uvx for MCP server)
python -m pip install --upgrade uv
uvx --version  # Verify: uvx 0.8.24

# Install AWS CLI (Windows)
winget install Amazon.AWSCLI

# Configure credentials
aws configure
aws sts get-caller-identity  # Verify

# Install SDK
pnpm add @aws-sdk/client-bedrock-runtime
```

**Enable model in AWS Console:**
- Bedrock → Model access → Enable "Anthropic Claude 3" models
- Wait 2-5 minutes for approval

**IAM permissions required:**
```json
{
  "Effect": "Allow",
  "Action": [
    "bedrock:InvokeModel",
    "bedrock:InvokeModelWithResponseStream",
    "bedrock:ListFoundationModels"
  ],
  "Resource": "*"
}
```

---

### 2️⃣ Configure Cursor MCP

**File:** `.cursor/mcp.json` (already created ✅)

```json
{
  "mcpServers": {
    "awslabs.amazon-bedrock-agentcore-mcp-server": {
      "command": "uvx",
      "args": ["awslabs.amazon-bedrock-agentcore-mcp-server@latest"],
      "env": {
        "AWS_REGION": "us-east-1",
        "FASTMCP_LOG_LEVEL": "ERROR"
      },
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

**After saving:** Fully restart Cursor (only loads MCP servers at startup)

---

### 3️⃣ Test Connection

**TypeScript test (direct):**
```bash
pnpm dlx tsx scripts/test-bedrock-connection.ts
```

**PowerShell wrapper (recommended):**
```powershell
pwsh -File scripts\test-bedrock-connection.ps1
```

**Expected output:**
```
Region: us-east-1 | Model: anthropic.claude-3-haiku-20240307-v1:0
[Basic] {
  "content": [{ "text": "BEDROCK_CONNECTED" }],
  ...
}
STREAMING
```

---

## 📄 File Contents (Copy-Paste Ready)

### `.cursor/mcp.json`
```json
{
  "mcpServers": {
    "awslabs.amazon-bedrock-agentcore-mcp-server": {
      "command": "uvx",
      "args": ["awslabs.amazon-bedrock-agentcore-mcp-server@latest"],
      "env": {
        "AWS_REGION": "us-east-1",
        "FASTMCP_LOG_LEVEL": "ERROR"
      },
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

---

### `scripts/test-bedrock-connection.ts`
```typescript
import {
  BedrockRuntimeClient,
  InvokeModelCommand,
  InvokeModelWithResponseStreamCommand,
  ResponseStream
} from "@aws-sdk/client-bedrock-runtime";

const region = process.env.AWS_REGION ?? "us-east-1";
const modelId =
  process.env.BEDROCK_MODEL_ID ??
  "anthropic.claude-3-haiku-20240307-v1:0"; // ensure you enabled this model in Bedrock

const client = new BedrockRuntimeClient({ region });
const td = new TextDecoder();

async function basic() {
  const body = {
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: 64,
    messages: [{ role: "user", content: "Reply with: BEDROCK_CONNECTED" }]
  };

  const res = await client.send(
    new InvokeModelCommand({
      modelId,
      contentType: "application/json",
      accept: "application/json",
      body: Buffer.from(JSON.stringify(body))
    })
  );

  const json = JSON.parse(td.decode(res.body as Uint8Array));
  console.log("[Basic]", JSON.stringify(json, null, 2));
}

async function streaming() {
  const body = {
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: 64,
    messages: [{ role: "user", content: "Stream the word STREAMING." }]
  };

  const res = await client.send(
    new InvokeModelWithResponseStreamCommand({
      modelId,
      contentType: "application/json",
      accept: "application/json",
      body: Buffer.from(JSON.stringify(body))
    })
  );

  for await (const part of res.body as AsyncIterable<ResponseStream>) {
    if ("chunk" in part && part.chunk?.bytes) process.stdout.write(td.decode(part.chunk.bytes));
  }
  process.stdout.write("\n");
}

(async () => {
  console.log(`Region: ${region} | Model: ${modelId}`);
  await basic();
  await streaming();
})();
```

---

### `scripts/test-bedrock-connection.ps1`
```powershell
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
```

---

## 🔍 Verification Checklist

After setup, verify:

- [ ] `uvx --version` returns version number
- [ ] `aws sts get-caller-identity` returns your ARN
- [ ] Model access enabled (Bedrock console → Model access)
- [ ] `.cursor/mcp.json` created and Cursor restarted
- [ ] MCP tools visible: Command Palette → "MCP" → see `search_agentcore_docs`
- [ ] Smoke test passes: `pnpm dlx tsx scripts/test-bedrock-connection.ts`
- [ ] Both basic and streaming outputs appear

---

## 💡 Usage Examples

### Basic Invocation (in your code)
```typescript
import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";

const client = new BedrockRuntimeClient({ region: "us-east-1" });
const res = await client.send(new InvokeModelCommand({
  modelId: "anthropic.claude-3-haiku-20240307-v1:0",
  contentType: "application/json",
  body: Buffer.from(JSON.stringify({
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: 300,
    messages: [{ role: "user", content: "Analyze this OTel trace..." }]
  }))
}));

const result = JSON.parse(new TextDecoder().decode(res.body));
console.log(result.content[0].text);
```

### Streaming Invocation
```typescript
import { BedrockRuntimeClient, InvokeModelWithResponseStreamCommand } from "@aws-sdk/client-bedrock-runtime";

const client = new BedrockRuntimeClient({ region: "us-east-1" });
const res = await client.send(new InvokeModelWithResponseStreamCommand({
  modelId: "anthropic.claude-3-haiku-20240307-v1:0",
  contentType: "application/json",
  body: Buffer.from(JSON.stringify({
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: 1000,
    messages: [{ role: "user", content: "Explain this error..." }]
  }))
}));

const td = new TextDecoder();
for await (const chunk of res.body) {
  if ("chunk" in chunk && chunk.chunk?.bytes) {
    process.stdout.write(td.decode(chunk.chunk.bytes));
  }
}
```

---

## 🚀 Next Steps (Optional Enhancements)

### Add Guardrails (Production safety)
```typescript
// Coming soon: Guardrails configuration example
// Prevents harmful outputs, enforces content policies
```

### Add Knowledge Base (RAG)
```typescript
// Coming soon: Knowledge Base integration
// Query your docs before sending to model
```

### Next.js Streaming Route
```typescript
// Coming soon: `/api/bedrock/stream` example
// Server-side streaming for web apps
```

---

## 🔧 Troubleshooting Quick Fixes

| Issue | Fix |
|-------|-----|
| **MCP tools missing** | `uvx --version` → Install: `pip install uv` → Restart Cursor completely |
| **AWS creds error** | `aws configure` → `aws sts get-caller-identity` |
| **Model access denied** | AWS Console → Bedrock → Model access → Enable Claude 3 |
| **Streaming fails** | Check model supports streaming: `aws bedrock get-foundation-model --model-identifier <id>` |

---

## 📚 References

- **MCP Setup:** https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/mcp-install-server.html
- **InvokeModel API:** https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_InvokeModel.html
- **Streaming API:** https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_InvokeModelWithResponseStream.html
- **AWS SDK (JS):** https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/bedrock-runtime/

---

## 🐾 BossCat Gate Status

**Integration:** ✅ Complete  
**Code:** ✅ Minimal & tight (100 lines total)  
**Tests:** ✅ Smoke test ready  
**Docs:** ✅ Copy-paste ready  
**Gate:** 🚪 Ready for `@cat ready-for-gate` ✅

---

🎉 **Copy-paste kit complete! Wire Cursor ⇄ Bedrock in 3 steps.**

*For gate verification checklist, see: `BEDROCK_GATE_CHECKLIST.md`*

