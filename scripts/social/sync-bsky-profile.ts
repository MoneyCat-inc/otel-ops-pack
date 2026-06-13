#!/usr/bin/env tsx
/** Sync @resonai.bsky.social bio + pinned post with current project links */
import { BskyAgent, RichText } from '@atproto/api';
import { readFileSync } from 'fs';

const STARTER_PACK_URL =
  'https://bsky.app/starter-pack/resonai.bsky.social/3m3rct677yo2t';

const BIO = `Evidence-first observability + truth literacy.
22 OTel features scored 0-100.
Hub: https://hub.resonai.uk/
GitHub: github.com/MoneyCat-inc/otel-ops-pack
Support: ko-fi.com/fubumaki · patreon.com/c/FaeMcLachlan`;

const PINNED_TEXT = `Resonai [OTel] — evidence-first Windows observability.

Hub: https://hub.resonai.uk/
GitHub: https://github.com/MoneyCat-inc/otel-ops-pack
Ko-fi: https://ko-fi.com/fubumaki
Patreon: https://www.patreon.com/c/FaeMcLachlan

Starter Pack: ${STARTER_PACK_URL}`;

function loadEnv(): Record<string, string> {
  const config: Record<string, string> = {};
  for (const line of readFileSync('.env.socm', 'utf8').split('\n')) {
    const match = line.match(/^([A-Z_]+)=(.+)$/);
    if (match) config[match[1]] = match[2].trim();
  }
  return config;
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

  if (BIO.length > 256) {
    console.error(`Bio too long: ${BIO.length}/256`);
    process.exit(1);
  }
  if (PINNED_TEXT.length > 300) {
    console.error(`Pinned post too long: ${PINNED_TEXT.length}/300`);
    process.exit(1);
  }

  const agent = new BskyAgent({ service });
  await agent.login({ identifier: handle, password });
  console.log(`Logged in as ${handle}`);

  const before = await agent.getProfile({ actor: handle });
  console.log('\nBefore:');
  console.log(`  displayName: ${before.data.displayName}`);
  console.log(`  bio: ${JSON.stringify(before.data.description)}`);
  console.log(`  pinned: ${before.data.pinnedPost?.uri ?? '(none)'}`);

  await agent.upsertProfile((existing) => ({
    ...existing,
    displayName: existing.displayName || 'BossCat',
    description: BIO,
  }));
  console.log('\nBio updated.');

  const rt = new RichText({ text: PINNED_TEXT });
  await rt.detectFacets(agent);

  const post = await agent.post({
    text: rt.text,
    facets: rt.facets,
    createdAt: new Date().toISOString(),
  });
  console.log(`Pinned post created: ${post.uri}`);

  await agent.upsertProfile((existing) => ({
    ...existing,
    pinnedPost: { uri: post.uri, cid: post.cid },
  }));
  console.log('Post pinned.');

  const after = await agent.getProfile({ actor: handle });
  const rkey = post.uri.split('/').pop();
  console.log(`\nProfile: https://bsky.app/profile/${handle}`);
  console.log(`Pinned:  https://bsky.app/profile/${handle}/post/${rkey}`);
  console.log(`Bio length: ${after.data.description?.length ?? 0}/256`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
