# 🐾 BossCat Gate Checklist - Bedrock Integration

**Integration:** Cursor ⇄ AWS Bedrock (AgentCore MCP)  
**Gate Status:** 🚪 Ready for verification  
**Tag:** `@cat ready-for-gate` ✅

---

## 📋 Gate Checklist (BossCat-style)

### Prerequisites
- [ ] **AWS credentials configured** - `aws sts get-caller-identity` returns OK
- [ ] **Model access enabled** - Claude 3 Haiku/Sonnet enabled in Bedrock console
- [ ] **IAM permissions** - `bedrock:InvokeModel`, `bedrock:InvokeModelWithResponseStream` attached
- [ ] **uvx installed** - `uvx --version` returns version (via `pip install uv`)
- [ ] **AWS SDK installed** - `@aws-sdk/client-bedrock-runtime` in package.json

### Configuration
- [ ] **`.cursor/mcp.json`** present, matches official AWS spec, Cursor restarted
- [ ] **MCP tools visible** - Command palette shows `search_agentcore_docs`, `fetch_agentcore_doc`
- [ ] **Region configured** - `AWS_REGION` set in `.cursor/mcp.json` (default: us-east-1)

### Testing
- [ ] **TypeScript smoke test passes** - Basic + streaming invocation working
  ```bash
  pnpm dlx tsx scripts/test-bedrock-connection.ts
  ```
- [ ] **PowerShell wrapper passes** - Wrapper validates and runs test
  ```powershell
  pwsh -File scripts\test-bedrock-connection.ps1
  ```
- [ ] **Expected output:**
  - `[Basic]` JSON containing **BEDROCK_CONNECTED**
  - One line streaming output containing **STREAMING**

### Security
- [ ] **No secrets in repo** - Credentials in env/CI, not committed
- [ ] **IAM least privilege** - Only required Bedrock permissions granted
- [ ] **(Optional) Guardrails configured** - For production use (can add later)
- [ ] **(Optional) Knowledge Base** - For RAG use cases (can add later)

### Documentation
- [ ] **Setup guide** - `BEDROCK_SETUP_QUICKSTART.md` complete
- [ ] **Integration guide** - `docs/BossCat/BEDROCK_INTEGRATION_GUIDE.md` comprehensive
- [ ] **Gate checklist** - This file, ready for PR review

---

## 🚀 Quick Verification Commands

```bash
# 1. Prerequisites check
uvx --version
aws --version
aws sts get-caller-identity

# 2. Model access check (in AWS Console)
# Bedrock → Model access → Ensure "Anthropic Claude" models enabled

# 3. Run smoke test
pnpm dlx tsx scripts/test-bedrock-connection.ts

# 4. Run PowerShell wrapper
pwsh -File scripts\test-bedrock-connection.ps1

# 5. Verify MCP in Cursor
# Restart Cursor → Command Palette → Search "MCP" → See tools
```

---

## ✅ Expected Test Output

### Basic Invocation
```json
[Basic] {
  "id": "msg_...",
  "type": "message",
  "role": "assistant",
  "content": [
    {
      "type": "text",
      "text": "BEDROCK_CONNECTED"
    }
  ],
  "model": "claude-3-haiku-20240307",
  "stop_reason": "end_turn",
  "usage": {
    "input_tokens": 15,
    "output_tokens": 8
  }
}
```

### Streaming Invocation
```
STREAMING
```

---

## 🔧 Troubleshooting Quick Fixes

### ❌ MCP tools not appearing
```bash
# 1. Verify uvx installed
uvx --version  # Should show: uvx 0.8.24 or later

# 2. Verify config
cat .cursor/mcp.json  # Should match official spec

# 3. Restart Cursor completely
# Close all windows, check Task Manager, reopen
```

### ❌ AWS credentials error
```bash
# Reconfigure
aws configure

# Verify
aws sts get-caller-identity
```

### ❌ Model access denied
```
# In AWS Console:
1. Bedrock → Model access
2. Click "Modify model access" or "Enable specific models"
3. Check "Anthropic → Claude 3" models
4. Save and wait 2-5 minutes
```

### ❌ Streaming not working
- Model must support streaming (`responseStreamingSupported: true`)
- Claude 3 Haiku/Sonnet/Opus all support streaming
- Check via: `aws bedrock get-foundation-model --model-identifier anthropic.claude-3-haiku-20240307-v1:0`

---

## 📦 Files Included in PR

### Core Files
- `.cursor/mcp.json` - MCP server configuration (official AWS spec)
- `scripts/test-bedrock-connection.ts` - Minimal smoke test (TypeScript)
- `scripts/test-bedrock-connection.ps1` - PowerShell wrapper

### Documentation
- `BEDROCK_SETUP_QUICKSTART.md` - Quick 3-step guide
- `BEDROCK_GATE_CHECKLIST.md` - This file (gate verification)
- `docs/BossCat/BEDROCK_INTEGRATION_GUIDE.md` - Comprehensive guide
- `BEDROCK_INTEGRATION_STATUS.md` - Current status report

### Support Scripts
- `scripts/setup-bedrock-prerequisites.ps1` - Auto-installer for prerequisites

---

## 🎯 Gate Approval Criteria

### ✅ Must Pass
1. All checklist items above marked complete
2. TypeScript smoke test exits with code 0
3. Both basic and streaming invocations working
4. MCP tools visible in Cursor after restart
5. No secrets committed to repository

### 🟡 Nice to Have (Optional)
- Guardrails configuration (for production safety)
- Knowledge Base integration (for RAG)
- Next.js streaming route example (`/api/bedrock/stream`)
- Additional model tests (Sonnet, Opus)

---

## 🚪 Gate Status

**Current:** 🟡 **READY FOR VERIFICATION**

**Next Steps:**
1. Install AWS CLI (if missing): `winget install Amazon.AWSCLI`
2. Configure credentials: `aws configure`
3. Enable model access in Bedrock console
4. Run smoke test: `pnpm dlx tsx scripts/test-bedrock-connection.ts`
5. Mark all checklist items complete
6. Submit PR with tag: `@cat ready-for-gate` ✅

**Gate Owner:** BossCat OEM  
**Reviewer:** Cursor Implementer → QA Scribe  
**Approval:** Auto-approve on green smoke test

---

## 🐾 BossCat ECRR Summary

### 🔍 Examine
- ✅ Official AWS AgentCore MCP server specified
- ✅ Minimal, tight implementation (copy-paste ready)
- ✅ All prerequisites documented

### 🧹 Clean
- ✅ No unnecessary code or complexity
- ✅ Streamlined test scripts
- ✅ Clean separation: config, test, docs

### 📊 Report
- ✅ This gate checklist
- ✅ Quick verification commands
- ✅ Expected outputs documented

### 🎭 Role
- **Current:** User → Complete AWS setup
- **Next:** QA Scribe → Verify smoke test passes
- **Final:** BossCat OEM → Gate approval

---

🚪 **Gate ready for verification after AWS credentials configured!**

*Tag PR with: `@cat ready-for-gate` when all items checked* ✅

