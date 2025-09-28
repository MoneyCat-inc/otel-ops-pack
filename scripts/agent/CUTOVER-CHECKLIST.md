# 🚀 Post-Phase-3 Cutover Checklist

## 🎯 **One-Time Setup Per Environment**

### **1. Pin Runtimes & Verify Determinism** ✅
```powershell
# Commit runtime versions
git add .node-version .nvmrc
git commit -m "Pin Node.js and pnpm versions for deterministic builds"

# Verify determinism check passes
pnpm agent:test-determinism
# Expected: Overall: PASS
```

### **2. Install Windows Service** ✅
```powershell
# Run as Administrator
pnpm agent:service-install

# Verify service status
Get-Service codex-local | Format-List Status,Name,StartType
# Expected: Status = Running, StartType = Automatic
```

### **3. Wire CI Gates** ✅
```powershell
# Copy workflows to .github/workflows/
Copy-Item "scripts/agent/workflows/*.yml" ".github/workflows/"

# Test with inline style violation
# Create test file with: <div style="color: red;">Test</div>
# Push PR and verify:
# - CodeQL job runs
# - GitLeaks job runs  
# - Guardrail workflow fails
# - Artifacts uploaded (.agent/status*.json, guardrails_report.json)
```

### **4. OPA Policy Live** ✅
```powershell
# Generate guardrails report
pnpm agent:guardrails-premium -Json > .agent/guardrails_report.json

# Test policy check (requires OPA installation)
pnpm agent:policy-check
# Expected: Compliance check results
```

### **5. Telemetry Sanity Check** ✅
**In SigNoz/Grafana, verify:**
- `service.name="codex-local"` present in traces
- `codex.jobs_processed` counter increments per cycle
- `watchdog.cycle.duration` histogram has data
- Alerts created for:
  - **Stall**: `rate(codex.jobs_processed[15m]) == 0` AND `state == "running"`
  - **Lock**: `max_over_time(state == "paused:lock"[1h]) == 1`
  - **P95 Breach**: `histogram_quantile(0.95, rate(watchdog_cycle_duration_bucket[15m])) > 300s`
  - **Violations**: `increase(codex.guardrail_violations[5m]) > 0`

### **6. Documentation Updates** ✅
- [ ] README badge renders correctly
- [ ] `docs/RUNBOOK.md` has Service Mode start/stop procedures
- [ ] `docs/SECURITY.md` references SBOM path and disclosure contact
- [ ] `docs/OPEN_TELEMETRY_ALIGNMENT.md` linked from README

### **7. Fleet Mode (Optional)** ✅
```powershell
# Test fleet status across workspace
pnpm agent:status-fleet

# Add composite badge to README
pnpm agent:status-fleet-json
```

## 🔧 **Day-2 Ops Guardrails (Hardening Habits)**

### **Atomic JSON Writes**
- ✅ All `.agent/status.json` and report files use tmp → move pattern
- ✅ Prevents truncation during CI reads
- ✅ Implemented in `scripts/agent/utils/atomic-writes.ps1`

### **Output Modes First**
- ✅ Every entrypoint sets `$env:NO_COLOR=1` in JSON/Quiet modes
- ✅ Progress bars disabled when `-Json` or `-Quiet` specified
- ✅ Clean JSON output for CI parsing

### **Single Instance Enforcement**
- ✅ PID file (`.agent/WATCHDOG.PID`) with alive-check
- ✅ `service-install.ps1` refuses to start second instance
- ✅ Graceful cleanup on SIGTERM/CTRL+C

### **Budget Enforcement**
- ✅ `-Fix` mode stops at 10 files / 200 LOC (configurable)
- ✅ Logs `needs-followup` entries to `TASKS.md`
- ✅ Prevents runaway automated fixes

### **Secrets Redaction**
- ✅ All log writes redact tokens, emails, bearer strings
- ✅ Pattern matching in `scripts/agent/utils/secrets-hygiene.ps1`
- ✅ Environment variable validation

### **Schema Versioning**
- ✅ Every JSON includes `"schema":"codex-local.status.v1"`
- ✅ Bump version on breaking changes
- ✅ Keep 1-cycle compatibility writer

## 🚀 **Fast Validation Commands**

### **JSON Purity Test**
```powershell
# Extract clean JSON and verify structure
$status = pnpm agent:status-premium -Json 2>$null | 
    Where-Object { $_ -match '^\s*\{' } | 
    Select-Object -First 1 | 
    ConvertFrom-Json
$status | Select state,cycles,lastUpdate
```

### **Kill-Switch Drill**
```powershell
# Test lock mechanism
"manual" > .agent/LOCK
pnpm agent:status-premium -Json | ConvertFrom-Json | Select state
# Expected: state = "locked"

Remove-Item .agent/LOCK
pnpm agent:status-premium -Json | ConvertFrom-Json | Select state
# Expected: state = "unknown" or "running"
```

### **Policy Gate Test**
```powershell
# Generate and test policy
pnpm agent:guardrails-premium -Json > .agent/guardrails_report.json
pnpm agent:policy-check
if ($LASTEXITCODE) { "DENIED" } else { "OK" }
```

### **Service Health Check**
```powershell
# Check service status and logs
Get-Service codex-local
Get-Content .agent\logs\service.out.log -Tail 50
```

### **Comprehensive Validation**
```powershell
# Run all validation tests
pwsh -File scripts/agent/cutover-validation.ps1
# Expected: ALL TESTS PASSED
```

## 🌐 **Upstream & Community Outreach**

