# Status Auto-Update: GitHub Actions Setup

> **HISTORICAL (2026-09-02 truth pass).** The `status-auto-update.yml` workflow this page
> describes was removed in commit `31423808` ("ci(workflows): clear the 13 per-push
> validation failures"); no workflow refreshes the status dashboard today. Status updates
> are manual: `pwsh scripts/update-status-dashboard.ps1`, then commit through the normal PR
> lane. Kept as the design/setup record.

## 🔐 Required Repository Settings

The Status Dashboard Auto-Update workflow requires specific GitHub Actions permissions to create pull requests.

### Enable PR Creation for GitHub Actions

**⚠️ CRITICAL:** The workflow will fail with "GitHub Actions is not permitted to create or
approve pull requests" unless this setting is enabled.

**Steps to Enable:**

1. Go to repository **Settings**
2. Navigate to **Actions** → **General**
3. Scroll down to **Workflow permissions**
4. Check the box: ✅ **"Allow GitHub Actions to create and approve pull requests"**
5. Click **Save**

### Current Permissions

The workflow `.github/workflows/status-auto-update.yml` already declares:

```yaml
permissions:
  contents: write        # Push commits, create branches
  pull-requests: write   # Create and update PRs
```

These permissions are only effective if the repository setting above is enabled.

---

## 🔧 Alternative: Use Personal Access Token (PAT)

If you cannot enable the repository setting, use a PAT instead:

### 1. Create PAT

1. Go to **GitHub** → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token (classic)**
3. Name: `status-auto-update-bot`
4. Scopes: Select `repo` (full control)
5. Click **Generate token**
6. **Copy the token** (you won't see it again!)

### 2. Add Token to Repository Secrets

1. Go to repository **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `PAT_TOKEN`
4. Value: (paste your PAT)
5. Click **Add secret**

### 3. Update Workflow

Modify `.github/workflows/status-auto-update.yml`:

```yaml
- name: Create PR (lane discipline)
  uses: peter-evans/create-pull-request@v6
  with:
    token: ${{ secrets.PAT_TOKEN }}  # Use PAT instead of GITHUB_TOKEN
    branch: bots/status-auto-update
    # ... rest of config
```

---

## ✅ Verification

After enabling the setting or configuring PAT:

1. **Trigger workflow:** `gh workflow run status-auto-update.yml --ref main`
2. **Wait for completion:** ~1-2 minutes
3. **Check for PR:** `gh pr list --head bots/status-auto-update`
4. **Expected:** PR created successfully

---

## 📊 BossCat Compliance

**Lane Discipline:** ✅ Creates PR (never pushes to main)  
**Kill-switch:** ✅ Checks `.agent/LOCK`  
**Budgets:** ✅ ≤10 files, allow-list  
**A/B Pairing:** ✅ Writer + Verifier  

**Authority:** Cursor{Implementer}  
**Date:** 2025-10-22

