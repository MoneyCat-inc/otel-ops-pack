# SigNoz Credential Management Guide

## 🔐 **Repository Secrets Configuration**

The SigNoz automation system requires two repository secrets to be configured:

### **Required Secrets**

1. **SIGNOZ_USER** - SigNoz login email/username
2. **SIGNOZ_PASS** - SigNoz login password

### **Current Configuration**
- **User**: `fubumaki@gmail.com`
- **Password**: `X+4E*Cn*dpq4p2C2`

## 🔄 **Credential Refresh Process**

### **When to Refresh Credentials**

Credentials should be refreshed when:
- SigNoz administrators rotate account passwords
- Security policies require regular credential updates
- Account access is compromised or suspected
- SigNoz infrastructure is updated with new authentication requirements

### **Step-by-Step Refresh Process**

#### **1. Update Repository Secrets**

Navigate to your GitHub repository settings:

```bash
# GitHub Web Interface
https://github.com/[ORG]/[REPO]/settings/secrets/actions
```

Or use GitHub CLI:
```bash
# Update SIGNOZ_USER
gh secret set SIGNOZ_USER --body "new-email@example.com"

# Update SIGNOZ_PASS  
gh secret set SIGNOZ_PASS --body "new-secure-password"
```

#### **2. Verify Credential Update**

Test the updated credentials locally:

```bash
# Set environment variables for testing
export SIGNOZ_USER="new-email@example.com"
export SIGNOZ_PASS="new-secure-password"

# Run SigNoz automation tests
pnpm run test:signoz

# Run complete automation suite
pnpm run automate:signoz
```

#### **3. Validate CI/CD Integration**

Trigger a test workflow to ensure CI/CD works with new credentials:

```bash
# Trigger workflow manually
gh workflow run "SigNoz Automation" --ref main

# Or push a test commit
git commit --allow-empty -m "test: verify SigNoz credentials"
git push origin main
```

#### **4. Monitor Automation Health**

Check that all automation continues to work:

- ✅ Nightly automation runs complete successfully
- ✅ Pull request tests pass
- ✅ Manual workflow triggers work
- ✅ No authentication errors in logs

## 🚨 **Emergency Credential Rotation**

### **If Credentials Are Compromised**

1. **Immediate Action**:
   ```bash
   # Disable automation temporarily
   gh secret set SIGNOZ_USER --body "DISABLED"
   gh secret set SIGNOZ_PASS --body "DISABLED"
   ```

2. **Generate New Credentials**:
   - Contact SigNoz administrator for new account
   - Or create new service account if self-hosted

3. **Update and Test**:
   ```bash
   # Update with new credentials
   gh secret set SIGNOZ_USER --body "new-account@example.com"
   gh secret set SIGNOZ_PASS --body "new-secure-password"
   
   # Test immediately
   pnpm run test:signoz
   ```

## 🔧 **Local Development Setup**

### **Environment Variables**

For local development, set these environment variables:

```bash
# .env.local or shell environment
export SIGNOZ_USER="fubumaki@gmail.com"
export SIGNOZ_PASS="X+4E*Cn*dpq4p2C2"
export SIGNOZ_URL="http://localhost:8080"
```

### **Testing Credentials Locally**

```bash
# Quick credential test
pnpm run test:signoz

# Full automation test
pnpm run automate:signoz

# Debug authentication
pnpm run test:signoz:debug
```

## 📋 **Credential Monitoring**

### **Automated Monitoring**

The CI/CD pipeline automatically monitors credential health:

- **Nightly Tests**: Scheduled at 2 AM UTC daily
- **Pull Request Tests**: Run on every PR
- **Manual Triggers**: Available via GitHub Actions UI

### **Failure Indicators**

Watch for these signs of credential issues:

- ❌ Authentication tests failing
- ❌ "invalid email format" errors in logs
- ❌ "unauthorized" responses from SigNoz API
- ❌ Tests redirecting to login page repeatedly

### **Success Indicators**

Healthy credentials show:

- ✅ All authentication tests passing
- ✅ localStorage shows `IS_LOGGED_IN: true`
- ✅ `AUTH_TOKEN` present in browser storage
- ✅ Can access dashboards, logs, and alerts

## 🔍 **Troubleshooting**

### **Common Issues**

#### **"Invalid Email Format" Error**
```bash
# Check email format in SigNoz logs
docker logs signoz | grep "invalid email format"

# Verify email is properly formatted
echo $SIGNOZ_USER
```

#### **Authentication Timeout**
```bash
# Check SigNoz health
curl -f http://localhost:8080/api/v1/health

# Verify SigNoz is running
docker ps | grep signoz
```

#### **Credentials Not Working**
```bash
# Test credentials manually
curl -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":"'$SIGNOZ_USER'","password":"'$SIGNOZ_PASS'"}'
```

### **Debug Commands**

```bash
# Check SigNoz logs
docker logs signoz --tail 50

# Check authentication flow
pnpm exec playwright test tests/signoz.final.spec.ts --debug

# View Playwright traces
pnpm exec playwright show-trace test-results/*/trace.zip
```

## 📝 **Documentation Updates**

When credentials are updated, also update:

- ✅ This credential management guide
- ✅ `docs/SIGNOZ_AUTOMATION_SETUP.md`
- ✅ `SIGNOZ_AUTHENTICATION_TROUBLESHOOTING.md`
- ✅ Team documentation (if applicable)

## 🔐 **Security Best Practices**

### **Credential Security**

- **Never commit credentials** to version control
- **Use repository secrets** for CI/CD environments
- **Rotate credentials regularly** (quarterly recommended)
- **Use strong passwords** with special characters
- **Monitor credential usage** in SigNoz audit logs

### **Access Control**

- **Limit credential access** to necessary team members
- **Use service accounts** instead of personal accounts when possible
- **Enable MFA** on SigNoz accounts if available
- **Regular access reviews** to remove unused accounts

## 📞 **Support Contacts**

### **For Credential Issues**

- **SigNoz Admin**: Contact your SigNoz administrator
- **DevOps Team**: For CI/CD integration issues
- **Security Team**: For credential compromise concerns

### **Emergency Contacts**

- **On-call Engineer**: For urgent automation failures
- **Security Incident**: For suspected credential compromise

---

## 🎯 **Quick Reference**

### **Update Credentials**
```bash
gh secret set SIGNOZ_USER --body "new-email@example.com"
gh secret set SIGNOZ_PASS --body "new-password"
```

### **Test Credentials**
```bash
pnpm run test:signoz
```

### **Check Status**
```bash
pnpm run automate:signoz
```

### **View Logs**
```bash
docker logs signoz --tail 50
```
