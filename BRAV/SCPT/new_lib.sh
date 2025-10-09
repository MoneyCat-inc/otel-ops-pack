#!/usr/bin/env bash
# Create a new shared library under ALFA/LIBS/
set -euo pipefail

name="${1:-}"
if [[ -z "$name" ]]; then
    echo "usage: $0 <lib-name>"
    echo "example: $0 my-utils"
    exit 1
fi

base="ALFA/LIBS/$name"
mkdir -p "$base/src"

cat > "$base/README.md" <<EOF
# $name

**Location:** \`ALFA/LIBS/$name\`  
**Type:** Shared Library

## Exports
<Describe what this library provides>

## Consumers
<List apps/libs that use this>

## Usage
\`\`\`typescript
import { something } from '@alfa/LIBS/$name';
\`\`\`

## Development
\`\`\`bash
npm install
npm test
\`\`\`
EOF

cat > "$base/package.json" <<EOF
{
  "name": "@resonai/$name",
  "version": "0.1.0",
  "description": "Shared library: $name",
  "main": "src/index.js",
  "types": "src/index.d.ts",
  "scripts": {
    "test": "echo 'Add test command'"
  }
}
EOF

cat > "$base/src/index.js" <<EOF
// $name library exports
export const example = () => {
  console.log('$name library loaded');
};
EOF

echo "✅ Created new library: $base/"
echo ""
echo "Next steps:"
echo "  1. Update $base/README.md with actual exports"
echo "  2. Implement library functionality in $base/src/"
echo "  3. Add tests"
echo "  4. Update TypeScript aliases if needed"

