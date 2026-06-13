#!/usr/bin/env tsx
/** Week-2 engagement: tips + CHECKLIST reply on pinned post */
import { BskyAgent, RichText } from '@atproto/api';
import { readFileSync } from 'fs';

const STARTER_PACK =
  'https://bsky.app/starter-pack/resonai.bsky.social/3m3rct677yo2t';

const POSTS: string[] = [
  `⚡ Windows OTel health check in one command:

pwsh scripts/quick-monitor.ps1

SigNoz UI, collector service, canary path — color-coded pass/fail.

Part of Resonai [OTel] (MIT). Receipts in repo.

https://github.com/MoneyCat-inc/otel-ops-pack`,

  `❌ Myth: "Dashboard green = prod is fine."
✅ Fact: Dashboards show what you instrumented. Missing spans, sampling drops, and collector backpressure hide in the gaps.

We publish baselines + ECRR reports when we change the pipeline.`,

  `Curating signal on Bluesky?

AntiClickbait Starter Pack — 15 fact-check + OSINT + observability accounts, one click:

${STARTER_PACK}`,
];

const CHECKLIST_REPLY = `🔍 Verification Checklist — reply "CHECKLIST" anytime:

□ Two independent sources
□ Original source named + linked
□ Date/context clear (not recycled old news)
□ Reverse-image search if visuals matter

Full guide: https://hub.resonai.uk/`;

function loadEnv(): Record<string, string> {
  const config: Record<string, string> = {};
  for (const line of readFileSync('.env.socm', 'utf8').split('\n')) {
    const match = line.match(/^([A-Z_]+)=(.+)$/);
    if (match) config[match[1]] = match[2].trim();
  }
  return config;
}

async function postText(
  agent: BskyAgent,
  handle: string,
  text: string,
  reply?: { root: { uri: string; cid: string }; parent: { uri: string; cid: string } }
) {
  if (text.length > 300) throw new Error(`Too long (${text.length}/300)`);
  const rt = new RichText({ text });
  await rt.detectFacets(agent);
  const post = await agent.post({
    text: rt.text,
    facets: rt.facets,
    reply,
    createdAt: new Date().toISOString(),
  });
  const rkey = post.uri.split('/').pop();
  console.log(`✅ https://bsky.app/profile/${handle}/post/${rkey}`);
  return post;
}

async function main() {
  const env = loadEnv();
  const handle = env.BSKY_HANDLE || 'resonai.bsky.social';
  const agent = new BskyAgent({ service: env.BSKY_SERVICE || 'https://bsky.social' });
  await agent.login({ identifier: handle, password: env.BSKY_APP_PASSWORD! });

  const profile = await agent.getProfile({ actor: handle });
  const pinned = profile.data.pinnedPost;
  if (!pinned?.uri || !pinned?.cid) {
    console.warn('No pinned post — skipping CHECKLIST reply');
  }

  console.log(`Posting ${POSTS.length} feed posts...\n`);
  for (let i = 0; i < POSTS.length; i++) {
    if (i > 0) await new Promise((r) => setTimeout(r, 2500));
    await postText(agent, handle, POSTS[i]);
  }

  if (pinned?.uri && pinned?.cid) {
    console.log('\nPosting CHECKLIST reply on pinned post...\n');
    await new Promise((r) => setTimeout(r, 2500));
    const root = { uri: pinned.uri, cid: pinned.cid };
    await postText(agent, handle, CHECKLIST_REPLY, { root, parent: root });
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
