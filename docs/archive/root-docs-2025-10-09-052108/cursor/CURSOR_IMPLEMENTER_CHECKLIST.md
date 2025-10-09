# ✅ cursor{implementer} Execution Checklist
**IONA-GATE-002: Gate Finalization + Diagnostic Shell**  
**BossCat OEM Official Tracking Document**  
**Date**: 2025-10-07

---

## 🎯 **Mission Status: READY TO START**

**Current Progress**: 95% → Target: 100%  
**Estimated Time**: 6-8 hours  
**Actor**: cursor{implementer}  
**Signal Completion**: `@cat ready-for-gate`

---

## 📋 **Pre-Work Setup**

- [ ] Read `CURSOR_IMPLEMENTER_SETUP_PROMPT.md` (primary guide)
- [ ] Skim `CURSOR_IMPLEMENTER_HANDOFF_FINAL.md` (executive summary)
- [ ] Bookmark `CURSOR_IMPLEMENTER_QUICK_REF.md` (commands)
- [ ] Install dependencies: `pnpm install`
- [ ] Install Playwright: `npx playwright install --with-deps chromium`
- [ ] Install Python packages: `pip install opentelemetry-sdk opentelemetry-exporter-otlp-proto-grpc`
- [ ] Start SigNoz: `docker-compose up -d`
- [ ] Verify SigNoz: `curl http://localhost:8080/api/v1/health`
- [ ] Start dev server: `pnpm dev`
- [ ] Verify app: `curl http://localhost:3000/api/health`

---

## 🔧 **Phase 1: Testing Unblocked** (1-2 hours)

### **Objective**: Fix synthetic span script OR document bypass

#### **Option A: Debug Synthetic Span** (Preferred)
- [ ] Check Python version: `python --version` (need 3.8+)
- [ ] Verify OpenTelemetry packages: `pip list | grep opentelemetry`
- [ ] Check OTLP endpoints: `curl http://localhost:4317` and `curl http://localhost:5318/v1/traces`
- [ ] Run synthetic span: `python synthetic/send_iona_boot_span.py --verbose`
- [ ] Verify in SigNoz: Check for `iona.boot` span with `synthetic=true`
- [ ] Update `docs/BossCat/IONA_ECRR_REPORT.md` with fix details

#### **Option B: Document Bypass** (Alternative)
- [ ] Create `docs/BossCat/IONA_SYNTHETIC_SPAN_BYPASS.md`
- [ ] Document reason for bypass (exit code -1073741819)
- [ ] Document impact assessment (browser telemetry sufficient)
- [ ] Update `scripts/verify-iona-gate.ps1` (comment out synthetic span check)
- [ ] Update `docs/BossCat/IONA_ECRR_REPORT.md` with bypass decision

#### **Verification**
- [ ] Run `pwsh -File scripts/verify-iona-gate.ps1`
- [ ] Expected: All checks PASS (or PASS with documented bypass)

#### **Commit**
- [ ] Stage changes: `git add docs/BossCat/`
- [ ] Commit with ECRR format: `fix(iona): resolve synthetic span emission issue`
- [ ] Include 4-section ECRR message (Examine, Clean, Report, Role)

---

## 🛠️ **Phase 2: Diagnostic Shell** (4-6 hours)

### **Objective**: Build `/diagnostics` route with live telemetry

#### **File Creation (12 files)**

**Route & Main Component:**
- [ ] Create `app/diagnostics/page.tsx` (diagnostics route)
- [ ] Create `components/TelemetryShell.tsx` (main shell component)

**Panels (4 files):**
- [ ] Create `components/telemetry/MetricsPanel.tsx`
- [ ] Create `components/telemetry/TracesPanel.tsx`
- [ ] Create `components/telemetry/LogsPanel.tsx`
- [ ] Create `components/telemetry/ControlsPanel.tsx`

**API Routes (5 files):**
- [ ] Create `app/api/telemetry/stats/route.ts`
- [ ] Create `app/api/telemetry/metrics/route.ts`
- [ ] Create `app/api/telemetry/traces/route.ts`
- [ ] Create `app/api/telemetry/logs/route.ts`
- [ ] Create `app/api/telemetry/emit-span/route.ts`

**Documentation:**
- [ ] Create `docs/BossCat/IONA_DIAGNOSTICS_GUIDE.md`

**Testing:**
- [ ] Add 3 new Playwright tests to `scripts/iona-snapshot.spec.ts`:
  - [ ] Test: "should render diagnostics shell"
  - [ ] Test: "should toggle instrumentation"
  - [ ] Test: "should emit synthetic span"

