#!/usr/bin/env tsx
/** List all ATProto record collections on the logged-in account (debug SkyFeed state). */
import { readFileSync } from 'fs';
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
  const agent = new BskyAgent({ service: env.BSKY_SERVICE || 'https://bsky.social' });
  await agent.login({ identifier: env.BSKY_HANDLE, password: env.BSKY_APP_PASSWORD! });
  const did = agent.did!;

  const collections = [
    'app.bsky.feed.generator',
    'app.bsky.graph.starterpack',
    'app.bsky.actor.profile',
  ];

  for (const collection of collections) {
    try {
      const res = await agent.com.atproto.repo.listRecords({ repo: did, collection, limit: 25 });
      console.log(`\n${collection}: ${res.data.records?.length ?? 0}`);
      for (const r of res.data.records ?? []) {
        console.log(' ', r.uri);
      }
    } catch (e) {
      console.log(`\n${collection}: error ${(e as Error).message}`);
    }
  }
}

main();
