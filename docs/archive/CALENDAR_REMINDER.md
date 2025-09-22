# 📅 Quarterly Archive Audit Calendar Reminder

## Next Audit Dates

### 2025
- **Q1**: January 15, 2025
- **Q2**: April 15, 2025  
- **Q3**: July 15, 2025
- **Q4**: October 15, 2025

### 2026
- **Q1**: January 15, 2026
- **Q2**: April 15, 2026
- **Q3**: July 15, 2026
- **Q4**: October 15, 2026

---

## Quick Commands

```powershell
# Check current status
.\scripts\simple-archive-audit.ps1 -DryRun

# Clean up if safe
.\scripts\simple-archive-audit.ps1 -Force
```

---

## Calendar Integration

### Outlook/Teams
- **Subject**: "Quarterly Archive Audit - [Quarter]"
- **Recurrence**: Quarterly on 15th
- **Reminder**: 1 day before

### Google Calendar
- **Title**: "Archive Audit - [Quarter]"
- **Repeat**: Every 3 months
- **Description**: Run `.\scripts\simple-archive-audit.ps1 -DryRun`

---

*Add these dates to your calendar to ensure regular archive maintenance.*