#### **Local Testing**
- [ ] Open diagnostics page: `http://localhost:3000/diagnostics`
- [ ] Verify all panels render correctly
- [ ] Test instrumentation toggle
- [ ] Test sampling rate slider
- [ ] Test "Emit Synthetic Span" button
- [ ] Verify stats update every 5 seconds
- [ ] Check browser console for errors

#### **Playwright Testing**
- [ ] Run tests: `pnpm playwright test scripts/iona-snapshot.spec.ts`
- [ ] Verify all 14 tests pass (11 existing + 3 new)
- [ ] Check screenshot generated: `artifacts/iona-diagnostics.png`
- [ ] View report: `npx playwright show-report`

#### **Commit**
- [ ] Stage all changes: `git add app/ components/ docs/`
- [ ] Commit with ECRR format: `feat(iona): complete diagnostic telemetry shell`
- [ ] Include 4-section ECRR message (Examine, Clean, Report, Role)

---

## 📝 **ECRR Compliance**

### **Documentation Updates**
- [ ] Update `docs/BossCat/IONA_ECRR_REPORT.md`:
  - [ ] Add Phase 1 findings (Examine)
  - [ ] Document resolution approach (Clean)
  - [ ] Include evidence artifacts (Report)
  - [ ] Update actor declaration (Role)
  - [ ] Add Phase 2 implementation details
  - [ ] Include diagnostic shell screenshots
  - [ ] Update ECRR Gate checklist

- [ ] Create `docs/BossCat/IONA_DIAGNOSTICS_GUIDE.md`:
  - [ ] Overview and purpose
  - [ ] Features and capabilities
  - [ ] Usage instructions
  - [ ] API reference
  - [ ] Troubleshooting guide

### **Commit Messages**
- [ ] All commits follow ECRR format:
  - [ ] Type: `fix(iona):` or `feat(iona):` or `docs(ecrr):`
  - [ ] Summary line
  - [ ] 4-section body: Examine → Clean → Report → Role
  - [ ] Actor declaration: cursor{implementer}
  - [ ] Task ID: IONA-GATE-002

### **Actor Declaration**
- [ ] All commits signed by: cursor{implementer}
- [ ] All ECRR reports declare actor: cursor{implementer}
- [ ] All documentation updates reference: cursor{implementer}

---

## 🔍 **Quality Gates**

### **TypeScript Compilation**
- [ ] Run: `pnpm run build`
- [ ] Expected: 0 errors
- [ ] If errors: Fix all compilation issues
- [ ] Re-run until clean build

### **Linter**
- [ ] Run: `pnpm run lint`
- [ ] Expected: 0 errors
- [ ] If errors: Fix all linting issues
- [ ] Re-run until clean lint

### **Type Checking**
- [ ] Run: `npx tsc --noEmit`
- [ ] Expected: 0 errors
- [ ] If errors: Fix all type issues

### **Playwright Tests**
- [ ] Run: `pnpm playwright test scripts/iona-snapshot.spec.ts`
- [ ] Expected: 14/14 tests passing
- [ ] If failures: Debug and fix failing tests
- [ ] Re-run until all pass

---

## ✅ **Final Verification** (30 minutes)

### **Complete Verification Script**
- [ ] Run: `pwsh -File scripts/verify-iona-gate.ps1`
- [ ] Expected output: `✓ IONA GATE VERIFICATION: PASSED`
- [ ] Check all sections:
  - [ ] ✓ Required files exist
  - [ ] ✓ Playwright tests passing
  - [ ] ✓ Artifacts generated
  - [ ] ✓ Documentation complete
  - [ ] ✓ Telemetry active (browser or synthetic)

### **Artifact Verification**
- [ ] Check: `artifacts/iona-home.png` exists
- [ ] Check: `artifacts/iona-practice.png` exists
- [ ] Check: `artifacts/iona-memx-labs.png` exists
- [ ] Check: `artifacts/iona-diagnostics.png` exists
- [ ] Check: All screenshots are valid (not corrupted)

### **Documentation Verification**
- [ ] Check: `docs/BossCat/IONA_ECRR_REPORT.md` updated
- [ ] Check: `docs/BossCat/IONA_DIAGNOSTICS_GUIDE.md` created
- [ ] Check: All ECRR sections complete (4/4)
- [ ] Check: All evidence artifacts referenced
- [ ] Check: Actor declaration present in all docs

### **SigNoz Verification**
- [ ] Open: `http://localhost:8080`
- [ ] Filter: `service.name = "iona-app"`
- [ ] Verify: `iona.boot` spans present
- [ ] Check: Recent traces (last 15 minutes)
- [ ] Check: No error logs

