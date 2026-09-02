# 🔐 GitHub App Integration Guide

**BossCat OEM Framework** - Automated PR Commenting via GitHub App

---

## Overview

The BossCat OEM framework now uses a GitHub App for automated PR commenting instead of the default `GITHUB_TOKEN`. This provides:

✅ **Enhanced permissions** - Bypass rate limits and access restrictions  
✅ **Better traceability** - Comments appear from the BossCat App, not generic bot  
✅ **Audit compliance** - All actions tracked under app installation  
✅ **Graceful fallback** - Falls back to `GITHUB_TOKEN` if app secrets are unavailable

---

## Prerequisites

1. **GitHub App created** with permissions:
   - Repository permissions:
     - Issues: Read & write
     - Pull requests: Read & write
     - Contents: Read
     - Metadata: Read

2. **App installed** on your repository/organization

3. **Secrets configured** in repository settings:
   - `BOSSCAT_APP_ID` - The application ID (numeric)
   - `BOSSCAT_APP_PRIVATE_KEY` - The private key (PEM format)

---

## Implementation Status

### ✅ Updated Workflows

The following workflows now use GitHub App authentication:

| Workflow | File | Status |
|----------|------|--------|
| IONA Gate Verification | `.github/workflows/iona-gate-verify.yml` | ⛔ RETIRED 2026-08-03 (dispatch only) |
| Boss Gate Verification | `.github/workflows/boss-gate-verify.yml` | ⛔ RETIRED 2026-08-03 (dispatch only) |
| Security Scanning | `.github/workflows/security-scan.yml` | ⛔ RETIRED 2026-08-03 (dispatch only) |
| Gitleaks Security Scan | `.github/workflows/gitleaks-security-scan.yml` | ⛔ RETIRED 2026-08-03 (dispatch only) |

As of 2026-09-02 no scheduled or PR-triggered workflow consumes the App token; the integration is
dormant (truth pass).

### Pattern Used

All workflows follow this pattern:

```yaml
steps:
  - name: Checkout repository
    uses: actions/checkout@v4
  
  # Generate GitHub App token (optional, falls back to GITHUB_TOKEN)
  - name: Generate GitHub App token
    id: bosscat-auth
    if: ${{ secrets.BOSSCAT_APP_ID && secrets.BOSSCAT_APP_PRIVATE_KEY }}
    uses: tibdex/github-app-token@v2
    with:
      app_id: ${{ secrets.BOSSCAT_APP_ID }}
      private_key: ${{ secrets.BOSSCAT_APP_PRIVATE_KEY }}
  
  # Use the app token with fallback
  - name: Comment PR with results
    if: github.event_name == 'pull_request' && always()
    uses: actions/github-script@v7
    with:
      github-token: ${{ steps.bosscat-auth.outputs.token || secrets.GITHUB_TOKEN }}
      script: |
        github.rest.issues.createComment({
          issue_number: context.issue.number,
          owner: context.repo.owner,
          repo: context.repo.repo,
          body: 'Your comment here'
        });
```

---

## Configuration Steps

### 1. Create GitHub App (if not exists)

1. Go to GitHub Settings → Developer settings → GitHub Apps
2. Click "New GitHub App"
3. Configure:
   - **App name**: `BossCat OEM Bot` (or similar)
   - **Homepage URL**: Your repository URL
   - **Webhook**: Uncheck "Active" (not needed for this use case)
   - **Permissions**:
     - Repository → Issues: Read & write
     - Repository → Pull requests: Read & write
     - Repository → Contents: Read
   - **Where can this GitHub App be installed?**: Only on this account

4. Click "Create GitHub App"
5. Note the **App ID** (shown at top of settings page)
6. Generate a **private key**:
   - Scroll to "Private keys" section
   - Click "Generate a private key"
   - Download the `.pem` file

### 2. Install the App

1. On the app settings page, click "Install App"
2. Select your organization/account
3. Choose repositories (select your repo or all repos)
4. Click "Install"

### 3. Add Secrets to Repository

