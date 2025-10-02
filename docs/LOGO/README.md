# Resonai Logo Assets Guide

This directory contains the Resonai logo assets for consistent branding across dashboards, exports, and print materials.

## Asset Usage Guide

### Header Logos (Primary Branding)
- **`Resonai_LOGO_A.png`** - Dark mode header logo (height: 36px)
- **`Resonai_LOGO_B.png`** - Light mode header logo (height: 36px)

**Usage**: Main dashboard headers with dark/light mode switching
```html
<picture class="logo-container">
  <source media="(prefers-color-scheme: light)" srcset="LOGO/Resonai_LOGO_B.png">
  <img src="LOGO/Resonai_LOGO_A.png" alt="" height="36" decoding="async" aria-hidden="true">
</picture>
```

### Favicon & App Icons
- **`Resonai_LOGO_ICONonly.png`** - Icon-only logo for favicons and app icons

**Usage**: Browser tabs, bookmarks, mobile home screen
```html
<link rel="icon" type="image/png" sizes="32x32" href="LOGO/Resonai_LOGO_ICONonly.png?v=1">
<link rel="icon" type="image/png" sizes="192x192" href="LOGO/Resonai_LOGO_ICONonly.png?v=1">
<link rel="apple-touch-icon" href="LOGO/Resonai_LOGO_ICONonly.png?v=1">
```

### Export Wordmarks
- **`Resonai_Wordmark_shimmer_grad.png`** - Wordmark for PDF and Markdown exports

**Usage**: Document headers and export materials
```html
<p align="left">
  <img src="../LOGO/Resonai_Wordmark_shimmer_grad.png" alt="Resonai" height="28">
</p>
```

### Footer & Small Contexts
- **`Resonai_LOGO_monochrome.png`** - Monochrome version for footers and small contexts

**Usage**: Footer branding and subtle branding elements
```html
<img src="LOGO/Resonai_LOGO_monochrome.png" alt="" class="logo-mono" height="16" aria-hidden="true">
```

## Shared CSS System

For consistent branding across all dashboards, include the shared brand system:

```html
<link rel="stylesheet" href="assets/resonai-tokens.css">
```

This provides:
- **Brand tokens**: `--rsn-*` color variables
- **Logo classes**: `.logo-container`, `.logo-mono`, `.logo-wordmark`
- **Utility classes**: Brand color helpers
- **Print optimizations**: Responsive sizing and color preservation

### CSS Classes

Standardized CSS classes for consistent logo styling:

```css
.logo-container { display: flex; gap: 0.5rem; align-items: center; }
.logo-mono { height: 16px; opacity: 0.7; }
.logo-wordmark { height: 28px; }

@media print {
  .logo-container img { height: 24px !important; }
  .logo-wordmark { height: 20px; }
}
```

## Brand Tokens

For consistent branding across pages, use these CSS custom properties:

```css
:root {
  --rsn-bg: #000;            /* primary dark */
  --rsn-fg: #fff;            /* text */
  --rsn-grad-blue: #2D9CFF;
  --rsn-grad-purple: #9B51E0;
  --rsn-grad-magenta: #E040FB;
  --rsn-grad-orange: #FF6A00;
}
```

## Accessibility Guidelines

- **Header logos**: Use `alt=""` and `aria-hidden="true"` (decorative)
- **Export wordmarks**: Use `alt="Resonai"` (meaningful content)
- **Footer logos**: Use `alt=""` and `aria-hidden="true"` (decorative)
- **Ensure page `<h1>` remains the first announced element**

## File Specifications

- **Header logos**: 180x36px recommended (height: 36px in use)
- **Favicon**: 32x32px, 192x192px, 180x180px variants
- **Wordmark**: 120x28px recommended (height: 28px in use)
- **Monochrome**: 16x16px for footer use

## SVG-First Preparation

The shared CSS system includes SVG-ready classes for future vector assets:

```css
.logo-svg { width: auto; height: 36px; }
.logo-svg-mono { width: auto; height: 16px; opacity: 0.7; }
.logo-svg-wordmark { width: auto; height: 28px; }
```

When SVG versions become available:
1. Add `<source type="image/svg+xml">` to picture elements
2. Keep PNG as fallback
3. Use `.logo-svg-*` classes for vector assets

```html
<picture class="logo-container">
  <source type="image/svg+xml" srcset="LOGO/Resonai_LOGO_A.svg">
  <source media="(prefers-color-scheme: light)" srcset="LOGO/Resonai_LOGO_B.png">
  <img src="LOGO/Resonai_LOGO_A.png" alt="" class="logo-wordmark" aria-hidden="true">
</picture>
```

## Future Enhancements

For small-size contexts (≤24px), create simplified versions without inner laminar ripples to avoid shimmer artifacts:
- `Resonai_ICON_simplified-24.png`
- Use for favicons, small badges, and table stamps
