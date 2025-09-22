# 🚀 Cursor Setup Guide — Multi-Project Workflow

This guide provides tailored Cursor setup prompts for different project contexts within the Resonai ecosystem.

## 📁 Available Setup Prompts

### 1. **General Workflow** (`CURSOR_SETUP_PROMPT.md`)
- **Use for**: Any Resonai/OTel project
- **Context**: Generic workflow with both OTel and Resonai contexts
- **Best for**: New projects or when context is unclear

### 2. **Resonai Voice Practice** (`CURSOR_SETUP_PROMPT_RESONAI.md`)
- **Use for**: Resonai voice practice application (`c:\Projects\resonai`)
- **Context**: M1 Warmup, M2 Prosody, Instant Practice features
- **Focus**: Voice practice flows, analytics integration, OTLP wiring

### 3. **OTel Observability** (`CURSOR_SETUP_PROMPT_OTEL.md`)
- **Use for**: OTel observability pipeline (`c:\otel`)
- **Context**: Windows Collector + SigNoz stack
- **Focus**: Observability, monitoring, agent system maintenance

## 🎯 How to Use

### Step 1: Choose Your Context
Based on your current project:

```bash
# For Resonai voice practice app
cp CURSOR_SETUP_PROMPT_RESONAI.md .cursor-prompt.md

# For OTel observability pipeline  
cp CURSOR_SETUP_PROMPT_OTEL.md .cursor-prompt.md

# For general/unknown context
cp CURSOR_SETUP_PROMPT.md .cursor-prompt.md
```

### Step 2: Set Cursor System Prompt
1. Open Cursor IDE
2. Go to Settings → AI → System Prompt
3. Copy the contents of your chosen prompt file
4. Paste into the system prompt field
5. Save and restart Cursor

### Step 3: Verify Setup
Run the appropriate health check:

```powershell
# For OTel projects
pwsh -File scripts/health-check.ps1

# For Resonai projects  
pnpm run ci
```

## 🔄 Context Switching

When switching between projects:

1. **Update system prompt** with the appropriate file
2. **Check project structure** matches expected context
3. **Run health checks** to verify environment
4. **Update `.agent/status.json`** if using agent system

## 🎭 ECRR Integration

All prompts include **ECRR mantra** integration:
- **Examine** → Capture environment state
- **Clean** → Remove drift, enforce guardrails  
- **Report** → Save results in `docs/ECRR_REPORTS/`
- **Role** → Declare actor in PR body

## 🛡️ Common Guardrails

All prompts enforce:
- **Security**: No secrets, safe defaults, localhost-only CORS
- **Accessibility**: ARIA roles, keyboard navigation, reduced-motion
- **Privacy**: No PII logging, confirm redaction for telemetry
- **Budgets**: ≤10 files / ≤200 LOC per PR
- **Local-first**: No external network calls except localhost

## 🚨 Troubleshooting

### Wrong Context Detected
If Cursor seems confused about project context:
1. Check current directory matches expected project
2. Verify system prompt matches project type
3. Run appropriate health checks
4. Update `.agent/status.json` if needed

### Agent System Issues
If agent system not responding:
1. Check `.agent/LOCK` file exists
2. Verify `.agent/state/queue.jsonl` has tasks
3. Run `pwsh -File .agent/scripts/run-codex.ps1`
4. Check logs in `.agent/logs/`

### Port Conflicts
If experiencing port conflicts:
1. Check port mapping (4317/4318 vs 14317/14318)
2. Verify Docker Desktop WSL integration
3. Run `pwsh -File scripts/check-ports.ps1`
4. Update configuration files as needed

## 📊 Success Indicators

**OTel Projects:**
- SigNoz UI reachable on `http://localhost:8080`
- Collector service healthy
- Canary tests passing
- Agent system processing tasks

**Resonai Projects:**
- `window.crossOriginIsolated === true`
- Mic constraints properly configured
- Practice flow integrity maintained
- Analytics flowing to SigNoz

## 🔄 Maintenance

Update prompts when:
- New project phases are added
- Guardrails change
- New tools or scripts are introduced
- Agent system evolves
- ECRR methodology updates

## 📝 Customization

To create a new project-specific prompt:
1. Copy the general template (`CURSOR_SETUP_PROMPT.md`)
2. Update the **Project Context** section
3. Modify **Commands** and **Key Files** sections
4. Adjust **Success Metrics** for your project
5. Test with health checks before deploying

---

**Ready to set up Cursor for your project!** 🚀

Choose your prompt, set your system prompt, and start building! 🎯
