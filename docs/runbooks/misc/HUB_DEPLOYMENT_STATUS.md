# 🐾 BossCat Hub Deployment Status

> ## HISTORICAL — status snapshot of 2025-10-19 05:17 UTC
>
> A waiting-on-nameservers snapshot from the hub cutover. The blocker resolved the same week;
> `hub.resonai.uk` served, and the site migrated to `moneycat.resonai.uk` on 2026-08-15 (see
> `docs/PURPOSE.md`, 2026-08-17 amendment). The site lane itself moved to the `moneycat-site`
> repository in the Pack 3B split (2026-07-24). The three workflows listed as "ready to trigger"
> (`hub-smoke.yml`, `link-check.yml`, `update-kpis.yml`) were retired to `workflow_dispatch` on
> 2026-08-03. Nothing here is pending. Kept unedited as the record.

**Last Updated:** 2025-10-19 05:17 UTC  
**Gate Status:** HOLD - Awaiting Nameserver Activation

---

## ✅ COMPLETED PHASES

### Phase 1: Domain Registration ✅

- **Domain:** resonai.io
- **Registrar:** Cloudflare
- **Nameservers Assigned:**
  - amit.ns.cloudflare.com
  - chelsea.ns.cloudflare.com
- **Status:** Registered, awaiting activation

### Phase 2: DNS Configuration ✅

- **CNAME Record Added:**
  - Type: CNAME
  - Name: hub
  - Target: moneycat-inc.github.io
  - Proxy: DNS only (grey cloud)
  - TTL: Auto
- **Status:** Configured and ready

### Phase 3: GitHub Pages Configuration ✅

- **Source:** main / (root)
- **Custom Domain:** hub.resonai.uk
- **CNAME File:** Present in repository
- **Status:** Configured, awaiting DNS activation

### Phase 4: Code Artifacts ✅

- **Hub Files:** 17/17 present in main
- **PRs Merged:** #168, #169, #170
- **Verification Scripts:** Created and tested
- **Status:** All code ready

---

## ⏳ PENDING PHASES

### Phase 5: Nameserver Activation ⏳

- **Expected Time:** 2-24 hours (typically 2-4 hours)
- **Trigger:** Automatic (registrar processing)
- **Notification:** Email from Cloudflare
- **Current Status:** Waiting for registrar to update nameservers

### Phase 6: DNS Propagation ⏳

- **Expected Time:** 5-30 minutes after activation
- **Verification:** `pwsh scripts/hub-verify-dns.ps1`
- **Current Status:** Pending nameserver activation

### Phase 7: GitHub Pages Verification ⏳

- **Expected Time:** 5-10 minutes after DNS propagates
- **Action:** GitHub automatically detects CNAME and issues HTTPS cert
- **Current Status:** Pending DNS propagation

### Phase 8: Hub Goes LIVE 🚀

- **Expected Time:** Instant after GitHub verification
- **Actions:**
  - Run full smoke tests
  - Browser verification
  - Trigger automation workflows
  - Generate ECRR artifact
  - Update BOSSCAT_LOG.md
  - Declare PRODUCTION LIVE
- **Current Status:** Awaiting all prior phases

---

## 🔍 MONITORING COMMANDS

### Check DNS Status

```powershell
pwsh scripts/hub-verify-dns.ps1
```

**Expected when NOT ready:**

```text
❌ DNS lookup failed: DNS name does not exist
```

**Expected when READY:**

```text
✅ CNAME found: moneycat-inc.github.io
✅ Points to correct target
```

### Check GitHub Actions

```powershell
Start-Process "https://github.com/MoneyCat-inc/otel-ops-pack/actions"
```

Look for "pages build and deployment" workflow with green checkmark.

### Full Smoke Test (when DNS ready)

```powershell
pwsh scripts/hub-smoke-test.ps1
```

Tests all 10 Hub endpoints for HTTP 200 responses.

---

## ⏰ TIMELINE

| Phase | Duration | Status |
|-------|----------|--------|
| Domain Registration | Completed | ✅ |
| DNS Configuration | Completed | ✅ |
| GitHub Pages Setup | Completed | ✅ |
| **Nameserver Activation** | **2-24 hrs (est. 2-4 hrs)** | **⏳ Current** |
| DNS Propagation | 5-30 min | ⏳ |
| GitHub Verification | 5-10 min | ⏳ |
| Hub Goes LIVE | Instant | ⏳ |

