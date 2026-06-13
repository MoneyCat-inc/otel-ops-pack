/* scripts/social/update-profile.ts
 * Update Bluesky profile (bio, display name) via ATProto API
 * Uses credentials from .env.socm
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
  console.log(`   Handle: ${handle}`);
  
  const agent = new BskyAgent({ service });
  
  try {
    await agent.login({ identifier: handle, password });
    console.log('✅ Logged in successfully');
    
    // Get current profile
    const profile = await agent.getProfile({ actor: handle });
    console.log('\n📋 Current Profile:');
    console.log(`   Display Name: ${profile.data.displayName || '(none)'}`);
    console.log(`   Bio: ${profile.data.description || '(none)'}`);
    console.log(`   Avatar: ${profile.data.avatar ? 'Set' : 'Not set'}`);
    console.log(`   Banner: ${profile.data.banner ? 'Set' : 'Not set'}`);
    
    // Update profile
    const newBio = `Evidence-first observability + truth literacy.
22 OTel features scored 0-100.
Hub: https://hub.resonai.uk/
GitHub: github.com/MoneyCat-inc/otel-ops-pack
Support: ko-fi.com/fubumaki · patreon.com/c/FaeMcLachlan`;
    
    console.log('\n🔄 Updating profile...');
    console.log(`   New Bio: ${newBio}`);
    
    await agent.upsertProfile((existing) => {
      return {
        ...existing,
        displayName: existing.displayName || 'BossCat',
        description: newBio,
      };
    });
    
    console.log('✅ Profile updated successfully');
    
    // Verify update
    const updatedProfile = await agent.getProfile({ actor: handle });
    console.log('\n✅ Updated Profile:');
    console.log(`   Display Name: ${updatedProfile.data.displayName}`);
    console.log(`   Bio: ${updatedProfile.data.description}`);
    
    console.log('\n🎯 Next steps:');
    console.log('   1. Visit https://bsky.app/profile/resonai.bsky.social to verify');
    console.log('   2. Create new pinned post with hub showcase');
    console.log('   3. Follow 21 curated accounts from FOLLOW_LIST.yaml');
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

main();

