# 🔄 Credential Rotation Calendar

> **Correction 2026-09-02.** Under `docs/BossCat/CHARTER.md` the machine operator `@fubumaki` is the
> only seat that mints, rotates or reads a credential — the team owners below are replaced accordingly.
> The reminder workflow shipped as `.github/workflows/evidence-pat-rotation-reminder.yml`; the
> `iona-gate-verify.yml` smoke test is RETIRED. (2026-09-25: `bosscat-gate-verify.yml` has no App-token step either;
> see §1 step 3.)

**BossCat OEM Framework** - Security Key & Secret Rotation Schedule

---

## Overview

This document defines the **mandatory rotation schedule** for all credentials, keys, and secrets used in the BossCat OEM
observability stack. Regular rotation reduces risk from compromised credentials and ensures compliance with security
best practices.

---

## Rotation Schedule Summary

| Credential Type | Frequency | Last Rotated | Next Due | Owner |
|----------------|-----------|--------------|----------|-------|
| **GitHub App Private Key** | Annually | TBD | TBD | Machine operator (`@fubumaki`) |
| **GitHub Deploy Keys** | Annually | not in use; see note | — | Machine operator (`@fubumaki`) |
| **SigNoz API Keys** | Quarterly | TBD | TBD | Machine operator (`@fubumaki`) |
| **Docker Registry Credentials** | Quarterly | not in use; see note | — | Machine operator (`@fubumaki`) |
| **OTel Service Account Tokens** | Semi-annually | TBD | TBD | Machine operator (`@fubumaki`) |
| **CI/CD Secrets (General)** | Annually | TBD | TBD | Machine operator (`@fubumaki`) |
| **Personal Access Tokens (PATs)** | 90 days | TBD | TBD | Individual Users |
| **SSH Keys** | Annually | TBD | TBD | Individual Users |
| **`EVIDENCE_REPO_TOKEN`** (fine-grained PAT: MoneyCat-inc / `otel-ops-evidence` / Contents R/W) | 90 days | 2026-09-24 (r3) | 2026-12-23 (amber opens ~2026-12-09) | Machine operator (`@fubumaki`) |
| **`BOSSCAT_TOKEN`** (fine-grained PAT `bosscat-rollup-otel-ops-pack`: `otel-ops-pack` / Contents + Pull requests R/W) | Before expiry | ~2026-08-25 (re-minted after it was found expired) | 2027-08-26 (amber opens ~2027-08-12) | Machine operator (`@fubumaki`) |

**Note (2026-09-25):** `DEPLOY_KEY_PRIVATE`, `DOCKER_USERNAME` and `DOCKER_PASSWORD` are referenced by no workflow, so
those rows have nothing to rotate. SigNoz stays live: `gate-nightly.yml` uses `SIGNOZ_API_KEY` and `signoz-*.yml` use
`WYZWOZ_SIGNOZ`. The two PAT rows are watched by `evidence-pat-rotation-reminder.yml`; rotations are recorded as
`[FG PAT ROTATE]` lines in `docs/BossCat/BOSSCAT_LOG.md`.

---

## Detailed Rotation Procedures

### 1. GitHub App Private Key

**Frequency**: Annually (or immediately if compromised)  
**Priority**: 🔴 Critical  
**Owner**: Machine operator (`@fubumaki`) — only seat that rotates credentials (CHARTER)

#### Rotation Process

1. **Generate New Key**
   - Navigate to GitHub Settings → Developer settings → GitHub Apps
   - Select "BossCat OEM Bot" app
   - Scroll to "Private keys" section
   - Click "Generate a private key"
   - Download the new `.pem` file
   - **Securely store** the file (password manager, secrets vault)

2. **Update Repository Secret**
   - Go to repository Settings → Secrets and variables → Actions
   - Click on `BOSSCAT_APP_PRIVATE_KEY` secret
   - Click "Update secret"
   - Paste the **entire contents** of the new `.pem` file
   - Click "Update secret"

3. **Verify New Key Works**

   The only workflows with an App-token step are four retired, `workflow_dispatch`-only ones: `boss-gate-verify.yml`,
   `iona-gate-verify.yml`, `security-scan.yml` and `gitleaks-security-scan.yml`. Dispatch one of them and check that
   its App-token step succeeds; no live workflow uses the key.

4. **Revoke Old Key** (after verification)
   - Return to GitHub App settings → Private keys
   - Find the old key (check fingerprint or creation date)
   - Click "Delete" next to the old key
   - Confirm deletion

