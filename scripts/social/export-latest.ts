// Suggest-only exporter: pulls latest posts (online if creds; else ledger) to JSON.
// ECRR: logs plan/preflight/report/exit; respects kill-switch.
// Usage: tsx scripts/social/export-latest.ts --count 5 --out docs/widgets/bluesky-latest.json
import { promises as fs } from 'fs';
import path from 'path';
import { BskyAgent } from '@atproto/api';

type Evidence = {
  t:string; who:'A'|'B'; type:string; lane:'SOCM';
  msg:string; files_touched?:number; loc_delta?:number;
};
const now = () => new Date().toISOString();
const log = async (e: Evidence) =>
  fs.appendFile('.agent/EVIDENCE.log', JSON.stringify(e) + '\n').catch(() => {});

const arg = (k:string, d?:string) => {
  const i = process.argv.indexOf(`--${k}`); return i> -1 ? process.argv[i+1] : d;
};

const OUT = arg('out','artifacts/social/latest.json')!;
const COUNT = parseInt(arg('count','5')!,10) || 5;

async function exists(p:string){ try{ await fs.stat(p); return true; }catch{ return false; } }
function hashtags(text:string): string[] {
  const set = new Set<string>(); for (const m of text.matchAll(/#([A-Za-z][\w-]{0,48})/g)) set.add(m[1]); return [...set];
}
function postUrl(handle:string, uri:string){
  const id = uri.split('/').pop() ?? '';
  return `https://bsky.app/profile/${handle}/post/${id}`;
}

async function fromLedger(handleFallback='resonai.bsky.social'){
  const p = 'artifacts/social/posted.jsonl';
  if (!(await exists(p))) return [];
  const lines = (await fs.readFile(p,'utf8')).trim().split('\n').slice(-COUNT).reverse();
  return lines.map(l => {
    const x = JSON.parse(l);
    const text = x.text ?? '';
    const handle = x.handle ?? handleFallback;
    return {
      text, createdAt: x.postedAt ?? now(), uri: x.bskyUri ?? '',
      url: x.bskyUri ? postUrl(handle, x.bskyUri) : '',
      hashtags: hashtags(text), links: (text.match(/\bhttps?:\/\/\S+/g)||[])
    };
  });
}

async function fromBsky(handle:string, pass:string){
  const agent = new BskyAgent({ service: 'https://bsky.social' });
  await agent.login({ identifier: handle, password: pass });
  const res = await agent.getAuthorFeed({ actor: handle, limit: COUNT });
  return res.data.feed
    .filter(f => (f.post?.record as any)?.$type === 'app.bsky.feed.post')
    .map(f => {
      const rec:any = f.post.record;
      const text = rec.text ?? '';
      return {
        text,
        createdAt: rec.createdAt ?? now(),
        uri: f.post.uri,
        url: postUrl(f.post.author?.handle ?? handle, f.post.uri),
        hashtags: hashtags(text),
        links: (rec.facets||[])
          .flatMap((fa:any) => (fa.features||[])
          .filter((ft:any)=>ft.$type==='app.bsky.richtext.facet#link').map((ft:any)=>ft.uri))
      };
    });
}

(async () => {
  if (await exists('.agent/LOCK')) {
    await log({t:now(), who:'A', type:'report', lane:'SOCM', msg:'paused:kill-switch'});
    process.exit(50);
  }
  await log({t:now(), who:'A', type:'plan', lane:'SOCM', msg:`export latest posts -> ${OUT}`});

  let posts:any[] = [];
  const H = process.env.BSKY_HANDLE, P = process.env.BSKY_APP_PASSWORD;
  try {
    if (H && P) posts = await fromBsky(H, P);
    else posts = await fromLedger();
  } catch (e:any) {
    posts = await fromLedger();
    await log({t:now(), who:'A', type:'report', lane:'SOCM', msg:`fallback ledger: ${e?.message||'error'}`});
  }

  await fs.mkdir(path.dirname(OUT), { recursive: true });
  await fs.writeFile(OUT, JSON.stringify({ generatedAt: now(), count: posts.length, posts }, null, 2));
  await log({t:now(), who:'A', type:'exit', lane:'SOCM', msg:`exported ${posts.length} posts`});
})();

