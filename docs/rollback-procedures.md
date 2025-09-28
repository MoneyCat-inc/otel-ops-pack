# 🚨 Emergency Rollback Procedures

## 🎯 **Overview**

This document provides step-by-step procedures for rolling back the C8 Beta Launch features in emergency situations. All procedures are designed to be executed quickly and safely while preserving user data and system stability.

## ⚡ **Immediate Rollback (Emergency)**

### **Scenario**: Critical bug or security issue requiring immediate feature disable

**Time to Execute**: < 2 minutes

**Steps**:
1. **Disable Cohort Flags Immediately**
   ```bash
   # Set environment variables to disable all cohort features
   export NEXT_PUBLIC_COHORT_ENABLED=0
   export NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY=0
   export NEXT_PUBLIC_COHORT_EVENT_SUMMARY=0
   
   # Restart development server
   pnpm dev
   ```

2. **Verify Rollback**
   ```bash
   # Check that cohort features are disabled
   curl -s http://localhost:3000/api/health | grep -q "cohort_enabled.*false"
   ```

3. **Notify Stakeholders**
   - Update status in TASKS.md
   - Send emergency notification
   - Document incident in ECRR report

## 🔄 **Code Rollback (Git)**

### **Scenario**: Need to revert to previous stable version

**Time to Execute**: < 5 minutes

**Steps**:
1. **Identify Rollback Point**
   ```bash
   # Find commit before C1-C4 implementation
   git log --oneline -10
   # Look for commit like "Pre-cohort implementation" or similar
   ```

2. **Execute Rollback**
   ```bash
   # Rollback to identified commit
   git reset --hard <commit-hash>
   
   # Force push to remote (if needed)
   git push --force-with-lease origin main
   ```

3. **Verify Rollback**
   ```bash
   # Run QA suite to ensure system is stable
   pnpm run qa:full
   
   # Check that cohort features are no longer present
   curl -s http://localhost:3000/progress | grep -q "404"
   curl -s http://localhost:3000/data | grep -q "404"
   ```

4. **Update Documentation**
   - Update TASKS.md with rollback status
   - Create ECRR report documenting rollback
   - Notify team of rollback completion

## 🎛️ **Feature-Specific Rollback**

### **Disable Progress Dashboard Only**

**Steps**:
1. **Remove Route**
   ```bash
   # Comment out or remove progress route
   # In app/progress/page.tsx, add:
   # return <div>Feature temporarily disabled</div>
   ```

2. **Remove Navigation**
   ```bash
   # In app/layout.tsx, comment out progress link
   # <!-- <Link href="/progress">Progress</Link> -->
   ```

3. **Keep Data Aggregation**
   - Leave `src/engine/metrics/aggregate.ts` intact
   - Preserve IndexedDB functionality
   - Maintain for future re-enablement

### **Disable Export/Delete Only**

**Steps**:
1. **Remove Route**
   ```bash
   # In app/data/page.tsx, add:
   # return <div>Feature temporarily disabled</div>
   ```

2. **Remove Navigation**
   ```bash
   # In app/layout.tsx, comment out data link
   # <!-- <Link href="/data">Data</Link> -->
   ```

3. **Keep IndexedDB Functionality**
   - Preserve data storage
   - Maintain export/delete logic
   - Keep for future re-enablement

### **Disable Cohort Flags Only**

**Steps**:
1. **Set All Flags to 0**
   ```bash
   export NEXT_PUBLIC_COHORT_ENABLED=0
   export NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY=0
   export NEXT_PUBLIC_COHORT_EVENT_SUMMARY=0
   ```

2. **Remove Conditional UI Components**
   ```bash
   # In components, wrap cohort features with:
   # {false && <CohortFeature />}
   ```

3. **Keep Flag Resolver**
   - Preserve `src/config/flags.ts`
   - Maintain flag infrastructure
   - Keep for future re-enablement

## 🗄️ **Database Rollback**

### **Scenario**: Need to clear user data (use with extreme caution)

**⚠️ WARNING**: This will permanently delete all user data. Users should export their data first.

**Steps**:
1. **Notify Users**
   - Send data export reminder
   - Provide 24-hour grace period
   - Document data loss implications

2. **Execute Data Clear**
   ```bash
   # Clear IndexedDB (browser-specific)
   # Chrome: DevTools → Application → Storage → Clear storage
   # Firefox: DevTools → Storage → Clear All
   # Safari: Develop → Empty Caches
   ```

