# MoneyCat Inc - Company Website

**Authority:** BossCat OEM  
**Created:** 2025-12-20  
**Status:** Complete

---

## Overview

Professional company website for MoneyCat Inc, following the Cat Nap Control Room aesthetic guide. The website showcases MoneyCat's observability solutions, services, and company information.

---

## Files Created

### Pages
- **`index.html`** - Homepage with hero section, features, stats, and CTA
- **`about.html`** - About page with mission, values, approach, and technology stack
- **`services.html`** - Services page with detailed service offerings and process
- **`contact.html`** - Contact page with form and company information

### Assets
- **`styles.css`** - Complete stylesheet following Cat Nap Control Room aesthetic
- **`script.js`** - JavaScript for navigation, form handling, and interactivity
- **`README.md`** - This documentation file

---

## Design Principles

The website follows the **Cat Nap Control Room** philosophy:

### 1. **Calm**
- Serene dark theme with soft glows
- Minimalist design with reduced visual clutter
- Soothing transitions and gentle animations

### 2. **Efficient**
- Fast loading with optimized CSS
- Clear navigation (max 2 clicks to any page)
- Instant clarity with color-coded elements

### 3. **Playful**
- Cat-themed elements (🐾 paw prints, cat emoji)
- Friendly personality without being unprofessional
- Subtle hover animations and interactions

### 4. **Professional**
- WCAG 2.1 AA compliant
- Enterprise-ready design
- Evidence-based messaging

---

## Features

### Accessibility
- ✅ Semantic HTML5 structure
- ✅ ARIA labels and roles
- ✅ Keyboard navigation support
- ✅ Visible focus indicators
- ✅ Respects `prefers-reduced-motion`
- ✅ Color contrast meets WCAG 2.1 AA standards

### Responsive Design
- ✅ Mobile-first approach
- ✅ Breakpoints: 480px, 768px, 1024px, 1280px
- ✅ Touch-friendly targets (min 44px × 44px)
- ✅ Flexible grid layouts

### Performance
- ✅ Minimal JavaScript (vanilla JS, no dependencies)
- ✅ Optimized CSS (single file, no external dependencies)
- ✅ Fast page loads
- ✅ Smooth animations (respects motion preferences)

---

## Color Palette

Following the Cat Nap Control Room aesthetic:

### Status Colors
- **Green:** `#2ecc71` - Success, operational
- **Yellow:** `#f39c12` - Warning, attention needed
- **Red:** `#e74c3c` - Critical, action required
- **Blue:** `#3498db` - Informational

### UI Colors
- **Dark Background:** `#1a1a1a` (primary)
- **Dark Elevated:** `#2a2a2a` (cards, sections)
- **Text Dark:** `#e0e0e0` (primary text)
- **Text Muted:** `#a0a0a0` (secondary text)
- **Accent Cat:** `#9b59b6` (purple for cat theme)
- **Accent Primary:** `#7c5cff` (primary actions)

---

## Usage

### Local Development
1. Open `index.html` in a web browser
2. Navigate between pages using the navigation menu
3. Test responsive design by resizing the browser window

### Deployment
**Current Setup:** Deployed to subdirectory at `hub.resonai.uk/moneycat/`

**To Deploy:**
- Push changes to `moneycat/` directory
- GitHub Actions will automatically deploy
- Access at: `https://hub.resonai.uk/moneycat/`

See `FINAL_DEPLOYMENT_PLAN.md` for complete deployment details.

### Deployment
1. Upload all files to your web server
2. Ensure `index.html` is set as the default page
3. Verify all relative paths work correctly
4. Test on multiple devices and browsers

### Customization
- Update company information in each HTML file
- Modify colors in `styles.css` (CSS variables)
- Adjust content in HTML files as needed
- Add additional pages following the same structure

---

## Browser Support

- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

---

## Content Security Policy

The website includes a strict CSP header:
```
default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self'; connect-src 'self'
```

This ensures:
- No external scripts (except same-origin)
- No inline scripts (except same-origin)
- Images from same origin or data URIs only
- Styles from same origin only

---

## Contact Form

The contact form currently shows a success message on submission. To make it functional:

1. **Backend Integration:** Connect to a server-side handler
2. **Email Service:** Use a service like SendGrid, Mailgun, or AWS SES
3. **Form Validation:** Enhanced client-side validation (already includes basic validation)

Example backend integration:
```javascript
// In script.js, replace the form handler with:
fetch('/api/contact', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(data)
})
```

---

## Future Enhancements

Potential additions:
- [ ] Blog section
- [ ] Case studies page
- [ ] Team page
- [ ] Resources/downloads section
- [ ] Live chat integration
- [ ] Analytics integration
- [ ] SEO optimization
- [ ] Multi-language support

---

## References

- **Canonical Creative Reference:** `C:\otel\docs\comfort cat`
- **Aesthetic Guide:** `docs/comfort-cat/AESTHETIC_GUIDE.md`
- **BossCat Framework:** `docs/BossCat/README.md`

---

## Maintenance

### Updating Content
1. Edit HTML files directly
2. Follow semantic HTML structure
3. Maintain accessibility attributes
4. Test changes in multiple browsers

### Updating Styles
1. Modify CSS variables in `:root` for global changes
2. Follow the 8px grid system for spacing
3. Maintain color contrast ratios
4. Test responsive breakpoints

### Adding Pages
1. Copy structure from existing pages
2. Update navigation links
3. Follow the same CSS class naming
4. Test accessibility and responsiveness

---

## License

© 2025 MoneyCat Inc · Resonai [OTel] · All rights reserved

---

🐾 **Cat Nap Control Room - Calm, Efficient, Professional**
