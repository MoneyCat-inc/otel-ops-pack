# Pull Request

## Description
<!-- Brief description of what this PR does -->

## Type of Change
<!-- Mark with an 'x' all that apply -->

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Refactoring
- [ ] CI/CD changes

## Performance Claims
<!-- ⚠️ REQUIRED if this PR changes performance-related copy -->

- [ ] **I changed performance claims** (e.g., throughput, latency, uplift numbers)
  - [ ] I have included a link to evidence report: `docs/ecrr/ECRR_REPORTS/EVIDENCE_YYYY-MM-DD.md`
  - [ ] Evidence includes: baseline config, new config, 5+ trials per variant, statistical confidence (95% CI)
  - [ ] Claims are scoped (e.g., "OTLP ingest throughput" not "product 7× faster")
  - [ ] Publication rules followed (CI lower bound ≥6× for "up to 7×" claims)

**OR**

- [ ] **I did NOT change performance claims** (no uplift numbers, no throughput values in hero/README/docs)

> **Note:** CI guard will fail if banned patterns detected (`77×`, `196.7`, etc.). See `docs/ecrr/ECRR_REPORTS/EVIDENCE_TEMPLATE.md` for measurement workflow.

## Testing
<!-- Describe the tests you ran to verify your changes -->

- [ ] Tested locally
- [ ] Passes CI/CD checks
- [ ] Added/updated tests
- [ ] CI guard passes: `pwsh -File scripts/guard-inflated-metrics.ps1`

## Checklist
<!-- Mark with an 'x' all that apply -->

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings or errors
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## BossCat Compliance
<!-- Required for ECRR/governance changes -->

- [ ] ECRR methodology followed (if applicable): Examine → Clean → Report → Role
- [ ] Budget compliance: Changes stay within lane/LOC limits
- [ ] Evidence artifacts generated (if applicable)
- [ ] BossCat OEM approval obtained (for critical infrastructure)

## Related Issues
<!-- Link to related issues -->

Closes #

## Additional Context
<!-- Add any other context about the PR here -->
