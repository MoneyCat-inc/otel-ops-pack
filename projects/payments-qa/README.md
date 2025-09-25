# Project sandbox: payments-qa

- Logs: C:\otel\projects\payments-qa\logs
- Scripts: C:\otel\projects\payments-qa\scripts
- Env: C:\otel\projects\payments-qa\.env

Launch scoped shell vars:

`powershell
pwsh -File scripts/enter.ps1 -EmitCanary
`

Verify in SigNoz Logs with filter: service.name = payments-qa
