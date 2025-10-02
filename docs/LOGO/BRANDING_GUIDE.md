# Resonai Branding Implementation Guide

This guide documents the complete branding system implementation across all dashboard pages.

## System Architecture

### Shared CSS System
- **File**: `docs/assets/resonai-tokens.css`
- **Purpose**: Centralized brand tokens and logo classes
- **Usage**: Include in all dashboard pages for consistent branding

### Dashboard Files
1. **Main Status Dashboard**: `docs/status.html`
2. **Dashboard Hub**: `docs/dashboard/index.html`
3. **ECRR Trends**: `docs/dashboard/ecrr-compliance-trends.html`
4. **Export Documentation**: `docs/ECRR_QUALITY_DASHBOARD.md`

## Implementation Checklist

### ✅ Favicon System
- Multi-size favicons with cache-busting (`?v=1`)
- Apple touch icon for mobile home screen
- Theme color for browser UI integration

### ✅ Header Branding
- Picture elements with dark/light mode switching
- Proper accessibility (`alt=""`, `aria-hidden="true"`)
- Responsive sizing with CSS custom properties

### ✅ Footer Branding
- Monochrome logos with consistent styling
- Subtle opacity for non-intrusive branding
- CSS-driven approach (no inline styles)

### ✅ Export Integration
- Wordmark branding in Markdown exports
- HTML img tags for reliable PDF rendering
- Relative paths for external file compatibility

### ✅ CSS Architecture
- Shared brand tokens (`--rsn-*` variables)
- Logo system classes (`.logo-container`, `.logo-mono`, `.logo-wordmark`)
- Print optimizations with color preservation
- Dark/light mode support

### ✅ Accessibility Compliance
- Decorative logos use `alt=""` and `aria-hidden="true"`
- Semantic HTML structure with proper roles
- Screen reader friendly with meaningful content prioritization

## Usage Examples

### New Dashboard Page
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Your Dashboard</title>
    
    <!-- Favicon system -->
    <link rel="icon" type="image/png" sizes="32x32" href="LOGO/Resonai_LOGO_ICONonly.png?v=1">
    <link rel="apple-touch-icon" href="LOGO/Resonai_LOGO_ICONonly.png?v=1">
    <meta name="theme-color" content="#0b0d12">
    <meta name="application-name" content="Resonai Dashboard">
    
    <!-- Shared brand system -->
    <link rel="stylesheet" href="assets/resonai-tokens.css">
</head>
<body>
    <header>
        <picture class="logo-container" aria-hidden="true">
            <source media="(prefers-color-scheme: light)" srcset="LOGO/Resonai_LOGO_B.png">
            <img src="LOGO/Resonai_LOGO_A.png" alt="" class="logo-wordmark" aria-hidden="true">
        </picture>
        <h1>Your Dashboard Title</h1>
    </header>
    
    <main>
        <!-- Dashboard content -->
    </main>
    
    <footer>
        <img src="LOGO/Resonai_LOGO_monochrome.png" alt="" class="logo-mono" aria-hidden="true">
        <p>Footer content</p>
    </footer>
</body>
</html>
```

### Export with Branding
```markdown
<p align="left">
  <img src="../LOGO/Resonai_Wordmark_shimmer_grad.png" alt="Resonai" height="28">
</p>
# Your Export Title
```

## Brand Token Usage

### Color Variables
```css
:root {
  --rsn-bg: #000;
  --rsn-fg: #fff;
  --rsn-grad-blue: #2D9CFF;
  --rsn-grad-purple: #9B51E0;
  --rsn-grad-magenta: #E040FB;
  --rsn-grad-orange: #FF6A00;
}
```

### Logo Sizing
```css
:root {
  --rsn-logo-header-height: 36px;
  --rsn-logo-footer-height: 16px;
  --rsn-logo-wordmark-height: 28px;
  --rsn-logo-gap: 0.5rem;
  --rsn-logo-opacity: 0.7;
}
```

### Utility Classes
```css
.bg-rsn-gradient { /* Brand gradient background */ }
.text-rsn-blue { color: var(--rsn-grad-blue); }
.text-rsn-purple { color: var(--rsn-grad-purple); }
.text-rsn-magenta { color: var(--rsn-grad-magenta); }
.text-rsn-orange { color: var(--rsn-grad-orange); }
```

## Future Enhancements

### SVG Integration (Ready)
When SVG assets become available, update picture elements:
```html
<picture class="logo-container">
  <source type="image/svg+xml" srcset="LOGO/Resonai_LOGO_A.svg">
  <source media="(prefers-color-scheme: light)" srcset="LOGO/Resonai_LOGO_B.png">
  <img src="LOGO/Resonai_LOGO_A.png" alt="" class="logo-wordmark" aria-hidden="true">
</picture>
```

### Small-Size Optimization
Create simplified icons for ≤24px contexts:
- `Resonai_ICON_simplified-24.png`
- Remove inner laminar ripples to avoid shimmer artifacts

## Verification Checklist

Before deploying any dashboard changes:

- [ ] Include `assets/resonai-tokens.css`
- [ ] Use proper favicon system with cache-busting
- [ ] Implement header branding with picture elements
- [ ] Add footer branding with monochrome logo
- [ ] Ensure no inline styles (`style=` attributes)
- [ ] Verify accessibility compliance (`aria-hidden="true"` for decorative logos)
- [ ] Test dark/light mode switching
- [ ] Confirm print optimization
- [ ] Validate semantic HTML structure

## File Structure

```
docs/
├── assets/
│   └── resonai-tokens.css          # Shared brand system
├── dashboard/
│   ├── index.html                  # Dashboard hub
│   └── ecrr-compliance-trends.html # ECRR trends dashboard
├── LOGO/
│   ├── README.md                   # Asset usage guide
│   ├── BRANDING_GUIDE.md          # Implementation guide (this file)
│   ├── Resonai_LOGO_A.png         # Dark mode header logo
│   ├── Resonai_LOGO_B.png         # Light mode header logo
│   ├── Resonai_LOGO_ICONonly.png  # Favicon/icon logo
│   ├── Resonai_LOGO_monochrome.png # Footer monochrome logo
│   └── Resonai_Wordmark_shimmer_grad.png # Export wordmark
├── status.html                     # Main status dashboard
└── ECRR_QUALITY_DASHBOARD.md      # Export documentation
```

This system ensures consistent, accessible, and maintainable branding across all Resonai dashboard pages.
