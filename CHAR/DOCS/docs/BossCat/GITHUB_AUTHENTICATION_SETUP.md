# GitHub Authentication Setup for BossCat CI/CD

**Date**: 2025-10-07  
**Status**: ✅ READY FOR IMPLEMENTATION  
**Framework**: BossCat Gating Compliance

---

## 🔐 Overview

This document outlines the secure authentication methods for automated access to GitHub repositories within the BossCat gating framework. **Personal Access Tokens (PATs) should NOT be used or shared** as they are essentially passwords and pose security risks.

---

## 🎯 Recommended Authentication Methods

### Method 1: GitHub App (Recommended)

**Best for**: Fine-grained permissions, multiple repositories, organization-wide automation

#### Advantages
✅ Short-lived installation tokens (1 hour expiry)  
✅ Fine-grained permissions per repository  
✅ Audit trail of all actions  
✅ Can be installed organization-wide  
✅ No user association required  

#### Setup Steps

1. **Create GitHub App**
   ```bash
   # Navigate to GitHub Settings → Developer settings → GitHub Apps
   # https://github.com/settings/apps/new
   ```

2. **Configure App Permissions**
   - **Repository permissions**:
     - Contents: Read & Write (for commits)
     - Pull requests: Read & Write (for comments)
     - Issues: Read & Write (for gate reporting)
     - Workflows: Read & Write (for CI/CD)
   - **Organization permissions** (optional):
     - Members: Read (for team assignments)

3. **Generate Private Key**
   ```bash
   # In GitHub App settings, generate a private key
   # Download the .pem file securely
   # Store in secure location (e.g., GitHub Secrets)
   ```

4. **Install App on Repository**
   ```bash
   # Install the app on specific repositories
   # Note the App ID and Installation ID
   ```

5. **Configure in CI/CD**
   ```yaml
   # .github/workflows/example.yml
   - name: Generate GitHub App Token
     id: generate-token
     uses: actions/create-github-app-token@v1
     with:
       app-id: ${{ secrets.BOSSCAT_APP_ID }}
       private-key: ${{ secrets.BOSSCAT_APP_PRIVATE_KEY }}
   
   - name: Use token
     run: |
       git config user.name "BossCat OEM Bot"
       git config user.email "bosscat-oem@noreply.github.com"
       # Token available as: ${{ steps.generate-token.outputs.token }}
   ```

6. **Add Secrets to GitHub**
   ```bash
   # Repository Settings → Secrets and variables → Actions
   # Add:
   #   - BOSSCAT_APP_ID (the GitHub App ID)
   #   - BOSSCAT_APP_PRIVATE_KEY (contents of the .pem file)
   ```

---

### Method 2: Deploy Keys (Alternative)

**Best for**: Single repository, read-only or write access, simpler setup

#### Advantages
✅ Repository-specific (isolated security)  
✅ Can grant write access if needed  
✅ No expiration (persistent)  
✅ Simple to set up  

#### Disadvantages
⚠️ Limited to single repository  
⚠️ Cannot comment on PRs/issues  
⚠️ No fine-grained permissions  

#### Setup Steps

1. **Generate SSH Key Pair**
   ```bash
   # On your local machine or CI runner
   ssh-keygen -t ed25519 -C "bosscat-deploy-key" -f ~/.ssh/bosscat_deploy_key
   # Do NOT set a passphrase for automated use
   ```

2. **Add Deploy Key to Repository**
   ```bash
   # Repository Settings → Deploy keys → Add deploy key
   # Title: "BossCat CI/CD Deploy Key"
   # Key: <contents of bosscat_deploy_key.pub>
   # ✅ Check "Allow write access" if needed
   ```

3. **Configure in CI/CD**
   ```yaml
   # .github/workflows/example.yml
   - name: Setup SSH
     run: |
       mkdir -p ~/.ssh
       echo "${{ secrets.BOSSCAT_DEPLOY_KEY }}" > ~/.ssh/bosscat_deploy_key
       chmod 600 ~/.ssh/bosscat_deploy_key
       ssh-keyscan github.com >> ~/.ssh/known_hosts
   
   - name: Clone with deploy key
     run: |
       GIT_SSH_COMMAND="ssh -i ~/.ssh/bosscat_deploy_key" git clone git@github.com:MoneyCat-inc/otel-ops-pack.git
   ```

