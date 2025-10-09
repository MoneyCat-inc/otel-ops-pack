# Resonai Logo System - Team Training Guide

## 🎯 Overview

The Resonai logo system provides consistent branding across all dashboard pages through a centralized CSS architecture. This guide helps development team members quickly implement and maintain the branding system.

## 🚀 Quick Start

### For New Dashboard Pages

1. **Include the shared CSS system**:
```html
<link rel="stylesheet" href="assets/resonai-tokens.css">
```

2. **Use standardized logo elements**:
```html
<!-- Header Logo -->
<picture class="logo-container" aria-hidden="true">
  <source media="(prefers-color-scheme: light)" srcset="LOGO/Resonai_LOGO_B.png">
  <img src="LOGO/Resonai_LOGO_A.png" alt="" class="logo-wordmark" aria-hidden="true">
</picture>

<!-- Footer Logo -->
<img src="LOGO/Resonai_LOGO_monochrome.png" alt="" class="logo-mono" aria-hidden="true">
```

3. **Follow the verification checklist**:
- ✅ No inline `style` attributes
- ✅ No inline `height` attributes on logos
- ✅ Proper `aria-hidden="true"` on decorative logos
- ✅ Semantic HTML structure

## 📚 Key Concepts

### CSS Custom Properties (Tokens)
```css
:root {
  --rsn-bg: #000;                    /* Primary dark background */
  --rsn-fg: #fff;                    /* Primary text color */
  --rsn-grad-blue: #2D9CFF;          /* Brand gradient blue */
  --rsn-grad-purple: #9B51E0;        /* Brand gradient purple */
  --rsn-grad-magenta: #E040FB;       /* Brand gradient magenta */
  --rsn-grad-orange: #FF6A00;        /* Brand gradient orange */
  
  /* Logo sizing */
  --rsn-logo-header-height: 36px;
  --rsn-logo-footer-height: 16px;
  --rsn-logo-wordmark-height: 28px;
}
```

### Logo Classes
- `.logo-container` - Flexbox container for header logos
- `.logo-wordmark` - Standard logo sizing (28px height)
- `.logo-mono` - Footer monochrome logo (16px height)

### Utility Classes
- `.bg-rsn-gradient` - Brand gradient background
- `.text-rsn-blue` - Brand blue text color
- `.text-rsn-purple` - Brand purple text color
- `.text-rsn-magenta` - Brand magenta text color
- `.text-rsn-orange` - Brand orange text color

## 🛠 Common Tasks

### Adding a New Dashboard Page

1. **Create the HTML file** with proper structure
2. **Include shared CSS**: `<link rel="stylesheet" href="assets/resonai-tokens.css">`
3. **Add favicon system**:
```html
<link rel="icon" type="image/png" sizes="32x32" href="LOGO/Resonai_LOGO_ICONonly.png?v=1">
<link rel="apple-touch-icon" href="LOGO/Resonai_LOGO_ICONonly.png?v=1">
<meta name="theme-color" content="#0b0d12">
<meta name="application-name" content="Resonai Dashboard">
```

4. **Implement header branding**:
```html
<header role="banner">
  <picture class="logo-container" aria-hidden="true">
    <source media="(prefers-color-scheme: light)" srcset="LOGO/Resonai_LOGO_B.png">
    <img src="LOGO/Resonai_LOGO_A.png" alt="" class="logo-wordmark" aria-hidden="true">
  </picture>
  <h1>Your Dashboard Title</h1>
</header>
```

5. **Add footer branding**:
```html
<footer role="contentinfo">
  <img src="LOGO/Resonai_LOGO_monochrome.png" alt="" class="logo-mono" aria-hidden="true">
  <p>Footer content</p>
</footer>
```

### Updating Brand Colors

1. **Edit the shared CSS file**: `docs/assets/resonai-tokens.css`
2. **Update CSS custom properties** in the `:root` selector
3. **Test across all dashboards** to ensure consistency

### Adding Export Branding

For Markdown/PDF exports, include the wordmark:
```markdown
<p align="left">
  <img src="../LOGO/Resonai_Wordmark_shimmer_grad.png" alt="Resonai" class="logo-wordmark">
</p>
# Your Export Title
```

## 🎨 Design Guidelines

### Logo Usage
- **Header logos**: Use `.logo-wordmark` class for consistent 28px height
- **Footer logos**: Use `.logo-mono` class for subtle 16px branding
- **Export logos**: Include wordmark at top of documents

### Color Usage
- **Primary branding**: Use `--rsn-grad-*` variables for gradients
- **Text colors**: Use `--rsn-fg` and `--rsn-muted` for readability
- **Backgrounds**: Use `--rsn-bg` and `--rsn-surface` for consistency

### Accessibility
- **Decorative logos**: Always use `aria-hidden="true"`
- **Meaningful logos**: Use descriptive `alt` text
- **Semantic structure**: Use proper HTML5 landmarks

## 🔧 Troubleshooting

### Logo Not Displaying
1. Check file paths are correct relative to dashboard location
2. Verify shared CSS is included: `<link rel="stylesheet" href="assets/resonai-tokens.css">`
3. Ensure logo files exist in `docs/LOGO/` directory

### Inconsistent Sizing
1. Use CSS classes instead of inline `height` attributes
2. Check that `.logo-wordmark` or `.logo-mono` classes are applied
3. Verify shared CSS is loaded before page-specific styles

### Dark/Light Mode Issues
1. Ensure `<picture>` element with `<source>` media queries
2. Check that both logo variants exist (A.png and B.png)
3. Test with system dark/light mode switching

## 📖 Additional Resources

- **Asset Guide**: `docs/LOGO/README.md` - Complete asset usage documentation
- **Implementation Guide**: `docs/LOGO/BRANDING_GUIDE.md` - Detailed technical reference
- **ECRR Report**: `docs/ECRR_REPORTS/2025-01-29-logo-system-rollout.md` - Implementation details

## 🤝 Getting Help

1. **Check existing dashboards** for reference implementations
2. **Review the verification checklist** in `BRANDING_GUIDE.md`
3. **Test in multiple browsers** and screen sizes
4. **Validate accessibility** with screen readers

---

**Remember**: The goal is consistent, accessible branding across all Resonai dashboard pages. When in doubt, follow the established patterns in existing dashboards.
