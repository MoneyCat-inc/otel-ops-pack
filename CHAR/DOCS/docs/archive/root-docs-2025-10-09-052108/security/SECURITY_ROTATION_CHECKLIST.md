# 🔑 SigNoz API Key Rotation Checklist

**Date**: 2025-10-07  
**Incident**: IONA-GATE-002 Security Remediation  
**Old Key**: `[REDACTED-old-SigNoz-key-rotated-2025-10-07]` ⚠️ **REVOKE THIS**  
**Status**: 🔄 **ROTATION IN PROGRESS**

---

## ⚠️ MANUAL ACTION REQUIRED

You must rotate the SigNoz API key to complete the security remediation.

---

## 🔐 Step 1: Rotate the Key

### Option A: Via SigNoz UI (Recommended)
```
1. Open: http://localhost:8080
2. Navigate to: Settings → API Keys
3. Find existing key: [REDACTED-old-SigNoz-key-rotated-2025-10-07]
4. Click: "Revoke" or "Delete"
5. Click: "Generate New API Key"
6. Copy the new key immediately (shown only once!)
```

### Option B: Via SigNoz API
```bash
# Revoke old key
curl -X DELETE http://localhost:8080/api/v1/auth/api-keys \
  -H "Authorization: Bearer [REDACTED-old-SigNoz-key-rotated-2025-10-07]" \
  -H "Content-Type: application/json"

# Generate new key
curl -X POST http://localhost:8080/api/v1/auth/api-keys \
  -H "Authorization: Bearer <temp-access-token>" \
  -H "Content-Type: application/json" \
  -d '{"name": "iona-app-key", "role": "admin"}'
```

---

## 🔐 Step 2: Store the New Key Securely

### Local Development
```powershell
# Set in current session
$env:SIGNOZ_API_KEY = '<NEW-KEY-HERE>'

# Persist for your user account
[Environment]::SetEnvironmentVariable('SIGNOZ_API_KEY','<NEW-KEY-HERE>','User')

# Verify it's set
$env:SIGNOZ_API_KEY
```

### GitHub Actions (CI/CD)
```
1. Go to: https://github.com/MoneyCat-inc/otel-ops-pack/settings/secrets/actions
2. Click: "New repository secret"
3. Name: SIGNOZ_API_KEY
4. Value: <NEW-KEY-HERE>
5. Click: "Add secret"
```

### For Team Members
```powershell
# Each team member should set locally:
$env:SIGNOZ_API_KEY = '<NEW-KEY-HERE>'
[Environment]::SetEnvironmentVariable('SIGNOZ_API_KEY','<NEW-KEY>','User')
```

**⚠️ NEVER commit the new key to git!**

---

## ✅ Step 3: Verify the Rotation

### Test Local Access
```powershell
# Test SigNoz API with new key
$headers = @{
    "Authorization" = "Bearer $env:SIGNOZ_API_KEY"
    "Content-Type" = "application/json"
}
Invoke-RestMethod -Uri "http://localhost:8080/api/v1/version" -Headers $headers
```

### Test OTLP Emission
```powershell
# Set OTLP environment
$env:OTEL_EXPORTER_OTLP_ENDPOINT = 'http://127.0.0.1:5318'
$env:OTEL_SERVICE_NAME = 'iona-app'

# Test synthetic span emitter
pnpm emit
# Expected: Exit 0 (success)

# Run full gate verification
pwsh -File scripts/verify-iona-gate.ps1
# Expected: PASSED with 18 successes
```

### Verify in SigNoz UI
```
1. Open: http://localhost:8080
2. Navigate to: Traces → Explorer
3. Filter: service.name = "iona-app"
4. Expected: See iona.boot and iona.synthetic spans
5. Verify: Spans are being ingested with new key
```

---

## 🔍 Step 4: Security Verification

### Run Local Secret Scan
```powershell
# Install gitleaks if needed
choco install gitleaks -y

# Scan repository
gitleaks detect --redact --verbose

# Expected: "No leaks found"
```

### Verify GitGuardian Re-scan
```
1. Wait ~5 minutes for GitGuardian to re-scan
2. Check PR: https://github.com/MoneyCat-inc/otel-ops-pack/pull/<PR-NUMBER>
3. Expected: "No secrets detected" or alert cleared
```

### Check CI Pipeline
```
1. Go to: Actions tab on GitHub
2. Find: "Security Scan" workflow
3. Expected: All jobs passing (green checkmarks)
```

