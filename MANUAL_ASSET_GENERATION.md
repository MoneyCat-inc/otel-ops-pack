# Manual Asset Generation Guide - ECRR v1.0.0

**Status**: Automated generation failed, manual process required  
**Purpose**: Generate PNG assets from HTML templates for social media launch

---

## 🎯 **Required Assets**

### **Social Media Banners**
- **Twitter/X**: `twitter-draft.html` → `twitter-draft.png` (1200x675px)
- **LinkedIn**: `linkedin-draft.html` → `linkedin-draft.png` (1200x627px)
- **Instagram Story**: `instagram-story-draft.html` → `instagram-story-draft.png` (1080x1920px)
- **Bluesky**: `bluesky-draft.html` → `bluesky-draft.png` (1200x630px)

### **Video Assets**
- **YouTube Thumbnail**: `youtube-thumbnail-draft.html` → `youtube-thumbnail-draft.png` (1280x720px)

### **Email Assets**
- **Email Header**: `email-header-draft.html` → `email-header-draft.png` (600x200px)
- **Email Banner**: `email-banner-draft.html` → `email-banner-draft.png` (600x300px)

---

## 🔧 **Manual Generation Steps**

### **Method 1: Browser Screenshot**

1. **Open HTML file** in Chrome/Firefox
2. **Set viewport size**:
   - Right-click → Inspect → Device Toolbar
   - Set custom dimensions to required size
3. **Take screenshot**:
   - Chrome: Right-click → "Capture screenshot"
   - Firefox: Right-click → "Take a Screenshot"
4. **Save as PNG** with platform-specific naming

### **Method 2: Browser Developer Tools**

1. **Open HTML file** in browser
2. **Open DevTools** (F12)
3. **Set viewport** in responsive design mode
4. **Use browser screenshot** or **Print to PDF** then convert

### **Method 3: Online Tools**

1. **HTML to Image converters**:
   - htmlcsstoimage.com
   - html2canvas.hertzen.com
   - screenshotapi.net
2. **Upload HTML file** and specify dimensions
3. **Download PNG** result

---

## 📐 **Exact Dimensions**

| Platform | File | Dimensions | Aspect Ratio |
|----------|------|------------|--------------|
| Twitter/X | `twitter-draft.html` | 1200x675px | 16:9 |
| LinkedIn | `linkedin-draft.html` | 1200x627px | 1.91:1 |
| Instagram | `instagram-story-draft.html` | 1080x1920px | 9:16 |
| Bluesky | `bluesky-draft.html` | 1200x630px | 1.91:1 |
| YouTube | `youtube-thumbnail-draft.html` | 1280x720px | 16:9 |
| Email Header | `email-header-draft.html` | 600x200px | 3:1 |
| Email Banner | `email-banner-draft.html` | 600x300px | 2:1 |

---

## 🎨 **Quality Checklist**

### **Visual Quality**
- [ ] **High resolution**: Sharp text and graphics
- [ ] **Color accuracy**: Brand colors match specifications
- [ ] **Typography**: Inter font renders correctly
- [ ] **Animations**: Static version captures key elements

### **Platform Optimization**
- [ ] **File size**: Under 5MB for social platforms
- [ ] **Compression**: Use TinyPNG for optimization
- [ ] **Format**: PNG for transparency, JPG for photos
- [ ] **Naming**: Use platform-specific naming convention

### **Accessibility**
- [ ] **Color contrast**: 4.5:1+ for normal text
- [ ] **Text legibility**: Clear and readable at platform size
- [ ] **Alt text**: Write descriptive alt text for each image
- [ ] **Focus areas**: Key elements visible in safe zones

---

## 📁 **File Organization**

### **Generated Assets Structure**
```
visual-assets-draft/
├── output/
│   ├── social-media/
│   │   ├── twitter-draft.png
│   │   ├── linkedin-draft.png
│   │   ├── instagram-story-draft.png
│   │   └── bluesky-draft.png
│   ├── video/
│   │   └── youtube-thumbnail-draft.png
│   ├── email/
│   │   ├── email-header-draft.png
│   │   └── email-banner-draft.png
│   └── icons/
│       ├── icon-privacy-draft.png
│       ├── icon-accessibility-draft.png
│       ├── icon-performance-draft.png
│       └── icon-affirming-draft.png
└── MANUAL_ASSET_GENERATION.md
```

---

## 🚀 **Quick Start Commands**

### **Create Output Directory**
```bash
mkdir -p output/social-media output/video output/email output/icons
```

### **Open All HTML Files**
```bash
# Windows
start social-media/twitter-draft.html
start social-media/linkedin-draft.html
start social-media/instagram-story-draft.html
start social-media/bluesky-draft.html
start video/youtube-thumbnail-draft.html
start email/email-header-draft.html
start email/email-banner-draft.html

# macOS
open social-media/twitter-draft.html
open social-media/linkedin-draft.html
open social-media/instagram-story-draft.html
open social-media/bluesky-draft.html
open video/youtube-thumbnail-draft.html
open email/email-header-draft.html
open email/email-banner-draft.html
```

---

## ⚡ **Alternative: Use Existing Assets**

If manual generation is time-consuming, you can:

1. **Use the HTML files directly** in social media posts (some platforms support HTML)
2. **Create simple text-based posts** with the prepared copy
3. **Use platform templates** and add the prepared text
4. **Generate basic graphics** using Canva or similar tools

---

**Status**: Manual generation guide ready - assets can be created in 15-30 minutes! 🎨
