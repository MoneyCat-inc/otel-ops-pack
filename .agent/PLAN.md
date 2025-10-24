# Gate #015 Execution Plan

**Objective:** Cursor Co-Author Loop via Bedrock MCP  
**Authority:** BossCat OEM  
**Executor:** Cursor{Implementer}  
**Budgets:** ≤10 files, ≤200 LOC/job, 2 jobs max

## Job-1: MCP Infrastructure
- Verify .cursor/mcp.json (bedrock-agentcore)
- Test Bedrock connectivity (sync + streaming)
- Generate evidence artifacts
**Files:** ≤5, **LOC:** ≤180

## Job-2: Co-Author Integration
- Add MCP call to author-loop.ps1
- Request preset suggestions from Bedrock
- Apply, snapshot, score iterations
- Generate JSONL evidence
**Files:** ≤5, **LOC:** ≤200

## Success: GREEN
- MCP tools visible in Cursor
- Bedrock test PASS
- 2+ MCP-driven iterations complete
- Evidence JSONL generated


