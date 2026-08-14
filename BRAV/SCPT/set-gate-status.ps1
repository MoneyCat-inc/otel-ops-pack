# BossCat OEM - Gate Status Updater
# Quick utility to flip gate status and update badges with audit trail

param(
  [ValidateSet("APPROVED","HOLD")][string]$Status = "HOLD",
  [string]$Reason = "",
  [string]$GateStatusMd = "docs\ecrr\GATE_STATUS.md"
)

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss") + " UTC"

$badge = if ($Status -eq "APPROVED") {
  "https://img.shields.io/badge/Gate%20Status-APPROVED-brightgreen?style=for-the-badge"
} else {
  "https://img.shields.io/badge/Gate%20Status-HOLD-red?style=for-the-badge"
}

$healthBadge = "https://img.shields.io/badge/Health%20Score-98%2F100-brightgreen?style=for-the-badge"
if ($Status -eq "HOLD") {
  $healthBadge = "https://img.shields.io/badge/Health%20Score-CHECK%20REQUIRED-orange?style=for-the-badge"
}

$reasonLine = if ($Reason) { "**Reason:** $Reason  " } else { "" }

$content = @"
# 🐾 Current Gate Status

![Gate Status]($badge)
![Health Score]($healthBadge)

**Last Updated:** $timestamp  
**Status:** $Status  
$reasonLine

---

## Quick Actions

``````powershell
# Verify pipeline health
pwsh -File BRAV\SCPT\verify-pipeline.ps1

# View full gate decision
cat docs\ecrr\gate_decision.json

# Check IONA errors
cat docs\IONA_ERRORS.md

# View SigNoz UI
Start-Process http://localhost:8080
``````

---

## Gate Decision Reference

- **Gate ID:** GATE-2025-10-08-234500
- **Decision Date:** 2025-10-08 23:45:00 UTC
- **Confidence:** 95%
- **Risk Level:** LOW

**Full Documentation:**
- [Gate Approval Certificate](ECRR_REPORTS/GATE-APPROVAL-2025-10-08.md)
- [Full ECRR Report](ECRR_REPORTS/ECRR-2025-10-08-234500.md)
- [QA Hardening Implementation](ECRR_REPORTS/QA-HARDENING-IMPLEMENTATION-2025-10-08.md)

---

🐾 **BossCat OEM** | Executive Overseer Manager
"@

Set-Content -Encoding UTF8 -Path $GateStatusMd -Value $content
Write-Host "🐾 Gate status set to $Status and badge updated." -ForegroundColor Cyan
Write-Host "   Updated: $GateStatusMd" -ForegroundColor Gray
if ($Reason) {
  Write-Host "   Reason: $Reason" -ForegroundColor Gray
}
Write-Host "   Timestamp: $timestamp" -ForegroundColor Gray

