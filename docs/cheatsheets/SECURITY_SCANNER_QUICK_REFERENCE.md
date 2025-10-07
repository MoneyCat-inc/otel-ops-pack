# Security Scanner Quick Reference

## 🔑 Required Secrets

| Scanner | Secret Name | Status | Action Needed |
|---------|-------------|---------|---------------|
| Snyk | `SNYK_TOKEN` | ❌ Missing | Get from snyk.io → Account Settings → API Token |
| APIsec | `APISEC_USERNAME` | ❌ Missing | Get from apisec.cloud.ai account |
| APIsec | `APISEC_PASSWORD` | ❌ Missing | Get from apisec.cloud.ai account |
| GitLeaks | `GITLEAKS_LICENSE` | ❌ Missing | Get from gitleaks.io license |

## 🚀 Quick Setup Commands

```bash
# Check current secrets
gh secret list

# Add secrets (replace with actual values)
gh secret set SNYK_TOKEN --body="your-snyk-token"
gh secret set APISEC_USERNAME --body="your-username"
gh secret set APISEC_PASSWORD --body="your-password"
gh secret set GITLEAKS_LICENSE --body="your-license"

# Test workflow
gh workflow run "Full CI & Gate Verification"
```

## 📊 Current CI Status
- ✅ CodeQL, PSScriptAnalyzer, OSV-Scanner: Working
- ❌ Snyk, APIsec, GitLeaks: Need credentials
- ✅ Fortify AST: Appears functional

## 🎯 Next Steps
1. Add missing secrets to GitHub repository
2. Test with workflow run
3. Verify all scanners pass
4. Monitor nightly exports complete
