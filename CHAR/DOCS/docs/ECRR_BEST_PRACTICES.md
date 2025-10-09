# ECRR Best Practices

## Structure
- Always include the 4 sections: Examine → Clean → Report → Role.
- Add a mandatory "ECRR Gate" checklist at the end.

## Role & Accountability
- Include a clear Actor Declaration in the Role section.
- Use consistent agent names: Cursor Agent, Cursor-Local, ChatGPT Agent, Codex Agent.

## Evidence & Verification
- Provide runnable checks (commands) for every change.
- Reference artifacts placed under artifacts/.

## Production Readiness
- Add a "Production Readiness Assessment" to deployment/merge/"complete" reports.
- Use clear status: PRODUCTION READY, NEEDS REVIEW, NOT PRODUCTION READY.

## Automation
- Use scripts in scripts/ to standardize fixes across many reports.
- Re-run validation after edits: scripts/validate-ecrr-compliance.ps1.

## Guardrails
- Local-first, safety, idempotence, verification — always.


