# 🤖 Gate Guardian Deployment Template
**Use this template to deploy autobots for new services**

---

## Service Information

**Service Name:** `____________________`  
**Service Type:** [ ] Windows Service  [ ] Docker Container  [ ] API Endpoint  [ ] Other: `________`  
**Criticality:** [ ] P0 (Critical)  [ ] P1 (High)  [ ] P2 (Medium)  [ ] P3 (Low)  
**Current Failure Rate:** `____` failures per `____` hours  
**Impact of Downtime:** `____________________`

---

## Pre-Deployment Assessment

### Problem Statement
Describe the recurring issue:
```
[What keeps failing? How often? What's the impact?]




```

### Current Manual Process
How do you fix it now?
```
[What commands/actions do you take to recover the service?]




```

### Health Check Design
How can we tell if it's healthy?
```
[What checks indicate service is running correctly?]
Examples:
- Service Status == Running
- HTTP GET returns 200
- Database query succeeds
- File exists and is recent



```

---

## Configuration

### Guardian Settings

**Check Interval:** `____` minutes  
**Recommended:** 2 min (P0), 5 min (P1), 10 min (P2), 30 min (P3)

**Recovery Actions:**
```
[List steps to fix the service]
1. 
2. 
3. 
```

**Dry Run First:** [ ] Yes (recommended)

### Auditor Settings

**Check Interval:** `____` hour(s)  
**Recommended:** 1 hour (standard), 4 hours (deep), daily (forensic)

**Lookback Window:** `____` hours  
**Recommended:** 24 hours (standard), 72 hours (deep analysis)

**Event Sources:**
- [ ] Windows Event Log (System/Application)
- [ ] Docker events
- [ ] Application logs
- [ ] Custom audit log: `____________________`

---

## Implementation Plan

### Step 1: Create Guardian Script ☐

**File:** `scripts/autobot-{service-name}-guardian.ps1`

**Functions to implement:**
- [ ] `Get-ServiceState` - Check if healthy
- [ ] `Invoke-ServiceRecovery` - Fix the service
- [ ] `New-ECRRIncidentReport` - Generate report
- [ ] `Invoke-GuardianCheck` - Main loop

**Test commands:**
```powershell
# Test dry run
pwsh -File scripts\autobot-{service-name}-guardian.ps1 -DryRun

# Test actual recovery (safe environment)
pwsh -File scripts\autobot-{service-name}-guardian.ps1
```

### Step 2: Create Auditor Script ☐

**File:** `scripts/autobot-{service-name}-auditor.ps1`

**Functions to implement:**
- [ ] `Get-ServiceChangeEvents` - Scan logs
- [ ] `Get-ServiceHistory` - Build timeline
- [ ] `Get-SuspiciousPatterns` - Detect issues

**Test commands:**
```powershell
# Run audit now
pwsh -File scripts\autobot-{service-name}-auditor.ps1 -LookbackHours 48
```

### Step 3: Create Deployment Script ☐

**File:** `scripts/setup-{service-name}-autobots.ps1`

**Features:**
- [ ] Deploy scheduled tasks
- [ ] Remove scheduled tasks (cleanup)
- [ ] Test mode (run once)

**Test commands:**
```powershell
# Deploy in test mode
pwsh -ExecutionPolicy Bypass -File scripts\setup-{service-name}-autobots.ps1 -TestMode

# Deploy for real
pwsh -ExecutionPolicy Bypass -File scripts\setup-{service-name}-autobots.ps1

# Remove if needed
pwsh -File scripts\setup-{service-name}-autobots.ps1 -Remove
```

---

## Deployment Checklist

### Pre-Deployment ☐

- [ ] Service identified and approved by BossCat OEM
- [ ] Health check tested manually and is deterministic
- [ ] Recovery procedure tested manually (success rate > 90%)
- [ ] Event logs/audit trails confirmed available
- [ ] Check intervals determined based on criticality
- [ ] Scripts created (Guardian, Auditor, Setup)
- [ ] Scripts tested in dry-run mode
- [ ] Scripts tested in safe environment

### Deployment ☐

- [ ] Run deployment script: `setup-{service-name}-autobots.ps1`
- [ ] Verify scheduled tasks created: `Get-ScheduledTask -TaskName "BossCat-*{service-name}*"`
- [ ] Verify tasks are enabled and ready
- [ ] Check first Guardian log exists: `artifacts\autobot-{service-name}-guardian-*.log`
- [ ] Wait for first Auditor run and check report: `artifacts\gate-audit-{service-name}-*.json`

### Post-Deployment (24h) ☐

- [ ] Review Guardian logs for any issues
- [ ] Verify Guardian has run at expected intervals
- [ ] Review first Auditor report
- [ ] Check for false positives (unnecessary recoveries)
- [ ] Adjust intervals if needed
- [ ] Generate ECRR deployment report
- [ ] Update ECRR report index

### Post-Deployment (7d) ☐