### **Diagnostics Shell Verification**
- [ ] Open: `http://localhost:3000/diagnostics`
- [ ] Verify: Stats dashboard shows live data
- [ ] Verify: All 4 panels render correctly
- [ ] Verify: Controls toggle works
- [ ] Verify: "Emit Synthetic Span" button works
- [ ] Verify: Data updates every 5 seconds

---

## 🎯 **Gate Activation**

### **Final Commit**
- [ ] Stage final changes: `git add docs/BossCat/IONA_ECRR_REPORT.md`
- [ ] Commit: `docs(ecrr): finalize IONA gate integration`
- [ ] Message includes:
  ```
  IONA-GATE-002 Complete
  
  All tasks complete:
  - ✅ Phase 1: Synthetic span resolved
  - ✅ Phase 2: Diagnostic shell implemented
  - ✅ All tests passing (14/14)
  - ✅ ECRR compliance 100%
  
  Ready for gate activation.
  ```

### **Push to Remote**
- [ ] Push all commits: `git push origin <branch-name>`
- [ ] Verify CI/CD triggers (if applicable)
- [ ] Check GitHub Actions workflow: `.github/workflows/iona-gate-verify.yml`

### **Signal Completion**
- [ ] Comment on PR or issue:
  ```
  @cat ready-for-gate
  
  IONA gate integration complete:
  - 95% → 100% (synthetic span + diagnostic shell)
  - 14 Playwright tests passing
  - Full ECRR documentation
  - All artifacts generated
  
  Phase 1: Testing unblocked ✅
  Phase 2: Diagnostic shell implemented ✅
  ECRR compliance: 100% ✅
  Quality gates: All passing ✅
  ```

---

## 📊 **Progress Tracking**

### **Phase Completion**

| Phase | Status | Completion | Time |
|-------|--------|------------|------|
| Pre-Work Setup | ⏳ Pending | 0% | - |
| Phase 1: Testing Unblocked | ⏳ Pending | 0% | - |
| Phase 2: Diagnostic Shell | ⏳ Pending | 0% | - |
| ECRR Compliance | ⏳ Pending | 0% | - |
| Quality Gates | ⏳ Pending | 0% | - |
| Final Verification | ⏳ Pending | 0% | - |
| Gate Activation | ⏳ Pending | 0% | - |

**Update this table as you progress!**

---

## 🏆 **Success Criteria** (Final Checklist)

Before signaling `@cat ready-for-gate`, all items must be checked:

### **Phase 1: Testing Unblocked**
- [ ] Synthetic span fixed OR bypass documented
- [ ] `scripts/verify-iona-gate.ps1` passes

### **Phase 2: Diagnostic Shell**
- [ ] `/diagnostics` route accessible
- [ ] All 4 panels render and update
- [ ] All 5 API routes functional
- [ ] 3 new Playwright tests passing
- [ ] Screenshot: `artifacts/iona-diagnostics.png`

### **ECRR Compliance**
- [ ] `docs/BossCat/IONA_ECRR_REPORT.md` updated
- [ ] `docs/BossCat/IONA_DIAGNOSTICS_GUIDE.md` created
- [ ] All commit messages ECRR-formatted
- [ ] Actor declaration: cursor{implementer}

### **Quality Gates**
- [ ] TypeScript compiles (0 errors)
- [ ] Linter passes (0 errors)
- [ ] Build succeeds (`pnpm run build`)
- [ ] All 14 Playwright tests pass

---

## 📚 **Reference Documents**

- **Primary Guide**: `CURSOR_IMPLEMENTER_SETUP_PROMPT.md`
- **Executive Summary**: `CURSOR_IMPLEMENTER_HANDOFF_FINAL.md`
- **Quick Reference**: `CURSOR_IMPLEMENTER_QUICK_REF.md`
- **Navigation Hub**: `CURSOR_IMPLEMENTER_INDEX.md`

---

## 📞 **Support**

If stuck, refer to:
1. `CURSOR_IMPLEMENTER_SETUP_PROMPT.md` → Troubleshooting section
2. `scripts/verify-iona-gate.ps1` → Self-diagnosing script
3. `docs/BossCat/IONA_SETUP_GUIDE.md` → Setup instructions

---

**ECRR Mantra**: *Examine → Clean → Report → Role*  
**BossCat Principle**: *Deploy, maintain, and audit with precision, speed, and accountability*

---

**Checklist Created**: 2025-10-07  
**For**: cursor{implementer}  
**Task**: IONA-GATE-002  
**Authority**: BossCat OEM

🐾 **Track your progress. Check off items as you go. Signal completion when all items are checked.**

*The gate awaits. Excellence is expected. Proceed with confidence.*

