# Cursor Agent Mini-Runbook

## Quick Start Guide

### 1. Agent Setup
```bash
# Ensure you're in the Resonai repo root
cd /path/to/resonai-repo

# Verify agent system is ready
pnpm agent:doctor

# Check current agent status
pnpm agent:status
```

### 2. Launch Cursor Agent
1. **Open Cursor** → **New Agent**
2. **Paste System Prompt**: Copy the entire contents of `docs/cursor-agent-system-prompt.md`
3. **Feed Tasks**: Start with T1 from `docs/cursor-agent-task-pack.md`

### 3. Task Execution Pattern

For each task, ask the agent to:

```
Please implement [TASK_NAME] from the task pack. Follow the ECRR methodology:
1. Examine current state
2. Clean any drift
3. Report findings
4. Declare role as Cursor Agent

Show me your plan first, then implement with tests.
```

### 4. Verification Commands

```bash
# Check agent is processing
pnpm agent:status

# Run specific tests
pnpm test:e2e --grep "resonance-buckets"
pnpm test:unit --grep "prosody-scoring"

# Verify guardrails
pnpm agent:doctor

# Check ECRR reports
ls docs/ECRR_REPORTS/
```

## Emergency Procedures

### Stop Agent Processing
```bash
# Emergency stop
touch .agent/LOCK

# Verify stopped
pnpm agent:status
```

### Resume After Fixes
```bash
# Remove lock to resume
rm .agent/LOCK

# Restart agent
pnpm agent:start
```

### Rollback Changes
```bash
# If agent breaks something
git log --oneline -5
git revert <commit-hash>

# Or reset to last known good
git reset --hard HEAD~1
```

## Task-Specific Commands

### T1: Resonance Buckets
```bash
# Test LPC worklet
pnpm dev
# Navigate to /labs/resonance-test

# Run e2e tests
pnpm test:e2e --grep "resonance"
```

### T2: Prosody Scenarios
```bash
# Test scenario cards
pnpm dev
# Navigate to /practice/scenarios

# Run unit tests
pnpm test:unit --grep "prosody"
```

### T3: Strain Guardrails
```bash
# Test strain detection
pnpm dev
# Navigate to /practice/tuning

# Run strain tests
pnpm test:unit --grep "strain"
```

### T4: Cross-Origin Isolation
```bash
# Test Firefox isolation
pnpm test:e2e --config playwright.firefox.config.ts

# Check COOP/COEP headers
curl -I http://localhost:3000
```

### T5: A11y Smoke
```bash
# Run accessibility tests
pnpm test:e2e --grep "accessibility"

# Test with screen reader
# (Manual testing with NVDA/JAWS)
```

## Monitoring & Debugging

### Check Agent Logs
```bash
# View agent state
cat .agent/state.json

# Check task queue
cat .agent/agent_queue.json

# View recent ECRR reports
ls -la docs/ECRR_REPORTS/ | head -5
```

### Debug Common Issues

**Agent Not Starting**:
```bash
# Check lock status
ls -la .agent/LOCK

# Check dependencies
pnpm install

# Restart agent system
pnpm agent:start
```

**Tests Failing**:
```bash
# Run specific test with verbose output
pnpm test:e2e --grep "resonance" --verbose

# Check test environment
pnpm test:env-check
```

**Guardrails Violations**:
```bash
# Run guardrail check
pnpm agent:doctor

# Fix inline styles
grep -r "style=" src/ --include="*.tsx"
```

## Integration with Existing Workflow

### With ChatGPT Agent
1. ChatGPT plans/specs → Cursor implements → Codex/CI gates
2. Cursor Agent respects existing guardrails and ECRR methodology
3. All changes go through same PR review process

### With Codex-Local
- Cursor Agent updates `.agent/state.json` with progress
- Respects `.agent/LOCK` kill-switch
- Integrates with existing health checks

### With CI/CD
- All changes must pass existing test suites
- ECRR reports are required for PR approval
- Guardrails are enforced at commit level

## Success Metrics

### Per Task
- ✅ All acceptance criteria met
- ✅ ECRR report generated
- ✅ Tests passing (unit + e2e)
- ✅ No guardrail violations
- ✅ PR ready for review

### Overall
- Tasks completed in priority order
- No regressions in existing functionality
- Improved accessibility scores
- Better performance metrics
- Cleaner codebase (no inline styles, proper ARIA)

## Troubleshooting

### Agent Stuck
```bash
# Check for infinite loops
ps aux | grep node

# Kill stuck processes
pkill -f "pnpm.*agent"

# Restart clean
rm .agent/LOCK
pnpm agent:start
```

### Memory Issues
```bash
# Check memory usage
ps aux | grep node | awk '{print $4, $11}'

# Restart with clean state
rm -rf .agent/state.json
pnpm agent:start
```

### Test Environment Issues
```bash
# Clean test artifacts
rm -rf test-results/
rm -rf playwright-report/

# Reinstall dependencies
rm -rf node_modules/
pnpm install

# Reset test database
pnpm test:reset-db
```

## Best Practices

1. **Start Small**: Begin with T1 (highest priority)
2. **Verify Often**: Run tests after each change
3. **Follow ECRR**: Always generate reports
4. **Respect Lock**: Don't override `.agent/LOCK`
5. **Clean Commits**: One concern per PR
6. **Document Changes**: Update relevant docs
7. **Test Thoroughly**: Unit + e2e + manual
8. **Monitor Performance**: Check for regressions

## Getting Help

- Check `docs/ECRR_REPORTS/` for recent issues
- Review `.agent/state.json` for current status
- Run `pnpm agent:doctor` for health check
- Consult `docs/comfort-cat/` for creative guidelines
- Check existing PRs for similar patterns
