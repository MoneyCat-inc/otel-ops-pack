# 🚀 cursor{implementer} Quick Reference Card
**IONA Gate Integration & Diagnostic Shell**

---

## 📁 Essential Files

| File | Purpose |
|------|---------|
| `CURSOR_IMPLEMENTER_SETUP_PROMPT.md` | **Primary guide** - complete implementation instructions |
| `CURSOR_IMPLEMENTER_HANDOFF_FINAL.md` | Executive summary and status dashboard |
| `scripts/verify-iona-gate.ps1` | Local verification script (run before signaling gate) |
| `docs/BossCat/IONA_ECRR_REPORT.md` | ECRR documentation (update as you progress) |

---

## 🎯 Two-Phase Mission

### **Phase 1: Unblock Testing (2%)**
**Fix**: `synthetic/send_iona_boot_span.py` (exit code -1073741819)

**Option A** (preferred): Debug and fix
```powershell
python --version
pip list | grep opentelemetry
python synthetic/send_iona_boot_span.py --verbose
```

**Option B** (alternative): Document bypass
- Edit `scripts/verify-iona-gate.ps1` (remove synthetic check)
- Create `docs/BossCat/IONA_SYNTHETIC_SPAN_BYPASS.md`

---

### **Phase 2: Build Diagnostic Shell (3%)**
**Goal**: Create `/diagnostics` route with live telemetry

**Files to Create** (12 total):
```
app/diagnostics/page.tsx                    # Route
components/TelemetryShell.tsx               # Main component
components/telemetry/MetricsPanel.tsx       # Metrics display
components/telemetry/TracesPanel.tsx        # Traces display
components/telemetry/LogsPanel.tsx          # Logs display
components/telemetry/ControlsPanel.tsx      # Controls
app/api/telemetry/stats/route.ts            # Stats API
app/api/telemetry/metrics/route.ts          # Metrics API
app/api/telemetry/traces/route.ts           # Traces API
app/api/telemetry/logs/route.ts             # Logs API
app/api/telemetry/emit-span/route.ts        # Emit span API
docs/BossCat/IONA_DIAGNOSTICS_GUIDE.md      # Documentation
```

---

## ⚡ Essential Commands

### **Setup**
```powershell
pnpm install
npx playwright install --with-deps chromium
pip install opentelemetry-sdk opentelemetry-exporter-otlp-proto-grpc
docker-compose up -d
```

### **Development**
```powershell
pnpm dev                                    # Start dev server
Start-Process "http://localhost:3000"       # Open app
Start-Process "http://localhost:3000/diagnostics"  # Open diagnostics
```

### **Testing**
```powershell
pnpm playwright test scripts/iona-snapshot.spec.ts  # Run all tests
pwsh -File scripts/verify-iona-gate.ps1             # Local verification
pnpm run build                                       # Build check
```

### **Verification**
```powershell
npx playwright show-report                  # View test report
ls artifacts/iona-*.png                     # Check screenshots
curl http://localhost:8080                  # Check SigNoz
```

---

## ✅ Definition of Done

### **Phase 1**
- [ ] Synthetic span fixed OR bypass documented
- [ ] `scripts/verify-iona-gate.ps1` passes

### **Phase 2**
- [ ] `/diagnostics` route functional
- [ ] All panels render and update
- [ ] API routes return data
- [ ] Playwright tests pass (14 total)
- [ ] Screenshot: `artifacts/iona-diagnostics.png`

### **ECRR**
- [ ] `docs/BossCat/IONA_ECRR_REPORT.md` updated
- [ ] `docs/BossCat/IONA_DIAGNOSTICS_GUIDE.md` created
- [ ] Commit messages ECRR-formatted
- [ ] Actor declaration: cursor{implementer}

---

## 🐾 Signal Completion

After all checks pass:
```
@cat ready-for-gate
```

---

## 📚 References

- **Setup**: `CURSOR_IMPLEMENTER_SETUP_PROMPT.md`
- **Handoff**: `CURSOR_IMPLEMENTER_HANDOFF_FINAL.md`
- **ECRR**: `docs/BossCat/IONA_ECRR_REPORT.md`
- **Agents**: `AGENTS.md`

---

**🐾 BossCat OEM** | **IONA-GATE-002** | **2025-10-07**

