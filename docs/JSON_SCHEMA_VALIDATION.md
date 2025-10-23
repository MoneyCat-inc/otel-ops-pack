# 📋 JSON Schema Validation Guide

**Authority:** BossCat OEM  
**Status:** Active (as of PR-1)  
**Purpose:** Document the validation gate mechanism for artifact contracts

---

## 🎯 Overview

The JSON schema validation gate ensures all artifacts conform to defined contracts before they're committed to the repository. This is a **fail-closed** system: if validation fails, the pipeline stops.

**Key Principle:** Invalid contracts = pipeline stops (no silent failures)

---

## 📂 Schema Files

### Location
All schema files are in the `schema/` directory at the repository root.

```
schema/
├── status-tests.schema.json              # Validates docs/status/tests.json
└── gate-verification-results.schema.json # Validates artifacts/gate-verification-results.json
```

### `status-tests.schema.json`

**Purpose:** Validates the test results stored in `docs/status/tests.json`

**Enforced Fields:**
- `version` (string, semver format)
- `endedAt` (ISO 8601 datetime)
- `actor` (string)
- `authority` (enum: BossCat OEM, Agent, System)
- `verdict` (enum: READY, WARN, FAIL)
- `gate` (integer)
- `checks` (array of check objects)

**File Path:** `docs/status/tests.json`

**Updated By:** Status auto-update workflow, gate verification scripts

### `gate-verification-results.schema.json`

**Purpose:** Validates gate verification results

