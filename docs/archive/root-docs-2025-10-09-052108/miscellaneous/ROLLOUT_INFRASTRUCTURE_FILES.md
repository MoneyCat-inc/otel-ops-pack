# 🚀 Rollout Infrastructure Files

**Copy these files to their respective locations in the resonai-mock repository:**

## 1. PR Template
**File:** `resonai-mock/.github/pull_request_template.md`

```markdown
## PR NOTES
**Scope:** <C# short description>  
**Branch:** cohort/<C#>-<short-name>  
**Files:** <key files + fixtures + docs>  
**Tests:** unit + e2e tags included  
**Risk:** low; isolated slice; local-first only  
**Rollback:** revert commit (no shared codepaths), flags off if applicable

## Reviewer Gates
- [ ] Deterministic tests (fixtures; console guard; no network on local-only pages)
- [ ] A11y: one `aria-live="polite"` per card; focus rings; reduced motion honored
- [ ] Privacy: no uploads; IndexedDB only; export JSON shape documented
- [ ] Security: CSP/COOP/COEP unchanged; no inline styles; console clean
- [ ] Paths: touches only its slice; no collision with other C# tasks
- [ ] Docs: release notes + user/ops docs updated
```

## 2. CODEOWNERS
**File:** `resonai-mock/.github/CODEOWNERS`

```text
# Cohort: C5
/app/labs/cohort-log/*                  @agent-a
/src/engine/metrics/cohortLog.ts        @agent-a
/tests/**/cohort-log*                   @agent-a
/docs/cohort-tester-guide.md            @agent-a
/docs/release-notes/c5-*                @agent-a

# Cohort: C6
/src/engine/metrics/aggregate.ts        @agent-b
/src/components/progress/BetaMetrics*   @agent-b
/tests/**/beta-metrics*                 @agent-b
/docs/beta-metrics.md                   @agent-b
/docs/release-notes/c6-*                @agent-b

# Cohort: C7 (done)
# mapped to @agent-c if you want backports

# Cohort: C8
/docs/BETA_LAUNCH_CHECKLIST.md          @agent-d
/docs/cohort-onboarding.md              @agent-d
/docs/rollback-procedures.md            @agent-d
/README.md                              @agent-d
/docs/release-notes/c8-*                @agent-d
```

## 3. Labels & Milestones
**Add to GitHub Issues/PRs:**

### Labels
- `cohort`, `privacy`, `a11y`, `docs`, `qa`, `no-network`, `dashboard`, `metrics`, `labs`

### Milestones
- `Cohort Launch Pack` (closed: C1–C4)
- `Cohort Ops Kit` (open: C5–C8)

## 4. Merge Queue & Collision Rules

### Queue Order (Safe Parallelism)
1. **C5** (labs + engine file isolated)
2. **C6** (adds exports, doesn't rename)
3. **C7** ✅ merged
4. **C8** (docs/README only)

### Collision Avoidance
- Only C6 extends `aggregate.ts` by **new exports** (no renames)
- Only C8 edits `README.md` (append only)
- Separate release notes per C# to avoid conflicts

## 5. CI Gates
**Add to workflow files:**

```bash
# e2e json (+ console guard is already in your specs)
pnpm test:e2e --reporter=json > playwright-report.json || true
pnpm qa:summary
```

**Block network calls on local-only routes (example in e2e):**

```ts
await page.route('**/*', route => {
  const t = route.request().resourceType();
  const same = new URL(route.request().url()).origin === new URL(page.url()).origin;
  const allow = same && ['document','stylesheet','script','font'].includes(t);
  allow ? route.continue() : route.abort();
});
```

## 6. Go/No-Go Checklist

### Go Criteria
- [ ] C5–C8 merged to `main`, **qa:full** green; **qa:summary** shows no failures
- [ ] Flags default OFF in prod; cohort env toggles validated in staging
- [ ] `/progress` renders with **C6** panel; no network activity
- [ ] `/labs/cohort-log` works offline; export JSON matches schema; rotation ≤100
- [ ] README links to **BETA_LAUNCH_CHECKLIST.md**; docs compile

### No-Go Criteria
- [ ] Any console COEP/CSP errors
- [ ] Any network request from local-only routes
- [ ] A11y smokes fail (multiple `aria-live`, missing focus rings)
- [ ] Isolation offline test fails (first-load pattern not honored)

## 7. Communication Templates

### Beta Invite (Short)
```
You're invited to the Resonai private beta. Your data stays on your device (no uploads).

1. Open Settings → enable "Cohort" toggles provided in the instructions
2. Practice for 5–10 minutes daily
3. Use /progress to see trends; use Data → Export to save your sessions
4. If something breaks, export your cohort log from /labs/cohort-log and send the file
```

### Privacy Note
```
Resonai is local-first. No audio or metrics are uploaded. You can export or delete your data at any time.
```

## 8. Definition of Done (Per C5/C6/C8 PR)

### C5 DoD
- Bounded log ≤100, export JSON validated, clear flow confirms, no network, a11y OK, docs + release notes

### C6 DoD
- Retention denominator declared & tested, strain rate guards divide-by-zero, filters a11y, no network, docs + release notes

### C8 DoD
- Checklist + onboarding + rollback docs link from README; commands are copy-paste runnable

---

**Ready to deploy:** Copy these files to their respective locations and the rollout infrastructure is complete!
