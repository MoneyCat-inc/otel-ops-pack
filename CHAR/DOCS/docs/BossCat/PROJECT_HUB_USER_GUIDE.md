# Resonai Project Hub - User Guide

**Version**: 1.0  
**Date**: 2025-10-07  
**BossCat OEM Certified**

---

## 🎯 Overview

The Resonai Project Hub (`index.html`) is your **central navigation system** for all active Resonai projects, dashboards, and documentation. Think of it as mission control for your observability and voice training operations.

---

## 🚀 Quick Start

### **Opening the Hub**

**Option A: File Protocol (Recommended for local dev)**
```bash
# Windows
start index.html

# Or navigate to
file:///C:/otel/index.html
```

**Option B: HTTP Server (For team sharing)**
```bash
# Python
python -m http.server 8000

# Or Node.js
npx http-server

# Then open
http://localhost:8000
```

---

## 📊 Dashboard Guide

### **1. OTel Observability Pipeline** (Production ✅)

The complete Windows → OTel Collector → SigNoz observability stack.

#### **Available Dashboards**

| Dashboard | Purpose | Update Frequency | Link |
|-----------|---------|------------------|------|
| **Status Dashboard** | Live KPIs, roadmap heatmap, ECRR compliance | Real-time (30s) | `docs/status.html` |
| **Cat Nap Control Room (Mockup)** | Enhanced UX mockup with placeholders | Static | `docs/BossCat/signoz_dashboard_mockup_v2.html` |
| **Cat Nap Control Room (Live)** | Real-time SigNoz data integration | Live (30s auto-refresh) | `docs/BossCat/signoz_dashboard_live.html` |
| **System Architecture** | Interactive 77× uplift diagram | Static | `docs/BossCat/SYSTEM_ARCHITECTURE_DIAGRAM.html` |
| **SigNoz UI** | Official SigNoz interface | Real-time | `http://localhost:8080` |

#### **Key Metrics**

- **Throughput**: 196.7 logs/sec (77× from baseline)
- **Latency**: <200ms batch processing
- **Success Rate**: 99.97%
- **Queue Depth**: 0% (optimal headroom)
- **Noise Reduction**: ~50%
- **GPU Utilization**: 16-23% (RTX 2080 Super)

---

### **2. Resonai Voice Training** (Beta 🔵)

Local-first voice training application with instant practice, prosody coaching, and accessibility support.

#### **Available Resources**

| Resource | Purpose | Link |
|----------|---------|------|
| **Launch Application** | Start the voice training app | `resonai-mock/index.html` |
| **Beta Checklist** | Preflight validation steps | `docs/BETA_LAUNCH_CHECKLIST.md` |
| **Tester Guide** | Onboarding for beta cohort | `docs/cohort-onboarding.md` |
| **Rollback Procedures** | Emergency rollback playbook | `docs/rollback-procedures.md` |

#### **Cohort Features**

- **C1**: Progress Dashboard (local-first trends)
- **C2**: Export & Delete UX (data sovereignty)
- **C3**: QA Release Runbook (deterministic gates)
- **C4**: Cohort Analytics Toggles (controlled rollout)
- **C5**: Cohort Log & Tester Guide
- **C6**: Beta Success Metrics
- **C7**: Dashboard Polish & UX
- **C8**: Beta Launch Checklist

---

### **3. BossCat Operations** (Active ✅)

Executive oversight and governance framework with ECRR compliance and automated monitoring.

#### **Key Components**

| Component | Purpose | Link |
|-----------|---------|------|
| **BossCat Guide** | Main operations manual | `docs/BossCat/README.md` |
| **Agent Framework** | ECRR agent coordination | `docs/AGENTS.md` |
| **Security Guide** | Vulnerability management | `docs/BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md` |
| **IONA Error Ledger** | Anomaly tracking | `docs/IONA_ERRORS.md` |

#### **Health Metrics**

- **ECRR Compliance**: 100%
- **Health Score**: 98/100
- **Drift Detection**: 0 configs
- **Active Anomalies**: 0

---

## ⚡ Quick Links Reference

### **Documentation** (4 links)
- Main README
- Runbook Index
- ECRR Project Report
- Quick Reference

### **Operations** (4 links)
- Quick Start Card
- Troubleshooting Guide
- Monitoring Setup
- Deployment Checklist

### **Design System** (4 links)
- Comfort Cat Guidelines
- Design Tokens (CSS)
- Creative Handoff
- Brand Assets (logos)

### **Testing & QA** (4 links)
- QA Checklist
- Tetragrammaton Guide (cross-language testing)
- Smoke Test Results
- Playwright Reports

### **Security** (4 links)
- Security Policy
- Rotation Calendar (credentials)
- Dependabot Guide
- Remediation Plan

### **Reports** (4 links)
- ECRR Report
- Evidence Package (stakeholder)
- CI Pipeline Status
- Artifacts Directory

---

## 🔌 Live Data Integration

### **Setting Up Live Dashboard**

1. **Open Live Dashboard**
   ```bash
   start docs/BossCat/signoz_dashboard_live.html
   ```

2. **Get SigNoz API Token** (optional for localhost)
   - Open http://localhost:8080
   - Navigate to **Settings → Ingestion Settings**
   - Click **Generate Token**
   - Copy the token

3. **Configure Dashboard**
   - Paste token in the "SigNoz API Token" field
   - Verify endpoint: `http://localhost:8080`
   - Click **"💾 Save & Connect"**

4. **Verify Data Flow**
   - Click **"🔄 Refresh Now"**
   - Check "Connection Status" shows **"Live"**
   - Logs should appear in the table
   - Charts should update with real data

