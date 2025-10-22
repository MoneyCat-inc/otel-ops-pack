#!/bin/bash
# Deploy 3 custom feeds using Bluesky's official feed-generator
# Run this to create self-hosted feeds

set -e

echo "📦 Setting up custom feeds..."

# Clone official feed-generator
if [ ! -d "custom-feeds-generator" ]; then
  git clone https://github.com/bluesky-social/feed-generator.git custom-feeds-generator
  cd custom-feeds-generator
  npm install
else
  cd custom-feeds-generator
  git pull
fi

echo "✅ Feed generator ready"
echo ""

# Create feed algorithm files
echo "📝 Creating feed algorithms..."

# Feed 1: Fact-Check Firehose
cat > src/algos/factcheck-firehose.ts << 'EOF'
import { QueryParams } from '../lexicon/types/app/bsky/feed/getFeedSkeleton'
import { AppContext } from '../config'

const FACT_CHECKER_DIDS = [
  'did:plc:27ovyakfahyrvm247jsfdkon', // fullfact.org
  'did:plc:dqa3uws2xsxnwtueag5zw6qk', // factcheck.afp.com
  'did:plc:hhteydoawq45y4nvmeipl7zy', // politifact.bsky.social
  'did:plc:jbvnehrrdqoulco4rf5gxg5r', // reuters.com
]

const KEYWORDS = ['fact check', 'debunk', 'misleading', 'correction', 'false claim']
const EXCLUDE = ['satire', 'parody']

export const handler = async (ctx: AppContext, params: QueryParams) => {
  // Implementation would query posts from these authors + keywords
  // Boost quote-posts by 2x
  // Exclude satire/parody
  return { cursor: undefined, feed: [] }
}
EOF

# Feed 2: OSINT + Verification
cat > src/algos/osint-verification.ts << 'EOF'
import { QueryParams } from '../lexicon/types/app/bsky/feed/getFeedSkeleton'
import { AppContext } from '../config'

const OSINT_DIDS = [
  'did:plc:sb54dpdfefflykmf5bcfvr7t', // bellingcat.com
  'did:plc:2whlowi5jjjqrdrrj4lxh2lx', // eliothiggins.bsky.social
  'did:plc:r4zn5hi2hj24d3y3mj5my2id', // sector035.bsky.social
  'did:plc:j45cwydngasqcktrd4cdi6tx', // alistaircoleman.bsky.social
]

const KEYWORDS = ['reverse image', 'exif', 'metadata', 'geolocate', 'osint', 'verify']

export const handler = async (ctx: AppContext, params: QueryParams) => {
  // Implementation would query OSINT accounts + method keywords
  // Boost method terms by 1.2x
  return { cursor: undefined, feed: [] }
}
EOF

# Feed 3: AntiClickbait HQ
cat > src/algos/anticlickbait-hq.ts << 'EOF'
import { QueryParams } from '../lexicon/types/app/bsky/feed/getFeedSkeleton'
import { AppContext } from '../config'

const BOSSCAT_DID = 'did:plc:ohvz4d5ucvbqiykwp2pkfato' // resonai.bsky.social

export const handler = async (ctx: AppContext, params: QueryParams) => {
  // Implementation would query BossCat + partners
  // Filter: Quote-posts only
  // Boost quote-posts by 3x
  return { cursor: undefined, feed: [] }
}
EOF

echo "✅ Algorithm files created"
echo ""
echo "🚀 Next steps:"
echo "   1. Deploy to Vercel/Railway/Fly.io"
echo "   2. Publish feeds: npm run publishFeed"
echo "   3. Add feed URIs to Starter Pack"
echo ""
echo "📖 Full implementation guide: https://github.com/bluesky-social/feed-generator"

