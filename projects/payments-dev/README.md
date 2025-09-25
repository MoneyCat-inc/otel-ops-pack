# Project sandbox: payments-dev

- Logs: C:\otel\projects\payments-dev\logs
- Scripts: C:\otel\projects\payments-dev\scripts
- Env: C:\otel\projects\payments-dev\.env

Launch scoped shell vars:

`powershell
pwsh -File scripts/enter.ps1 -EmitCanary
`

Verify in SigNoz Logs with filter: service.name = payments-dev
