# 👉 Cursor Agent Prompt — T5 A11y Polish (Live Regions + Reduced Motion)

**Task**: Complete accessibility audit and polish across Resonai app. Focus on **live regions consistency**, **reduced-motion enforcement**, and **Playwright a11y smoke tests**. Ensure WCAG 2.2 AA compliance with special attention to voice practice flows.

## 🔨 Implementation Plan

### **1. Live Regions Audit & Standardization**

#### **Current State Analysis**
- ✅ `CooldownCard`: Has `aria-live="polite"` with `aria-atomic="true"`
- ✅ `ScenarioCard`: Has `aria-live="polite"` with `aria-atomic="true"`
- ❓ **Missing**: Consistent live region patterns across all dynamic content
- ❓ **Missing**: Live region management for audio feedback, progress updates

#### **Live Regions Implementation**
```typescript
// Standardized live region component
interface LiveRegionProps {
  level: 'polite' | 'assertive';
  atomic?: boolean;
  children: React.ReactNode;
  className?: string;
}

export function LiveRegion({ level, atomic = true, children, className = 'sr-only' }: LiveRegionProps) {
  return (
    <div
      aria-live={level}
      aria-atomic={atomic}
      role="status"
      className={className}
    >
      {children}
    </div>
  );
}

// Usage patterns for different scenarios
const LIVE_REGION_PATTERNS = {
  // Audio feedback (polite - doesn't interrupt)
  audioFeedback: (message: string) => (
    <LiveRegion level="polite">
      {message}
    </LiveRegion>
  ),
  
  // Critical alerts (assertive - interrupts)
  criticalAlert: (message: string) => (
    <LiveRegion level="assertive">
      {message}
    </LiveRegion>
  ),
  
  // Progress updates (polite - continuous)
  progressUpdate: (message: string) => (
    <LiveRegion level="polite">
      {message}
    </LiveRegion>
  )
};
```

#### **Required Live Regions**
1. **Audio Engine Status**: "Microphone connected", "Audio processing started", "CNN classifier loaded"
2. **Practice Flow Updates**: "Recording started", "Analysis complete", "Feedback ready"
3. **Safety Alerts**: "Vocal strain detected", "Cooldown activated", "Safety pause complete"
4. **Progress Indicators**: "Exercise 1 of 3", "Progress: 67%", "Session complete"
5. **Error States**: "Microphone access denied", "Audio processing failed", "Network error"

### **2. Reduced Motion Enforcement**

#### **Current State Analysis**
- ✅ `CooldownCard`: Has `reducedMotion` prop and conditional animations
- ❓ **Missing**: Global reduced motion detection and enforcement
- ❓ **Missing**: Consistent reduced motion patterns across components

#### **Reduced Motion Implementation**
```typescript
// Global reduced motion hook
export function useReducedMotion(): boolean {
  const [reducedMotion, setReducedMotion] = useState(false);
  
  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    setReducedMotion(mediaQuery.matches);
    
    const handleChange = (e: MediaQueryListEvent) => {
      setReducedMotion(e.matches);
    };
    
    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, []);
  
  return reducedMotion;
}

// Animation utility with reduced motion support
export function getAnimationClasses(baseClasses: string, reducedMotion: boolean): string {
  if (reducedMotion) {
    return baseClasses.replace(/duration-\d+|animate-\w+|transition-\w+/g, '');
  }
  return baseClasses;
}

// Component pattern
export function AnimatedComponent({ children }: { children: React.ReactNode }) {
  const reducedMotion = useReducedMotion();
  
  return (
    <div className={getAnimationClasses(
      'transition-all duration-300 hover:scale-105',
      reducedMotion
    )}>
      {children}
    </div>
  );
}
```

#### **Required Reduced Motion Fixes**
1. **Progress Rings**: Remove `transition-all duration-1000` when reduced motion enabled
2. **Button Hover Effects**: Remove `hover:scale-105` and `transform` animations
3. **Loading Spinners**: Replace with static indicators or simple color changes
4. **Audio Visualizations**: Use static bars instead of animated waveforms
5. **Page Transitions**: Remove slide/fade animations between routes

### **3. Keyboard Navigation & Focus Management**

