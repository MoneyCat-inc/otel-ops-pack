# 📝 Commit Message Template - Archive Lifecycle

**Purpose**: Guide contributors to follow proper archival lifecycle in commits  
**Usage**: Reference when creating commits that affect documentation

---

## 🎯 **Archive Lifecycle Commit Guidelines**

### **When Adding New Reports/Documentation**:

```bash
# Template
feat/docs: [Brief description]

- [CHRONICLE]: Update milestone summary in docs/RESONAI_CHRONICLE.md
- [INDEX]: Add entry to archive/ARCHIVE_INDEX.md quick links
- [BACKUP]: Archive original report to appropriate /archive/ subdirectory

Archive Policy: See docs/ECRR_REPORTS/backup/ARCHIVE_POLICY.md
```

### **When Updating Existing Documentation**:

```bash
# Template  
update/docs: [Brief description]

- [CHRONICLE]: Update executive summary in docs/RESONAI_CHRONICLE.md
- [INDEX]: Update archive counts/references in archive/ARCHIVE_INDEX.md
- [BACKUP]: DO NOT MODIFY - preserve as immutable artifacts

Archive Policy: See docs/ECRR_REPORTS/backup/ARCHIVE_POLICY.md
```

### **When Archiving Completed Work**:

```bash
# Template
archive: [Brief description]

- [CHRONICLE]: Add milestone entry with executive summary
- [INDEX]: Update archive statistics and file listings  
- [BACKUP]: Move completed reports to appropriate /archive/ subdirectory
- Preserve original formatting (including emoji runes) in backup files

Archive Policy: See docs/ECRR_REPORTS/backup/ARCHIVE_POLICY.md
```

---

## 📋 **Quick Reference**

| **Action** | **Update Chronicle** | **Update Index** | **Touch Backup** |
|------------|---------------------|------------------|------------------|
| New report | ✅ Add summary | ✅ Add entry | ✅ Archive original |
| Update docs | ✅ Update summary | ✅ Update counts | ❌ NEVER |
| Archive work | ✅ Add milestone | ✅ Update stats | ✅ Move files |

---

## 🚫 **Common Mistakes to Avoid**

### **DO NOT**:
- ❌ Commit changes to backup files (preserve original formatting)
- ❌ Convert emoji runes to ASCII in backup files
- ❌ Update Chronicle without updating Index (or vice versa)
- ❌ Archive files without updating Chronicle executive summary

### **ALWAYS**:
- ✅ Update both Chronicle AND Index together
- ✅ Preserve backup files as immutable artifacts
- ✅ Reference Archive Policy in commit messages
- ✅ Use consistent ASCII formatting in active docs

---

## 🔧 **Archive Subdirectories**

Use appropriate subdirectory for archived reports:

```bash
# Milestone achievements and major handoffs
archive/milestone-reports/

# ECRR framework processing and consolidation  
archive/ecrr-reports/

# Monitoring, alerting, and compliance setup
archive/compliance-reports/

# Agent role documentation and handoffs
archive/handoff-reports/

# System audits and validation reports
archive/audit-reports/
```

---

## 📌 **Commit Message Checklist**

Before committing documentation changes:

- [ ] **Chronicle Updated**: Executive summary added/updated in `docs/RESONAI_CHRONICLE.md`
- [ ] **Index Updated**: Archive counts and references updated in `archive/ARCHIVE_INDEX.md`
- [ ] **Backup Preserved**: Original files archived without format changes
- [ ] **Policy Referenced**: Archive Policy mentioned in commit message
- [ ] **ASCII Compliance**: Active docs use ASCII-only formatting

---

## ✅ **Example Commit Messages**

### **Good Examples**:
```bash
feat/docs: Add beta launch milestone documentation

- [CHRONICLE]: Add Milestone 2 executive summary with 99.97% success rate
- [INDEX]: Update archive statistics (14 total reports, 6 milestone)
- [BACKUP]: Archive beta launch checklists to milestone-reports/

Archive Policy: See docs/ECRR_REPORTS/backup/ARCHIVE_POLICY.md

update/docs: Sync archive counts after report consolidation

- [CHRONICLE]: Update archive management section with correct totals
- [INDEX]: Fix compliance reports count (2→3) and total (10→14)
- [BACKUP]: DO NOT MODIFY - preserve emoji artifacts as historical context

Archive Policy: See docs/ECRR_REPORTS/backup/ARCHIVE_POLICY.md
```

### **Bad Examples**:
```bash
# ❌ Missing Chronicle update
docs: Add new report to archive
- [INDEX]: Added entry to compliance-reports/

# ❌ Modifying backup files  
fix: Clean up emoji placeholders in backup files
- [BACKUP]: Converted ?? to [SECTION] in historical reports

# ❌ Inconsistent updates
docs: Update archive index
- [INDEX]: Updated counts
# Missing Chronicle update!
```

---

**Status**: ✅ **COMMIT TEMPLATE ACTIVE** - Follow archive lifecycle in all documentation commits

*This template ensures consistent documentation practices and prevents accidental modification of historical backup files while maintaining clean ASCII formatting in active documentation.*
