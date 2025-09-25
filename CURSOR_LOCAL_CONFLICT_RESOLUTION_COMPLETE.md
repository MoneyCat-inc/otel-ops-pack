# Cursor-Local Conflict Resolution System - Complete Setup

## 🎯 Mission Accomplished

I have successfully implemented a comprehensive **Cursor-Local** conflict resolution system that assists **Codex-Cloud** with PR conflict resolution, documentation normalization, and maintenance patches. The system converts messy repository states into clean, reviewable patches with structured briefs for Codex-Cloud to act on.

## 📋 What Was Delivered

### 1. Core Conflict Resolution Engine
**File**: `.agent\cursor-local-conflict-resolver.ps1`
- **Purpose**: Main conflict detection, analysis, and resolution system
- **Features**:
  - Extracts conflict information from git merge attempts
  - Generates canonical resolutions for common patterns
  - Creates structured Codex-Cloud brief comments
  - Optionally creates minimal patches with safety validation
  - Enforces safety constraints (≤10 files, ≤200 LOC per PR)

### 2. GitHub Integration System
**File**: `.agent\github-integration.ps1`
- **Purpose**: GitHub CLI integration and PR monitoring
- **Features**:
  - GitHub CLI authentication management
  - PR monitoring for conflict triggers (`needs-conflict-help` label, `@codex` mentions)
  - Automatic labeling of conflicted PRs
  - GitHub Actions workflow generation
  - Webhook configuration support

### 3. Patch Validation & Safety System
**File**: `.agent\patch-validator.ps1`
- **Purpose**: Validates patches before application with safety checks
- **Features**:
  - Safety constraint enforcement (file count, LOC limits)
  - Secret detection and prevention
  - File syntax validation (PowerShell, YAML, JSON)
  - Backup and rollback capabilities
  - Dry-run patch application

### 4. Test Suite & Validation
**File**: `.agent\test-conflict-resolution.ps1`
- **Purpose**: End-to-end testing of the conflict resolution workflow
- **Features**:
  - Sample conflict generation
  - Full workflow testing
  - Validation of canonical resolutions
  - Cleanup utilities

### 5. Documentation & Templates
**Files**: 
- `.agent\conflict-resolution-template.md` - Template library for common conflict patterns
- `.agent\CURSOR_LOCAL_SETUP.md` - Comprehensive setup and usage guide
- `.agent\cursor-local-enhanced.prompt.md` - Enhanced Cursor-Local prompt with conflict resolution capabilities

### 6. Demo & Examples
**File**: `.agent\demo-conflict-resolution.ps1`
- **Purpose**: Interactive demonstration of the complete workflow
- **Features**:
  - Quick demo of key workflow steps
  - Full demo of complete process
  - Visual representation of conflict resolution

## 🔄 Complete Workflow

### Trigger Conditions
The system activates when any of these conditions are met:
1. **PR Label**: PR gains label `needs-conflict-help`
2. **PR Comment**: Comment includes `@codex please analyze this conflict` or `/analyze-conflicts`
3. **Manual Trigger**: Local dev runs `cursor task: conflicts --pr <num>`

### Workflow Steps
1. **Detect Conflicts** → Monitor PRs for merge conflicts
2. **Analyze Conflicts** → Extract conflict hunks with context
3. **Generate Canonical Resolution** → Apply consistent style rules
4. **Create Codex-Cloud Brief** → Post structured instructions to PR
5. **Optional Patch Creation** → Generate minimal, safe patches
6. **Codex-Cloud Action** → Apply resolution based on brief
7. **Verification** → Validate resolution meets acceptance criteria
8. **Handoff Complete** → Ready for merge

## 🛡️ Safety & Guardrails

### Non-Negotiable Constraints
- **Safety budget**: ≤ 10 changed files, ≤ 200 LOC per PR
- **Idempotence**: Patches must be safe to re-apply or noop on second run
- **Diff-only mindset**: Make the smallest change that resolves the issue
- **No secrets**: Never print or commit tokens/keys
- **No background promises**: Produce results in this run

### Validation Steps
1. **No merge markers**: Remove `<<<<<<<`, `=======`, `>>>>>>>`
2. **Style consistency**: Apply project rules
3. **Functionality**: Verify scripts/configs work
4. **Tests pass**: Run smoke tests if available
5. **Safety constraints**: File count and LOC limits respected

## 🎨 Style Rules & Canonical Resolutions

### Documentation Conflicts
**Common Pattern**: Different phrasing for same concept
**Example Conflict**:
```diff
- [feature-branch] **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off); run `make-audit-pack.ps1` on-demand for manual capture
+ [main]          **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail; run `make-audit-pack.ps1` on-demand if you need a manual capture
```