#### **Focus Management Implementation**
```typescript
// Focus trap for modal components
export function useFocusTrap(isActive: boolean) {
  const containerRef = useRef<HTMLElement>(null);
  
  useEffect(() => {
    if (!isActive || !containerRef.current) return;
    
    const focusableElements = containerRef.current.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    
    const firstElement = focusableElements[0] as HTMLElement;
    const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement;
    
    const handleTabKey = (e: KeyboardEvent) => {
      if (e.key === 'Tab') {
        if (e.shiftKey) {
          if (document.activeElement === firstElement) {
            lastElement.focus();
            e.preventDefault();
          }
        } else {
          if (document.activeElement === lastElement) {
            firstElement.focus();
            e.preventDefault();
          }
        }
      }
    };
    
    document.addEventListener('keydown', handleTabKey);
    firstElement?.focus();
    
    return () => document.removeEventListener('keydown', handleTabKey);
  }, [isActive]);
  
  return containerRef;
}

// Skip link component
export function SkipLink({ href, children }: { href: string; children: React.ReactNode }) {
  return (
    <a
      href={href}
      className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-blue-600 text-white px-4 py-2 rounded-lg z-50"
    >
      {children}
    </a>
  );
}
```

#### **Required Keyboard Navigation**
1. **Skip Links**: Add skip links to main content, navigation, and practice areas
2. **Focus Traps**: Implement focus traps for modal dialogs and cooldown cards
3. **Keyboard Shortcuts**: Add keyboard shortcuts for common actions (Space for record, Escape for stop)
4. **Focus Indicators**: Ensure all interactive elements have visible focus indicators
5. **Tab Order**: Verify logical tab order through all practice flows

### **4. Screen Reader Optimization**

#### **Screen Reader Implementation**
```typescript
// Screen reader announcements
export function useScreenReaderAnnouncements() {
  const [announcements, setAnnouncements] = useState<string[]>([]);
  
  const announce = useCallback((message: string, priority: 'polite' | 'assertive' = 'polite') => {
    setAnnouncements(prev => [...prev, message]);
    
    // Clear announcement after screen reader has time to process
    setTimeout(() => {
      setAnnouncements(prev => prev.filter(a => a !== message));
    }, 1000);
  }, []);
  
  return { announcements, announce };
}

// Accessible progress indicators
export function AccessibleProgress({ 
  value, 
  max, 
  label 
}: { 
  value: number; 
  max: number; 
  label: string; 
}) {
  const percentage = Math.round((value / max) * 100);
  
  return (
    <div>
      <div 
        role="progressbar"
        aria-valuenow={value}
        aria-valuemin={0}
        aria-valuemax={max}
        aria-label={`${label}: ${percentage}%`}
        className="w-full bg-gray-200 rounded-full h-2"
      >
        <div 
          className="bg-blue-600 h-2 rounded-full transition-all duration-300"
          style={{ width: `${percentage}%` }}
        />
      </div>
      <span className="sr-only">{label}: {percentage}%</span>
    </div>
  );
}
```

#### **Required Screen Reader Features**
1. **Audio Status**: Announce microphone connection, recording status, analysis results
2. **Practice Progress**: Announce exercise completion, session progress, achievements
3. **Error Messages**: Clear, actionable error messages with recovery instructions
4. **Form Labels**: All form inputs have descriptive labels and error messages
5. **Dynamic Content**: All dynamic content changes are announced appropriately

### **5. Playwright A11y Smoke Tests**

