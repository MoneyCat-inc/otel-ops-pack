#!/usr/bin/env tsx
/** Post progress + marketing batch to @resonai.bsky.social */
import { BskyAgent, RichText } from '@atproto/api';
import { readFileSync } from 'fs';

const POSTS: string[] = [
  `🐾 Resonai [OTel] progress check:

✅ Windows → OTel Collector → SigNoz pipeline
✅ BossCat gate lanes + ECRR audit trails
✅ Ko-fi + Patreon support pages synced
✅ Hub + portal links aligned

Evidence-first observability — no hype.
https://hub.resonai.uk/`,

  `Production observability without the hype.

Resonai [OTel]: Windows telemetry → OpenTelemetry → SigNoz. ~200ms batches, noise filtering, MIT licensed.

Sleep easy. We've got the signal. 💚

https://github.com/MoneyCat-inc/otel-ops-pack`,

  `Ko-fi is live for one-time tips ☕

Same mission as Patreon — fund BossCat automation, SigNoz playbooks, and our anti-clickbait transparency hub.

The stack stays free & open source. Support is optional.

https://ko-fi.com/fubumaki`,

  `Monthly tiers + early access? Patreon.

One-time tip? Ko-fi.

Code + runbooks? Always free on GitHub.

Pick what fits — we publish either way with full audit trails.

https://www.patreon.com/c/FaeMcLachlan
https://ko-fi.com/fubumaki`,

  `Windows SREs: tired of observability that dies in prod?

We ship runbooks, gate scripts, and dashboard exports with receipts — not slide decks.

Star ⭐ or tip 💚 if it helps your stack:

https://github.com/MoneyCat-inc/otel-ops-pack`,

  `We score OTel features 0–100 the same way we fact-check claims: source, date, context, limitations stated.

22 features. One audit trail. Zero vendor lock-in.

AntiClickbait Starter Pack 👇
https://bsky.app/starter-pack/resonai.bsky.social/3m3rct677yo2t`,
];

function loadEnv(): Record<string, string> {
  const config: Record<string, string> = {};
  for (const line of readFileSync('.env.socm', 'utf8').split('\n')) {
    const match = line.match(/^([A-Z_]+)=(.+)$/);
    if (match) config[match[1]] = match[2].trim();
  }
  return config;
}

async function postOne(agent: BskyAgent, handle: string, text: string, index: number) {
  if (text.length > 300) {
    throw new Error(`Post ${index + 1} too long: ${text.length}/300`);
  }
  const rt = new RichText({ text });
  await rt.detectFacets(agent);
  const post = await agent.post({
    text: rt.text,
    facets: rt.facets,
    createdAt: new Date().toISOString(),
  });
  const rkey = post.uri.split('/').pop();
  const url = `https://bsky.app/profile/${handle}/post/${rkey}`;
  console.log(`✅ [${index + 1}/${POSTS.length}] ${url}`);
  return url;
}

async function main() {
  const env = loadEnv();
  const handle = env.BSKY_HANDLE || 'resonai.bsky.social';
  const password = env.BSKY_APP_PASSWORD;
  const service = env.BSKY_SERVICE || 'https://bsky.social';

  if (!password) {
    console.error('BSKY_APP_PASSWORD missing in .env.socm');
    process.exit(1);
  }

  for (let i = 0; i < POSTS.length; i++) {
    if (POSTS[i].length > 300) {
      console.error(`Post ${i + 1} length ${POSTS[i].length}`);
      process.exit(1);
    }
  }

  const agent = new BskyAgent({ service });
  await agent.login({ identifier: handle, password });
  console.log(`Logged in as ${handle}\nPosting ${POSTS.length} updates...\n`);

  const urls: string[] = [];
  for (let i = 0; i < POSTS.length; i++) {
    if (i > 0) {
      await new Promise((r) => setTimeout(r, 2500));
    }
    urls.push(await postOne(agent, handle, POSTS[i], i));
  }

  console.log('\nDone.');
  urls.forEach((u) => console.log(`  ${u}`));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
