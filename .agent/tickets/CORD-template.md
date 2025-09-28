# CORD-XXXX: Review & merge [Feature] PR

**Inputs:** PR from IMPL (IMPL-XXXX)

**Tasks:**
- [ ] Verify CI (unit + Playwright) is green
- [ ] Check CSP/COOP/COEP headers in app build
- [ ] Refresh SSOT blocks if needed (DECISIONS.md, telemetry JSON, etc.)
- [ ] Quarantine flaky tests if present, bounce back with concrete failures
- [ ] Verify accessibility compliance (WCAG AA)
- [ ] Merge if all criteria pass

**Outputs:** Merged PR, updated SSOT
**Definition of Done:** Main branch stays green, compliant, and artifact-aligned
