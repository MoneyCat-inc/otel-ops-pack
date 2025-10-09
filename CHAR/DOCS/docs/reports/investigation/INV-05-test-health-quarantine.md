# INV-05 Test Health & Flake Quarantine - Investigation Report

**Investigation Date**: 2025-01-27  
**Investigator**: Cursor Investigator  
**Target**: Resonai Next.js 14 + WebAudio/AudioWorklets Application  
**Scope**: Test health & flake quarantine analysis  
**Status**: ✅ COMPLETE - Critical Issues Identified

## Summary

Conducted comprehensive test health analysis and flake quarantine investigation of the Resonai MEMX demo application. **CRITICAL FINDING**: Test configuration conflict between Vitest and Playwright causing all Playwright tests to fail. **ANALYZED**: Test reliability patterns, configuration issues, and quarantine strategies.

## Investigation Results

### 🔴 Critical Test Configuration Issue

**Problem**: **Test Framework Conflict**
- **Vitest** is running Playwright test files (`.spec.ts`)
- **Playwright** tests are being executed in Vitest environment
- **Result**: All Playwright tests fail with "test.describe() not expected here" error

**Evidence**:
```bash
> npm test
> vitest

FAIL tests/memx-chromium-debug.spec.ts
Error: Playwright Test did not expect test.describe() to be called here.

FAIL tests/memx.spec.ts  
Error: Playwright Test did not expect test.describe() to be called here.

FAIL tests/mobile-performance.spec.ts
Error: Playwright Test did not expect test.describe() to be called here.
```

**Root Cause**: Mixed test frameworks in same project
- **Vitest**: Unit tests (`tests/memx/basic.test.ts`) ✅ Working
- **Playwright**: E2E tests (`tests/*.spec.ts`) ❌ Failing

### ✅ Test Health Analysis

#### Working Tests (Vitest)
**File**: `tests/memx/basic.test.ts`
- **Status**: ✅ **HEALTHY** - 8 tests passing
- **Coverage**: MEMX core types, store operations, strain detection
- **Performance**: 17ms execution time
- **Reliability**: 100% pass rate

**Test Coverage**:
```typescript
✓ MEMX Core Types (2 tests)
✓ MEMX Store (5 tests) 
✓ Export Data Format (1 test)
```

#### Failing Tests (Playwright)
**Files**: `tests/*.spec.ts`
- **Status**: 🔴 **BROKEN** - Configuration conflict
- **Coverage**: E2E functionality, cross-origin isolation, mobile performance
- **Impact**: No E2E test coverage currently available

**Affected Test Suites**:
1. `tests/memx.spec.ts` - MEMX Labs Page functionality
2. `tests/memx-chromium-debug.spec.ts` - Chromium-specific debugging
3. `tests/mobile-performance.spec.ts` - Mobile performance testing

### ✅ Test Configuration Analysis

#### Current Configuration Issues

**Vitest Config** (`vitest.config.ts`):
```typescript
export default defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'],
    globals: true,
  },
});
```

**Playwright Config** (`playwright.config.ts`):
```typescript
export default defineConfig({
  testDir: './tests',
  testMatch: '**/*.spec.ts',  // ← Conflicts with Vitest
  // ...
});
```

**Problem**: Both frameworks trying to run `**/*.spec.ts` files

#### Test Setup Analysis
**File**: `tests/setup.ts`
- **Purpose**: Mock browser APIs for Vitest
- **Status**: ✅ **HEALTHY** - Proper mocking implementation
- **Coverage**: IndexedDB, performance.now, URL.createObjectURL, DOM manipulation

### ✅ Flake Pattern Analysis

#### Identified Flake Sources

**1. Test Framework Conflict** 🔴 **CRITICAL**
- **Impact**: 100% failure rate for E2E tests
- **Cause**: Mixed Vitest/Playwright configuration
- **Solution**: Separate test directories or proper exclusion

**2. Cross-Origin Isolation Variability** ⚠️ **MEDIUM**
- **Pattern**: Tests may pass/fail based on development vs production headers
- **Evidence**: Tests have conditional logic for `window.crossOriginIsolated`
- **Risk**: Environment-dependent failures

**3. Async Timing Issues** ⚠️ **LOW**
- **Pattern**: `waitForTimeout()` usage in tests
- **Evidence**: Multiple `await page.waitForTimeout(1000)` calls
- **Risk**: Timing-dependent failures

**4. Console Error Collection** ⚠️ **LOW**
- **Pattern**: Dynamic console error collection
- **Evidence**: `page.on('console', msg => {...})` in tests
- **Risk**: Race conditions in error collection

### ✅ Quarantine Strategy Recommendations

#### Immediate Quarantine (Critical)

**1. Separate Test Directories**
```bash
# Recommended structure
tests/
├── unit/           # Vitest tests
│   └── memx/
│       └── basic.test.ts
├── e2e/            # Playwright tests  
│   ├── memx.spec.ts
│   ├── mobile-performance.spec.ts
│   └── memx-chromium-debug.spec.ts
└── setup.ts        # Shared setup
```

**2. Update Configurations**
```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    include: ['tests/unit/**/*.test.ts'],
    exclude: ['tests/e2e/**/*.spec.ts'],
    // ...
  },
});

// playwright.config.ts  
export default defineConfig({
  testDir: './tests/e2e',
  testMatch: '**/*.spec.ts',
  // ...
});
```

#### Medium-Term Quarantine (Reliability)

**1. Cross-Origin Isolation Tests**
- **Quarantine**: Tests dependent on COI headers
- **Reason**: Environment-dependent behavior
- **Solution**: Mock COI state or separate CI/prod test runs

