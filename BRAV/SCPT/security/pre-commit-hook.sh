#!/bin/bash

# BossCat OEM - Pre-commit Secret Detection Hook
# Prevents hardcoded secrets from being committed

echo "🔍 BossCat OEM - Scanning for secrets..."

# Common secret patterns to detect
SECRET_PATTERNS=(
    "api[_-]?key"
    "secret"
    "password"
    "token"
    "auth[_-]?key"
    "private[_-]?key"
    "access[_-]?token"
    "ghp_[A-Za-z0-9]{36}"
    "gho_[A-Za-z0-9]{36}"
    "ghu_[A-Za-z0-9]{36}"
    "ghs_[A-Za-z0-9]{36}"
    "ghr_[A-Za-z0-9]{76}"
    "github_pat_[A-Za-z0-9_]{82}"
    "sk-[A-Za-z0-9]{48}"
    "pk_[A-Za-z0-9]{24}"
    "AIza[0-9A-Za-z\\-_]{35}"
    "ya29\\.[0-9A-Za-z\\-_]+"
)

# Files to exclude from scanning
EXCLUDE_DIRS=(
    ".git"
    "node_modules"
    "dist"
    "build"
    ".next"
    "coverage"
    ".nyc_output"
)

# Build exclude pattern
EXCLUDE_PATTERN=""
for dir in "${EXCLUDE_DIRS[@]}"; do
    EXCLUDE_PATTERN="$EXCLUDE_PATTERN --exclude-dir=$dir"
done

# Check for hardcoded secrets
SECRETS_FOUND=0

for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -r -i -E "$pattern\s*[:=]\s*[\"'][^\"']{10,}[\"']" $EXCLUDE_PATTERN . >/dev/null 2>&1; then
        echo "❌ Potential secret detected with pattern: $pattern"
        SECRETS_FOUND=1
    fi
done

# Check for the revoked SigNoz API keys. They are matched by SHA-256 prefix of each 44-char
# base64 token, so this hook never stores the key values themselves (literals removed
# 2026-11-04; the repository is public).
REVOKED_SIGNOZ_SHA256_PREFIXES=" 089c8993 3e775a2b 869a41b7 8abc66bc c66026b5 "
sha256_prefix() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi | cut -c1-8
}
while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    prefix=$(printf '%s' "$candidate" | sha256_prefix)
    case "$REVOKED_SIGNOZ_SHA256_PREFIXES" in
        *" $prefix "*)
            echo "❌ Revoked SigNoz API key detected (sha256 prefix $prefix)!"
            SECRETS_FOUND=1
            ;;
    esac
done < <(grep -r -h -o -E "[A-Za-z0-9+/]{43}=" $EXCLUDE_PATTERN . 2>/dev/null | sort -u)

# Check for placeholder secrets that shouldn't be committed
if grep -r -i "your-[a-z-]*-here" $EXCLUDE_PATTERN . >/dev/null 2>&1; then
    echo "❌ Placeholder secrets detected! Please use environment variables."
    SECRETS_FOUND=1
fi

if [ $SECRETS_FOUND -eq 1 ]; then
    echo ""
    echo "🚨 SECURITY VIOLATION DETECTED!"
    echo "   Please remove hardcoded secrets and use environment variables instead."
    echo "   See docs/SECURE_ENVIRONMENT_TEMPLATE.md for guidance."
    echo ""
    echo "   To fix:"
    echo "   1. Remove hardcoded secrets from your code"
    echo "   2. Use environment variables instead"
    echo "   3. Add secrets to .env.local (never commit this file)"
    echo ""
    exit 1
fi

echo "✅ No secrets detected. Commit approved."
exit 0
