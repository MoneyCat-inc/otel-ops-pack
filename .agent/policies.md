# Agent Policies - Observability Pipeline

## Security
- No hardcoded secrets; use env or local config; keep localhost only unless specified
- JWT tokens, API keys, and passwords must be redacted in logs and configs
- CORS settings restricted to localhost/127.0.0.1 unless explicitly required
- Collector endpoints should not be exposed to external networks without authentication

## Privacy
- Redact tokens/emails; do not log person-identifiable data
- Use `attributes/redact` processor to strip sensitive fields
- Ensure PII is not forwarded to external observability platforms
- Log rotation and retention policies must be defined

## Observability
- All configuration changes must be validated with `otelcol-contrib validate`
- Canary tests must pass before merging observability changes
- Maintain backward compatibility with existing SigNoz dashboards
- Collector service must restart cleanly after configuration changes

## Scope
- Change only files in declared `scope.paths`
- Never modify system files outside the project directory
- Preserve existing PowerShell script functionality
- Maintain Windows service compatibility

## Tests
- You must run lint/build/unit if they exist; do not skip failing tests
- Canary verification must pass for observability changes
- Simple smoke tests must validate all three data sources (OTLP, files, events)
- Collector configuration must validate before deployment

## Documentation
- Update README.md for significant changes
- Document new configuration options
- Maintain changelog for version tracking
- Include troubleshooting steps for common issues

