# QA Release Runbook

## Overview

This runbook provides a complete, deterministic QA process for pre-cohort releases. It covers environment setup, test execution, and troubleshooting to ensure every release meets our quality standards.

## Preflight Checklist

### **Environment Prerequisites**

#### **Node.js & Package Manager**
```bash
# Check Node version (requires 18+)
node --version  # Should be v18.0.0 or higher

# Check PNPM version (requires 8+)
pnpm --version  # Should be 8.0.0 or higher

# Install dependencies
pnpm install
```

#### **Browser Requirements**
- **Firefox**: Latest stable version (required for isolation testing)
- **Chromium**: Latest stable version (required for E2E testing)
- **Mobile**: iOS Safari / Android Chrome (for responsive testing)

#### **OS Prerequisites**
- **Windows**: PowerShell 7+ for script execution
- **macOS**: Xcode Command Line Tools
- **Linux**: Standard build tools (gcc, make)

### **Environment Verification**
```bash
# Verify all tools are available
pnpm run qa:env-check
```

## Test Matrix & Tags

### **Core Test Suites**

| Tag | Description | Scope | Expected Runtime |
|-----|-------------|-------|------------------|
| `@progress` | C1 Progress Dashboard | Data aggregation, UI, a11y | 2-3 min |
| `@data-control` | C2 Export & Delete UX | Export/delete flows, a11y | 1-2 min |
| `@prosody-scenarios` | T2 Applied Prosody | Scenario cards, mock data | 2-3 min |
| `@strain` | T3 Safety Guardrails | Strain detection, cooldown | 2-3 min |
| `@isolation-offline` | T4 Offline Isolation | COOP/COEP, Service Worker | 1-2 min |
| `@a11y-smokes` | T5 A11y Polish | Live regions, reduced motion | 1-2 min |

### **Test Execution Commands**

#### **Full QA Suite**
```bash
# Complete QA run (all tests)
pnpm run qa:full
# Expected runtime: 8-12 minutes
```

#### **Tag-Specific Runs**
```bash
# Individual test suites
pnpm run qa:a11y        # Accessibility smoke tests
pnpm run qa:isolation    # Offline isolation tests
pnpm run qa:prosody     # Prosody scenario tests
pnpm run qa:strain      # Strain detection tests
pnpm run qa:progress    # Progress dashboard tests
pnpm run qa:data        # Data control tests
```

#### **Unit Tests**
```bash
# Run all unit tests
pnpm test:unit

# Run specific unit test suites
pnpm test:unit --filter aggregate
pnpm test:unit --filter export-schema
pnpm test:unit --filter strain
```

## Determinism Guidelines

### **Fixture Management**

#### **Prosody Scenarios (T2)**
- **Mock Data**: Deterministic F0 contours with known rise/fall patterns
- **Voiced Masks**: Consistent voiced/unvoiced patterns
- **Silence Tails**: Standardized silence periods
- **Regeneration**: `pnpm run fixtures:prosody` to regenerate

#### **Strain Detection (T3)**
- **Loud Passage**: Consistent RMS levels above threshold
- **Rising Jitter**: Predictable jitter trend patterns
- **Neutral Passage**: Stable metrics below thresholds
- **Regeneration**: `pnpm run fixtures:strain` to regenerate

#### **Isolation Testing (T4)**
- **First Load Pattern**: Network serves initial document with headers
- **Service Worker**: Takes control on second load, preserves headers
- **Console Guard**: Fails on COEP/CORS error messages
- **Regeneration**: `pnpm run fixtures:isolation` to regenerate

### **Reduced Motion Testing**
```bash
# Test with reduced motion enabled
pnpm test:e2e --grep @a11y-smokes --project=chromium-reduced-motion
```

### **Cross-Browser Testing**
```bash
# Test specific browsers
pnpm test:e2e --project=firefox
pnpm test:e2e --project=chromium
pnpm test:e2e --project=webkit
```

## Accessibility Gates

### **Live Regions**
- **Single Announcement**: Exactly one `aria-live="polite"` per dynamic card
- **No Duplicates**: Avoid duplicate announcements within 500ms
- **Atomic Updates**: Use `aria-atomic="true"` for complete announcements

### **Focus Management**
- **Visible Focus Rings**: All interactive elements have clear focus indicators
- **Logical Tab Order**: Tab navigation follows logical flow
- **Skip Links**: "Skip to main content" links on key pages
- **Focus Trap**: Modal dialogs trap focus appropriately

### **Reduced Motion**
- **System Respect**: Honor `prefers-reduced-motion` setting
- **Static Fallbacks**: Provide non-animated alternatives
- **CSS Overrides**: Global CSS disables animations when reduced motion preferred

### **Screen Reader Support**
- **ARIA Labels**: All interactive elements properly labeled
- **Semantic HTML**: Use proper heading structure (h1, h2, h3)
- **Role Attributes**: Appropriate roles for custom components
- **Descriptive Text**: Clear, human-readable labels and descriptions

