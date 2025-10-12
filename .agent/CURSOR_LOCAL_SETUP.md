# Cursor-Local Conflict Resolution Setup

## Overview

This setup provides a **Cursor-Local** agent system that assists **Codex-Cloud** with PR conflict resolution, documentation normalization, and maintenance patches. The system converts messy repository states into clean, reviewable patches with concise briefs for Codex-Cloud to act on.

## Identity & Mission

- **You are**: `Cursor-Local`
- **Role**: Local orchestrator & patch crafter
- **Primary goal**: Convert messy repo state (conflicts, drift, style mismatches) into small, reviewable patches and concise briefs
- **Scope**: Local-first operations that never push to remote directly

## Operating Environment

- **OS**: Windows 11 + (optional) WSL2 Ubuntu
- **Tools**: `git`, `gh` (GitHub CLI), PowerShell and/or Bash
- **Repo**: `fubumaki/otel-ops-pack` (configurable per task)
- **Integration**: Codex-Cloud monitors PR comments and label changes

## Non-Negotiable Guardrails

- **Safety budget**: ≤ 10 changed files, ≤ 2,000 LOC per PR
- **Idempotence**: Patches must be safe to re-apply or noop on second run
- **Diff-only mindset**: Make the smallest change that resolves the issue
- **No secrets**: Never print or commit tokens/keys
- **No background promises**: Produce results in this run

## Trigger Conditions

The system activates when any of these conditions are met:

1. **PR Label**: PR gains label `needs-conflict-help`
2. **PR Comment**: Comment includes `@codex please analyze this conflict` or `/analyze-conflicts`
3. **Manual Trigger**: Local dev runs `cursor task: conflicts --pr <num>`

## System Components

### 1. Core Conflict Resolver
**File**: `.agent\cursor-local-conflict-resolver.ps1`

```powershell
# Basic usage
.\cursor-local-conflict-resolver.ps1 -PR 123 -Repo fubumaki/otel-ops-pack -CreatePatch

# Local conflict check
.\cursor-local-conflict-resolver.ps1 -LocalOnly
```

**Features**:
- Extracts conflict information from git merge attempts
- Generates canonical resolutions for common patterns
- Creates Codex-Cloud brief comments
- Optionally creates minimal patches with safety validation

### 2. GitHub Integration
**File**: `.agent\github-integration.ps1`

```powershell
# Setup GitHub CLI and webhooks
.\github-integration.ps1 -Action setup

# Monitor PR for triggers
.\github-integration.ps1 -Action monitor -PR 123 -Repo fubumaki/otel-ops-pack

# Auto-label conflicted PRs
.\github-integration.ps1 -Action check-conflicts -Repo fubumaki/otel-ops-pack
```

**Features**:
- GitHub CLI authentication management
- PR monitoring for conflict triggers
- Automatic labeling of conflicted PRs
- GitHub Actions workflow generation

### 3. Patch Validation System
**File**: `.agent\patch-validator.ps1`

```powershell
# Validate existing patch
.\patch-validator.ps1 -Validate -PatchFile conflict-fix.patch

# Apply patch with validation
.\patch-validator.ps1 -Apply -PatchFile conflict-fix.patch -DryRun

# Create patch from branch
.\patch-validator.ps1 -Branch cursor-local/conflict-resolve-123
```

**Features**:
- Safety constraint enforcement (file count, LOC limits)
- Secret detection and prevention
- File syntax validation (PowerShell, YAML, JSON)
- Backup and rollback capabilities

### 4. Test Suite
**File**: `.agent\test-conflict-resolution.ps1`

```powershell
# Create sample conflict scenario
.\test-conflict-resolution.ps1 -CreateSample

# Test full resolution workflow
.\test-conflict-resolution.ps1 -TestResolver

# Clean up test artifacts
.\test-conflict-resolution.ps1 -Cleanup
```

**Features**:
- Sample conflict generation
- End-to-end workflow testing
- Validation of canonical resolutions
- Cleanup utilities

## Standard Operating Procedure (SOP)

### A) Collect Conflicts & Context

1. **Identify PR metadata**:
   ```bash
   gh pr view <PR> --json baseRefName,headRefName,baseRepository,headRepository
   ```

2. **Reproduce merge conflicts**:
   ```bash
   git fetch --all --quiet
   git checkout -B pr/<PR> origin/<headRefName>
   git merge --no-commit --no-ff <baseRepositoryOwner>/<baseRefName> || true
   ```

3. **Extract conflict information**:
   ```bash
   git diff --name-only --diff-filter=U
   ```

### B) Generate Codex-Cloud Brief

For each conflicted file, the system assembles:
- File path and context
- Raw conflict diff with markers
- Canonical target text
- Style rules and acceptance criteria
- Idempotent resolution instructions

### C) Create Minimal Patch (Optional)

- Only for deterministic resolutions
- Validates safety constraints
- Creates backup branch
- Applies with validation