5. **Document Rotation**
   - Update "Last Rotated" date in this document
   - Calculate "Next Due" date (1 year from now)
   - Add a one-line entry to `docs/BossCat/BOSSCAT_LOG.md` (the rotation log; `[FG PAT ROTATE]` is the precedent)

#### Rollback Plan

If new key fails:

1. Re-upload previous key to `BOSSCAT_APP_PRIVATE_KEY` secret
2. Verify workflows function
3. Investigate failure cause before retry

---

### 2. GitHub Deploy Keys

**Frequency**: Annually  
**Priority**: 🟠 High  
**Owner**: Machine operator (`@fubumaki`) — only seat that rotates credentials (CHARTER)

#### Rotation Process

1. **Generate New SSH Key Pair**

   ```bash
   # Generate ED25519 key (recommended)
   ssh-keygen -t ed25519 -C "deploy-key-bosscat-$(date +%Y)" -f ~/.ssh/deploy_key_new
   
   # Or RSA 4096 if ED25519 not supported
   ssh-keygen -t rsa -b 4096 -C "deploy-key-bosscat-$(date +%Y)" -f ~/.ssh/deploy_key_new
   ```

2. **Add New Deploy Key**
   - Go to repository Settings → Deploy keys
   - Click "Add deploy key"
   - Title: `BossCat Deploy Key (2025)`
   - Key: Paste contents of `~/.ssh/deploy_key_new.pub`
   - Check "Allow write access" if needed
   - Click "Add key"

3. **Update CI/CD Configuration**
   - Update deploy key secret in GitHub Actions:

     ```bash
     # View current secret
     gh secret list
     
     # Update with new key
     gh secret set DEPLOY_KEY_PRIVATE < ~/.ssh/deploy_key_new
     ```

4. **Test New Key**

   ```bash
   # Test SSH connection
   ssh -i ~/.ssh/deploy_key_new -T git@github.com
   
   # Should see: "Hi <username>! You've successfully authenticated..."
   ```

5. **Remove Old Deploy Key**
   - Return to repository Settings → Deploy keys
   - Find old key (check creation date or title)
   - Click "Delete" and confirm

6. **Securely Delete Old Private Key**

   ```bash
   # Shred old key (Linux)
   shred -vfz ~/.ssh/deploy_key_old
   
   # Secure delete (macOS)
   rm -P ~/.ssh/deploy_key_old
   
   # Windows: Use Shift+Delete or cipher /w
   ```

---

### 3. SigNoz API Keys

**Frequency**: Quarterly (every 3 months)  
**Priority**: 🟠 High  
**Owner**: Machine operator (`@fubumaki`) — only seat that rotates credentials (CHARTER)

#### Rotation Process