**Enforced Fields:**
- `timestamp` (ISO 8601 datetime)
- `gateId` (pattern: GATE-### e.g., GATE-007)
- `status` (enum: READY, WARN, FAIL)
- `checks` (array with name, status, optional reason)

**File Path:** `artifacts/gate-verification-results.json`

**Updated By:** Gate verification workflows

---

## 🏃 Running Validation Locally

### Prerequisites

```bash
npm install -g ajv-cli ajv-formats
```

Or add to `package.json`:
```json
{
  "devDependencies": {
    "ajv": "^8.12.0",
    "ajv-cli": "^5.0.0",
    "ajv-formats": "^2.3.1"
  }
}
```

### Validate Individual Files

**Status Tests:**
```bash
ajv validate \
  -s schema/status-tests.schema.json \
  -d docs/status/tests.json \
  --spec=draft2020 \
  --all-errors
```

**Gate Verification Results:**
```bash
ajv validate \
  -s schema/gate-verification-results.schema.json \
  -d artifacts/gate-verification-results.json \
  --spec=draft2020 \
  --all-errors
```

### Validate All Schemas

```bash
# Run all validations
for schema in schema/*.schema.json; do
  echo "Validating against $schema..."
  # Determine matching data file and validate
done
```

---

## 🔄 CI/CD Integration

The validation runs automatically via `.github/workflows/json-validation-gate.yml`

### Trigger Events
- Push to `main` branch
- Pull requests modifying:
  - `schema/**`
  - `docs/status/**`
  - `artifacts/gate-verification-results.json`

### Workflow Steps
1. Checkout code
2. Setup Node.js v20
3. Install AJV tools
4. Validate `status-tests.json` (required)
5. Validate `gate-verification-results.json` (if exists)
6. Generate job summary

### Integration with Status Auto-Update

The `status-auto-update.yml` workflow now has a dependency:

```yaml
jobs:
  validate-schemas:
    runs-on: ubuntu-latest
    # Validation steps...
  
  auto-update:
    runs-on: ubuntu-latest
    needs: [validate-schemas]  # Must pass before proceeding
    # Auto-update steps...
```

---

## ➕ Adding New Schemas

### Step 1: Create Schema File

Save to `schema/your-artifact.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://otel-ops-pack.local/schemas/your-artifact.json",
  "title": "Your Artifact Name",
  "type": "object",
  "properties": {
    "field1": { "type": "string" },
    "field2": { "type": "integer" }
  },
  "required": ["field1"],
  "additionalProperties": true
}
```

### Step 2: Update Validation Workflow

Add validation step to `.github/workflows/json-validation-gate.yml`:

```yaml
- name: Validate your-artifact.json
  run: |
    if [ -f path/to/your-artifact.json ]; then
      ajv validate \
        -s schema/your-artifact.schema.json \
        -d path/to/your-artifact.json \
        --spec=draft2020 \
        --all-errors || exit 1
    fi
```

### Step 3: Test Locally

```bash
ajv validate \
  -s schema/your-artifact.schema.json \
  -d path/to/your-artifact.json \
  --spec=draft2020 \
  --all-errors
```

### Step 4: Document

Update this file with the new schema details and file path.

---

## 🐛 Troubleshooting

### Error: Schema validation failed

**Symptoms:**
```
Validation failed for docs/status/tests.json
  property "verdict" must be one of [READY, WARN, FAIL]
```

**Solution:**
1. Check the error message - it identifies the failing field and constraint
2. Update the artifact file to match the schema requirement
3. Rerun validation locally to confirm fix
4. Commit and push

**Common Issues:**
- Missing required fields: Check schema `required` array
- Wrong enum value: Use exact values from schema definition
- Wrong data type: Ensure field types match schema (string vs number, etc.)

### Error: File not found

**Symptoms:**
```
ENOENT: no such file or directory, open 'docs/status/tests.json'
```

**Solution:**
1. Ensure artifact file exists at expected path
2. Check file path in validation command
3. For optional artifacts, use conditional checks: `if [ -f path ]; then ...`

### Error: ajv command not found

**Symptoms:**
```
command not found: ajv
```

**Solution:**
```bash
npm install -g ajv-cli ajv-formats
# Or use npx
npx ajv validate -s schema/status-tests.schema.json -d docs/status/tests.json
```

### Validation passes locally but fails in CI

**Common Causes:**
- Line ending differences (use `--spec=draft2020` with consistent line endings)
- File encoding (ensure UTF-8)
- Path differences (use absolute paths in CI)

**Solution:**
```bash
# Run with same flags as CI
ajv validate \
  -s schema/status-tests.schema.json \
  -d docs/status/tests.json \
  --spec=draft2020 \
  --all-errors
```

---

## 📊 Schema Specification Reference

### JSON Schema Syntax

All schemas use JSON Schema Draft 2020-12 specification.

**Common Keywords:**
- `$schema` - Schema version identifier
- `$id` - Unique schema identifier
- `title` - Human-readable name
- `type` - Data type (object, string, integer, array, etc.)
- `properties` - Object field definitions
- `required` - Array of required field names
- `enum` - Array of allowed values
- `pattern` - Regular expression for strings
- `format` - Format hint (date-time, email, etc.)
- `minimum` / `maximum` - Number constraints
- `minItems` / `maxItems` - Array size constraints
- `additionalProperties` - Allow extra fields (true/false)

### Validation Features

**Format Validation** (requires `ajv-formats`):
```json
{
  "timestamp": {
    "type": "string",
    "format": "date-time"
  }
}
```

**Pattern Matching** (regex):
```json
{
  "gateId": {
    "type": "string",
    "pattern": "^GATE-[0-9]{3}$"
  }
}
```

**Enum Constraints:**
```json
{
  "status": {
    "type": "string",
    "enum": ["READY", "WARN", "FAIL"]
  }
}
```

---

## 🔗 Related Documentation

- **PR-1 Specification:** `docs/comfort-cat/PR-1_JSON_VALIDATION_GATE.md`
- **Gate Protocol:** `docs/comfort-cat/GATE_PROTOCOL.md`
- **ECRR Framework:** `docs/comfort-cat/ECRR_FRAMEWORK.md`
- **AJV Documentation:** https://ajv.js.org/

---

## 🐾 Canonical Reference

This documentation is part of the "Comfort Cat" canonical reference suite.

**Authority:** BossCat OEM  
**Status:** Active standard  
**Last Updated:** 2025-10-23  

**Seal:** 🐾 JSON Schema Validation Guide
