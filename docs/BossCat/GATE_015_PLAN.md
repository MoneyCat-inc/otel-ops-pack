# Gate #015 - Cursor Co-Author Loop (Bedrock MCP)

**Authority:** BossCat OEM  
**Executor:** Cursor{Implementer}  
**Date:** 2025-10-24  
**Status:** 🟢 **OPEN** - Executing

---

## 🎯 Objective

Enable **in-editor co-author cycle** in Cursor that can *propose → load → score → revise* ProjectM `.milk` presets via MCP tool wired to Bedrock.

---

## ✅ Acceptance Criteria (GREEN)

1. **✅ MCP Online:** Bedrock connectivity test passes
2. **✅ Co-Author Loop:** Produces ≥3 unique presets
3. **✅ Preset Switching:** ≤1.5s (already achieved)
4. **✅ Capture & Metrics:** /snap.jpg + /pm/metrics per iteration
5. **✅ Evidence:** JSONL with blackout, motion, critique
6. **✅ Budgets:** ≤10 files, ≤200 LOC per job (2 jobs max)
7. **✅ Two-Agent Safety:** Author proposes, Critic gates, no auto-merge

---

## 📦 Job Breakdown

### Job-1: Wire MCP + Smoke Test (≤5 files, ≤180 LOC)
- `.cursor/mcp.json` - MCP server configuration
- `package.json` - Add @aws-sdk/client-bedrock-runtime
- `scripts/test-bedrock-connection.ts` - Connectivity smoke test
- Verify MCP tools in Cursor palette

### Job-2: Co-Author Loop (≤5 files, ≤200 LOC)
- `scripts/author-codex.ts` - Bedrock LLM integration
- Update `scripts/author-loop.ps1` - Add LLM generation + critique
- `docs/BossCat/GATE_015_PLAN.md` - This document
- Run 3 presets × 2 iterations with evidence

**Total Files:** ≤10  
**Total LOC:** ≤380 (within budget)

---

## 🎨 Co-Author Architecture

### Author (LLM - Bedrock Claude)
- Proposes .milk preset text
- Receives critique from previous iteration
- Refines based on blackout/motion feedback
- Outputs valid INI format

### Critic (Scorebot + Rules)
- Measures blackout % (target ≤40%, stretch ≤20%)
- Calculates motion Δluma (target >0)
- Validates preset load time (target ≤1.5s)
- Generates 4-line critique for Author

### Loop Flow
```
1. Author generates .milk text (via Bedrock)
2. Load preset → pm-engine /preset
3. Capture → /snap.jpg
4. Score → /pm/metrics
5. Critic evaluates → PASS/WARN/FAIL
6. Feed critique back to Author
7. Repeat for next iteration
```

---

## 🛡️ Guardrails (ECRR)

- **Single-writer, lane-locked**
- **≤10 files, ≤200 LOC per job**
- **Two-agent supervision** (Author ↔ Critic)
- **No auto-merge** - all proposals logged
- **ECRR discipline** - Examine → Clean → Report → Role
- **Kill-switch respected**

---

## 🔧 Technical Components

### MCP Configuration
```json
{
  "mcpServers": {
    "bedrock-agentcore-mcp-server": {
      "command": "uvx",
      "args": ["awslabs.amazon-bedrock-agentcore-mcp-server@latest"],
      "env": { "FASTMCP_LOG_LEVEL": "ERROR", "AWS_REGION": "us-east-1" }
    }
  }
}
```

### Author Prompt Template
```
System: You write ProjectM Milkdrop (.milk) presets. Output ONLY valid .milk INI.
User brief:
- Mood: {crystalline nebula}
- Palette: {teal/magenta}
- Motion: prefer visible motion without audio
Constraints:
- Avoid full-black frames
- Maintain motion via per_frame zoom/rot
- Keep ≤80 lines
```

### Critic Rubric
- Blackout ≤20% (WARN ≤40%)
- Motion Δluma >0 (WARN 0-0.02)
- Switch time ≤1.5s
- 4-line critique on FAIL

---

## 📊 Success Metrics

| Metric | Target | Gate |
|--------|--------|------|
| MCP Connectivity | PASS | Job-1 |
| Presets Generated | ≥3 | Job-2 |
| Iterations | 6 (3×2) | Job-2 |
| Blackout | ≤40% (1+ preset) | Job-2 |
| Motion | >0 (1+ preset) | Job-2 |
| Evidence JSONL | Complete | Job-2 |
| Budget | ≤10 files, ≤380 LOC | Both |

---

## 🐾 ECRR Compliance

**Examine:** MCP config, AWS credentials, pm-engine health  
**Clean:** No drift, rollback ready, evidence archived  
**Report:** JSONL evidence, BOSSCAT_LOG entries, status doc  
**Role:** Cursor{Implementer} executes, BossCat OEM approves

---

**Status:** APPROVED FOR EXECUTION  
**Next:** Job-1 implementation

