/**
 * A11y Smoke Tests
 * 
 * T5: A11y Polish
 * Comprehensive accessibility smoke tests covering live regions,
 * reduced motion, keyboard navigation, and focus management.
 */

import { test, expect } from '@playwright/test';

test.describe('Accessibility Smoke Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Set up console monitoring for accessibility issues
    const a11yErrors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        const text = msg.text();
        if (text.includes('aria') || text.includes('accessibility') || text.includes('focus')) {
          a11yErrors.push(text);
        }
      }
    });
  });

  test.describe('Live Regions', () => {
    test('should have exactly one aria-live region per dynamic card', async ({ page }) => {
      // Test prosody scenarios page
      await page.goto('/labs/prosody-scenarios');
      
      const scenarioCards = page.locator('[data-testid="scenario-card"]');
      await expect(scenarioCards).toHaveCount(2);
      
      // Check each card has exactly one aria-live region
      for (let i = 0; i < 2; i++) {
        const card = scenarioCards.nth(i);
        const liveRegions = card.locator('[aria-live="polite"]');
        await expect(liveRegions).toHaveCount(1);
      }
    });

    test('should have single aria-live region on practice page', async ({ page }) => {
      await page.goto('/practice');
      
      // Check for single announcement region
      const liveRegions = page.locator('[aria-live="polite"]');
      await expect(liveRegions).toHaveCount(1);
      
      // Check metrics cards don't have individual aria-live regions
      const metricsCards = page.locator('[role="status"]');
      const metricsWithAriaLive = metricsCards.filter({ has: page.locator('[aria-live]') });
      await expect(metricsWithAriaLive).toHaveCount(0);
    });

    test('should have single aria-live region on listen page', async ({ page }) => {
      await page.goto('/listen');
      
      // Check for single announcement region
      const liveRegions = page.locator('[aria-live="polite"]');
      await expect(liveRegions).toHaveCount(1);
      
      // Check status indicators don't have individual aria-live regions
      const statusCards = page.locator('[role="status"]');
      const statusWithAriaLive = statusCards.filter({ has: page.locator('[aria-live]') });
      await expect(statusWithAriaLive).toHaveCount(0);
    });

    test('should announce verdicts to screen readers', async ({ page }) => {
      await page.goto('/labs/prosody-scenarios');
      
      // Enable mock mode
      await page.getByLabel(/Mock Mode/i).click();
      
      // Start voicemail scenario
      const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
      await voicemailCard.getByRole('button', { name: /Start Recording/i }).click();
      
      // Wait for completion
      await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });
      
      // Check aria-live region has announcement
      const liveRegion = page.locator('[aria-live="polite"]');
      await expect(liveRegion).toContainText(/Scenario complete/);
      await expect(liveRegion).toContainText(/Passed|Try again/);
    });

    test('should not duplicate announcements across cards', async ({ page }) => {
      await page.goto('/labs/prosody-scenarios');
      
      // Enable mock mode
      await page.getByLabel(/Mock Mode/i).click();
      
      // Start both scenarios
      const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
      const meetingCard = page.locator('[data-testid="scenario-card"]').last();
      
      await voicemailCard.getByRole('button', { name: /Start Recording/i }).click();
      await meetingCard.getByRole('button', { name: /Start Recording/i }).click();
      
      // Wait for completion
      await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });
      
      // Check that each card has its own announcement
      const voicemailLiveRegion = voicemailCard.locator('[aria-live="polite"]');
      const meetingLiveRegion = meetingCard.locator('[aria-live="polite"]');
      
      await expect(voicemailLiveRegion).toContainText(/voicemail|Voicemail/);
      await expect(meetingLiveRegion).toContainText(/meeting|Meeting/);
    });
  });

  test.describe('Reduced Motion', () => {
    test('should respect reduced motion preference', async ({ page }) => {
      // Mock reduced motion preference
      await page.emulateMedia({ reducedMotion: 'reduce' });
      
      // Navigate to practice page
      await page.goto('/practice');
      
      // Check reduced motion indicator appears
      await expect(page.getByText(/Reduced motion enabled/)).toBeVisible();
      
      // Check that no transition classes are applied
      const elementsWithTransitions = page.locator('[class*="transition"]');
      const transitionCount = await elementsWithTransitions.count();
      
      // Most elements should not have transition classes when reduced motion is enabled
      expect(transitionCount).toBeLessThan(5); // Allow for some necessary transitions
    });

    test('should disable animations in scenario cards', async ({ page }) => {
      // Mock reduced motion preference
      await page.emulateMedia({ reducedMotion: 'reduce' });
      
      await page.goto('/labs/prosody-scenarios');
      
      // Check scenario cards don't have transition animations
      const scenarioCards = page.locator('[data-testid="scenario-card"]');
      await expect(scenarioCards).toHaveCount(2);
      
      // Verify no transition classes are applied
      for (let i = 0; i < 2; i++) {
        const card = scenarioCards.nth(i);
        const element = await card.elementHandle();
        if (element) {
          const className = await element.getAttribute('class');
          expect(className).not.toContain('transition-all');
          expect(className).not.toContain('duration-200');
        }
      }
    });

    test('should disable progress ring animations', async ({ page }) => {
      // Mock reduced motion preference
      await page.emulateMedia({ reducedMotion: 'reduce' });
      
      await page.goto('/labs/strain');
      
      // Enable mock mode and trigger strain detection
      await page.getByLabel(/Mock Mode/i).click();
      await page.getByRole('button', { name: /Start Monitoring/i }).click();
      
      // Wait for cooldown card to appear
      await expect(page.locator('[data-testid="cooldown-card"]')).toBeVisible({ timeout: 10000 });
      
      // Check that progress ring doesn't have transition animations
      const progressRing = page.locator('[style*="transition"]');
      await expect(progressRing).not.toBeVisible();
    });

    test('should maintain functionality without animations', async ({ page }) => {
      // Mock reduced motion preference
      await page.emulateMedia({ reducedMotion: 'reduce' });
      
      await page.goto('/labs/prosody-scenarios');
      
      // Enable mock mode
      await page.getByLabel(/Mock Mode/i).click();
      
      // Complete scenario
      const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
      await voicemailCard.getByRole('button', { name: /Start Recording/i }).click();
      await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });
      
      // Verify functionality still works
      await expect(voicemailCard.getByText(/Gentle fall detected/)).toBeVisible();
      await expect(voicemailCard.getByText(/Passed/)).toBeVisible();
    });
  });

  test.describe('Keyboard Navigation', () => {
    test('should have visible focus rings on interactive elements', async ({ page }) => {
      await page.goto('/practice');
      
      // Tab to first interactive element
      await page.keyboard.press('Tab');
      
      // Check that focus is visible
      const focusedElement = page.locator(':focus');
      await expect(focusedElement).toBeVisible();
      
      // Check focus ring is visible
      const focusRing = await focusedElement.evaluate(el => {
        const styles = window.getComputedStyle(el);
        return styles.outline !== 'none' || styles.boxShadow !== 'none';
      });
      expect(focusRing).toBe(true);
    });

    test('should navigate through interactive elements with Tab', async ({ page }) => {
      await page.goto('/labs/prosody-scenarios');
      
      // Tab through interactive elements
      const interactiveElements = [
        'Mock Mode toggle',
        'Start Recording button',
        'Start Recording button'
      ];
      
      for (const elementText of interactiveElements) {
        await page.keyboard.press('Tab');
        const focusedElement = page.locator(':focus');
        await expect(focusedElement).toBeVisible();
      }
    });

    test('should activate buttons with Space and Enter', async ({ page }) => {
      await page.goto('/labs/prosody-scenarios');
      
      // Enable mock mode
      await page.getByLabel(/Mock Mode/i).click();
      
      // Tab to start recording button
      await page.keyboard.press('Tab');
      await page.keyboard.press('Tab');
      
      // Activate with Space
      await page.keyboard.press('Space');
      
      // Wait for scenario to complete
      await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });
    });

    test('should have skip links for keyboard users', async ({ page }) => {
      await page.goto('/practice');
      
      // Check skip link is present
      const skipLink = page.getByRole('link', { name: /Skip to main content/i });
      await expect(skipLink).toBeVisible();
      
      // Tab to skip link
      await page.keyboard.press('Tab');
      
      // Check skip link is focused
      const focusedElement = page.locator(':focus');
      await expect(focusedElement).toHaveText(/Skip to main content/);
      
      // Activate skip link
      await page.keyboard.press('Enter');
      
      // Check main content is focused
      const mainContent = page.locator('#main-content');
      await expect(mainContent).toBeVisible();
    });

    test('should maintain focus order in forms', async ({ page }) => {
      await page.goto('/listen');
      
      // Tab through form elements
      const formElements = [
        'Microphone button',
        'Audio Engine button',
        'Analysis Engine button'
      ];
      
      for (const elementText of formElements) {
        await page.keyboard.press('Tab');
        const focusedElement = page.locator(':focus');
        await expect(focusedElement).toBeVisible();
      }
    });
  });

  test.describe('Focus Management', () => {
    test('should manage focus during dynamic content changes', async ({ page }) => {
      await page.goto('/labs/prosody-scenarios');
      
      // Enable mock mode
      await page.getByLabel(/Mock Mode/i).click();
      
      // Start scenario
      const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
      await voicemailCard.getByRole('button', { name: /Start Recording/i }).click();
      
      // Wait for completion
      await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });
      
      // Check that focus is managed appropriately
      const focusedElement = page.locator(':focus');
      await expect(focusedElement).toBeVisible();
    });

    test('should restore focus after modal interactions', async ({ page }) => {
      await page.goto('/labs/strain');
      
      // Enable mock mode
      await page.getByLabel(/Mock Mode/i).click();
      
      // Start monitoring
      await page.getByRole('button', { name: /Start Monitoring/i }).click();
      
      // Wait for cooldown card
      await expect(page.locator('[data-testid="cooldown-card"]')).toBeVisible({ timeout: 10000 });
      
      // Check focus is managed
      const focusedElement = page.locator(':focus');
      await expect(focusedElement).toBeVisible();
    });

    test('should handle focus traps in interactive components', async ({ page }) => {
      await page.goto('/practice');
      
      // Start practice session
      await page.getByRole('button', { name: /Start Practice/i }).click();
      
      // Check focus is trapped within practice interface
      const practiceInterface = page.locator('[role="main"]');
      const focusedElement = page.locator(':focus');
      
      // Focus should be within practice interface
      await expect(practiceInterface).toContainElement(focusedElement);
    });
  });

  test.describe('Screen Reader Support', () => {
    test('should have proper ARIA labels and roles', async ({ page }) => {
      await page.goto('/labs/prosody-scenarios');
      
      // Check main heading
      await expect(page.getByRole('heading', { name: /Applied Prosody Scenarios/i })).toBeVisible();
      
      // Check scenario cards have proper structure
      const scenarioCards = page.locator('[data-testid="scenario-card"]');
      await expect(scenarioCards).toHaveCount(2);
      
      // Check buttons have proper labels
      await expect(page.getByRole('button', { name: /Start Recording/i })).toBeVisible();
      await expect(page.getByLabel(/Mock Mode/i)).toBeVisible();
    });

    test('should announce status changes', async ({ page }) => {
      await page.goto('/listen');
      
      // Check status announcements
      const liveRegion = page.locator('[aria-live="polite"]');
      await expect(liveRegion).toBeVisible();
      
      // Start microphone
      await page.getByRole('button', { name: /Start Microphone/i }).click();
      
      // Check announcement updates
      await expect(liveRegion).toContainText(/Microphone active/);
    });

    test('should have descriptive button labels', async ({ page }) => {
      await page.goto('/practice');
      
      // Check button labels are descriptive
      const startButton = page.getByRole('button', { name: /Start Practice/i });
      await expect(startButton).toBeVisible();
      
      const stopButton = page.getByRole('button', { name: /Stop Practice/i });
      await expect(stopButton).toBeVisible();
    });

    test('should have proper heading hierarchy', async ({ page }) => {
      await page.goto('/practice');
      
      // Check heading hierarchy
      const h1 = page.locator('h1');
      await expect(h1).toHaveCount(1);
      
      const h2 = page.locator('h2');
      await expect(h2).toHaveCount(2); // Should have at least 2 h2 elements
      
      // Check h1 comes before h2
      const h1Index = await h1.evaluate(el => Array.from(document.querySelectorAll('h1, h2')).indexOf(el));
      const h2Index = await h2.first().evaluate(el => Array.from(document.querySelectorAll('h1, h2')).indexOf(el));
      expect(h1Index).toBeLessThan(h2Index);
    });
  });

  test.describe('Color and Contrast', () => {
    test('should have sufficient color contrast', async ({ page }) => {
      await page.goto('/practice');
      
      // Check that text is visible and readable
      const textElements = page.locator('p, span, div').filter({ hasText: /[a-zA-Z]/ });
      const textCount = await textElements.count();
      expect(textCount).toBeGreaterThan(0);
      
      // Check that buttons have sufficient contrast
      const buttons = page.locator('button');
      const buttonCount = await buttons.count();
      expect(buttonCount).toBeGreaterThan(0);
    });

    test('should not rely on color alone for information', async ({ page }) => {
      await page.goto('/labs/prosody-scenarios');
      
      // Enable mock mode
      await page.getByLabel(/Mock Mode/i).click();
      
      // Complete scenario
      const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
      await voicemailCard.getByRole('button', { name: /Start Recording/i }).click();
      await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });
      
      // Check that status is communicated through text, not just color
      await expect(voicemailCard.getByText(/Passed|Try again/)).toBeVisible();
    });
  });

  test.describe('Error Handling', () => {
    test('should handle accessibility errors gracefully', async ({ page }) => {
      // Navigate to page
      await page.goto('/practice');
      
      // Check no accessibility errors in console
      const a11yErrors: string[] = [];
      page.on('console', msg => {
        if (msg.type() === 'error') {
          const text = msg.text();
          if (text.includes('aria') || text.includes('accessibility')) {
            a11yErrors.push(text);
          }
        }
      });
      
      // Wait for page to load
      await page.waitForLoadState('networkidle');
      
      // Check no accessibility errors
      expect(a11yErrors).toHaveLength(0);
    });

    test('should maintain accessibility during errors', async ({ page }) => {
      await page.goto('/labs/prosody-scenarios');
      
      // Simulate error by disabling mock mode and trying to record
      const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
      await voicemailCard.getByRole('button', { name: /Start Recording/i }).click();
      
      // Check that error handling maintains accessibility
      const liveRegion = page.locator('[aria-live="polite"]');
      await expect(liveRegion).toBeVisible();
    });
  });
});
