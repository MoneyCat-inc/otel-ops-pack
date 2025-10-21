/* scripts/social/post-hub-showcase.ts
 * Create hub showcase post for pinning
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
  
  if (!password) {
    console.error('❌ BSKY_APP_PASSWORD not found in .env.socm');
    process.exit(1);
  }
  
  console.log('🔐 Logging in to Bluesky...');
  
  const agent = new BskyAgent({ service });
  
  try {
    await agent.login({ identifier: handle, password });
    console.log('✅ Logged in successfully\n');
    
    // Hub showcase post
    const postText = `[DATA] BossCat Hub is live: https://hub.resonai.uk/

Evidence-first observability for Windows:
- 22 OTel features scored 0-100
- Full transparency (source links, limitations, artifacts)
- Real deployments, real metrics

No hype. Just what actually works.

#OpenTelemetry #AntiClickbait`;
    
    console.log('📝 Creating hub showcase post...');
    console.log(`   Length: ${postText.length} / 300 chars`);
    console.log(`\n   Text:\n${postText}\n`);
    
    const post = await agent.post({
      text: postText,
      createdAt: new Date().toISOString(),
    });
    
    console.log('✅ Post created successfully');
    console.log(`   URI: ${post.uri}`);
    console.log(`   CID: ${post.cid}`);
    
    const postUrl = `https://bsky.app/profile/${handle}/post/${post.uri.split('/').pop()}`;
    console.log(`   URL: ${postUrl}`);
    
    console.log('\n🎯 Next steps:');
    console.log(`   1. Visit ${postUrl}`);
    console.log('   2. Click 3-dot menu → "Pin to profile"');
    console.log('   3. Unpin old post if needed (only 1 pin allowed)');
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

main();