**Estimated Go-Live:** 2-6 hours from 05:17 UTC (earliest: 07:17 UTC, latest: tomorrow)

---

## 💬 SIGNAL PROTOCOL

**When to alert Cursor{Implementer}:**

1. **Cloudflare Email Received:**
   - Subject: "resonai.io is now active on Cloudflare"
   - Message: "Cloudflare activated" or "Got the email"

2. **DNS Check Succeeds:**
   - Run: `pwsh scripts/hub-verify-dns.ps1`
   - Shows: CNAME found
   - Message: "DNS is live" or paste output

3. **Later Check-In:**
   - After 4-6 hours
   - Message: "Check status" or "Ready to verify"

---

## 🎯 FINAL VERIFICATION SEQUENCE

When DNS is active, Cursor{Implementer} will execute:

1. ✅ Verify DNS resolution (`hub-verify-dns.ps1`)
2. ✅ Check GitHub Pages deployment status
3. ✅ Run full smoke tests (`hub-smoke-test.ps1`)
4. ✅ Browser verification (CSP, metrics, navigation)
5. ✅ Manually trigger workflows:
   - Hub Uptime Smoke
   - Link Check
   - Update KPIs
6. ✅ Generate ECRR artifact
7. ✅ Update `docs/BossCat/BOSSCAT_LOG.md`
8. ✅ Declare: **🚀 PRODUCTION LIVE 🚀**

---

## 📊 BossCat Gate Summary

**Gate Status:** HOLD - Awaiting External Dependency (Nameserver Activation)

**Executor:** Cursor{Implementer}  
**Authority:** Fubumaki (under BossCat OEM directive)  
**Lane:** DOCS  
**Evidence:** All artifacts present, DNS configured correctly  
**Blocker:** Registrar nameserver propagation (automatic, beyond our control)

---

## 🎯 BossCat Playbook — Activation to Go-Live

### Verification Commands Ready

**DNS Check:**

```powershell
# Check nameservers
Resolve-DnsName resonai.io -Type NS

# Check CNAME
Resolve-DnsName hub.resonai.uk -Type CNAME

# Full resolution
Resolve-DnsName hub.resonai.uk
```

**Production Smoke:**

```powershell
# Full endpoint suite
pwsh scripts/hub-smoke-test.ps1

# Or manual checks
irm https://hub.resonai.uk/ -Method Head -SkipHeaderValidation
irm https://hub.resonai.uk/assets/hub.v1.js -Method Head -SkipHeaderValidation
irm https://hub.resonai.uk/docs/status/kpis.json -Method Head -SkipHeaderValidation
```

### Acceptance Criteria

**DNS Resolution:**

- ✅ NS records show: amit.ns.cloudflare.com, chelsea.ns.cloudflare.com
- ✅ CNAME shows: hub.resonai.uk → moneycat-inc.github.io
- ✅ A records resolve to GitHub Pages IPs

**Production Endpoints:**

- ✅ All 10 endpoints return HTTP 200
- ✅ Browser console shows no CSP violations
- ✅ KPI metrics panel populates from /docs/status/kpis.json
- ✅ Data Room flows execute: Laminar → Chaotic → Canary → Stop
- ✅ Navigation links functional

**Automation Health:**

- ✅ Hub Uptime Smoke workflow passes
- ✅ Link Check workflow passes
- ✅ Update KPIs workflow commits to main

### Evidence Artifacts to Generate

1. **ECRR JSON:** `artifacts/ecrr/docs/hub-golive-<timestamp>.json`
2. **BOSSCAT_LOG Entry:**

   ```text
   2025-10-19T[time]Z — DOCS: Hub clearnet cutover; Pages+DNS verified; smoke pass; automations dispatched.
   ```

3. **Smoke Test Report:** `artifacts/hub-smoke-<timestamp>.json`

---

**Next Update:** When nameserver activation completes or upon user signal.

**Signal Protocol:** Any of these triggers immediate verification:

- "Cloudflare activated"
- "DNS live"
- "Hub is loading"
- "Check status"

🐾 BossCat Cursor{Implementer} standing by for activation signal.

