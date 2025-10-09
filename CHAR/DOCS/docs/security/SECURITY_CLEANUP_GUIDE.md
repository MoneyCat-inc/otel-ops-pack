# Security Cleanup Guide
**BossCat OEM - Security Hygiene Automation**

---

## 🎯 Purpose

This guide explains the automated security cleanup process for identifying and removing potentially vulnerable files from the repository.

---

## 🔒 What Gets Scanned

### **CRITICAL Risk Files**
- **Screenshots** (`.png`, `.jpg`, `.jpeg`, `.gif`, `.bmp`)
  - May contain credentials in UI
  - May show API keys or tokens
  - May expose internal system details
  - May contain PII (Personally Identifiable Information)

- **Memory Dumps** (`.dump`, `.dmp`, `.core`)
  - May contain secrets in memory
  - May expose sensitive application state
  - May contain encryption keys

### **HIGH Risk Files**
- **Log Files** (`.log`, `.txt`)
  - May contain API keys in error messages
  - May include authentication tokens
  - May expose internal paths or configurations
  - May contain user data

- **Backup Files** (`.bak`, `.backup`, `.old`, `.orig`)
  - May contain outdated secrets
  - May have deprecated configurations with keys
  - May expose previous vulnerabilities

### **MEDIUM Risk Files**
- **Temporary Files** (`.tmp`, `.temp`, `.swp`, `.swo`)
  - May contain partial sensitive data
  - Editor artifacts with credentials
  - Incomplete operations with secrets

- **Patch Files** (`.diff`, `.patch`)
  - May expose internal code
  - May contain temporary test credentials
  - May show security vulnerabilities

---

## 🚀 Usage

### **Dry Run (Scan Only)**
```powershell
pwsh scripts/security-cleanup.ps1 -DryRun
```
**Effect:** Identifies vulnerable files without modifying anything.

### **Live Run (Archive & Remove)**
```powershell
pwsh scripts/security-cleanup.ps1
```
**Effect:** 
- Archives vulnerable files to `C:\archive_bin\security-cleanup-TIMESTAMP\`
- Removes files from working directory
- Generates security report in `docs/security/`

### **Force Cleanup (No Prompts)**
```powershell
pwsh scripts/security-cleanup.ps1 -Force
```
**Effect:** Runs cleanup without confirmations (for automation).

### **Skip Archive (Delete Only)**
```powershell
pwsh scripts/security-cleanup.ps1 -SkipArchive
```
**Effect:** Deletes files without archiving (⚠️ **DANGEROUS** - use with caution).

---

## 📋 Workflow

### **Step 1: Run Dry Run**
```powershell
pwsh scripts/security-cleanup.ps1 -DryRun
```
Review the list of files that would be archived.

### **Step 2: Run Live Cleanup**
```powershell
pwsh scripts/security-cleanup.ps1
```
Files are archived to timestamped directory.

### **Step 3: Review Archive**
```powershell
explorer C:\archive_bin\security-cleanup-YYYYMMDD-HHMMSS
```
Manually review archived files for:
- Exposed credentials
- API keys or tokens
- Sensitive internal data
- PII

### **Step 4: Rotate Secrets (If Needed)**
If sensitive data found:
- Rotate any exposed API keys
- Update compromised credentials
- Review git history for exposure
- Consider using `git-filter-repo` to purge

### **Step 5: Commit Security Report**
```powershell
git add docs/security/SECURITY_CLEANUP_*.md
git commit -m "docs(security): Security cleanup report - YYYYMMDD"
git push origin main
```

### **Step 6: Delete Archive (After 30 Days)**
```powershell
Remove-Item 'C:\archive_bin\security-cleanup-YYYYMMDD-HHMMSS' -Recurse -Force
```

---

## 🔄 Automation

### **Add to Pre-Commit Hook**
`.git/hooks/pre-commit`:
```bash
#!/bin/bash
pwsh scripts/security-cleanup.ps1 -DryRun
if [ $? -ne 0 ]; then
  echo "⚠️  Security cleanup found vulnerable files. Run: pwsh scripts/security-cleanup.ps1"
  exit 1
fi
```

### **Add to GitHub Actions**
`.github/workflows/security-cleanup.yml`:
```yaml
name: Security Cleanup Check
on: [pull_request]
jobs:
  security-scan:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Security cleanup scan
        run: pwsh scripts/security-cleanup.ps1 -DryRun
      - name: Fail if vulnerabilities found
        run: |
          if ($LASTEXITCODE -ne 0) {
            Write-Error "Vulnerable files detected"
            exit 1
          }
```

### **Monthly Automation**
Add to scheduled tasks:
```powershell
# Windows Task Scheduler
$action = New-ScheduledTaskAction -Execute 'pwsh' -Argument '-File C:\otel\scripts\security-cleanup.ps1'
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 2am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "OTel Security Cleanup"
```

---

## 🛡️ Prevention

### **Update .gitignore**
Add these patterns to prevent future introduction:
```gitignore
# Security - Potentially vulnerable files
*.log
!package-lock.json
!pnpm-lock.yaml
*.bak
*.backup
*.old
*.orig
*.dump
*.dmp
*.core
*.tmp
*.temp
*.swp
*.swo

# Security - Debug artifacts
debug-*.png
test-*.png
*-screenshot.png
health_*.log
*_stderr.log
*_signals.log
```

### **Pre-Commit Validation**
```powershell
# Add to lefthook.yml or husky
pre-commit:
  commands:
    security-scan:
      run: pwsh scripts/security-cleanup.ps1 -DryRun
```

---

## 📊 ECRR Compliance

This script follows the ECRR methodology:

- **Examine:** Scans repository for 6 categories of vulnerable files
- **Clean:** Archives files to secure location before removal
- **Report:** Generates comprehensive security report with audit trail
- **Role:** BossCat OEM Security Automation

---

## ⚠️ Important Notes

### **What's Safe to Delete**
- Debug screenshots (debug-*.png, test-*.png)
- Health check logs (health_*.log)
- Temporary editor files (*.swp, *.swo)
- Old backup configs (*.bak)

### **What to Review Carefully**
- Application logs (may need for debugging)
- Patch files (may be needed for upstream contributions)
- Any file with "prod", "production", or "live" in name

### **What NEVER to Delete Without Review**
- Lock files (package-lock.json, pnpm-lock.yaml)
- Git files (.gitignore, .gitattributes)
- Configuration templates (.env.example)

---

## 🎯 Success Criteria

✅ **CRITICAL** and **HIGH** risk files: 0  
✅ **MEDIUM** risk files: <5  
✅ Security report: Generated and committed  
✅ Archive: Created and scheduled for review  
✅ Prevention: .gitignore updated

---

## 📞 Questions?

- **What if I need a file back?** - Copy from archive directory
- **How long to keep archive?** - 30 days minimum, then delete
- **Found a secret?** - Rotate immediately, check git history
- **Automation failing?** - Check permissions on archive directory

---

🔐 **BossCat Security:** Regular cleanup prevents security drift and credential exposure.

**Last Updated:** 2025-10-09  
**Next Review:** Run monthly or before major releases

