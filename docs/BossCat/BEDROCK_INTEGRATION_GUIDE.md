# 🐾 BossCat OEM - AWS Bedrock Integration Guide

**MoneyCat Inc · Resonai [OTel] · Bedrock AgentCore Setup**  
**Issued by:** BossCat OEM (Executive Overseer Manager)

---

## 🎯 Purpose

Connect **Cursor IDE** to **Amazon Bedrock** via the **AgentCore MCP (Model Context Protocol)** server, enabling AI-powered observability insights directly in the development environment.

---

## 📋 Prerequisites

### 1. AWS Account & Credentials

You need:
- AWS account with Bedrock access enabled
- IAM permissions: `bedrock:InvokeModel`, `bedrock:InvokeModelWithResponseStream`
- AWS CLI installed and configured

### 2. AWS CLI Setup

**Install AWS CLI:**
- **Windows:** Download from [aws.amazon.com/cli](https://aws.amazon.com/cli/)
- **macOS:** `brew install awscli`
- **Linux:** `curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install`

**Configure credentials:**
```bash
aws configure
```

Provide:
- AWS Access Key ID
- AWS Secret Access Key  
- Default region (e.g., `us-east-1`)
- Output format: `json`

**Verify:**
```bash
aws sts get-caller-identity
```

### 3. Required IAM Policy

Your IAM user/role needs this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
        "bedrock:ListFoundationModels"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 🔧 Installation Steps

### Step 1: Configure Cursor MCP

The `.cursor/mcp.json` file has been created at the repository root:

```json
{
  "mcpServers": {
    "bedrock-agentcore": {
      "command": "npx",
      "args": [
        "-y",
        "@aws/bedrock-agentcore-mcp"
      ],
      "env": {
        "AWS_REGION": "us-east-1"
      }
    }
  }
}
```

**To change region:** Edit `AWS_REGION` in `.cursor/mcp.json`

### Step 2: Restart Cursor IDE

**Important:** Cursor only loads MCP servers on startup.

1. Close Cursor completely (check task manager on Windows)
2. Reopen Cursor
3. Wait ~10 seconds for MCP server initialization

### Step 3: Verify MCP Server

In Cursor's command palette (Ctrl+Shift+P / Cmd+Shift+P):
1. Search for "MCP"
2. You should see new tools:
   - `search_agentcore_docs`
   - `fetch_agentcore_doc`

If these tools appear, the MCP server is active! ✅

### Step 4: Install AWS SDK

```bash
# Install Bedrock Runtime SDK
pnpm add @aws-sdk/client-bedrock-runtime

# Or using npm
npm install @aws-sdk/client-bedrock-runtime
```

### Step 5: Run Connectivity Test

```powershell
# PowerShell (recommended for Windows)
pwsh -File scripts\test-bedrock-connection.ps1

# Or run TypeScript directly
npx tsx scripts/test-bedrock-connection.ts
```

**Expected output:**
```
🐾 BossCat OEM - Bedrock Connectivity Test
============================================================
🔍 [Examine] Testing Bedrock connection to anthropic.claude-3-sonnet-20240229-v1:0...
✅ [Success] Bedrock responded in 1247ms
📝 Response: BEDROCK_CONNECTED

🔍 [Examine] Testing Bedrock streaming connection...
📡 [Streaming] Receiving chunks...
1... 2... 3... 4... 5...
✅ [Success] Streaming test complete

# ECRR Report: Bedrock Connectivity Test
**Generated:** 2025-10-07T...
**Agent:** Cursor Implementer (Investigator)

## 🔍 Examine
- **AWS Region:** us-east-1
- **Model ID:** anthropic.claude-3-sonnet-20240229-v1:0

## 🧹 Clean
- Status: ✅ PASS
- Latency: 1247ms

## 📊 Report
- Bedrock connection established successfully
- Integration ready for production use

## 🎭 Role
- **Next Action:** Deploy to production
- **Agent Assignment:** QA Scribe → Documentation
```

---

## 🚀 Usage Examples

### Basic Model Invocation (TypeScript)

```typescript
import {
  BedrockRuntimeClient,
  InvokeModelCommand,
} from '@aws-sdk/client-bedrock-runtime';

async function analyzeLogAnomaly(logMessage: string) {
  const client = new BedrockRuntimeClient({ region: 'us-east-1' });

  const payload = {
    anthropic_version: 'bedrock-2023-05-31',
    max_tokens: 500,
    messages: [
      {
        role: 'user',
        content: `Analyze this OpenTelemetry log for anomalies: ${logMessage}`,
      },
    ],
  };

  const command = new InvokeModelCommand({
    modelId: 'anthropic.claude-3-sonnet-20240229-v1:0',
    contentType: 'application/json',
    accept: 'application/json',
    body: JSON.stringify(payload),
  });

  const response = await client.send(command);
  const result = JSON.parse(new TextDecoder().decode(response.body));
  
  return result.content[0].text;
}
```

### Streaming Invocation (TypeScript)

```typescript
import {
  BedrockRuntimeClient,
  InvokeModelWithResponseStreamCommand,
} from '@aws-sdk/client-bedrock-runtime';

async function streamTraceAnalysis(traceData: string) {
  const client = new BedrockRuntimeClient({ region: 'us-east-1' });

  const payload = {
    anthropic_version: 'bedrock-2023-05-31',
    max_tokens: 1000,
    messages: [
      {
        role: 'user',
        content: `Analyze this distributed trace and identify bottlenecks: ${traceData}`,
      },
    ],
  };

  const command = new InvokeModelWithResponseStreamCommand({
    modelId: 'anthropic.claude-3-sonnet-20240229-v1:0',
    contentType: 'application/json',
    accept: 'application/json',
    body: JSON.stringify(payload),
  });

  const response = await client.send(command);

  if (response.body) {
    for await (const event of response.body) {
      if (event.chunk) {
        const chunk = JSON.parse(new TextDecoder().decode(event.chunk.bytes));
        if (chunk.type === 'content_block_delta') {
          process.stdout.write(chunk.delta.text);
        }
      }
    }
  }
}
```

---

## 🔍 Available Bedrock Models

### Claude Models (Anthropic)
- `anthropic.claude-3-opus-20240229-v1:0` - Most capable, highest cost
- `anthropic.claude-3-sonnet-20240229-v1:0` - Balanced performance ⭐ **Recommended**
- `anthropic.claude-3-haiku-20240307-v1:0` - Fastest, lowest cost

### Other Models
- `amazon.titan-text-express-v1` - AWS Titan Text
- `ai21.j2-ultra-v1` - Jurassic-2 Ultra
- `meta.llama2-70b-chat-v1` - Llama 2 70B

**To list all available models:**
```bash
aws bedrock list-foundation-models --region us-east-1
```

---

## 🛠️ Troubleshooting

### ❌ MCP Server Not Loading

**Symptom:** Tools like `search_agentcore_docs` don't appear

**Fix:**
1. Verify `.cursor/mcp.json` exists and is valid JSON
2. Completely close Cursor (check Task Manager on Windows)
3. Reopen Cursor and wait 10-15 seconds
4. Check Cursor's output panel for MCP errors

### ❌ AWS Credentials Error

**Symptom:** `UnrecognizedClientException` or `The security token is invalid`

**Fix:**
```bash
# Reconfigure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity

# Check environment variables (should be empty or match aws configure)
echo $AWS_ACCESS_KEY_ID
```

### ❌ Model Not Available

**Symptom:** `ValidationException: The provided model identifier is invalid`

**Fix:**
1. Check if model is available in your region:
   ```bash
   aws bedrock list-foundation-models --region us-east-1 | grep claude-3-sonnet
   ```
2. Request model access in AWS Console:
   - Go to AWS Bedrock console
   - Navigate to "Model access"
   - Request access to Claude models

### ❌ Insufficient Permissions

**Symptom:** `AccessDeniedException`

**Fix:**
- Add the IAM policy shown in Prerequisites section
- Wait 5-10 minutes for IAM changes to propagate
- Try `aws sts get-caller-identity` to verify role/user

### ❌ Network/Timeout Issues

**Symptom:** `TimeoutError` or `NetworkingError`

**Fix:**
- Check internet connectivity
- Verify no corporate proxy blocking AWS endpoints
- Try different AWS region: edit `AWS_REGION` in `.cursor/mcp.json`
- Increase timeout in SDK client:
  ```typescript
  const client = new BedrockRuntimeClient({
    region: 'us-east-1',
    requestHandler: {
      requestTimeout: 60000, // 60 seconds
    },
  });
  ```

---

## 📊 Integration with Observability Pipeline

### Use Case: Automated Log Analysis

```typescript
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';

// Analyze high-priority logs from OpenTelemetry
async function analyzeOtelLogs(logs: any[]) {
  const client = new BedrockRuntimeClient({ region: 'us-east-1' });
  
  const highPriorityLogs = logs.filter(log => 
    log.attributes.severity_text === 'ERROR' || 
    log.attributes.severity_text === 'FATAL'
  );

  const analysis = await Promise.all(
    highPriorityLogs.map(async (log) => {
      const payload = {
        anthropic_version: 'bedrock-2023-05-31',
        max_tokens: 300,
        messages: [{
          role: 'user',
          content: `Analyze this error log and suggest remediation:\n${JSON.stringify(log)}`,
        }],
      };

      const command = new InvokeModelCommand({
        modelId: 'anthropic.claude-3-sonnet-20240229-v1:0',
        contentType: 'application/json',
        body: JSON.stringify(payload),
      });

      const response = await client.send(command);
      const result = JSON.parse(new TextDecoder().decode(response.body));
      
      return {
        logId: log.attributes.log_id,
        analysis: result.content[0].text,
      };
    })
  );

  return analysis;
}
```

### Use Case: Trace Bottleneck Detection

```typescript
// Analyze slow traces from SigNoz
async function identifyBottlenecks(traceId: string, spans: any[]) {
  const client = new BedrockRuntimeClient({ region: 'us-east-1' });
  
  const slowSpans = spans
    .filter(span => span.duration_nano > 1000000000) // > 1 second
    .map(span => ({
      name: span.name,
      duration: span.duration_nano / 1000000, // ms
      attributes: span.attributes,
    }));

  const payload = {
    anthropic_version: 'bedrock-2023-05-31',
    max_tokens: 500,
    messages: [{
      role: 'user',
      content: `These spans are slow in trace ${traceId}. Identify root causes:\n${JSON.stringify(slowSpans, null, 2)}`,
    }],
  };

  const command = new InvokeModelCommand({
    modelId: 'anthropic.claude-3-sonnet-20240229-v1:0',
    contentType: 'application/json',
    body: JSON.stringify(payload),
  });

  const response = await client.send(command);
  const result = JSON.parse(new TextDecoder().decode(response.body));
  
  return result.content[0].text;
}
```

---

## 🔐 Security Best Practices

1. **Never commit AWS credentials to Git**
   - Use `aws configure` or environment variables
   - Credentials stored in `~/.aws/credentials` (not in repo)

2. **Use IAM roles in production**
   - Attach Bedrock policies to EC2/ECS/Lambda roles
   - Avoid long-lived access keys

3. **Enable CloudTrail logging**
   - Monitor Bedrock API usage
   - Detect anomalous invocations

4. **Implement cost controls**
   - Set AWS Budgets for Bedrock usage
   - Monitor token consumption via CloudWatch

5. **Rotate credentials regularly**
   - See `docs/BossCat/CREDENTIAL_ROTATION_CALENDAR.md`

---

## 📚 Additional Resources

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Cursor MCP Documentation](https://cursor.sh/docs/mcp)
- [AgentCore MCP NPM Package](https://www.npmjs.com/package/@aws/bedrock-agentcore-mcp)
- [Claude Model Documentation](https://docs.anthropic.com/claude/docs)

---

## 🐾 BossCat Compliance

**ECRR Framework Applied:**
- ✅ **Examine:** Connectivity test validates credentials and network
- ✅ **Clean:** Automated setup script removes manual configuration drift
- ✅ **Report:** Test generates ECRR-compliant reports in `artifacts/`
- ✅ **Role:** Clear agent assignments for troubleshooting

**Next Steps:**
1. Run connectivity test: `pwsh scripts\test-bedrock-connection.ps1`
2. If successful → Deploy to production observability pipeline
3. If failed → Gap-Closer agent resolves credential/network issues

---

🐾 **End of Bedrock Integration Guide.**

*This guide is maintained by BossCat OEM and follows the Cat Nap Control Room aesthetic.*

