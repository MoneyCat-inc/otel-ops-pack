# 📂 Cheat Sheets & Workarounds

**Location**: `docs/cheatsheets/`  
**Purpose**: Proven solutions to prevent re-debugging the same issues over and over

## 🚨 **CRITICAL: Check Here First**

**ALWAYS CHECK HERE FIRST** before implementing any solution. These cheat sheets contain proven fixes for issues that have been encountered and solved before.

## 🚀 **Quick Access**

### **📋 One-Page Reference**
- **`QUICK_REFERENCE.md`** - Markdown version for quick scanning
- **`QUICK_REFERENCE.html`** - Visual HTML version (print to PDF)
- **Generate PDF**: `pwsh -File scripts/generate-quick-reference-pdf.ps1`

### **🎯 Emergency Quick Fixes**
- **Dashboard No Panels** → Check `signoz-dashboard.md` (use LOGS data source)
- **Audio Latency High** → Check `mic.md` (disable DSP)
- **Cross-Origin Fails** → Check `isolation.md` (COOP/COEP headers)
- **Worker Won't Start** → Check `workers.md` (kill switch + bootstrap)

## 📋 **Available Cheat Sheets**

### **🔒 Cross-Origin & Security**
- **`isolation.md`** - Cross-Origin Isolation (Firefox + Vercel) headers and workarounds

### **🎤 Audio & Microphone**
- **`mic.md`** - Low-latency microphone capture and DSP settings
- **`pitch.md`** - Pitch tracking stack (CREPE/YIN) and smoothing

### **📊 Practice Flow & Analytics**
- **`practice-flow.md`** - Practice Flow JSON schema and local-first implementation
- **`analytics.md`** - Instant Practice Rollout A/B tests and analytics events

### **🔧 System & Infrastructure**
- **`loudness.md`** - Loudness guardrails and strain detection
- **`workers.md`** - Background Worker (BossCat/Codex-Local) configuration
- **`ui-a11y.md`** - UI & Accessibility guardrails and standards

### **📈 Observability**
- **`signoz-dashboard.md`** - SigNoz dashboard creation and troubleshooting
- **`signoz-queries.md`** - SigNoz query syntax and data source selection

## 🎯 **Quick Problem Resolution**

### **Audio Issues**
- **Latency too high** → Check `mic.md` (disable DSP)
- **Pitch tracking fails** → Check `pitch.md` (fallback to YIN)
- **Volume warnings** → Check `loudness.md` (calibrate thresholds)

### **Cross-Origin Issues**
- **Service Worker strips headers** → Check `isolation.md` (coi-serviceworker)
- **Fonts/CDN blocked** → Check `isolation.md` (CORS headers)

### **Dashboard Issues**
- **No panels showing** → Check `signoz-dashboard.md` (use LOGS data source)
- **Wrong data source** → Check `signoz-queries.md` (Prometheus vs Logs)

### **Worker Issues**
- **Agent fails to start** → Check `workers.md` (PATH + bootstrap)
- **Budget exceeded** → Check `workers.md` (≤2 jobs, ≤10 files, ≤200 LOC)

## 🔄 **How to Use**

1. **Encounter an issue** → Check relevant cheat sheet
2. **Follow proven solution** → Don't reinvent the wheel
3. **Update cheat sheet** → Add new workarounds as discovered
4. **Share knowledge** → Link to cheat sheets in PRs/issues

## 📝 **Contributing**

When you solve a new issue:
1. **Document the solution** in the relevant cheat sheet
2. **Add workarounds** for common pitfalls
3. **Update this index** if creating new cheat sheet
4. **Test the solution** before documenting

---

**Remember**: These cheat sheets prevent hours of re-debugging. Use them!
