# SVG Integration Guide - Resonai Logo System

## 🎯 Overview

This guide outlines the preparation for SVG integration into the Resonai logo system. The current CSS architecture is already SVG-ready, requiring only asset updates when vector files become available.

## 🏗 Current Architecture (SVG-Ready)

### Picture Element Structure
The existing `<picture>` elements are designed to support SVG with PNG fallback:

```html
<picture class="logo-container" aria-hidden="true">
  <source type="image/svg+xml" srcset="LOGO/Resonai_LOGO_A.svg">
  <source media="(prefers-color-scheme: light)" srcset="LOGO/Resonai_LOGO_B.png">
  <img src="LOGO/Resonai_LOGO_A.png" alt="" class="logo-wordmark" aria-hidden="true">
</picture>
```

### CSS Classes (Vector-Optimized)
The shared CSS system includes SVG-specific classes:

```css
/* Current PNG classes */
.logo-wordmark { height: var(--rsn-logo-wordmark-height); }
.logo-mono { height: var(--rsn-logo-footer-height); opacity: 0.7; }

/* SVG-ready classes (already defined) */
.logo-svg { width: auto; height: var(--rsn-logo-header-height); }
.logo-svg-mono { width: auto; height: var(--rsn-logo-footer-height); opacity: 0.7; }
.logo-svg-wordmark { width: auto; height: var(--rsn-logo-wordmark-height); }
```

## 📁 Expected SVG Assets

When SVG versions become available, place them in `docs/LOGO/`:

### Primary Logos
- `Resonai_LOGO_A.svg` - Dark mode header logo
- `Resonai_LOGO_B.svg` - Light mode header logo
- `Resonai_LOGO_ICONonly.svg` - Favicon/icon logo
- `Resonai_LOGO_monochrome.svg` - Footer monochrome logo

### Export Assets
- `Resonai_Wordmark_shimmer_grad.svg` - Export wordmark
- `Resonai_Wordmark_monochrome.svg` - Monochrome wordmark

### Simplified Icons (Future)
- `Resonai_ICON_simplified-24.svg` - Small size optimized icon

## 🔄 Migration Steps

### Step 1: Update Picture Elements
Replace existing picture elements with SVG-first approach:

```html
<!-- BEFORE: PNG-first -->
<picture class="logo-container" aria-hidden="true">
  <source media="(prefers-color-scheme: light)" srcset="LOGO/Resonai_LOGO_B.png">
  <img src="LOGO/Resonai_LOGO_A.png" alt="" class="logo-wordmark" aria-hidden="true">
</picture>

<!-- AFTER: SVG-first -->
<picture class="logo-container" aria-hidden="true">
  <source type="image/svg+xml" srcset="LOGO/Resonai_LOGO_A.svg">
  <source media="(prefers-color-scheme: light)" type="image/svg+xml" srcset="LOGO/Resonai_LOGO_B.svg">
  <source media="(prefers-color-scheme: light)" srcset="LOGO/Resonai_LOGO_B.png">
  <img src="LOGO/Resonai_LOGO_A.png" alt="" class="logo-wordmark" aria-hidden="true">
</picture>
```

### Step 2: Update CSS Classes
Switch from PNG classes to SVG classes:

```html
<!-- BEFORE: PNG classes -->
<img src="LOGO/Resonai_LOGO_A.png" alt="" class="logo-wordmark" aria-hidden="true">

<!-- AFTER: SVG classes -->
<img src="LOGO/Resonai_LOGO_A.svg" alt="" class="logo-svg-wordmark" aria-hidden="true">
```

### Step 3: Update Favicon System
Replace PNG favicons with SVG:

```html
<!-- BEFORE: PNG favicons -->
<link rel="icon" type="image/png" sizes="32x32" href="LOGO/Resonai_LOGO_ICONonly.png?v=1">
<link rel="icon" type="image/png" sizes="192x192" href="LOGO/Resonai_LOGO_ICONonly.png?v=1">

<!-- AFTER: SVG favicon -->
<link rel="icon" type="image/svg+xml" href="LOGO/Resonai_LOGO_ICONonly.svg?v=1">
<link rel="icon" type="image/png" sizes="32x32" href="LOGO/Resonai_LOGO_ICONonly.png?v=1">
<link rel="icon" type="image/png" sizes="192x192" href="LOGO/Resonai_LOGO_ICONonly.png?v=1">
```

