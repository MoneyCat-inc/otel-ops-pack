# 🐾 BossCat Commit Guide

**MoneyCat Inc · Resonai [OTel] · BossCat Governance**

---

## 🎯 Purpose

This guide mandates ECRR-compliant commit messages for all Resonai [OTel] operations. All commits must follow BossCat governance standards to ensure traceability, audit compliance, and operational excellence.

---

## 📜 ECRR Commit Message Format

### Standard Format
```
<type>(scope): <detailed description>
```

### Type Categories (BossCat Approved)

#### **Core Operations**
- `docs(ecrr)` - Documentation updates and governance artifacts
- `fix(gap)` - Bug fixes and configuration patches  
- `test(canary)` - Test execution and validation frameworks
- `feat(bosscat)` - New BossCat features and capabilities

#### **Infrastructure & Monitoring**
- `feat(otel)` - OpenTelemetry pipeline enhancements
- `fix(pipeline)` - Observability pipeline corrections
- `perf(latency)` - Performance optimizations (<200ms target)
- `ci(automation)` - Continuous integration and automation

#### **SigNoz Integration**
- `feat(signoz)` - SigNoz dashboard and reporting features
- `fix(export)` - Dashboard export and snapshot fixes
- `docs(dashboard)` - Dashboard documentation updates

#### **Agent System**
- `feat(agent)` - Agent framework enhancements
- `fix(agent)` - Agent bug fixes and improvements
- `docs(agent)` - Agent documentation and guides

---

## 🎯 BossCat Mandatory Fields

### Header Requirements
- **Type**: Must be one of approved BossCat types
- **Scope**: Must indicate affected component
- **Description**: Must be concise but descriptive (<72 chars for header)

### Body Requirements (for significant changes)
- **Examine**: Pre-change state documentation
- **Clean**: Implementation details
- **Report**: Evidence collection
- **Role**: Agent responsibility

---

## 📋 Commit Message Examples

### ✅ Valid BossCat Commits

```bash
docs(ecrr): Add nightly dashboard export automation
fix(pipeline): Resolve SigNoz memory pressure issue
feat(bosscat): Implement Agent hierarchy governance
test(canary): Add resiliency tests for metrics pipeline
perf(latency): Optimize batch processing to 150ms
ci(automation): Add GitHub Actions for nightly exports
feat(signoz): Add queue pressure monitoring dashboard
fix(export): Correct Playwright PDF generation
```

### ❌ Invalid Commits (Non-BossCat)

```bash
fix: bug in thing              # Missing scope
update docs                    # Missing type prefix
Fix the problem               # Improper capitalization
feat: add new thing          # Too vague
```

---

## 🔍 Detailed Commit Body Structure

### For Significant Changes (>50 lines)
```markdown
docs(ecrr): Add BossCat governance framework

**Examine:**
- Current agent system lacks formal governance
- No standardized commit message format
- Missing ECRR methodology enforcement

**Clean:**
- Implement BossCat charter in AGENTS.md
- Create ECRR commit message standards
- Add GitHub issue and PR templates

**Report:**
- Created docs/COMMIT_GUIDE.md
- Added .github/ISSUE_TEMPLATE/ECRR-task.md
- Generated BossCat compliance documentation

**Role:**
- BossCat OEM: Oversight and approval
- Investigator Agent: Implementation verification
- QA Scribe: Documentation validation
```

---

## 🎬 BossCat Commit Workflow

### Pre-Commit Checklist
- [ ] Changes align with BossCat charter
- [ ] SigNoz dashboard impact assessed
- [ ] ECRR methodology applied
- [ ] Agent roles respected
- [ ] Evidence collection planned

### Commit Execution
1. **Stage relevant files**: `git add <files>`
2. **Verify message format**: Follows BossCat standard
3. **Execute commit**: `git commit -m "message"`
4. **Validate**: `git log --oneline -1` verifies format

### Post-Commit Actions
- Update SigNoz dashboards if needed
- Generate ECRR report for significant changes
- Notify BossCat OEM of governance-impacting changes

---

## 📊 BossCat Compliance Metrics

### Automated Checks
- Commit message format validation
- Documentation artifact generation
- SigNoz export automation
- Evidence collection verification

### Manual Reviews
- BossCat OEM approval for major changes
- Agent role compliance verification
- ECRR methodology application
- Governance artifact completeness

---

## 🚨 BossCat Enforcement

### Automated Rejection Triggers
- Invalid message format
- Missing BossCat type prefix
- Undocumented significant changes
- Skipped ECRR methodology

### Human Review Required
- Breaking changes to agent system
- SigNoz configuration modifications
- BossCat charter updates
- Governance framework changes

---

## 📈 Success Validation

### Commit Verification Commands
```bash
# Validate commit message format
git log --oneline -10

# Check BossCat compliance
git log --grep="^(docs|fix|test|feat|perf|ci)\(" --oneline

# Verify ECRR artifacts exist
ls docs/ecrr/ECRR_REPORTS/
ls docs/observability/snapshots/
```

### BossCat Dashboard Monitoring
- Commit frequency and type distribution
- ECRR methodology compliance rate
- Evidence collection completion
- Agent workflow efficiency

---

🐾 **All commits must pass BossCat governance review. Non-compliant commits will be rejected automatically.**

---

*This guide is enforced by BossCat OEM and supersedes all previous commit conventions.*