1. **Generate New API Key**
   - Log in to SigNoz UI: `http://localhost:8080`
   - Navigate to Settings → API Keys
   - Click "Create API Key"
   - Name: `BossCat OEM Bot - Q<quarter> <year>`
   - Permissions: Select required scopes (read dashboards, metrics, etc.)
   - Copy the generated key **immediately** (won't be shown again)

2. **Update Environment Variables**

   ```bash
   # Update .env file (if used locally)
   SIGNOZ_API_KEY=<new-key>
   
   # Update GitHub Actions secret
   gh secret set SIGNOZ_API_KEY --body "<new-key>"
   
   # Update Windows environment variable (if applicable)
   [Environment]::SetEnvironmentVariable("SIGNOZ_API_KEY", "<new-key>", "User")
   ```

3. **Update Configuration Files**
   - Check for hardcoded keys (should not exist!)
   - Verify references use environment variables:

     ```yaml
     # config.yaml
     exporters:
       otlp/signoz:
         headers:
           Authorization: ${env:SIGNOZ_API_KEY}
     ```

4. **Verify Functionality**

   ```bash
   # Test API access
   curl -H "Authorization: Bearer <new-key>" http://localhost:8080/api/v1/dashboards
   
   # Should return dashboard list
   ```

5. **Revoke Old Key**
   - Return to SigNoz UI → Settings → API Keys
   - Find old key (check creation date or name)
   - Click "Revoke" and confirm
   - Monitor for errors indicating services still using old key

6. **Monitor for Issues**
   - Watch SigNoz logs for authentication errors
   - Check OTLP exporter metrics for failures
   - Review dashboard export workflow runs

---

### 4. Docker Registry Credentials

**Frequency**: Quarterly  
**Priority**: 🟡 Moderate  
**Owner**: Machine operator (`@fubumaki`) — only seat that rotates credentials (CHARTER)

#### Rotation Process

1. **Generate New Token** (Docker Hub example)
   - Log in to Docker Hub
   - Account Settings → Security → Access Tokens
   - Click "New Access Token"
   - Description: `BossCat CI/CD - Q<quarter> <year>`
   - Permissions: Read, Write, Delete (as needed)
   - Copy token immediately

2. **Update GitHub Actions Secret**

   ```bash
   gh secret set DOCKER_USERNAME --body "<username>"
   gh secret set DOCKER_PASSWORD --body "<new-token>"
   ```

3. **Update Docker Login in Workflows**
   - Verify workflows use secrets:

     ```yaml
     - name: Login to Docker Hub
       uses: docker/login-action@v3
       with:
         username: ${{ secrets.DOCKER_USERNAME }}
         password: ${{ secrets.DOCKER_PASSWORD }}
     ```

4. **Test Docker Operations**

   ```bash
   # Test login
   echo "<new-token>" | docker login -u "<username>" --password-stdin
   
   # Test pull
   docker pull your-registry/your-image:latest
   
   # Test push (if applicable)
   docker push your-registry/test-image:latest
   ```

5. **Revoke Old Token**
   - Return to Docker Hub → Access Tokens
   - Find old token
   - Click "Delete" and confirm

---

### 5. Personal Access Tokens (PATs)

**Frequency**: Every 90 days  
**Priority**: 🟠 High  
**Owner**: Individual Users

#### Rotation Process

1. **Create New PAT**
   - GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token"
   - Note: `BossCat Development - <date>`
   - Expiration: 90 days
   - Select scopes: `repo`, `workflow`, `write:packages` (as needed)
   - Click "Generate token"
   - Copy token immediately

2. **Update Local Git Configuration**

   ```bash
   # Update remote URL with new token
   git remote set-url origin https://<new-token>@github.com/<owner>/<repo>.git
   
   # Or use credential manager
   git credential approve <<EOF
   protocol=https
   host=github.com
   username=<your-username>
   password=<new-token>
   EOF
   ```

3. **Update Tools Using PAT**
   - GitHub CLI: `gh auth login`
   - IDE integrations: Update in settings
   - Local scripts: Update in secure storage

4. **Verify Access**

   ```bash
   # Test git operations
   git fetch origin
   git pull origin main
   
   # Test GitHub CLI
   gh repo view
   ```

5. **Revoke Old PAT**
   - Return to GitHub Settings → Personal access tokens
   - Find old token
   - Click "Delete" and confirm

---

## Emergency Rotation

### Trigger Conditions

Rotate credentials **immediately** if:

- 🚨 Credential exposed in public repository
- 🚨 Credential found in logs or error messages
- 🚨 Unauthorized access detected
- 🚨 Team member with access leaves organization
- 🚨 Security breach or compromise suspected

### Emergency Process

1. **Contain the Breach**
   - Immediately revoke compromised credential
   - Generate and deploy new credential
   - Monitor for unauthorized access attempts

2. **Assess Impact**
   - Review access logs for credential usage
   - Identify affected systems and data
   - Determine scope of potential compromise

3. **Notify Stakeholders**
   - Alert the machine operator `@fubumaki`
   - Inform affected users
   - Document incident details

4. **Post-Incident Actions**
   - Conduct root cause analysis
   - Update security procedures
   - Implement preventive measures
   - Schedule follow-up review

---

## Rotation Tracking

### Log Format

Rotations are recorded as one-line entries in `docs/BossCat/BOSSCAT_LOG.md` (e.g. `[D2 FG ROTATE]` 2026-07-24,
`[FG PAT ROTATE]` 2026-09-24). There is no separate `docs/security/rotation-log.md`.

### Automation

**Reminder system (shipped):** `.github/workflows/evidence-pat-rotation-reminder.yml` runs `'0 12 * * 1'` (Mondays
12:00 UTC) over an expiry matrix (`EVIDENCE_REPO_TOKEN`, `BOSSCAT_TOKEN`). Inside 14 days of an expiry it opens an
amber issue labelled `security` + `rotation` (both labels exist since 2026-09-24) and comments on it on later Mondays.
Update the matrix `expires` after every rotation.

---

## Best Practices

### ✅ Do's

- **Use secrets manager** - Store credentials in GitHub Secrets, Azure Key Vault, etc.
- **Set expiration dates** - Force regular rotation
- **Principle of least privilege** - Grant minimal required permissions
- **Audit access logs** - Regularly review credential usage
- **Document rotations** - Maintain detailed log
- **Test immediately** - Verify new credentials before revoking old
- **Rotate on schedule** - Don't skip rotations
- **Monitor for leaks** - Use Gitleaks, GitGuardian

### ❌ Don'ts

- **Never commit secrets** - Use environment variables
- **Don't share credentials** - Each user/service has unique key
- **Don't skip verification** - Always test before revoking old key
- **Don't use weak keys** - Use strong cryptographic keys
- **Don't ignore expiration** - Rotate before expiry
- **Don't reuse old keys** - Generate fresh keys every rotation

---

## Compliance & Auditing

### Audit Checklist

**Quarterly Security Review**:

- [ ] All credentials rotated on schedule
- [ ] Rotation log updated and accurate
- [ ] No credentials exposed in code/logs
- [ ] Access logs reviewed for anomalies
- [ ] Unused credentials revoked
- [ ] Team access list current
- [ ] Emergency procedures tested
- [ ] Documentation up to date

### Compliance Standards

Supports compliance with:

- **SOC 2** - Access control and key management
- **ISO 27001** - Information security management
- **NIST** - Cybersecurity framework
- **PCI DSS** - Payment card industry standards (if applicable)

---

## Tools & Resources

### Secrets Management Tools

- **GitHub Secrets** - Built-in GitHub Actions secrets
- **Azure Key Vault** - Enterprise secrets management
- **HashiCorp Vault** - Open-source secrets management
- **1Password** - Team password manager
- **Bitwarden** - Open-source password manager

### Rotation Automation Tools

- **Renovate** - Automated dependency updates (can include secrets)
- **Keeper Secrets Manager** - Secrets rotation automation
- **CyberArk** - Enterprise privileged access management

### Monitoring Tools

- **Gitleaks** - Secret scanning in repositories
- **GitGuardian** - Real-time secret detection
- **Trivy** - Vulnerability and secret scanning
- **Snyk** - Secrets detection in CI/CD

---

## Contact & Escalation

### Rotation Issues

- **Technical Issues**: Open issue with labels `security`, `rotation`
- **Security Incidents**: Follow incident response plan
- **Questions**: machine operator `@fubumaki` (the only seat that handles credentials; CHARTER)

### Escalation Path

1. The machine operator `@fubumaki` (the only seat that handles credentials; CHARTER). There is no further level.

---

**Last Updated**: 2025-10-07  
**Next Review**: Monthly  
**Maintained By**: BossCat OEM Security Team  
**Status**: ✅ Production Ready

---

## Appendix: Rotation Templates

### Email Template: Rotation Reminder

```yaml
Subject: [Action Required] Credential Rotation Due - <Credential Type>

Hi <Team>,

This is a reminder that the following credential is due for rotation:

- Credential Type: <Type>
- Current Key ID: <ID/Fingerprint>
- Last Rotated: <Date>
- Next Due: <Date> (DUE NOW)

Please follow the rotation procedure in:
docs/BossCat/CREDENTIAL_ROTATION_CALENDAR.md

After rotation, update the rotation log at:
docs/BossCat/BOSSCAT_LOG.md (one line)

If you have any questions, contact the machine operator.

--
BossCat OEM Security Team
```

### Issue Template: Rotation Tracking

```markdown
## Credential Rotation Task

**Credential Type**: <GitHub App Private Key / Deploy Key / API Key / etc.>
**Priority**: <Critical / High / Moderate / Low>
**Due Date**: <YYYY-MM-DD>

### Pre-Rotation Checklist
- [ ] Review rotation procedure
- [ ] Gather required access/permissions
- [ ] Notify affected team members
- [ ] Schedule maintenance window (if needed)

### Rotation Steps
- [ ] Generate new credential
- [ ] Update configuration/secrets
- [ ] Verify functionality
- [ ] Revoke old credential
- [ ] Update rotation log

### Post-Rotation Verification
- [ ] All services operational
- [ ] No authentication errors
- [ ] Access logs reviewed
- [ ] Documentation updated

### Notes
<Add any additional context or issues encountered>
```

---

### 🐾 End of Credential Rotation Calendar