## 🎨 SVG Optimization Guidelines

### File Structure
- **Clean markup**: Remove unnecessary metadata and comments
- **Optimized paths**: Use simplified vector paths
- **Proper viewBox**: Set appropriate viewBox dimensions
- **Consistent sizing**: Match PNG dimensions for seamless transition

### Color Handling
- **CSS variables**: Use CSS custom properties for colors where possible
- **Theme support**: Separate light/dark variants
- **Monochrome versions**: Simplified versions for footer use

### Performance
- **Compression**: Use SVGO or similar tools for optimization
- **Inline consideration**: For small icons, consider inline SVG
- **Caching**: Ensure proper cache headers for SVG files

## 🧪 Testing Checklist

### Browser Compatibility
- [ ] Chrome/Chromium (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile browsers (iOS Safari, Chrome Mobile)

### Responsive Testing
- [ ] Desktop (1920x1080)
- [ ] Tablet (768x1024)
- [ ] Mobile (375x667)
- [ ] High-DPI displays (2x, 3x)

### Feature Testing
- [ ] Dark/light mode switching
- [ ] Print optimization
- [ ] Favicon display
- [ ] Export functionality

## 🔧 Implementation Script

### Automated Migration
Create a migration script to update all dashboard files:

```bash
#!/bin/bash
# SVG Migration Script

# Update picture elements
find docs/ -name "*.html" -exec sed -i 's/source media="(prefers-color-scheme: light)" srcset="LOGO\/Resonai_LOGO_B\.png"/source type="image\/svg+xml" srcset="LOGO\/Resonai_LOGO_A.svg"\n  <source media="(prefers-color-scheme: light)" type="image\/svg+xml" srcset="LOGO\/Resonai_LOGO_B.svg"\n  <source media="(prefers-color-scheme: light)" srcset="LOGO\/Resonai_LOGO_B.png"/g' {} \;

# Update CSS classes
find docs/ -name "*.html" -exec sed -i 's/class="logo-wordmark"/class="logo-svg-wordmark"/g' {} \;
find docs/ -name "*.html" -exec sed -i 's/class="logo-mono"/class="logo-svg-mono"/g' {} \;

echo "SVG migration complete. Please test all dashboards."
```

## 📋 Rollback Plan

### Quick Rollback
If SVG integration causes issues:

1. **Revert picture elements** to PNG-first approach
2. **Switch CSS classes** back to PNG versions
3. **Update favicon links** to PNG fallbacks
4. **Test functionality** across all browsers

### Rollback Script
```bash
#!/bin/bash
# SVG Rollback Script

# Revert picture elements
find docs/ -name "*.html" -exec sed -i 's/source type="image\/svg+xml" srcset="LOGO\/Resonai_LOGO_A\.svg"//g' {} \;
find docs/ -name "*.html" -exec sed -i 's/source media="(prefers-color-scheme: light)" type="image\/svg+xml" srcset="LOGO\/Resonai_LOGO_B\.svg"//g' {} \;

# Revert CSS classes
find docs/ -name "*.html" -exec sed -i 's/class="logo-svg-wordmark"/class="logo-wordmark"/g' {} \;
find docs/ -name "*.html" -exec sed -i 's/class="logo-svg-mono"/class="logo-mono"/g' {} \;

echo "SVG rollback complete. PNG fallbacks restored."
```

## 🚀 Benefits of SVG Integration

### Performance
- **Smaller file sizes** for simple logos
- **Scalable graphics** without quality loss
- **Better caching** with proper headers

### Quality
- **Crisp rendering** at all resolutions
- **Perfect scaling** for high-DPI displays
- **Consistent appearance** across devices

### Maintainability
- **CSS styling** for color changes
- **Easier updates** for brand modifications
- **Better accessibility** with semantic markup

## 📚 Additional Resources

- **SVG Optimization**: [SVGO Documentation](https://github.com/svg/svgo)
- **Browser Support**: [Can I Use SVG](https://caniuse.com/svg)
- **Performance**: [SVG Performance Best Practices](https://web.dev/svg-optimization/)
- **Accessibility**: [SVG Accessibility Guidelines](https://www.w3.org/WAI/WCAG21/Understanding/non-text-content.html)

---

**Ready for SVG Integration**: The current logo system architecture is fully prepared for SVG assets. When vector files become available, follow this guide for seamless migration while maintaining all existing functionality.