### **Troubleshooting Live Dashboard**

| Issue | Solution |
|-------|----------|
| "Connection Status: Error" | Verify SigNoz is running: `docker ps` |
| "No logs found" | Generate canary: `pwsh -File scripts/canary-test.ps1` |
| CORS errors | API calls from file:// should work locally; use http-server if needed |
| Charts not updating | Check browser console for errors |

---

## 🎨 Customization

### **Adding New Projects**

Edit `index.html` and add a new project card:

```html
<div class="project-card observability">
  <span class="project-icon">🆕</span>
  <h3 class="project-title">New Project Name</h3>
  <div style="margin-bottom: 12px;">
    <span class="status-indicator live">
      <span class="status-dot"></span>
      Production
    </span>
  </div>
  <p class="project-description">
    Your project description here...
  </p>
  <div class="project-stats">
    <div class="stat">
      <span class="stat-label">Metric 1</span>
      <span class="stat-value ok">Value</span>
    </div>
  </div>
  <div class="project-links">
    <a href="path/to/resource" class="link-btn">
      <span>📊 Dashboard</span>
      <span class="icon">→</span>
    </a>
  </div>
</div>
```

### **Adding Quick Links**

Add a new quick link card in the "Quick Links" section:

```html
<div class="quick-link-card">
  <div class="quick-link-title">🆕 New Category</div>
  <ul class="quick-link-list">
    <li><a href="path/to/doc">→ Link Name</a></li>
  </ul>
</div>
```

---

## 📈 Monitoring Best Practices

### **Daily Routine**

1. **Morning**
   - Open project hub (`index.html`)
   - Check **Status Dashboard** for overnight issues
   - Review **IONA Error Ledger** for anomalies
   - Verify **Live Dashboard** shows green status

2. **Mid-Day**
   - Review **SigNoz UI** for trends
   - Check **CI Pipeline Status** for build health
   - Monitor **Beta Metrics** (if applicable)

3. **Evening**
   - Export **Status Dashboard** to PDF
   - Review **ECRR Compliance** score
   - Plan next-day actions based on alerts

### **Weekly Routine**

1. **Monday**
   - Review **Roadmap Heatmap**
   - Check **Security Remediation Plan**
   - Update **Stakeholder Evidence Package**

2. **Wednesday**
   - Review **Test Results** (Playwright reports)
   - Check **Dependabot** alerts
   - Rotate credentials (if scheduled)

3. **Friday**
   - Generate **Weekly ECRR Report**
   - Archive **Artifacts** directory
   - Update **Quick Reference Card**

---

## 🔒 Security Notes

### **Sensitive Data**

- **API Tokens**: Stored in localStorage (browser-specific)
- **Credentials**: Never commit to Git
- **Endpoints**: Localhost only by default

### **Access Control**

- **Project Hub**: Public (no authentication)
- **SigNoz UI**: Configurable (http://localhost:8080)
- **Live Dashboard**: Uses SigNoz token (optional)

### **Best Practices**

1. Clear localStorage when finished: `localStorage.clear()`
2. Use environment variables for tokens in scripts
3. Review `.gitignore` to exclude sensitive files
4. Rotate tokens monthly (see Rotation Calendar)

---

## 🐛 Troubleshooting

### **Common Issues**

#### **"Links don't work"**
- **Cause**: Relative paths in file:// mode
- **Solution**: Ensure you're in `C:\otel\` directory when opening

#### **"Dashboard shows old data"**
- **Cause**: Browser cache
- **Solution**: Hard refresh (Ctrl+Shift+R)

#### **"Charts not rendering"**
- **Cause**: Chart.js CDN not loaded
- **Solution**: Check internet connection or use local Chart.js

#### **"SigNoz API fails"**
- **Cause**: SigNoz not running
- **Solution**: `docker-compose up -d`

---

## 📚 Additional Resources

- **Full Documentation**: [README.md](../../README.md)
- **Architecture Diagram**: [SYSTEM_ARCHITECTURE_DIAGRAM.md](SYSTEM_ARCHITECTURE_DIAGRAM.md)
- **Dashboard Comparison**: [DASHBOARD_COMPARISON.md](DASHBOARD_COMPARISON.md)
- **ECRR Framework**: [../../AGENTS.md](../../AGENTS.md)
- **Comfort Cat Guidelines**: [../comfort-cat/README.md](../comfort-cat/README.md)

---

## 🆘 Getting Help

### **Internal Resources**

1. **BossCat Operations**: See `docs/BossCat/README.md`
2. **IONA Error Ledger**: Check `docs/IONA_ERRORS.md` for known issues
3. **Troubleshooting Guide**: `docs/TROUBLESHOOTING.md`

### **External Resources**

- **SigNoz Docs**: https://signoz.io/docs/
- **OpenTelemetry**: https://opentelemetry.io/
- **Chart.js**: https://www.chartjs.org/

---

## 🎓 Training Materials

### **New Team Members**

1. Read this user guide
2. Review [Quick Start Card](QUICK_START_CARD.md)
3. Complete [Onboarding Checklist](../cohort-onboarding.md)
4. Watch [Demo Flow Videos](../demos/) (if available)

### **Advanced Users**

1. Study [System Architecture Diagram](SYSTEM_ARCHITECTURE_DIAGRAM.md)
2. Review [ECRR Framework](../../AGENTS.md)
3. Learn [Security Maintenance](SECURITY_MAINTENANCE_MASTER_GUIDE.md)
4. Practice [Nightly Operations](guides/NIGHTLY_DASHBOARD_INTEGRATION.md)

---

**🐾 BossCat OEM Certified User Guide**  
*Last updated: 2025-10-07*