## Security & Isolation Gates

### **Cross-Origin Isolation**
- **COOP Headers**: `Cross-Origin-Opener-Policy: same-origin`
- **COEP Headers**: `Cross-Origin-Embedder-Policy: require-corp`
- **CORP Headers**: `Cross-Origin-Resource-Policy: cross-origin`
- **First Load Pattern**: Network serves initial document, SW takes control on reload

### **Console Error Monitoring**
```bash
# Fail on COEP/CORS errors
pnpm test:e2e --grep @isolation-offline --reporter=line
```

### **Service Worker Behavior**
- **Header Preservation**: SW preserves COOP/COEP when serving cached content
- **Offline Isolation**: `window.crossOriginIsolated === true` offline
- **SharedArrayBuffer**: Available when isolation is true

### **CSP Compliance**
- **No Inline Styles**: All styles in external CSS files
- **No Inline Scripts**: All JavaScript in external files
- **Strict CSP**: Production CSP blocks unsafe practices
- **Development Relaxed**: Dev CSP allows necessary debugging

## Troubleshooting

### **Common Flaky Symptoms**

#### **"Test timeout" Errors**
```bash
# Increase timeout for slow tests
pnpm test:e2e --timeout=60000

# Check for hanging processes
pnpm run qa:cleanup
```

#### **"Element not found" Errors**
```bash
# Regenerate fixtures
pnpm run fixtures:regenerate

# Clear browser cache
pnpm run qa:clear-cache
```

#### **"COEP/CORS" Errors**
```bash
# Check headers
pnpm run qa:check-headers

# Verify Service Worker
pnpm run qa:check-sw
```

#### **"Accessibility" Failures**
```bash
# Run a11y tests in isolation
pnpm run qa:a11y --reporter=line

# Check for duplicate aria-live regions
pnpm run qa:check-a11y
```

### **Fixture Regeneration**

#### **Prosody Fixtures**
```bash
# Regenerate prosody test data
pnpm run fixtures:prosody
# Creates: fixtures/prosody/scenarios.json
```

#### **Strain Fixtures**
```bash
# Regenerate strain test data
pnpm run fixtures:strain
# Creates: fixtures/strain/patterns.json
```

#### **Isolation Fixtures**
```bash
# Regenerate isolation test data
pnpm run fixtures:isolation
# Creates: fixtures/isolation/headers.json
```

### **Environment Reset**
```bash
# Clean all test artifacts
pnpm run qa:cleanup

# Reset browser state
pnpm run qa:reset-browsers

# Clear all caches
pnpm run qa:clear-cache
```

## Release Process

### **Pre-Release Checklist**
1. **Environment**: Verify all prerequisites met
2. **Dependencies**: Run `pnpm install` to ensure latest
3. **Fixtures**: Regenerate all test fixtures
4. **Full QA**: Run `pnpm run qa:full`
5. **Summary**: Run `pnpm run qa:summary` for report

### **Release Commands**
```bash
# Complete pre-release QA
pnpm run qa:full && pnpm run qa:summary

# Expected output: All green ✅
# Expected runtime: 8-12 minutes
```

### **CI Integration**
```yaml
# Example GitHub Actions step
- name: Run QA Suite
  run: |
    pnpm install
    pnpm run qa:full
    pnpm run qa:summary
```

## Performance Benchmarks

### **Expected Runtimes**
- **Unit Tests**: 30-60 seconds
- **E2E Tests**: 8-12 minutes total
- **Individual Suites**: 1-3 minutes each
- **Full QA**: 8-12 minutes

### **Performance Thresholds**
- **Page Load**: < 500ms for all pages
- **Data Processing**: < 100ms for aggregation
- **Export**: < 500ms for large datasets
- **Delete**: < 200ms for data clearing

## Quality Gates

### **Required Passes**
- **Unit Tests**: 100% pass rate
- **E2E Tests**: 100% pass rate
- **Accessibility**: All a11y tests pass
- **Isolation**: All isolation tests pass
- **Cross-Browser**: Firefox + Chromium pass

### **Failure Handling**
- **Unit Failures**: Fix before proceeding
- **E2E Failures**: Investigate and fix
- **A11y Failures**: Must be resolved
- **Isolation Failures**: Critical for Firefox support

## Maintenance

### **Regular Updates**
- **Weekly**: Run full QA suite
- **Pre-Release**: Complete QA run
- **Post-Release**: Verify no regressions
- **Monthly**: Update fixtures and dependencies

### **Documentation Updates**
- **New Features**: Add to appropriate test suite
- **New Tags**: Update test matrix
- **New Fixtures**: Document regeneration process
- **New Troubleshooting**: Add common issues

---

*This runbook ensures every release meets our quality standards and provides a deterministic, repeatable process for pre-cohort validation.*
