# Dashboard Template Usage Example

## 🎯 **Template Demonstration**

The `DASHBOARD_TEMPLATE.html` provides a complete starting point for new dashboard pages with integrated Resonai branding.

## 🚀 **Quick Start Example**

### **Step 1: Copy Template**
```bash
# Copy template to new dashboard location
cp docs/LOGO/DASHBOARD_TEMPLATE.html docs/my-new-dashboard.html
```

### **Step 2: Customize Content**
```html
<!-- Update title -->
<title>My New Dashboard - Resonai</title>

<!-- Update header content -->
<h1>My New Dashboard</h1>
<p>Description of this dashboard's purpose</p>

<!-- Update main content -->
<section class="content-section" aria-label="My Data">
    <h2>My Data Section</h2>
    <p>Add your dashboard content here...</p>
</section>
```

### **Step 3: Add Custom Styling**
```css
/* Add to the <style> section */
:root {
    /* Dashboard-specific theme (extends shared tokens) */
    --my-dashboard-accent: #ff6b35;
    --my-dashboard-success: #4caf50;
}

.my-custom-element {
    background: var(--my-dashboard-accent);
    color: var(--rsn-fg);
}
```

## 🎨 **Template Features**

### **Built-in Branding**
- ✅ **Shared CSS system** automatically included
- ✅ **Responsive logo** with dark/light mode switching
- ✅ **Consistent favicon** and app icons
- ✅ **Brand color variables** available throughout

### **Responsive Design**
- ✅ **Mobile-first** approach with responsive breakpoints
- ✅ **Flexible grid** system for content layout
- ✅ **Touch-friendly** interface elements
- ✅ **Print optimization** for PDF exports

### **Accessibility Features**
- ✅ **Semantic HTML** structure with proper landmarks
- ✅ **ARIA labels** for screen readers
- ✅ **Keyboard navigation** support
- ✅ **High contrast** mode compatibility

## 📊 **Content Sections**

### **Metric Cards**
```html
<div class="metric-grid">
    <div class="metric-card">
        <div class="metric-value">95%</div>
        <div class="metric-label">Success Rate</div>
    </div>
    <!-- Add more metric cards -->
</div>
```

### **Content Sections**
```html
<section class="content-section" aria-label="Data Visualization">
    <h2>Charts & Graphs</h2>
    <!-- Add your charts here -->
</section>
```

### **Brand Color Examples**
```html
<div style="display: flex; gap: 16px; flex-wrap: wrap;">
    <div style="background: var(--rsn-grad-blue); color: white; padding: 8px 16px; border-radius: 4px;">Blue</div>
    <div style="background: var(--rsn-grad-purple); color: white; padding: 8px 16px; border-radius: 4px;">Purple</div>
    <div style="background: var(--rsn-grad-magenta); color: white; padding: 8px 16px; border-radius: 4px;">Magenta</div>
    <div style="background: var(--rsn-grad-orange); color: white; padding: 8px 16px; border-radius: 4px;">Orange</div>
</div>
```

## 🔧 **Customization Examples**

### **Adding Chart.js Integration**
```html
<!-- Add to <head> -->
<script src="https://cdn.jsdelivr.net/npm/chart.js" defer></script>

<!-- Add to content section -->
<section class="content-section" aria-label="Performance Metrics">
    <h2>Performance Chart</h2>
    <canvas id="performanceChart" width="400" height="200"></canvas>
</section>

<script>
// Chart.js integration
const ctx = document.getElementById('performanceChart');
new Chart(ctx, {
    type: 'line',
    data: {
        labels: ['Jan', 'Feb', 'Mar', 'Apr'],
        datasets: [{
            label: 'Performance',
            data: [12, 19, 3, 5],
            borderColor: 'var(--rsn-grad-blue)',
            backgroundColor: 'var(--rsn-grad-blue)',
            tension: 0.1
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: {
                labels: { color: 'var(--rsn-text)' }
            }
        },
        scales: {
            y: {
                ticks: { color: 'var(--rsn-muted)' },
                grid: { color: 'var(--rsn-border)' }
            },
            x: {
                ticks: { color: 'var(--rsn-muted)' },
                grid: { display: false }
            }
        }
    }
});
</script>
```

### **Adding Data Tables**
```html
<section class="content-section" aria-label="Data Table">
    <h2>Recent Activity</h2>
    <table style="width: 100%; border-collapse: collapse;">
        <thead>
            <tr style="background: var(--rsn-grad-blue); color: var(--rsn-fg);">
                <th style="padding: 12px; text-align: left;">Timestamp</th>
                <th style="padding: 12px; text-align: left;">Event</th>
                <th style="padding: 12px; text-align: left;">Status</th>
            </tr>
        </thead>
        <tbody>
            <tr style="border-bottom: 1px solid var(--rsn-border);">
                <td style="padding: 12px;">2025-01-29 10:30</td>
                <td style="padding: 12px;">System Check</td>
                <td style="padding: 12px; color: var(--rsn-grad-blue);">✓ Success</td>
            </tr>
        </tbody>
    </table>
</section>
```

## 🎯 **Verification Checklist**

### **Before Deployment**
- [ ] **Title updated** with descriptive name
- [ ] **Content customized** for specific dashboard purpose
- [ ] **Brand colors used** via CSS variables
- [ ] **Responsive design** tested on mobile/tablet
- [ ] **Dark/light mode** switching works
- [ ] **Print preview** renders correctly
- [ ] **Accessibility** validated with screen reader

### **Code Quality**
- [ ] **No inline styles** (use CSS classes and variables)
- [ ] **Semantic HTML** structure maintained
- [ ] **ARIA labels** added for complex elements
- [ ] **JavaScript** follows best practices
- [ ] **Performance** optimized for loading speed

## 📁 **File Organization**

### **Recommended Structure**
```
docs/
├── my-dashboard.html          # New dashboard page
├── assets/
│   └── resonai-tokens.css    # Shared brand system
└── LOGO/
    └── [logo assets]         # Brand assets
```

### **Path References**
- **Shared CSS**: `href="assets/resonai-tokens.css"`
- **Logo assets**: `src="LOGO/Resonai_LOGO_A.png"`
- **Relative paths**: Adjust based on dashboard location

## 🚀 **Deployment Steps**

### **1. Test Locally**
```bash
# Open in browser
start docs/my-new-dashboard.html
```

### **2. Validate Implementation**
- Check logo display and sizing
- Test dark/light mode switching
- Verify responsive behavior
- Validate accessibility

### **3. Commit to Repository**
```bash
git add docs/my-new-dashboard.html
git commit -m "feat: add new dashboard with Resonai branding"
git push origin main
```

---

**The dashboard template provides everything needed for consistent, accessible, and branded dashboard pages. Simply copy, customize, and deploy!**
