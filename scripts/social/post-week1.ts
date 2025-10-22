#!/usr/bin/env tsx
// Post Week-1 content (Wed-Fri automated posts)
// Sat/Sun require manual curation

import { BskyAgent, RichText } from '@atproto/api';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.join(process.cwd(), '.env.socm') });

const BSKY_HANDLE = process.env.BSKY_HANDLE!;
const BSKY_APP_PASSWORD = process.env.BSKY_APP_PASSWORD!;
const BSKY_SERVICE = process.env.BSKY_SERVICE || 'https://bsky.social';

const agent = new BskyAgent({ service: BSKY_SERVICE });

async function postWithFacets(text: string, delayMs = 0) {
  if (delayMs > 0) {
    console.log(`⏳ Waiting ${delayMs}ms...`);
    await new Promise(r => setTimeout(r, delayMs));
  }
  
  const rt = new RichText({ text });
  await rt.detectFacets(agent);
  
  const post = await agent.post({
    text: rt.text,
    facets: rt.facets,
    createdAt: new Date().toISOString(),
  });
  
  const postId = post.uri.split('/').pop();
  console.log(`✅ Posted: https://bsky.app/profile/${BSKY_HANDLE}/post/${postId}`);
  return post;
}

async function main() {
  console.log('🔐 Logging in to Bluesky...');
  await agent.login({
    identifier: BSKY_HANDLE,
    password: BSKY_APP_PASSWORD,
  });
  console.log('✅ Logged in\n');
  
  console.log('📅 Posting Week-1 Content (Wed-Fri)\n');
  
  // Wed - Mythbuster
  console.log('📍 POST 1: Wednesday Mythbuster');
  await postWithFacets(`❌ Myth: "One screenshot = proof."
✅ Fact: Screens can be altered. Check source, date, context. Do a quick reverse-image search. Ask for a link to the original.
Reply "CHECKLIST" for our 60-sec workflow.`);
  
  // Thu - Method thread (create 3 linked posts)
  console.log('\n📍 POST 2: Thursday Method Thread (1/3)');
  const thread1 = await postWithFacets(`1/3 How we verify claims fast:
• Define the claim exactly
• Source (primary vs. commentary)
• Date (current or old?)
• Context (what's omitted?)
Thread 👇`, 2000);
  
  console.log('📍 POST 3: Method Thread (2/3) - Reply to 1/3');
  const thread2 = await agent.post({
    text: `2/3 Cross-checks:
• Search the exact phrasing in quotes
• Reverse image search if visuals
• Look for primary docs (.gov, court filings)`,
    reply: {
      root: { uri: thread1.uri, cid: thread1.cid },
      parent: { uri: thread1.uri, cid: thread1.cid },
    },
    createdAt: new Date().toISOString(),
  });
  const post2Id = thread2.uri.split('/').pop();
  console.log(`✅ Posted: https://bsky.app/profile/${BSKY_HANDLE}/post/${post2Id}`);
  
  await new Promise(r => setTimeout(r, 2000));
  
  console.log('📍 POST 4: Method Thread (3/3) - Reply to 2/3');
  const thread3 = await agent.post({
    text: `3/3 Outcomes:
• Correct • Needs context • Misleading • False • Unverified
We always cite sources. Send us a claim to audit.`,
    reply: {
      root: { uri: thread1.uri, cid: thread1.cid },
      parent: { uri: thread2.uri, cid: thread2.cid },
    },
    createdAt: new Date().toISOString(),
  });
  const post3Id = thread3.uri.split('/').pop();
  console.log(`✅ Posted: https://bsky.app/profile/${BSKY_HANDLE}/post/${post3Id}`);
  
  // Fri - Weekly recap
  console.log('\n📍 POST 5: Friday Weekly Recap');
  await postWithFacets(`🗂️ This week's patterns:
• Old stories shared as new
• Cropped images hiding context
• Anonymous screenshots w/ no links
If you see these, pause before reposting. Send us candidates to check.`, 2000);
  
  console.log('\n✅ All automated posts created!');
  console.log('');
  console.log('📝 Manual posts remaining:');
  console.log('   - Sat (10:00 UTC): Community Spotlight (requires real account + link)');
  console.log('   - Sun (18:00 UTC): Signal Boost (requires quote-post of current debunk)');
  console.log('');
  console.log('🎯 Next: Create custom feeds in SkyFeed or self-host');
}

main().catch((error) => {
  console.error('❌ Error:', error.message);
  process.exit(1);
});

