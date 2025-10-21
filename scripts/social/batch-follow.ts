/* scripts/social/batch-follow.ts
 * Follow accounts from FOLLOW_LIST.yaml
 */
import { BskyAgent } from '@atproto/api';
import { readFileSync } from 'fs';
import * as yaml from 'yaml';

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
    
    // Load follow list
    const followList = yaml.parse(readFileSync('docs/social/FOLLOW_LIST.yaml', 'utf8'));
    
    // Collect all handles
    const accounts: Array<{handle: string, reason: string, category: string}> = [];
    for (const category of Object.keys(followList)) {
      const items = followList[category];
      for (const item of items) {
        accounts.push({
          handle: item.handle,
          reason: item.reason,
          category,
        });
      }
    }
    
    console.log(`📋 Found ${accounts.length} accounts to follow\n`);
    
    let followed = 0;
    let skipped = 0;
    let errors = 0;
    
    for (const account of accounts) {
      try {
        console.log(`   Following @${account.handle}`);
        console.log(`      Category: ${account.category}`);
        console.log(`      Reason: ${account.reason}`);
        
        // Resolve handle to DID
        const profile = await agent.getProfile({ actor: account.handle });
        const did = profile.data.did;
        console.log(`      DID: ${did}`);
        
        // Follow using DID
        try {
          await agent.follow(did);
          followed++;
          console.log(`      ✅ Followed\n`);
        } catch (followError: any) {
          if (followError.message?.includes('already') || followError.message?.includes('duplicate')) {
            console.log(`      ⏭️  Already following\n`);
            skipped++;
          } else {
            throw followError;
          }
        }
        
        // Rate limit: wait 1 second between follows
        await new Promise(resolve => setTimeout(resolve, 1000));
        
      } catch (error: any) {
        console.log(`      ❌ Error: ${error.message}\n`);
        errors++;
      }
    }
    
    console.log('📊 Summary:');
    console.log(`   Total accounts: ${accounts.length}`);
    console.log(`   Newly followed: ${followed}`);
    console.log(`   Already following: ${skipped}`);
    console.log(`   Errors: ${errors}`);
    
    console.log('\n✅ Batch follow complete');
    console.log('\n🎯 Next step: Visit https://bsky.app/profile/resonai.bsky.social to verify');
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

main();

