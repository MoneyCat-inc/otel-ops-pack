# 🔍 Reviewer Checklist — Observability Verification

## Quick Review Process

### 1. Check Job Summary
- ✅ Look for "🔍 Observability Verify — Job Summary" in the workflow run
- ✅ Verify "Verification result: all checks passed" 
- ✅ Click the **Run artifacts** link to access full evidence files

### 2. Review Evidence Files
**In the artifacts download:**
- ✅ `verify-run.txt` ends with "== Verification complete: all checks passed =="
- ✅ `api-sample.json` contains recent synthetic data with redaction (`Bearer ***`, `pwd=***`)

### 3. Verify API Integration
**Look for these indicators:**
- ✅ API verification enabled (not skipped due to missing token)
- ✅ Redaction working: `auth_header: "Bearer ***"` and `secret_example: "pwd=***"`
- ✅ Recent synthetic data found (timestamp within last 15 minutes)

### 4. Check CI Integration
**Verify these components:**
- ✅ Windows Collector: RUNNING, health endpoint 200
- ✅ SigNoz Stack: All containers UP, ClickHouse schema present  
- ✅ Synthetic Dataset: Recent logs found, API verification successful
- ✅ Canary: End-to-end pipeline verified with unique GUID

## 🚨 Red Flags

**Fail the review if you see:**
- ❌ "Verification result: did not find success line"
- ❌ API verification skipped due to authentication
- ❌ No redaction in API response (tokens exposed)
- ❌ No recent synthetic data (all timestamps > 15 minutes old)
- ❌ Any component showing FAIL status

## ✅ Approval Criteria

**Approve if:**
- ✅ All verification components show PASS status
- ✅ API verification completed successfully with redaction
- ✅ Recent synthetic data confirmed in API response
- ✅ No security concerns (tokens properly redacted)

## 🔗 Useful Links

- **Run artifacts:** Click the link in the job summary
- **Full verification script:** `scripts/verify-integration.ps1`
- **Evidence capture tool:** `artifacts/capture-evidence.ps1`
- **Setup guide:** `README.md` (API Token Setup section)

---

**Note:** This checklist ensures complete observability validation including security testing via redaction verification.