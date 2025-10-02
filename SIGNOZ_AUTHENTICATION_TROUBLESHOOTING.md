# SigNoz Authentication Troubleshooting Guide

## ✅ **Authentication Issue RESOLVED**

The SigNoz automation system is now **fully functional** with proper authentication handling.

## 🔍 **Root Cause Analysis**

### **Original Issue**
- Tests were failing because they expected URL redirects after login
- Authentication was actually **working correctly** but tests were checking wrong indicators
- SigNoz uses localStorage-based authentication (`IS_LOGGED_IN`, `AUTH_TOKEN`) rather than URL redirects

### **Key Discovery**
From the debug session, we found:
```javascript
// Authentication was successful - localStorage showed:
IS_LOGGED_IN: true
AUTH_TOKEN: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
USER_ID: 01995f8e-233c-7bea-bee3-e45f7abcba51
REFRESH_AUTH_TOKEN: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 🛠️ **Solution Implemented**

### **1. Updated Authentication Logic**
```typescript
// Check authentication state via localStorage instead of URL
const isLoggedIn = await page.evaluate(() => {
  return localStorage.getItem('IS_LOGGED_IN') === 'true';
});

// Wait for authentication completion
await page.waitForFunction(() => {
  return localStorage.getItem('IS_LOGGED_IN') === 'true';
}, { timeout: 30000 });
```

### **2. Fixed Test Expectations**
- Changed from URL-based validation to localStorage-based validation
- Tests now verify `IS_LOGGED_IN` and `AUTH_TOKEN` presence
- More reliable and accurate authentication verification

## 📊 **Current Authentication Setup**

### **SigNoz Configuration**
- **JWT Secret**: `local-signoz-jwt-secret-rotate` (from docker-compose)
- **Authentication Method**: Email/Password with multi-step login
- **Session Storage**: localStorage-based (not cookie-based)
- **Credentials**: `fubumaki@gmail.com` / `X+4E*Cn*dpq4p2C2`

### **Authentication Flow**
1. **Email Input**: `input[type='email']`
2. **Next Button**: `button` with text matching `/next/i`
3. **Password Input**: `input[type='password']`
4. **Submit Button**: `button[type='submit']`
5. **Success Indicator**: `localStorage.getItem('IS_LOGGED_IN') === 'true'`

## ✅ **Verification Results**

### **All Tests Now Pass**
```bash
✅ SigNoz health check
✅ Authentication and basic navigation  
✅ Logs page accessibility
✅ Alerts page accessibility
✅ Logs search functionality
```

### **Success Metrics**
- **Health Check**: ✅ `{"status":"ok"}`
- **Authentication**: ✅ localStorage shows `IS_LOGGED_IN: true`
- **Navigation**: ✅ Can access `/dashboards`, `/logs`, `/alerts/rules`
- **Token Presence**: ✅ `AUTH_TOKEN` present in localStorage
- **Automation Script**: ✅ Complete workflow working

## 🔧 **Troubleshooting Tips**

### **If Authentication Fails Again**
1. **Check localStorage**: Verify `IS_LOGGED_IN` and `AUTH_TOKEN` presence
2. **Verify Credentials**: Ensure correct email/password format
3. **Check SigNoz Logs**: Look for authentication errors in `docker logs signoz`
4. **JWT Secret**: Verify `SIGNOZ_JWT_SECRET` is set correctly

### **Common Issues**
- **"invalid email format"**: Check email format in login request
- **Session timeout**: SigNoz may require re-authentication
- **Network issues**: Verify SigNoz is reachable at `http://localhost:8080`

## 🎯 **Production Recommendations**

### **For CI/CD**
- Use environment variables for credentials
- Implement retry logic for authentication failures
- Monitor authentication success rates

### **For Monitoring**
- Track authentication token expiry
- Monitor localStorage state in browser
- Set up alerts for authentication failures

## 📝 **Files Updated**

- ✅ `tests/signoz.final.spec.ts` - Fixed authentication logic
- ✅ `scripts/automate-signoz-setup.ps1` - Working automation script
- ✅ `playwright.signoz.config.ts` - Dedicated SigNoz configuration
- ✅ `package.json` - Updated scripts

## 🎉 **Status: RESOLVED**

The SigNoz authentication system is now **fully operational** and ready for production use. All automation commands complete successfully with proper authentication handling.