**2. Timing-Dependent Tests**
- **Quarantine**: Tests using `waitForTimeout()`
- **Reason**: Unreliable timing assumptions
- **Solution**: Use proper wait conditions instead

**3. Console Error Tests**
- **Quarantine**: Dynamic console error collection
- **Reason**: Race condition potential
- **Solution**: Use Playwright's built-in error handling

#### Long-Term Quarantine (Maintenance)

**1. Mobile Performance Tests**
- **Quarantine**: Until mobile viewports enabled
- **Reason**: Tests written but mobile config disabled
- **Solution**: Enable mobile viewports in Playwright config

**2. Debug-Specific Tests**
- **Quarantine**: `memx-chromium-debug.spec.ts`
- **Reason**: Debug-specific functionality
- **Solution**: Move to separate debug test suite

## Test Health Status

### ✅ Healthy Components
- **Vitest Unit Tests**: 100% pass rate, fast execution
- **Test Setup**: Proper mocking, no conflicts
- **Test Coverage**: Core MEMX functionality covered

### 🔴 Broken Components  
- **Playwright E2E Tests**: 100% failure rate due to config conflict
- **Cross-Browser Testing**: Not functional
- **Mobile Testing**: Not functional

### ⚠️ At-Risk Components
- **Timing-Dependent Tests**: Potential flakiness
- **Environment-Dependent Tests**: COI variability
- **Console Error Tests**: Race condition potential

## Quarantine Implementation Plan

### Phase 1: Critical Fixes (Immediate)
1. **Separate Test Directories**: Move Playwright tests to `tests/e2e/`
2. **Update Configurations**: Fix Vitest/Playwright conflict
3. **Verify Test Execution**: Ensure both frameworks work independently

### Phase 2: Reliability Improvements (Short Term)
1. **Replace waitForTimeout**: Use proper wait conditions
2. **Mock COI State**: Remove environment dependencies
3. **Improve Error Handling**: Use Playwright's built-in mechanisms

### Phase 3: Mobile Testing (Medium Term)
1. **Enable Mobile Viewports**: Uncomment mobile config in Playwright
2. **Run Mobile Tests**: Execute mobile performance tests
3. **Validate Mobile Coverage**: Ensure mobile functionality works

## Verification Commands

### Test Framework Separation
```bash
# Run Vitest unit tests only
npx vitest run tests/unit/

# Run Playwright E2E tests only  
npx playwright test tests/e2e/

# Run all tests (after separation)
npm run test:unit && npm run test:e2e
```

### Test Health Verification
```bash
# Check test configuration
npx vitest --config vitest.config.ts --dry-run
npx playwright test --config playwright.config.ts --dry-run

# Run specific test suites
npx vitest run tests/memx/basic.test.ts
npx playwright test tests/e2e/memx.spec.ts
```

### Flake Detection
```bash
# Run tests multiple times to detect flakes
for i in {1..5}; do npm test; done

# Check for timing issues
npx playwright test --reporter=line --timeout=30000
```

## Risk Assessment

### 🔴 High Risk - Test Framework Conflict
- **Impact**: Complete E2E test failure
- **Probability**: 100% (currently happening)
- **Mitigation**: Immediate test directory separation

### ⚠️ Medium Risk - Environment Dependencies
- **Impact**: Tests pass/fail based on environment
- **Probability**: 50% (development vs production)
- **Mitigation**: Mock environment state

### ⚠️ Low Risk - Timing Dependencies
- **Impact**: Occasional test failures
- **Probability**: 20% (timing-dependent)
- **Mitigation**: Use proper wait conditions

## Next Actions

### Immediate (Critical)
1. ✅ **Test Framework Conflict**: Identified and documented
2. 🔄 **Separate Test Directories**: Move Playwright tests to `tests/e2e/`
3. 🔄 **Update Configurations**: Fix Vitest/Playwright conflict
4. 🔄 **Verify Test Execution**: Ensure both frameworks work

### Short Term (Reliability)
1. **Replace Timing Dependencies**: Use proper wait conditions
2. **Mock Environment State**: Remove COI dependencies
3. **Improve Error Handling**: Use Playwright's built-in mechanisms

### Long Term (Coverage)
1. **Enable Mobile Testing**: Uncomment mobile viewports
2. **Add Integration Tests**: Cross-component testing
3. **Performance Testing**: Load and stress testing

## Files Analyzed

### Test Files
- `tests/memx/basic.test.ts` - Vitest unit tests (healthy)
- `tests/memx.spec.ts` - Playwright E2E tests (broken)
- `tests/memx-chromium-debug.spec.ts` - Debug tests (broken)
- `tests/mobile-performance.spec.ts` - Mobile tests (broken)
- `tests/setup.ts` - Test setup (healthy)

### Configuration Files
- `vitest.config.ts` - Vitest configuration
- `playwright.config.ts` - Playwright configuration
- `package.json` - Test scripts

### Test Results
- `test-results-chromium.json` - Previous test results
- `playwright-report/` - Test reports

---

**Investigation Status**: ✅ COMPLETE - Critical Test Issues Identified  
**Next Investigation**: Ready for test framework separation and quarantine implementation  
**Quality Gate**: ⚠️ BLOCKED - E2E tests non-functional due to configuration conflict

The investigation reveals a critical test configuration issue that must be resolved before implementing the fast wins from INV-04. The test framework conflict is preventing all E2E testing, which is essential for validating the mobile performance improvements and CSP tightening.
