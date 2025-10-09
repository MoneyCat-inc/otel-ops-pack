# Runbook: Adding New Components to Tetragram Structure

**Version:** 1.0  
**Last Updated:** 2025-10-09  
**Audience:** Developers, DevOps

---

## 🎯 Overview

This runbook explains how to add new components (apps, libraries, scripts, docs, configs) to the tetragram repository structure while maintaining guardrails compliance.

---

## 🏗️ Quick Reference: Where Things Go

```
ALFA/  → Application & Source
  APPS/   New deployable apps/services
  LIBS/   New shared libraries/modules
  CORE/   Framework code
  OTEL/   OTel instrumentation
  TEST/   New test suites
  TOOL/   Developer tools

BRAV/  → Build, Runtime, Automation
  SCPT/   New scripts (CI/runtime/ops)
  DOCK/   New Dockerfiles
  INFR/   Infrastructure configs (helm/k8s)

CHAR/  → Compliance, Human, Audit
  DOCS/   New documentation
  EVID/   Reports/artifacts
  PRSV/   Archives/experiments

DELT/  → Data, Environment, Load
  CONF/   New configurations
  ASST/   Static assets
  FIXT/   Test fixtures
  TMPL/   Templates
```

---

## 📦 Adding a New Application

### Using the Scaffold

**Unix/macOS:**
```bash
bash BRAV/SCPT/new_app.sh my-service
```

**Windows:**
```powershell
pwsh -File BRAV\SCPT\new_app.ps1 -Name my-service
```

**Result:**
```
ALFA/APPS/my-service/
├── src/
│   └── index.js
├── config/
├── scripts/
├── README.md
└── package.json
```

### Manual Setup

1. **Create directory:**
   ```bash
   mkdir -p ALFA/APPS/my-service/src
   ```

2. **Add README:**
   - Purpose, build, run commands
   - Link to related docs in CHAR/DOCS/

3. **Add package.json or equivalent:**
   - Name, version, scripts
   - Dependencies

4. **Implement:**
   - Source code in `src/`
   - Tests in `ALFA/TEST/my-service/` or local `test/`
   - Config templates in `config/`

5. **Update CODEOWNERS:**
   ```
   /ALFA/APPS/my-service/ @your-team
   ```

6. **Verify guardrails:**
   ```bash
   python BRAV/SCPT/check_guardrails.py
   ```

---

## 📚 Adding a New Library

### Using the Scaffold

**Unix/macOS:**
```bash
bash BRAV/SCPT/new_lib.sh my-utils
```

**Windows:**
```powershell
pwsh -File BRAV\SCPT\new_lib.ps1 -Name my-utils
```

**Result:**
```
ALFA/LIBS/my-utils/
├── src/
│   └── index.js
├── README.md
└── package.json
```

### TypeScript Path Aliases

Ensure `tsconfig.base.json` includes:
```json
{
  "compilerOptions": {
    "paths": {
      "@alfa/*": ["ALFA/*"]
    }
  }
}
```

**Usage in consumers:**
```typescript
import { something } from '@alfa/LIBS/my-utils';
```

---

## 📝 Adding Documentation

**Location:** `CHAR/DOCS/`

**Categories:**
- **ADRs:** `CHAR/DOCS/ADR/NNNN-title.md`
- **Runbooks:** `CHAR/DOCS/runbooks/name.md`
- **Policies:** `CHAR/DOCS/policies/name.md`
- **Guides:** `CHAR/DOCS/<topic>/guide.md`

**Template:**
```markdown
# Document Title

**Author:** <name>  
**Date:** <YYYY-MM-DD>  
**Status:** Draft | Active | Deprecated

## Overview
<What this document covers>

## Details
<Content>
```

---

## 🔧 Adding Scripts

**Location:** `BRAV/SCPT/`

**Rules:**
1. All operational scripts go in `BRAV/SCPT/`
2. Make scripts executable: `chmod +x script.sh`
3. Add header comment explaining purpose
4. Workflows must call these (no long inline logic)

**Template:**
```bash
#!/usr/bin/env bash
# Script Name: <name>
# Purpose: <description>
# Usage: bash BRAV/SCPT/<name>.sh [args]

set -euo pipefail
# Implementation
```

---

## ⚙️ Adding Configuration

**Location:** `DELT/CONF/`

**Categories:**
- **Environment configs:** `DELT/CONF/<service>/`
- **Alert configs:** `DELT/CONF/alerts/`
- **Infrastructure:** `DELT/CONF/<infra-type>/`

**Rules:**
1. No secrets in configs (use env vars or secret managers)
2. Use templates in `DELT/TMPL/` for scaffolding
3. Document in `CHAR/DOCS/` how to use the config

---

## 🧪 Adding Tests