### D) Post Brief and Patch

- Posts detailed comment to PR
- Optionally creates patch branch
- Provides verification instructions

## Handoff Pattern: Cursor-Local → Codex-Cloud

### 1. Cursor-Local Actions
- Detects conflicts via triggers
- Extracts and analyzes conflict content
- Generates canonical resolutions
- Posts structured brief to PR
- Creates minimal patch if safe

### 2. Codex-Cloud Actions
- Monitors PR comments for briefs
- Reviews canonical resolutions
- Applies idempotent fixes
- Validates against acceptance criteria
- Merges when ready

### 3. Verification Loop
- Cursor-Local validates applied changes
- Runs smoke tests if available
- Confirms no merge markers remain
- Verifies style consistency

## Common Conflict Patterns & Resolutions

### Documentation Wording Conflicts
**Pattern**: Different phrasing for same concept
**Example**: "hands-off" vs "automated", "on-demand" vs "on demand"
**Resolution**: Apply consistent style rules

### Configuration Format Conflicts
**Pattern**: YAML/JSON formatting differences
**Resolution**: Apply project formatting standards

### Script Path Conflicts
**Pattern**: Different file paths or references
**Resolution**: Use canonical paths from project structure

### Version/Date Conflicts
**Pattern**: Different version numbers or dates
**Resolution**: Use more recent or higher version

## Style Rules Reference

### Documentation
- Keep **"(hands-off)"** parenthetical for automation policy
- Use **"on demand"** (no hyphen)
- Prefer concise, declarative style
- Preserve arrows **→** for action/result mapping

### PowerShell Scripts
- Use `.\` for relative paths in current directory
- Use `Get-Content` with `-Raw` for multiline content
- Use `Set-Content` with `-NoNewline` to preserve formatting

### YAML Configuration
- Use 2-space indentation
- Quote strings with special characters
- Maintain consistent field ordering

## Safety & Validation

### Safety Constraints
- **Maximum files**: 10 per PR
- **Maximum lines**: 200 per PR
- **Idempotence**: Safe to re-apply
- **No secrets**: Never commit tokens/keys
- **Diff-only**: Minimal changes only

### Validation Steps
1. **No merge markers**: Remove `<<<<<<<`, `=======`, `>>>>>>>`
2. **Style consistency**: Apply project rules
3. **Functionality**: Verify scripts/configs work
4. **Tests pass**: Run smoke tests if available
5. **Documentation**: Update if behavior changes

## Quick Start Guide

### 1. Initial Setup
```powershell
# Setup GitHub integration
.\github-integration.ps1 -Action setup

# Create conflict resolution label
.\github-integration.ps1 -Action label -Repo fubumaki/otel-ops-pack
```

### 2. Monitor for Conflicts
```powershell
# Check for conflicted PRs
.\github-integration.ps1 -Action check-conflicts -Repo fubumaki/otel-ops-pack

# Monitor specific PR
.\github-integration.ps1 -Action monitor -PR 123 -Repo fubumaki/otel-ops-pack
```

### 3. Manual Conflict Resolution
```powershell
# Analyze and resolve conflicts in PR 123
.\cursor-local-conflict-resolver.ps1 -PR 123 -Repo fubumaki/otel-ops-pack -CreatePatch

# Check local conflicts
.\cursor-local-conflict-resolver.ps1 -LocalOnly
```

### 4. Test the System
```powershell
# Run full test suite
.\test-conflict-resolution.ps1 -CreateSample
.\test-conflict-resolution.ps1 -TestResolver
.\test-conflict-resolution.ps1 -Cleanup
```

## Troubleshooting

### Common Issues

**GitHub CLI not authenticated**:
```powershell
gh auth login
```

**No conflicts detected**:
- Verify PR has actual merge conflicts
- Check branch names and repository

**Patch validation fails**:
- Review safety constraints
- Check for secrets in content
- Validate file syntax

**Resolution not applied**:
- Verify canonical resolution format
- Check style rules compliance
- Ensure no merge markers remain

### Rollback Procedures

**Revert applied patch**:
```powershell
git reset --hard HEAD~1
```

**Reset to clean state**:
```powershell
git checkout main
git branch -D <conflict-branch>
```

**Remove test artifacts**:
```powershell
.\test-conflict-resolution.ps1 -Cleanup
```

## Integration with Existing Agent System

This conflict resolution system integrates with the existing `.agent` infrastructure:

- **Uses existing policies**: Enforces `.agent\policies.md` rules
- **Leverages existing tools**: Integrates with `.agent\tools\smoke.mjs`
- **Follows existing patterns**: Uses same task queue format
- **Maintains compatibility**: Works with existing `cursor.prompt.md` and `codex.prompt.md`

The system extends the current agent capabilities without disrupting existing workflows, providing specialized conflict resolution that complements the broader observability pipeline management.
