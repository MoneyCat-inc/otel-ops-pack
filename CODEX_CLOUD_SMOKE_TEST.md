# Codex-Cloud Smoke Test

This is a test branch to validate the Codex-Cloud conflict resolution system.

## Test Scenario
- Create a simple conflict in README.md
- Add the 'needs-conflict-help' label to trigger Codex-Cloud
- Verify automated conflict resolution

## Expected Behavior
Codex-Cloud should:
1. Detect the conflict via GitHub Actions
2. Analyze the conflict using cursor-local-conflict-resolver.ps1
3. Post a structured brief with canonical resolution
4. Optionally create a minimal patch

## Test Status
- [ ] Conflict created
- [ ] PR opened with label
- [ ] Codex-Cloud triggered
- [ ] Resolution posted
- [ ] System validated
