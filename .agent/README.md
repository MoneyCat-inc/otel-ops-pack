# AUTO-BOTS Framework

**🐾 BossCat OEM - Paired Agent Stability Pack**

This directory contains the AUTO-BOTS stability framework implementing Rules #2-#4:

## Architecture

- **Agent A (Writer)**: Single writer with lane-locked execution
- **Agent B (Monitor)**: Read-only monitoring and ECRR validation
- **IONA Controller**: Orchestrates paired agents, monitors health

## Components

### Kill-Switch
- **File**: `.agent/LOCK`
- **Purpose**: Emergency pause for all AUTO-BOTS
- **Action**: Create this file to immediately halt all agent operations
- **Exit Code**: 50 (`paused:lock`)

### Write Lock
- **File**: `.agent/JOB.lock`
- **Purpose**: Single-writer mutex (Agent A only)
- **Action**: Automatically managed by lane executor
- **Exit Code**: 52 (`conflict:writer-present`)

### Configuration
- **File**: `.agent/config.json`
- **Contents**:
  - Budgets: Max 2 jobs, 10 files, 200 LOC per job
  - Retry: Max 3 attempts, 15min backoff, 12h TTL
  - Lanes: Approved file patterns per lane

## Lanes

### Approved Lanes
1. **ssot** - Single Source of Truth artifacts
2. **docs** - Documentation drift fixes
3. **a11y** - Accessibility improvements
4. **csp** - Content Security Policy fixes
5. **flaky** - Flaky test quarantine
6. **selector** - Selector hygiene
7. **gate** - Quality/production gates (perf + observability evidence)
8. **site** - Site integrity (build, links, a11y, CSP)

Each lane has specific allow-list patterns defined in `config.json`.

## Scripts

### `scripts/agent/preflight.ts`
Abort-fast checks before any agent operation:
- Kill-switch detection (`.agent/LOCK`)
- Git state pristine check
- Lane validation

**Exit Codes:**
- 0: All checks passed
- 50: Kill-switch active
- 51: Git state blocked

**Usage:**
```bash
pnpm agent:preflight
pnpm agent:preflight --lane=docs
```

### `scripts/agent/lock.ts`
Single-writer mutex for Agent A:
- Atomic lock acquisition
- PID tracking
- Automatic cleanup on exit/error

**Exit Codes:**
- 0: Lock acquired
- 52: Writer conflict

**Usage:**
```bash
# Typically called by run-lane.ts
tsx scripts/agent/lock.ts --agent=A --lane=docs
```

### `scripts/agent/retry.ts`
Bounded retry with backoff and TTL:
- Max 3 attempts
- Exponential backoff with jitter (base 15min)
- 12-hour job TTL
- Automatic rollback on failure

**Exit Codes:**
- 0: Success within retry budget
- 53: Retry exhausted (rollback performed)

**Features:**
- ECRR report generation on failure
- BossCat log entry
- Git rollback (`git restore --staged . && git checkout -- .`)

### `scripts/agent/run-lane.ts`
Lane-scoped executor (Agent A only):
- Budget enforcement (≤10 files, ≤ 2,000 LOC)
- Lane allow-list validation
- Write lock management
- ECRR report generation
- BossCat log updates

**Exit Codes:**
- 0: Success
- 52: Lock conflict
- 53: Retry exhausted

**Usage:**
```bash
pnpm agent:run --lane=docs
pnpm agent:run:ssot  # Shorthand
```

## Workflow

### Normal Execution (Agent A)
```
1. Preflight Check → 2. Acquire Lock → 3. Execute Work → 4. Validate → 5. Release Lock → 6. ECRR
```

### With Retry
```
Attempt 1 → [Fail] → Backoff → Attempt 2 → [Fail] → Backoff → Attempt 3 → [Fail] → Rollback → ECRR
```

### Emergency Stop
```
Create .agent/LOCK → All agents abort with exit code 50
```

## Budgets

**Per-Run Limits:**
- **Jobs**: ≤2 concurrent
- **Files**: ≤10 modified
- **Lines**: ≤200 changed

**Retry Limits:**
- **Attempts**: ≤3 max
- **TTL**: 12 hours
- **Backoff**: 15min base (exponential with jitter)

## ECRR Artifacts

**Location:** `artifacts/ecrr/<lane>/<timestamp>.json`

**Format:**
```json
{
  "actor": "Agent A",
  "lane": "docs",
  "examine": "...",
  "clean": "...",
  "report": "...",
  "role": "...",
  "status": "success|failed",
  "retries": 0,
  "ttlHit": false,
  "timestamp": "2025-10-09T01:40:00.000Z",
  "filesModified": ["..."],
  "linesChanged": 42
}
```

## BossCat Log

**Location:** `docs/BossCat/BOSSCAT_LOG.md`

**Format:**
```markdown
- **2025-10-09T01:40:00.000Z** - Lane docs: Successfully processed 5 files (120 lines)
```

## CI Integration

**Preflight Hook:**
```yaml
# .github/workflows/agent.yml
- name: Preflight Check
  run: pnpm agent:preflight
  
- name: Run Agent
  run: pnpm agent:run:docs
```

## Emergency Procedures

### Pause All Agents
```bash
# Create kill-switch
touch .agent/LOCK

# All agents will exit with code 50
```

### Resume Operations
```bash
# Remove kill-switch
rm .agent/LOCK

# Agents can now run
pnpm agent:preflight  # Should pass
```

### Force Release Lock
```bash
# Only if Agent A crashed without cleanup
rm .agent/JOB.lock

# Verify lock is gone
ls -la .agent/
```

### Rollback Failed Run
```bash
# Automatic on retry exhaustion, or manual:
git restore --staged .
git checkout -- .
```

## Monitoring (Agent B)

Agent B monitors but never writes:
- Watch `artifacts/ecrr/` for new reports
- Validate ECRR structure
- Check `docs/BossCat/BOSSCAT_LOG.md` for patterns
- Alert on repeated failures

**Agent B never calls:**
- `lock.ts` (read-only)
- `run-lane.ts` (writer-only)

**Agent B can call:**
- `preflight.ts` (validation only)
- Read ECRR artifacts
- Generate monitoring reports

## Gate Signal

When a PR is ready:
```markdown
CI is green and all checks are satisfied. **@cat ready-for-gate** 🚪✅
```

## References

- **BossCat Charter**: `docs/AGENTS.md`
- **ECRR Methodology**: `docs/ecrr/`
- **Approved Lanes**: This README + `config.json`

---

🐾 **BossCat OEM** - Executive Overseer Manager  
*Governing paired AUTO-BOTS with stability, evidence, and bounded execution*
