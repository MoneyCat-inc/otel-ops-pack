# ECRR Report – Jest Guardrail Audit

**Date**: 2025-09-27
**Agent**: Cursor Agent — Observability Copilot
**Role**: 4-sibling swarm (Scout • Fixer • Scribe • Strategist)
**Session**: npm quality commands audit after eslint restore

---

## 🔍 **1. Examine**

### **Initial State Captured**
- **Environment**: Node 20.19.4 via nvm, npm 11.4.2, pnpm 10.5.2 inside Ubuntu container.
- **Current State**: Fresh checkout on `work` with the restored flat ESLint config and existing pnpm workspace layout.
- **Key Findings**: `npm run lint` crashed because the local node_modules cache was missing `@eslint/js`, `npm run typecheck` flagged a missing Node `process` global, and `npm test` hard-failed when Jest tried to execute Playwright specs.
- **Attached Evidence**: Lint failure log (`chunk 65907d`), typecheck failure (`chunk d73b31`), Jest failure trace (`chunk 03ebf9`).

### **Key Findings**
- **Dependency hydration gap**: Without running `pnpm install`, `eslint.config.mjs` could not resolve `@eslint/js`, breaking the documented lint script (`chunk 65907d`).
- **Ambient Node types**: TypeScript could not find the `process` global until the Node types were installed (`chunk d73b31`).
- **Jest/Playwright collision**: Jest’s default pattern picked up `tests/smoke/*.spec.ts` and attempted to execute them as CommonJS, crashing immediately (`chunk 03ebf9`).

### **Attached Evidence**
- **Console logs**: `npm run lint` failure (`chunk 65907d`), `npm run typecheck` failure (`chunk d73b31`), `npm test` stack trace (`chunk 03ebf9`).
- **Configuration**: `package.json` scripts observed; no Jest config present before audit.
- **Test outputs**: Post-fix lint/typecheck/test runs captured in `chunks 58d2b8`, `f93340`, and `95f32b`/`3f2c83`.

---

## 🧹 **2. Clean**

### **Drift Removal**
- **Hydrated toolchain**: Ran `pnpm install` to refresh the workspace links so ESLint and TypeScript could see the restored dependencies (`chunk a7b5f3`).
- **Guarded Jest**: Added `jest.config.cjs` that ignores the Playwright smoke directory, enforces Node defaults, and exits cleanly when no unit tests are present (`F:jest.config.cjs†L1-L10`).

### **Guardrail Enforcement**
- **Local-First**: All fixes applied locally without touching external services.
- **Safety**: No secrets or production configs were read or modified.
- **Idempotence**: Jest config can be re-run safely; Playwright specs remain untouched.
- **Verification**: `npm run lint`, `npm run typecheck`, and `npm test` now complete successfully (`chunks 58d2b8`, `f93340`, `95f32b`/`3f2c83`).

---

## 📝 **3. Report**

### **Artifacts Added**
- `jest.config.cjs` to quarantine Playwright smoke specs from Jest (`F:jest.config.cjs†L1-L10`).
- This ECRR report for traceability (`F:docs/ECRR_REPORTS/2025-09-27-jest-guardrail-audit.md†L1-L50`).

### **Validation Evidence**
- `npm run lint` → success (`chunk 58d2b8`).
- `npm run typecheck` → success (`chunk f93340`).
- `npm test` → Jest exits 0 with no unit suites (`chunks 95f32b` & `3f2c83`).

---

## 🎭 **4. Role**
- **Scout**: Captured failing lint/typecheck/test baselines and noted the missing dependency state.
- **Fixer**: Created Jest guardrail config to stop Playwright specs from breaking the quality gate.
- **Scribe**: Logged commands, outputs, and config deltas in this report.
- **Strategist**: Identified follow-up opportunities and next actions below.

---

## 🔄 **Next Actions & Suggestions**
1. **Document pnpm-first workflow**: Update the onboarding docs/README to emphasize `pnpm install` whenever dependencies change so `npm run lint` stays reliable.
2. **Decide on a unit-test story**: Either remove Jest entirely or scaffold a `tests/unit` folder with `*.test.ts` plus `ts-jest`/`@swc/jest` so the `npm test` command exercises real suites.
3. **Automate hydration check**: Add a lightweight `pnpm exec` sanity check (e.g., `pnpm exec eslint --version`) to the hygiene script to catch stale node_modules before lint runs.
4. **Consider Playwright segregation**: Move smoke specs into `smoke/` outside Jest’s `testMatch` patterns or rename to `.pw.spec.ts` to avoid accidental collisions if Jest patterns expand again.

---

## ✅ **ECRR Gate**
- [x] **Examine** — Captured the failing quality command baselines with evidence.
- [x] **Clean** — Rehydrated dependencies and isolated Jest from Playwright specs.
- [x] **Report** — Logged findings in `docs/ECRR_REPORTS/2025-09-27-jest-guardrail-audit.md`.
- [x] **Role** — Declared Scout/Fixer/Scribe/Strategist contributions.
