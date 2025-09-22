# Comfort Cat Motion

## Animation Principles
- **Gentle and calm** - Like a cat's slow blink
- **Purposeful** - Every animation serves a function
- **Respectful** - Never startle or overwhelm
- **Efficient** - Quick enough to feel responsive

## Timing Functions
- **Ease-in-out**: `cubic-bezier(0.4, 0, 0.2, 1)` - Default for most animations
- **Ease-out**: `cubic-bezier(0, 0, 0.2, 1)` - For entrances
- **Ease-in**: `cubic-bezier(0.4, 0, 1, 1)` - For exits

## Duration Guidelines
- **Micro-interactions**: 150ms (hover, focus)
- **UI transitions**: 300ms (panel slides, modal opens)
- **Status changes**: 500ms (loading states, success states)
- **Page transitions**: 600ms (route changes)

## Specific Animations

### Status Indicators
- **Pulse**: 2s duration, infinite, ease-in-out
- **Fade in/out**: 300ms duration
- **Scale**: 0.95 to 1.05 for subtle emphasis

### Data Updates
- **Counter animations**: 800ms duration for number changes
- **Chart updates**: 600ms duration with stagger
- **List updates**: 400ms duration with fade

### Loading States
- **Skeleton screens**: 1.5s duration, infinite
- **Spinners**: 1s duration, infinite, linear
- **Progress bars**: Smooth transitions, no jumps

## Reduce Motion Support
```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Accessibility
- Respect `prefers-reduced-motion` setting
- Provide alternative feedback for motion-dependent interactions
- Ensure animations don't cause vestibular disorders
- Keep motion subtle and purposeful
