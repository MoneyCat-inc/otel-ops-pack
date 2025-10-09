# Runbook: CI Workflow Delegation to BRAV/SCPT

**Purpose:** Guide for creating workflows that delegate to BRAV/SCPT scripts  
**Owner:** BossCat OEM / CI/CD Team  
**Last Updated:** 2025-10-09

---

## Overview

GitHub Actions workflows should be **thin delegators** that call scripts in `BRAV/SCPT/`. This keeps workflows maintainable and allows local testing.

**Rule:** Inline `run:` blocks should be ≤20 lines (enforced at 40 during migration, ratcheting to 20). Complex logic goes in `BRAV/SCPT/`.

---

## Pattern: Good Workflow (Thin Delegator)

```yaml
name: Example CI Job

on:
  pull_request:
  push:
    branches: [main]

jobs:
  my-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup
        run: |
          # Minimal setup only
          npm install -g pnpm
          pnpm install
      
      - name: Run my check
        run: |
          # Delegate to BRAV/SCPT
          pwsh -File BRAV/SCPT/my-check.ps1
          # Or: bash BRAV/SCPT/my-check.sh
```

**Benefits:**
- ✅ Workflow is readable
- ✅ Logic is testable locally
- ✅ Version controlled with code
- ✅ Can be reused across jobs
- ✅ Easier to maintain

---

## Anti-Pattern: Bad Workflow (Heavy Inline Logic)

```yaml
name: Bad Example

jobs:
  my-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Complex logic inline
        run: |
          # ❌ 50+ lines of inline bash/powershell
          npm install
          for file in $(find . -name "*.ts"); do
            if grep -q "badPattern" "$file"; then
              echo "Found bad pattern in $file"
              # ... more logic
              # ... more logic
              # ... (40+ more lines)
            fi
          done
          # ❌ Hard to test locally
          # ❌ Hard to maintain
          # ❌ Fails guardrails check
```

**Problems:**
- ❌ Workflow is complex and hard to read
- ❌ Can't test locally without running full workflow
- ❌ Harder to version and review
- ❌ Violates guardrails (>40 line inline run block)

---

## Migration Guide: Heavy Workflow → Delegated

### Step 1: Extract Logic to Script

**Create `BRAV/SCPT/my-check.ps1`:**
```powershell
#!/usr/bin/env pwsh
# My Check - Extracted from workflow
param(
    [string]$Environment = "dev"
)

Write-Host "Running my check in $Environment environment..."

# All the logic from the workflow
npm install
Get-ChildItem -Recurse -Filter "*.ts" | ForEach-Object {
    if (Select-String -Path $_.FullName -Pattern "badPattern" -Quiet) {
        Write-Host "Found bad pattern in $($_.FullName)"
        exit 1
    }
}

Write-Host "Check passed!"
```

### Step 2: Update Workflow to Delegate

**Update `.github/workflows/my-workflow.yml`:**
```yaml
- name: Run my check
  run: |
    pwsh -File BRAV/SCPT/my-check.ps1 -Environment ${{ github.event.inputs.environment || 'dev' }}
```

### Step 3: Test Locally

```powershell
# Test the script works
pwsh -File BRAV\SCPT\my-check.ps1

# Test with parameters
pwsh -File BRAV\SCPT\my-check.ps1 -Environment prod
```

### Step 4: Commit

```bash
git add BRAV/SCPT/my-check.ps1 .github/workflows/my-workflow.yml
git commit -m "refactor(ci): extract my-check logic to BRAV/SCPT

- Move complex logic from workflow to BRAV/SCPT/my-check.ps1
- Workflow now delegates (thin)
- Can be tested locally
- Passes guardrails check"
```

---

## Script Organization in BRAV/SCPT

### Subdirectories (examples)

```
BRAV/SCPT/
├── ci/                  # CI-specific scripts
│   ├── run-tests.ps1
│   └── generate-report.ps1
├── observability/       # Monitoring/SigNoz scripts
│   ├── emit-telemetry.ps1
│   └── check-health.ps1
├── security/            # Security scanning
│   ├── scan-secrets.ps1
│   └── scan-dependencies.ps1
├── ecrr/                # ECRR compliance
│   ├── collect-evidence.ps1
│   └── generate-report.ps1
└── [individual scripts at root for small utilities]
```

**Naming:**
- Use kebab-case: `my-script.ps1`
- Be descriptive: `check-signoz-health.ps1` not `check.ps1`
- Include extension: `.ps1` (PowerShell), `.sh` (Bash), `.py` (Python)

---

## Common Patterns

### Pattern 1: Simple Check

**Workflow:**
```yaml
- name: Check something
  run: pwsh -File BRAV/SCPT/check-thing.ps1
```

**Script (`BRAV/SCPT/check-thing.ps1`):**
```powershell
# Exit 0 if pass, non-zero if fail
if (Test-Condition) {
    Write-Host "Check passed!"
    exit 0
} else {
    Write-Host "Check failed!"
    exit 1
}
```

### Pattern 2: Generate Report

