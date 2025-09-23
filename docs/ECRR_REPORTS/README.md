# ECRR Reports

> **Examine → Clean → Report → Role** framework for documenting all significant changes and implementations.

## Overview

ECRR reports provide a structured way to document changes, implementations, and system modifications following the ECRR methodology. Each report includes a unique key for tracking and cross-referencing.

## File Naming Convention

All ECRR reports must follow the naming convention:
```
ECRR-YYYYMMDD-HHMMSS(-SLUG).md
```

Examples:
- `ECRR-20250923-001032.md` - Basic timestamp
- `ECRR-20250923-001032-NIGHTLY-TRACKER-SYNC.md` - With descriptive slug

## Front-Matter Requirements

Each ECRR report must include YAML front-matter with the following fields:

```yaml
---
ecrr_key: ECRR-YYYYMMDD-HHMMSS
timestamp_utc: YYYY-MM-DDTHH:MM:SSZ
branch: main
commit: <commit_sha>
scope: Brief description of what was implemented
actor: Who performed the work
outcome: success | partial | fail
links:
  pr: ""
  workflows: ["Workflow Name"]
artifacts:
  - path/to/artifact
version: 1
---
```

## Key Generation

Use the provided scripts to generate unique ECRR keys:

### PowerShell
```powershell
.\scripts\generate-ecrr-key.ps1
.\scripts\generate-ecrr-key.ps1 -Slug "FEATURE-NAME"
```

### Bash
```bash
./scripts/generate-ecrr-key.sh
./scripts/generate-ecrr-key.sh -s "FEATURE-NAME"
```

## Index

The canonical index of all ECRR reports is maintained automatically:
- **Human-readable**: [INDEX.md](./INDEX.md)
- **Machine-readable**: [index.json](./index.json)

## Automation

- **Auto-indexing**: The index is updated automatically when ECRR files are added/modified
- **PR Validation**: PRs that modify ECRR files must reference the ECRR key in the PR body
- **Filename Linting**: ECRR filenames are validated against the naming convention

## Integration

### PR Guardrails
The PR Guardrails workflow automatically:
- Validates ECRR filename format
- Requires ECRR key reference in PR body when ECRR files are modified

### Cross-References
ECRR keys should be referenced in:
- Commit messages: `docs(ecrr): ECRR-20250923-001032 — description`
- PR descriptions: Include the ECRR key for tracking
- Documentation: Link to specific ECRR reports when relevant

## Retention Policy

### Current Year
- Keep all ECRR reports for the current calendar year
- Maintain full index and cross-references

### Previous Year
- Keep all ECRR reports for the previous calendar year
- Maintain quarterly summaries (Q1, Q2, Q3, Q4)

### Older Years
- Retain quarterly reports (Q1–Q4) only
- Retain any "fail" or "incident" ECRR reports regardless of age
- Archive other reports to `docs/ECRR_REPORTS/archive/`

### Manual Curation
- The index generator does not delete files automatically
- Retention is managed through manual curation
- Review and archive annually

## Workflow Integration

### Creating ECRR Reports
1. Generate unique key: `./scripts/generate-ecrr-key.sh`
2. Create file: `docs/ECRR_REPORTS/ECRR-YYYYMMDD-HHMMSS.md`
3. Add front-matter with required fields
4. Follow ECRR structure: Examine → Clean → Report → Role

### PR Integration
1. Reference ECRR key in PR body: `ECRR-YYYYMMDD-HHMMSS`
2. PR Guardrails will validate filename format
3. Auto-indexing will update the index

### Search and Discovery
- Search by key: `grep -r "ECRR-YYYYMMDD-HHMMSS" .`
- Search by scope: Use the index table
- Search by outcome: Filter by success/partial/fail

## Quality Assurance

### Required Elements
- [ ] Unique ECRR key in filename and front-matter
- [ ] Complete YAML front-matter
- [ ] ECRR structure: Examine → Clean → Report → Role
- [ ] Evidence and artifacts documented
- [ ] Actor declaration

### Validation
- [ ] Filename matches convention
- [ ] Front-matter is valid YAML
- [ ] All required fields present
- [ ] Links to artifacts are valid
- [ ] ECRR Gate section completed

## Examples

See the [INDEX.md](./INDEX.md) for all available ECRR reports and their scopes.

## Support

For questions about ECRR reports:
1. Check existing reports in the index
2. Review this README for conventions
3. Use the key generation scripts
4. Follow the ECRR methodology structure
