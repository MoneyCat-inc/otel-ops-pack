# Release Notes — IONA Gate Promotion

Release Date: 2025-10-13  
Gate Phrase: @cat ready-for-gate  
Gate: IONA  
Branch: main  
Commit: e6ade399

---

## Summary

BossCat has verified the IONA gate for both CI and PROD. All required evidence is present, including queue-steward verification for PROD. Verdict is READY for promotion under ECRR governance.

- CI: READY (non-prod evidence set sufficient)
- PROD: READY (queue-steward verification present)

---

## Evidence Links

- Gate Results (JSON): DELT/ARTF/gate-verification-results.json
- Latest ECRR Gate Report: docs/ecrr/ECRR_REPORTS/ECRR_GATE_RUN_LATEST.md
- PR Comment: PR_COMMENT_IONA_GATE_002_FINAL.md
- Status Inputs:
  - .github/workflows/bosscat-gate-verify.yml
  - docs/status/tests.json
  - docs/status.html
  - docs/observability/snapshots
  - docs/IONA_ERRORS.md
  - docs/cheatsheets
  - index.html
- PROD Queue Evidence: artifacts/queue-steward-verification.txt

---

## Operational Notes

- Queue-steward artifact is ephemeral by design and may be gitignored; verifier checks presence only.
- SigNoz helper located at ALFA/TEST/helpers/signoz.ts.
- Nightly and governance automations remain unchanged.

---

## Verification Commands

```powershell
# CI gate verification
pwsh -File scripts/verify-iona-gate.ps1 -Gate IONA -Site ci

# PROD gate verification
pwsh -File scripts/verify-iona-gate.ps1 -Gate IONA -Site prod
```

---

## ECRR Declaration

Evidence recorded to disk; decisions traceable to artifacts listed above. Promotion remains subject to BossCat OEM approval in accordance with governance policy.
