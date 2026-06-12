# MoneyCat Website - Final Deployment Plan

**Decision:** Deploy MoneyCat as a subdirectory to preserve `hub.resonai.uk`

- Hub: `https://hub.resonai.uk/` (root, unchanged)
- MoneyCat: `https://hub.resonai.uk/moneycat/`
- Optional redirect: `moneycat.resonai.uk -> hub.resonai.uk/moneycat/`

---

## Status
- `moneycat/CNAME` removed (no conflicting domain)
- GitHub Pages workflow publishes Hub + MoneyCat together
- File paths remain relative; work from `/moneycat`

---

## Deployment Steps

1) **Enable Pages**
   - Repo **Settings > Pages** → **Source: GitHub Actions**

2) **Deploy**
   - Push changes to `moneycat/`, or run **Deploy MoneyCat Website** in Actions
   - Workflow stages:
     - Copies Hub root assets + `CNAME` to deploy root
     - Copies MoneyCat to `/moneycat`
     - Publishes via GitHub Pages

3) **Verify**
   ```powershell
   pwsh moneycat/verify-deployment.ps1
   ```
   - Checks HTTP/HTTPS, main pages, assets
   - Pass `-CustomDomain moneycat.resonai.uk` if you add a redirect CNAME

4) **Optional redirect**
   - DNS CNAME: `moneycat -> hub.resonai.uk`
   - Add a redirect rule to `https://hub.resonai.uk/moneycat/` (e.g., Cloudflare)

---

## URLs
- Hub: `https://hub.resonai.uk/`
- MoneyCat: `https://hub.resonai.uk/moneycat/`
- About: `https://hub.resonai.uk/moneycat/about.html`
- Services: `https://hub.resonai.uk/moneycat/services.html`
- Contact: `https://hub.resonai.uk/moneycat/contact.html`
- Optional redirect: `https://moneycat.resonai.uk` (if CNAME + redirect rule configured)

---

## Verification Checklist
- [ ] Workflow succeeded
- [ ] MoneyCat loads at `/moneycat/`
- [ ] Navigation links work
- [ ] CSS/JS load without errors
- [ ] Hub still loads at root
- [ ] (Optional) Custom domain redirect works

---

## Future: Dedicated Domain
- Create a separate repo for MoneyCat
- Enable Pages with `moneycat.resonai.uk`
- Set DNS `moneycat -> <org>.github.io`
- Deploy MoneyCat as the root of that repo
