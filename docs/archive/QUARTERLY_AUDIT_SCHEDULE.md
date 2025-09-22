# Quarterly Archive Audit Schedule

> **Purpose**: Regular review of archived runbooks to determine if they can be safely deleted

---

## 📅 **Audit Schedule**

### **Quarterly Dates**
- **Q1**: January 15th
- **Q2**: April 15th  
- **Q3**: July 15th
- **Q4**: October 15th

### **Next Audit**
- **Date**: April 15, 2025
- **Status**: Scheduled

---

## 🔧 **Audit Process**

### **1. Run Audit Script**
```powershell
# Dry run first (preview what would be deleted)
.\scripts\simple-archive-audit.ps1 -DryRun

# If safe to delete, run with force
.\scripts\simple-archive-audit.ps1 -Force
```

### **2. Review Criteria**
- **Age**: Files archived for ≥90 days
- **References**: No active references in current documentation
- **Content**: Historical data no longer needed for audits

### **3. Decision Matrix**

| Condition | Action | Reason |
|-----------|--------|--------|
| <90 days old | Keep | Too recent for deletion |
| ≥90 days + no references | Delete | Safe to remove |
| ≥90 days + has references | Update references first | Prevent broken links |
| Contains unique historical data | Keep | Preserve for audits |

---

## 📊 **Audit History**

| Date | Files Reviewed | Action Taken | Notes |
|------|----------------|--------------|-------|
| 2024-12-19 | 2 files | Archived | Initial archive setup |
| 2025-01-15 | TBD | TBD | First quarterly audit |
| 2025-04-15 | TBD | TBD | Second quarterly audit |

---

## 🚨 **Important Notes**

1. **Never delete without audit**: Always run the audit script first
2. **Check references**: Ensure no active documentation links to archived files
3. **Preserve historical data**: Keep files with unique execution records or canary IDs
4. **Update documentation**: If deleting, update any references in active docs

---

## 📞 **Escalation**

If unsure about deletion:
- **Review with team**: Get consensus before deleting
- **Check audit reports**: Review `docs/archive/audit-report-*.md` files
- **Preserve when in doubt**: Better to keep than lose important data

---

*This schedule is maintained by the Observability Copilot and updated quarterly.*
