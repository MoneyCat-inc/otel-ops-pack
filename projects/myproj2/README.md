# Project sandbox: myproj2

- Logs: C:\otel\projects\myproj2\logs
- Scripts: C:\otel\projects\myproj2\scripts
- Env: C:\otel\projects\myproj2\.env

Launch scoped shell vars:

`powershell
pwsh -File scripts/enter.ps1 -EmitCanary
`

Verify in SigNoz Logs with filter: service.name = myproj2
