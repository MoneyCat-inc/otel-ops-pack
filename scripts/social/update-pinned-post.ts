#!/usr/bin/env tsx
// Update pinned post with Starter Pack link
// Uses RichText for clickable links

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

  // New pinned post text (under 280 chars as user specified)
  const postText = `🧩 AntiClickbait — calm, evidence-first media literacy.
We add context with sources (quote > repost).
Want our 60-sec check? Reply "CHECKLIST".

Starter Pack: ${STARTER_PACK_URL}`;

  console.log('📝 Creating new pinned post...\n');
  console.log('Text:', postText);
  console.log('Character count:', postText.length);
  console.log('');

  // Use RichText to detect facets
  const rt = new RichText({ text: postText });
  await rt.detectFacets(agent);

  console.log('✨ Detected facets:', rt.facets?.length || 0);
  console.log('');

  // Create the post
  const post = await agent.post({
    text: rt.text,
    facets: rt.facets,
    createdAt: new Date().toISOString(),
  });

  console.log('✅ Post created!');
  console.log(`   URI: ${post.uri}`);
  console.log(`   CID: ${post.cid}`);
  console.log('');

  // Now pin it
  console.log('📌 Pinning post to profile...');
  
  await agent.upsertProfile((existing) => {
    return {
      ...existing,
      pinnedPost: {
        uri: post.uri,
        cid: post.cid,
      },
    };
  });

  console.log('✅ Post pinned successfully!');
  console.log('');
  console.log(`🔗 View post: https://bsky.app/profile/${BSKY_HANDLE}/post/${post.uri.split('/').pop()}`);
  console.log(`🔗 View profile: https://bsky.app/profile/${BSKY_HANDLE}`);
  console.log('');
  console.log('🎯 Pinned post is now live with Starter Pack link!');
}

main().catch((error) => {
  console.error('❌ Error:', error.message);
  process.exit(1);
});