**Canonical Resolution**:
```markdown
- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off). Run `make-audit-pack.ps1` on demand for a manual capture.
```

**Style Rules Applied**:
- Keep **"(hands-off)"** parenthetical (automation policy)
- Use **"on demand"** (no hyphen)
- Split into two sentences for clarity
- Preserve arrow **→** for action/result mapping

## 🚀 Quick Start Guide

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

# Run demo
.\demo-conflict-resolution.ps1 -QuickDemo
```

## 📝 Codex-Cloud Brief Template

The system generates structured briefs like this:

```markdown
@codex please resolve this conflict set with the canonical wording below

PR: #123 — fubumaki/otel-ops-pack
Base: `main`  
Head: `feature-branch`

## Context
We're normalizing wording in the **Periodic Maintenance** section. Preserve automation policy and concise style.

### Conflict hunk
```diff
- [feature-branch] **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off); run `make-audit-pack.ps1` on-demand for manual capture
+ [main]          **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail; run `make-audit-pack.ps1` on-demand if you need a manual capture
```

### Canonical resolution (apply exactly)
```markdown
- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off). Run `make-audit-pack.ps1` on demand for a manual capture.
```

### Style/intent rules
* Keep **"(hands-off)"** parenthetical (automation policy).
* Prefer concise, declarative style.
* Use **"on demand"** (no hyphen). Break into two sentences.
* Preserve the arrow **→** for action/result mapping.

### Acceptance criteria
* No merge markers remain.
* Canonical resolution applied exactly.
* No unrelated lines changed.
```

## 🔧 Integration with Existing System

This conflict resolution system seamlessly integrates with the existing `.agent` infrastructure:

- **Uses existing policies**: Enforces `.agent\policies.md` rules
- **Leverages existing tools**: Integrates with `.agent\tools\smoke.mjs`
- **Follows existing patterns**: Uses same task queue format
- **Maintains compatibility**: Works with existing `cursor.prompt.md` and `codex.prompt.md`

## 📊 System Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitHub PR     │───▶│  Cursor-Local    │───▶│  Codex-Cloud    │
│                 │    │  Conflict        │    │                 │
│ • Labels        │    │  Resolver        │    │ • Reviews brief │
│ • Comments      │    │                  │    │ • Applies fix   │
│ • Merge status  │    │ • Detects        │    │ • Validates     │
└─────────────────┘    │ • Analyzes       │    │ • Commits       │
                       │ • Generates      │    └─────────────────┘
                       │ • Creates brief  │
                       │ • Validates      │
                       └──────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │  Patch Validator │
                       │                  │
                       │ • Safety checks  │
                       │ • Syntax valid   │
                       │ • Rollback ready │
                       └──────────────────┘
```

## ✅ Verification & Testing

The system has been tested with:
- ✅ Sample conflict generation
- ✅ Conflict detection and extraction
- ✅ Canonical resolution generation
- ✅ Patch validation and safety checks
- ✅ GitHub integration components
- ✅ End-to-end workflow demonstration

## 🎯 Success Criteria Met

All requested features have been implemented:

1. **✅ Identity & Role**: Cursor-Local as local orchestrator & patch crafter
2. **✅ Operating Assumptions**: Windows 11 + PowerShell + GitHub CLI
3. **✅ Non-Negotiable Guardrails**: Safety budgets, idempotence, diff-only mindset
4. **✅ Trigger Conditions**: Labels, comments, manual triggers
5. **✅ Input/Output Contracts**: PR metadata, conflict extraction, structured briefs
6. **✅ Standard Operating Procedure**: Complete workflow from detection to handoff
7. **✅ Comment Templates**: Structured briefs for Codex-Cloud
8. **✅ Local Commands**: PowerShell scripts for all operations
9. **✅ Handoff Pattern**: Clear Cursor-Local → Codex-Cloud workflow
10. **✅ Failure Handling**: Rollback procedures and error handling

## 🚀 Ready for Production

The system is now ready for immediate use:

1. **Setup**: Run the GitHub integration setup
2. **Monitor**: Enable PR monitoring for conflict triggers
3. **Resolve**: Use the conflict resolver for any conflicted PRs
4. **Validate**: Ensure all patches pass safety and validation checks
5. **Handoff**: Let Codex-Cloud process the structured briefs

The complete Cursor-Local conflict resolution system provides a robust, safe, and efficient way to handle PR conflicts while maintaining code quality and project standards.
