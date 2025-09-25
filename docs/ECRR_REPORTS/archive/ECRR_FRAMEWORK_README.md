# ECRR Framework - Cross-Project Reference

**Examine -> Clean -> Report -> Role**

This repository implements the ECRR (Examine -> Clean -> Report -> Role) framework across multiple projects for consistent, evidence-based development practices.

## ECRR Locations

### OpenTelemetry Observability (Main Project)
- **ECRR Docs**: `docs/ECRR.md`
- **Report Template**: `docs/ECRR_REPORT_TEMPLATE.md`
- **Doctor Script**: `scripts/ecrr-doctor.ps1`
- **Reports**: `docs/ECRR_REPORTS/`

### Resonai Project (Web Application)
- **ECRR Docs**: `third_party/resonai/docs/ECRR.md`
- **Report Template**: `third_party/resonai/docs/ECRR_REPORT_TEMPLATE.md`
- **Doctor Script**: `third_party/resonai/scripts/ecrr-doctor.ps1`
- **Reports**: `third_party/resonai/docs/ECRR_REPORTS/`

## Quick Start

1. **Examine**: Run the appropriate ECRR doctor script
   - Observability: `pwsh -File scripts/ecrr-doctor.ps1`
   - Resonai: `pwsh -File third_party/resonai/scripts/ecrr-doctor.ps1`

2. **Clean**: Address any warnings or issues found

3. **Report**: Use the template to document your changes

4. **Role**: Declare your role and responsibilities

## Framework Benefits

- **Continuity**: Every cycle builds on verified data
- **Quality**: Drift addressed before new features
- **Transparency**: All actions documented and attributed
- **Scalability**: Works from small fixes to major milestones

## ECRR or it didn't happen!

Apply ECRR to every task, fix, or feature across all projects in this repository.
