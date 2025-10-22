#!/usr/bin/env tsx
// Announce the published Starter Pack on Bluesky
// Uses RichText for clickable links and hashtags

import { BskyAgent, RichText } from '@atproto/api';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load credentials
const envPath = path.join(process.cwd(), '.env.socm');
dotenv.config({ path: envPath });

const BSKY_HANDLE = process.env.BSKY_HANDLE!;
const BSKY_APP_PASSWORD = process.env.BSKY_APP_PASSWORD!;
const BSKY_SERVICE = process.env.BSKY_SERVICE || 'https://bsky.social';

// Starter Pack URL
const STARTER_PACK_URL = 'https://bsky.app/starter-pack/resonai.bsky.social/3m3rct677yo2t';

async function main() {
  console.log('🔐 Logging in to Bluesky...');
  const agent = new BskyAgent({ service: BSKY_SERVICE });
  
  await agent.login({
    identifier: BSKY_HANDLE,
    password: BSKY_APP_PASSWORD,
  });
  
  console.log('✅ Logged in successfully\n');

  // Announcement text (under 300 chars)
  const postText = `🚀 AntiClickbait Starter Pack is live

15 trusted sources: fact-checkers, OSINT practitioners, media literacy orgs, observability leaders.

One-click follow for evidence-first verification.

${STARTER_PACK_URL}

#AntiClickbait #StarterPack #FactCheck`;

  console.log('📝 Creating announcement post...\n');
  console.log('Text:', postText);
  console.log('');

  // Use RichText to detect facets (clickable links and hashtags)
  const rt = new RichText({ text: postText });
  await rt.detectFacets(agent);

  console.log('✨ Detected facets:', rt.facets?.length || 0);
  console.log('');

  // Post with RichText facets
  const post = await agent.post({
    text: rt.text,
    facets: rt.facets, // Makes links and hashtags clickable
    createdAt: new Date().toISOString(),
  });

  console.log('✅ Announcement posted!');
  console.log('');
  console.log('📊 Post details:');
  console.log(`   URI: ${post.uri}`);
  console.log(`   CID: ${post.cid}`);
  console.log('');
  console.log(`🔗 View post: https://bsky.app/profile/${BSKY_HANDLE}/post/${post.uri.split('/').pop()}`);
  console.log('');
  console.log('🎯 Next steps:');
  console.log('   1. Update pinned post with Starter Pack link');
  console.log('   2. Create 3 custom feeds via SkyFeed');
  console.log('   3. Add feeds to Starter Pack');
  console.log('');
}

main().catch((error) => {
  console.error('❌ Error:', error.message);
  process.exit(1);
});

