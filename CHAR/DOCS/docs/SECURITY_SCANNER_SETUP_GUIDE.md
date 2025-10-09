# Security Scanner Setup Guide

**MoneyCat Inc · Resonai [OTel] · Security Scanner Configuration**  
**Issued by:** BossCat OEM (Executive Overseer Manager)

---

## 🎯 Purpose

This guide documents the setup process for security scanners used in the CI/CD pipeline to ensure all security checks pass and maintain compliance with BossCat standards.

---

## 🔧 Required Security Scanners

### 1. **Snyk Security Scanner**
- **Purpose:** Vulnerability scanning for dependencies
- **Required Secret:** `SNYK_TOKEN`
- **Setup Process:**
  1. Sign up at [snyk.io](https://snyk.io)
  2. Go to Account Settings → API Token
  3. Generate new token
  4. Add to GitHub Secrets as `SNYK_TOKEN`
- **Status:** ❌ Missing token (currently empty)

### 2. **APIsec Scanner**
- **Purpose:** API security testing
- **Required Secrets:** `APISEC_USERNAME`, `APISEC_PASSWORD`
- **Setup Process:**
  1. Sign up at [apisec.cloud.ai](https://apisec.cloud.ai)
  2. Create account and note credentials
  3. Add to GitHub Secrets:
     - `APISEC_USERNAME`: Your APIsec username
     - `APISEC_PASSWORD`: Your APIsec password
- **Status:** ❌ Missing credentials (currently empty)

### 3. **GitLeaks Scanner**
- **Purpose:** Secret detection and prevention
- **Required Secret:** `GITLEAKS_LICENSE`
- **Setup Process:**
  1. Visit [gitleaks.io](https://gitleaks.io)
  2. Obtain license key
  3. Add to GitHub Secrets as `GITLEAKS_LICENSE`
- **Status:** ❌ Missing license (not configured)

### 4. **Fortify AST Scanner**
- **Purpose:** Application Security Testing
- **Required Secrets:** May need Fortify credentials
- **Setup Process:**
  1. Verify if Fortify AST requires additional credentials
  2. Check Fortify documentation for API keys
  3. Add required secrets if needed
- **Status:** ✅ Appears to be working (needs verification)

---

## 🚀 Setup Instructions

### Step 1: Access GitHub Secrets
1. Navigate to repository settings
2. Go to "Secrets and variables" → "Actions"
3. Click "New repository secret"

### Step 2: Add Required Secrets
```bash
# Snyk Token
SNYK_TOKEN = <your-snyk-token>

# APIsec Credentials
APISEC_USERNAME = <your-apisec-username>
APISEC_PASSWORD = <your-apisec-password>

# GitLeaks License
GITLEAKS_LICENSE = <your-gitleaks-license>
```

### Step 3: Verify Configuration
1. Run a test workflow to verify secrets are accessible
2. Check CI logs for successful authentication
3. Confirm all security scanners pass

---

## 🔍 Current CI Status

**Failing Scanners:**
- ❌ Snyk: Missing `SNYK_TOKEN`
- ❌ APIsec: Missing `APISEC_USERNAME`, `APISEC_PASSWORD`
- ❌ GitLeaks: Missing `GITLEAKS_LICENSE`

**Working Scanners:**
- ✅ CodeQL: No credentials needed
- ✅ PSScriptAnalyzer: No credentials needed
- ✅ OSV-Scanner: No credentials needed
- ✅ GitLeaks (basic): Working without license
- ✅ Fortify AST: Appears functional

---

## 📋 Verification Checklist

- [ ] All required secrets added to GitHub repository
- [ ] Test workflow run with new secrets
- [ ] Verify all security scanners pass
- [ ] Document any additional configuration needed
- [ ] Update this guide with any changes

---

## 🛠️ Troubleshooting

### Common Issues:
1. **"Resource not accessible by integration"**
   - Check if secrets are properly configured
   - Verify repository permissions

2. **"Authentication failed"**
   - Double-check secret values
   - Ensure no extra spaces or characters

3. **"License not found"**
   - Verify license key is correct
   - Check if license is active

### Support Resources:
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Snyk Documentation](https://docs.snyk.io/)
- [APIsec Documentation](https://docs.apisec.cloud.ai/)
- [GitLeaks Documentation](https://github.com/zricethezav/gitleaks)

---

## 📊 Expected Results

After proper configuration:
- All security scanners should pass in CI
- No more "missing credentials" errors
- Full compliance with BossCat security standards
- Automated security scanning on every PR

---

🐾 **End of Security Scanner Setup Guide.**

*This guide should be updated whenever new security scanners are added or configuration changes.*
