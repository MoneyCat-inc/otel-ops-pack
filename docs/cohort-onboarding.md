# 🎯 Cohort Tester Onboarding Guide

## 🚀 **Welcome to the Resonai Beta Cohort!**

Thank you for joining our beta testing program. This guide will help you get started with the new cohort features and understand how to provide feedback.

## 🔧 **How to Enable Cohort Features**

### **Step 1: Access the Application**
1. Navigate to the Resonai application in your browser
2. Ensure you're using a supported browser (Chrome, Firefox, Safari, Edge)
3. Make sure you have a stable internet connection

### **Step 2: Enable Cohort Flags**
Cohort features are controlled by feature flags that default to OFF for privacy and controlled rollout.

**Option A: Environment Variables (Development)**
```bash
# Set these environment variables before starting the app
export NEXT_PUBLIC_COHORT_ENABLED=1
export NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY=1
export NEXT_PUBLIC_COHORT_EVENT_SUMMARY=1
```

**Option B: Browser Console (Production)**
```javascript
// Open browser console (F12) and run:
localStorage.setItem('cohort_enabled', 'true');
localStorage.setItem('cohort_dashboard_entry', 'true');
localStorage.setItem('cohort_event_summary', 'true');

// Refresh the page
location.reload();
```

### **Step 3: Verify Features Are Active**
Look for these indicators that cohort features are enabled:
- **Progress Dashboard**: New "Progress" link in navigation
- **Data Control**: New "Data" link in navigation
- **Event Summary**: Enhanced practice page with local analytics

## 📊 **What to Expect in the UI**

### **Progress Dashboard (`/progress`)**
- **Trend Sparklines**: Visual representation of your practice trends
- **Metric Cards**: Key performance indicators
- **Safety Strip**: Timeline of strain events
- **Local Data**: All data processed locally, no uploads

### **Data Control (`/data`)**
- **Export Functionality**: Download your data as JSON
- **Delete Options**: One-click data deletion with confirmation
- **Privacy Controls**: Complete data sovereignty

### **Enhanced Practice Page**
- **Local Event Summary**: Practice session analytics
- **Cohort CTA**: Navigation to new features
- **Real-time Metrics**: Live performance indicators

## 🔒 **Privacy & Data Handling**

### **Local-First Approach**
- **No Uploads**: All data stays on your device
- **IndexedDB Storage**: Data stored locally in your browser
- **No Network Calls**: Cohort features work offline
- **Complete Control**: You own your data

### **What Data Is Collected**
- **Practice Metrics**: Session duration, completion rates
- **Performance Data**: Audio processing metrics
- **Usage Patterns**: Feature adoption, navigation paths
- **Error Logs**: Technical issues for debugging

### **What Data Is NOT Collected**
- **Audio Recordings**: No audio is stored or transmitted
- **Personal Information**: No PII beyond what you provide
- **Third-party Data**: No external service integration
- **Location Data**: No geolocation tracking

### **Data Export & Deletion**
- **Export**: Download complete data as JSON
- **Delete**: One-click removal of all data
- **Backup**: Export before deletion recommended
- **Recovery**: Deleted data cannot be recovered

## 🐛 **How to Report Issues**

### **Issue Reporting Process**
1. **Document the Problem**: Screenshots, error messages, steps to reproduce
2. **Check Console**: Look for JavaScript errors (F12 → Console)
3. **Test Environment**: Note browser, OS, and version
4. **Submit Report**: Use the issue reporting form or email

### **What to Include in Reports**
- **Description**: Clear explanation of the issue
- **Steps to Reproduce**: Exact steps that led to the problem
- **Expected Behavior**: What should have happened
- **Actual Behavior**: What actually happened
- **Screenshots**: Visual evidence of the issue
- **Console Logs**: Any error messages from browser console
- **Environment**: Browser, OS, version information

### **Issue Categories**
- **Bug Reports**: Functionality not working as expected
- **Feature Requests**: Suggestions for improvements
- **Performance Issues**: Slow loading, lag, or crashes
- **Accessibility Issues**: Problems with screen readers or keyboard navigation
- **Privacy Concerns**: Questions about data handling

## 📈 **Success Metrics We're Tracking**

### **Technical Health**
- **Page Load Times**: How quickly features load
- **Error Rates**: Frequency of technical issues
- **Accessibility**: Screen reader compatibility
- **Performance**: Smooth operation across devices

### **User Engagement**
- **Retention**: How often you return to practice
- **Session Duration**: Time spent in practice sessions
- **Feature Adoption**: Which cohort features you use
- **Satisfaction**: Overall experience rating

### **Privacy & Security**
- **Data Leakage**: Ensuring no unintended data transmission
- **CSP Compliance**: Security policy adherence
- **Cross-Origin Isolation**: Browser security features
- **Local-First**: Confirming no network calls

## 🎯 **Beta Testing Goals**

### **Primary Objectives**
1. **Validate Core Features**: Ensure C1-C4 features work reliably
2. **Gather User Feedback**: Understand how features improve practice
3. **Identify Issues**: Catch bugs before broader release
4. **Measure Success**: Track engagement and retention metrics

### **What We're Looking For**
- **Usability**: Are the features intuitive and helpful?
- **Performance**: Do features load quickly and work smoothly?
- **Accessibility**: Are features usable with assistive technologies?
- **Privacy**: Do you feel comfortable with data handling?

## 🚨 **Emergency Procedures**

### **If Something Goes Wrong**
1. **Disable Cohort Features**: Use browser console to turn off flags
2. **Clear Browser Data**: Remove any problematic data
3. **Report Immediately**: Contact support with details
4. **Use Fallback**: Continue with standard practice features

### **Emergency Contacts**
- **Technical Support**: [Support Email]
- **Privacy Concerns**: [Privacy Email]
- **General Questions**: [General Email]

## 📚 **Additional Resources**

### **Documentation**
- [Beta Launch Checklist](docs/BETA_LAUNCH_CHECKLIST.md)
- [Rollback Procedures](docs/rollback-procedures.md)
- [Privacy Policy](docs/privacy-policy.md)
- [FAQ](docs/faq.md)

### **Technical Resources**
- [QA Release Runbook](docs/QA_RELEASE_RUNBOOK.md)
- [Cohort Flags Documentation](docs/cohort-flags.md)
- [Progress Dashboard Guide](docs/user/progress-dashboard.md)
- [Data Control Guide](docs/user/data-control.md)

### **Support Channels**
- **GitHub Issues**: [Repository Issues]
- **Discord**: [Community Server]
- **Email**: [Support Email]
- **Documentation**: [Docs Site]

## 🎉 **Thank You!**

Your participation in the beta cohort is invaluable. Together, we're building a better voice feminization training experience that's private, accessible, and effective.

**Remember**: This is a beta test. Features may change, bugs may occur, and your feedback is essential for making improvements.

---

*Last Updated: [Current Date]*
*Version: 1.0*
*Status: Beta Testing*
