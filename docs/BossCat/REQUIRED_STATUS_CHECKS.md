# Required Status Checks Configuration

**Authority**: BossCat OEM  
**Purpose**: Branch protection rules for main branch

---

## Recommended Required Checks

### Core Gates (Live Required Set)

> **Correction (2026-09-01):** earlier revisions claimed `bosscat-gate-verify`,
> `boss-gate-verify`, and `iona-gate-verify` were required. None of them is in
> the live branch-protection config (verified via
> `branches/main/protection/required_status_checks`; see the
> `.github/workflows/required-check-shims.yml` header audit trail).

The contexts actually required on `main` (verified live 2026-09-01):

1. **CodeQL** (github-code-scanning app)
2. **PSScriptAnalyzer** (github-code-scanning app)
3. **gitleaks** (gitleaks.yml)
4. **Gate • k6 thresholds** (gate-site-evidence.yml)
5. **Gate • synthetic trace (OTLP/HTTP)** (gate-site-evidence.yml)
6. **Site • links + a11y + CSP (coarse)** (gate-site-evidence.yml)
7. **Repository Structure Compliance** (guardrails.yml)

### Docs Lane (Recommended to Add)

**Workflow**: `docs_checks` (from docs-lane-checks.yml)

**What it validates**:

- Budget enforcement (≤10 files, ≤200 LOC)
- Kill-switch check (`.agent/LOCK`)
- Markdown linting (changed files)
- Link checking (changed files)
- ECRR evidence generation

**Why required**:

- Prevents docs drift
- Enforces two-agent protocol
- Validates evidence presence
- Rule #7 compliance (changed-paths testing)

---

## How to Configure (GitHub UI)

### Step 1: Navigate to Branch Protection

```text
Repository → Settings → Branches → Branch protection rules
→ Edit rule for "main"
```

### Step 2: Add Required Status Checks

Under **"Require status checks to pass before merging"**:

**Search for and add**:

- `docs_checks` (from docs-lane-checks.yml)

**Existing required** (keep these — live set as of 2026-09-01):

- `CodeQL` ✅
- `PSScriptAnalyzer` ✅
- `gitleaks` ✅
- `Gate • k6 thresholds` ✅
- `Gate • synthetic trace (OTLP/HTTP)` ✅
- `Site • links + a11y + CSP (coarse)` ✅
- `Repository Structure Compliance` ✅

### Step 3: Optional Settings

**Recommended**:

- ☑️ Require branches to be up to date before merging
- ☑️ Require conversation resolution before merging
- ☑️ Require deployments to succeed before merging (if applicable)

**For docs PRs**:

- May want to allow bypass for minor typo fixes
- Or create a `docs-minor` workflow that runs lighter checks

---

## Via GitHub CLI

```bash
# List current required checks
gh api repos/MoneyCat-inc/otel-ops-pack/branches/main/protection/required_status_checks

# Add docs_checks to required checks (requires existing rule).
# IMPORTANT: contexts[] REPLACES the whole list — re-send every live required
# context (list them with the GET above) plus the new one, e.g.:
gh api --method PATCH \
  repos/MoneyCat-inc/otel-ops-pack/branches/main/protection/required_status_checks \
  -f strict=true \
  -F contexts[]=CodeQL \
  -F contexts[]=PSScriptAnalyzer \
  -F contexts[]=gitleaks \
  -F "contexts[]=Gate • k6 thresholds" \
  -F "contexts[]=Gate • synthetic trace (OTLP/HTTP)" \
  -F "contexts[]=Site • links + a11y + CSP (coarse)" \
  -F "contexts[]=Repository Structure Compliance" \
  -F contexts[]=docs_checks
```

---

## Alternative: Status Check Groups

For more flexible docs validation:

```yaml
# .github/workflows/docs-lane-checks.yml
# Current job name: docs_checks

# Optional: Create a status check group
# In branch protection:
# - docs_checks (main validation)
# - docs_checks_minor (typo-fix fast track)
```

---

## Exemptions & Bypasses

### When to Bypass Docs Lane

**Safe to bypass** (admin override):

- Minor typo fixes (1-2 characters)
- Emergency hotfix documentation
- Automated bot updates (Dependabot, etc.)

**Unsafe to bypass**:

- New documentation files
- Structural changes
- Configuration changes
- Template modifications

### Kill-Switch Usage

**File**: `.agent/LOCK`

**When to create**:

- Emergency: Pause all automated reviews
- Debugging: Isolate reviewer behavior
- Rollback: Temporarily disable two-agent protocol

**How to use**:

```bash
# Activate kill-switch (docs-lane returns BLACK)
echo "EMERGENCY_HALT" > .agent/LOCK
git add .agent/LOCK
git commit -m "chore: Activate kill-switch"

# Deactivate
git rm .agent/LOCK
git commit -m "chore: Deactivate kill-switch"
```

**Result**: All docs PRs fail with BLACK until removed

---

## Secrets Configuration (Notifications Mark-Read)

### For Nightly Workflow

**Current**: Mark-read disabled by default (no PAT required)

**To Enable**:

1. Create PAT Classic with `notifications` scope:
   - <https://github.com/settings/tokens>
   - Scopes: `repo`, `notifications`

2. Add to repository secrets:

   ```text
   Settings → Secrets and variables → Actions
   → New repository secret
   Name: NOTIFICATIONS_PAT
   Value: ghp_...
   ```

3. Update workflow:

   ```yaml
   env:
     GITHUB_TOKEN: ${{ secrets.NOTIFICATIONS_PAT }}  # Instead of secrets.GITHUB_TOKEN
   ```

4. Enable mark-read in manual trigger:

   ```bash
   gh workflow run security-notifications-archive-nightly.yml \
     -f mark_notifications_read=true
   ```

**Recommendation**: Keep disabled unless actively managing notification backlog

---

## Testing Required Checks

### Test Docs Lane Locally

```bash
# Simulate CI checks
markdownlint docs/**/*.md README.md
./lychee --no-progress --exclude-mail docs/**/*.md README.md
```

### Test on Branch

```bash
# Create test branch
git checkout -b test/docs-lane

# Make doc changes (within budget)
echo "# Test" > docs/test.md
git add docs/test.md
git commit -m "docs: test docs-lane CI"

# Push and create PR
git push origin test/docs-lane
gh pr create --title "Test: Docs Lane CI" --body "Testing docs-lane-checks workflow"

# Watch CI run
gh pr checks --watch
```

---

## Monitoring

### GitHub Actions UI

```text
Repository → Actions → Docs Lane Checks
→ View runs
→ Check job summaries
→ Download ecrr-docs artifacts
```

### Via gh CLI

```bash
# List recent docs-lane runs
gh run list --workflow=docs-lane-checks.yml --limit 10

# View specific run
gh run view <run-id>

# Download evidence artifact
gh run download <run-id> --name ecrr-docs
```

---

## Related Documentation

- **Reviewer B Playbook**: `docs/BossCat/ReviewerB_Playbook.md`
- **Evidence Templates**: `.agent/TEMPLATES/PLAN.md`, `.agent/TEMPLATES/EVIDENCE.log.stub`
- **BossCat Charter**: `docs/BossCat/CHARTER.md`
- **Workflow Patterns**: `docs/AGENTS.md`

---

**Authority**: BossCat OEM  
**Status**: Production-ready  
**Last Updated**: 2026-09-01 (required-set lists corrected against live branch protection)

🐾 **BossCat Branch Protection — Governance Framework**
