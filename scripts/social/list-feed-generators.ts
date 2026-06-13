#!/usr/bin/env tsx
/** List app.bsky.feed.generator records on @resonai.bsky.social */
import { readFileSync, writeFileSync } from 'fs';
import { BskyAgent } from '@atproto/api';

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

  const agent = new BskyAgent({ service });
  await agent.login({ identifier: handle, password });
  const did = agent.did!;
  console.log(`Logged in as ${handle} (${did})`);

  const feeds = await agent.com.atproto.repo.listRecords({
    repo: did,
    collection: 'app.bsky.feed.generator',
    limit: 100,
  });

  const records = feeds.data.records ?? [];
  console.log(`Feed generators: ${records.length}`);

  const out = records.map((r) => ({
    uri: r.uri,
    rkey: r.uri.split('/').pop(),
    displayName: (r.value as { displayName?: string }).displayName,
    description: (r.value as { description?: string }).description,
    serviceDid: (r.value as { did?: string }).did,
  }));

  for (const f of out) {
    console.log(`- ${f.displayName ?? f.rkey}: ${f.uri}`);
  }

  writeFileSync(
    'docs/social/skyfeed-feeds-live.json',
    JSON.stringify({ did, handle, updatedAt: new Date().toISOString(), feeds: out }, null, 2),
  );
  console.log('Wrote docs/social/skyfeed-feeds-live.json');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
