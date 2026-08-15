# 🛡️ Dependabot Security Management Guide

**BossCat OEM Framework** - Dependency Security & Automated Updates

---

## Overview

Dependabot automatically monitors and creates PRs for security vulnerabilities and outdated dependencies in your
repository. This guide covers:

- Reviewing and addressing Dependabot alerts
- Prioritizing high-severity vulnerabilities
- Managing automated dependency updates
- Integration with BossCat gating framework

---

## Dependabot Configuration

### Current Configuration

Located at `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule: { interval: "weekly" }
  
  - package-ecosystem: "pip"
    directory: "/"
    schedule: { interval: "daily" }
  
  - package-ecosystem: "npm"
    directory: "/"
    schedule: { interval: "daily" }
```

### Monitored Ecosystems

| Ecosystem | Frequency | Files Monitored |
|-----------|-----------|-----------------|
| **GitHub Actions** | Weekly | `.github/workflows/*.yml` |
| **Python (pip)** | Daily | `requirements*.txt`, `setup.py` |
| **Node.js (npm)** | Daily | `package.json`, `package-lock.json`, `pnpm-lock.yaml` |

---

## Accessing Security Alerts

### Method 1: Security Tab (Recommended)

1. Navigate to repository → **Security** tab
2. Click **Dependabot alerts** in left sidebar
3. Filter by:
   - **Severity**: Critical, High, Moderate, Low
   - **Ecosystem**: npm, pip, GitHub Actions
   - **State**: Open, Dismissed, Fixed

### Method 2: Pull Requests Tab

1. Go to **Pull requests** tab
2. Filter by author: `dependabot[bot]`
3. Review automated PRs for available updates

### Method 3: Email Notifications

- Configure in Settings → Notifications
- Receive alerts for high/critical vulnerabilities
- Weekly digest of new vulnerabilities

---

## Priority Matrix

### 🔴 Critical Severity (Immediate Action)

**Response Time**: Same day  
**Action Required**: Emergency patch

#### Process

1. Review alert details in Security tab
2. Check if Dependabot PR exists
3. If PR exists:
   - Review changes in PR
   - Run local tests: `pnpm test` or `pytest`
   - Approve and merge immediately
4. If no PR:
   - Manually update: `pnpm update <package>` or `pip install --upgrade <package>`
   - Create emergency PR with prefix: `fix(security): [CRITICAL]`
   - Bypass normal review if necessary
5. Verify fix in production within 1 hour

### 🟠 High Severity (24-48 Hours)

**Response Time**: Within 2 business days  
**Action Required**: Priority patch

#### Process

1. Review vulnerability details and impact
2. Check for Dependabot PR
3. If PR exists:
   - Review code changes
   - Test locally
   - Run integration tests
   - Merge within 48 hours
4. If no PR:
   - Check for patched version availability
   - Plan update window
   - Update and test in staging
   - Deploy to production
5. Document any breaking changes

### 🟡 Moderate Severity (1 Week)

**Response Time**: Within 1 week  
**Action Required**: Standard patch

#### Process

1. Batch with other moderate-severity fixes
2. Review Dependabot PR or create manual update
3. Full test suite execution required
4. Merge during regular maintenance window
5. Include in weekly release notes

### 🟢 Low Severity (Next Sprint)

**Response Time**: Within 30 days  
**Action Required**: Routine maintenance

#### Process

1. Add to backlog
2. Group with dependency update sprint
3. Merge with other low-priority updates
4. Standard review process

---

## Addressing Dependabot Alerts

### Step 1: Review Alert Details

In Security tab → Dependabot alerts, click on alert to view:

- **CVE/GHSA ID** - Unique vulnerability identifier
- **Description** - What the vulnerability does
- **Severity** - CVSS score and rating
- **Affected versions** - Which versions are vulnerable
- **Patched versions** - Which versions fix the issue
- **References** - Links to advisories, patches, discussions

### Step 2: Assess Impact

Questions to answer:

1. **Is this dependency actually used in production?**
   - Check import usage: `git grep -r "import <package>"`
   - Review if it's dev-only dependency

2. **Is the vulnerable code path exercised?**
   - Review functionality that uses this dependency
   - Check if vulnerable features are disabled/unused

3. **Are there workarounds available?**
   - Configuration changes to avoid vulnerable code
   - Feature flags to disable functionality

### Step 3: Apply Fix

#### Option A: Merge Dependabot PR (Preferred)

```bash
# Review the PR locally
gh pr checkout <PR-number>

# Run tests
pnpm test           # For npm packages
pytest              # For Python packages

# Check for breaking changes
git diff origin/main package.json
git diff origin/main requirements.txt

# Merge via GitHub UI or CLI
gh pr merge <PR-number> --squash
```

#### Option B: Manual Update

