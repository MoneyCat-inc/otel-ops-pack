# Open Graph Preview Image

**Required:** `og-default.png` (1200×630 pixels)

## Quick Creation

### Option A: SVG to PNG (ImageMagick)
```bash
magick og/og-default.svg -resize 1200x630 og/og-default.png
```

### Option B: Canva/Figma
1. Create 1200×630 canvas
2. Dark background (#0b0d12)
3. Add text: "BossCat Hub"
4. Tagline: "Stay Human. Kill the Clickbait."
5. Logo/icon if available
6. Export as PNG

### Option C: Simple SVG Template
Create `og-default.svg` then export:

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630">
  <rect width="1200" height="630" fill="#0b0d12"/>
  <text x="600" y="280" font-family="system-ui" font-size="72" font-weight="700" 
        fill="#e9edf7" text-anchor="middle">🐾 BossCat Hub</text>
  <text x="600" y="350" font-family="system-ui" font-size="36" 
        fill="#b4bac9" text-anchor="middle">Stay Human. Kill the Clickbait.</text>
  <text x="600" y="420" font-family="system-ui" font-size="24" 
        fill="#7c5cff" text-anchor="middle">hub.resonai.uk</text>
</svg>
```

---

**Once created, reference in index.html:**
```html
<meta property="og:image" content="/og/og-default.png">
```