- [ ] Calculate success rate (successful recoveries / total attempts)
- [ ] Review pattern detection effectiveness
- [ ] Identify root cause if patterns detected
- [ ] Document lessons learned
- [ ] Share results with team

---

## Monitoring Commands

Copy these for your service:

```powershell
# Check AutoBot status
Get-ScheduledTask -TaskName "BossCat-*{service-name}*"

# View Guardian logs (today)
Get-Content "artifacts\autobot-{service-name}-guardian-$(Get-Date -Format 'yyyyMMdd').log" -Tail 50

# View Auditor reports (recent)
Get-ChildItem "artifacts\gate-audit-{service-name}-*.json" | 
  Sort-Object LastWriteTime -Descending | 
  Select-Object -First 5

# Check for recovery incidents
Get-ChildItem "docs\ecrr\ECRR_REPORTS\AUTOBOT_{SERVICE-NAME}_RECOVERY_*"

# Count recoveries today
(Get-ChildItem "docs\ecrr\ECRR_REPORTS\AUTOBOT_{SERVICE-NAME}_RECOVERY_$(Get-Date -Format 'yyyyMMdd')*").Count
```

---

## Expected Outcomes

### Short-Term (24-48h)

**Service Stability:**
- [ ] Max downtime reduced to < check interval
- [ ] Zero manual interventions needed
- [ ] All failures auto-recovered

**Evidence Collection:**
- [ ] X recovery reports generated (expected: based on current failure rate)
- [ ] Y audit reports generated (expected: 1-2 per day)
- [ ] Patterns identified: [ ] Yes  [ ] No

### Medium-Term (7d)

**Root Cause:**
- [ ] Root cause identified: `____________________`
- [ ] Source of failures: [ ] Automation  [ ] Manual  [ ] External  [ ] Unknown
- [ ] Permanent fix: [ ] Implemented  [ ] Planned  [ ] Not possible

**Metrics:**
- Recovery success rate: `____%` (target: >95%)
- False positive rate: `____%` (target: <5%)
- Avg recovery time: `___` seconds (target: <30s)
- Pattern detection accuracy: `____%` (target: >80%)

### Long-Term (30d+)

- [ ] Service stable (failures reduced by >80%)
- [ ] Root cause addressed
- [ ] AutoBots can be [ ] removed  [ ] kept for safety  [ ] scaled to other services

---

## Rollback Plan

If autobots cause issues:

```powershell
# 1. Disable immediately (stops execution but keeps config)
Disable-ScheduledTask -TaskName "BossCat-{ServiceName}Guardian"
Disable-ScheduledTask -TaskName "BossCat-{ServiceName}Auditor"

# 2. Remove completely (if needed)
pwsh -File scripts\setup-{service-name}-autobots.ps1 -Remove

# 3. Manual recovery (if service broken by autobot)
[Insert manual recovery steps here]
```

**Escalation:** If autobots cause more issues than they solve, immediately disable and notify BossCat OEM.

---

## Documentation

### Required Artifacts

- [ ] Guardian script: `scripts/autobot-{service-name}-guardian.ps1`
- [ ] Auditor script: `scripts/autobot-{service-name}-auditor.ps1`
- [ ] Setup script: `scripts/setup-{service-name}-autobots.ps1`
- [ ] Deployment report: `docs/ecrr/AUTOBOT_{SERVICE-NAME}_DEPLOYMENT_*.md`
- [ ] Pattern document: Update `docs/patterns/GATE_GUARDIAN_PATTERN.md` with this case

### Update These Files

- [ ] `docs/ecrr/ECRR_REPORT_INDEX.md` - Add new autobot reports
- [ ] `docs/patterns/GATE_GUARDIAN_PATTERN.md` - Add to "Example Implementations"
- [ ] `README.md` - Add autobot info if needed
- [ ] Monitoring dashboard - Add autobot metrics

---

## Success Criteria

**Deployment considered successful if:**

✅ AutoBots deployed and running for 7 days  
✅ Recovery success rate > 95%  
✅ False positive rate < 5%  
✅ Max downtime < check interval  
✅ Root cause identified or patterns detected  
✅ No manual interventions needed  
✅ Team trained on monitoring/management  

**Deployment considered failed if:**

❌ AutoBots cause more issues than they solve  
❌ Recovery success rate < 80%  
❌ False positive rate > 20%  
❌ Service stability worse than before  
❌ Root cause remains unknown after 30 days  

---

## Notes

Use this space for service-specific quirks, gotchas, or lessons learned:

```





```

---

## Sign-Off

**Deployment Prepared By:** `____________________`  
**Date:** `____________________`  
**Approved By (BossCat OEM):** `____________________`  
**Date:** `____________________`  

**Post-Deployment Review:**
**Date:** `____________________`  
**Success:** [ ] Yes  [ ] Partial  [ ] No  
**Notes:** `____________________`

---

🐾 **BossCat Pattern: Gate Guardian**  
**Template Version:** 1.0  
**Last Updated:** 2025-10-09

