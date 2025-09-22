# 🚀 Cursor Setup Guide — Clean & Focused

This guide provides **ready-to-drop Cursor setup prompts** tailored for different project contexts within the Resonai ecosystem.

## 📁 Available Setup Prompts

### 1. **General Workflow** (`CURSOR_SETUP_PROMPT_GENERAL_CLEAN.md`)
- **Use for**: Any Resonai ecosystem project
- **Context**: Auto-detects Resonai voice practice vs OTel observability
- **Best for**: New projects or when context is unclear

### 2. **Resonai Voice Practice** (`CURSOR_SETUP_PROMPT_RESONAI_CLEAN.md`)
- **Use for**: Resonai voice practice application (`c:\Projects\resonai`)
- **Context**: M1 Warmup, M2 Prosody, Instant Practice features
- **Focus**: Voice practice flows, analytics integration, OTLP wiring

### 3. **OTel Observability** (`CURSOR_SETUP_PROMPT_OTEL_CLEAN.md`)
- **Use for**: OTel observability pipeline (`c:\otel`)
- **Context**: Windows Collector + SigNoz stack
- **Focus**: Observability, monitoring, agent system maintenance

## 🎯 How to Use

### Step 1: Choose Your Context
Based on your current project:

```bash
# For Resonai voice practice app
cp CURSOR_SETUP_PROMPT_RESONAI_CLEAN.md .cursor-prompt.md

# For OTel observability pipeline  
cp CURSOR_SETUP_PROMPT_OTEL_CLEAN.md .cursor-prompt.md

# For general/unknown context
cp CURSOR_SETUP_PROMPT_GENERAL_CLEAN.md .cursor-prompt.md
```

### Step 2: Set Cursor System Prompt
1. Open Cursor IDE
2. Go to Settings → AI → System Prompt
3. Copy the contents of your chosen prompt file
4. Paste into the system prompt field
5. Save and restart Cursor

### Step 3: Verify Setup
Run the appropriate health check:

```bash
# For Resonai projects
pnpm run ci

# For OTel projects
pwsh -File scripts/health-check.ps1
```

## 🔄 Context Switching

When switching between projects:

1. **Update system prompt** with the appropriate file
2. **Check project structure** matches expected context
3. **Run health checks** to verify environment
4. **Update `.agent/status.json`** if using agent system

## 🛡️ Common Guardrails

All prompts enforce:
- **CSP**: No inline styles, no `dangerouslySetInnerHTML`
- **Accessibility**: ARIA roles, keyboard navigation, reduced-motion
- **Privacy**: No PII logging, local-first audio processing
- **Budgets**: ≤10 files / ≤200 LOC per PR
- **CI Discipline**: Run `pnpm run ci` before every PR

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

**Resonai Projects:**
- `window.crossOriginIsolated === true`
- Mic constraints properly configured
- Practice flow integrity maintained
- Analytics flowing to SigNoz

**OTel Projects:**
- SigNoz UI reachable on `http://localhost:8080`
- Collector service healthy
- Canary tests passing
- Agent system processing tasks

## 🔄 Maintenance

Update prompts when:
- New project phases are added
- Guardrails change
- New tools or scripts are introduced
- Agent system evolves

## 📝 Customization

To create a new project-specific prompt:
1. Copy the general template (`CURSOR_SETUP_PROMPT_GENERAL_CLEAN.md`)
2. Update the **Project Context** section
3. Modify **Commands** and **Key Files** sections
4. Adjust **Success Metrics** for your project
5. Test with health checks before deploying

---

## 🚀 Quick Start

```bash
# Choose your prompt
cp CURSOR_SETUP_PROMPT_RESONAI_CLEAN.md .cursor-prompt.md

# Set in Cursor IDE
# Settings → AI → System Prompt → Paste contents

# Verify setup
pnpm run ci
```

**Ready to build!** 🎯

---

📌 **Pro Tip**: Keep `.cursor-prompt.md` in your project root for easy context switching and team consistency.
