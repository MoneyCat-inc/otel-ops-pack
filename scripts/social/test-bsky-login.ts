#!/usr/bin/env tsx
/** Test Bluesky login — diagnoses app password / handle issues (never prints password). */
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

function maskPassword(pw: string): string {
  const clean = pw.replace(/\s/g, '');
  if (clean.length < 8) return '(too short — check copy)';
  return `${clean.slice(0, 4)}…${clean.slice(-4)} (${clean.length} chars, dashes: ${(pw.match(/-/g) ?? []).length})`;
}

async function tryLogin(
  service: string,
  identifier: string,
  password: string,
): Promise<{ ok: boolean; error?: string }> {
  const agent = new BskyAgent({ service });
  try {
    await agent.login({ identifier, password });
    return { ok: true };
  } catch (e) {
    return { ok: false, error: (e as Error).message };
  }
}

async function main() {
  const env = loadEnv();
  const password = env.BSKY_APP_PASSWORD ?? '';
  const service = env.BSKY_SERVICE || 'https://bsky.social';
  const handle = env.BSKY_HANDLE || 'resonai.bsky.social';

  if (!password) {
    console.error('❌ BSKY_APP_PASSWORD missing in .env.socm');
    process.exit(1);
  }

  console.log('Bluesky login diagnostic\n');
  console.log(`Service: ${service}`);
  console.log(`Handle in .env.socm: ${handle}`);
  console.log(`Password in .env.socm: ${maskPassword(password)}`);
  console.log('');

  const attempts: { label: string; id: string }[] = [
    { label: 'full handle', id: handle },
    { label: 'handle without domain', id: handle.replace(/\.bsky\.social$/i, '') },
    { label: 'email-style @ prefix stripped', id: handle.replace(/^@/, '') },
  ];

  for (const { label, id } of attempts) {
    const result = await tryLogin(service, id, password);
    if (result.ok) {
      console.log(`✅ Login OK with ${label}: "${id}"`);
      console.log('\nIf SkyFeed still fails, paste the SAME password into SkyFeed manually.');
      console.log('SkyFeed fields: Service=bsky.social  Username=resonai.bsky.social');
      return;
    }
    console.log(`❌ Failed (${label} "${id}"): ${result.error}`);
  }

  console.log('\n--- Fix checklist ---');
  console.log('1. You created a NEW "SkyFeed" app password — update .env.socm:');
  console.log('   BSKY_APP_PASSWORD=<paste the 19-char password ONCE, shown at creation>');
  console.log('2. Format must be exactly: xxxx-xxxx-xxxx-xxxx (16 letters + 3 dashes)');
  console.log('3. No quotes, spaces, or line breaks around the password');
  console.log('4. Do NOT use your main Bluesky account password');
  console.log('5. In SkyFeed use Username: resonai.bsky.social (not email)');
  console.log('6. Re-run: npx tsx scripts/social/test-bsky-login.ts');
  process.exit(1);
}

main();
