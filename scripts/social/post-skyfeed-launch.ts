#!/usr/bin/env tsx
/** Post Bluesky announcement when SkyFeed feeds are live. */
import { readFileSync } from 'fs';
import { BskyAgent, RichText } from '@atproto/api';

function loadEnv(): Record<string, string> {
  const config: Record<string, string> = {};
  for (const line of readFileSync('.env.socm', 'utf8').split('\n')) {
    const match = line.match(/^([A-Z_]+)=(.+)$/);
    if (match) config[match[1]] = match[2].trim();
  }
  return config;
}

type LiveFeed = { uri: string; displayName?: string; rkey?: string };

function feedBskyUrl(uri: string): string {
  const rkey = uri.split('/').pop() ?? '';
  return `https://bsky.app/profile/resonai.bsky.social/feed/${rkey}`;
}

async function main() {
  const live = JSON.parse(
    readFileSync('docs/social/skyfeed-feeds-live.json', 'utf8'),
  ) as { feeds: LiveFeed[] };

  if (!live.feeds?.length) {
    console.error('No feeds in skyfeed-feeds-live.json');
    process.exit(1);
  }

  const env = loadEnv();
  const agent = new BskyAgent({ service: env.BSKY_SERVICE || 'https://bsky.social' });
  await agent.login({ identifier: env.BSKY_HANDLE, password: env.BSKY_APP_PASSWORD! });

  const lines = [
    '🦋 New custom feeds on Bluesky (SkyFeed):',
    '',
    ...live.feeds.map((f) => {
      const name = f.displayName ?? f.rkey ?? 'Feed';
      return `• ${name}\n  ${feedBskyUrl(f.uri)}`;
    }),
    '',
    'Evidence-first observability + fact-check literacy.',
    'Hub: https://hub.resonai.uk/',
    'Starter Pack: https://bsky.app/starter-pack/resonai.bsky.social/3m3rct677yo2t',
    '',
    '#AntiClickbait #OpenTelemetry #FactCheck',
  ];

  const text = lines.join('\n');
  const rt = new RichText({ text });
  await rt.detectFacets(agent);

  const post = await agent.post({
    text: rt.text,
    facets: rt.facets,
    createdAt: new Date().toISOString(),
  });

  console.log('Posted:', post.uri);
  console.log('https://bsky.app/profile/resonai.bsky.social/post/' + post.uri.split('/').pop());
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
