# 🚀 BossCat Quick Start Card

> ## HISTORICAL — Week-1 onboarding card of 2025-10-07
>
> Written for a security-maintenance rollout that assumed a team (L1/L2/CISO escalation), a
> `nightly-dashboard-export.yml` workflow that does not exist, and a `security-scan.yml` that has
> been dispatch-only since 2026-08-03. The rotation table was never filled in. Kept as the record.
>
> **Current equivalents:** cadence and seats in `CHARTER.md` and `../PURPOSE.md`; Dependabot triage
> in `DEPENDABOT_TRIAGE.md`; credential rules in `../../AGENTS.md` (blast-radius standing rule).

## Print this out or keep it handy for daily operations

---

## 📋 Daily Checklist (5 minutes)

```text
□ Check GitHub Actions for failed workflows
□ Review new Dependabot PRs (merge low-risk updates)
□ Check Security tab for new alerts
□ Verify latest dashboard snapshot exists
```

**Commands**:

```powershell
# One-liner health check
gh run list --limit 5; gh api /repos/:owner/:repo/dependabot/alerts --jq 'length'
```

---

## 🔴 Emergency: Secret Leaked

1. **Immediate**: Revoke compromised credential
2. **Generate**: New credential
3. **Update**: All systems using credential
4. **Verify**: Everything works
5. **Document**: In incident log

**Guide**: [CREDENTIAL_ROTATION_CALENDAR.md](CREDENTIAL_ROTATION_CALENDAR.md#emergency-rotation)

---

## 🟠 High-Severity Vulnerability Found

1. **Review**: Details in Security tab
2. **Check**: Dependabot PR exists?
3. **Test**: Locally (`pnpm test` or `pytest`)
4. **Merge**: Within 48 hours
5. **Verify**: Alert closes

**Guide**: [DEPENDABOT_SECURITY_GUIDE.md](DEPENDABOT_SECURITY_GUIDE.md#priority-matrix)

---

## 🟡 Nightly Export Failed

1. **Check**: Workflow logs for errors
2. **Verify**: SigNoz is running (`docker ps | grep signoz`)
3. **Re-run**: Manually (`gh workflow run nightly-dashboard-export.yml`)
4. **Document**: Issue if persistent

**Guide**: [NIGHTLY_DASHBOARD_GUIDE.md](NIGHTLY_DASHBOARD_GUIDE.md#troubleshooting)

---

## 🔧 Quick Commands

### Security Status

```powershell
# View open alerts
gh api /repos/:owner/:repo/dependabot/alerts | jq -r '.[] | select(.state=="open") | "\(.security_advisory.severity): \(.security_advisory.summary)"'
```

### Dashboard Verification

```powershell
# Check last 7 days
0..6 | % { $d=(Get-Date).AddDays(-$_).ToString("yyyy-MM-dd"); "$d : $(if(Test-Path "docs/observability/snapshots/$d"){'✅'}else{'❌'})" }
```

### Workflow Status

```bash
# Recent runs
gh run list --workflow=security-scan.yml --limit 7

# View specific run
gh run view <run-id> --log
```

### Trigger Manual Export

```bash
gh workflow run nightly-dashboard-export.yml
```

---

## 📚 Documentation Links

| Need | Document | Section |
|------|----------|---------|
| **Setup GitHub App** | [GITHUB_APP_IMPLEMENTATION_GUIDE.md](GITHUB_APP_IMPLEMENTATION_GUIDE.md) | Configuration Steps |
| **Fix Dependabot Alert** | [DEPENDABOT_SECURITY_GUIDE.md](DEPENDABOT_SECURITY_GUIDE.md) | Addressing Alerts |
| **Rotate Credential** | [CREDENTIAL_ROTATION_CALENDAR.md](CREDENTIAL_ROTATION_CALENDAR.md) | Detailed Procedures |
| **Verify Dashboard** | [NIGHTLY_DASHBOARD_GUIDE.md](NIGHTLY_DASHBOARD_GUIDE.md) | Verification Process |
| **Incident Response** | [SECURITY_MAINTENANCE_MASTER_GUIDE.md](SECURITY_MAINTENANCE_MASTER_GUIDE.md) | Incident Response |

---

## 🎯 Success Metrics (Weekly Review)

```text
Metric                          Target    Current
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Critical Vulnerabilities         0        [___]
High Vulnerabilities            <5        [___]
MTTR Critical (hours)          <24        [___]
MTTR High (days)                <7        [___]
Workflow Success Rate          >95%       [___]
Dashboard Export Success       100%       [___]
```

---

## 📞 Escalation Path

1. **L1**: Repository maintainers (GitHub issues)
2. **L2**: Security team lead (`@security-team`)
3. **L3**: CISO / Security Officer (critical incidents)

**Emergency**: Create issue with `security-escalation` label

---

## 🗓️ Rotation Schedule

| Credential | Frequency | Next Due |
|------------|-----------|----------|
| GitHub App Key | Annual | [____-**-**] |
| SigNoz API Key | Quarterly | [____-**-**] |
| Docker Creds | Quarterly | [____-**-**] |
| PATs | 90 days | [____-**-**] |

**Update after each rotation!**

---

## ✅ Week 1 Complete

- [x] GitHub App integrated (4 workflows)
- [x] Documentation created (6 guides)
- [x] Diagnostic run successfully
- [ ] Security alerts triaged → **DO THIS WEEK 2**
- [ ] Rotation calendar populated → **DO THIS WEEK 2**
- [ ] Team trained → **SCHEDULE WEEK 3**

---

**Version**: 1.0  
**Updated**: 2025-10-07  
**Next Review**: Weekly

---

### 🐾 BossCat OEM - Quick, Calm, Secure

