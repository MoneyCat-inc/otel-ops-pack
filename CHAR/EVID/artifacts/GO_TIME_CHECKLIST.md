# 🚀 Go-Time Checklist — API Token Verification

## 5-Step Process

### 1. Set Token (Temporary)
```powershell
$env:SIGNOZ_API_TOKEN = "<your-real-token>"
```

### 2. Capture Evidence
```powershell
pwsh -File .\artifacts\capture-evidence.ps1
```

### 3. Skim Outputs
**Check `artifacts\verify-run.txt`:**
- ✅ Ends with: `== Verification complete: all checks passed ==`
- ✅ Shows: API verification successful (not skipped)

**Check `artifacts\api-sample.json`:**
- ✅ Contains recent row with `synthetic_id`
- ✅ Shows redaction: `Bearer ***` and `pwd=***`

### 4. Copy PR Comment
```powershell
Get-Content .\artifacts\PR_COMMENT_TEMPLATE.md
```
*Paste this into your PR comment and attach the two artifact files*

### 5. Commit Safely
```powershell
# Add only the safe files (not tokens or API responses)
git add .gitignore .github/workflows/ci-verify.yml artifacts/capture-evidence.ps1 artifacts/PR_COMMENT_TEMPLATE.md artifacts/INTEGRATION_SUMMARY.md README.md scripts/ci-verify.ps1

# Verify no sensitive data
git status
git diff --cached
```

## 🎯 Success Criteria

**Local Verification:**
- ✅ All 5 components PASS
- ✅ API verification enabled (not skipped)
- ✅ Redaction confirmed in API response

**CI Integration:**
- ✅ GitHub secret `SIGNOZ_API_TOKEN` configured
- ✅ Workflow uploads artifacts automatically
- ✅ PR comments include verification evidence

## 🆘 If Something Fails

**Send me:**
1. Last 10 lines of `artifacts\verify-run.txt`
2. The status line your script prints
3. Any error messages from the API probe

**Common Issues:**
- **401 Unauthorized**: Check token format and permissions
- **No synthetic data**: Ensure synthetic logs are recent (< 60 minutes)
- **Connection refused**: Verify SigNoz is running on localhost:8080

---

**Ready to go!** 🚀
