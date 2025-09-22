# 📸 ECRR Canary Alert — Screenshot Checklist

**Date of Drill:** __________  
**Operator:** __________  

---

## 1. Baseline — Canary Healthy
| Expected | Observed | Screenshot |
|----------|----------|------------|
| Canary visible in SigNoz Logs Explorer (`service.name = ecrr-canary`) | ☐ Yes / ☐ No | [ ] Paste screenshot |
| `verify-integration.ps1` ends with "== Verification complete: all checks passed ==" | ☐ Yes / ☐ No | [ ] Paste screenshot |
| Canary GUID shown in logs | ☐ Yes / ☐ No | [ ] Paste screenshot |

---

## 2. Failure Drill — Canary Disabled
| Expected | Observed | Screenshot |
|----------|----------|------------|
| No new canary events for >15 minutes | ☐ Yes / ☐ No | [ ] Paste screenshot |
| SigNoz Alerts page shows **ECRR Canary Missing** alert firing | ☐ Yes / ☐ No | [ ] Paste screenshot |
| Alert severity: warning (labels: service=ecrr-canary, framework=ecrr) | ☐ Yes / ☐ No | [ ] Paste screenshot |

---

## 3. Recovery — Canary Re-enabled
| Expected | Observed | Screenshot |
|----------|----------|------------|
| Canary resumes in Logs Explorer | ☐ Yes / ☐ No | [ ] Paste screenshot |
| New canary GUID appears in logs | ☐ Yes / ☐ No | [ ] Paste screenshot |
| SigNoz Alerts page shows alert resolved | ☐ Yes / ☐ No | [ ] Paste screenshot |

---

## 4. Notifications (Optional)
| Expected | Observed | Screenshot |
|----------|----------|------------|
| Slack/Email/Webhook received alert notification | ☐ Yes / ☐ No | [ ] Paste screenshot |
| Slack/Email/Webhook shows **resolved** notification | ☐ Yes / ☐ No | [ ] Paste screenshot |

---

## 🧾 Notes
- Drill duration: __________ minutes  
- Any anomalies: ___________________________________  
- Follow-ups required: ☐ Yes / ☐ No → (list)  

---

✅ **Completion Criteria:** Canary alert fired when disabled, and resolved automatically when re-enabled. Screenshots attached for baseline, firing, and resolution.