#### **Test Implementation**
```typescript
// tests/e2e/a11y-smoke.e2e.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Accessibility Smoke Tests', () => {
  test('should have proper heading hierarchy', async ({ page }) => {
    await page.goto('/');
    
    // Check for proper h1
    const h1 = await page.locator('h1').first();
    await expect(h1).toBeVisible();
    
    // Check heading order (no skipped levels)
    const headings = await page.locator('h1, h2, h3, h4, h5, h6').all();
    let currentLevel = 0;
    
    for (const heading of headings) {
      const level = parseInt(await heading.evaluate(el => el.tagName.charAt(1)));
      expect(level).toBeLessThanOrEqual(currentLevel + 1);
      currentLevel = Math.max(currentLevel, level);
    }
  });
  
  test('should support keyboard navigation', async ({ page }) => {
    await page.goto('/');
    
    // Tab through interactive elements
    await page.keyboard.press('Tab');
    const firstFocused = await page.locator(':focus');
    await expect(firstFocused).toBeVisible();
    
    // Check focus indicators
    const focusStyles = await firstFocused.evaluate(el => {
      const styles = window.getComputedStyle(el);
      return {
        outline: styles.outline,
        boxShadow: styles.boxShadow
      };
    });
    
    expect(focusStyles.outline).not.toBe('none');
  });
  
  test('should respect reduced motion preferences', async ({ page }) => {
    await page.goto('/');
    
    // Enable reduced motion
    await page.emulateMedia({ reducedMotion: 'reduce' });
    
    // Check that animations are disabled
    const animatedElements = await page.locator('[class*="animate-"], [class*="transition-"]').all();
    
    for (const element of animatedElements) {
      const computedStyle = await element.evaluate(el => {
        const styles = window.getComputedStyle(el);
        return {
          animationDuration: styles.animationDuration,
          transitionDuration: styles.transitionDuration
        };
      });
      
      expect(computedStyle.animationDuration).toBe('0s');
      expect(computedStyle.transitionDuration).toBe('0s');
    }
  });
  
  test('should have proper ARIA labels and roles', async ({ page }) => {
    await page.goto('/practice');
    
    // Check for proper ARIA labels
    const buttons = await page.locator('button').all();
    for (const button of buttons) {
      const ariaLabel = await button.getAttribute('aria-label');
      const ariaLabelledBy = await button.getAttribute('aria-labelledby');
      const textContent = await button.textContent();
      
      expect(ariaLabel || ariaLabelledBy || textContent?.trim()).toBeTruthy();
    }
    
    // Check for proper roles
    const progressbars = await page.locator('[role="progressbar"]');
    await expect(progressbars).toHaveCount(await page.locator('.progress, [class*="progress"]').count());
  });
  
  test('should announce dynamic content changes', async ({ page }) => {
    await page.goto('/practice');
    
    // Start recording
    await page.click('button[aria-label*="Start"]');
    
    // Check for live region announcements
    const liveRegions = await page.locator('[aria-live]');
    await expect(liveRegions).toHaveCount(1);
    
    // Check that live region has content
    const liveRegionContent = await liveRegions.textContent();
    expect(liveRegionContent).toBeTruthy();
  });
  
  test('should have proper color contrast', async ({ page }) => {
    await page.goto('/');
    
    // Check text color contrast (simplified test)
    const textElements = await page.locator('p, span, div').all();
    
    for (const element of textElements) {
      const textContent = await element.textContent();
      if (textContent && textContent.trim().length > 0) {
        const color = await element.evaluate(el => {
          const styles = window.getComputedStyle(el);
          return styles.color;
        });
        
        // Basic check that color is not transparent
        expect(color).not.toBe('rgba(0, 0, 0, 0)');
      }
    }
  });
});
```

#### **Required Test Coverage**
1. **Heading Hierarchy**: Proper h1-h6 structure without skipped levels
2. **Keyboard Navigation**: Tab order, focus indicators, keyboard shortcuts
3. **Reduced Motion**: Animations disabled when `prefers-reduced-motion: reduce`
4. **ARIA Labels**: All interactive elements have proper labels and roles
5. **Live Regions**: Dynamic content changes are announced appropriately
6. **Color Contrast**: Text meets WCAG AA contrast requirements
7. **Screen Reader**: Content is properly structured for screen readers

### **6. Component-Specific A11y Fixes**

#### **Practice HUD Accessibility**
```typescript
export function AccessiblePracticeHUD({ 
  pitch, 
  confidence, 
  isRecording 
}: {
  pitch: number;
  confidence: number;
  isRecording: boolean;
}) {
  const reducedMotion = useReducedMotion();
  const { announce } = useScreenReaderAnnouncements();
  
  useEffect(() => {
    if (isRecording) {
      announce(`Recording started. Current pitch: ${Math.round(pitch)} Hz`);
    }
  }, [isRecording, pitch, announce]);
  
  return (
    <div role="region" aria-label="Practice HUD">
      <SkipLink href="#main-content">Skip to main content</SkipLink>
      
      <div className="grid grid-cols-2 gap-4">
        <div>
          <h3 className="text-sm font-medium text-gray-700">Pitch</h3>
          <div 
            className="text-2xl font-bold"
            aria-live="polite"
            aria-label={`Current pitch: ${Math.round(pitch)} Hz`}
          >
            {Math.round(pitch)} Hz
          </div>
        </div>
        
        <div>
          <h3 className="text-sm font-medium text-gray-700">Confidence</h3>
          <AccessibleProgress 
            value={confidence}
            max={1}
            label="Detection confidence"
          />
        </div>
      </div>
      
      <div className="mt-4">
        <div 
          className={`w-3 h-3 rounded-full ${
            isRecording ? 'bg-red-500' : 'bg-gray-400'
          }`}
          aria-label={isRecording ? 'Recording' : 'Not recording'}
        />
        <span className="sr-only">
          {isRecording ? 'Recording in progress' : 'Not recording'}
        </span>
      </div>
    </div>
  );
}
```

