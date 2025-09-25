# ECRR Report — Sandbox Name Conflict Resolution (2025-09-24)

## Examine

- Detected duplicate project sandboxes: `projects/payments qa` (spaced) and `projects/payments-qa` (hyphenated).
- Risk: Inconsistent `service.name` and file paths causing split metrics/logs and confusion in SigNoz queries.
- References found in docs; active scripts/configs existed in both variants.

## Clean

- Canonicalized to hyphenated variant: `projects/payments-qa`.
- Removed files under spaced path:
  - `projects/payments qa/README.md`
  - `projects/payments qa/scripts/enter.ps1`
  - `projects/payments qa/config/collector.project.yaml`
- Verified no remaining code references to spaced path (only historical docs mention it).
- Ensured `projects/payments-qa/scripts/enter.ps1` exports:
  - `OTEL_SERVICE_NAME=payments-qa`
  - `OTEL_RESOURCE_ATTRIBUTES` includes `service.name=payments-qa, project=payments-qa`

## Report

- Files removed (duplicate path): 3
- Files retained/validated:
  - `projects/payments-qa/README.md`
  - `projects/payments-qa/scripts/enter.ps1`
  - `projects/payments-qa/config/collector.project.yaml`

### Verification

- Grep confirms no code references to spaced path remain.
- Launch command (example):
  ```powershell
  pwsh -File projects/payments-qa/scripts/enter.ps1 -EmitCanary
  ```
  Expected: canary written to `C:\otel\projects\payments-qa\logs\canary.log` and visible in SigNoz with `service.name = payments-qa`.

## Role

- Actor: Cursor Agent — Observability Copilot
- Scope: Project sandbox consolidation and hygiene.

## ✅ ECRR Gate

- Examine: duplicate directories identified; risks assessed
- Clean: removed spaced-path duplicate; standardized env vars
- Report: this document with verification steps
- Role: declared

## Next Actions

- Update any internal references in documentation to prefer `payments-qa`.
- Consider adding a repo check to prevent directories with spaces under `projects/`.


