#!/usr/bin/env pwsh
# Archive Gate #007 Session Artifacts
# Date: 2025-10-11
# Purpose: Clean up session files, archive important docs, remove temp files

$ErrorActionPreference = 'Continue'

Write-Host "🐾 Starting Gate #007 Session Archive & Cleanup..." -ForegroundColor Cyan

# Create archive structure
$archiveBase = "CHAR/PRSV/archive/gate-007"
New-Item -ItemType Directory -Path $archiveBase -Force | Out-Null
New-Item -ItemType Directory -Path "$archiveBase/session-docs" -Force | Out-Null
New-Item -ItemType Directory -Path "$archiveBase/option-b" -Force | Out-Null
New-Item -ItemType Directory -Path "$archiveBase/cursor-reports" -Force | Out-Null

Write-Host "✅ Archive directories created" -ForegroundColor Green

# Archive Gate #007 session documentation
Write-Host "`n📂 Archiving Gate #007 documentation..." -ForegroundColor Yellow

$gate007Docs = @(
    "GATE_007_APPROVED_FINAL.md",
    "GATE_007_FINAL_DECISION.md",
    "GATE_007_MERGE_COMPLETE_FINAL.md",
    "RELEASE_PR_GATE_007.md"
)

foreach ($doc in $gate007Docs) {
    if (Test-Path $doc) {
        Copy-Item $doc -Destination "$archiveBase/session-docs/" -Force
        Remove-Item $doc -Force
        Write-Host "  ✓ Archived & removed: $doc" -ForegroundColor Green
    }
}

# Archive Option B documentation
Write-Host "`n📂 Archiving Option B documentation..." -ForegroundColor Yellow

$optionBDocs = @(
    "OPTION_B_EXECUTION_DIAGNOSIS.md",
    "OPTION_B_EXECUTION_GUIDE.ps1",
    "OPTION_B_FINAL_STATUS_20251011.md",
    "OPTION_B_INTEGRATION_COMPLETE.md",
    "OPTION_B_SERVICE_TROUBLESHOOTING.md",
    "OPTION_B_STATUS_HOLD_20251011.md"
)

foreach ($doc in $optionBDocs) {
    if (Test-Path $doc) {
        Copy-Item $doc -Destination "$archiveBase/option-b/" -Force
        Remove-Item $doc -Force
        Write-Host "  ✓ Archived & removed: $doc" -ForegroundColor Green
    }
}

# Archive Cursor Implementer reports
Write-Host "`n📂 Archiving Cursor Implementer reports..." -ForegroundColor Yellow

$cursorReports = @(
    "CURSOR_IMPLEMENTER_FINAL_STATUS.md",
    "CURSOR_IMPLEMENTER_FINAL_SUMMARY.md",
    "CURSOR_IMPLEMENTER_HANDOFF_FINAL.md",
    "CURSOR_IMPLEMENTER_REPORT_20251010.md"
)

foreach ($doc in $cursorReports) {
    if (Test-Path $doc) {
        Copy-Item $doc -Destination "$archiveBase/cursor-reports/" -Force
        Remove-Item $doc -Force
        Write-Host "  ✓ Archived & removed: $doc" -ForegroundColor Green
    }
}

# Archive PR-related docs
Write-Host "`n📂 Archiving PR documentation..." -ForegroundColor Yellow

$prDocs = @(
    "PR_DEPLOYMENT_STATUS_20251010.md",
    "PR_MERGE_COMPLETE_20251010.md",
    "PR_MERGE_SUMMARY_20251010.md"
)

foreach ($doc in $prDocs) {
    if (Test-Path $doc) {
        Copy-Item $doc -Destination "$archiveBase/session-docs/" -Force
        Remove-Item $doc -Force
        Write-Host "  ✓ Archived & removed: $doc" -ForegroundColor Green
    }
}

# Archive BossCat session docs
Write-Host "`n📂 Archiving BossCat session docs..." -ForegroundColor Yellow

$bosscatDocs = @(
    "BOSSCAT_HYGIENE_PATCH_20251010.md",
    "BOSSCAT_PR_MERGE_FINAL_REPORT.md"
)

