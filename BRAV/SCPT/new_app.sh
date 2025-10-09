#!/usr/bin/env bash
# Create a new application under ALFA/APPS/
set -euo pipefail

name="${1:-}"
if [[ -z "$name" ]]; then
    echo "usage: $0 <app-name>"
    echo "example: $0 my-service"
    exit 1
fi

base="ALFA/APPS/$name"
mkdir -p "$base"/{src,config,scripts}

cat > "$base/README.md" <<EOF
# $name

**Location:** \`ALFA/APPS/$name\`  
**Type:** Application

## Purpose
<Describe what this application does>

## Build
\`\`\`bash
# Add build commands
npm install
npm run build
\`\`\`

## Run
\`\`\`bash
# Add run commands
npm run dev
\`\`\`

## Configuration
See \`config/\` for environment-specific settings.

## Scripts
See \`scripts/\` for operational scripts.
EOF

cat > "$base/package.json" <<EOF
{
  "name": "$name",
  "version": "0.1.0",
  "private": true,
  "description": "Application: $name",
  "main": "src/index.js",
  "scripts": {
    "dev": "node src/index.js",
    "build": "echo 'Add build command'",
    "test": "echo 'Add test command'"
  }
}
EOF

cat > "$base/src/index.js" <<EOF
// $name entry point
console.log('$name starting...');
EOF

echo "✅ Created new app: $base/"
echo ""
echo "Next steps:"
echo "  1. Update $base/README.md with actual details"
echo "  2. Add dependencies to $base/package.json"
echo "  3. Implement functionality in $base/src/"
echo "  4. Add to CODEOWNERS if needed"