1. Go to your repository → Settings → Secrets and variables → Actions
2. Add two secrets:

   **BOSSCAT_APP_ID**

   ```text
   123456  # Your app ID (numeric)
   ```

   **BOSSCAT_APP_PRIVATE_KEY**

   ```text
   -----BEGIN RSA PRIVATE KEY-----
   MIIEpAIBAAKCAQEA...
   (entire contents of the .pem file)
   ...
   -----END RSA PRIVATE KEY-----
   ```

### 4. Verify Integration

1. Create a test PR on a feature branch
2. Trigger one of the gate verification workflows
3. Check the PR comments - should appear from the GitHub App
4. Review workflow logs for "Generate GitHub App token" step

---

## Troubleshooting

### Issue: Comments still appear from `github-actions[bot]`

**Cause**: App secrets not configured or GitHub App token generation failing

**Solution**:

1. Check that both `BOSSCAT_APP_ID` and `BOSSCAT_APP_PRIVATE_KEY` are set
2. Verify the private key format (must include header/footer lines)
3. Check workflow logs for the "Generate GitHub App token" step
4. Ensure the app is installed on the repository

### Issue: Token generation fails with "App does not have access"

**Cause**: App not installed on repository or missing permissions

**Solution**:

1. Verify app is installed: Settings → GitHub Apps → Installed Apps
2. Check app permissions match requirements
3. Reinstall the app if necessary

### Issue: Rate limiting still occurs

**Cause**: Still using `GITHUB_TOKEN` (fallback mode)

**Solution**:

1. Verify secrets are correctly named (exact match required)
2. Check that `tibdex/github-app-token@v2` action runs successfully
3. Review workflow logs for authentication step

---

## Security Considerations

### Private Key Rotation

🔄 **Rotate private keys annually** or immediately if compromised:

1. GitHub App settings → Private keys
2. Click "Generate a private key"
3. Update `BOSSCAT_APP_PRIVATE_KEY` secret
4. Revoke old key after verifying new one works

### Access Control

- GitHub App has **limited scope** (only PR/issue comments)
- Cannot push code or modify repository settings
- Access can be revoked instantly by uninstalling the app

### Audit Trail

All actions performed via the GitHub App are logged:

- Repository activity logs show app actions
- Audit logs available in organization settings
- Comments clearly attributed to the app

---

## Migration Notes

### Before (Default Token)

```yaml
- name: Comment PR
  uses: actions/github-script@v7
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Limitations**:

- Rate limited (1000 requests/hour per repo)
- Generic `github-actions[bot]` attribution
- Limited permissions in some scenarios

### After (GitHub App)

```yaml
- name: Generate GitHub App token
  id: bosscat-auth
  if: ${{ secrets.BOSSCAT_APP_ID && secrets.BOSSCAT_APP_PRIVATE_KEY }}
  uses: tibdex/github-app-token@v2
  with:
    app_id: ${{ secrets.BOSSCAT_APP_ID }}
    private_key: ${{ secrets.BOSSCAT_APP_PRIVATE_KEY }}

- name: Comment PR
  uses: actions/github-script@v7
  with:
    github-token: ${{ steps.bosscat-auth.outputs.token || secrets.GITHUB_TOKEN }}
```

**Benefits**:

- Higher rate limits (5000 requests/hour per installation)
- Custom app name in comments
- Better permissions and security
- Graceful fallback if app unavailable

---

## Maintenance Schedule

| Task | Frequency | Action |
|------|-----------|--------|
| Verify app is active | Monthly | Check app installation status |
| Review app permissions | Quarterly | Ensure minimal required permissions |
| Rotate private key | Annually | Generate new key, update secret |
| Audit app actions | Monthly | Review activity logs |

---

## References

- [GitHub Apps Documentation](https://docs.github.com/en/apps)
- [tibdex/github-app-token Action](https://github.com/tibdex/github-app-token)
- [GitHub Actions Security Best Practices](https://docs.github.com/en/actions/security-guides)

---

**Last Updated**: 2025-10-07  
**Maintained By**: BossCat OEM Framework  
**Status**: Dormant — all four consumer workflows RETIRED 2026-08-03 (truth pass 2026-09-02)
