# ECRR Report: Monolith-D Encoding Hygiene & DMA Guard

**Date**: 2025-09-23  
**Agent**: Cursor Agent — Observability Copilot  
**Task**: Capture UTF-8 drift & Kernel DMA guard status for monolith-D  
**Status**: ⚠️ **PENDING** (DMA reboot outstanding)

## 🔍 Examine

**Environment Snapshot**:
- Host: `D-MONOLITH` (Windows 11 Pro 10.0.26220)
- Logs reviewed: `C:\otel\logs\ai-assistant-helper.last.txt`, `canary-check-min.last.log`, `config-schema.last.txt`
- Encoding symptom: mojibake line in `ai-assistant-helper.last.txt`
- Security state: `Kernel DMA Protection : Off` (via `systeminfo`)

**Evidence Commands**:
- `Get-Content C:\otel\logs\ai-assistant-helper.last.txt`
- `systeminfo | Select-String 'Kernel DMA Protection'`
- `Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity`

## 🧹 Clean

**Actions**:
1. Updated `ai-assistant-helper.ps1` (lines 12-27) to force UTF-8 console/output encoding and write logs via `StreamWriter`.
2. Removed stale mojibake log (`Remove-Item C:\otel\logs\ai-assistant-helper.last.txt`) and re-ran helper to regenerate clean UTF-8 entries.
3. Documented DMA guard enablement procedure (registry keys + reboot) and executed helper scripts for verification.

**Outcomes**:
- ✅ New helper runs log clean ASCII/UTF-8 lines.
- ✅ `C:\otel\logs\utf8-test.txt` confirms UTF-8 pipeline using `Out-File -Encoding UTF8`.
- ⚠️ DMA registry value missing; final elevated pass + reboot still required.

## 📝 Report

**Key Commands Executed**:
- `pwsh -File .\ai-assistant-helper.ps1 -Action help`
- `Get-PnpDevice -FriendlyName '*Virtual Desktop Monitor*'`
- `Get-AppxPackage -Name 'Microsoft.YourPhone'`
- `Get-ChildItem 'C:\ProgramData\Microsoft\Windows\WER\Temp' -Filter '*.mdmp'`
- `pwsh -File scripts\system-health-check.ps1` (ready for ongoing monitoring)

**Findings**:
- Virtual desktop monitor and PhoneExperienceHost health remain ✅.
- SigNoz health endpoint returns `status: ok`.
- DMA guard pending due to missing `DmaSecurityEnabled` registry value.

**Artifacts**:
- `ai-assistant-helper.ps1` (UTF-8 fix)
- `C:\otel\logs\ai-assistant-helper.last.txt` (clean log)
- `C:\otel\logs\utf8-test.txt`
- DMA enable script: `scripts\enable-dma-protection.ps1`

## 🎭 Role

- **Actor**: Cursor Agent — Observability Copilot  
- **Responsibilities**: Inspect logs, remediate encoding drift, stage DMA guard instructions, surface remaining action to operators.

## ▶️ Next Steps

1. Run `Start-Process pwsh -Verb RunAs -ArgumentList '-File scripts\enable-dma-protection.ps1'` and reboot to flip DMA guard.
2. After reboot, re-run:
   ```powershell
   systeminfo | Select-String 'Kernel DMA Protection'
   (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity').DmaSecurityEnabled
   pwsh -File scripts\system-health-check.ps1
   ```
3. Import `docs/system-health-dashboard.json` into SigNoz for ongoing visibility.
