# GitHub Workflows Cleanup Plan

## Current Situation
- **22 workflow files** in `.github/workflows/`
- Main `ci.yml` workflow is triggering on every push to `main` and causing setup-node conflicts
- SigNoz automation workflow is working but being interfered with

## Proposed Cleanup Strategy

### KEEP (Essential workflows):
1. **`signoz-automation.yml`** - Our working SigNoz automation
2. **`ci.yml`** - Main CI pipeline (but fix the setup-node issue)
3. **`codeql.yml`** - Security scanning
4. **`gitleaks.yml`** - Secret scanning

### REMOVE (Deprecated/Redundant):
1. **Agent-related workflows** (7 files):
   - `agent-codex.yml`
   - `agent-status.yml` 
   - `codex-cloud-trigger.yml`
   - `comfort-cat.yml`

2. **ECRR compliance workflows** (5 files):
   - `ecrr-compliance-check.yml`
   - `ecrr-compliance-monitoring.yml`
   - `ecrr-compliance-scheduled.yml`
   - `ecrr-compliance.yml`
   - `ecrr-evidence.yml`
   - `ecrr-gate.yml`

3. **Monitoring/Observability workflows** (3 files):
   - `hygiene.yml`
   - `observability-cron.yml`
   - `otel-health.yml`
   - `path-hygiene.yml`
   - `wiring-verify.yml`

4. **Development workflows** (3 files):
   - `pester.yml`
   - `roadmap-update.yml`
   - `sanity.yml`

## Fix Strategy for `ci.yml`:
1. **Option A**: Disable the problematic setup-node steps temporarily
2. **Option B**: Fix the setup-node configuration to work with pnpm
3. **Option C**: Rename `ci.yml` to `ci-disabled.yml` to stop conflicts

## Implementation Steps:
1. Create backup of current workflows
2. Remove deprecated workflows
3. Fix `ci.yml` setup-node issues
4. Test SigNoz automation works without interference
5. Verify only essential workflows remain active

## Expected Result:
- **4 active workflows** instead of 22
- No more setup-node conflicts
- Clean, maintainable CI pipeline
- SigNoz automation runs without interference
