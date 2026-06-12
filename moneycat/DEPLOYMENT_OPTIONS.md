# MoneyCat Deployment Options

**Constraint:** One custom domain per GitHub Pages site (per repo).

**Current:**  
- Hub live at `hub.resonai.uk` → `moneycat-inc.github.io` (via root `CNAME`)  
- MoneyCat deployed to subdirectory `/moneycat` (no CNAME)

---

## Option 1: Subdirectory (Chosen)
- **What:** Keep Hub at root; serve MoneyCat at `/moneycat`
- **URL:** `https://hub.resonai.uk/moneycat/`
- **Pros:** Both sites stay live, no domain swap, fastest
- **Cons:** MoneyCat not at root domain
- **Optional:** DNS CNAME `moneycat -> hub.resonai.uk` + redirect rule

---

## Option 2: Move Hub, Give MoneyCat the Domain
- **What:** Point the repo’s custom domain to MoneyCat instead of Hub
- **Pros:** MoneyCat gets `moneycat.resonai.uk` as root
- **Cons:** Hub loses `hub.resonai.uk` unless moved/redirected
- **Steps:** Replace root `CNAME` with `moneycat.resonai.uk`, deploy MoneyCat at root, move Hub to subdir or another repo

---

## Option 3: Separate Repository (Best for Dedicated Domain)
- **What:** New repo just for MoneyCat
- **Pros:** Clean separation, independent CI/CD, dedicated `moneycat.resonai.uk`
- **Cons:** Requires new repo and pipeline
- **Steps:** Create `moneycat-website` repo, move files to root, enable Pages, set custom domain `moneycat.resonai.uk`, set DNS `moneycat -> <org>.github.io`

---

## Option 4: Reverse Proxy / CDN Routing
- **What:** Use Cloudflare/Netlify/Vercel to route domains to different paths
- **Pros:** Both domains can coexist independently
- **Cons:** More infra/complexity, potential cost
- **Steps:** Configure CDN routes: `hub.resonai.uk -> /` (Hub), `moneycat.resonai.uk -> /moneycat` (MoneyCat)

---

## Recommendation

- **Quick win (current):** Option 1 (subdirectory)  
- **Dedicated domain later:** Option 3 (separate repo)  
