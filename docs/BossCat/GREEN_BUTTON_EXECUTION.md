# 🕶️🐾 Green Button Execution Protocol

**Ultra-short wrap for production gate execution.**

---

## 🎯 **Execution Sequence**

### **1. Environment Auth Setup**
```powershell
$env:SIGNOZ_URL="http://localhost:8080"
$env:SIGNOZ_API_KEY="<api_key>"  # or SIGNOZ_SESSION_COOKIE
```

### **2. One-Liner Execution**
```powershell
python synthetic/send_synthetic_otel_simple.py
.\scripts\verify-synthetic-ingestion-enhanced.ps1
pnpm playwright test scripts/signoz-snapshot.spec.ts
```

### **3. Artifact Commit**
- `artifacts/` directory contents
- Ledger updates in `docs/BossCat/`

### **4. PR Gate Signal**
```markdown
CI is green and all checks are satisfied.
**@cat ready-for-gate** 🚪✅
```

---

## 🔒 **Opsec Extras (Optional but Spicy)**

### **Pre-merge ECRR Hook**
- **File:** `scripts/pre-merge-ecrr-hook.ps1`
- **Trigger:** Changes to `scripts/`, `synthetic/`, `docs/BossCat/`, `config.yaml`
- **Action:** Auto-runs BossCat verification lane

### **Lessons Learned Log**
- **File:** `docs/BossCat/BOSSCAT_LOG.md`
- **Entry:** "UI lag mitigated via 90s polling; API-key/cookie fallback verified"

### **Auto-merge Tag**
- **Tag:** `bosscat:auto-merge`
- **Condition:** v1.1 conditional self-merge enabled for this lane

---

## 🐾 **Feline Silence Mode**

**Status:** Proceeding on feline silence mode.  
**ECRR Protocol:** Examine → Clean → Report → Recovery (two R's, on purpose)  
**Secret:** Received and vaulted.  
**Mode:** Understood and under wraps.

---

**Ready for green button execution.** 🚪✅