```bash
# For npm/pnpm
pnpm update <package-name>
pnpm test

# For Python
pip install --upgrade <package-name>
pip freeze > requirements.txt
pytest

# Commit and push
git add package.json pnpm-lock.yaml  # or requirements.txt
git commit -m "fix(security): update <package> to fix <CVE>"
git push
```

#### Option C: No Patch Available

If no patched version exists:

1. **Assess risk**: Is the vulnerability exploitable in your context?
2. **Implement workarounds**:
   - Disable vulnerable features
   - Add input validation
   - Implement compensating controls
3. **Monitor for patches**: Set reminder to check weekly
4. **Consider alternatives**: Evaluate replacement packages
5. **Document decision**: Add comment in Security tab explaining why alert is dismissed

### Step 4: Verify Fix

```bash
# Pull latest changes
git pull origin main

# Run full test suite
pnpm test
pnpm run test:integration

# For Python
pytest tests/
python -m pytest --cov

# Verify no new vulnerabilities
npm audit
pip-audit  # Install with: pip install pip-audit
```

### Step 5: Close Alert

- If fixed via Dependabot PR: Alert closes automatically
- If fixed manually: GitHub detects fix and closes alert
- If dismissed (false positive/won't fix): Add dismissal reason in Security tab

---

## Common Scenarios

### Scenario 1: Transitive Dependency Vulnerability

**Problem**: Vulnerability in package you don't directly depend on

**Solution**:

```bash
# For npm/pnpm - use overrides in package.json
{
  "pnpm": {
    "overrides": {
      "vulnerable-package": "^patched-version"
    }
  }
}

# For Python - update parent package
pip install --upgrade parent-package
```

### Scenario 2: Breaking Changes in Patch

**Problem**: Security patch includes breaking changes

**Solution**:

1. Review changelog and migration guide
2. Create feature branch: `fix/security-<package>-breaking-changes`
3. Update code to handle breaking changes
4. Run comprehensive tests
5. Create PR with detailed notes on changes
6. Request thorough review

### Scenario 3: Multiple Vulnerabilities in Same Package

**Problem**: Package has several open CVEs

**Solution**:

1. Check if package is maintained: Last commit date, open issues
2. If maintained: Update to latest version
3. If abandoned: **Find replacement package**
   - Search npm/PyPI for alternatives
   - Check community recommendations
   - Plan migration in separate PR
4. Document decision in issue

### Scenario 4: Dev-Only Dependency Vulnerability

**Problem**: Vulnerability in dev dependency (e.g., testing tool)

**Solution**:

1. Assess if it affects CI/CD pipeline security
2. If low risk: Schedule with next maintenance window
3. If risk to CI secrets: Prioritize as High severity
4. Update using standard process

### Scenario 5: Serial Lockfile Conflicts Across Dependabot PRs

**Problem**: Several Dependabot PRs touch `package.json` and `pnpm-lock.yaml`. Merging them one-by-one can make later PR
branches dirty or conflicting even when each PR was green before the first merge.

**Solution**:

1. Merge the green, non-conflicting PRs first through the normal PR gate.
2. If the remaining PRs conflict only in dependency manifests or lockfiles, stop serial merges.
3. Create one combined dependency update from fresh `origin/main`.
4. Apply each remaining intended bump explicitly:
   - Runtime npm dependency: `pnpm add -w <package>@<range> --lockfile-only`
   - Dev npm dependency: `pnpm add -Dw <package>@<range> --lockfile-only`
   - Python requirement: edit the scoped `requirements*.txt` line and keep already-merged bumps.
5. Verify `package.json`, `requirements*.txt`, and `pnpm-lock.yaml` have no conflict markers.
6. Commit the combined update and close the superseded Dependabot PRs with a comment that points to the combined commit.
7. Record the closeout in `CHAR/ECRR/ECRR_REPORTS/`.

**Reference command sketch**:

```powershell
git fetch origin main
git switch -c chore/deps-combined origin/main
pnpm add -w '@opentelemetry/instrumentation-fetch@^0.219.0' --lockfile-only
pnpm add -Dw '@opentelemetry/semantic-conventions@^1.41.1' '@jest/globals@^30.4.1' --lockfile-only
git diff --check
git add package.json pnpm-lock.yaml requirements*.txt
git commit -m "chore(deps): apply remaining Dependabot updates"
```

---

## Dependabot PR Review Checklist

When reviewing a Dependabot PR:

- [ ] **Check severity** - Matches priority matrix response time
- [ ] **Review changelog** - Understand what changed
- [ ] **Test locally** - Run full test suite
- [ ] **Check for breaking changes** - Review BREAKING CHANGE notes
- [ ] **Verify compatibility** - Check Node/Python version requirements
- [ ] **Review release notes** - Any security implications?
- [ ] **Run security scan** - `npm audit` or `pip-audit`
- [ ] **Check CI/CD** - All workflows pass
- [ ] **Update documentation** - If breaking changes affect docs
- [ ] **Merge strategy** - Use squash merge for clean history

---

## Automated Workflows

### Security Scanning Workflow

Runs on: Push to main, PRs, Daily at 2 AM UTC

**File**: `.github/workflows/security-scan.yml`

Includes:

- **Gitleaks** - Secret scanning
- **CodeQL** - Code security analysis
- **Trivy** - Vulnerability scanning
- **Dependency Review** - PR-based dependency checks

### Dependabot PR Auto-Approval (Optional)

To auto-approve low-risk updates:

```yaml
# .github/workflows/dependabot-auto-merge.yml
name: Dependabot Auto-Merge
on: pull_request

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: ${{ github.actor == 'dependabot[bot]' }}
    steps:
      - name: Dependabot metadata
        id: metadata
        uses: dependabot/fetch-metadata@v1
      
      - name: Auto-merge for patch updates
        if: ${{ steps.metadata.outputs.update-type == 'version-update:semver-patch' }}
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{github.event.pull_request.html_url}}
          GITHUB_TOKEN: ${{secrets.GITHUB_TOKEN}}
```

---

## Reporting and Metrics

### Weekly Security Review

Run weekly to assess security posture:

```bash
# Check npm vulnerabilities
npm audit --json > artifacts/npm-audit-$(date +%Y%m%d).json
npm audit summary

# Check Python vulnerabilities
pip-audit --format json > artifacts/pip-audit-$(date +%Y%m%d).json
pip-audit

# Generate report
echo "# Security Review - $(date +%Y-%m-%d)" > docs/security/weekly-review.md
echo "## npm Audit" >> docs/security/weekly-review.md
npm audit summary >> docs/security/weekly-review.md
echo "## pip-audit" >> docs/security/weekly-review.md
pip-audit >> docs/security/weekly-review.md
```

### Metrics to Track

| Metric | Target | Formula |
|--------|--------|---------|
| **Mean Time to Remediate (MTTR)** | < 7 days | Time from alert to fix deployed |
| **Critical Vulnerability Count** | 0 | Open critical alerts |
| **High Vulnerability Count** | < 5 | Open high alerts |
| **Dependabot PR Merge Rate** | > 90% | (Merged PRs / Total PRs) × 100 |
| **Vulnerability Backlog Age** | < 30 days | Average age of open alerts |

### Dashboard Integration

Export metrics to SigNoz:

```bash
# Add to scripts/security-metrics.ps1
pwsh scripts/emit-security-metrics.ps1

# Schedule weekly in crontab/Task Scheduler
# Sends metrics to OTel collector → SigNoz
```

---

## Best Practices

### ✅ Do's

- **Enable notifications** for high/critical alerts
- **Review Dependabot PRs** within SLA timeframes
- **Test thoroughly** before merging security updates
- **Document decisions** when dismissing alerts
- **Keep dependencies up to date** - Reduces future alert volume
- **Use lock files** - `pnpm-lock.yaml`, `requirements.txt` for reproducibility
- **Monitor security advisories** - Subscribe to package security feeds

### ❌ Don'ts

- **Don't ignore security alerts** - Even low severity can escalate
- **Don't auto-merge** without review (except low-risk patches)
- **Don't dismiss alerts** without investigation
- **Don't delay critical patches** - Exploit timeline is often days
- **Don't update blindly** - Always test and verify
- **Don't use vulnerable packages** in production while "planning" update

---

## Escalation Process

### When to Escalate

Escalate to **BossCat OEM** (security lead) if:

- Critical vulnerability with no patch available
- Security update breaks production functionality
- Multiple high-severity alerts accumulating
- Dependabot creating conflicting PRs
- Uncertainty about risk assessment

### Escalation Contact

- **GitHub Issue**: Tag `@security-team` and label `security-escalation`
- **Emergency**: Follow incident response plan
- **Documentation**: File details in `docs/security/incidents/`

---

## Resources

### Tools

- **npm audit**: Built-in npm security scanner
- **pip-audit**: Python package vulnerability scanner
- **Gitleaks**: Secret scanning
- **Trivy**: Multi-format vulnerability scanner
- **Snyk**: Commercial vulnerability scanner (optional)

### References

- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [npm Audit](https://docs.npmjs.com/cli/v8/commands/npm-audit)
- [pip-audit](https://github.com/pypa/pip-audit)
- [NIST NVD](https://nvd.nist.gov/) - Vulnerability database
- [CVE.org](https://www.cve.org/) - CVE information

---

**Last Updated**: 2025-10-07  
**Next Review**: Weekly  
**Maintained By**: BossCat OEM Framework  
**Status**: ✅ Production Ready

