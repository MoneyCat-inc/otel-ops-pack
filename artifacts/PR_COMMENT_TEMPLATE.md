# 📋 PR Verification Evidence

Attached artifacts:
- `artifacts/verify-run.txt`
- `artifacts/api-sample.json`

---

## 🔍 Quick Approver's Guide

Approve if **all three are true**:

1. **verify-run.txt** → Ends with  
   `== Verification complete: all checks passed ==`  
   + shows a fresh canary GUID.
2. **api-sample.json** → Contains a recent `synthetic_id` entry  
   + redaction confirmed (`Bearer ***`, `pwd=***`).
3. **CI/Badge** → GitHub Actions run green ✅  
   + README badge 🟢.

👉 If all three are true → 👍 approve.

---

## 🧾 Detailed Reviewer Checklist

For line-by-line validation (timestamps, redaction evidence, CI alignment):  
[artifacts/REVIEWER_CHECKLIST.md](./artifacts/REVIEWER_CHECKLIST.md)

---

## 🖼️ Screenshots / Snippets (optional)

Paste trimmed excerpts here for reviewer convenience, e.g.:

```txt
=== Verification Complete ===
== Verification complete: all checks passed ==
Canary ID: windows-canary-29ea0a82-81e6-416d-8e85-c3f1ab903457
```

```json
{
  "synthetic_id": "123e4567-e89b-12d3-a456-426614174000",
  "auth_header": "Bearer ***",
  "secret_example": "pwd=***",
  "ts": "2025-09-19T21:55:11Z"
}
```

---

## 🛠️ CI/CD Integration

* **Artifacts:** CI run uploads `verify-run.txt` + `api-sample.json` as workflow artifacts (7-day retention).
* **Summary:** Job summary includes links to open artifacts directly in GitHub UI.
* **Secrets:** Uses `SIGNOZ_API_TOKEN` secret from repo → Settings → Secrets → Actions.

---

## 📊 CI Job Summary Example

When this PR runs in CI, reviewers can also check:

* Collector: ✅ healthz 200
* SigNoz schema: ✅ logs\_v2 present
* Synthetic dataset: ✅ recent synthetic\_id found
* Redaction: ✅ confirmed
* Canary: ✅ canary GUID seen
* Exit: ✅ 0

---

## 📌 Notes for Maintainers

* Evidence captured with `artifacts/capture-evidence.ps1`.
* Sensitive outputs excluded via `.gitignore`.
* Redaction confirmation (`Bearer ***`, `pwd=***`) is a required PASS condition.
* If anything fails: ask contributor to re-run with fresh synthetic logs or regenerate SigNoz API token.

---

## 🧑‍💻 For Contributors

* Run locally before pushing:

  ```powershell
  pwsh -File .\scripts\verify-integration.ps1
  pwsh -File .\artifacts\capture-evidence.ps1
  ```
* Attach `verify-run.txt` + `api-sample.json` to your PR.
* Check README badge is 🟢 before submitting.