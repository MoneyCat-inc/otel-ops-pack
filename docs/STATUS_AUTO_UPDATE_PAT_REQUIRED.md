# Status Auto-Update: PAT Required

## 🚨 GITHUB_TOKEN Limitation Discovered

<!-- markdownlint-disable-next-line MD013 -->
**Issue:** Despite enabling "Allow GitHub Actions to create and approve pull requests" at both repository and organization levels, workflows still fail with:

```text
##[error]GitHub Actions is not permitted to create or approve pull requests.
```

<!-- markdownlint-disable-next-line MD013 -->
**Root Cause:** The `GITHUB_TOKEN` in GitHub Actions has restrictions in enterprise/organization contexts that prevent PR creation, even with settings enabled.

**Solution:** Use a Personal Access Token (PAT) instead of `GITHUB_TOKEN`.

---

## 🔧 CREATE PERSONAL ACCESS TOKEN (5 minutes)

### Step 1: Generate PAT

1. **Navigate to:** `https://github.com/settings/tokens`
2. **Click:** "Generate new token" → "Generate new token (classic)"
3. **Settings:**
   - **Note:** `status-auto-update-bot`
   - **Expiration:** 90 days (or No expiration for prod)
   - **Scopes:** Check ☑ `repo` (full control of private repositories)
     - This includes: `repo:status`, `repo_deployment`, `public_repo`, `repo:invite`
4. **Click:** "Generate token"
5. **Copy token:** (you won't see it again!)
   - Format: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### Step 2: Add Token to Repository Secrets

1. **Navigate to:** `https://github.com/MoneyCat-inc/otel-ops-pack/settings/secrets/actions`
2. **Click:** "New repository secret"
3. **Name:** `PAT_STATUS_UPDATE`
4. **Value:** (paste your PAT from Step 1)
5. **Click:** "Add secret"

### Step 3: Verify Secret Added

You should see `PAT_STATUS_UPDATE` in the list of repository secrets.

---

## ✅ I'LL UPDATE THE WORKFLOW

<!-- markdownlint-disable-next-line MD013 -->
Once you've added the secret, I'll update `.github/workflows/status-auto-update.yml` to use `PAT_STATUS_UPDATE` instead of `GITHUB_TOKEN`.

**Change required:**

```yaml
- name: Create PR (lane discipline)
  uses: peter-evans/create-pull-request@v6
  with:
    token: ${{ secrets.PAT_STATUS_UPDATE }}  # Use PAT instead of GITHUB_TOKEN
    branch: bots/status-auto-update
    # ... rest unchanged
```

---

## 🎯 Expected Results After PAT

✅ **Workflow runs successfully**  
✅ **PR created to `bots/status-auto-update`**  
✅ **BossCat compliance maintained:**

- Lane discipline (PR workflow)
- Kill-switch enforcement
- Budget limits
- A/B pairing

---

## 📊 Why PAT Works (GITHUB_TOKEN Doesn't)

| Token Type | Repo Settings | Org Settings | PR Creation | Result |
|------------|---------------|--------------|-------------|--------|
| `GITHUB_TOKEN` | ✅ Enabled | ✅ Enabled | ❌ Blocked | **FAILS** |
| `PAT` | N/A | N/A | ✅ Works | **SUCCESS** |

<!-- markdownlint-disable-next-line MD013 -->
**Reason:** PATs are tied to a user account and have full permissions granted by their scopes, bypassing enterprise/organization token restrictions.

---

## 🔐 Security Notes

- **Token Scope:** `repo` (full repository access)
- **Token Owner:** Should be a dedicated bot account (or trusted admin)
- **Token Storage:** Encrypted in GitHub Secrets
- **Token Rotation:** Set expiration and rotate regularly
- **BossCat Compliance:** PAT usage is acceptable for automation when `GITHUB_TOKEN` is insufficient

---

**Ready for you to create the PAT!** Once added to secrets, signal me and I'll update the workflow. 🚀

**Authority:** Cursor{Implementer}  
**Status:** Awaiting PAT creation