**Location:** `ALFA/TEST/`

**Structure:**
```
ALFA/TEST/
├── unit/              # Unit tests
├── integration/       # Integration tests
├── e2e/               # End-to-end tests
└── <app-name>/        # App-specific tests
```

**Or:** Co-locate with app:
```
ALFA/APPS/my-service/
└── test/              # Local tests
```

---

## 🛡️ Guardrails Compliance

**Always verify before committing:**
```bash
python BRAV/SCPT/check_guardrails.py --config BRAV/SCPT/guardrails.json
```

**Common Issues:**

| Issue | Cause | Fix |
|-------|-------|-----|
| Forbidden root | Created at wrong level | `git mv <dir> <tetragram-path>` |
| Unauthorized dir | New top-level dir | Move to plane or add to allowed list |
| Path depth | Nested too deep (>7) | Flatten directory structure |
| Ephemeral tracked | Committed logs/tmp/out | Add to .gitignore, `git rm --cached` |

---

## 🔄 Workflow Integration

**When adding CI/CD for new component:**

1. **Create script in BRAV/SCPT:**
   ```bash
   # BRAV/SCPT/build-my-service.sh
   #!/usr/bin/env bash
   cd ALFA/APPS/my-service
   npm ci
   npm run build
   ```

2. **Call from workflow:**
   ```yaml
   - name: Build my-service
     run: bash BRAV/SCPT/build-my-service.sh
   ```

3. **Keep inline logic ≤ 20 lines** (or guardrails will warn)

---

## 📋 Pre-Commit Checklist

Before committing new components:

- [ ] Code in correct plane (ALFA/BRAV/CHAR/DELT)
- [ ] README created with purpose/usage
- [ ] Guardrails check passes (`check_guardrails.py`)
- [ ] No secrets committed
- [ ] CODEOWNERS updated (if needed)
- [ ] Path depth ≤ 7
- [ ] TypeScript aliases work (if applicable)
- [ ] Tests added/passing
- [ ] Documentation updated

---

## 🚀 Examples

### Example 1: New Monitoring Service
```bash
# Create app
bash BRAV/SCPT/new_app.sh monitoring-dashboard

# Add implementation
cd ALFA/APPS/monitoring-dashboard
npm install express
# ... implement service

# Verify
python BRAV/SCPT/check_guardrails.py
```

### Example 2: New Shared Utility Library
```bash
# Create library
bash BRAV/SCPT/new_lib.sh date-utils

# Implement
cd ALFA/LIBS/date-utils
# ... add functions

# Use in app
# import { formatDate } from '@alfa/LIBS/date-utils';
```

### Example 3: New Operational Script
```bash
# Create script
cat > BRAV/SCPT/deploy-staging.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "Deploying to staging..."
# ... implementation
EOF

chmod +x BRAV/SCPT/deploy-staging.sh

# Call from workflow
# - run: bash BRAV/SCPT/deploy-staging.sh
```

---

## 🔍 Troubleshooting

### "Unauthorized top-level directory" Error
**Cause:** Created directory at repo root  
**Fix:** Move to appropriate plane
```bash
git mv my-new-dir ALFA/APPS/my-new-dir
```

### "Forbidden legacy root" Error
**Cause:** Used a forbidden name (scripts/, docs/, config/, etc.)  
**Fix:** Use tetragram location instead
```bash
# Don't create scripts/ - use BRAV/SCPT/
# Don't create docs/ - use CHAR/DOCS/
```

### "Path depth exceeds limit" Error
**Cause:** Too many nested directories (>7 levels)  
**Fix:** Flatten structure
```bash
# Bad:  ALFA/APPS/app/components/ui/buttons/primary/large/index.tsx
# Good: ALFA/APPS/app/components/buttons/PrimaryLarge.tsx
```

---

## 📚 Related Documentation

- **ADR-0001:** [`CHAR/DOCS/ADR/0001-tetragram-baseline.md`](../ADR/0001-tetragram-baseline.md)
- **Guardrails:** [`repo-structure-violations.md`](./repo-structure-violations.md)
- **CI Delegation:** [`ci-delegation.md`](./ci-delegation.md)
- **README:** Repository root

---

## 🐾 BossCat Compliance

**All new components must:**
1. Follow tetragram structure (ALFA/BRAV/CHAR/DELT)
2. Pass guardrails check (exit 0)
3. Include documentation
4. Avoid forbidden legacy names
5. Stay within path depth limit (7)

**Automation:**
- Guardrails CI workflow runs on all PRs
- Violations block merge
- Ephemeral directories (logs/, tmp/, etc.) tolerated when untracked

---

**Version:** 1.0  
**Maintained by:** BossCat OEM  
**Last Verified:** 2025-10-09

