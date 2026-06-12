# MoneyCat Website - Quick Start

**URL:** `https://hub.resonai.uk/moneycat/`  
**Status:** Ready for deployment (subdirectory of Hub)

---

## 🚀 Deploy in 4 Steps

1) **Enable GitHub Pages**  
   - Repository **Settings > Pages** → **Source: GitHub Actions**

2) **Deploy**  
   - Push changes to `moneycat/` on `main`, or  
   - Manually run **Deploy MoneyCat Website** workflow

3) **Verify**  
   ```powershell
   pwsh moneycat/verify-deployment.ps1
   ```
   (defaults to `https://hub.resonai.uk/moneycat/`)

4) **Optional redirect**  
   - DNS CNAME: `moneycat -> hub.resonai.uk`  
   - Add a redirect rule to `https://hub.resonai.uk/moneycat/` if your DNS/CDN supports it.

---

## ✅ What’s Already Set

- Workflow builds one Pages artifact: Hub at root + MoneyCat at `/moneycat`
- Root `CNAME` (`hub.resonai.uk`) preserved
- `.nojekyll` included

---

## 📂 File Structure (MoneyCat)

```
moneycat/
├── index.html
├── about.html
├── services.html
├── contact.html
├── styles.css
├── script.js
└── verify-deployment.ps1
```

---

## 🔍 Quick Checks

- [ ] `https://hub.resonai.uk/moneycat/` loads
- [ ] Navigation works (Home, About, Services, Contact)
- [ ] CSS/JS load (no console errors)
- [ ] Hub still works at `https://hub.resonai.uk/`

---

## 🔧 Troubleshooting

- Workflow failed? Check Actions logs.  
- Seeing 404s? Confirm Pages source is **GitHub Actions** and deployment succeeded.  
- Redirect not working? Verify CNAME + redirect rule.  
