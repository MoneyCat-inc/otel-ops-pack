# ECRR Report – COOP/COEP Hard Gate

## Examine
- Baseline preview UI loaded Tailwind CDN without isolation headers, blocking SharedArrayBuffer/WebGPU.
- No automated CI proof that HTML or worker responses enforced COOP/COEP.

## Clean
- Replaced CDN dependencies with local Vite bundle (`preview/src`) and registered a minimal worker endpoint.
- Hardened Vite dev/preview servers with COOP/COEP/CORP + CSP headers at port 3003.
- Added Playwright security regression covering `/` and `/workers/pipeline.js` for required headers + CSP.

## Report
- ✅ `npm run test:smoke` – boots Vite (port 3003) and verifies COOP/COEP, CSP and `window.crossOriginIsolated === true`.
- ✅ Worker handshake (`postMessage ping/pong`) succeeds under isolation headers.

## Role
- **Codex Agent**