4. **Add Private Key as Secret**
   ```bash
   # Repository Settings → Secrets and variables → Actions
   # Name: BOSSCAT_DEPLOY_KEY
   # Value: <contents of bosscat_deploy_key (private key)>
   ```

---

### Method 3: Machine User (Not Recommended)

**Best for**: Organizations that cannot use GitHub Apps

#### Disadvantages
⚠️ Requires dedicated GitHub account (consumes license)  
⚠️ Uses PAT (long-lived token)  
⚠️ Less audit visibility  
⚠️ Requires manual token rotation  

#### If You Must Use This Method

1. Create dedicated GitHub account (`bosscat-ci-bot`)
2. Add to organization as member
3. Generate PAT with minimal scopes:
   - `repo` (full control of private repositories)
   - `workflow` (update GitHub Actions workflows)
4. Store PAT as secret: `BOSSCAT_MACHINE_USER_TOKEN`
5. **Rotate token every 90 days**

---

## 🛡️ Security Best Practices

### DO ✅
- Use GitHub Apps for organization-wide automation
- Use deploy keys for single-repository access
- Store all credentials in GitHub Secrets
- Rotate credentials regularly (quarterly)
- Use least-privilege permissions
- Monitor audit logs for suspicious activity
- Document which credentials are used where

### DON'T ❌
- Share PATs in chat, email, or code
- Commit private keys to version control
- Use personal PATs for automation
- Grant excessive permissions
- Reuse credentials across repositories
- Store credentials in plaintext

---

## 📋 Implementation Checklist

For **otel-ops-pack** and **IONA** repositories:

- [ ] **Choose authentication method** (GitHub App recommended)
- [ ] **Create GitHub App** (if using Method 1)
  - [ ] Configure permissions
  - [ ] Generate private key
  - [ ] Install on repository
- [ ] **Generate deploy keys** (if using Method 2)
  - [ ] Add public key to repository
  - [ ] Store private key as secret
- [ ] **Update CI/CD workflows**
  - [ ] Replace `${{ secrets.GITHUB_TOKEN }}` with App token where needed
  - [ ] Configure git identity for commits
- [ ] **Test authentication**
  - [ ] Run gate verification workflow
  - [ ] Verify PR comments work
  - [ ] Verify dashboard export commits work
- [ ] **Document credentials**
  - [ ] Update this doc with App ID / installation details
  - [ ] Add rotation schedule to calendar
- [ ] **Remove any PATs**
  - [ ] Audit repository for hardcoded tokens
  - [ ] Run Gitleaks scan
  - [ ] Rotate any exposed credentials

---

## 🔄 Token Rotation Schedule

| Credential Type | Rotation Frequency | Next Rotation |
|-----------------|-------------------|---------------|
| GitHub App Private Key | Annually | 2026-10-07 |
| Deploy Key | Annually | 2026-10-07 |
| Machine User PAT | Quarterly | 2026-01-07 |

---

## 🧪 Testing Authentication

### Test GitHub App Token Generation
```bash
# In your workflow, add a test step:
- name: Test GitHub App authentication
  run: |
    echo "Token generated: ${{ steps.generate-token.outputs.token != '' }}"
    gh api user
  env:
    GH_TOKEN: ${{ steps.generate-token.outputs.token }}
```

### Test Deploy Key Access
```bash
# Locally:
GIT_SSH_COMMAND="ssh -i ~/.ssh/bosscat_deploy_key -v" git ls-remote git@github.com:MoneyCat-inc/otel-ops-pack.git
```

---

## 📞 Troubleshooting

### "Resource not accessible by integration"
- **Cause**: GitHub App doesn't have required permissions
- **Solution**: Update app permissions in GitHub App settings

### "Permission denied (publickey)"
- **Cause**: Deploy key not configured correctly
- **Solution**: Verify public key is added to repository, private key is in secrets

### "Bad credentials"
- **Cause**: Token expired or invalid
- **Solution**: Regenerate GitHub App private key or deploy key

---

## 📚 References

- [GitHub Apps Documentation](https://docs.github.com/en/apps)
- [Managing Deploy Keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys)
- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

## ✅ Sign-off

**Prepared by**: Cursor Implementer  
**Reviewed by**: BossCat OEM  
**Status**: Ready for Implementation  
**Framework**: BossCat Gating Compliance

---

**End of GitHub Authentication Setup Guide**

