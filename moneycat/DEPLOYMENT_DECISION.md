# MoneyCat Deployment Decision

**Decision:** Keep Hub on the root domain and deploy MoneyCat to `/moneycat`.

## Why This Path
- Both sites stay live with zero domain swap
- Root `CNAME` remains `hub.resonai.uk`
- Fastest to ship; optional redirect for `moneycat.resonai.uk`

## What Was Implemented
1) `moneycat/CNAME` removed (no standalone domain)  
2) Pages workflow updated to publish:
   - Hub at root (with `CNAME`)
   - MoneyCat at `/moneycat`
3) MoneyCat links and verification aligned to the subdirectory path

## Optional Redirect
- DNS CNAME: `moneycat -> hub.resonai.uk`
- Add a redirect rule to `https://hub.resonai.uk/moneycat/` (e.g., Cloudflare page rule)

## If a Dedicated Domain Is Needed Later
- Create a separate repo for MoneyCat
- Enable Pages with `moneycat.resonai.uk`
- Set DNS `moneycat -> <org>.github.io`