### **CNCF Slack Posts**
**Post to `#otel-collector`, `#otel-windows`, `#otel-users`:**

> 🚀 **Windows Day-2 Ops Kit with OpenTelemetry**
> 
> Just shipped a production-ready autonomous observability subsystem for Windows environments! 
> 
> **Key Features:**
> - OTLP-first design (HTTP/gRPC endpoints)
> - Windows Event Log + file log monitoring
> - Autonomous guardrail enforcement (CSP, A11y, Performance)
> - Policy-as-Code with OPA/Rego
> - Windows service mode with NSSM
> - Fleet-wide health aggregation
> 
> **Docs:** https://github.com/resonai/codex-local/blob/main/docs/OPEN_TELEMETRY_ALIGNMENT.md
> **Example Config:** https://github.com/resonai/codex-local/blob/main/docs/OPEN_TELEMETRY_ALIGNMENT.md#collector-integration
> 
> Would love feedback from the Windows observability community! 🎯

### **GitHub Discussion**
**Open in `opentelemetry-collector`:**

> **Windows Day-2 Operations with OpenTelemetry: Autonomous Observability Subsystem**
> 
> I've developed a production-ready autonomous observability subsystem specifically for Windows environments that aligns with OpenTelemetry best practices.
> 
> **Key Contributions:**
> - **OTLP-First Design**: Primary OTLP/HTTP (5318), secondary OTLP/gRPC (5317)
> - **Guardrail Methodology**: Automated enforcement of CSP, accessibility, and performance standards
> - **Policy-as-Code**: OPA/Rego integration for declarative compliance
> - **Windows Service Mode**: Native service hosting with NSSM
> - **Semantic Conventions**: Full compliance with OTel semantic conventions
> 
> **Documentation:** [Windows Day-2 Ops Guide](https://github.com/resonai/codex-local/blob/main/docs/OPEN_TELEMETRY_ALIGNMENT.md)
> 
> **Example Collector Config:** [Production-Ready Configuration](https://github.com/resonai/codex-local/blob/main/docs/OPEN_TELEMETRY_ALIGNMENT.md#collector-integration)
> 
> Would the community be interested in an example PR to the `examples/` directory with Windows service configuration and runbook?

### **Example Repository PR**
**Offer to `opentelemetry-collector/examples/`:**

- Windows collector service configuration
- NSSM service wrapper scripts
- Operational runbook link
- Guardrail policy examples

## 🎁 **Nice Extras (Low Effort, High Signal)**

### **README Live Section**
```markdown
## 📊 Live Status
<!-- Auto-refreshed by agent:doc-refresh -->
- **Last Doctor Run**: 2025-09-27T23:24:23Z
- **Current State**: running
- **Violations (24h)**: 0
- **Health Score**: 95%
```

### **Nightly Chaos Engineering**
```powershell
# Rotate 3 chaos recipes nightly
pnpm agent:nightly-chaos
# Recipes: inline style seed, long cycle, lock-flap
# Post results to "Health Diary" GitHub Discussion
```

### **Golden Outputs Diff**
```yaml
# Add to CI workflow
- name: Golden outputs diff
  run: |
    pnpm agent:status-premium -Json > .agent/status-ci.json
    pnpm agent:guardrails-premium -Json > .agent/guardrails-ci.json
    diff docs/golden/status.json .agent/status-ci.json || echo "Status drift detected"
    diff docs/golden/guardrails_report.json .agent/guardrails-ci.json || echo "Guardrails drift detected"
```

## 🔄 **Rollback Plan**

### **Service Mode Rollback**
```powershell
# Stop and remove service
nssm stop codex-local
nssm remove codex-local confirm

# Verify removal
Get-Service codex-local -ErrorAction SilentlyContinue
# Expected: Service not found
```

### **Agent Pause**
```powershell
# Create emergency lock
"emergency-rollback" > .agent/LOCK

# Verify agent state changes to paused:lock within one cycle
pnpm agent:status-premium -Json | ConvertFrom-Json | Select state
# Expected: state = "paused:lock"
```

### **Policy Enforcement Disable**
```powershell
# Set environment variable to disable enforcement
$env:CODEX_POLICY_ENFORCE = "0"

# Doctor will warn but CI still runs read-only
pnpm agent:doctor
# Expected: Warning about policy enforcement disabled
```

### **CI Gates Override**
```yaml
# Add to PR with override-codex label
# Document who can apply this label (typically: maintainers, security team)
# CI jobs will skip codex-local checks
```

## ✅ **Cutover Success Criteria**

- [ ] **Determinism**: `pnpm agent:test-determinism` returns PASS
- [ ] **Service**: `Get-Service codex-local` shows Running status
- [ ] **CI Gates**: Test PR with inline style fails and uploads artifacts
- [ ] **Policy**: `pnpm agent:policy-check` runs without errors (OPA installed)
- [ ] **Telemetry**: SigNoz shows `service.name="codex-local"` metrics
- [ ] **Docs**: README badge renders, all documentation linked
- [ ] **Validation**: `pwsh -File scripts/agent/cutover-validation.ps1` returns ALL TESTS PASSED

## 🎯 **Post-Cutover Actions**

1. **Monitor First 24 Hours**: Watch for any issues in logs and telemetry
2. **Team Training**: Share runbook with operations team
3. **Community Outreach**: Post to CNCF Slack and open GitHub Discussion
4. **Documentation**: Update any environment-specific procedures
5. **Success Celebration**: 🎉 You've successfully deployed an enterprise-grade autonomous observability platform!

---

**This checklist ensures a smooth transition from prototype to production-ready autonomous observability subsystem.**
