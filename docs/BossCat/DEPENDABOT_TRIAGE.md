# Dependabot Triage — 2026-06-13

## Critical (2 open at triage time)

| Alert | Package | Chain | Mitigation |
|-------|---------|-------|------------|
| #255 | `protobufjs` | OTel gRPC exporters (dev) | `pnpm.overrides`: `>=8.0.1` |
| #161 | `fast-xml-parser` | `@aws-sdk/xml-builder` | `pnpm.overrides`: `>=5.3.4`; lockfile on 5.8.0 |

## Actions taken

- Added `pnpm.overrides` in `package.json`
- Ran `pnpm install` to refresh `pnpm-lock.yaml`

## Notes

- Both are **transitive** (not direct dependencies).
- `protobufjs` 8.6.3 on npm may already include the 8.0.1+ patch; Dependabot can lag until lockfile push + rescan.
- `fast-xml-parser` 5.8.0 is above patched `5.3.5`; alert may clear after GitHub rescan.
- Full backlog: 158 open alerts — schedule monthly `pnpm audit` + targeted `@aws-sdk/*` / OTel bumps.

## Verify

```powershell
pnpm why protobufjs
pnpm why fast-xml-parser
gh api "repos/MoneyCat-inc/otel-ops-pack/dependabot/alerts?state=open&severity=critical" --jq 'length'
```