**Workflow:**
```yaml
- name: Generate report
  run: pwsh -File BRAV/SCPT/generate-report.ps1 -Output artifacts/report.json

- name: Upload artifact
  uses: actions/upload-artifact@v3
  with:
    name: report
    path: artifacts/report.json
```

**Script:** Outputs to specified location

### Pattern 3: With Environment Variables

**Workflow:**
```yaml
- name: Deploy
  env:
    ENVIRONMENT: ${{ github.event.inputs.environment }}
    API_KEY: ${{ secrets.API_KEY }}
  run: |
    pwsh -File BRAV/SCPT/deploy.ps1
```

**Script:** Reads from `$env:ENVIRONMENT`, `$env:API_KEY`

### Pattern 4: Multi-Step with Delegation

**Workflow:**
```yaml
- name: Setup
  run: pnpm install

- name: Build
  run: pwsh -File BRAV/SCPT/build.ps1

- name: Test
  run: pwsh -File BRAV/SCPT/test.ps1

- name: Package
  run: pwsh -File BRAV/SCPT/package.ps1
```

Each step delegates to a focused script.

---

## Testing Scripts Locally

### Before Committing

```powershell
# Test script runs
pwsh -File BRAV\SCPT\my-script.ps1

# Test with parameters
pwsh -File BRAV\SCPT\my-script.ps1 -Param1 value

# Test error handling
pwsh -File BRAV\SCPT\my-script.ps1 -ForceError

# Check exit code
$LASTEXITCODE  # Should be 0 for success
```

### Simulating CI Environment

```powershell
# Set environment variables like CI would
$env:GITHUB_WORKSPACE = $PWD
$env:GITHUB_REF = "refs/heads/main"

# Run script
pwsh -File BRAV\SCPT\my-script.ps1

# Clean up
Remove-Item env:GITHUB_WORKSPACE
Remove-Item env:GITHUB_REF
```

---

## Guardrails Compliance

### Check Workflow Complexity

**Command:**
```powershell
# Check inline run block length
python BRAV\SCPT\check_guardrails.py --config BRAV\SCPT\guardrails.json
```

**Will warn if:**
- Inline `run:` block > 40 lines (configurable)
- Workflow doesn't reference BRAV/SCPT at all

### Fix Long Inline Blocks

**Extract to script:**
1. Copy inline logic to new script in BRAV/SCPT/
2. Make script executable and testable
3. Replace inline block with script call
4. Test locally
5. Commit both workflow and script

---

## Best Practices

### DO ✅

- ✅ Keep workflows thin (delegation only)
- ✅ Put logic in BRAV/SCPT scripts
- ✅ Make scripts testable locally
- ✅ Use clear, descriptive names
- ✅ Add comments explaining parameters
- ✅ Handle errors properly (exit codes)
- ✅ Test before committing

### DON'T ❌

- ❌ Put 40+ lines of logic in workflows
- ❌ Duplicate logic across workflows
- ❌ Use inline scripts for complex operations
- ❌ Hardcode values (use parameters/env vars)
- ❌ Skip local testing
- ❌ Ignore guardrails warnings

---

## Example: Full Migration

**Before (80-line inline block):**
```yaml
- name: Complex deployment
  run: |
    # 80 lines of deployment logic
    # Can't test locally easily
    # Hard to maintain
```

**After (delegated):**

**Workflow:**
```yaml
- name: Deploy
  env:
    ENVIRONMENT: ${{ github.event.inputs.environment }}
  run: pwsh -File BRAV/SCPT/deploy-app.ps1
```

**Script (`BRAV/SCPT/deploy-app.ps1`):**
```powershell
#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = $env:ENVIRONMENT
)

# All 80 lines of logic here
# Can be tested locally
# Can be reused
# Version controlled
# Maintainable
```

---

## Troubleshooting

### Script Not Found

**Error:** `pwsh: BRAV/SCPT/my-script.ps1 not found`

**Fix:**
- Check path is correct (use forward slashes in workflows)
- Ensure script is committed
- Verify checkout action ran first

### Permission Denied (Unix)

**Error:** `Permission denied`

**Fix:**
```bash
chmod +x BRAV/SCPT/my-script.sh
git add BRAV/SCPT/my-script.sh
git commit -m "fix: make script executable"
```

### Script Fails in CI but Works Locally

**Common causes:**
- Different environment (paths, tools available)
- Missing environment variables
- Timing/race conditions

**Debug:**
- Add verbose output in script
- Check CI logs carefully
- Test in Docker container locally

---

## References

- **Guardrails Config:** BRAV/SCPT/guardrails.json
- **Check Script:** BRAV/SCPT/check_guardrails.py
- **Example Scripts:** BRAV/SCPT/ (browse existing)
- **Workflow Examples:** .github/workflows/

---

🐾 **Keep workflows thin. Delegate to BRAV/SCPT. Test locally. The guardrails will keep you honest.**

---

_Runbook: CI Workflow Delegation_  
_Maintained by: BossCat OEM_  
_Version: 1.0_

