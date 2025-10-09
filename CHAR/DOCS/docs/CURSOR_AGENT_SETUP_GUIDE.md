# cursor-gap-closer Agent Setup Guide

## 🎯 Quick Start

Your **cursor-gap-closer** agent is now ready to process UI/UX and audio-engine tasks! Here's how to use it:

### Basic Commands

```bash
# Start the agent (processes high-priority tasks)
pnpm cursor:start

# Check agent status
pnpm cursor:status

# Stop agent (emergency)
pnpm cursor:stop

# Resume agent
pnpm cursor:resume
```

### Advanced Commands

```bash
# List all tasks in queue
pnpm cursor:list-tasks

# Process a specific task by ID
pnpm cursor:task task-a11y-001

# Process all high-priority tasks
pnpm cursor:process-all

# Dry run (see what would be done)
pwsh -File scripts/cursor-agent-processor.ps1 -DryRun

# Verbose output
pwsh -File scripts/cursor-agent-processor.ps1 -Verbose
```

### What's Configured

✅ **Agent Configuration** (`.agent/config.json`)
- Max jobs: 2 concurrent tasks
- Max files: 10 per task
- Max lines: 200 per task
- TTL: 12 hours per task
- Max attempts: 3 retries

✅ **Task Queue** (`.agent/agent_queue.json`)
- 5 priority tasks loaded
- Focus on accessibility, audio engine, and mobile UX
- ECRR-compliant task structure

✅ **Agent Documentation** (`AGENTS.md`)
- Complete cursor-gap-closer section added
- Guardrails and acceptance criteria defined
- PR template included

### Current Task Queue

| Priority | Task | Type | Files |
|----------|------|------|-------|
| 10 | Add aria-live and keyboard navigation to Practice HUD | a11y-fix | `src/components/PracticeHUD.tsx` |
| 9 | Integrate WASM formant tracker fallback | audio-upgrade | `public/worklets/lpc-processor.js`, `src/audio/formantTracker.ts` |
| 8 | Implement responsive design for mobile practice flow | ui-enhancement | `src/components/PracticeFlow.tsx`, `app/ui.css` |
| 7 | Optimize audio processing pipeline for low latency | performance-optimization | `src/audio/processor.ts`, `src/audio/bufferManager.ts` |
| 6 | Add comprehensive ARIA labels and roles | accessibility | `src/components/**/*.tsx` |

### Guardrails Enforced

- **No Inline Styles**: Use `app/ui.css` utilities only
- **Accessibility First**: ARIA, reduced-motion, WCAG AA compliance
- **Local-First**: No external network calls
- **ECRR Compliance**: Examine → Clean → Report → Role methodology
- **Lock Respect**: Honor `.agent/LOCK` kill-switch

### ECRR Reports

Each completed task generates an ECRR report in `docs/ECRR_REPORTS/`:

- **Format**: `YYYY-MM-DDTHH-mm-ssZ-{taskId}-{taskType}.md`
- **Content**: Examine → Clean → Report → Role methodology
- **Evidence**: Screenshots, performance metrics, accessibility audits
- **Artifacts**: Code changes, documentation updates, test results

Example report: `2025-09-28T04-50-28Z-task-a11y-001-a11y-fix.md`

### Next Steps

1. **Start Processing**: Run `pnpm cursor:start` to begin task processing
2. **Monitor Progress**: Use `pnpm cursor:status` to check agent state
3. **Add Tasks**: Edit `.agent/agent_queue.json` to add new tasks
4. **Review Results**: Check `docs/ECRR_REPORTS/` for task completion reports
5. **Advanced Processing**: Use `pnpm cursor:list-tasks` to see queue, `pnpm cursor:task {id}` for specific tasks

### Integration with Cursor

The agent is designed to work seamlessly with Cursor's AI capabilities:

- **Task Processing**: Automatically processes high-priority UI/UX tasks
- **Code Generation**: Follows guardrails for accessibility and performance
- **Documentation**: Generates ECRR reports for each completed task
- **Quality Assurance**: Enforces WCAG AA compliance and performance budgets

### Troubleshooting

**Agent won't start?**
- Check if `.agent/LOCK` exists (use `pnpm cursor:resume`)
- Verify `.agent/config.json` and `.agent/agent_queue.json` exist
- Run `pnpm cursor:status` for detailed diagnostics

**Tasks not processing?**
- Ensure agent is unlocked (`pnpm cursor:resume`)
- Check task priorities in `.agent/agent_queue.json`
- Verify file paths in task payloads are correct

**Need to add tasks?**
- Edit `.agent/agent_queue.json` with new task objects
- Follow the existing task structure (id, type, priority, payload)
- Use priority 1-10 (10 = highest priority)

---

## 🎉 Ready to Go!

Your cursor-gap-closer agent is now configured and ready to help close the UI/UX and audio-engine gaps identified in your project. The agent will automatically process high-priority tasks while maintaining strict guardrails for accessibility, performance, and code quality.

**Start processing tasks now:**
```bash
pnpm cursor:start
```
