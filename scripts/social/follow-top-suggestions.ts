#!/usr/bin/env tsx
/** Follow up to 5 accounts from follow_suggestions.jsonl (not already followed) */
import { BskyAgent } from '@atproto/api';
import { readFileSync, appendFileSync, existsSync, mkdirSync } from 'fs';

const MAX = 5;
const SUGGESTIONS = 'artifacts/social/follow_suggestions.jsonl';
const LEDGER = 'artifacts/social/followed.jsonl';

function loadEnv(): Record<string, string> {
  const config: Record<string, string> = {};
  for (const line of readFileSync('.env.socm', 'utf8').split('\n')) {
    const m = line.match(/^([A-Z_]+)=(.+)$/);
    if (m) config[m[1]] = m[2].trim();
  }
  return config;
}

function alreadyFollowed(): Set<string> {
  const set = new Set<string>();
  if (!existsSync(LEDGER)) return set;
  for (const line of readFileSync(LEDGER, 'utf8').split('\n').filter(Boolean)) {
    try {
      set.add(JSON.parse(line).handle);
    } catch {
      /* skip */
    }
  }
  return set;
}

async function main() {
  if (!existsSync(SUGGESTIONS)) {
    console.error(`Run first: npm run social:recommend-follows`);
    process.exit(1);
  }

  const env = loadEnv();
  const agent = new BskyAgent({ service: env.BSKY_SERVICE || 'https://bsky.social' });
  await agent.login({ identifier: env.BSKY_HANDLE!, password: env.BSKY_APP_PASSWORD! });

  const done = alreadyFollowed();
  const lines = readFileSync(SUGGESTIONS, 'utf8').split('\n').filter(Boolean);
  const picks: { handle: string; score: number }[] = [];
  for (const line of lines) {
    const row = JSON.parse(line);
    if (row.handle && !done.has(row.handle)) picks.push(row);
  }
  picks.sort((a, b) => (b.score ?? 0) - (a.score ?? 0));

  mkdirSync('artifacts/social', { recursive: true });
  let followed = 0;
  for (const { handle } of picks) {
    if (followed >= MAX) break;
    try {
      const profile = await agent.getProfile({ actor: handle });
      await agent.follow(profile.data.did);
      appendFileSync(
        LEDGER,
        JSON.stringify({ handle, followedAt: new Date().toISOString() }) + '\n'
      );
      console.log(`✅ Followed @${handle}`);
      followed++;
      await new Promise((r) => setTimeout(r, 1200));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      if (/already|duplicate/i.test(msg)) {
        console.log(`⏭️  Already following @${handle}`);
      } else {
        console.log(`❌ @${handle}: ${msg}`);
      }
    }
  }
  console.log(`\nDone. New follows this run: ${followed}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
