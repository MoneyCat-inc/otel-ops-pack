// BRAV/SCPT/icf/retry-on-slow-ui.ts
// ICF Heuristic 01: Bounded retry for slow UI smoke test
// Pings UI endpoint, allows one retry if slow, fails only on persistent slowness
import { setTimeout as sleep } from 'timers/promises';
const url = process.env.UI_URL; const p95 = +process.env.P95_MS! || 1500;
const retryMs = +process.env.RETRY_MS! || 5000; const toMs = +process.env.TIMEOUT_MS! || 10000;
if (!url) { console.error('UI_URL required'); process.exit(2); }
async function ping() {
  const t0 = Date.now(), c = new AbortController(), id = setTimeout(()=>c.abort(), toMs);
  try { const r = await fetch(url, { signal: c.signal }); return { ok: r.ok, ms: Date.now()-t0 }; }
  catch { return { ok: false, ms: Date.now()-t0 }; } finally { clearTimeout(id); }
}
let a = await ping(); console.log(JSON.stringify({type:'icf-smoke',url,attempt:1,ms:a.ms,ok:a.ok,p95}));
if (a.ok && a.ms <= p95) process.exit(0);
await sleep(retryMs);
let b = await ping(); console.log(JSON.stringify({type:'icf-smoke',url,attempt:2,ms:b.ms,ok:b.ok,p95}));
process.exit(b.ok && b.ms <= p95 ? 0 : 1);