3. **Verify Data Clear**
   ```bash
   # Check that IndexedDB is empty
   # In browser console:
   # indexedDB.databases().then(dbs => console.log(dbs.length))
   ```

4. **Update Documentation**
   - Document data loss
   - Update privacy policy if needed
   - Create incident report

## 🔍 **Rollback Validation**

### **Post-Rollback Checks**

1. **Technical Validation**
   ```bash
   # Run full QA suite
   pnpm run qa:full
   
   # Check specific components
   pnpm run qa:progress
   pnpm run qa:data
   pnpm run qa:a11y
   
   # Verify cohort flags
   pnpm test:unit tests/unit/flags.test.ts
   ```

2. **User Experience Validation**
   - [ ] **Progress Dashboard**: Returns 404 or disabled message
   - [ ] **Data Control**: Returns 404 or disabled message
   - [ ] **Cohort Flags**: Default OFF, no unexpected UI changes
   - [ ] **Accessibility**: Screen reader compatibility maintained
   - [ ] **Performance**: Page load times acceptable

3. **Security Validation**
   - [ ] **CSP Headers**: No violations in console
   - [ ] **COOP/COEP**: Cross-origin isolation maintained
   - [ ] **Local-First**: No network calls for cohort features
   - [ ] **Privacy**: No data transmission verified

## 📊 **Rollback Monitoring**

### **Success Metrics**
- **Rollback Time**: < 5 minutes for code rollback
- **System Stability**: All tests passing
- **User Impact**: Minimal disruption
- **Data Safety**: User data preserved where possible

### **Failure Indicators**
- **Extended Downtime**: > 15 minutes
- **Test Failures**: QA suite not passing
- **Data Loss**: Unintended data deletion
- **Security Issues**: New vulnerabilities introduced

## 🚨 **Emergency Contacts**

### **Rollback Authority**
- **Immediate**: Human Project Lead
- **Code**: Human Project Lead
- **Database**: Human Project Lead
- **Security**: Human Project Lead

### **Technical Support**
- **Primary**: Cursor Agent - Observability Copilot
- **Secondary**: Human Project Lead
- **Supporting**: Codex-Local

### **Communication**
- **Status Updates**: Via TASKS.md
- **Issue Tracking**: GitHub Issues
- **Documentation**: ECRR Reports
- **Incident Reports**: Emergency notification system

## 📋 **Rollback Checklist**

### **Before Rollback**
- [ ] **Assess Impact**: Determine scope of rollback needed
- [ ] **Notify Team**: Alert relevant stakeholders
- [ ] **Backup Data**: Ensure user data is safe
- [ ] **Document Issue**: Record problem details

### **During Rollback**
- [ ] **Execute Steps**: Follow rollback procedure
- [ ] **Monitor Progress**: Watch for errors or issues
- [ ] **Verify Changes**: Confirm rollback success
- [ ] **Update Status**: Communicate progress

### **After Rollback**
- [ ] **Validate System**: Run QA suite
- [ ] **Check User Experience**: Verify functionality
- [ ] **Document Incident**: Create ECRR report
- [ ] **Plan Recovery**: Determine next steps

## 🔄 **Recovery Procedures**

### **Re-enabling Features**
1. **Fix Underlying Issue**: Address root cause
2. **Test Fix**: Verify solution works
3. **Gradual Rollout**: Re-enable features incrementally
4. **Monitor Closely**: Watch for recurrence

### **Data Recovery**
1. **Assess Damage**: Determine data loss extent
2. **Restore from Backup**: If available
3. **Notify Users**: Inform of data loss/recovery
4. **Update Procedures**: Improve backup strategy

## 📚 **Related Documentation**

- [Beta Launch Checklist](docs/BETA_LAUNCH_CHECKLIST.md)
- [Tester Onboarding Guide](docs/cohort-onboarding.md)
- [QA Release Runbook](docs/QA_RELEASE_RUNBOOK.md)
- [Cohort Flags Documentation](docs/cohort-flags.md)
- [ECRR Report Template](docs/ECRR_REPORT_TEMPLATE.md)

---

**🚨 Remember**: Rollbacks are emergency procedures. Always prioritize user safety and data preservation. Document all actions and communicate clearly with stakeholders.

*Last Updated: [Current Date]*
*Version: 1.0*
*Status: Emergency Procedures*