#### **Audio Controls Accessibility**
```typescript
export function AccessibleAudioControls({ 
  onStart, 
  onStop, 
  isRecording 
}: {
  onStart: () => void;
  onStop: () => void;
  isRecording: boolean;
}) {
  const { announce } = useScreenReaderAnnouncements();
  
  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === ' ' && !isRecording) {
      e.preventDefault();
      onStart();
      announce('Recording started');
    } else if (e.key === 'Escape' && isRecording) {
      e.preventDefault();
      onStop();
      announce('Recording stopped');
    }
  };
  
  useEffect(() => {
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isRecording]);
  
  return (
    <div className="flex space-x-4">
      <button
        onClick={onStart}
        disabled={isRecording}
        className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        aria-label={isRecording ? 'Recording in progress' : 'Start recording'}
        aria-describedby="recording-instructions"
      >
        {isRecording ? 'Recording...' : 'Start Recording'}
      </button>
      
      <button
        onClick={onStop}
        disabled={!isRecording}
        className="px-6 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:bg-gray-400 focus:ring-2 focus:ring-red-500 focus:ring-offset-2"
        aria-label="Stop recording"
      >
        Stop Recording
      </button>
      
      <div id="recording-instructions" className="sr-only">
        Press Space to start recording, Escape to stop
      </div>
    </div>
  );
}
```

## ✅ Acceptance Criteria

- [ ] **Live Regions**: Consistent `aria-live` patterns across all dynamic content
- [ ] **Reduced Motion**: All animations respect `prefers-reduced-motion: reduce`
- [ ] **Keyboard Navigation**: Full keyboard accessibility with proper tab order
- [ ] **Screen Reader**: All content properly announced and structured
- [ ] **ARIA Labels**: All interactive elements have descriptive labels
- [ ] **Focus Management**: Visible focus indicators and proper focus traps
- [ ] **Playwright Tests**: Comprehensive a11y smoke test suite passing
- [ ] **WCAG 2.2 AA**: All components meet accessibility standards

## 📦 Deliverables

- **Components**: `LiveRegion`, `AccessibleProgress`, `SkipLink`, `useReducedMotion` hook
- **Tests**: `tests/e2e/a11y-smoke.e2e.spec.ts` with comprehensive coverage
- **Documentation**: `docs/accessibility-guide.md` with implementation patterns
- **Release Notes**: `docs/release-notes/t5-a11y-polish.md`
- **PR Notes**: Scope, files changed, test coverage, rollback plan

---

# 📝 GitHub Issue Body — T5 A11y Polish (copy-paste)

```markdown
# T5: A11y Polish — Live Regions + Reduced Motion + Playwright Smokes

## Priority
🟡 Medium (after T4) — required before broader beta

## Goal
Complete accessibility audit and polish across Resonai app. Focus on live regions consistency, reduced-motion enforcement, and Playwright a11y smoke tests. Ensure WCAG 2.2 AA compliance with special attention to voice practice flows.

## Scope
- Live regions audit & standardization across all dynamic content
- Reduced motion enforcement with global detection and component patterns
- Keyboard navigation & focus management improvements
- Screen reader optimization with proper announcements
- Playwright a11y smoke test suite with comprehensive coverage
- Component-specific a11y fixes for Practice HUD and audio controls

## Acceptance Criteria
- [ ] Live regions: Consistent `aria-live` patterns across all dynamic content
- [ ] Reduced motion: All animations respect `prefers-reduced-motion: reduce`
- [ ] Keyboard navigation: Full keyboard accessibility with proper tab order
- [ ] Screen reader: All content properly announced and structured
- [ ] ARIA labels: All interactive elements have descriptive labels
- [ ] Focus management: Visible focus indicators and proper focus traps
- [ ] Playwright tests: Comprehensive a11y smoke test suite passing
- [ ] WCAG 2.2 AA: All components meet accessibility standards

## Files
- `src/components/a11y/LiveRegion.tsx`
- `src/components/a11y/AccessibleProgress.tsx`
- `src/hooks/useReducedMotion.ts`
- `src/hooks/useScreenReaderAnnouncements.ts`
- `tests/e2e/a11y-smoke.e2e.spec.ts`
- `docs/accessibility-guide.md`
- `docs/release-notes/t5-a11y-polish.md`

## ECRR
- [ ] Examine: current a11y implementation and gaps
- [ ] Clean: standardize patterns, remove inconsistent implementations
- [ ] Report: accessibility guide, test results, compliance status
- [ ] Role: Cursor Agent implementor

## Labels
`accessibility`, `a11y`, `wcag`, `screen-reader`, `keyboard-navigation`, `medium-priority`

## Milestone
A11y Polish v1

## Assignee
@cursor-agent
```

---

*This T5 prompt provides comprehensive accessibility improvements focusing on live regions, reduced motion, and Playwright testing. The implementation includes standardized components, hooks, and test patterns to ensure WCAG 2.2 AA compliance across the entire Resonai application.*
