# 📋 PR-1: JSON Contracts + Validation Gate (AJV)

> ## IMPLEMENTED — pre-merge spec of 2025-10-23, shipped
>
> The gate this spec describes is live: `.github/workflows/json-validation-gate.yml` (push + PR on
> `schema/**`, `docs/status/**`; KEEP per the 2026-08-03 audit) validates `schema/status-tests.schema.json`
> and `schema/gate-verification-results.schema.json` with `ajv` (`^8.20.0`, `ajv-formats ^3.0.1` — newer
> than the versions pinned below). The `status-auto-update.yml` workflow it planned to chain from was
> removed in the per-push-failure cleanup and no longer exists. Kept unedited as the design record.

**Authority:** BossCat OEM  
**Status:** Ready to Implement  
**Created:** 2025-10-23  
**Target Merge:** Post-PR #196 & #193  

---

## 🎯 Overview

<!-- markdownlint-disable-next-line MD013 -->
This PR implements a **JSON schema validation gate** using AJV (Another JSON Schema Validator) to prevent future auto-update failures by validating all artifact contracts before they're committed.

**Key Principle:** Fail closed - if validation fails, the pipeline stops.

---

## 📊 Scope

### Files to Create

1. `schema/status-tests.schema.json` - Test results contract
2. `schema/gate-verification-results.schema.json` - Gate verification contract  
3. `.github/workflows/json-validation-gate.yml` - CI/CD validation workflow

### Files to Modify

1. `.github/workflows/status-auto-update.yml` - Add validation gate dependency
2. `package.json` - Add AJV dependencies

### No Changes

- ✅ No UI modifications
- ✅ No dashboard changes
- ✅ No monitoring logic changes

---

## 📝 JSON Schemas to Define

### 1. `schema/status-tests.schema.json`

**Purpose:** Validate test results structure in `docs/status/tests.json`

**Required Fields:**

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://otel-ops-pack.local/schemas/status-tests.json",
  "title": "Status Tests Results",
  "type": "object",
  "properties": {
    "timestamp": { "type": "string", "format": "date-time" },
    "canaryTest": { "type": "string", "enum": ["PASS", "FAIL", "PENDING"] },
    "verifyPipeline": { "type": "string", "enum": ["PASS", "FAIL", "PENDING"] },
    "traceID": { "type": "string", "pattern": "^[a-f0-9]{32}$" },
    "logsInClickHouse": { "type": "string" },
    "metricsActive": { "type": "boolean" }
  },
  "required": ["timestamp", "canaryTest", "verifyPipeline"],
  "additionalProperties": false
}
```

### 2. `schema/gate-verification-results.schema.json`

**Purpose:** Validate gate verification results in `artifacts/gate-verification-results.json`

**Required Fields:**

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://otel-ops-pack.local/schemas/gate-verification-results.json",
  "title": "Gate Verification Results",
  "type": "object",
  "properties": {
    "timestamp": { "type": "string", "format": "date-time" },
    "gateId": { "type": "string", "pattern": "^GATE-[0-9]{3}$" },
    "status": { "type": "string", "enum": ["READY", "WARN", "FAIL"] },
    "checks": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "name": { "type": "string" },
          "status": { "type": "string", "enum": ["PASS", "FAIL", "SKIP"] },
          "duration_ms": { "type": "integer", "minimum": 0 }
        },
        "required": ["name", "status"]
      }
    },
    "evidence": { "type": "string" }
  },
  "required": ["timestamp", "gateId", "status", "checks"],
  "additionalProperties": false
}
```

---

## ⚙️ CI/CD Workflow: `json-validation-gate.yml`

**Trigger:** Before status-auto-update runs (as dependency)

**Steps:**

```yaml
name: JSON Validation Gate
on:
  push:
    branches: [main]
    paths:
      - 'schema/**'
      - 'docs/status/**'
      - 'artifacts/gate-verification-results.json'
  pull_request:
    paths:
      - 'schema/**'
      - 'docs/status/**'
      - 'artifacts/gate-verification-results.json'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install validation tools
        run: npm i -g ajv-cli ajv-formats
      
      - name: Validate status-tests.json
        run: |
          ajv validate \
            -s schema/status-tests.schema.json \
            -d docs/status/tests.json \
            --spec=draft2020 \
            --all-errors || exit 1
      
      - name: Validate gate-verification-results.json (if exists)
        run: |
          if [ -f artifacts/gate-verification-results.json ]; then
            ajv validate \
              -s schema/gate-verification-results.schema.json \
              -d artifacts/gate-verification-results.json \
              --spec=draft2020 \
              --all-errors || exit 1
          fi
      
      - name: 📋 Validation Summary
        if: always()
        run: |
          {
            echo '### JSON Validation Gate'
            echo '✅ All contracts validated'
            echo ''
            echo '**Files checked:**'
            echo '- `docs/status/tests.json`'
            echo '- `artifacts/gate-verification-results.json` (if exists)'
          } >> "$GITHUB_STEP_SUMMARY"
```

---

## 🔗 Integration with Status Auto-Update

**Modified:** `.github/workflows/status-auto-update.yml`

```yaml
jobs:
  # ... existing jobs ...
  
  # ADD THIS:
  validate-schemas:
    runs-on: ubuntu-latest
    name: JSON Validation Gate
    # Use the validation workflow or inline steps
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm i -g ajv-cli ajv-formats
      - run: |
          ajv validate \
            -s schema/status-tests.schema.json \
            -d docs/status/tests.json \
            --spec=draft2020 --all-errors || exit 1
  
  auto-update:
    runs-on: ubuntu-latest
    needs: validate-schemas  # ← ADD THIS DEPENDENCY
    # ... rest of workflow ...
```

---

## 📦 Dependencies to Add

**In `package.json`:**

```json
{
  "devDependencies": {
    "ajv": "^8.12.0",
    "ajv-cli": "^5.0.0",
    "ajv-formats": "^2.3.1"
  }
}
```

---

## ✅ Acceptance Criteria

- [ ] Both schema files created and valid
- [ ] Validation workflow runs on push/PR
- [ ] Status auto-update depends on validation
- [ ] Validation fails if schemas don't match artifacts
- [ ] Job summary documents validation results
- [ ] No existing artifacts break validation
- [ ] Documentation updated with schema reference
- [ ] Merge once all tests pass

---

## 🚀 Benefits

1. **Prevent Silent Failures:** Auto-update can't proceed without valid contracts
2. **Clear Contracts:** Schema documents expected structure for all tools
3. **Early Detection:** Validation happens before artifacts are committed
4. **Audit Trail:** Job summary shows what was validated
5. **Future-Proof:** Easy to add more schemas as needed

---

## 🐾 Canonical Reference

**Related Documents:**

- `docs/comfort-cat/GATE_PROTOCOL.md` - Gate readiness protocol
- `docs/comfort-cat/ECRR_FRAMEWORK.md` - ECRR methodology
- Current PR specs in this directory

**Fail-Closed Protocol:** If any schema validation fails, the entire auto-update gate stops.

---

**Status:** Ready for implementation  
**Authority:** BossCat OEM  
**Seal:** 🐾 Validation Gate Specification
