/* scripts/social/pin-post.ts
 * Pin a post to profile
 */
import { BskyAgent } from '@atproto/api';
import { readFileSync } from 'fs';

function loadEnv() {
  const env = readFileSync('.env.socm', 'utf8');
  const lines = env.split('\n');
  const config: Record<string, string> = {};
  
  for (const line of lines) {
    const match = line.match(/^([A-Z_]+)=(.+)$/);
    if (match) {
      config[match[1]] = match[2].trim();
    }
  }
  
  return config;
}

async function main() {
  const config = loadEnv();
  const handle = config.BSKY_HANDLE || 'resonai.bsky.social';
  const password = config.BSKY_APP_PASSWORD;
  const service = config.BSKY_SERVICE || 'https://bsky.social';
  
  const postUri = process.argv[2];
  if (!postUri) {
    console.error('❌ Usage: npx tsx scripts/social/pin-post.ts <post-uri>');
    console.error('   Example: npx tsx scripts/social/pin-post.ts at://did:plc:abc.../app.bsky.feed.post/xyz');
    process.exit(1);
  }
  
  if (!password) {
    console.error('❌ BSKY_APP_PASSWORD not found in .env.socm');
    process.exit(1);
  }
  
  console.log('🔐 Logging in to Bluesky...');
  
  const agent = new BskyAgent({ service });
  
  try {
    await agent.login({ identifier: handle, password });
    console.log('✅ Logged in successfully\n');
    
    console.log(`📌 Pinning post: ${postUri}`);
    
    // Get post to extract CID
    const postId = postUri.split('/').pop();
    const postThread = await agent.getPostThread({ uri: postUri });
    const post = postThread.data.thread.post;
    
    console.log(`   CID: ${post.cid}`);
    
    // Update profile with pinnedPost (strong reference)
    await agent.upsertProfile((existing) => {
      return {
        ...existing,
        pinnedPost: {
          uri: postUri,
          cid: post.cid,
        },
      };
    });
    
    console.log('✅ Post pinned successfully');
    
    // Verify
    const profile = await agent.getProfile({ actor: handle });
    console.log('\n✅ Current pinned post:');
    console.log(`   ${profile.data.pinnedPost || '(none)'}`);
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

main();