foreach ($doc in $bosscatDocs) {
    if (Test-Path $doc) {
        Copy-Item $doc -Destination "$archiveBase/session-docs/" -Force
        Remove-Item $doc -Force
        Write-Host "  ✓ Archived & removed: $doc" -ForegroundColor Green
    }
}

# Archive governance docs
Write-Host "`n📂 Archiving governance docs..." -ForegroundColor Yellow

$govDocs = @(
    "GOVERNANCE_INTEGRATION_COMPLETE.md"
)

foreach ($doc in $govDocs) {
    if (Test-Path $doc) {
        Copy-Item $doc -Destination "$archiveBase/session-docs/" -Force
        Remove-Item $doc -Force
        Write-Host "  ✓ Archived & removed: $doc" -ForegroundColor Green
    }
}

# Keep essential reference docs (don't archive/remove)
Write-Host "`n📌 Keeping essential reference docs..." -ForegroundColor Cyan

$keepDocs = @(
    "TODO_NEXT_SESSION.md",
    "TODO_ROADMAP_ORGANIZED.md",
    "OPERATORS_QUICK_CARD.md",
    "BOSSCAT_LOG.md"
)

foreach ($doc in $keepDocs) {
    if (Test-Path $doc) {
        Write-Host "  ✓ Kept: $doc" -ForegroundColor Cyan
    }
}

# Clean up temporary artifacts (old canary logs)
Write-Host "`n🧹 Cleaning up old canary logs..." -ForegroundColor Yellow

$oldCanaryLogs = Get-ChildItem -Path "DELT/ARTF" -Filter "otel-canary-2025-10-*.json" -ErrorAction SilentlyContinue
if ($oldCanaryLogs) {
    $canaryArchive = "$archiveBase/canary-logs"
    New-Item -ItemType Directory -Path $canaryArchive -Force | Out-Null
    
    foreach ($log in $oldCanaryLogs) {
        Copy-Item $log.FullName -Destination $canaryArchive -Force
        Remove-Item $log.FullName -Force
        Write-Host "  ✓ Archived & removed: $($log.Name)" -ForegroundColor Green
    }
}

# Create archive index
Write-Host "`n📋 Creating archive index..." -ForegroundColor Yellow

$indexContent = @"
# Gate #007 Session Archive

**Archive Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')  
**Session:** Gate #007 - Production Release  
**Status:** Complete

---

## 📂 Archive Contents

### Session Documentation
- Gate #007 approval and decision documents
- Release PR documentation
- PR merge reports
- BossCat hygiene patches
- Governance integration docs

### Option B Documentation
- Execution guides and diagnostics
- Final status reports
- Service troubleshooting guides
- Integration completion docs

### Cursor Implementer Reports
- Final status and summary
- Handoff documentation
- Session execution reports

### Canary Logs
- Historical canary test results from Oct 10-11

---

## 🎯 Session Outcomes

**Gate #007:** ✅ Merged to production (PR #124)  
**ECRR Reports:** 55 documents processed (237 KB)  
**Option B:** Operational with P95 validation  
**Documentation:** Complete audit trail

---

## 📝 Next Steps

See: \`TODO_NEXT_SESSION.md\` in repository root

**Priority Tasks:**
1. Review workflow changes (\`.github/workflows/bosscat-gate-verify.yml\`)
2. GPU work (next focus area)

---

🐾 **Archive complete. Repository cleaned and ready for next session.**
"@

$indexContent | Set-Content -Path "$archiveBase/README.md" -Encoding utf8
Write-Host "  ✓ Archive index created" -ForegroundColor Green

# Summary
Write-Host "`n✅ Archive & Cleanup Complete!" -ForegroundColor Green
Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "  Archive location: $archiveBase" -ForegroundColor White
Write-Host "  Essential docs: Kept in root" -ForegroundColor White
Write-Host "  Temporary files: Cleaned up" -ForegroundColor White
Write-Host "  Next steps: See TODO_NEXT_SESSION.md" -ForegroundColor White

Write-Host "`n🐾 Repository ready for GPU work!" -ForegroundColor Cyan