---

## 📝 Step 5: Update Documentation

### Mark Rotation Complete
```powershell
# Update this file
$content = Get-Content SECURITY_ROTATION_CHECKLIST.md -Raw
$content = $content -replace 'Status.*ROTATION IN PROGRESS', 'Status**: ✅ **ROTATION COMPLETE**'
$content | Set-Content SECURITY_ROTATION_CHECKLIST.md

# Update security remediation report
$report = Get-Content SECURITY_REMEDIATION.md -Raw
$report = $report -replace 'INCIDENT CLOSED', 'INCIDENT CLOSED - KEY ROTATED'
$report | Set-Content SECURITY_REMEDIATION.md

# Commit the updates
git add SECURITY_ROTATION_CHECKLIST.md SECURITY_REMEDIATION.md
git commit -m "docs(security): confirm SigNoz API key rotation complete"
git push
```

---

## 📋 Completion Checklist

Mark each item as you complete it:

### Rotation
- [ ] Old key revoked in SigNoz
- [ ] New key generated
- [ ] New key stored in local environment variables
- [ ] New key added to GitHub Secrets
- [ ] Team members notified of new key

### Verification
- [ ] Local SigNoz API access works with new key
- [ ] `pnpm emit` succeeds
- [ ] `scripts/verify-iona-gate.ps1` passes
- [ ] Spans visible in SigNoz UI
- [ ] Gitleaks scan shows no secrets
- [ ] GitGuardian alert cleared
- [ ] CI Security Scan workflow passing

### Documentation
- [ ] SECURITY_ROTATION_CHECKLIST.md updated (this file)
- [ ] SECURITY_REMEDIATION.md updated
- [ ] Changes committed and pushed
- [ ] PR comment posted with confirmation

---

## 🎯 Final PR Comment Template

Once all checklist items are complete, post this on the PR:

```markdown
## 🔒 Security Remediation Complete - Key Rotated ✅

**Incident**: GitGuardian detected exposed SigNoz API key  
**Status**: ✅ **FULLY REMEDIATED**

### Actions Completed:
1. ✅ **Exposed secret removed** - `env.template` contains placeholder only
2. ✅ **Key rotation complete** - Old key revoked, new key in use
3. ✅ **Security hardening** - `.gitleaks.toml`, enhanced `.gitignore`, pre-commit hook, CI workflow
4. ✅ **Full verification** - Local and CI tests passing
5. ✅ **GitGuardian re-scan** - Alert cleared, no secrets detected

### Evidence:
- ✅ `gitleaks detect` - No leaks found
- ✅ `pnpm emit` - Success (exit 0)
- ✅ Gate verification - PASSED (18 successes)
- ✅ SigNoz spans - Visible with new key
- ✅ CI Security Scan - All jobs passing

### Preventive Measures Active:
- 🛡️ Pre-commit secret scanning
- 🛡️ CI secret scan workflow
- 🛡️ Template validation in CI
- 🛡️ Enhanced .gitignore
- 🛡️ Comprehensive incident documentation

**Commit**: 9254792 (remediation) + [rotation confirmation commit]  
**Risk Level**: HIGH → **RESOLVED**

---

CI is green and all checks are satisfied.
**@cat ready-for-gate** 🚪✅

Evidence:
- Native ESM NodeSDK emitter (scripts/emit-synthetic-span.mjs)
- Gate verifier + diagnostics shell ASCII-aligned
- Playwright diagnostics suite: PASS
- Artifacts confirmed (iona-home.png, iona-practice.png, iona-memx-labs.png, iona-diagnostics.png)
- SigNoz endpoint reachable; spans iona.boot → iona.synthetic present
- Security incident remediated; key rotated; hardening complete
```

---

## 🔗 References

- **Incident Report**: `SECURITY_REMEDIATION.md`
- **Gitleaks Config**: `.gitleaks.toml`
- **CI Workflow**: `.github/workflows/security-scan.yml`
- **SigNoz API Keys**: http://localhost:8080/settings/api-keys

---

## 📞 Questions?

If you encounter any issues during rotation:
1. Check SigNoz logs: `docker-compose logs signoz`
2. Verify SigNoz is running: `curl http://localhost:8080/api/v1/health`
3. Consult: `SECURITY_REMEDIATION.md` for full incident context

---

**Last Updated**: 2025-10-07  
**Next Action**: Follow Steps 1-5 above to complete rotation

