# MoneyCat Website Deployment Guide

**Primary URL:** `https://hub.resonai.uk/moneycat/`  
**Authority:** BossCat OEM  
**Status:** Ready for deployment

---

## Deployment Overview

MoneyCat ships as a subdirectory of the Hub site so both stay online:
- Hub remains at `https://hub.resonai.uk/`
- MoneyCat lives at `https://hub.resonai.uk/moneycat/`

---

## Prerequisites

1. GitHub Pages enabled for the repository  
2. GitHub Actions permissions for Pages + id-token  
3. Root `CNAME` set to `hub.resonai.uk` (keeps Hub domain)

---

## Step 1: Enable GitHub Pages

1. Go to **Settings > Pages** in the repository  
2. Set **Source** to **GitHub Actions**

The workflow `.github/workflows/deploy-moneycat.yml` builds one artifact that includes:
- Hub root content (index, portal, docs, assets, CHAR, etc.)
- MoneyCat under `/moneycat`
- Root `CNAME` for `hub.resonai.uk`

---

## Step 2: Deploy

Automatic triggers:
- Push changes to `main` that touch `moneycat/`, or
- Manually run **Deploy MoneyCat Website** in Actions

What the workflow does:
1. Copies Hub assets to the deployment root  
2. Adds MoneyCat to `/moneycat` (no separate CNAME)  
3. Preserves root `CNAME` and `.nojekyll`  
4. Publishes via GitHub Pages

---

## Step 3: Verify

Run the verification script (defaults to the subdirectory URL):
```powershell
pwsh moneycat/verify-deployment.ps1
```

Checks performed:
- Optional custom-domain DNS (if you pass `-CustomDomain`)
- HTTP/HTTPS reachability
- Main pages (home, about, services, contact)
- Assets (CSS/JS)

---

## Optional: DNS Redirect for moneycat.resonai.uk

If you want `moneycat.resonai.uk` to redirect to the subdirectory:
```
Type: CNAME
Name: moneycat
Value: hub.resonai.uk
```
Then add a DNS/CDN page rule (e.g., Cloudflare) to forward to `https://hub.resonai.uk/moneycat/`.

---

## File Structure (MoneyCat)

```
moneycat/
├── index.html
├── about.html
├── services.html
├── contact.html
├── styles.css
├── script.js
├── README.md
├── DEPLOYMENT.md
├── FINAL_DEPLOYMENT_PLAN.md
└── verify-deployment.ps1
```

---

## Troubleshooting

- **Pages 404:** Ensure Pages source is **GitHub Actions** and the workflow succeeded.  
- **Hub missing:** Confirm the workflow copied hub root assets and `CNAME` (see run logs).  
- **Assets not loading:** CSS/JS must be reachable under `/moneycat`; verify relative paths.  
- **DNS redirect issues:** Check `moneycat -> hub.resonai.uk` CNAME and any CDN redirect rules.  

---

## Monitoring

- Monitor the **Deploy MoneyCat Website** workflow in Actions.  
- Run `moneycat/verify-deployment.ps1` after each deploy.  
