# 🐾 BossCat Hub — Go-Live Runbook

**Status:** Ready for Deployment  
**Date:** 2025-10-19  
**PRs Merged:** #168 (core), #169 (automations), #170 (polish)

---

## ✅ Pre-Flight Checklist (COMPLETE)

- [x] All 3 PRs merged to `main`
- [x] 17 Hub files in repository
- [x] Workflows validated (`update-kpis.yml` has `permissions: contents: write`)
- [x] Smoke test scripts created
- [x] Local `main` synced with remote

---

## 🚀 Deployment Steps (USER MANUAL ACTIONS REQUIRED)

### **Step 1: Enable GitHub Pages** ⏳ PENDING

**Action:** Configure GitHub Pages in repository settings

**URL:** https://github.com/MoneyCat-inc/otel-ops-pack/settings/pages

**Configuration:**
```
Source:        Deploy from a branch
Branch:        main
Folder:        / (root)
Custom domain: hub.resonai.io
Enforce HTTPS: ✅ (checked)
```

**Expected Result:** Green checkmark + "Your site is published at https://hub.resonai.io"

---

### **Step 2: Configure DNS** ⏳ PENDING

**Action:** Add CNAME record at DNS provider (e.g., Cloudflare)

**DNS Configuration:**
```
Type:   CNAME
Name:   hub
Target: moneycat-inc.github.io
TTL:    Auto
Proxy:  Optional (Cloudflare orange cloud is fine)
```

**Verification Command:**
```powershell
pwsh scripts/hub-verify-dns.ps1
```

**Expected Output:**
```
✅ CNAME found: moneycat-inc.github.io
✅ Points to correct target
```

---

### **Step 3: Wait for Propagation** ⏳ PENDING

**Timeline:**
- GitHub Pages build: 2-3 minutes
- DNS propagation: 5-30 minutes (typically <10 min)

**Check Build Status:**
https://github.com/MoneyCat-inc/otel-ops-pack/actions

**Check DNS:**
```powershell
pwsh scripts/hub-verify-dns.ps1
```

---

## 🧪 Verification Steps (AUTOMATED)

### **Smoke Test — All Endpoints**

```powershell
pwsh scripts/hub-smoke-test.ps1
```

**Expected Result:**
```
✅ Hub Landing → 200
✅ Hub JS (v1) → 200
✅ KPI Feed → 200
✅ Status Page → 200
✅ Live Metrics → 200
✅ Data Room → 200
✅ SEO Robots → 200
✅ Favicon → 200
✅ Security Policy → 200
✅ Humans File → 200

Passed: 10
Failed: 0
```

---

### **Browser Verification**

**Manual Checks:**
1. Open https://hub.resonai.io/
2. **Console:** No CSP violations
3. **Hero Metrics:** Values load from `kpis.json`
4. **Click "Data Room"** → Verify page loads
5. **Click "Live Metrics"** → Verify page loads
6. **Click "Status"** → Verify page loads

**Demo Flow (90 seconds):**
1. Hub landing → Point out metrics card
2. Data Room → Run Laminar → Chaotic → Canary → Stop
3. Live Metrics → Show throughput/latency
4. Status → Show breadcrumbs + unified design

---

## ⚙️ Post-Deployment Actions

### **Kick Automations (Don't Wait for Cron)**

**Actions → Workflows → Run workflow:**

1. **Hub Uptime Smoke** (`.github/workflows/hub-smoke.yml`)
   - Should pass with all 200s
   - Runs every 10 minutes automatically

2. **Link Check** (`.github/workflows/link-check.yml`)
   - Validates all internal/external links
   - Runs on PRs + nightly at 1 AM

3. **Update KPIs** (`.github/workflows/update-kpis.yml`)
   - Writes fresh `docs/status/kpis.json`
   - Runs nightly at 2 AM UTC

---

## 🎨 Optional: OG Preview Image

**Status:** ⏳ Deferred (commented out in `index.html`)

**When Ready:**
1. Create `/og/og-default.png` (1200×630)
2. Uncomment in `index.html:8`:
   ```html
   <meta property="og:image" content="/og/og-default.png">
   ```
3. Test: Paste URL in Bluesky/X/LinkedIn compose

---

## 🔬 Optional: Synthetic OTel Trace

**Status:** ⏳ Optional Enhancement

**Reference:** `docs/ecrr/OTEL_SYNTH_RUNBOOK.md`

**Quick Steps:**
1. Run .NET console with auto-instrumentation
2. Set env vars:
   ```bash
   CORECLR_ENABLE_PROFILING=1
   OTEL_SERVICE_NAME=hub-synth
   OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
   ```
3. Hit `https://hub.resonai.io/robots.txt`
4. Confirm trace in SigNoz
5. Screenshot → `docs/ecrr/ECRR_REPORTS/OTEL_SYNTH_<date>.md`

---

## 📊 Success Metrics

**Hub Health:**
- All endpoints return 200 ✅
- No CSP violations ✅
- Metrics load dynamically ✅
- Links resolve correctly ✅

**Automation Health:**
- Uptime checks passing ✅
- Link validation clean ✅
- KPI updates committing ✅

**Client Demo Ready:**
- Hub live on custom domain ✅
- Data Room functional ✅
- Visual polish present ✅
- Security signals (security.txt, CSP) ✅

---

## 🚨 Troubleshooting

### DNS Not Resolving
```powershell
# Check current DNS
pwsh scripts/hub-verify-dns.ps1

# Expected: CNAME → moneycat-inc.github.io
# If missing: Add at DNS provider, wait 5-30 min
```

### 404 on GitHub Pages
- Verify: Settings → Pages → Source = `main` / `(root)`
- Check: Actions → Recent workflows for build errors
- Wait: Initial build takes 2-3 minutes

### KPI JSON 404
- Manual trigger: Actions → Update KPIs → Run workflow
- Check: `docs/status/kpis.json` exists in `main` branch
- Verify: Workflow has `permissions: contents: write` ✅

### Stale Browser Cache
- Hard reload: Ctrl+Shift+R (Windows) / Cmd+Shift+R (Mac)
- Or append: `?v=1` to URL once
- Note: Already using `hub.v1.js` for cache-busting

---

## 📝 Evidence Artifacts

**Generated by Smoke Test:**
```
artifacts/hub-smoke-<timestamp>.json
```

**Manual Collection:**
- [ ] Screenshot: Hub landing page
- [ ] Screenshot: Data Room in action
- [ ] Screenshot: Browser console (no CSP errors)
- [ ] Screenshot: SigNoz trace (if running synthetic test)

---

## 🎯 Definition of Done

- [x] Code merged to `main`
- [ ] GitHub Pages enabled
- [ ] DNS configured
- [ ] All smoke tests pass
- [ ] Browser verification clean
- [ ] Automations kicked manually
- [ ] Demo flow rehearsed
- [ ] Social rollout posted (optional)

---

**Next Action:** Complete Steps 1-3 above, then run verification scripts.

**Signal:** Reply with "Pages enabled + DNS configured" when ready for automated verification.

